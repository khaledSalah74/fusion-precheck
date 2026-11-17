# XXX_FV Pre-Fusion Data Validation: APEX 26.1 app spec

This is the build spec for the APEX app. The database layer in `db/` already exists. Every page process calls **one** procedure in `xxx_fv_batch_api`, and there is no business SQL in the pages.

App name: **Fusion Data Readiness**. Theme: Universal Theme (Redwood Light, or the 26.1 Iris style). Authentication: APEX accounts for the demo.

## 0. One-time setup (done by hand in the builder)

1. **Generative AI Service.** Go to Workspace Utilities → Generative AI Services → Create.
   - AI Provider: **Anthropic Claude**
   - Name: `Claude`, Static ID: **`CLAUDE`** (this must match `xxx_fv_const_pkg.c_ai_service_static_id`)
   - Model: a current Claude model, for example `claude-sonnet-5-5`
   - Credential: a new Web Credential holding the Anthropic API key. Never put the key in code.
   - Runtime controls: Maximum AI Tokens **8000**, Server Timeout **180** seconds.
   - Click **Test Connection**.
2. **App AI attributes.** Go to App → Shared Components → AI Attributes → Service = `CLAUDE`. This also enables Natural Language for the Issues Interactive Report.
3. **AI Agent for chat.** Go to Shared Components → AI Agents → Create.
   - Static ID `fv_batch_analyst`, Service: Application Default.
   - System prompt:
     > You answer questions about one pre-Fusion data migration validation batch for Oracle Fusion Cloud ERP. The batch facts are in the JSON context supplied with this conversation. Answer only from those facts and quote counts and amounts exactly. If the answer is not in the facts, say so and point the user to the Results or AI Report page. Reply in the language the user writes in (Arabic or English). Keep object codes, rule codes and column names in English.
   - Tool: Execution Point **Augment System Prompt**, Type **Function Body**:
     ```sql
     return xxx_fv_ai_pkg.get_batch_context(:P40_BATCH_ID);
     ```
4. **Authorization schemes.**
   - `FV_USER`: any authenticated user.
   - `FV_ADMIN`: an APEX ACL role `ADMIN`. Admin pages and the rule editor need `FV_ADMIN` (PLT-02).
5. Session State Protection is on. Every page item that holds an ID (`P10_BATCH_ID` and the others) is set to **Checksum Required – Session Level**.

## 1. Navigation

Side menu: Batches (1), Admin › Objects (90), Columns (91), Rules (92), Error Log (93).

Pages 10, 20, 30 and 40 share a **Batch header** region and use a page-tab list: *Files & Mapping | Results | AI Report | Ask Claude*. Each of these pages has a `Pnn_BATCH_ID` item.

Batch header region (Classic Report, template "Content Row" or a Static Content with substitutions):
```sql
select b.batch_name, b.client_name, b.target_env, to_char(b.cutover_date, 'YYYY-MM-DD') cutover_date,
       s.status_name, b.readiness_score, b.readiness_status,
       b.line_count, b.error_count, b.warning_count, b.info_count,
       to_char(b.last_validated_on, 'YYYY-MM-DD HH24:MI') last_validated_on
  from xxx_fv_batches b
  join xxx_fv_batch_statuses s on s.status_code = b.status_code
 where b.batch_id = :P10_BATCH_ID
```
Show the readiness score as a badge with a color by status: NOT_READY red, READY_WITH_WARNINGS amber, READY green.

## 2. Pages

### Page 1: Batches (Cards)
```sql
select b.batch_id, b.batch_name, b.client_name, s.status_name,
       b.readiness_score, b.readiness_status, b.error_count, b.warning_count,
       to_char(b.cutover_date, 'YYYY-MM-DD') cutover_date
  from xxx_fv_batches b
  join xxx_fv_batch_statuses s on s.status_code = b.status_code
 order by b.created_on desc
```
- The card links to page 10 with `P10_BATCH_ID`.
- A **New batch** button opens page 2.

### Page 2: New Batch (modal)
- Items: `P2_BATCH_NAME` (required), `P2_CLIENT_NAME`, `P2_TARGET_ENV` (select list: DEV, TEST, UAT, PROD), `P2_CUTOVER_DATE` (date, required), and hidden `P2_BATCH_ID`.
- Process:
  ```sql
  xxx_fv_batch_api.create_batch(:P2_BATCH_NAME, :P2_CLIENT_NAME, :P2_TARGET_ENV,
                                to_date(:P2_CUTOVER_DATE, :APP_DATE_FORMAT), :APP_USER, :P2_BATCH_ID);
  ```
- Close the dialog, then branch to page 10 with `P10_BATCH_ID = &P2_BATCH_ID.`

### Page 10: Files & Mapping
- `P10_FILES`: File Upload item, multiple files allowed, Storage = Table APEX_APPLICATION_TEMP_FILES, file types `.xlsx,.csv`.
- **Upload** button → process:
  ```sql
  xxx_fv_batch_api.add_uploaded_files(:P10_BATCH_ID, :P10_FILES, :APP_USER);
  ```
- **Files** Interactive Report:
  ```sql
  select f.file_id, d.document_id, d.file_name, f.sheet_display_name, f.object_code, o.object_name,
         f.row_count,
         (select count(*) from xxx_fv_file_columns c where c.file_id = f.file_id and c.mapped_column is not null) mapped_cols,
         (select count(*) from xxx_fv_file_columns c where c.file_id = f.file_id and c.mapped_column is null) unmapped_cols,
         (select count(*) from xxx_fv_columns k
           where k.object_code = f.object_code and k.is_required = 'Y'
             and not exists (select 1 from xxx_fv_file_columns c
                              where c.file_id = f.file_id and c.mapped_column = k.column_name)) missing_required
    from xxx_fv_files f
    join xxx_fv_documents d on d.document_id = f.document_id
    left join xxx_fv_objects o on o.object_code = f.object_code
   where f.batch_id = :P10_BATCH_ID
   order by d.file_name, f.file_id
  ```
  - The `file_id` column links to page 11 (mapping).
  - A delete icon per document calls `xxx_fv_batch_api.remove_document(:P10_DOCUMENT_ID, :APP_USER)` after the user confirms.
  - Highlight rows where `object_code is null` or `missing_required > 0`.
- **Validate** button → process `xxx_fv_batch_api.validate_batch(:P10_BATCH_ID, :APP_USER);` then branch to page 20.
  - Optional: run it as an Execution Chain with *Run in Background* for large files, and show progress with `apex_background_process`.

### Page 11: Column Mapping (modal)
- `P11_FILE_ID` (hidden). `P11_OBJECT_CODE`: select list on `xxx_fv_objects`, enabled objects only. **Assign object** button →
  `xxx_fv_batch_api.assign_object(:P11_FILE_ID, :P11_OBJECT_CODE, :APP_USER);`
- **Mapping** Interactive Grid (editable: update only):
  ```sql
  select fc.file_id, fc.column_position, fc.file_header, fc.sample_shape,
         fc.mapped_column, fc.mapping_source, fc.ai_confidence, fc.ai_reason
    from xxx_fv_file_columns fc
   where fc.file_id = :P11_FILE_ID
   order by fc.column_position
  ```
  - `mapped_column` is a Select List with this LOV:
    ```sql
    select c.column_name || case when c.is_required = 'Y' then ' *' end d, c.column_name r
      from xxx_fv_columns c
      join xxx_fv_files f on f.object_code = c.object_code
     where f.file_id = :P11_FILE_ID
     order by c.column_seq
    ```
  - Make every column except `mapped_column` read only. Show the `mapping_source` badge: AUTO grey, AI purple, USER blue. Show `ai_confidence` as a percentage.
  - Target type: **PL/SQL Code** (instead of automatic DML):
    ```sql
    xxx_fv_batch_api.set_mapping(:FILE_ID, :COLUMN_POSITION, :MAPPED_COLUMN, :APP_USER);
    ```
- **Suggest with Claude** button → process:
  ```sql
  declare
      l_status varchar2(1);
      l_msg    varchar2(4000);
  begin
      xxx_fv_batch_api.suggest_mapping(:P11_FILE_ID, :APP_USER, l_status, l_msg);
      if l_status = 'E' then
          apex_error.add_error(p_message => 'Claude could not suggest a mapping: ' || l_msg,
                               p_display_location => apex_error.c_inline_in_notification);
      end if;
  end;
  ```
  The block is a few lines of UI glue only. Its success message is "Claude suggested mappings for the unmapped headers. Review them before validating."
- Region "Required columns still missing": a list of required columns of the object that are not mapped (the same subquery as on page 10).

### Page 20: Validation Results
- **Summary chart** (bar, stacked by severity):
  ```sql
  select nvl(i.object_code, 'BATCH') object_code, i.severity, count(*) issues
    from xxx_fv_issues i
   where i.batch_id = :P20_BATCH_ID
   group by nvl(i.object_code, 'BATCH'), i.severity
   order by 1
  ```
- **Reconciliations** Classic Report. Show `status_code` as a badge (MATCHED green, DIFF red), with the amounts right-aligned in format `999G999G999G990D00`:
  ```sql
  select ru.title, rr.recon_label, rr.currency_code, rr.source_total, rr.target_total, rr.difference, rr.status_code
    from xxx_fv_recon_results rr
    join xxx_fv_rules ru on ru.rule_code = rr.rule_code
   where rr.batch_id = :P20_BATCH_ID
   order by ru.run_order, rr.recon_label, rr.currency_code
  ```
- **Issues** Interactive Report. Turn on **AI › Natural Language** so users can type "errors in suppliers about VAT", and add saved reports for *Errors only* and *By rule*:
  ```sql
  select i.issue_id, i.severity, o.module_code, i.object_code, i.rule_code, r.title rule_title,
         i.line_number, i.column_name, i.bad_value, i.message, r.fix_hint,
         d.file_name, f.sheet_display_name, i.file_id
    from xxx_fv_issues i
    join xxx_fv_rules r on r.rule_code = i.rule_code
    left join xxx_fv_objects o on o.object_code = i.object_code
    left join xxx_fv_files f on f.file_id = i.file_id
    left join xxx_fv_documents d on d.document_id = f.document_id
   where i.batch_id = :P20_BATCH_ID
  ```
  The `line_number` column links to page 21 (row detail).
- Buttons: **Re-validate** (same process as page 10) and **Generate AI report** (go to page 30).

### Page 21: Row Detail (modal)
`P21_FILE_ID`, `P21_LINE_NUMBER`. The values report masks sensitive columns:
```sql
select c.column_seq, v.column_name,
       case when c.is_sensitive = 'Y' then lpad(substr(v.cell_value, -4), length(v.cell_value), '*') else v.cell_value end cell_value
  from xxx_fv_stage_values v
  join xxx_fv_files f on f.file_id = v.file_id
  join xxx_fv_columns c on c.object_code = f.object_code and c.column_name = v.column_name
 where v.file_id = :P21_FILE_ID and v.line_number = :P21_LINE_NUMBER
 order by c.column_seq
```
Add a second report with the issues for that line.

### Page 30: AI Report
- `P30_LANGUAGE`: radio group with **English** (EN) and **العربية** (AR), default EN.
- `P30_REPORT_ID`: computed before regions:
  ```sql
  select report_id from xxx_fv_ai_reports
   where batch_id = :P30_BATCH_ID and report_type = 'BATCH_REPORT' and status_code = 'COMPLETED'
   order by requested_on desc, report_id desc fetch first 1 row only
  ```
- **Generate with Claude** button. It is enabled when the batch status is VALIDATED or REPORTED. Process:
  ```sql
  declare
      l_status varchar2(1);
      l_msg    varchar2(4000);
  begin
      xxx_fv_batch_api.generate_ai_report(:P30_BATCH_ID, :P30_LANGUAGE, :APP_USER, :P30_REPORT_ID, l_status, l_msg);
      if l_status = 'E' then
          apex_error.add_error(p_message => 'Claude report failed: ' || l_msg,
                               p_display_location => apex_error.c_inline_in_notification);
      end if;
  end;
  ```
  Show a "Claude is analysing the batch…" spinner. A call takes about 20–60 seconds.
- When the report language is AR, add `dir="rtl"` and an Arabic font class to the report regions:
  ```sql
  select case language_code when 'AR' then 'u-rtl' end from xxx_fv_ai_reports where report_id = :P30_REPORT_ID
  ```
- **Executive summary** region. Show the readiness badge from the batch header next to `readiness_explanation`:
  ```sql
  select j.executive_summary, j.readiness_explanation
    from xxx_fv_ai_reports r
   cross apply json_table(r.response_json, '$' columns (
           executive_summary     varchar2(4000) path '$.executive_summary',
           readiness_explanation varchar2(4000) path '$.readiness_explanation')) j
   where r.report_id = :P30_REPORT_ID
  ```
- **Modules** Cards region. The badge is `status` (BLOCKED red, WARNING amber, OK green, NOT_PROVIDED grey). The body shows the summary, the findings and the actions as lists:
  ```sql
  select m.seq, m.module, m.object_code, m.status, m.summary,
         (select listagg('• ' || f.txt, chr(10)) within group (order by f.rn)
            from json_table(m.findings, '$[*]' columns (rn for ordinality, txt varchar2(1000) path '$')) f) key_findings,
         (select listagg('→ ' || a.txt, chr(10)) within group (order by a.rn)
            from json_table(m.actions, '$[*]' columns (rn for ordinality, txt varchar2(1000) path '$')) a) actions
    from xxx_fv_ai_reports r
   cross apply json_table(r.response_json, '$.modules[*]' columns (
           seq         for ordinality,
           module      varchar2(30)   path '$.module',
           object_code varchar2(30)   path '$.object_code',
           status      varchar2(20)   path '$.status',
           summary     varchar2(4000) path '$.summary',
           findings    varchar2(4000) format json path '$.key_findings',
           actions     varchar2(4000) format json path '$.actions')) m
   where r.report_id = :P30_REPORT_ID
   order by m.seq
  ```
- **Insights** Cards region (badge = impact):
  ```sql
  select i.seq, i.title, i.detail, i.evidence, i.impact
    from xxx_fv_ai_reports r
   cross apply json_table(r.response_json, '$.insights[*]' columns (
           seq for ordinality, title varchar2(400) path '$.title', detail varchar2(4000) path '$.detail',
           evidence varchar2(4000) path '$.evidence', impact varchar2(10) path '$.impact')) i
   where r.report_id = :P30_REPORT_ID
   order by decode(i.impact, 'HIGH', 1, 'MEDIUM', 2, 3), i.seq
  ```
- **Reconciliation comments**, **Top risks** and **Next steps** are list regions built the same way, on `$.reconciliation_comments[*]`, `$.top_risks[*]` and `$.next_steps[*]` (show the owner as a badge).
- **What Claude received** (a collapsed region, for transparency): the pretty-printed `context_json` and `elapsed_ms`.
  ```sql
  select json_serialize(context_json returning clob pretty) context_json, elapsed_ms, requested_by, requested_on
    from xxx_fv_ai_reports where report_id = :P30_REPORT_ID
  ```
- **History**: a classic report of every report for the batch (including FAILED ones with `error_message`). Clicking a row sets `P30_REPORT_ID`.

### Page 40: Ask Claude
- `P40_BATCH_ID`.
- A **Show AI Assistant** dynamic action on page load, display **Inline** in a region, with AI Agent `fv_batch_analyst`. The welcome message:
  > Ask me anything about this batch, for example: *Which supplier issues block the load?* or *لماذا لا يتطابق رصيد الموردين مع الأستاذ العام؟*
- Quick-action chips (buttons that send a prompt): "Top 5 blocking issues", "Explain the AP to GL difference", "What should the client fix first?", "لخص الوضع بالعربي".

### Admin pages (authorization FV_ADMIN)
- **90 Objects**: an IR plus form on `xxx_fv_objects`. Simple table edits are fine here because this is configuration (SAP-02 open layer).
- **91 Columns**: an IG on `xxx_fv_columns` filtered by an object select list, with child IGs for allowed values and aliases.
- **92 Rules**: an IR plus form on `xxx_fv_rules`.
  - `rule_sql` uses a Code Editor (SQL).
  - A **Test rule** button calls `xxx_fv_rules_pkg.check_rule_sql(:P92_RULE_CODE);` and shows "Rule SQL is valid" on success.
  - Help text: the query must reference the batch through `join b on b.batch_id = <view>.batch_id`. Row rules return `file_id, line_number, column_name, bad_value, message`. Reconciliations return `recon_label, currency_code, source_total, target_total`.
- **93 Error Log**: a read-only IR on `xxx_fv_error_log`, newest first.

## 3. Rules for the generated app
- No PL/SQL block in a page longer than the UI glue shown above (PLT-01, CA-08).
- Escaping stays on everywhere. AI text is displayed escaped, never as raw HTML (PLT-02).
- No `COMMIT` in page processes. APEX commits at the end of the request.
- All IDs come from page items with checksums. No `&ITEM.` substitution inside SQL; use bind variables (CON-01).
