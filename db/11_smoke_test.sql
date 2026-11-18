-- =============================================================================
-- XXX_FV  rules engine smoke test - no utPLSQL needed.
-- Builds its own test object and data, runs xxx_fv_rules_pkg.run_all, checks the
-- results, and ROLLS BACK everything at the end (nothing stays in the schema).
-- Run in SQLcl:  set serveroutput on   then   @db/11_smoke_test.sql
-- Expected last line: "SMOKE TEST PASSED (9 checks)"
-- =============================================================================
set serveroutput on
whenever sqlerror continue

declare
    c_obj    constant varchar2(30) := 'ZZ_SMOKE_OBJ';
    l_batch  number;
    l_doc    number;
    l_file   number;
    l_unk    number;
    l_checks pls_integer := 0;
    l_failed pls_integer := 0;
    l_r      xxx_fv_rules_pkg.t_readiness;

    procedure expect (p_name in varchar2, p_actual in number, p_expected in number) is
    begin
        l_checks := l_checks + 1;
        if p_actual = p_expected then
            dbms_output.put_line('PASS  ' || p_name);
        else
            l_failed := l_failed + 1;
            dbms_output.put_line('FAIL  ' || p_name || ': expected ' || p_expected || ', got ' || p_actual);
        end if;
    end expect;

    function issues (p_rule in varchar2) return number is
        l_n number;
    begin
        select count(*) into l_n
          from xxx_fv_issues
         where batch_id = l_batch and rule_code = p_rule and object_code = c_obj;
        return l_n;
    end issues;

    procedure line (p_line in number, p_code in varchar2, p_amount in varchar2, p_status in varchar2) is
    begin
        insert into xxx_fv_stage_lines (file_id, line_number) values (l_file, p_line);
        insert into xxx_fv_stage_values (file_id, line_number, column_name, cell_value)
        select l_file, p_line, x.col, x.val
          from (select 'CODE' col, p_code val from dual
                union all select 'AMOUNT', p_amount from dual
                union all select 'STATUS', p_status from dual) x
         where x.val is not null;
    end line;
begin
    savepoint smoke_start;

    -- private test configuration (disabled object so it never appears as "missing")
    insert into xxx_fv_objects (object_code, module_code, object_name, load_order, is_enabled)
    values (c_obj, 'AP', 'Smoke test object', 999, 'N');
    insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, is_required, unique_key_seq)
    values (c_obj, 'CODE', 10, 'VARCHAR2', 'Y', 1);
    insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, is_required)
    values (c_obj, 'AMOUNT', 20, 'NUMBER', 'N');
    insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, is_required)
    values (c_obj, 'STATUS', 30, 'VARCHAR2', 'N');
    insert into xxx_fv_column_values (object_code, column_name, allowed_value) values (c_obj, 'STATUS', 'OPEN');
    insert into xxx_fv_column_values (object_code, column_name, allowed_value) values (c_obj, 'STATUS', 'CLOSED');

    insert into xxx_fv_batches (batch_name, cutover_date, status_code, created_by)
    values ('smoke test', date '2026-12-31', 'FILES_LOADED', 'SMOKE')
    returning batch_id into l_batch;
    insert into xxx_fv_documents (batch_id, file_name, file_content, uploaded_by)
    values (l_batch, 'smoke.csv', empty_blob(), 'SMOKE')
    returning document_id into l_doc;
    insert into xxx_fv_files (batch_id, document_id, object_code)
    values (l_batch, l_doc, c_obj)
    returning file_id into l_file;
    insert into xxx_fv_file_columns (file_id, column_position, file_header, mapped_column, mapping_source)
    values (l_file, 1, 'CODE', 'CODE', 'AUTO');
    insert into xxx_fv_file_columns (file_id, column_position, file_header, mapped_column, mapping_source)
    values (l_file, 2, 'AMOUNT', 'AMOUNT', 'AUTO');
    insert into xxx_fv_file_columns (file_id, column_position, file_header, mapped_column, mapping_source)
    values (l_file, 3, 'STATUS', 'STATUS', 'AUTO');

    -- two sheets with no object: one ignored by the user, one not
    insert into xxx_fv_files (batch_id, document_id, sheet_display_name, sheet_file_name, object_code, is_ignored)
    values (l_batch, l_doc, 'Notes', 'sheet8.xml', null, 'Y');
    insert into xxx_fv_files (batch_id, document_id, sheet_display_name, sheet_file_name, object_code, is_ignored)
    values (l_batch, l_doc, 'Mystery', 'sheet9.xml', null, 'N');

    -- data: one problem per line, plus one clean line
    line(2, null,  '10',        'OPEN');     -- required CODE missing
    line(3, 'A1',  '12,500.00', 'OPEN');     -- invalid number
    line(4, 'A2',  '5',         'Open');     -- not in allowed list (case sensitive)
    line(5, 'D1',  '7',         'CLOSED');   -- duplicate key ...
    line(6, 'D1',  '8',         'CLOSED');   -- ... reported on both lines
    line(7, 'OK1', '99.5',      'OPEN');     -- clean

    xxx_fv_rules_pkg.run_all(l_batch);
    expect('COL_REQUIRED on empty CODE',         issues('COL_REQUIRED'), 1);
    expect('COL_NUMBER on 12,500.00',            issues('COL_NUMBER'), 1);
    expect('COL_ALLOWED_VALUE on "Open"',        issues('COL_ALLOWED_VALUE'), 1);
    expect('COL_DUPLICATE_KEY on both D1 lines', issues('COL_DUPLICATE_KEY'), 2);

    select count(*) into l_unk from xxx_fv_issues where batch_id = l_batch and rule_code = 'FILE_UNKNOWN_OBJECT';
    expect('FILE_UNKNOWN_OBJECT only for the sheet not ignored', l_unk, 1);
    select count(*) into l_unk
      from xxx_fv_issues i
      join xxx_fv_files f on f.file_id = i.file_id
     where i.batch_id = l_batch and f.is_ignored = 'Y';
    expect('no issues on the ignored sheet',      l_unk, 0);

    xxx_fv_rules_pkg.run_all(l_batch);           -- idempotent re-run
    expect('re-run does not duplicate issues',   issues('COL_REQUIRED'), 1);

    l_r := xxx_fv_rules_pkg.get_readiness(l_batch);
    expect('line_count = 6',                     l_r.line_count, 6);
    expect('status NOT_READY',                   case l_r.readiness_status when 'NOT_READY' then 1 else 0 end, 1);

    rollback to smoke_start;
    if l_failed = 0 then
        dbms_output.put_line('SMOKE TEST PASSED (' || l_checks || ' checks)');
    else
        dbms_output.put_line('SMOKE TEST FAILED: ' || l_failed || ' of ' || l_checks || ' checks');
    end if;
exception
    when others then
        rollback to smoke_start;
        dbms_output.put_line('SMOKE TEST ERROR: ' || sqlerrm);
        dbms_output.put_line(dbms_utility.format_error_backtrace);
        raise;
end;
/
