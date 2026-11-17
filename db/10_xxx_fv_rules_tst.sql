-- =============================================================================
-- utPLSQL suite for the rules engine (EUT-01..10).
-- Each test builds only the data it needs on a private test object (ZZ_TEST_OBJ)
-- and is rolled back automatically. Built-in rule rows from 09_seed_rules.sql are
-- reference data the engine needs, so they must be installed.
-- Run:  exec ut.run('xxx_fv_rules_tst');
-- =============================================================================

create or replace package xxx_fv_rules_tst as
    --%suite(XXX_FV rules engine)
    --%rollback(auto)

    --%beforeeach
    procedure setup_config;

    --%test(Reports an empty required value on a mapped column)
    procedure required_value_missing_is_reported;

    --%test(Reports a number written with a thousands separator)
    procedure invalid_number_is_reported;

    --%test(Reports a value outside the allowed list, case sensitive)
    procedure value_outside_allowed_list_is_reported;

    --%test(Reports every copy of a duplicated business key)
    procedure duplicate_key_reports_every_copy;

    --%test(Re-running validation replaces previous results)
    procedure rerun_replaces_previous_results;

    --%test(Batch with an error is NOT_READY)
    procedure readiness_not_ready_when_errors;

    --%test(Rejects rule SQL with a second statement)
    --%throws(-20103)
    procedure unsafe_rule_sql_is_rejected;
end xxx_fv_rules_tst;
/

create or replace package body xxx_fv_rules_tst as

    c_obj constant varchar2(30) := 'ZZ_TEST_OBJ';

    -- ---------------------------------------------------------------- builders
    procedure setup_config is
    begin
        insert into xxx_fv_objects (object_code, module_code, object_name, load_order, is_enabled)
        values (c_obj, 'AP', 'Test object', 999, 'N');   -- disabled: not reported as missing elsewhere

        insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, is_required, unique_key_seq)
        values (c_obj, 'CODE', 10, 'VARCHAR2', 'Y', 1);
        insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, is_required)
        values (c_obj, 'AMOUNT', 20, 'NUMBER', 'N');
        insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, is_required)
        values (c_obj, 'STATUS', 30, 'VARCHAR2', 'N');
        insert into xxx_fv_column_values (object_code, column_name, allowed_value) values (c_obj, 'STATUS', 'OPEN');
        insert into xxx_fv_column_values (object_code, column_name, allowed_value) values (c_obj, 'STATUS', 'CLOSED');
    end setup_config;

    function new_batch return number is
        l_id number;
    begin
        insert into xxx_fv_batches (batch_name, cutover_date, status_code, created_by)
        values ('ut batch', date '2026-12-31', 'FILES_LOADED', 'UT')
        returning batch_id into l_id;
        return l_id;
    end new_batch;

    -- file with CODE, AMOUNT, STATUS mapped at positions 1..3
    function new_file (p_batch_id in number) return number is
        l_doc  number;
        l_file number;
    begin
        insert into xxx_fv_documents (batch_id, file_name, file_content, uploaded_by)
        values (p_batch_id, 'ut.csv', empty_blob(), 'UT')
        returning document_id into l_doc;

        insert into xxx_fv_files (batch_id, document_id, object_code)
        values (p_batch_id, l_doc, c_obj)
        returning file_id into l_file;

        insert into xxx_fv_file_columns (file_id, column_position, file_header, mapped_column, mapping_source)
        select l_file, rownum, column_value, column_value, 'AUTO'
          from table(sys.odcivarchar2list('CODE', 'AMOUNT', 'STATUS'));
        return l_file;
    end new_file;

    procedure add_line (
        p_file_id in number, p_line in number,
        p_code in varchar2, p_amount in varchar2 default null, p_status in varchar2 default null)
    is
    begin
        insert into xxx_fv_stage_lines (file_id, line_number) values (p_file_id, p_line);
        insert into xxx_fv_stage_values (file_id, line_number, column_name, cell_value)
        select p_file_id, p_line, c.name, c.val
          from (select 'CODE' as name, p_code as val from dual
                union all select 'AMOUNT', p_amount from dual
                union all select 'STATUS', p_status from dual) c
         where c.val is not null;
    end add_line;

    function issue_count (p_batch_id in number, p_rule_code in varchar2) return number is
        l_count number;
    begin
        select count(*)
          into l_count
          from xxx_fv_issues
         where batch_id = p_batch_id
           and rule_code = p_rule_code
           and object_code = c_obj;
        return l_count;
    end issue_count;

    -- ------------------------------------------------------------------- tests
    procedure required_value_missing_is_reported is
        l_batch number := new_batch;
        l_file  number := new_file(l_batch);
    begin
        add_line(l_file, 2, p_code => null, p_amount => '10');

        xxx_fv_rules_pkg.run_all(l_batch);

        ut.expect(issue_count(l_batch, 'COL_REQUIRED')).to_equal(1);
    end required_value_missing_is_reported;

    procedure invalid_number_is_reported is
        l_batch number := new_batch;
        l_file  number := new_file(l_batch);
    begin
        add_line(l_file, 2, p_code => 'A1', p_amount => '12,500.00');   -- thousands separator

        xxx_fv_rules_pkg.run_all(l_batch);

        ut.expect(issue_count(l_batch, 'COL_NUMBER')).to_equal(1);
    end invalid_number_is_reported;

    procedure value_outside_allowed_list_is_reported is
        l_batch number := new_batch;
        l_file  number := new_file(l_batch);
    begin
        add_line(l_file, 2, p_code => 'A1', p_status => 'Open');   -- allowed is OPEN

        xxx_fv_rules_pkg.run_all(l_batch);

        ut.expect(issue_count(l_batch, 'COL_ALLOWED_VALUE')).to_equal(1);
    end value_outside_allowed_list_is_reported;

    procedure duplicate_key_reports_every_copy is
        l_batch number := new_batch;
        l_file  number := new_file(l_batch);
    begin
        add_line(l_file, 2, p_code => 'A1');
        add_line(l_file, 3, p_code => 'A1');
        add_line(l_file, 4, p_code => 'B2');

        xxx_fv_rules_pkg.run_all(l_batch);

        ut.expect(issue_count(l_batch, 'COL_DUPLICATE_KEY')).to_equal(2);   -- lines 2 and 3
    end duplicate_key_reports_every_copy;

    procedure rerun_replaces_previous_results is
        l_batch number := new_batch;
        l_file  number := new_file(l_batch);
    begin
        add_line(l_file, 2, p_code => null);

        xxx_fv_rules_pkg.run_all(l_batch);
        xxx_fv_rules_pkg.run_all(l_batch);

        ut.expect(issue_count(l_batch, 'COL_REQUIRED')).to_equal(1);
    end rerun_replaces_previous_results;

    procedure readiness_not_ready_when_errors is
        l_batch number := new_batch;
        l_file  number := new_file(l_batch);
        l_r     xxx_fv_rules_pkg.t_readiness;
    begin
        add_line(l_file, 2, p_code => 'A1', p_amount => 'abc');
        add_line(l_file, 3, p_code => 'B2', p_amount => '5');

        xxx_fv_rules_pkg.run_all(l_batch);
        l_r := xxx_fv_rules_pkg.get_readiness(l_batch);

        ut.expect(l_r.readiness_status).to_equal('NOT_READY');
        ut.expect(l_r.line_count).to_equal(2);
    end readiness_not_ready_when_errors;

    procedure unsafe_rule_sql_is_rejected is
    begin
        insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, rule_sql)
        values ('ZZ_UNSAFE', 'ROW_SQL', c_obj, 'ERROR', 'unsafe',
                'select 1 file_id, 1 line_number, null column_name, null bad_value, null message from dual; delete from xxx_fv_batches');

        xxx_fv_rules_pkg.check_rule_sql('ZZ_UNSAFE');
    end unsafe_rule_sql_is_rejected;

end xxx_fv_rules_tst;
/
