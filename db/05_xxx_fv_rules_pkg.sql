-- =============================================================================
-- XXX_FV_RULES_PKG  (core / business layer)
-- Validation engine over staging. Pure SQL/PLSQL: no APEX, no HTTP, no session reads
-- (CA-01, CA-11). Built-in checks are set-based SQL (CON-03); client-specific checks
-- are plug-in rows in xxx_fv_rules (microkernel, SAP-05). Collects every issue in one
-- run instead of stopping at the first (RTP-13). Never commits (CON-12).
-- =============================================================================

create or replace package xxx_fv_rules_pkg authid definer as

    type t_readiness is record (
        line_count      number,
        error_count     number,
        warning_count   number,
        info_count      number,
        readiness_score number,
        readiness_status varchar2(30));

    -- Deletes previous results for the batch and runs every enabled rule. Idempotent.
    procedure run_all (p_batch_id in xxx_fv_batches.batch_id%type);

    -- Score and status from the current results (deterministic; the AI only explains it).
    function get_readiness (p_batch_id in xxx_fv_batches.batch_id%type) return t_readiness;

    -- Admin "Test rule": raises if the rule SQL is unsafe, does not parse, or lacks the
    -- columns its rule type needs.
    procedure check_rule_sql (p_rule_code in xxx_fv_rules.rule_code%type);

end xxx_fv_rules_pkg;
/

create or replace package body xxx_fv_rules_pkg as

    c_amount_mask constant varchar2(30) := 'FM999,999,999,999,990.00';

    -- -------------------------------------------------------------------------
    procedure clear_results (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        delete from xxx_fv_issues        where batch_id = p_batch_id;
        delete from xxx_fv_recon_results where batch_id = p_batch_id;
    end clear_results;

    -- -------------------------------------------------------------------------
    -- File-level checks: unknown sheets, missing/unmapped columns, empty files,
    -- objects with no file at all.
    procedure run_file_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        insert into xxx_fv_issues (batch_id, file_id, rule_code, severity, message)
        select f.batch_id, f.file_id, r.rule_code, r.severity,
               'Sheet/file "' || coalesce(f.sheet_display_name, d.file_name) || '" in ' || d.file_name
               || ' does not match any migration object. Assign an object or remove it.'
          from xxx_fv_files f
          join xxx_fv_documents d
            on d.document_id = f.document_id
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_unknown_object
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and f.object_code is null;

        insert into xxx_fv_issues (batch_id, file_id, object_code, column_name, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, c.column_name, r.rule_code, r.severity,
               'Required column ' || c.column_name || ' is missing or not mapped.'
          from xxx_fv_files f
          join xxx_fv_columns c
            on c.object_code = f.object_code
           and c.is_required = 'Y'
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_missing_column
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and not exists (select 1
                             from xxx_fv_file_columns fc
                            where fc.file_id = f.file_id
                              and fc.mapped_column = c.column_name);

        insert into xxx_fv_issues (batch_id, file_id, object_code, column_name, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, substr(fc.file_header, 1, 200), r.rule_code, r.severity,
               'Column "' || fc.file_header || '" is not mapped to a Fusion field and will be ignored.'
          from xxx_fv_files f
          join xxx_fv_file_columns fc
            on fc.file_id = f.file_id
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_unmapped_column
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and f.object_code is not null
           and fc.mapped_column is null;

        insert into xxx_fv_issues (batch_id, file_id, object_code, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, r.rule_code, r.severity,
               'No data rows found for ' || f.object_code || '.'
          from xxx_fv_files f
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_empty_file
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and f.object_code is not null
           and not exists (select 1 from xxx_fv_stage_lines l where l.file_id = f.file_id);

        insert into xxx_fv_issues (batch_id, object_code, rule_code, severity, message)
        select p_batch_id, o.object_code, r.rule_code, r.severity,
               'No file provided for ' || o.object_name || ' (' || o.module_code || ').'
          from xxx_fv_objects o
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_object_missing
           and r.is_enabled = 'Y'
         where o.is_enabled = 'Y'
           and not exists (select 1
                             from xxx_fv_files f
                            where f.batch_id = p_batch_id
                              and f.object_code = o.object_code);
    end run_file_checks;

    -- -------------------------------------------------------------------------
    procedure run_required_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        -- only for mapped columns; an unmapped required column is reported once at file level
        insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, l.line_number, c.column_name, r.rule_code, r.severity,
               c.column_name || ' is required.'
          from xxx_fv_files f
          join xxx_fv_columns c
            on c.object_code = f.object_code
           and c.is_required = 'Y'
          join xxx_fv_file_columns fc
            on fc.file_id = f.file_id
           and fc.mapped_column = c.column_name
          join xxx_fv_stage_lines l
            on l.file_id = f.file_id
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_required
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and not exists (select 1
                             from xxx_fv_stage_values v
                            where v.file_id = l.file_id
                              and v.line_number = l.line_number
                              and v.column_name = c.column_name);
    end run_required_checks;

    -- -------------------------------------------------------------------------
    -- One pass over every non-empty cell: type, length, pattern, allowed list.
    -- The first failing check per cell is reported. Sensitive values are masked.
    procedure run_value_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name,
                                   rule_code, severity, message, bad_value)
        select x.batch_id, x.file_id, x.object_code, x.line_number, x.column_name,
               r.rule_code, r.severity,
               substr(case x.rule_code
                          when xxx_fv_const_pkg.c_rule_number then
                              'Not a valid number: "' || x.shown_value || '". Use digits and "." only, no thousands separators.'
                          when xxx_fv_const_pkg.c_rule_date then
                              'Not a valid date for format ' || x.date_format || ': "' || x.shown_value || '".'
                          when xxx_fv_const_pkg.c_rule_max_length then
                              'Too long: ' || length(x.cell_value) || ' characters (max ' || x.max_length || ').'
                          when xxx_fv_const_pkg.c_rule_pattern then
                              'Invalid format: "' || x.shown_value || '". Expected: ' || nvl(x.pattern_hint, x.regex_pattern) || '.'
                          when xxx_fv_const_pkg.c_rule_allowed_value then
                              'Value "' || x.shown_value || '" is not allowed. Allowed: '
                              || (select listagg(cv.allowed_value, ', ') within group (order by cv.allowed_value)
                                    from xxx_fv_column_values cv
                                   where cv.object_code = x.object_code
                                     and cv.column_name = x.column_name) || '.'
                      end, 1, 1000),
               substr(x.shown_value, 1, 400)
          from (select f.batch_id, f.file_id, f.object_code, v.line_number, v.column_name, v.cell_value,
                       c.date_format, c.max_length, c.regex_pattern, c.pattern_hint,
                       case when c.is_sensitive = 'Y'
                            then lpad(substr(v.cell_value, -4), length(v.cell_value), '*')
                            else v.cell_value
                       end as shown_value,
                       case
                           when c.data_type = 'NUMBER'
                                and not regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$')
                               then xxx_fv_const_pkg.c_rule_number
                           when c.data_type = 'DATE'
                                and case c.date_format
                                        when 'YYYY-MM-DD'  then validate_conversion(v.cell_value as date, 'YYYY-MM-DD')
                                        when 'YYYY/MM/DD'  then validate_conversion(v.cell_value as date, 'YYYY/MM/DD')
                                        when 'DD-MON-YYYY' then validate_conversion(v.cell_value as date, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=ENGLISH')
                                    end = 0
                               then xxx_fv_const_pkg.c_rule_date
                           when c.max_length is not null
                                and length(v.cell_value) > c.max_length
                               then xxx_fv_const_pkg.c_rule_max_length
                           when c.regex_pattern is not null
                                and not regexp_like(v.cell_value, c.regex_pattern)
                               then xxx_fv_const_pkg.c_rule_pattern
                           when exists (select 1
                                          from xxx_fv_column_values cv
                                         where cv.object_code = c.object_code
                                           and cv.column_name = c.column_name)
                                and not exists (select 1
                                                  from xxx_fv_column_values cv
                                                 where cv.object_code = c.object_code
                                                   and cv.column_name = c.column_name
                                                   and cv.allowed_value = v.cell_value)
                               then xxx_fv_const_pkg.c_rule_allowed_value
                       end as rule_code
                  from xxx_fv_files f
                  join xxx_fv_stage_values v
                    on v.file_id = f.file_id
                  join xxx_fv_columns c
                    on c.object_code = f.object_code
                   and c.column_name = v.column_name
                 where f.batch_id = p_batch_id) x
          join xxx_fv_rules r
            on r.rule_code = x.rule_code
           and r.is_enabled = 'Y';
    end run_value_checks;

    -- -------------------------------------------------------------------------
    -- Duplicate business keys across all files of the same object in the batch.
    procedure run_duplicate_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name,
                                   rule_code, severity, message, bad_value)
        select d.batch_id, d.file_id, d.object_code, d.line_number, substr(d.key_columns, 1, 200),
               r.rule_code, r.severity,
               substr('Duplicate key ' || d.key_columns || ' = ' || d.key_shown
                      || ' appears ' || d.dup_count || ' times.', 1, 1000),
               substr(d.key_shown, 1, 400)
          from (select k.batch_id, k.file_id, k.object_code, k.line_number, k.key_columns, k.key_shown,
                       count(*) over (partition by k.object_code, k.key_value) as dup_count
                  from (select f.batch_id, f.file_id, f.object_code, l.line_number,
                               listagg(c.column_name, '+') within group (order by c.unique_key_seq) as key_columns,
                               listagg(nvl(v.cell_value, '<empty>'), ' | ') within group (order by c.unique_key_seq) as key_value,
                               -- sensitive key parts (bank account numbers) are masked for display
                               listagg(nvl(case when c.is_sensitive = 'Y'
                                                then lpad(substr(v.cell_value, -4), length(v.cell_value), '*')
                                                else v.cell_value
                                           end, '<empty>'), ' | ') within group (order by c.unique_key_seq) as key_shown
                          from xxx_fv_files f
                          join xxx_fv_columns c
                            on c.object_code = f.object_code
                           and c.unique_key_seq is not null
                          join xxx_fv_stage_lines l
                            on l.file_id = f.file_id
                          left join xxx_fv_stage_values v
                            on v.file_id = l.file_id
                           and v.line_number = l.line_number
                           and v.column_name = c.column_name
                         where f.batch_id = p_batch_id
                         group by f.batch_id, f.file_id, f.object_code, l.line_number) k) d
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_duplicate_key
           and r.is_enabled = 'Y'
         where d.dup_count > 1;
    end run_duplicate_checks;

    -- -------------------------------------------------------------------------
    -- Rule SQL is admin configuration (code, not values). Values stay bound (CON-01);
    -- the text is screened here and only admins can edit rules (APEX authorization).
    procedure assert_safe_sql (p_rule_code in varchar2, p_sql in clob) is
        l_sql clob := lower(p_sql);
    begin
        if not regexp_like(l_sql, '^\s*(select|with)\s')
           or instr(l_sql, ';') > 0
           or regexp_like(l_sql, 'for\s+update')
           or regexp_like(l_sql, '(^|[^a-z0-9_$#])(dbms_|utl_|apex_|htp\.|owa_|sys\.)')
        then
            raise_application_error(xxx_fv_const_pkg.c_err_unsafe_rule_sql,
                'Rule ' || p_rule_code || ': SQL must be one SELECT/WITH query, without ";", '
                || 'FOR UPDATE, or calls to DBMS_/UTL_/APEX_/SYS packages.');
        end if;
    end assert_safe_sql;

    -- -------------------------------------------------------------------------
    procedure run_row_rule (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_rule      in xxx_fv_rules%rowtype)
    is
    begin
        execute immediate
               'insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name, '
            || '                           rule_code, severity, message, bad_value) '
            || 'with b as (select :batch_id as batch_id from dual) '
            || 'select :batch_id2, x.file_id, coalesce(:object_code, f.object_code), x.line_number, '
            || '       substr(x.column_name, 1, 200), :rule_code, :severity, '
            || '       substr(x.message, 1, 1000), substr(x.bad_value, 1, 400) '
            || '  from (' || p_rule.rule_sql || ') x '
            || '  left join xxx_fv_files f on f.file_id = x.file_id'
            using p_batch_id, p_batch_id, p_rule.object_code, p_rule.rule_code, p_rule.severity;
    end run_row_rule;

    -- -------------------------------------------------------------------------
    procedure run_recon_rule (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_rule      in xxx_fv_rules%rowtype)
    is
    begin
        execute immediate
               'insert into xxx_fv_recon_results (batch_id, rule_code, recon_label, currency_code, '
            || '                                  source_total, target_total, difference, status_code) '
            || 'with b as (select :batch_id as batch_id from dual) '
            || 'select :batch_id2, :rule_code, substr(x.recon_label, 1, 200), x.currency_code, '
            || '       x.source_total, x.target_total, '
            || '       nvl(x.source_total, 0) - nvl(x.target_total, 0), '
            || '       case when abs(nvl(x.source_total, 0) - nvl(x.target_total, 0)) <= :tolerance '
            || '            then :matched else :diff end '
            || '  from (' || p_rule.rule_sql || ') x'
            using p_batch_id, p_batch_id, p_rule.rule_code, p_rule.tolerance,
                  xxx_fv_const_pkg.c_recon_matched, xxx_fv_const_pkg.c_recon_diff;

        insert into xxx_fv_issues (batch_id, object_code, rule_code, severity, message)
        select rr.batch_id, p_rule.object_code, rr.rule_code, p_rule.severity,
               substr(rr.recon_label || ' [' || nvl(rr.currency_code, '-') || ']: source '
                      || to_char(rr.source_total, c_amount_mask) || ' vs target '
                      || to_char(rr.target_total, c_amount_mask) || ', difference '
                      || to_char(rr.difference, c_amount_mask) || '.', 1, 1000)
          from xxx_fv_recon_results rr
         where rr.batch_id = p_batch_id
           and rr.rule_code = p_rule.rule_code
           and rr.status_code = xxx_fv_const_pkg.c_recon_diff;
    end run_recon_rule;

    -- -------------------------------------------------------------------------
    procedure run_custom_rules (p_batch_id in xxx_fv_batches.batch_id%type) is
        l_rule xxx_fv_rules%rowtype;
    begin
        -- one statement per configured rule: a loop is inherent to plug-in rules (CON-03)
        for r in (select ru.rule_code
                    from xxx_fv_rules ru
                   where ru.rule_type in (xxx_fv_const_pkg.c_rule_type_row_sql, xxx_fv_const_pkg.c_rule_type_recon)
                     and ru.is_enabled = 'Y'
                     and (ru.object_code is null
                          or exists (select 1
                                       from xxx_fv_files f
                                      where f.batch_id = p_batch_id
                                        and f.object_code = ru.object_code))
                   order by ru.run_order, ru.rule_code)
        loop
            select * into l_rule from xxx_fv_rules where rule_code = r.rule_code;
            assert_safe_sql(l_rule.rule_code, l_rule.rule_sql);
            if l_rule.rule_type = xxx_fv_const_pkg.c_rule_type_row_sql then
                run_row_rule(p_batch_id, l_rule);
            else
                run_recon_rule(p_batch_id, l_rule);
            end if;
        end loop;
    end run_custom_rules;

    -- -------------------------------------------------------------------------
    procedure run_all (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        clear_results(p_batch_id);
        run_file_checks(p_batch_id);
        run_required_checks(p_batch_id);
        run_value_checks(p_batch_id);
        run_duplicate_checks(p_batch_id);
        run_custom_rules(p_batch_id);
    end run_all;

    -- -------------------------------------------------------------------------
    -- Score = % of data lines with no ERROR, minus 5 points per batch/file-level
    -- ERROR (missing columns, failed reconciliations, ...), floored at 0.
    function get_readiness (p_batch_id in xxx_fv_batches.batch_id%type) return t_readiness is
        l_r            t_readiness;
        l_error_lines  number;
        l_level_errors number;
    begin
        select count(*)
          into l_r.line_count
          from xxx_fv_stage_lines l
          join xxx_fv_files f
            on f.file_id = l.file_id
         where f.batch_id = p_batch_id;

        select count(case when i.severity = xxx_fv_const_pkg.c_sev_error   then 1 end),
               count(case when i.severity = xxx_fv_const_pkg.c_sev_warning then 1 end),
               count(case when i.severity = xxx_fv_const_pkg.c_sev_info    then 1 end),
               count(distinct case when i.severity = xxx_fv_const_pkg.c_sev_error and i.line_number is not null
                                   then i.file_id || ':' || i.line_number end),
               count(case when i.severity = xxx_fv_const_pkg.c_sev_error and i.line_number is null then 1 end)
          into l_r.error_count, l_r.warning_count, l_r.info_count, l_error_lines, l_level_errors
          from xxx_fv_issues i
         where i.batch_id = p_batch_id;

        l_r.readiness_score :=
            case when l_r.line_count = 0 then 0
                 else greatest(0, round(100 * (l_r.line_count - l_error_lines) / l_r.line_count) - 5 * l_level_errors)
            end;

        l_r.readiness_status :=
            case when l_r.error_count > 0   then xxx_fv_const_pkg.c_not_ready
                 when l_r.warning_count > 0 then xxx_fv_const_pkg.c_ready_with_warnings
                 else xxx_fv_const_pkg.c_ready
            end;
        return l_r;
    end get_readiness;

    -- -------------------------------------------------------------------------
    procedure check_rule_sql (p_rule_code in xxx_fv_rules.rule_code%type) is
        l_rule     xxx_fv_rules%rowtype;
        l_cursor   integer;
        l_count    integer;
        l_desc     dbms_sql.desc_tab2;
        l_found    varchar2(4000) := ',';
        l_missing  varchar2(4000);
        l_required sys.odcivarchar2list;
    begin
        begin
            select * into l_rule from xxx_fv_rules where rule_code = p_rule_code;
        exception
            when no_data_found then
                raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter, 'Rule ' || p_rule_code || ' not found.');
        end;

        if l_rule.rule_type = xxx_fv_const_pkg.c_rule_type_column then
            return;   -- built-in rule, logic lives in this package
        end if;

        assert_safe_sql(l_rule.rule_code, l_rule.rule_sql);

        if l_rule.rule_type = xxx_fv_const_pkg.c_rule_type_row_sql then
            l_required := sys.odcivarchar2list('FILE_ID', 'LINE_NUMBER', 'COLUMN_NAME', 'BAD_VALUE', 'MESSAGE');
        else
            l_required := sys.odcivarchar2list('RECON_LABEL', 'CURRENCY_CODE', 'SOURCE_TOTAL', 'TARGET_TOTAL');
        end if;

        -- parse only (no execution) to get the select list
        l_cursor := dbms_sql.open_cursor;
        dbms_sql.parse(l_cursor,
                       'with b as (select 0 as batch_id from dual) select * from (' || l_rule.rule_sql || ') where 1 = 0',
                       dbms_sql.native);
        dbms_sql.describe_columns2(l_cursor, l_count, l_desc);
        dbms_sql.close_cursor(l_cursor);

        for i in 1 .. l_count loop
            l_found := l_found || upper(l_desc(i).col_name) || ',';
        end loop;

        for i in 1 .. l_required.count loop
            if instr(l_found, ',' || l_required(i) || ',') = 0 then
                l_missing := l_missing || ' ' || l_required(i);
            end if;
        end loop;

        if l_missing is not null then
            raise_application_error(xxx_fv_const_pkg.c_err_rule_sql_columns,
                'Rule ' || p_rule_code || ': the query must return the columns' || l_missing || '.');
        end if;
    exception
        when others then
            if l_cursor is not null and dbms_sql.is_open(l_cursor) then
                dbms_sql.close_cursor(l_cursor);
            end if;
            raise;
    end check_rule_sql;

end xxx_fv_rules_pkg;
/
