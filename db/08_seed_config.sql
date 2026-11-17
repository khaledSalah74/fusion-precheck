-- =============================================================================
-- XXX_FV  seed: objects, columns, allowed values, header aliases
-- (generated from gen/model.py; demo templates inspired by Fusion FBDI objects,
--  not the full FBDI column lists - extend per client)
-- =============================================================================

insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('GL_BALANCES', 'GL', 'GL Opening Balances', 'GL_OPENING_BALANCES', 'GL journal import (GlInterface FBDI) - balances journal', 10, 'Trial balance at cutover, one line per ledger / period / account / currency.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('AP_SUPPLIERS', 'AP', 'Suppliers', 'SUPPLIERS', 'Supplier import (PozSuppliersInt, sites, bank accounts)', 20, 'Supplier master with one site per row and the remit-to bank account.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('AP_INVOICES', 'AP', 'Open AP Invoices', 'OPEN_AP_INVOICES', 'Payables invoice import (ApInvoicesInterface FBDI)', 30, 'Unpaid and partially paid supplier invoices at cutover.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('AR_CUSTOMERS', 'AR', 'Customers', 'CUSTOMERS', 'Customer import (HZ bulk import FBDI)', 40, 'Customer accounts with bill-to site.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('AR_INVOICES', 'AR', 'Open AR Transactions', 'OPEN_AR_INVOICES', 'AutoInvoice import (RaInterfaceLinesAll FBDI)', 50, 'Open receivables (invoices, credit memos, debit memos) at cutover.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('CE_BANK_ACCOUNTS', 'CE', 'Bank Accounts and Balances', 'BANK_ACCOUNTS', 'Bank account import + opening balance', 60, 'Internal bank accounts with cash balance at cutover.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('PO_ORDERS', 'PO', 'Open Purchase Orders', 'OPEN_PURCHASE_ORDERS', 'Purchase order import (PoHeadersInterfaceOrder FBDI)', 70, 'Open PO lines (not fully received / billed) at cutover.');
insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)
values ('PR_REQUISITIONS', 'PR', 'Open Requisitions', 'OPEN_REQUISITIONS', 'Requisition import (PorReqHeadersInterfaceAll FBDI)', 80, 'Approved requisition lines not yet converted to a PO.');

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'LEDGER_NAME', 10, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'PERIOD_NAME', 20, 'VARCHAR2', 15, null, 'Y', 2, '^[A-Z][a-z]{2}-[0-9]{2}$', 'Fusion period name, e.g. Dec-26', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'ACCOUNT_COMBINATION', 30, 'VARCHAR2', 100, null, 'Y', 3, '^[0-9]{2}-[0-9]{3}-[0-9]{5}-[0-9]{2}$', 'Company(2)-CostCenter(3)-Account(5)-Intercompany(2), e.g. 01-000-21100-00', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'CURRENCY', 40, 'VARCHAR2', 3, null, 'Y', 4, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'ENTERED_DR', 50, 'NUMBER', null, null, 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'ENTERED_CR', 60, 'NUMBER', null, null, 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('GL_BALANCES', 'DESCRIPTION', 70, 'VARCHAR2', 240, null, 'N', null, null, null, 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'SUPPLIER_NUMBER', 10, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'SUPPLIER_NAME', 20, 'VARCHAR2', 360, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'ALTERNATE_NAME', 30, 'VARCHAR2', 360, null, 'N', null, null, null, 'N', 'Supplier name in Arabic or another alternate name');
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'SUPPLIER_TYPE', 40, 'VARCHAR2', 30, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'TAX_REGISTRATION_NUMBER', 50, 'VARCHAR2', 20, null, 'N', null, '^3[0-9]{13}3$', 'KSA VAT number: 15 digits, starts and ends with 3', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'COUNTRY', 60, 'VARCHAR2', 2, null, 'Y', null, '^[A-Z]{2}$', 'ISO 3166 two-letter country code', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'BUSINESS_UNIT', 70, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'SITE_NAME', 80, 'VARCHAR2', 40, null, 'Y', 2, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'PAYMENT_TERMS', 90, 'VARCHAR2', 50, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'INVOICE_CURRENCY', 100, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'BANK_IBAN', 110, 'VARCHAR2', 34, null, 'N', null, '^SA[0-9]{22}$', 'Saudi IBAN: SA followed by 22 digits, no spaces', 'Y', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_SUPPLIERS', 'EMAIL', 120, 'VARCHAR2', 240, null, 'N', null, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', 'Valid e-mail address', 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'INVOICE_NUMBER', 10, 'VARCHAR2', 50, null, 'Y', 2, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'SUPPLIER_NUMBER', 20, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'BUSINESS_UNIT', 30, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'INVOICE_TYPE', 40, 'VARCHAR2', 30, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'INVOICE_DATE', 50, 'DATE', null, 'YYYY-MM-DD', 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'INVOICE_CURRENCY', 60, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'INVOICE_AMOUNT', 70, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'AMOUNT_REMAINING', 80, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'DUE_DATE', 90, 'DATE', null, 'YYYY-MM-DD', 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'LIABILITY_ACCOUNT', 100, 'VARCHAR2', 100, null, 'Y', null, '^[0-9]{2}-[0-9]{3}-[0-9]{5}-[0-9]{2}$', 'Company(2)-CostCenter(3)-Account(5)-Intercompany(2), e.g. 01-000-21100-00', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AP_INVOICES', 'DESCRIPTION', 110, 'VARCHAR2', 240, null, 'N', null, null, null, 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'CUSTOMER_NUMBER', 10, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'CUSTOMER_NAME', 20, 'VARCHAR2', 360, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'ACCOUNT_TYPE', 30, 'VARCHAR2', 30, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'TAX_REGISTRATION_NUMBER', 40, 'VARCHAR2', 20, null, 'N', null, '^3[0-9]{13}3$', 'KSA VAT number: 15 digits, starts and ends with 3', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'COUNTRY', 50, 'VARCHAR2', 2, null, 'Y', null, '^[A-Z]{2}$', 'ISO 3166 two-letter country code', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'BUSINESS_UNIT', 60, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'BILL_TO_SITE', 70, 'VARCHAR2', 40, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'PAYMENT_TERMS', 80, 'VARCHAR2', 50, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'CREDIT_LIMIT', 90, 'NUMBER', null, null, 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_CUSTOMERS', 'CURRENCY', 100, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'TRANSACTION_NUMBER', 10, 'VARCHAR2', 50, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'CUSTOMER_NUMBER', 20, 'VARCHAR2', 30, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'TRANSACTION_TYPE', 30, 'VARCHAR2', 10, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'TRANSACTION_DATE', 40, 'DATE', null, 'YYYY-MM-DD', 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'DUE_DATE', 50, 'DATE', null, 'YYYY-MM-DD', 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'CURRENCY', 60, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'ORIGINAL_AMOUNT', 70, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'AMOUNT_DUE', 80, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('AR_INVOICES', 'RECEIVABLE_ACCOUNT', 90, 'VARCHAR2', 100, null, 'Y', null, '^[0-9]{2}-[0-9]{3}-[0-9]{5}-[0-9]{2}$', 'Company(2)-CostCenter(3)-Account(5)-Intercompany(2), e.g. 01-000-21100-00', 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'BANK_NAME', 10, 'VARCHAR2', 360, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'BRANCH_NAME', 20, 'VARCHAR2', 360, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'ACCOUNT_NAME', 30, 'VARCHAR2', 100, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'ACCOUNT_NUMBER', 40, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'Y', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'IBAN', 50, 'VARCHAR2', 34, null, 'N', null, '^SA[0-9]{22}$', 'Saudi IBAN: SA followed by 22 digits, no spaces', 'Y', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'CURRENCY', 60, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'GL_CASH_ACCOUNT', 70, 'VARCHAR2', 100, null, 'Y', null, '^[0-9]{2}-[0-9]{3}-[0-9]{5}-[0-9]{2}$', 'Company(2)-CostCenter(3)-Account(5)-Intercompany(2), e.g. 01-000-21100-00', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'OPENING_BALANCE', 80, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('CE_BANK_ACCOUNTS', 'BALANCE_DATE', 90, 'DATE', null, 'YYYY-MM-DD', 'Y', null, null, null, 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'PO_NUMBER', 10, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'LINE_NUMBER', 20, 'NUMBER', null, null, 'Y', 2, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'SUPPLIER_NUMBER', 30, 'VARCHAR2', 30, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'BUSINESS_UNIT', 40, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'BUYER_EMAIL', 50, 'VARCHAR2', 240, null, 'N', null, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', 'Valid e-mail address', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'ITEM_DESCRIPTION', 60, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'CATEGORY', 70, 'VARCHAR2', 100, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'QUANTITY', 80, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'QUANTITY_RECEIVED', 90, 'NUMBER', null, null, 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'UNIT_PRICE', 100, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'CURRENCY', 110, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PO_ORDERS', 'NEED_BY_DATE', 120, 'DATE', null, 'YYYY-MM-DD', 'N', null, null, null, 'N', null);

insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'REQUISITION_NUMBER', 10, 'VARCHAR2', 30, null, 'Y', 1, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'LINE_NUMBER', 20, 'NUMBER', null, null, 'Y', 2, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'REQUESTER_EMAIL', 30, 'VARCHAR2', 240, null, 'Y', null, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$', 'Valid e-mail address', 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'BUSINESS_UNIT', 40, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'ITEM_DESCRIPTION', 50, 'VARCHAR2', 240, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'CATEGORY', 60, 'VARCHAR2', 100, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'QUANTITY', 70, 'NUMBER', null, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'UNIT_PRICE', 80, 'NUMBER', null, null, 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'CURRENCY', 90, 'VARCHAR2', 3, null, 'Y', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'NEED_BY_DATE', 100, 'DATE', null, 'YYYY-MM-DD', 'N', null, null, null, 'N', null);
insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)
values ('PR_REQUISITIONS', 'APPROVAL_STATUS', 110, 'VARCHAR2', 20, null, 'Y', null, null, null, 'N', null);

insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('GL_BALANCES', 'LEDGER_NAME', 'KSA Primary Ledger');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('GL_BALANCES', 'CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('GL_BALANCES', 'CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('GL_BALANCES', 'CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('GL_BALANCES', 'CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'SUPPLIER_TYPE', 'SUPPLIER');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'SUPPLIER_TYPE', 'CONTRACTOR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'SUPPLIER_TYPE', 'GOVERNMENT');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'SUPPLIER_TYPE', 'EMPLOYEE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'BUSINESS_UNIT', 'KSA BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'BUSINESS_UNIT', 'UAE BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'PAYMENT_TERMS', 'IMMEDIATE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'PAYMENT_TERMS', 'NET 30');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'PAYMENT_TERMS', 'NET 45');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'PAYMENT_TERMS', 'NET 60');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'INVOICE_CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'INVOICE_CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'INVOICE_CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_SUPPLIERS', 'INVOICE_CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'BUSINESS_UNIT', 'KSA BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'BUSINESS_UNIT', 'UAE BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_TYPE', 'STANDARD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_TYPE', 'CREDIT');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_TYPE', 'PREPAYMENT');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AP_INVOICES', 'INVOICE_CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'ACCOUNT_TYPE', 'ORGANIZATION');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'ACCOUNT_TYPE', 'PERSON');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'BUSINESS_UNIT', 'KSA BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'BUSINESS_UNIT', 'UAE BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'PAYMENT_TERMS', 'IMMEDIATE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'PAYMENT_TERMS', 'NET 30');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'PAYMENT_TERMS', 'NET 45');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'PAYMENT_TERMS', 'NET 60');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_CUSTOMERS', 'CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'TRANSACTION_TYPE', 'INV');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'TRANSACTION_TYPE', 'CM');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'TRANSACTION_TYPE', 'DM');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('AR_INVOICES', 'CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('CE_BANK_ACCOUNTS', 'CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('CE_BANK_ACCOUNTS', 'CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('CE_BANK_ACCOUNTS', 'CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('CE_BANK_ACCOUNTS', 'CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'BUSINESS_UNIT', 'KSA BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'BUSINESS_UNIT', 'UAE BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CATEGORY', 'IT.HARDWARE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CATEGORY', 'IT.SOFTWARE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CATEGORY', 'SERVICES.CONSULTING');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CATEGORY', 'FACILITIES.MAINTENANCE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CATEGORY', 'OFFICE.SUPPLIES');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PO_ORDERS', 'CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'BUSINESS_UNIT', 'KSA BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'BUSINESS_UNIT', 'UAE BU');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CATEGORY', 'IT.HARDWARE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CATEGORY', 'IT.SOFTWARE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CATEGORY', 'SERVICES.CONSULTING');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CATEGORY', 'FACILITIES.MAINTENANCE');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CATEGORY', 'OFFICE.SUPPLIES');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CURRENCY', 'SAR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CURRENCY', 'USD');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CURRENCY', 'EUR');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'CURRENCY', 'AED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'APPROVAL_STATUS', 'APPROVED');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'APPROVAL_STATUS', 'PENDING');
insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ('PR_REQUISITIONS', 'APPROVAL_STATUS', 'REJECTED');

insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'LEDGER', 'LEDGER_NAME');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'PERIOD', 'PERIOD_NAME');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'ACCOUNT', 'ACCOUNT_COMBINATION');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'GL_ACCOUNT', 'ACCOUNT_COMBINATION');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'CODE_COMBINATION', 'ACCOUNT_COMBINATION');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'CURRENCY_CODE', 'CURRENCY');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'DEBIT', 'ENTERED_DR');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'DR', 'ENTERED_DR');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'CREDIT', 'ENTERED_CR');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('GL_BALANCES', 'CR', 'ENTERED_CR');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'VENDOR_NO', 'SUPPLIER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'VENDOR_NUMBER', 'SUPPLIER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'SUPPLIER_NO', 'SUPPLIER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'VENDOR_NAME', 'SUPPLIER_NAME');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'VENDOR_TYPE', 'SUPPLIER_TYPE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'VAT_NUMBER', 'TAX_REGISTRATION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'VAT_NO', 'TAX_REGISTRATION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'TRN', 'TAX_REGISTRATION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'BU', 'BUSINESS_UNIT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'SUPPLIER_SITE', 'SITE_NAME');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'SITE', 'SITE_NAME');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'TERMS', 'PAYMENT_TERMS');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'CURRENCY', 'INVOICE_CURRENCY');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'IBAN', 'BANK_IBAN');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_SUPPLIERS', 'EMAIL_ADDRESS', 'EMAIL');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'INVOICE_NUM', 'INVOICE_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'INVOICE_NO', 'INVOICE_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'VENDOR_NO', 'SUPPLIER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'VENDOR_NUMBER', 'SUPPLIER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'BU', 'BUSINESS_UNIT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'CURRENCY', 'INVOICE_CURRENCY');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'AMOUNT', 'INVOICE_AMOUNT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'OPEN_AMOUNT', 'AMOUNT_REMAINING');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AP_INVOICES', 'BALANCE', 'AMOUNT_REMAINING');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_CUSTOMERS', 'CUSTOMER_NO', 'CUSTOMER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_CUSTOMERS', 'ACCOUNT_NUMBER', 'CUSTOMER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_CUSTOMERS', 'VAT_NUMBER', 'TAX_REGISTRATION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_CUSTOMERS', 'TRN', 'TAX_REGISTRATION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_CUSTOMERS', 'BU', 'BUSINESS_UNIT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_CUSTOMERS', 'TERMS', 'PAYMENT_TERMS');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'TRX_NUMBER', 'TRANSACTION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'INVOICE_NUMBER', 'TRANSACTION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'TRX_TYPE', 'TRANSACTION_TYPE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'TRX_DATE', 'TRANSACTION_DATE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'AMOUNT', 'ORIGINAL_AMOUNT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'OPEN_AMOUNT', 'AMOUNT_DUE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('AR_INVOICES', 'BALANCE', 'AMOUNT_DUE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'LINE_NO', 'LINE_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'LINE', 'LINE_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'VENDOR_NO', 'SUPPLIER_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'BU', 'BUSINESS_UNIT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'QTY', 'QUANTITY');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'QTY_RECEIVED', 'QUANTITY_RECEIVED');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PO_ORDERS', 'PRICE', 'UNIT_PRICE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'REQ_NUMBER', 'REQUISITION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'REQ_NO', 'REQUISITION_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'LINE_NO', 'LINE_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'LINE', 'LINE_NUMBER');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'BU', 'BUSINESS_UNIT');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'QTY', 'QUANTITY');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'PRICE', 'UNIT_PRICE');
insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ('PR_REQUISITIONS', 'STATUS', 'APPROVAL_STATUS');
