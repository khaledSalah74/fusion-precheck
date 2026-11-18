-- =============================================================================
-- XXX_FV  Pre-Fusion Data Validation - data model
-- Target : Oracle ATP (19c or 26ai), APEX 26.1, run as the workspace parsing schema
-- Layers : config (objects/columns/rules) -> batch & files -> staging -> results
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 1. Configuration: what each Fusion object must look like
-- -----------------------------------------------------------------------------
create table xxx_fv_objects (
    object_code     varchar2(30)   not null,
    module_code     varchar2(10)   not null,
    object_name     varchar2(100)  not null,
    sheet_alias     varchar2(60),
    fusion_target   varchar2(200),
    load_order      number(3)      not null,
    description     varchar2(1000),
    is_enabled      varchar2(1)    default 'Y' not null,
    constraint xxx_fv_objects_pk  primary key (object_code),
    constraint xxx_fv_objects_ck1 check (is_enabled in ('Y', 'N')),
    constraint xxx_fv_objects_ck2 check (module_code in ('GL', 'AP', 'AR', 'CE', 'PO', 'PR', 'FA', 'INV')),
    constraint xxx_fv_objects_ck3 check (regexp_like(object_code, '^[A-Z][A-Z0-9_]*$'))
);

create table xxx_fv_columns (
    object_code     varchar2(30)   not null,
    column_name     varchar2(60)   not null,
    column_seq      number(3)      not null,
    data_type       varchar2(10)   default 'VARCHAR2' not null,
    max_length      number(5),
    date_format     varchar2(20),
    is_required     varchar2(1)    default 'N' not null,
    unique_key_seq  number(2),
    regex_pattern   varchar2(400),
    pattern_hint    varchar2(200),
    is_sensitive    varchar2(1)    default 'N' not null,
    description     varchar2(500),
    constraint xxx_fv_columns_pk  primary key (object_code, column_name),
    constraint xxx_fv_columns_fk1 foreign key (object_code) references xxx_fv_objects (object_code),
    constraint xxx_fv_columns_ck1 check (data_type in ('VARCHAR2', 'NUMBER', 'DATE')),
    constraint xxx_fv_columns_ck2 check (date_format in ('YYYY-MM-DD', 'YYYY/MM/DD', 'DD-MON-YYYY')),
    constraint xxx_fv_columns_ck3 check (data_type <> 'DATE' or date_format is not null),
    constraint xxx_fv_columns_ck4 check (is_required in ('Y', 'N')),
    constraint xxx_fv_columns_ck5 check (is_sensitive in ('Y', 'N')),
    constraint xxx_fv_columns_ck6 check (regexp_like(column_name, '^[A-Z][A-Z0-9_]*$'))
);

create table xxx_fv_column_values (
    object_code     varchar2(30)   not null,
    column_name     varchar2(60)   not null,
    allowed_value   varchar2(200)  not null,
    meaning         varchar2(200),
    constraint xxx_fv_column_values_pk  primary key (object_code, column_name, allowed_value),
    constraint xxx_fv_column_values_fk1 foreign key (object_code, column_name)
        references xxx_fv_columns (object_code, column_name) on delete cascade
);

create table xxx_fv_column_aliases (
    object_code     varchar2(30)   not null,
    alias_norm      varchar2(100)  not null,
    column_name     varchar2(60)   not null,
    constraint xxx_fv_column_aliases_pk  primary key (object_code, alias_norm),
    constraint xxx_fv_column_aliases_fk1 foreign key (object_code, column_name)
        references xxx_fv_columns (object_code, column_name) on delete cascade,
    constraint xxx_fv_column_aliases_ck1 check (regexp_like(alias_norm, '^[A-Z0-9_]+$'))
);
create index xxx_fv_column_aliases_n1 on xxx_fv_column_aliases (object_code, column_name);

-- Rule catalogue.
--   COLUMN  : built-in checks run by xxx_fv_rules_pkg (code decides logic, row decides severity/on-off)
--   ROW_SQL : admin-written SELECT returning file_id, line_number, column_name, bad_value, message
--   RECON   : admin-written SELECT returning recon_label, currency_code, source_total, target_total
-- Rule SQL refers to the current batch through the CTE "b" (b.batch_id). No binds, no ';'.
create table xxx_fv_rules (
    rule_code       varchar2(40)   not null,
    rule_type       varchar2(10)   not null,
    object_code     varchar2(30),
    severity        varchar2(10)   not null,
    title           varchar2(200)  not null,
    fix_hint        varchar2(1000),
    rule_sql        clob,
    tolerance       number         default 0 not null,
    run_order       number(4)      default 100 not null,
    is_enabled      varchar2(1)    default 'Y' not null,
    constraint xxx_fv_rules_pk  primary key (rule_code),
    constraint xxx_fv_rules_fk1 foreign key (object_code) references xxx_fv_objects (object_code),
    constraint xxx_fv_rules_ck1 check (rule_type in ('COLUMN', 'ROW_SQL', 'RECON')),
    constraint xxx_fv_rules_ck2 check (severity in ('ERROR', 'WARNING', 'INFO')),
    constraint xxx_fv_rules_ck3 check (rule_type = 'COLUMN' or rule_sql is not null),
    constraint xxx_fv_rules_ck4 check (is_enabled in ('Y', 'N')),
    constraint xxx_fv_rules_ck5 check (tolerance >= 0)
);
create index xxx_fv_rules_n1 on xxx_fv_rules (object_code);

-- -----------------------------------------------------------------------------
-- 2. Batches and the single allowed-transition table (RTP-04)
-- -----------------------------------------------------------------------------
create table xxx_fv_batch_statuses (
    status_code     varchar2(20)   not null,
    status_name     varchar2(100)  not null,
    display_seq     number(3)      not null,
    constraint xxx_fv_batch_statuses_pk primary key (status_code)
);

create table xxx_fv_status_transitions (
    from_status     varchar2(20)   not null,
    to_status       varchar2(20)   not null,
    constraint xxx_fv_status_transitions_pk  primary key (from_status, to_status),
    constraint xxx_fv_status_transitions_fk1 foreign key (from_status) references xxx_fv_batch_statuses (status_code),
    constraint xxx_fv_status_transitions_fk2 foreign key (to_status)   references xxx_fv_batch_statuses (status_code)
);
create index xxx_fv_status_transitions_n1 on xxx_fv_status_transitions (to_status);

create table xxx_fv_batches (
    batch_id          number generated always as identity,
    batch_name        varchar2(200)  not null,
    client_name       varchar2(200),
    target_env        varchar2(100),
    cutover_date      date           not null,
    status_code       varchar2(20)   default 'NEW' not null,
    line_count        number         default 0 not null,
    error_count       number         default 0 not null,
    warning_count     number         default 0 not null,
    info_count        number         default 0 not null,
    readiness_score   number(3),
    readiness_status  varchar2(30),
    last_validated_on date,
    row_version       number         default 1 not null,
    created_by        varchar2(255)  not null,
    created_on        date           default sysdate not null,
    updated_by        varchar2(255),
    updated_on        date,
    constraint xxx_fv_batches_pk  primary key (batch_id),
    constraint xxx_fv_batches_fk1 foreign key (status_code) references xxx_fv_batch_statuses (status_code),
    constraint xxx_fv_batches_ck1 check (readiness_status in ('READY', 'READY_WITH_WARNINGS', 'NOT_READY')),
    constraint xxx_fv_batches_ck2 check (readiness_score between 0 and 100)
);
create index xxx_fv_batches_n1 on xxx_fv_batches (status_code);

-- -----------------------------------------------------------------------------
-- 3. Uploaded documents and the files (CSV, or one row per XLSX sheet) inside them
-- -----------------------------------------------------------------------------
create table xxx_fv_documents (
    document_id     number generated always as identity,
    batch_id        number         not null,
    file_name       varchar2(400)  not null,
    mime_type       varchar2(255),
    file_content    blob           not null,
    uploaded_by     varchar2(255)  not null,
    uploaded_on     date           default sysdate not null,
    constraint xxx_fv_documents_pk  primary key (document_id),
    constraint xxx_fv_documents_fk1 foreign key (batch_id) references xxx_fv_batches (batch_id) on delete cascade
);
create index xxx_fv_documents_n1 on xxx_fv_documents (batch_id);

create table xxx_fv_files (
    file_id             number generated always as identity,
    batch_id            number         not null,
    document_id         number         not null,
    sheet_display_name  varchar2(200),
    sheet_file_name     varchar2(200),
    object_code         varchar2(30),
    is_ignored          varchar2(1)    default 'N' not null,
    row_count           number,
    staged_on           date,
    constraint xxx_fv_files_pk  primary key (file_id),
    constraint xxx_fv_files_fk1 foreign key (batch_id)    references xxx_fv_batches (batch_id) on delete cascade,
    constraint xxx_fv_files_fk2 foreign key (document_id) references xxx_fv_documents (document_id) on delete cascade,
    constraint xxx_fv_files_fk3 foreign key (object_code) references xxx_fv_objects (object_code),
    constraint xxx_fv_files_ck1 check (is_ignored in ('Y', 'N'))
);
create index xxx_fv_files_n1 on xxx_fv_files (batch_id, object_code);
create index xxx_fv_files_n2 on xxx_fv_files (object_code);
-- one row per sheet per document; CSV files have no sheet (CON-52/CON-56)
create unique index xxx_fv_files_u1 on xxx_fv_files (document_id, nvl(sheet_file_name, '#CSV#'));

create table xxx_fv_file_columns (
    file_id          number         not null,
    column_position  number(3)      not null,
    file_header      varchar2(400),
    header_norm      varchar2(400),
    sample_shape     varchar2(400),
    mapped_column    varchar2(60),
    mapping_source   varchar2(10),
    ai_confidence    number(3,2),
    ai_reason        varchar2(400),
    constraint xxx_fv_file_columns_pk  primary key (file_id, column_position),
    constraint xxx_fv_file_columns_fk1 foreign key (file_id) references xxx_fv_files (file_id) on delete cascade,
    constraint xxx_fv_file_columns_ck1 check (mapping_source in ('AUTO', 'AI', 'USER')),
    constraint xxx_fv_file_columns_ck2 check (ai_confidence between 0 and 1)
);
-- a target column can be mapped only once per file
create unique index xxx_fv_file_columns_u1 on xxx_fv_file_columns (
    case when mapped_column is not null then file_id end,
    mapped_column);

-- -----------------------------------------------------------------------------
-- 4. Staging: one row per data line, one row per non-empty mapped cell
-- -----------------------------------------------------------------------------
create table xxx_fv_stage_lines (
    file_id         number         not null,
    line_number     number         not null,
    constraint xxx_fv_stage_lines_pk  primary key (file_id, line_number),
    constraint xxx_fv_stage_lines_fk1 foreign key (file_id) references xxx_fv_files (file_id) on delete cascade
);

create table xxx_fv_stage_values (
    file_id         number         not null,
    line_number     number         not null,
    column_name     varchar2(60)   not null,
    cell_value      varchar2(4000) not null,
    constraint xxx_fv_stage_values_pk  primary key (file_id, line_number, column_name),
    constraint xxx_fv_stage_values_fk1 foreign key (file_id) references xxx_fv_files (file_id) on delete cascade
);
-- column checks and pivots read by file + column
create index xxx_fv_stage_values_n1 on xxx_fv_stage_values (file_id, column_name) compress 1;

-- -----------------------------------------------------------------------------
-- 5. Results
-- -----------------------------------------------------------------------------
create table xxx_fv_issues (
    issue_id        number generated always as identity,
    batch_id        number         not null,
    file_id         number,
    object_code     varchar2(30),
    line_number     number,
    column_name     varchar2(200),
    rule_code       varchar2(40)   not null,
    severity        varchar2(10)   not null,
    message         varchar2(1000) not null,
    bad_value       varchar2(400),
    created_on      date           default sysdate not null,
    constraint xxx_fv_issues_pk  primary key (issue_id),
    constraint xxx_fv_issues_fk1 foreign key (batch_id)  references xxx_fv_batches (batch_id) on delete cascade,
    constraint xxx_fv_issues_fk2 foreign key (file_id)   references xxx_fv_files (file_id) on delete cascade,
    constraint xxx_fv_issues_fk3 foreign key (rule_code) references xxx_fv_rules (rule_code),
    constraint xxx_fv_issues_ck1 check (severity in ('ERROR', 'WARNING', 'INFO'))
);
create index xxx_fv_issues_n1 on xxx_fv_issues (batch_id, severity, object_code);
create index xxx_fv_issues_n2 on xxx_fv_issues (file_id, line_number);
create index xxx_fv_issues_n3 on xxx_fv_issues (rule_code);

create table xxx_fv_recon_results (
    recon_id        number generated always as identity,
    batch_id        number         not null,
    rule_code       varchar2(40)   not null,
    recon_label     varchar2(200)  not null,
    currency_code   varchar2(15),
    source_total    number,
    target_total    number,
    difference      number,
    status_code     varchar2(10)   not null,
    created_on      date           default sysdate not null,
    constraint xxx_fv_recon_results_pk  primary key (recon_id),
    constraint xxx_fv_recon_results_fk1 foreign key (batch_id)  references xxx_fv_batches (batch_id) on delete cascade,
    constraint xxx_fv_recon_results_fk2 foreign key (rule_code) references xxx_fv_rules (rule_code),
    constraint xxx_fv_recon_results_ck1 check (status_code in ('MATCHED', 'DIFF'))
);
create index xxx_fv_recon_results_n1 on xxx_fv_recon_results (batch_id, rule_code);
create index xxx_fv_recon_results_n2 on xxx_fv_recon_results (rule_code);

create table xxx_fv_ai_reports (
    report_id          number generated always as identity,
    batch_id           number         not null,
    file_id            number,
    report_type        varchar2(20)   not null,
    language_code      varchar2(2)    default 'EN' not null,
    status_code        varchar2(20)   not null,
    service_static_id  varchar2(255),
    context_json       clob,
    response_json      clob,
    error_message      varchar2(4000),
    elapsed_ms         number,
    requested_by       varchar2(255)  not null,
    requested_on       date           default sysdate not null,
    constraint xxx_fv_ai_reports_pk  primary key (report_id),
    constraint xxx_fv_ai_reports_fk1 foreign key (batch_id) references xxx_fv_batches (batch_id) on delete cascade,
    constraint xxx_fv_ai_reports_fk2 foreign key (file_id)  references xxx_fv_files (file_id) on delete cascade,
    constraint xxx_fv_ai_reports_ck1 check (report_type in ('BATCH_REPORT', 'MAPPING', 'CHAT')),
    constraint xxx_fv_ai_reports_ck2 check (language_code in ('EN', 'AR')),
    constraint xxx_fv_ai_reports_ck3 check (status_code in ('COMPLETED', 'FAILED')),
    constraint xxx_fv_ai_reports_ck4 check (context_json is json),
    constraint xxx_fv_ai_reports_ck5 check (response_json is json)
);
create index xxx_fv_ai_reports_n1 on xxx_fv_ai_reports (batch_id, report_type, requested_on);
create index xxx_fv_ai_reports_n2 on xxx_fv_ai_reports (file_id);

-- -----------------------------------------------------------------------------
-- 6. Error log (written only by xxx_fv_log_pkg, the one autonomous transaction)
-- -----------------------------------------------------------------------------
create table xxx_fv_error_log (
    log_id          number generated always as identity,
    log_ts          timestamp      default systimestamp not null,
    module          varchar2(200)  not null,
    log_key         varchar2(200),
    err_stack       varchar2(4000),
    backtrace       varchar2(4000),
    call_stack      varchar2(4000),
    db_user         varchar2(128)  default user not null,
    constraint xxx_fv_error_log_pk primary key (log_id)
);
create index xxx_fv_error_log_n1 on xxx_fv_error_log (log_ts);
