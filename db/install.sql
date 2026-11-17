-- =============================================================================
-- XXX_FV  install script. Run in SQLcl as the APEX workspace parsing schema:
--   sql -name <your_atp_connection> @install.sql
-- Fresh install only. To reinstall, run uninstall.sql first.
-- =============================================================================
whenever sqlerror exit rollback
set define off
set sqlblanklines on
set serveroutput on

prompt == Tables
@@01_tables.sql
prompt == Views
@@02_views.sql
prompt == Constants and logger
@@03_xxx_fv_const_log.sql
prompt == File adapter
@@04_xxx_fv_file_adapter_pkg.sql
prompt == Rules engine
@@05_xxx_fv_rules_pkg.sql
prompt == AI adapter
@@06_xxx_fv_ai_pkg.sql
prompt == Batch API
@@07_xxx_fv_batch_api.sql
prompt == Seed: objects and columns
@@08_seed_config.sql
prompt == Seed: statuses and rules
@@09_seed_rules.sql

commit;

prompt == Compile check (expect no rows)
select name, type, line, position, text
  from user_errors
 where name like 'XXX_FV%'
 order by name, type, sequence;

prompt == Done. Optional: @@10_xxx_fv_rules_tst.sql then exec ut.run('xxx_fv_rules_tst')
