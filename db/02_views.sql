-- =============================================================================
-- XXX_FV  typed pivot views over staging, one per object (generated from gen/model.py)
-- Values that fail conversion become NULL here; the column checks report them.
-- =============================================================================

create or replace view xxx_fv_gl_balances_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'LEDGER_NAME' then v.cell_value end) as ledger_name,
       max(case when v.column_name = 'PERIOD_NAME' then v.cell_value end) as period_name,
       max(case when v.column_name = 'ACCOUNT_COMBINATION' then v.cell_value end) as account_combination,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_number(max(case when v.column_name = 'ENTERED_DR' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as entered_dr,
       to_number(max(case when v.column_name = 'ENTERED_CR' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as entered_cr,
       max(case when v.column_name = 'DESCRIPTION' then v.cell_value end) as description
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'GL_BALANCES'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_ap_suppliers_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'SUPPLIER_NUMBER' then v.cell_value end) as supplier_number,
       max(case when v.column_name = 'SUPPLIER_NAME' then v.cell_value end) as supplier_name,
       max(case when v.column_name = 'ALTERNATE_NAME' then v.cell_value end) as alternate_name,
       max(case when v.column_name = 'SUPPLIER_TYPE' then v.cell_value end) as supplier_type,
       max(case when v.column_name = 'TAX_REGISTRATION_NUMBER' then v.cell_value end) as tax_registration_number,
       max(case when v.column_name = 'COUNTRY' then v.cell_value end) as country,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'SITE_NAME' then v.cell_value end) as site_name,
       max(case when v.column_name = 'PAYMENT_TERMS' then v.cell_value end) as payment_terms,
       max(case when v.column_name = 'INVOICE_CURRENCY' then v.cell_value end) as invoice_currency,
       max(case when v.column_name = 'BANK_IBAN' then v.cell_value end) as bank_iban,
       max(case when v.column_name = 'EMAIL' then v.cell_value end) as email
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AP_SUPPLIERS'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_ap_invoices_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'INVOICE_NUMBER' then v.cell_value end) as invoice_number,
       max(case when v.column_name = 'SUPPLIER_NUMBER' then v.cell_value end) as supplier_number,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'INVOICE_TYPE' then v.cell_value end) as invoice_type,
       to_date(max(case when v.column_name = 'INVOICE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as invoice_date,
       max(case when v.column_name = 'INVOICE_CURRENCY' then v.cell_value end) as invoice_currency,
       to_number(max(case when v.column_name = 'INVOICE_AMOUNT' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as invoice_amount,
       to_number(max(case when v.column_name = 'AMOUNT_REMAINING' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as amount_remaining,
       to_date(max(case when v.column_name = 'DUE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as due_date,
       max(case when v.column_name = 'LIABILITY_ACCOUNT' then v.cell_value end) as liability_account,
       max(case when v.column_name = 'DESCRIPTION' then v.cell_value end) as description
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AP_INVOICES'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_ar_customers_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'CUSTOMER_NUMBER' then v.cell_value end) as customer_number,
       max(case when v.column_name = 'CUSTOMER_NAME' then v.cell_value end) as customer_name,
       max(case when v.column_name = 'ACCOUNT_TYPE' then v.cell_value end) as account_type,
       max(case when v.column_name = 'TAX_REGISTRATION_NUMBER' then v.cell_value end) as tax_registration_number,
       max(case when v.column_name = 'COUNTRY' then v.cell_value end) as country,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'BILL_TO_SITE' then v.cell_value end) as bill_to_site,
       max(case when v.column_name = 'PAYMENT_TERMS' then v.cell_value end) as payment_terms,
       to_number(max(case when v.column_name = 'CREDIT_LIMIT' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as credit_limit,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AR_CUSTOMERS'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_ar_invoices_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'TRANSACTION_NUMBER' then v.cell_value end) as transaction_number,
       max(case when v.column_name = 'CUSTOMER_NUMBER' then v.cell_value end) as customer_number,
       max(case when v.column_name = 'TRANSACTION_TYPE' then v.cell_value end) as transaction_type,
       to_date(max(case when v.column_name = 'TRANSACTION_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as transaction_date,
       to_date(max(case when v.column_name = 'DUE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as due_date,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_number(max(case when v.column_name = 'ORIGINAL_AMOUNT' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as original_amount,
       to_number(max(case when v.column_name = 'AMOUNT_DUE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as amount_due,
       max(case when v.column_name = 'RECEIVABLE_ACCOUNT' then v.cell_value end) as receivable_account
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AR_INVOICES'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_ce_bank_accounts_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'BANK_NAME' then v.cell_value end) as bank_name,
       max(case when v.column_name = 'BRANCH_NAME' then v.cell_value end) as branch_name,
       max(case when v.column_name = 'ACCOUNT_NAME' then v.cell_value end) as account_name,
       max(case when v.column_name = 'ACCOUNT_NUMBER' then v.cell_value end) as account_number,
       max(case when v.column_name = 'IBAN' then v.cell_value end) as iban,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       max(case when v.column_name = 'GL_CASH_ACCOUNT' then v.cell_value end) as gl_cash_account,
       to_number(max(case when v.column_name = 'OPENING_BALANCE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as opening_balance,
       to_date(max(case when v.column_name = 'BALANCE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as balance_date
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'CE_BANK_ACCOUNTS'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_po_orders_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'PO_NUMBER' then v.cell_value end) as po_number,
       to_number(max(case when v.column_name = 'LINE_NUMBER' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as po_line_number,
       max(case when v.column_name = 'SUPPLIER_NUMBER' then v.cell_value end) as supplier_number,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'BUYER_EMAIL' then v.cell_value end) as buyer_email,
       max(case when v.column_name = 'ITEM_DESCRIPTION' then v.cell_value end) as item_description,
       max(case when v.column_name = 'CATEGORY' then v.cell_value end) as category,
       to_number(max(case when v.column_name = 'QUANTITY' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as quantity,
       to_number(max(case when v.column_name = 'QUANTITY_RECEIVED' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as quantity_received,
       to_number(max(case when v.column_name = 'UNIT_PRICE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as unit_price,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_date(max(case when v.column_name = 'NEED_BY_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as need_by_date
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'PO_ORDERS'
 group by f.batch_id, l.file_id, l.line_number;

create or replace view xxx_fv_pr_requisitions_v as
select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'REQUISITION_NUMBER' then v.cell_value end) as requisition_number,
       to_number(max(case when v.column_name = 'LINE_NUMBER' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as req_line_number,
       max(case when v.column_name = 'REQUESTER_EMAIL' then v.cell_value end) as requester_email,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'ITEM_DESCRIPTION' then v.cell_value end) as item_description,
       max(case when v.column_name = 'CATEGORY' then v.cell_value end) as category,
       to_number(max(case when v.column_name = 'QUANTITY' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as quantity,
       to_number(max(case when v.column_name = 'UNIT_PRICE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as unit_price,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_date(max(case when v.column_name = 'NEED_BY_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as need_by_date,
       max(case when v.column_name = 'APPROVAL_STATUS' then v.cell_value end) as approval_status
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'PR_REQUISITIONS'
 group by f.batch_id, l.file_id, l.line_number;
