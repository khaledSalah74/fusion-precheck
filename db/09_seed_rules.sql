-- =============================================================================
-- XXX_FV  seed: batch statuses, allowed transitions, rule catalogue
-- Custom rules (ROW_SQL / RECON) read the typed views and refer to the current
-- batch through the CTE "b" (join b on b.batch_id = <view>.batch_id).
-- =============================================================================

-- statuses and the only allowed moves (RTP-04)
insert into xxx_fv_batch_statuses (status_code, status_name, display_seq) values ('NEW',          'New',             10);
insert into xxx_fv_batch_statuses (status_code, status_name, display_seq) values ('FILES_LOADED', 'Files loaded',    20);
insert into xxx_fv_batch_statuses (status_code, status_name, display_seq) values ('VALIDATED',    'Validated',       30);
insert into xxx_fv_batch_statuses (status_code, status_name, display_seq) values ('REPORTED',     'AI report ready', 40);

insert into xxx_fv_status_transitions (from_status, to_status) values ('NEW',          'FILES_LOADED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('FILES_LOADED', 'FILES_LOADED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('FILES_LOADED', 'VALIDATED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('VALIDATED',    'FILES_LOADED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('VALIDATED',    'VALIDATED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('VALIDATED',    'REPORTED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('REPORTED',     'FILES_LOADED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('REPORTED',     'VALIDATED');
insert into xxx_fv_status_transitions (from_status, to_status) values ('REPORTED',     'REPORTED');

-- -----------------------------------------------------------------------------
-- Built-in rules (logic in xxx_fv_rules_pkg; severity and on/off configurable)
-- -----------------------------------------------------------------------------
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('FILE_UNKNOWN_OBJECT', 'COLUMN', 'WARNING', 'Sheet or file not recognised',
 'Rename the sheet to the object name, or assign the object on the Files page.', 10);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('FILE_MISSING_COLUMN', 'COLUMN', 'ERROR', 'Required column missing or not mapped',
 'Add the column to the template or map an existing header to it on the Mapping page.', 20);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('FILE_UNMAPPED_COLUMN', 'COLUMN', 'INFO', 'Column not mapped, will be ignored',
 'Map it if it carries data Fusion needs; otherwise remove it from the template.', 30);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('FILE_EMPTY', 'COLUMN', 'WARNING', 'File has no data rows',
 'Check the sheet has data below the header row.', 40);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('BATCH_OBJECT_MISSING', 'COLUMN', 'INFO', 'Object not provided in this batch',
 'Confirm the object is out of scope or will come in a later batch.', 50);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_REQUIRED', 'COLUMN', 'ERROR', 'Required value is empty',
 'Fill the value in the source file.', 60);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_NUMBER', 'COLUMN', 'ERROR', 'Invalid number',
 'Use plain numbers with "." as decimal separator and no thousands separators.', 70);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_DATE', 'COLUMN', 'ERROR', 'Invalid date',
 'Format dates as text in YYYY-MM-DD.', 80);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_MAX_LENGTH', 'COLUMN', 'ERROR', 'Value too long for Fusion',
 'Shorten the value to the maximum length.', 90);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_PATTERN', 'COLUMN', 'ERROR', 'Value does not match the required format',
 'Correct the value to the expected format shown in the message.', 100);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_ALLOWED_VALUE', 'COLUMN', 'ERROR', 'Value not in the allowed list',
 'Use one of the allowed values exactly (values are case sensitive) or add a mapping.', 110);
insert into xxx_fv_rules (rule_code, rule_type, severity, title, fix_hint, run_order) values
('COL_DUPLICATE_KEY', 'COLUMN', 'ERROR', 'Duplicate business key',
 'Remove the duplicate rows or correct the key values.', 120);

-- -----------------------------------------------------------------------------
-- Cross-row / cross-object rules (ROW_SQL)
-- Must return: file_id, line_number, column_name, bad_value, message
-- -----------------------------------------------------------------------------
insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_SUP_VAT_MISSING', 'ROW_SQL', 'AP_SUPPLIERS', 'WARNING', 'Saudi supplier without VAT number',
 'Collect the VAT registration number; it is needed for ZATCA-compliant invoices.', 200, q'~
select s.file_id, s.line_number, 'TAX_REGISTRATION_NUMBER' as column_name, s.supplier_number as bad_value,
       'Supplier ' || s.supplier_number || ' (' || s.supplier_name || ') is in SA but has no VAT number.' as message
  from xxx_fv_ap_suppliers_v s
  join b on b.batch_id = s.batch_id
 where s.country = 'SA'
   and s.tax_registration_number is null
   and nvl(s.supplier_type, 'X') <> 'EMPLOYEE'~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_SUP_SIMILAR_NAME', 'ROW_SQL', 'AP_SUPPLIERS', 'WARNING', 'Possible duplicate supplier (similar name)',
 'Confirm whether both numbers are the same supplier; merge before migration if so.', 210, q'~
with n as (
    select s.file_id, s.line_number, s.supplier_number, s.supplier_name,
           replace(regexp_replace(regexp_replace(' ' || regexp_replace(upper(s.supplier_name), '[^A-Z0-9]+', ' ') || ' ',
                                                 ' (CO|COMPANY|LTD|LLC|EST|ESTABLISHMENT|THE|TRADING|GROUP) ', ' '),
                                  ' (CO|COMPANY|LTD|LLC|EST|ESTABLISHMENT|THE|TRADING|GROUP) ', ' '), ' ', '') as name_key
      from xxx_fv_ap_suppliers_v s
      join b on b.batch_id = s.batch_id
     where s.supplier_name is not null)
select n1.file_id, n1.line_number, 'SUPPLIER_NAME' as column_name, n1.supplier_name as bad_value,
       'Supplier ' || n1.supplier_number || ' "' || n1.supplier_name || '" looks like supplier '
       || n2.supplier_number || ' "' || n2.supplier_name || '".' as message
  from n n1
  join n n2
    on n2.name_key = n1.name_key
   and n2.supplier_number <> n1.supplier_number~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_INV_SUPPLIER_EXISTS', 'ROW_SQL', 'AP_INVOICES', 'ERROR', 'Invoice supplier not in supplier file',
 'Add the supplier to the supplier file, or confirm it already exists in Fusion.', 220, q'~
select i.file_id, i.line_number, 'SUPPLIER_NUMBER' as column_name, i.supplier_number as bad_value,
       'Invoice ' || i.invoice_number || ': supplier ' || i.supplier_number || ' is not in the supplier file.' as message
  from xxx_fv_ap_invoices_v i
  join b on b.batch_id = i.batch_id
 where i.supplier_number is not null
   and not exists (select 1
                     from xxx_fv_ap_suppliers_v s
                    where s.batch_id = i.batch_id
                      and s.supplier_number = i.supplier_number)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_INV_REMAINING_GT_AMOUNT', 'ROW_SQL', 'AP_INVOICES', 'ERROR', 'Open amount larger than invoice amount',
 'Correct the remaining amount; it cannot exceed the invoice amount.', 230, q'~
select i.file_id, i.line_number, 'AMOUNT_REMAINING' as column_name, to_char(i.amount_remaining) as bad_value,
       'Invoice ' || i.invoice_number || ': remaining ' || i.amount_remaining || ' > invoice amount ' || i.invoice_amount || '.' as message
  from xxx_fv_ap_invoices_v i
  join b on b.batch_id = i.batch_id
 where abs(i.amount_remaining) > abs(i.invoice_amount)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_INV_SIGN', 'ROW_SQL', 'AP_INVOICES', 'ERROR', 'Invoice amount sign does not match invoice type',
 'STANDARD and PREPAYMENT invoices are positive; CREDIT memos are negative.', 240, q'~
select i.file_id, i.line_number, 'INVOICE_AMOUNT' as column_name, to_char(i.invoice_amount) as bad_value,
       'Invoice ' || i.invoice_number || ' is ' || i.invoice_type || ' with amount ' || i.invoice_amount || '.' as message
  from xxx_fv_ap_invoices_v i
  join b on b.batch_id = i.batch_id
 where (i.invoice_type = 'CREDIT' and i.invoice_amount > 0)
    or (i.invoice_type in ('STANDARD', 'PREPAYMENT') and i.invoice_amount < 0)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_INV_AFTER_CUTOVER', 'ROW_SQL', 'AP_INVOICES', 'WARNING', 'Invoice dated after cutover',
 'Invoices after cutover should be entered in Fusion, not migrated.', 250, q'~
select i.file_id, i.line_number, 'INVOICE_DATE' as column_name, to_char(i.invoice_date, 'YYYY-MM-DD') as bad_value,
       'Invoice ' || i.invoice_number || ' is dated ' || to_char(i.invoice_date, 'YYYY-MM-DD')
       || ', after cutover ' || to_char(bt.cutover_date, 'YYYY-MM-DD') || '.' as message
  from xxx_fv_ap_invoices_v i
  join b on b.batch_id = i.batch_id
  join xxx_fv_batches bt on bt.batch_id = i.batch_id
 where i.invoice_date > bt.cutover_date~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AP_INV_CURRENCY_DIFF', 'ROW_SQL', 'AP_INVOICES', 'INFO', 'Invoice currency differs from supplier default',
 'Fine if intended; check the supplier site allows this currency.', 260, q'~
select i.file_id, i.line_number, 'INVOICE_CURRENCY' as column_name, i.invoice_currency as bad_value,
       'Invoice ' || i.invoice_number || ' is in ' || i.invoice_currency
       || '; supplier ' || i.supplier_number || ' defaults to another currency.' as message
  from xxx_fv_ap_invoices_v i
  join b on b.batch_id = i.batch_id
 where exists (select 1 from xxx_fv_ap_suppliers_v s
                where s.batch_id = i.batch_id and s.supplier_number = i.supplier_number)
   and not exists (select 1 from xxx_fv_ap_suppliers_v s
                    where s.batch_id = i.batch_id and s.supplier_number = i.supplier_number
                      and s.invoice_currency = i.invoice_currency)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AR_INV_CUSTOMER_EXISTS', 'ROW_SQL', 'AR_INVOICES', 'ERROR', 'Transaction customer not in customer file',
 'Add the customer to the customer file, or confirm it already exists in Fusion.', 300, q'~
select t.file_id, t.line_number, 'CUSTOMER_NUMBER' as column_name, t.customer_number as bad_value,
       'Transaction ' || t.transaction_number || ': customer ' || t.customer_number || ' is not in the customer file.' as message
  from xxx_fv_ar_invoices_v t
  join b on b.batch_id = t.batch_id
 where t.customer_number is not null
   and not exists (select 1
                     from xxx_fv_ar_customers_v c
                    where c.batch_id = t.batch_id
                      and c.customer_number = t.customer_number)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AR_TRX_SIGN', 'ROW_SQL', 'AR_INVOICES', 'ERROR', 'Transaction amount sign does not match type',
 'INV and DM are positive; CM (credit memo) is negative.', 310, q'~
select t.file_id, t.line_number, 'ORIGINAL_AMOUNT' as column_name, to_char(t.original_amount) as bad_value,
       'Transaction ' || t.transaction_number || ' is ' || t.transaction_type || ' with amount ' || t.original_amount || '.' as message
  from xxx_fv_ar_invoices_v t
  join b on b.batch_id = t.batch_id
 where (t.transaction_type = 'CM' and t.original_amount > 0)
    or (t.transaction_type in ('INV', 'DM') and t.original_amount < 0)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AR_DUE_GT_ORIGINAL', 'ROW_SQL', 'AR_INVOICES', 'ERROR', 'Amount due larger than original amount',
 'Correct the amount due; it cannot exceed the original amount.', 320, q'~
select t.file_id, t.line_number, 'AMOUNT_DUE' as column_name, to_char(t.amount_due) as bad_value,
       'Transaction ' || t.transaction_number || ': due ' || t.amount_due || ' > original ' || t.original_amount || '.' as message
  from xxx_fv_ar_invoices_v t
  join b on b.batch_id = t.batch_id
 where abs(t.amount_due) > abs(t.original_amount)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('AR_CUST_NO_CREDIT_LIMIT', 'ROW_SQL', 'AR_CUSTOMERS', 'INFO', 'Customer with zero or no credit limit',
 'Confirm credit limits with the credit controller before go-live.', 330, q'~
select c.file_id, c.line_number, 'CREDIT_LIMIT' as column_name, to_char(c.credit_limit) as bad_value,
       'Customer ' || c.customer_number || ' has credit limit ' || nvl(to_char(c.credit_limit), 'empty') || '.' as message
  from xxx_fv_ar_customers_v c
  join b on b.batch_id = c.batch_id
 where nvl(c.credit_limit, 0) = 0~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('GL_LINE_DR_AND_CR', 'ROW_SQL', 'GL_BALANCES', 'WARNING', 'Balance line has both debit and credit',
 'Net the line to a single debit or credit.', 400, q'~
select g.file_id, g.line_number, 'ACCOUNT_COMBINATION' as column_name, g.account_combination as bad_value,
       'Account ' || g.account_combination || ' has DR ' || g.entered_dr || ' and CR ' || g.entered_cr || ' on one line.' as message
  from xxx_fv_gl_balances_v g
  join b on b.batch_id = g.batch_id
 where nvl(g.entered_dr, 0) <> 0
   and nvl(g.entered_cr, 0) <> 0~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('GL_LINE_ZERO', 'ROW_SQL', 'GL_BALANCES', 'INFO', 'Balance line with zero amount',
 'Remove zero lines from the opening balance file.', 410, q'~
select g.file_id, g.line_number, 'ACCOUNT_COMBINATION' as column_name, g.account_combination as bad_value,
       'Account ' || g.account_combination || ' has no debit or credit amount.' as message
  from xxx_fv_gl_balances_v g
  join b on b.batch_id = g.batch_id
 where nvl(g.entered_dr, 0) = 0
   and nvl(g.entered_cr, 0) = 0~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('CE_BALANCE_DATE', 'ROW_SQL', 'CE_BANK_ACCOUNTS', 'WARNING', 'Bank balance not at cutover date',
 'Provide the bank balance as at the cutover date.', 500, q'~
select a.file_id, a.line_number, 'BALANCE_DATE' as column_name, to_char(a.balance_date, 'YYYY-MM-DD') as bad_value,
       'Account ' || a.account_name || ' balance is dated ' || to_char(a.balance_date, 'YYYY-MM-DD')
       || ', cutover is ' || to_char(bt.cutover_date, 'YYYY-MM-DD') || '.' as message
  from xxx_fv_ce_bank_accounts_v a
  join b on b.batch_id = a.batch_id
  join xxx_fv_batches bt on bt.batch_id = a.batch_id
 where a.balance_date <> bt.cutover_date~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('PO_SUPPLIER_EXISTS', 'ROW_SQL', 'PO_ORDERS', 'ERROR', 'PO supplier not in supplier file',
 'Add the supplier to the supplier file, or confirm it already exists in Fusion.', 600, q'~
select p.file_id, p.line_number, 'SUPPLIER_NUMBER' as column_name, p.supplier_number as bad_value,
       'PO ' || p.po_number || ' line ' || p.po_line_number || ': supplier ' || p.supplier_number || ' is not in the supplier file.' as message
  from xxx_fv_po_orders_v p
  join b on b.batch_id = p.batch_id
 where p.supplier_number is not null
   and not exists (select 1
                     from xxx_fv_ap_suppliers_v s
                    where s.batch_id = p.batch_id
                      and s.supplier_number = p.supplier_number)~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('PO_RECEIVED_GT_ORDERED', 'ROW_SQL', 'PO_ORDERS', 'ERROR', 'Received quantity larger than ordered',
 'Correct the received quantity or the ordered quantity.', 610, q'~
select p.file_id, p.line_number, 'QUANTITY_RECEIVED' as column_name, to_char(p.quantity_received) as bad_value,
       'PO ' || p.po_number || ' line ' || p.po_line_number || ': received ' || p.quantity_received
       || ' > ordered ' || p.quantity || '.' as message
  from xxx_fv_po_orders_v p
  join b on b.batch_id = p.batch_id
 where p.quantity_received > p.quantity~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('PO_FULLY_RECEIVED', 'ROW_SQL', 'PO_ORDERS', 'WARNING', 'PO line already fully received',
 'Fully received lines are usually closed in the legacy system, not migrated as open.', 620, q'~
select p.file_id, p.line_number, 'QUANTITY_RECEIVED' as column_name, to_char(p.quantity_received) as bad_value,
       'PO ' || p.po_number || ' line ' || p.po_line_number || ' is fully received (' || p.quantity || ').' as message
  from xxx_fv_po_orders_v p
  join b on b.batch_id = p.batch_id
 where p.quantity_received = p.quantity~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('PO_PRICE_NOT_POSITIVE', 'ROW_SQL', 'PO_ORDERS', 'ERROR', 'Unit price is zero or negative',
 'Provide the agreed unit price.', 630, q'~
select p.file_id, p.line_number, 'UNIT_PRICE' as column_name, to_char(p.unit_price) as bad_value,
       'PO ' || p.po_number || ' line ' || p.po_line_number || ' has unit price ' || p.unit_price || '.' as message
  from xxx_fv_po_orders_v p
  join b on b.batch_id = p.batch_id
 where p.unit_price <= 0~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('PR_NOT_APPROVED', 'ROW_SQL', 'PR_REQUISITIONS', 'WARNING', 'Requisition line not approved',
 'Only approved requisitions are migrated; approve or drop pending and rejected lines.', 700, q'~
select r.file_id, r.line_number, 'APPROVAL_STATUS' as column_name, r.approval_status as bad_value,
       'Requisition ' || r.requisition_number || ' line ' || r.req_line_number || ' is ' || r.approval_status || '.' as message
  from xxx_fv_pr_requisitions_v r
  join b on b.batch_id = r.batch_id
 where r.approval_status <> 'APPROVED'~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, rule_sql) values
('PR_NEED_BY_PAST', 'ROW_SQL', 'PR_REQUISITIONS', 'INFO', 'Need-by date before cutover',
 'Confirm the requirement is still valid, or update the need-by date.', 710, q'~
select r.file_id, r.line_number, 'NEED_BY_DATE' as column_name, to_char(r.need_by_date, 'YYYY-MM-DD') as bad_value,
       'Requisition ' || r.requisition_number || ' line ' || r.req_line_number || ' was needed by '
       || to_char(r.need_by_date, 'YYYY-MM-DD') || '.' as message
  from xxx_fv_pr_requisitions_v r
  join b on b.batch_id = r.batch_id
  join xxx_fv_batches bt on bt.batch_id = r.batch_id
 where r.need_by_date < bt.cutover_date~');

-- -----------------------------------------------------------------------------
-- Reconciliations (RECON)
-- Must return: recon_label, currency_code, source_total, target_total
-- Natural account (segment 3) values below are this demo's chart of accounts.
-- -----------------------------------------------------------------------------
insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, tolerance, rule_sql) values
('GL_TRIAL_BALANCE', 'RECON', 'GL_BALANCES', 'ERROR', 'Trial balance: debits equal credits',
 'The opening balance journal must balance per ledger, period and currency.', 800, 0.01, q'~
select 'Trial balance ' || g.ledger_name || ' ' || g.period_name || ' (DR vs CR)' as recon_label,
       g.currency as currency_code,
       sum(nvl(g.entered_dr, 0)) as source_total,
       sum(nvl(g.entered_cr, 0)) as target_total
  from xxx_fv_gl_balances_v g
  join b on b.batch_id = g.batch_id
 group by g.ledger_name, g.period_name, g.currency~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, tolerance, rule_sql) values
('AP_TO_GL', 'RECON', 'AP_INVOICES', 'WARNING', 'Open AP equals GL liability (21100)',
 'Find the invoices missing from the AP file or the GL journal that explains the gap.', 810, 1, q'~
with ap as (
    select i.invoice_currency as currency_code, sum(i.amount_remaining) as total
      from xxx_fv_ap_invoices_v i
      join b on b.batch_id = i.batch_id
     group by i.invoice_currency),
gl as (
    select g.currency as currency_code, sum(nvl(g.entered_cr, 0) - nvl(g.entered_dr, 0)) as total
      from xxx_fv_gl_balances_v g
      join b on b.batch_id = g.batch_id
     where regexp_substr(g.account_combination, '[^-]+', 1, 3) = '21100'
     group by g.currency)
select 'Open AP vs GL liability 21100' as recon_label,
       coalesce(ap.currency_code, gl.currency_code) as currency_code,
       ap.total as source_total,
       gl.total as target_total
  from ap
  full outer join gl
    on gl.currency_code = ap.currency_code~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, tolerance, rule_sql) values
('AR_TO_GL', 'RECON', 'AR_INVOICES', 'WARNING', 'Open AR equals GL receivables (11300)',
 'Find the transactions missing from the AR file or the GL journal that explains the gap.', 820, 1, q'~
with ar as (
    select t.currency as currency_code, sum(t.amount_due) as total
      from xxx_fv_ar_invoices_v t
      join b on b.batch_id = t.batch_id
     group by t.currency),
gl as (
    select g.currency as currency_code, sum(nvl(g.entered_dr, 0) - nvl(g.entered_cr, 0)) as total
      from xxx_fv_gl_balances_v g
      join b on b.batch_id = g.batch_id
     where regexp_substr(g.account_combination, '[^-]+', 1, 3) = '11300'
     group by g.currency)
select 'Open AR vs GL receivables 11300' as recon_label,
       coalesce(ar.currency_code, gl.currency_code) as currency_code,
       ar.total as source_total,
       gl.total as target_total
  from ar
  full outer join gl
    on gl.currency_code = ar.currency_code~');

insert into xxx_fv_rules (rule_code, rule_type, object_code, severity, title, fix_hint, run_order, tolerance, rule_sql) values
('CASH_TO_GL', 'RECON', 'CE_BANK_ACCOUNTS', 'WARNING', 'Bank balances equal GL cash (11100)',
 'Check unreconciled bank items or accounts missing from the bank file.', 830, 1, q'~
with bank as (
    select a.currency as currency_code, sum(a.opening_balance) as total
      from xxx_fv_ce_bank_accounts_v a
      join b on b.batch_id = a.batch_id
     group by a.currency),
gl as (
    select g.currency as currency_code, sum(nvl(g.entered_dr, 0) - nvl(g.entered_cr, 0)) as total
      from xxx_fv_gl_balances_v g
      join b on b.batch_id = g.batch_id
     where regexp_substr(g.account_combination, '[^-]+', 1, 3) = '11100'
     group by g.currency)
select 'Bank balances vs GL cash 11100' as recon_label,
       coalesce(bank.currency_code, gl.currency_code) as currency_code,
       bank.total as source_total,
       gl.total as target_total
  from bank
  full outer join gl
    on gl.currency_code = bank.currency_code~');
