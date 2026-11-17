-- =============================================================================
-- XXX_FV  shared services: named constants (CC-08) and the autonomous logger (CON-39)
-- =============================================================================

create or replace package xxx_fv_const_pkg authid definer as
    -- batch statuses (rows in xxx_fv_batch_statuses, moves in xxx_fv_status_transitions)
    c_status_new           constant varchar2(20) := 'NEW';
    c_status_files_loaded  constant varchar2(20) := 'FILES_LOADED';
    c_status_validated     constant varchar2(20) := 'VALIDATED';
    c_status_reported      constant varchar2(20) := 'REPORTED';

    -- severities
    c_sev_error            constant varchar2(10) := 'ERROR';
    c_sev_warning          constant varchar2(10) := 'WARNING';
    c_sev_info             constant varchar2(10) := 'INFO';

    -- rule types
    c_rule_type_column     constant varchar2(10) := 'COLUMN';
    c_rule_type_row_sql    constant varchar2(10) := 'ROW_SQL';
    c_rule_type_recon      constant varchar2(10) := 'RECON';

    -- built-in rule codes (rows in xxx_fv_rules, rule_type = COLUMN)
    c_rule_unknown_object  constant varchar2(40) := 'FILE_UNKNOWN_OBJECT';
    c_rule_missing_column  constant varchar2(40) := 'FILE_MISSING_COLUMN';
    c_rule_unmapped_column constant varchar2(40) := 'FILE_UNMAPPED_COLUMN';
    c_rule_empty_file      constant varchar2(40) := 'FILE_EMPTY';
    c_rule_object_missing  constant varchar2(40) := 'BATCH_OBJECT_MISSING';
    c_rule_required        constant varchar2(40) := 'COL_REQUIRED';
    c_rule_number          constant varchar2(40) := 'COL_NUMBER';
    c_rule_date            constant varchar2(40) := 'COL_DATE';
    c_rule_max_length      constant varchar2(40) := 'COL_MAX_LENGTH';
    c_rule_pattern         constant varchar2(40) := 'COL_PATTERN';
    c_rule_allowed_value   constant varchar2(40) := 'COL_ALLOWED_VALUE';
    c_rule_duplicate_key   constant varchar2(40) := 'COL_DUPLICATE_KEY';

    -- recon result status
    c_recon_matched        constant varchar2(10) := 'MATCHED';
    c_recon_diff           constant varchar2(10) := 'DIFF';

    -- readiness
    c_ready                constant varchar2(30) := 'READY';
    c_ready_with_warnings  constant varchar2(30) := 'READY_WITH_WARNINGS';
    c_not_ready            constant varchar2(30) := 'NOT_READY';

    -- column mapping sources
    c_map_auto             constant varchar2(10) := 'AUTO';
    c_map_ai               constant varchar2(10) := 'AI';
    c_map_user             constant varchar2(10) := 'USER';

    -- AI
    c_ai_service_static_id constant varchar2(255) := 'CLAUDE';   -- Workspace Utilities > Generative AI Services
    c_report_batch         constant varchar2(20)  := 'BATCH_REPORT';
    c_report_mapping       constant varchar2(20)  := 'MAPPING';
    c_report_chat          constant varchar2(20)  := 'CHAT';
    c_ai_completed         constant varchar2(20)  := 'COMPLETED';
    c_ai_failed            constant varchar2(20)  := 'FAILED';
    c_lang_en              constant varchar2(2)   := 'EN';
    c_lang_ar              constant varchar2(2)   := 'AR';

    -- parsing
    c_max_file_columns     constant pls_integer   := 60;     -- columns read per sheet/CSV

    -- error codes (CC-05): one registry
    c_err_invalid_transition constant pls_integer := -20101;
    c_err_batch_not_found    constant pls_integer := -20102;
    c_err_unsafe_rule_sql    constant pls_integer := -20103;
    c_err_rule_sql_columns   constant pls_integer := -20104;
    c_err_ai_response        constant pls_integer := -20105;
    c_err_file_not_found     constant pls_integer := -20106;
    c_err_bad_parameter      constant pls_integer := -20107;

    e_invalid_transition exception;
    pragma exception_init (e_invalid_transition, -20101);
    e_batch_not_found exception;
    pragma exception_init (e_batch_not_found, -20102);
    e_unsafe_rule_sql exception;
    pragma exception_init (e_unsafe_rule_sql, -20103);
    e_rule_sql_columns exception;
    pragma exception_init (e_rule_sql_columns, -20104);
    e_ai_response exception;
    pragma exception_init (e_ai_response, -20105);
    e_file_not_found exception;
    pragma exception_init (e_file_not_found, -20106);
    e_bad_parameter exception;
    pragma exception_init (e_bad_parameter, -20107);
end xxx_fv_const_pkg;
/

create or replace package xxx_fv_log_pkg authid definer as
    -- Records the current error with full stacks. Caller must RAISE afterwards (CON-30).
    procedure error (p_module in varchar2, p_key in varchar2 default null);
end xxx_fv_log_pkg;
/

create or replace package body xxx_fv_log_pkg as
    procedure error (p_module in varchar2, p_key in varchar2 default null) is
        pragma autonomous_transaction;   -- the only autonomous transaction in XXX_FV (CON-38)
    begin
        insert into xxx_fv_error_log (module, log_key, err_stack, backtrace, call_stack)
        values (substr(p_module, 1, 200),
                substr(p_key, 1, 200),
                substr(dbms_utility.format_error_stack, 1, 4000),
                substr(dbms_utility.format_error_backtrace, 1, 4000),
                substr(dbms_utility.format_call_stack, 1, 4000));
        commit;   -- commits only the log row
    end error;
end xxx_fv_log_pkg;
/
