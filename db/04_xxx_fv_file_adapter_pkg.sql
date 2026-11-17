-- =============================================================================
-- XXX_FV_FILE_ADAPTER_PKG  (adapter layer)
-- The only package that knows about APEX_DATA_PARSER. Turns an uploaded CSV/XLSX
-- into xxx_fv_files + xxx_fv_file_columns (headers, auto mapping) and staging rows.
-- No COMMIT: the caller (xxx_fv_batch_api, called from APEX) owns the transaction.
-- Assumption: APEX_DATA_PARSER returns the header row as line_number 1 for CSV/XLSX.
-- Dates in source files are expected as text in the column's date_format (YYYY-MM-DD).
-- =============================================================================

create or replace package xxx_fv_file_adapter_pkg authid definer as

    -- Normalises a header / sheet / file name to UPPER_SNAKE (used in SQL, hence public).
    function normalize_name (p_text in varchar2) return varchar2 deterministic;

    -- Stores the document, creates one file row per XLSX sheet (or one for a CSV),
    -- detects the object from the sheet/file name, captures headers and auto-maps them.
    procedure register_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type);

    -- Re-points a file to another object and redoes the automatic mapping.
    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type);

    -- Sets (or clears, when p_column_name is null) the target column for one header.
    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type);

    -- Re-reads the file and replaces its staging rows (idempotent).
    procedure stage_file (p_file_id in xxx_fv_files.file_id%type);

end xxx_fv_file_adapter_pkg;
/

create or replace package body xxx_fv_file_adapter_pkg as

    c_csv  constant varchar2(4) := 'CSV';
    c_xlsx constant varchar2(4) := 'XLSX';

    type t_file_source is record (
        content          blob,
        file_name        xxx_fv_documents.file_name%type,
        sheet_file_name  xxx_fv_files.sheet_file_name%type,
        object_code      xxx_fv_files.object_code%type);

    -- -------------------------------------------------------------------------
    function normalize_name (p_text in varchar2) return varchar2 deterministic is
    begin
        return upper(trim(both '_' from regexp_replace(trim(p_text), '[^A-Za-z0-9]+', '_')));
    end normalize_name;

    -- -------------------------------------------------------------------------
    function file_kind (p_file_name in varchar2) return varchar2 is
    begin
        if lower(p_file_name) like '%.xlsx' then
            return c_xlsx;
        elsif lower(p_file_name) like '%.csv' or lower(p_file_name) like '%.txt' then
            return c_csv;
        end if;
        raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter,
            'Unsupported file type for "' || p_file_name || '". Upload .xlsx or .csv files.');
    end file_kind;

    -- -------------------------------------------------------------------------
    function load_source (p_file_id in xxx_fv_files.file_id%type) return t_file_source is
        l_src t_file_source;
    begin
        select d.file_content, d.file_name, f.sheet_file_name, f.object_code
          into l_src.content, l_src.file_name, l_src.sheet_file_name, l_src.object_code
          from xxx_fv_files f
          join xxx_fv_documents d
            on d.document_id = f.document_id
         where f.file_id = p_file_id;
        return l_src;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found, 'File ' || p_file_id || ' not found.');
    end load_source;

    -- -------------------------------------------------------------------------
    -- Headers from line 1, plus the "shape" of the first sample value (digits -> 9)
    -- so the AI can suggest a mapping without seeing account or VAT numbers.
    procedure capture_headers (p_file_id in xxx_fv_files.file_id%type) is
        l_src t_file_source := load_source(p_file_id);
    begin
        delete from xxx_fv_file_columns where file_id = p_file_id;

        insert into xxx_fv_file_columns (file_id, column_position, file_header, header_norm, sample_shape)
        select p_file_id,
               c.column_position,
               max(case when c.line_number = 1 then substr(c.cell, 1, 400) end),
               max(case when c.line_number = 1 then substr(xxx_fv_file_adapter_pkg.normalize_name(c.cell), 1, 400) end),
               substr(min(case when c.line_number > 1
                               then lpad(c.line_number, 6, '0') || regexp_replace(c.cell, '[0-9]', '9') end), 7, 60)
          from (select p.line_number,
                       pos.column_position,
                       trim(case pos.column_position
                                when 1 then p.col001
                                when 2 then p.col002
                                when 3 then p.col003
                                when 4 then p.col004
                                when 5 then p.col005
                                when 6 then p.col006
                                when 7 then p.col007
                                when 8 then p.col008
                                when 9 then p.col009
                                when 10 then p.col010
                                when 11 then p.col011
                                when 12 then p.col012
                                when 13 then p.col013
                                when 14 then p.col014
                                when 15 then p.col015
                                when 16 then p.col016
                                when 17 then p.col017
                                when 18 then p.col018
                                when 19 then p.col019
                                when 20 then p.col020
                                when 21 then p.col021
                                when 22 then p.col022
                                when 23 then p.col023
                                when 24 then p.col024
                                when 25 then p.col025
                                when 26 then p.col026
                                when 27 then p.col027
                                when 28 then p.col028
                                when 29 then p.col029
                                when 30 then p.col030
                                when 31 then p.col031
                                when 32 then p.col032
                                when 33 then p.col033
                                when 34 then p.col034
                                when 35 then p.col035
                                when 36 then p.col036
                                when 37 then p.col037
                                when 38 then p.col038
                                when 39 then p.col039
                                when 40 then p.col040
                                when 41 then p.col041
                                when 42 then p.col042
                                when 43 then p.col043
                                when 44 then p.col044
                                when 45 then p.col045
                                when 46 then p.col046
                                when 47 then p.col047
                                when 48 then p.col048
                                when 49 then p.col049
                                when 50 then p.col050
                                when 51 then p.col051
                                when 52 then p.col052
                                when 53 then p.col053
                                when 54 then p.col054
                                when 55 then p.col055
                                when 56 then p.col056
                                when 57 then p.col057
                                when 58 then p.col058
                                when 59 then p.col059
                                when 60 then p.col060
                            end) as cell
                  from table(apex_data_parser.parse(
                                 p_content           => l_src.content,
                                 p_file_name         => l_src.file_name,
                                 p_xlsx_sheet_name   => l_src.sheet_file_name,
                                 p_detect_data_types => 'N',
                                 p_max_rows          => 6)) p
                 cross join (select level as column_position
                               from dual
                            connect by level <= xxx_fv_const_pkg.c_max_file_columns) pos
               ) c
         where c.cell is not null
         group by c.column_position
        having max(case when c.line_number = 1 then c.cell end) is not null;
    end capture_headers;

    -- -------------------------------------------------------------------------
    -- Header = column name, or header = known alias. First header wins on duplicates.
    procedure auto_map (p_file_id in xxx_fv_files.file_id%type) is
    begin
        merge into xxx_fv_file_columns fc
        using (select m.file_id, m.column_position, m.column_name
                 from (select fc2.file_id,
                              fc2.column_position,
                              coalesce(c.column_name, a.column_name) as column_name,
                              row_number() over (partition by coalesce(c.column_name, a.column_name)
                                                 order by fc2.column_position) as rn
                         from xxx_fv_file_columns fc2
                         join xxx_fv_files f
                           on f.file_id = fc2.file_id
                         left join xxx_fv_columns c
                           on c.object_code = f.object_code
                          and c.column_name = fc2.header_norm
                         left join xxx_fv_column_aliases a
                           on a.object_code = f.object_code
                          and a.alias_norm  = fc2.header_norm
                        where fc2.file_id = p_file_id
                          and fc2.mapped_column is null) m
                where m.column_name is not null
                  and m.rn = 1
                  and not exists (select 1
                                    from xxx_fv_file_columns x
                                   where x.file_id = m.file_id
                                     and x.mapped_column = m.column_name)) s
           on (fc.file_id = s.file_id and fc.column_position = s.column_position)
         when matched then update
              set fc.mapped_column  = s.column_name,
                  fc.mapping_source = xxx_fv_const_pkg.c_map_auto;
    end auto_map;

    -- -------------------------------------------------------------------------
    -- Fallback when the sheet/file name names no object: score each object by the
    -- headers that match its columns or aliases. Each header counts 1/(number of objects
    -- it matches), so distinctive headers (LEDGER_NAME) outweigh shared ones (CURRENCY).
    -- Assigns only on a clear win: score >= 1.5 and >= 1.5 x the runner-up.
    procedure detect_by_headers (p_file_id in xxx_fv_files.file_id%type) is
    begin
        update xxx_fv_files f
           set f.object_code = (
                   with hdr as (select distinct fc.header_norm
                                  from xxx_fv_file_columns fc
                                 where fc.file_id = p_file_id
                                   and fc.header_norm is not null),
                        cand as (select c.object_code, c.column_name as name_norm from xxx_fv_columns c
                                 union
                                 select a.object_code, a.alias_norm from xxx_fv_column_aliases a),
                        hit as (select distinct h.header_norm, k.object_code
                                  from hdr h
                                  join cand k
                                    on k.name_norm = h.header_norm
                                  join xxx_fv_objects o
                                    on o.object_code = k.object_code
                                   and o.is_enabled = 'Y'),
                        scored as (select object_code, sum(wt) as score
                                     from (select object_code, 1 / count(*) over (partition by header_norm) as wt
                                             from hit)
                                    group by object_code),
                        ranked as (select object_code, score,
                                          row_number() over (order by score desc, object_code) as rn,
                                          lead(score) over (order by score desc, object_code) as next_score
                                     from scored)
                   select r.object_code
                     from ranked r
                    where r.rn = 1
                      and r.score >= 1.5
                      and (r.next_score is null or r.score >= 1.5 * r.next_score))
         where f.file_id = p_file_id
           and f.object_code is null;
    end detect_by_headers;

    -- -------------------------------------------------------------------------
    procedure register_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type)
    is
        l_kind  varchar2(4) := file_kind(p_file_name);
    begin
        insert into xxx_fv_documents (batch_id, file_name, mime_type, file_content, uploaded_by)
        values (p_batch_id, p_file_name, p_mime_type, p_content, p_user)
        returning document_id into x_document_id;

        if l_kind = c_xlsx then
            insert into xxx_fv_files (batch_id, document_id, sheet_display_name, sheet_file_name, object_code)
            select p_batch_id,
                   x_document_id,
                   w.sheet_display_name,
                   w.sheet_file_name,
                   (select min(o.object_code)
                      from xxx_fv_objects o
                     where o.is_enabled = 'Y'
                       and xxx_fv_file_adapter_pkg.normalize_name(w.sheet_display_name) in (o.object_code, o.sheet_alias))
              from table(apex_data_parser.get_xlsx_worksheets(p_content => p_content)) w
             order by w.sheet_sequence;
        else
            insert into xxx_fv_files (batch_id, document_id, object_code)
            select p_batch_id,
                   x_document_id,
                   (select min(o.object_code)
                      from xxx_fv_objects o
                     where o.is_enabled = 'Y'
                       and xxx_fv_file_adapter_pkg.normalize_name(regexp_replace(p_file_name, '\.[^.]*$', '')) in (o.object_code, o.sheet_alias))
              from dual;
        end if;

        -- one parse per sheet: a loop is required because each sheet is read separately (CON-03)
        for f in (select file_id
                    from xxx_fv_files
                   where document_id = x_document_id
                   order by file_id)
        loop
            capture_headers(f.file_id);
            detect_by_headers(f.file_id);
            auto_map(f.file_id);
        end loop;
    end register_document;

    -- -------------------------------------------------------------------------
    procedure clear_staging (p_file_id in xxx_fv_files.file_id%type) is
    begin
        delete from xxx_fv_stage_values where file_id = p_file_id;
        delete from xxx_fv_stage_lines  where file_id = p_file_id;
        update xxx_fv_files
           set row_count = null,
               staged_on = null
         where file_id = p_file_id;
    end clear_staging;

    -- -------------------------------------------------------------------------
    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type)
    is
    begin
        update xxx_fv_files
           set object_code = p_object_code
         where file_id = p_file_id;

        if sql%rowcount = 0 then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found, 'File ' || p_file_id || ' not found.');
        end if;

        update xxx_fv_file_columns
           set mapped_column  = null,
               mapping_source = null,
               ai_confidence  = null,
               ai_reason      = null
         where file_id = p_file_id;

        clear_staging(p_file_id);
        auto_map(p_file_id);
    end assign_object;

    -- -------------------------------------------------------------------------
    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type)
    is
        l_valid pls_integer;
    begin
        if p_column_name is not null then
            select count(*)
              into l_valid
              from xxx_fv_files f
              join xxx_fv_columns c
                on c.object_code = f.object_code
             where f.file_id = p_file_id
               and c.column_name = p_column_name;

            if l_valid = 0 then
                raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter,
                    'Column ' || p_column_name || ' does not belong to the object of this file.');
            end if;
        end if;

        update xxx_fv_file_columns
           set mapped_column  = p_column_name,
               mapping_source = case when p_column_name is not null then xxx_fv_const_pkg.c_map_user end,
               ai_confidence  = null,
               ai_reason      = null
         where file_id = p_file_id
           and column_position = p_column_position;

        clear_staging(p_file_id);
    end set_mapping;

    -- -------------------------------------------------------------------------
    procedure stage_file (p_file_id in xxx_fv_files.file_id%type) is
        l_src   t_file_source := load_source(p_file_id);
        l_lines pls_integer;
    begin
        clear_staging(p_file_id);

        if l_src.object_code is null then
            return;   -- unknown object: reported by FILE_UNKNOWN_OBJECT, nothing to stage
        end if;

        insert into xxx_fv_stage_values (file_id, line_number, column_name, cell_value)
        select p_file_id, c.line_number, c.mapped_column, substr(c.cell, 1, 4000)
          from (select p.line_number,
                       m.mapped_column,
                       trim(case m.column_position
                                when 1 then p.col001
                                when 2 then p.col002
                                when 3 then p.col003
                                when 4 then p.col004
                                when 5 then p.col005
                                when 6 then p.col006
                                when 7 then p.col007
                                when 8 then p.col008
                                when 9 then p.col009
                                when 10 then p.col010
                                when 11 then p.col011
                                when 12 then p.col012
                                when 13 then p.col013
                                when 14 then p.col014
                                when 15 then p.col015
                                when 16 then p.col016
                                when 17 then p.col017
                                when 18 then p.col018
                                when 19 then p.col019
                                when 20 then p.col020
                                when 21 then p.col021
                                when 22 then p.col022
                                when 23 then p.col023
                                when 24 then p.col024
                                when 25 then p.col025
                                when 26 then p.col026
                                when 27 then p.col027
                                when 28 then p.col028
                                when 29 then p.col029
                                when 30 then p.col030
                                when 31 then p.col031
                                when 32 then p.col032
                                when 33 then p.col033
                                when 34 then p.col034
                                when 35 then p.col035
                                when 36 then p.col036
                                when 37 then p.col037
                                when 38 then p.col038
                                when 39 then p.col039
                                when 40 then p.col040
                                when 41 then p.col041
                                when 42 then p.col042
                                when 43 then p.col043
                                when 44 then p.col044
                                when 45 then p.col045
                                when 46 then p.col046
                                when 47 then p.col047
                                when 48 then p.col048
                                when 49 then p.col049
                                when 50 then p.col050
                                when 51 then p.col051
                                when 52 then p.col052
                                when 53 then p.col053
                                when 54 then p.col054
                                when 55 then p.col055
                                when 56 then p.col056
                                when 57 then p.col057
                                when 58 then p.col058
                                when 59 then p.col059
                                when 60 then p.col060
                            end) as cell
                  from table(apex_data_parser.parse(
                                 p_content           => l_src.content,
                                 p_file_name         => l_src.file_name,
                                 p_xlsx_sheet_name   => l_src.sheet_file_name,
                                 p_detect_data_types => 'N')) p
                 cross join (select column_position, mapped_column
                               from xxx_fv_file_columns
                              where file_id = p_file_id
                                and mapped_column is not null) m
                 where p.line_number > 1) c
         where c.cell is not null;

        insert into xxx_fv_stage_lines (file_id, line_number)
        select distinct file_id, line_number
          from xxx_fv_stage_values
         where file_id = p_file_id;
        l_lines := sql%rowcount;

        update xxx_fv_files
           set row_count = l_lines,
               staged_on = sysdate
         where file_id = p_file_id;
    end stage_file;

end xxx_fv_file_adapter_pkg;
/
