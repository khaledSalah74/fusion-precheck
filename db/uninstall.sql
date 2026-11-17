-- =============================================================================
-- XXX_FV  uninstall: drops every XXX_FV object. Dev/demo use only.
-- =============================================================================
whenever sqlerror continue
set define off

drop package xxx_fv_rules_tst;
drop package xxx_fv_batch_api;
drop package xxx_fv_ai_pkg;
drop package xxx_fv_rules_pkg;
drop package xxx_fv_file_adapter_pkg;
drop package xxx_fv_log_pkg;
drop package xxx_fv_const_pkg;

drop view xxx_fv_gl_balances_v;
drop view xxx_fv_ap_suppliers_v;
drop view xxx_fv_ap_invoices_v;
drop view xxx_fv_ar_customers_v;
drop view xxx_fv_ar_invoices_v;
drop view xxx_fv_ce_bank_accounts_v;
drop view xxx_fv_po_orders_v;
drop view xxx_fv_pr_requisitions_v;

drop table xxx_fv_ai_reports purge;
drop table xxx_fv_recon_results purge;
drop table xxx_fv_issues purge;
drop table xxx_fv_stage_values purge;
drop table xxx_fv_stage_lines purge;
drop table xxx_fv_file_columns purge;
drop table xxx_fv_files purge;
drop table xxx_fv_documents purge;
drop table xxx_fv_batches purge;
drop table xxx_fv_status_transitions purge;
drop table xxx_fv_batch_statuses purge;
drop table xxx_fv_rules purge;
drop table xxx_fv_column_aliases purge;
drop table xxx_fv_column_values purge;
drop table xxx_fv_columns purge;
drop table xxx_fv_objects purge;
drop table xxx_fv_error_log purge;
