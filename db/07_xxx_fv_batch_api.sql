-- =============================================================================
-- XXX_FV_BATCH_API  (application layer / entry API for the APEX app)
-- Every APEX process calls one procedure here (CA-08, PLT-01). It locks the batch,
-- checks the status move against xxx_fv_status_transitions (the one transition API,
-- RTP-04), delegates to the adapters and the rules engine, and logs + re-raises
-- errors (CON-30). No COMMIT: APEX commits at the end of the request (CON-12).
-- =============================================================================

create or replace package xxx_fv_batch_api authid definer as

    procedure create_batch (
        p_batch_name    in  xxx_fv_batches.batch_name%type,
        p_client_name   in  xxx_fv_batches.client_name%type,
        p_target_env    in  xxx_fv_batches.target_env%type,
        p_cutover_date  in  xxx_fv_batches.cutover_date%type,
        p_user          in  varchar2,
        x_batch_id      out xxx_fv_batches.batch_id%type);

    -- Lost-update safe header edit (CON-10): fails if p_row_version is stale.
    procedure update_batch_header (
        p_batch_id      in xxx_fv_batches.batch_id%type,
        p_row_version   in xxx_fv_batches.row_version%type,
        p_batch_name    in xxx_fv_batches.batch_name%type,
        p_client_name   in xxx_fv_batches.client_name%type,
        p_target_env    in xxx_fv_batches.target_env%type,
        p_cutover_date  in xxx_fv_batches.cutover_date%type,
        p_user          in varchar2);

    procedure add_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type);

    -- APEX convenience: p_temp_file_names is the colon-separated value of a
    -- File Browse item stored in APEX_APPLICATION_TEMP_FILES.
    procedure add_uploaded_files (
        p_batch_id         in xxx_fv_batches.batch_id%type,
        p_temp_file_names  in varchar2,
        p_user             in varchar2);

    procedure remove_document (
        p_document_id  in xxx_fv_documents.document_id%type,
        p_user         in varchar2);

    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type,
        p_user         in varchar2);

    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type,
        p_user             in varchar2);

    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2);

    -- Stages every file and runs all rules; replaces previous results (idempotent).
    procedure validate_batch (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_user      in varchar2);

    procedure generate_ai_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2);

    -- Ignore (p_ignored = 'Y') or include again ('N') a sheet; no-op when unchanged.
    procedure ignore_file (
        p_file_id  in xxx_fv_files.file_id%type,
        p_ignored  in xxx_fv_files.is_ignored%type,
        p_user     in varchar2);

    -- Ask Claude chat turn (no status change).
    procedure ask_claude (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_question       in  varchar2,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2);

end xxx_fv_batch_api;
/

create or replace package body xxx_fv_batch_api as

    c_module constant varchar2(30) := 'XXX_FV';

    -- -------------------------------------------------------------------------
    -- Serialises work on one batch (CON-11, CON-17) and returns its status.
    procedure lock_batch (
        p_batch_id  in  xxx_fv_batches.batch_id%type,
        x_status    out xxx_fv_batches.status_code%type)
    is
    begin
        select status_code
          into x_status
          from xxx_fv_batches
         where batch_id = p_batch_id
           for update wait 10;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_batch_not_found, 'Batch ' || p_batch_id || ' not found.');
    end lock_batch;

    -- -------------------------------------------------------------------------
    procedure assert_transition (
        p_from  in varchar2,
        p_to    in varchar2)
    is
        l_allowed pls_integer;
    begin
        select count(*)
          into l_allowed
          from xxx_fv_status_transitions
         where from_status = p_from
           and to_status   = p_to;

        if l_allowed = 0 then
            raise_application_error(xxx_fv_const_pkg.c_err_invalid_transition,
                'This action is not allowed while the batch is ' || p_from || ' (needs a move to ' || p_to || ').');
        end if;
    end assert_transition;

    -- -------------------------------------------------------------------------
    -- Locks, checks the move, and returns. Callers do their work, then set_status.
    procedure begin_change (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_to        in varchar2)
    is
        l_status xxx_fv_batches.status_code%type;
    begin
        lock_batch(p_batch_id, l_status);
        assert_transition(l_status, p_to);
    end begin_change;

    -- -------------------------------------------------------------------------
    procedure set_status (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_to        in varchar2,
        p_user      in varchar2)
    is
    begin
        update xxx_fv_batches
           set status_code = p_to,
               row_version = row_version + 1,
               updated_by  = p_user,
               updated_on  = sysdate
         where batch_id = p_batch_id;
    end set_status;

    -- -------------------------------------------------------------------------
    function batch_of_file (p_file_id in xxx_fv_files.file_id%type) return xxx_fv_files.batch_id%type is
        l_batch_id xxx_fv_files.batch_id%type;
    begin
        select batch_id into l_batch_id from xxx_fv_files where file_id = p_file_id;
        return l_batch_id;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found, 'File ' || p_file_id || ' not found.');
    end batch_of_file;

    -- =========================================================================
    procedure create_batch (
        p_batch_name    in  xxx_fv_batches.batch_name%type,
        p_client_name   in  xxx_fv_batches.client_name%type,
        p_target_env    in  xxx_fv_batches.target_env%type,
        p_cutover_date  in  xxx_fv_batches.cutover_date%type,
        p_user          in  varchar2,
        x_batch_id      out xxx_fv_batches.batch_id%type)
    is
    begin
        insert into xxx_fv_batches (batch_name, client_name, target_env, cutover_date, status_code, created_by)
        values (p_batch_name, p_client_name, p_target_env, p_cutover_date, xxx_fv_const_pkg.c_status_new, p_user)
        returning batch_id into x_batch_id;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.create_batch', p_batch_name);
            raise;
    end create_batch;

    -- -------------------------------------------------------------------------
    procedure update_batch_header (
        p_batch_id      in xxx_fv_batches.batch_id%type,
        p_row_version   in xxx_fv_batches.row_version%type,
        p_batch_name    in xxx_fv_batches.batch_name%type,
        p_client_name   in xxx_fv_batches.client_name%type,
        p_target_env    in xxx_fv_batches.target_env%type,
        p_cutover_date  in xxx_fv_batches.cutover_date%type,
        p_user          in varchar2)
    is
    begin
        update xxx_fv_batches
           set batch_name   = p_batch_name,
               client_name  = p_client_name,
               target_env   = p_target_env,
               cutover_date = p_cutover_date,
               row_version  = row_version + 1,
               updated_by   = p_user,
               updated_on   = sysdate
         where batch_id    = p_batch_id
           and row_version = p_row_version;

        if sql%rowcount = 0 then
            raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter,
                'The batch was changed by someone else. Reload the page and try again.');
        end if;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.update_batch_header', to_char(p_batch_id));
            raise;
    end update_batch_header;

    -- -------------------------------------------------------------------------
    procedure add_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type)
    is
    begin
        begin_change(p_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.register_document(p_batch_id, p_file_name, p_mime_type, p_content, p_user, x_document_id);
        set_status(p_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.add_document', p_batch_id || ':' || p_file_name);
            raise;
    end add_document;

    -- -------------------------------------------------------------------------
    procedure add_uploaded_files (
        p_batch_id         in xxx_fv_batches.batch_id%type,
        p_temp_file_names  in varchar2,
        p_user             in varchar2)
    is
        l_document_id xxx_fv_documents.document_id%type;
    begin
        -- one document per uploaded file; each needs its own parse
        for f in (select t.filename, t.mime_type, t.blob_content
                    from apex_application_temp_files t
                   where t.name in (select column_value from table(apex_string.split(p_temp_file_names, ':')))
                   order by t.filename)
        loop
            add_document(p_batch_id, f.filename, f.mime_type, f.blob_content, p_user, l_document_id);
        end loop;
    end add_uploaded_files;

    -- -------------------------------------------------------------------------
    procedure remove_document (
        p_document_id  in xxx_fv_documents.document_id%type,
        p_user         in varchar2)
    is
        l_batch_id xxx_fv_documents.batch_id%type;
    begin
        select batch_id into l_batch_id from xxx_fv_documents where document_id = p_document_id;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        delete from xxx_fv_documents where document_id = p_document_id;   -- files, mappings, staging cascade
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.remove_document', to_char(p_document_id));
            raise;
    end remove_document;

    -- -------------------------------------------------------------------------
    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type,
        p_user         in varchar2)
    is
        l_batch_id xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_current  xxx_fv_files.object_code%type;
    begin
        select object_code into l_current from xxx_fv_files where file_id = p_file_id;
        if l_current = p_object_code or (l_current is null and p_object_code is null) then
            return;   -- nothing changes: keep the batch status (and its results)
        end if;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.assign_object(p_file_id, p_object_code);
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.assign_object', to_char(p_file_id));
            raise;
    end assign_object;

    -- -------------------------------------------------------------------------
    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type,
        p_user             in varchar2)
    is
        l_batch_id xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_current  xxx_fv_file_columns.mapped_column%type;
    begin
        select mapped_column into l_current
          from xxx_fv_file_columns
         where file_id = p_file_id
           and column_position = p_column_position;
        if l_current = p_column_name or (l_current is null and p_column_name is null) then
            return;   -- unchanged row submitted by the grid
        end if;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.set_mapping(p_file_id, p_column_position, p_column_name);
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.set_mapping', p_file_id || ':' || p_column_position);
            raise;
    end set_mapping;

    -- -------------------------------------------------------------------------
    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_batch_id  xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_report_id xxx_fv_ai_reports.report_id%type;
        l_mapped    number;
    begin
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_ai_pkg.suggest_mapping(p_file_id, p_user, l_report_id, l_mapped, x_return_status, x_message);
        if x_return_status = 'S' and l_mapped > 0 then
            set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
        end if;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.suggest_mapping', to_char(p_file_id));
            raise;
    end suggest_mapping;

    -- -------------------------------------------------------------------------
    procedure validate_batch (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_user      in varchar2)
    is
        l_readiness xxx_fv_rules_pkg.t_readiness;
    begin
        begin_change(p_batch_id, xxx_fv_const_pkg.c_status_validated);
        dbms_application_info.set_module(c_module, 'validate batch ' || p_batch_id);   -- CON-07

        -- each file is parsed separately, so staging loops over files (CON-03)
        for f in (select file_id from xxx_fv_files where batch_id = p_batch_id and is_ignored = 'N' order by file_id) loop
            dbms_application_info.set_action('stage file ' || f.file_id);
            xxx_fv_file_adapter_pkg.stage_file(f.file_id);
        end loop;

        dbms_application_info.set_action('run rules');
        xxx_fv_rules_pkg.run_all(p_batch_id);
        l_readiness := xxx_fv_rules_pkg.get_readiness(p_batch_id);

        update xxx_fv_batches
           set line_count        = l_readiness.line_count,
               error_count       = l_readiness.error_count,
               warning_count     = l_readiness.warning_count,
               info_count        = l_readiness.info_count,
               readiness_score   = l_readiness.readiness_score,
               readiness_status  = l_readiness.readiness_status,
               last_validated_on = sysdate
         where batch_id = p_batch_id;

        set_status(p_batch_id, xxx_fv_const_pkg.c_status_validated, p_user);
        dbms_application_info.set_module(null, null);
    exception
        when others then
            dbms_application_info.set_module(null, null);
            xxx_fv_log_pkg.error('xxx_fv_batch_api.validate_batch', to_char(p_batch_id));
            raise;
    end validate_batch;

    -- -------------------------------------------------------------------------
    procedure generate_ai_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
    begin
        begin_change(p_batch_id, xxx_fv_const_pkg.c_status_reported);
        xxx_fv_ai_pkg.generate_batch_report(p_batch_id, nvl(p_language, xxx_fv_const_pkg.c_lang_en), p_user,
                                            x_report_id, x_return_status, x_message);
        if x_return_status = 'S' then
            set_status(p_batch_id, xxx_fv_const_pkg.c_status_reported, p_user);
        end if;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.generate_ai_report', to_char(p_batch_id));
            raise;
    end generate_ai_report;

    -- -------------------------------------------------------------------------
    procedure ask_claude (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_question       in  varchar2,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_answer clob;
    begin
        if trim(p_question) is null then
            x_return_status := 'E';
            x_message       := 'Type a question first.';
            return;
        end if;
        xxx_fv_ai_pkg.ask_batch(p_batch_id, substr(p_question, 1, 2000), p_user, l_answer, x_return_status, x_message);
    end ask_claude;

    -- -------------------------------------------------------------------------
    procedure ignore_file (
        p_file_id  in xxx_fv_files.file_id%type,
        p_ignored  in xxx_fv_files.is_ignored%type,
        p_user     in varchar2)
    is
        l_batch_id xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_current  xxx_fv_files.is_ignored%type;
    begin
        if p_ignored not in ('Y', 'N') or p_ignored is null then
            raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter, 'p_ignored must be Y or N.');
        end if;
        select is_ignored into l_current from xxx_fv_files where file_id = p_file_id;
        if l_current = p_ignored then
            return;   -- nothing changes: keep the batch status
        end if;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.set_ignored(p_file_id, p_ignored);
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.ignore_file', p_file_id || ':' || p_ignored);
            raise;
    end ignore_file;

end xxx_fv_batch_api;
/
