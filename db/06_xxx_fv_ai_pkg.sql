-- =============================================================================
-- XXX_FV_AI_PKG  (adapter layer)
-- The only package that talks to the Generative AI service (APEX_AI -> Claude).
-- Principle: SQL decides, Claude explains. Claude receives aggregated facts
-- (profiles, issue counts, examples, reconciliations), never full files, and
-- sensitive values are already masked by the rules engine.
-- APEX_AI needs an APEX session: from APEX pages it exists; from SQLcl call
-- apex_session.create_session(app_id, page_id, user) first.
-- =============================================================================

create or replace package xxx_fv_ai_pkg authid definer as

    -- JSON facts about a validated batch. Also used by the "Ask Claude" agent.
    function get_batch_context (p_batch_id in xxx_fv_batches.batch_id%type) return clob;

    -- JSON facts for mapping one file's unmapped headers.
    function get_mapping_context (p_file_id in xxx_fv_files.file_id%type) return clob;

    -- Status-code APIs (accepted exception to CON-30): on failure they roll back to
    -- their savepoint, log the error, keep a FAILED report row, and return 'E'.
    procedure generate_batch_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2);

    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2);

end xxx_fv_ai_pkg;
/

create or replace package body xxx_fv_ai_pkg as

    -- -------------------------------------------------------------------------
    c_report_schema constant varchar2(8000) := q'~{
  "type": "object",
  "properties": {
    "executive_summary": { "type": "string" },
    "readiness_explanation": { "type": "string" },
    "modules": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "module": { "type": "string" },
          "object_code": { "type": "string" },
          "status": { "type": "string", "enum": ["OK", "WARNING", "BLOCKED", "NOT_PROVIDED"] },
          "summary": { "type": "string" },
          "key_findings": { "type": "array", "items": { "type": "string" } },
          "actions": { "type": "array", "items": { "type": "string" } }
        },
        "required": ["module", "object_code", "status", "summary", "key_findings", "actions"],
        "additionalProperties": false
      }
    },
    "insights": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": { "type": "string" },
          "detail": { "type": "string" },
          "evidence": { "type": "string" },
          "impact": { "type": "string", "enum": ["HIGH", "MEDIUM", "LOW"] }
        },
        "required": ["title", "detail", "evidence", "impact"],
        "additionalProperties": false
      }
    },
    "reconciliation_comments": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "reconciliation": { "type": "string" },
          "comment": { "type": "string" }
        },
        "required": ["reconciliation", "comment"],
        "additionalProperties": false
      }
    },
    "top_risks": { "type": "array", "items": { "type": "string" } },
    "next_steps": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "step": { "type": "string" },
          "owner": { "type": "string", "enum": ["CLIENT", "CONSULTANT", "BOTH"] }
        },
        "required": ["step", "owner"],
        "additionalProperties": false
      }
    }
  },
  "required": ["executive_summary", "readiness_explanation", "modules", "insights",
               "reconciliation_comments", "top_risks", "next_steps"],
  "additionalProperties": false
}~';

    c_mapping_schema constant varchar2(4000) := q'~{
  "type": "object",
  "properties": {
    "mappings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "column_position": { "type": "integer" },
          "target_column": { "type": "string" },
          "confidence": { "type": "number" },
          "reason": { "type": "string" }
        },
        "required": ["column_position", "target_column", "confidence", "reason"],
        "additionalProperties": false
      }
    }
  },
  "required": ["mappings"],
  "additionalProperties": false
}~';

    -- -------------------------------------------------------------------------
    function report_system_prompt (p_language in varchar2) return clob is
    begin
        return
'You are a senior Oracle Fusion Cloud ERP data-migration consultant. You review the result of a
pre-load validation run (master data and opening balances for GL, AP, AR, Cash Management,
Purchasing and Requisitions) and write the report a project manager and the client finance team read
before FBDI loads start.

Rules:
1. Use only the facts in the JSON context. Never invent records, counts, amounts or rule results.
2. Quote counts and amounts exactly as given. Do not recalculate totals.
3. readiness_score and readiness_status are computed by the system. Explain them; never change them.
4. ERROR blocks the load, WARNING needs a decision, INFO is for awareness.
   Module status: BLOCKED if it has any ERROR, WARNING if only warnings, OK otherwise,
   NOT_PROVIDED when the object appears in missing_objects.
5. Actions must be concrete: name the column, the rule_code and what the client must change.
6. Insights are what an experienced consultant notices beyond single errors: patterns across
   rows (for example inconsistent casing, near-duplicate names), aging of open items, currency mix,
   concentration, reconciliation gaps, objects that look out of scope (fully received POs,
   unapproved requisitions), and data that is valid but suspicious. Each insight cites its evidence
   from the context.
7. Be concise. No marketing language. If the context has no data for a section, return an empty list.
8. ' || case p_language
            when xxx_fv_const_pkg.c_lang_ar then
                'Write every narrative field in Modern Standard Arabic, business register. Keep object codes, '
                || 'rule codes, column names, numbers, dates and currency codes exactly as given (Latin script).'
            else
                'Write in clear business English.'
          end;
    end report_system_prompt;

    -- -------------------------------------------------------------------------
    function mapping_system_prompt return clob is
    begin
        return
'You map spreadsheet headers to Oracle Fusion migration template columns.
For each unmapped header return the best target_column from target_columns, or "" when none fits.
Use the header text (it may be Arabic or abbreviated) and the sample_shape (digits are shown as 9).
Never map to a column listed in already_mapped. Never map two headers to the same target.
confidence is 0..1; use below 0.5 when unsure. reason is one short sentence in English.';
    end mapping_system_prompt;

    -- -------------------------------------------------------------------------
    -- Strips ``` fences if a provider adds them, then checks it is a JSON object.
    function clean_json (p_text in clob) return clob is
        l_text clob := regexp_replace(p_text, '^\s*```(json)?\s*|\s*```\s*$', '');
        l_obj  json_object_t;
    begin
        l_obj := json_object_t.parse(l_text);
        return l_text;
    exception
        when others then
            raise_application_error(xxx_fv_const_pkg.c_err_ai_response,
                'The AI response is not valid JSON: ' || dbms_lob.substr(p_text, 300, 1));
    end clean_json;

    -- -------------------------------------------------------------------------
    function elapsed_ms (p_started in timestamp) return number is
        l_diff interval day(3) to second(3) := systimestamp - p_started;
    begin
        return round(extract(day from l_diff) * 86400000 + extract(hour from l_diff) * 3600000
                     + extract(minute from l_diff) * 60000 + extract(second from l_diff) * 1000);
    end elapsed_ms;

    -- -------------------------------------------------------------------------
    function call_ai (
        p_system_prompt in clob,
        p_prompt        in clob,
        p_schema        in clob) return clob
    is
    begin
        return clean_json(
                   apex_ai.generate(
                       p_prompt               => p_prompt,
                       p_system_prompt        => p_system_prompt,
                       p_service_static_id    => xxx_fv_const_pkg.c_ai_service_static_id,
                       -- no p_temperature: current Claude models reject it (HTTP 400 "temperature is deprecated")
                       p_response_json_schema => p_schema));
    end call_ai;

    -- -------------------------------------------------------------------------
    procedure save_report (
        p_batch_id     in  number,
        p_file_id      in  number,
        p_report_type  in  varchar2,
        p_language     in  varchar2,
        p_status       in  varchar2,
        p_context      in  clob,
        p_response     in  clob,
        p_error        in  varchar2,
        p_elapsed_ms   in  number,
        p_user         in  varchar2,
        x_report_id    out number)
    is
    begin
        insert into xxx_fv_ai_reports (batch_id, file_id, report_type, language_code, status_code,
                                       service_static_id, context_json, response_json, error_message,
                                       elapsed_ms, requested_by)
        values (p_batch_id, p_file_id, p_report_type, p_language, p_status,
                xxx_fv_const_pkg.c_ai_service_static_id, p_context, p_response, substr(p_error, 1, 4000),
                p_elapsed_ms, p_user)
        returning report_id into x_report_id;
    end save_report;

    -- =========================================================================
    -- Context builders (queries only, CC-04)
    -- =========================================================================
    function get_batch_context (p_batch_id in xxx_fv_batches.batch_id%type) return clob is
        l_files    clob;
        l_missing  clob;
        l_profile  clob;
        l_issues   clob;
        l_recon    clob;
        l_json     clob;
    begin
        select json_arrayagg(
                   json_object(
                       'file'             value d.file_name,
                       'sheet'            value f.sheet_display_name,
                       'object_code'      value f.object_code,
                       'object_name'      value o.object_name,
                       'module'           value o.module_code,
                       'rows'             value f.row_count,
                       'unmapped_headers' value (select json_arrayagg(fc.file_header order by fc.column_position returning clob)
                                                   from xxx_fv_file_columns fc
                                                  where fc.file_id = f.file_id
                                                    and fc.mapped_column is null) format json
                       absent on null returning clob)
                   order by o.load_order, f.file_id returning clob)
          into l_files
          from xxx_fv_files f
          join xxx_fv_documents d
            on d.document_id = f.document_id
          left join xxx_fv_objects o
            on o.object_code = f.object_code
         where f.batch_id = p_batch_id;

        select json_arrayagg(
                   json_object('object_code' value o.object_code,
                               'object_name' value o.object_name,
                               'module'      value o.module_code returning clob)
                   order by o.load_order returning clob)
          into l_missing
          from xxx_fv_objects o
         where o.is_enabled = 'Y'
           and not exists (select 1
                             from xxx_fv_files f
                            where f.batch_id = p_batch_id
                              and f.object_code = o.object_code);

        with vals as (
            select f.object_code, v.column_name, v.cell_value, count(*) as cnt,
                   row_number() over (partition by f.object_code, v.column_name
                                      order by count(*) desc, v.cell_value) as rn,
                   count(*) over (partition by f.object_code, v.column_name) as distinct_cnt
              from xxx_fv_stage_values v
              join xxx_fv_files f
                on f.file_id = v.file_id
             where f.batch_id = p_batch_id
             group by f.object_code, v.column_name, v.cell_value),
        tops as (
            select vals.object_code, vals.column_name,
                   json_arrayagg(json_object('value' value vals.cell_value, 'count' value vals.cnt)
                                 order by vals.rn returning clob) as top_values
              from vals
              join xxx_fv_columns c
                on c.object_code = vals.object_code
               and c.column_name = vals.column_name
             where vals.rn <= 8
               and vals.distinct_cnt <= 15
               and c.is_sensitive = 'N'
             group by vals.object_code, vals.column_name),
        obj_rows as (
            select f.object_code, sum(nvl(f.row_count, 0)) as total_rows
              from xxx_fv_files f
             where f.batch_id = p_batch_id
               and f.object_code is not null
             group by f.object_code),
        prof as (
            select f.object_code, c.column_name, c.column_seq, c.data_type, c.is_sensitive,
                   count(v.cell_value) as filled,
                   count(distinct v.cell_value) as distinct_cnt,
                   sum(case when c.data_type = 'NUMBER'
                            then to_number(v.cell_value default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') end) as num_sum,
                   min(case when c.data_type = 'NUMBER'
                            then to_number(v.cell_value default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') end) as num_min,
                   max(case when c.data_type = 'NUMBER'
                            then to_number(v.cell_value default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') end) as num_max,
                   min(case when c.data_type = 'DATE'
                            then to_date(v.cell_value default null on conversion error, 'YYYY-MM-DD') end) as date_min,
                   max(case when c.data_type = 'DATE'
                            then to_date(v.cell_value default null on conversion error, 'YYYY-MM-DD') end) as date_max
              from xxx_fv_files f
              join xxx_fv_columns c
                on c.object_code = f.object_code
              left join xxx_fv_stage_values v
                on v.file_id = f.file_id
               and v.column_name = c.column_name
             where f.batch_id = p_batch_id
             group by f.object_code, c.column_name, c.column_seq, c.data_type, c.is_sensitive)
        select json_arrayagg(
                   json_object(
                       'object_code' value p.object_code,
                       'column'      value p.column_name,
                       'type'        value p.data_type,
                       'rows'        value r.total_rows,
                       'filled'      value p.filled,
                       'fill_pct'    value round(100 * p.filled / nullif(r.total_rows, 0), 1),
                       'distinct'    value p.distinct_cnt,
                       'sum'         value case when p.is_sensitive = 'N' then p.num_sum end,
                       'min'         value case when p.is_sensitive = 'N'
                                                then coalesce(to_char(p.num_min), to_char(p.date_min, 'YYYY-MM-DD')) end,
                       'max'         value case when p.is_sensitive = 'N'
                                                then coalesce(to_char(p.num_max), to_char(p.date_max, 'YYYY-MM-DD')) end,
                       'top_values'  value t.top_values format json
                       absent on null returning clob)
                   order by p.object_code, p.column_seq returning clob)
          into l_profile
          from prof p
          join obj_rows r
            on r.object_code = p.object_code
          left join tops t
            on t.object_code = p.object_code
           and t.column_name = p.column_name;

        with grp as (
            select i.object_code, i.rule_code, i.severity, i.column_name, count(*) as cnt
              from xxx_fv_issues i
             where i.batch_id = p_batch_id
             group by i.object_code, i.rule_code, i.severity, i.column_name),
        ex as (
            select i.object_code, i.rule_code, i.column_name, i.line_number, i.bad_value, i.message,
                   row_number() over (partition by i.object_code, i.rule_code, i.column_name
                                      order by i.line_number, i.issue_id) as rn
              from xxx_fv_issues i
             where i.batch_id = p_batch_id),
        exa as (
            select ex.object_code, ex.rule_code, ex.column_name,
                   json_arrayagg(json_object('line'    value ex.line_number,
                                             'value'   value ex.bad_value,
                                             'message' value ex.message absent on null)
                                 order by ex.rn returning clob) as examples
              from ex
             where ex.rn <= 3
             group by ex.object_code, ex.rule_code, ex.column_name)
        select json_arrayagg(
                   json_object(
                       'object_code' value g.object_code,
                       'rule_code'   value g.rule_code,
                       'rule_title'  value r.title,
                       'severity'    value g.severity,
                       'column'      value g.column_name,
                       'count'       value g.cnt,
                       'fix_hint'    value r.fix_hint,
                       'examples'    value e.examples format json
                       absent on null returning clob)
                   order by decode(g.severity, 'ERROR', 1, 'WARNING', 2, 3), g.cnt desc, g.rule_code
                   returning clob)
          into l_issues
          from grp g
          join xxx_fv_rules r
            on r.rule_code = g.rule_code
          left join exa e
            on decode(e.object_code, g.object_code, 1, 0) = 1
           and e.rule_code = g.rule_code
           and decode(e.column_name, g.column_name, 1, 0) = 1;

        select json_arrayagg(
                   json_object('rule_code'     value rr.rule_code,
                               'title'         value ru.title,
                               'label'         value rr.recon_label,
                               'currency'      value rr.currency_code,
                               'source_total'  value rr.source_total,
                               'target_total'  value rr.target_total,
                               'difference'    value rr.difference,
                               'status'        value rr.status_code
                               absent on null returning clob)
                   order by ru.run_order, rr.recon_label returning clob)
          into l_recon
          from xxx_fv_recon_results rr
          join xxx_fv_rules ru
            on ru.rule_code = rr.rule_code
         where rr.batch_id = p_batch_id;

        select json_object(
                   'batch' value json_object(
                       'batch_name'         value b.batch_name,
                       'client'             value b.client_name,
                       'target_environment' value b.target_env,
                       'cutover_date'       value to_char(b.cutover_date, 'YYYY-MM-DD'),
                       'data_lines'         value b.line_count,
                       'errors'             value b.error_count,
                       'warnings'           value b.warning_count,
                       'info'               value b.info_count,
                       'readiness_score'    value b.readiness_score,
                       'readiness_status'   value b.readiness_status
                       absent on null),
                   'files'           value l_files   format json,
                   'missing_objects' value l_missing format json,
                   'column_profile'  value l_profile format json,
                   'issue_summary'   value l_issues  format json,
                   'reconciliations' value l_recon   format json
                   absent on null returning clob)
          into l_json
          from xxx_fv_batches b
         where b.batch_id = p_batch_id;

        return l_json;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_batch_not_found, 'Batch ' || p_batch_id || ' not found.');
    end get_batch_context;

    -- -------------------------------------------------------------------------
    function get_mapping_context (p_file_id in xxx_fv_files.file_id%type) return clob is
        l_json clob;
    begin
        select json_object(
                   'object_code' value o.object_code,
                   'object_name' value o.object_name,
                   'fusion_target' value o.fusion_target,
                   'target_columns' value (
                       select json_arrayagg(
                                  json_object(
                                      'column'      value c.column_name,
                                      'type'        value c.data_type,
                                      'required'    value c.is_required,
                                      'description' value c.description,
                                      'format'      value nvl(c.pattern_hint, c.date_format),
                                      'allowed'     value (select json_arrayagg(cv.allowed_value order by cv.allowed_value returning clob)
                                                             from xxx_fv_column_values cv
                                                            where cv.object_code = c.object_code
                                                              and cv.column_name = c.column_name) format json
                                      absent on null returning clob)
                                  order by c.column_seq returning clob)
                         from xxx_fv_columns c
                        where c.object_code = o.object_code) format json,
                   'already_mapped' value (
                       select json_arrayagg(fc.mapped_column order by fc.column_position returning clob)
                         from xxx_fv_file_columns fc
                        where fc.file_id = f.file_id
                          and fc.mapped_column is not null) format json,
                   'unmapped_headers' value (
                       select json_arrayagg(
                                  json_object('column_position' value fc.column_position,
                                              'header'          value fc.file_header,
                                              'sample_shape'    value fc.sample_shape
                                              absent on null returning clob)
                                  order by fc.column_position returning clob)
                         from xxx_fv_file_columns fc
                        where fc.file_id = f.file_id
                          and fc.mapped_column is null) format json
                   absent on null returning clob)
          into l_json
          from xxx_fv_files f
          join xxx_fv_objects o
            on o.object_code = f.object_code
         where f.file_id = p_file_id;
        return l_json;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found,
                'File ' || p_file_id || ' not found or has no object assigned.');
    end get_mapping_context;

    -- =========================================================================
    -- Status-code APIs
    -- =========================================================================
    procedure generate_batch_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_started  timestamp := systimestamp;
        l_context  clob;
        l_response clob;
        l_error    varchar2(4000);
    begin
        savepoint ai_report_sp;

        l_context  := get_batch_context(p_batch_id);
        l_response := call_ai(
                          p_system_prompt => report_system_prompt(p_language),
                          p_prompt        => 'Validation run context (JSON). Write the report from these facts only.'
                                             || chr(10) || l_context,
                          p_schema        => c_report_schema);

        save_report(p_batch_id, null, xxx_fv_const_pkg.c_report_batch, p_language,
                    xxx_fv_const_pkg.c_ai_completed, l_context, l_response, null,
                    elapsed_ms(l_started), p_user, x_report_id);
        x_return_status := 'S';
    exception
        when others then
            l_error := sqlerrm;
            rollback to ai_report_sp;
            xxx_fv_log_pkg.error('xxx_fv_ai_pkg.generate_batch_report', 'batch ' || p_batch_id);
            save_report(p_batch_id, null, xxx_fv_const_pkg.c_report_batch, nvl(p_language, xxx_fv_const_pkg.c_lang_en),
                        xxx_fv_const_pkg.c_ai_failed, l_context, null, l_error,
                        elapsed_ms(l_started), p_user, x_report_id);
            x_return_status := 'E';
            x_message       := l_error;
    end generate_batch_report;

    -- -------------------------------------------------------------------------
    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_started  timestamp := systimestamp;
        l_batch_id xxx_fv_files.batch_id%type;
        l_context  clob;
        l_response clob;
        l_error    varchar2(4000);
    begin
        savepoint ai_mapping_sp;

        select batch_id into l_batch_id from xxx_fv_files where file_id = p_file_id;

        l_context  := get_mapping_context(p_file_id);
        l_response := call_ai(
                          p_system_prompt => mapping_system_prompt,
                          p_prompt        => 'Map the unmapped headers.' || chr(10) || l_context,
                          p_schema        => c_mapping_schema);

        merge into xxx_fv_file_columns fc
        using (select s.column_position, s.target_column, s.confidence, s.reason
                 from (select j.column_position,
                              upper(trim(j.target_column)) as target_column,
                              least(1, greatest(0, round(j.confidence, 2))) as confidence,
                              substr(j.reason, 1, 400) as reason,
                              row_number() over (partition by upper(trim(j.target_column))
                                                 order by j.confidence desc, j.column_position) as rn
                         from json_table(l_response, '$.mappings[*]'
                                  columns (column_position number         path '$.column_position',
                                           target_column   varchar2(100)  path '$.target_column',
                                           confidence      number         path '$.confidence',
                                           reason          varchar2(1000) path '$.reason')) j
                        where j.confidence >= 0.5
                          and trim(j.target_column) is not null) s
                 join xxx_fv_files f
                   on f.file_id = p_file_id
                 join xxx_fv_columns c
                   on c.object_code = f.object_code
                  and c.column_name = s.target_column
                where s.rn = 1
                  and not exists (select 1
                                    from xxx_fv_file_columns x
                                   where x.file_id = p_file_id
                                     and x.mapped_column = s.target_column)) src
           on (fc.file_id = p_file_id and fc.column_position = src.column_position)
         when matched then update
              set fc.mapped_column  = src.target_column,
                  fc.mapping_source = xxx_fv_const_pkg.c_map_ai,
                  fc.ai_confidence  = src.confidence,
                  fc.ai_reason      = src.reason
            where fc.mapped_column is null;

        save_report(l_batch_id, p_file_id, xxx_fv_const_pkg.c_report_mapping, xxx_fv_const_pkg.c_lang_en,
                    xxx_fv_const_pkg.c_ai_completed, l_context, l_response, null,
                    elapsed_ms(l_started), p_user, x_report_id);
        x_return_status := 'S';
    exception
        when others then
            l_error := sqlerrm;
            rollback to ai_mapping_sp;
            xxx_fv_log_pkg.error('xxx_fv_ai_pkg.suggest_mapping', 'file ' || p_file_id);
            if l_batch_id is not null then
                save_report(l_batch_id, p_file_id, xxx_fv_const_pkg.c_report_mapping, xxx_fv_const_pkg.c_lang_en,
                            xxx_fv_const_pkg.c_ai_failed, l_context, null, l_error,
                            elapsed_ms(l_started), p_user, x_report_id);
            end if;
            x_return_status := 'E';
            x_message       := l_error;
    end suggest_mapping;

end xxx_fv_ai_pkg;
/
