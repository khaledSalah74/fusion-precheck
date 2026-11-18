"""Writes samples/FBDI_Mapping_Reference.xlsx: app template column -> Oracle Fusion FBDI
template / interface table / column, plus the FBDI-only fields to add when generating
the real load files. 'Verified' = column name confirmed in Oracle documentation;
'Check template' = confirm against the FBDI template of your Fusion release."""
import sys
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

OUT = sys.argv[1] if len(sys.argv) > 1 else 'samples'
V, C = 'Verified', 'Check template'

M = [
 # object, app column, FBDI template, interface table, FBDI column, notes, confidence
 ('GL_BALANCES', 'LEDGER_NAME', 'Journal Import', 'GL_INTERFACE', 'LEDGER_ID', 'Template takes the ledger ID; resolve the ledger name to its ID.', V),
 ('GL_BALANCES', 'PERIOD_NAME', 'Journal Import', 'GL_INTERFACE', 'PERIOD_NAME / ACCOUNTING_DATE', 'ACCOUNTING_DATE (YYYY/MM/DD) assigns the period; use the cutover date.', V),
 ('GL_BALANCES', 'ACCOUNT_COMBINATION', 'Journal Import', 'GL_INTERFACE', 'SEGMENT1..SEGMENT4', 'Split 01-000-21100-00 into one column per segment of your chart of accounts.', V),
 ('GL_BALANCES', 'CURRENCY', 'Journal Import', 'GL_INTERFACE', 'CURRENCY_CODE', 'Foreign currency lines also need conversion type/rate or accounted amounts.', V),
 ('GL_BALANCES', 'ENTERED_DR', 'Journal Import', 'GL_INTERFACE', 'ENTERED_DR', '', V),
 ('GL_BALANCES', 'ENTERED_CR', 'Journal Import', 'GL_INTERFACE', 'ENTERED_CR', '', V),
 ('GL_BALANCES', 'DESCRIPTION', 'Journal Import', 'GL_INTERFACE', 'REFERENCE10', 'Journal line description.', C),

 ('AP_SUPPLIERS', 'SUPPLIER_NUMBER', 'Supplier Import', 'POZ_SUPPLIERS_INT', 'SEGMENT1', 'Only when supplier numbering is manual.', C),
 ('AP_SUPPLIERS', 'SUPPLIER_NAME', 'Supplier Import', 'POZ_SUPPLIERS_INT', 'VENDOR_NAME', 'Max 360.', V),
 ('AP_SUPPLIERS', 'ALTERNATE_NAME', 'Supplier Import', 'POZ_SUPPLIERS_INT', 'VENDOR_NAME_ALT', 'Arabic name.', V),
 ('AP_SUPPLIERS', 'SUPPLIER_TYPE', 'Supplier Import', 'POZ_SUPPLIERS_INT', 'VENDOR_TYPE_LOOKUP_CODE', 'Must be a code of your supplier type lookup.', V),
 ('AP_SUPPLIERS', 'TAX_REGISTRATION_NUMBER', 'Supplier Import', 'POZ_SUPPLIERS_INT', 'TAX_REGISTRATION_NUMBER', 'KSA VAT (15 digits). Also maintain in the party tax profile.', C),
 ('AP_SUPPLIERS', 'COUNTRY', 'Supplier Address Import', 'POZ_SUP_ADDRESSES_INT', 'COUNTRY', 'Address also needs ADDRESS_NAME, ADDRESS_LINE1, CITY.', C),
 ('AP_SUPPLIERS', 'BUSINESS_UNIT', 'Supplier Site / Site Assignment Import', 'POZ_SUPPLIER_SITES_INT / POZ_SITE_ASSIGNMENTS_INT', 'Procurement BU / Client BU', 'Site is created in the procurement BU and assigned to the client (invoicing) BU.', C),
 ('AP_SUPPLIERS', 'SITE_NAME', 'Supplier Site Import', 'POZ_SUPPLIER_SITES_INT', 'VENDOR_SITE_CODE', 'Set pay site / purchasing site flags.', V),
 ('AP_SUPPLIERS', 'PAYMENT_TERMS', 'Supplier Site Import', 'POZ_SUPPLIER_SITES_INT', 'TERMS_NAME', 'Must match a payment term defined in Payables.', V),
 ('AP_SUPPLIERS', 'INVOICE_CURRENCY', 'Supplier Site Import', 'POZ_SUPPLIER_SITES_INT', 'INVOICE_CURRENCY_CODE', '', C),
 ('AP_SUPPLIERS', 'BANK_IBAN', 'Supplier Bank Account Import', 'IBY_TEMP_EXT_BANK_ACCTS', 'IBAN', 'Bank and branch must exist in Cash Management first.', C),
 ('AP_SUPPLIERS', 'EMAIL', 'Supplier Address Import', 'POZ_SUP_ADDRESSES_INT', 'EMAIL_ADDRESS', 'Remittance e-mail.', C),

 ('AP_INVOICES', 'INVOICE_NUMBER', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'INVOICE_NUM', 'Must be unique per supplier.', V),
 ('AP_INVOICES', 'SUPPLIER_NUMBER', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'VENDOR_NUM', 'Supplier must already exist (load suppliers first).', V),
 ('AP_INVOICES', 'BUSINESS_UNIT', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'OPERATING_UNIT', 'Business unit name.', V),
 ('AP_INVOICES', 'INVOICE_TYPE', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'INVOICE_TYPE_LOOKUP_CODE', 'STANDARD or CREDIT; type must match the sign of the amount.', V),
 ('AP_INVOICES', 'INVOICE_DATE', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'INVOICE_DATE', 'FBDI date format is YYYY/MM/DD.', V),
 ('AP_INVOICES', 'INVOICE_CURRENCY', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'INVOICE_CURRENCY_CODE', '', V),
 ('AP_INVOICES', 'INVOICE_AMOUNT', 'Payables Standard Invoice Import', '-', '(reference only)', 'Original amount; keep in DESCRIPTION or a DFF for audit.', V),
 ('AP_INVOICES', 'AMOUNT_REMAINING', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE + AP_INVOICE_LINES_INTERFACE', 'INVOICE_AMOUNT / AMOUNT', 'Open-balance conversion loads the remaining amount as the invoice amount.', V),
 ('AP_INVOICES', 'DUE_DATE', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'TERMS_NAME / TERMS_DATE', 'Fusion derives the due date from terms and terms date.', C),
 ('AP_INVOICES', 'LIABILITY_ACCOUNT', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'ACCTS_PAY_CODE_CONCATENATED', 'Line distribution goes to a conversion clearing account.', C),
 ('AP_INVOICES', 'DESCRIPTION', 'Payables Standard Invoice Import', 'AP_INVOICES_INTERFACE', 'DESCRIPTION', '', C),

 ('AR_CUSTOMERS', 'CUSTOMER_NUMBER', 'Customer Import', 'HZ_IMP_ACCOUNTS_T', 'ACCOUNT_NUMBER (+ CUST_ORIG_SYSTEM_REFERENCE)', 'Source system + reference must be unique.', V),
 ('AR_CUSTOMERS', 'CUSTOMER_NAME', 'Customer Import', 'HZ_IMP_PARTIES_T', 'ORGANIZATION_NAME (+ PARTY_ORIG_SYSTEM_REFERENCE)', 'For PERSON parties use the person name columns.', V),
 ('AR_CUSTOMERS', 'ACCOUNT_TYPE', 'Customer Import', 'HZ_IMP_PARTIES_T', 'PARTY_TYPE', 'ORGANIZATION or PERSON.', C),
 ('AR_CUSTOMERS', 'TAX_REGISTRATION_NUMBER', 'Tax registrations (Party Tax Profile)', '-', 'Tax registration number', 'Not in the customer template; load through Tax setup.', C),
 ('AR_CUSTOMERS', 'COUNTRY', 'Customer Import', 'HZ_IMP_LOCATIONS_T', 'COUNTRY', '', C),
 ('AR_CUSTOMERS', 'BUSINESS_UNIT', 'Customer Import', 'HZ_IMP_ACCTSITES_T', 'Account site set / BU', 'Account site belongs to the reference set of the BU.', C),
 ('AR_CUSTOMERS', 'BILL_TO_SITE', 'Customer Import', 'HZ_IMP_ACCTSITEUSES_T', 'SITE_USE_CODE = BILL_TO', '', C),
 ('AR_CUSTOMERS', 'PAYMENT_TERMS', 'Customer Import', 'RA_CUSTOMER_PROFILES_INT_ALL', 'Standard terms', '', C),
 ('AR_CUSTOMERS', 'CREDIT_LIMIT', 'Customer Import', 'RA_CUSTOMER_PROFILES_INT_ALL', 'Credit limit (profile amount)', '', C),
 ('AR_CUSTOMERS', 'CURRENCY', 'Customer Import', 'RA_CUSTOMER_PROFILES_INT_ALL', 'Profile amount currency', '', C),

 ('AR_INVOICES', 'TRANSACTION_NUMBER', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'TRX_NUMBER', 'Needs a transaction source with manual numbering.', V),
 ('AR_INVOICES', 'CUSTOMER_NUMBER', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'ORIG_SYSTEM_BILL_CUSTOMER_REF', 'Bill-to customer reference.', C),
 ('AR_INVOICES', 'TRANSACTION_TYPE', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'CUST_TRX_TYPE_NAME', 'Credit memos must use a credit memo transaction type.', V),
 ('AR_INVOICES', 'TRANSACTION_DATE', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'TRX_DATE', 'GL_DATE = cutover date.', C),
 ('AR_INVOICES', 'DUE_DATE', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'TERM_NAME', 'Due date derived from terms.', C),
 ('AR_INVOICES', 'CURRENCY', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'CURRENCY_CODE', '', C),
 ('AR_INVOICES', 'ORIGINAL_AMOUNT', 'AutoInvoice Import', '-', '(reference only)', 'Keep for audit.', C),
 ('AR_INVOICES', 'AMOUNT_DUE', 'AutoInvoice Import', 'RA_INTERFACE_LINES_ALL', 'AMOUNT', 'Open-balance conversion loads the amount due.', C),
 ('AR_INVOICES', 'RECEIVABLE_ACCOUNT', 'AutoInvoice Import', 'RA_INTERFACE_DISTRIBUTIONS_ALL', 'Account, ACCOUNT_CLASS = REC', '', C),

 ('CE_BANK_ACCOUNTS', 'BANK_NAME', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Banks sheet', 'Bank Name', 'Rapid implementation spreadsheet, then Upload Banks, Branches, and Accounts.', V),
 ('CE_BANK_ACCOUNTS', 'BRANCH_NAME', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Branches sheet', 'Branch Name', '', V),
 ('CE_BANK_ACCOUNTS', 'ACCOUNT_NAME', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Accounts sheet', 'Account Name', '', C),
 ('CE_BANK_ACCOUNTS', 'ACCOUNT_NUMBER', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Accounts sheet', 'Account Number', '', C),
 ('CE_BANK_ACCOUNTS', 'IBAN', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Accounts sheet', 'IBAN', '', C),
 ('CE_BANK_ACCOUNTS', 'CURRENCY', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Accounts sheet', 'Currency', '', C),
 ('CE_BANK_ACCOUNTS', 'GL_CASH_ACCOUNT', 'Create Banks, Branches, and Accounts in Spreadsheet', 'Accounts sheet', 'Cash account', '', C),
 ('CE_BANK_ACCOUNTS', 'OPENING_BALANCE', 'Journal Import', 'GL_INTERFACE', 'ENTERED_DR on the cash account', 'The cash opening balance is a GL journal line, not part of the bank template.', V),
 ('CE_BANK_ACCOUNTS', 'BALANCE_DATE', 'Journal Import', 'GL_INTERFACE', 'ACCOUNTING_DATE', 'Cutover date.', V),

 ('PO_ORDERS', 'PO_NUMBER', 'Purchase Order Import (Import Orders)', 'PO_HEADERS_INTERFACE', 'DOCUMENT_NUM', '', V),
 ('PO_ORDERS', 'LINE_NUMBER', 'Purchase Order Import (Import Orders)', 'PO_LINES_INTERFACE', 'LINE_NUM', '', C),
 ('PO_ORDERS', 'SUPPLIER_NUMBER', 'Purchase Order Import (Import Orders)', 'PO_HEADERS_INTERFACE', 'VENDOR_NUM / VENDOR_NAME', 'With VENDOR_SITE_CODE = MAIN.', V),
 ('PO_ORDERS', 'BUSINESS_UNIT', 'Purchase Order Import (Import Orders)', 'PO_HEADERS_INTERFACE', 'PRC_BU_NAME (+ REQ_BU_NAME, BILLTO_BU_NAME)', '', C),
 ('PO_ORDERS', 'BUYER_EMAIL', 'Purchase Order Import (Import Orders)', 'PO_HEADERS_INTERFACE', 'AGENT_NAME', 'The template takes the buyer name; map e-mail to the buyer.', C),
 ('PO_ORDERS', 'ITEM_DESCRIPTION', 'Purchase Order Import (Import Orders)', 'PO_LINES_INTERFACE', 'ITEM_DESCRIPTION', '', C),
 ('PO_ORDERS', 'CATEGORY', 'Purchase Order Import (Import Orders)', 'PO_LINES_INTERFACE', 'CATEGORY', '', C),
 ('PO_ORDERS', 'QUANTITY', 'Purchase Order Import (Import Orders)', 'PO_LINES_INTERFACE', 'QUANTITY', 'Open-PO conversion usually loads QUANTITY - QUANTITY_RECEIVED.', C),
 ('PO_ORDERS', 'QUANTITY_RECEIVED', 'Purchase Order Import (Import Orders)', '-', '(validation only)', 'Not loaded; used to calculate the open quantity.', C),
 ('PO_ORDERS', 'UNIT_PRICE', 'Purchase Order Import (Import Orders)', 'PO_LINES_INTERFACE', 'UNIT_PRICE', '', C),
 ('PO_ORDERS', 'CURRENCY', 'Purchase Order Import (Import Orders)', 'PO_HEADERS_INTERFACE', 'CURRENCY_CODE', '', V),
 ('PO_ORDERS', 'NEED_BY_DATE', 'Purchase Order Import (Import Orders)', 'PO_LINE_LOCATIONS_INTERFACE', 'NEED_BY_DATE', '', C),

 ('PR_REQUISITIONS', 'REQUISITION_NUMBER', 'Requisition Import', 'POR_REQ_HEADERS_INTERFACE_ALL', 'REQUISITION_NUMBER', '', C),
 ('PR_REQUISITIONS', 'LINE_NUMBER', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'LINE_NUMBER', '', C),
 ('PR_REQUISITIONS', 'REQUESTER_EMAIL', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'Requester e-mail', 'Requester must be an active worker in Fusion.', C),
 ('PR_REQUISITIONS', 'BUSINESS_UNIT', 'Requisition Import', 'POR_REQ_HEADERS_INTERFACE_ALL', 'REQ_BU_NAME', 'Requisitioning BU.', C),
 ('PR_REQUISITIONS', 'ITEM_DESCRIPTION', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'ITEM_DESCRIPTION', '', C),
 ('PR_REQUISITIONS', 'CATEGORY', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'CATEGORY_NAME', '', C),
 ('PR_REQUISITIONS', 'QUANTITY', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'QUANTITY', '', C),
 ('PR_REQUISITIONS', 'UNIT_PRICE', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'UNIT_PRICE', '', C),
 ('PR_REQUISITIONS', 'CURRENCY', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'CURRENCY_CODE', '', C),
 ('PR_REQUISITIONS', 'NEED_BY_DATE', 'Requisition Import', 'POR_REQ_LINES_INTERFACE_ALL', 'NEED_BY_DATE', '', C),
 ('PR_REQUISITIONS', 'APPROVAL_STATUS', 'Requisition Import', 'POR_REQ_HEADERS_INTERFACE_ALL', 'DOCUMENT_STATUS (+ approver e-mail)', 'Approved import needs the approver e-mail and the Import Approved Requisition privilege.', V),
]

EXTRA = [
 ('Journal Import', 'STATUS = NEW; ACTUAL_FLAG = A; ACCOUNTING_DATE = 2026/12/31; USER_JE_SOURCE_NAME and USER_JE_CATEGORY_NAME (e.g. a "Conversion" source/category); batch and journal names; GROUP_ID'),
 ('Supplier Import', 'Import action CREATE; business relationship (spend authorized); address lines and purposes (ordering, remit-to); site purposes (pay, purchasing); site assignment to the client BU'),
 ('Payables Standard Invoice Import', 'INVOICE_ID linking header and lines; SOURCE; VENDOR_SITE_CODE; one ITEM line per invoice with AMOUNT and a conversion clearing distribution; GL date = cutover'),
 ('Customer Import', 'Source system (registered) and unique source references for party, location, site, account, account site and site use; batch ID; address lines'),
 ('AutoInvoice Import', 'BU_NAME; BATCH_SOURCE_NAME (imported source for conversion); LINE_TYPE = LINE; DESCRIPTION; GL_DATE = cutover; INTERFACE_LINE_CONTEXT + ATTRIBUTEn as unique line key'),
 ('Purchase Order Import', 'INTERFACE_HEADER_KEY / LINE_KEY; ACTION = ORIGINAL; DOCUMENT_TYPE_CODE = STANDARD; ship-to location; distribution charge account; run Import Orders with Approval Action = Bypass Approval to land open POs'),
 ('Requisition Import', 'Header/line/distribution keys; preparer and approver e-mails; destination type; deliver-to location; charge account'),
 ('All FBDI files', 'FBDI dates are YYYY/MM/DD. This app expects YYYY-MM-DD in the validation files; convert when generating the FBDI CSVs.'),
]

# Every rule in xxx_fv_rules (db/09_seed_rules.sql) and the FBDI requirement it protects.
RULES = [
 ('FILE_UNKNOWN_OBJECT', 'WARNING', 'Each FBDI template loads one object; a sheet that is not a migration object has no target. Ignore it in the app if it is notes or a cover page.'),
 ('FILE_MISSING_COLUMN', 'ERROR', 'Mandatory FBDI columns cannot be produced if the source column is missing or unmapped.'),
 ('FILE_UNMAPPED_COLUMN', 'INFO', 'Unmapped data is not carried into the FBDI file.'),
 ('FILE_EMPTY', 'WARNING', 'An empty template produces no interface rows.'),
 ('BATCH_OBJECT_MISSING', 'INFO', 'Object will not be loaded in this cutover (check the load order).'),
 ('COL_REQUIRED', 'ERROR', 'Mandatory interface column would be empty; the import program rejects the row.'),
 ('COL_NUMBER', 'ERROR', 'FBDI numeric columns accept digits and "." only (no thousands separators).'),
 ('COL_DATE', 'ERROR', 'Dates must be valid; they are converted to the FBDI YYYY/MM/DD format.'),
 ('COL_MAX_LENGTH', 'ERROR', 'Value longer than the template column used by the app; check the interface column length of your release.'),
 ('COL_PATTERN', 'ERROR', 'Account segments, KSA VAT, IBAN, e-mail and period formats the load needs.'),
 ('COL_ALLOWED_VALUE', 'ERROR', 'Lookup codes (supplier type, payment terms, BU, currency, category, status) must exist in Fusion with exactly this spelling.'),
 ('COL_DUPLICATE_KEY', 'ERROR', 'FBDI source references / document numbers must be unique.'),
 ('AP_SUP_VAT_MISSING', 'WARNING', 'Saudi suppliers need a tax registration for VAT invoices.'),
 ('AP_SUP_SIMILAR_NAME', 'WARNING', 'Avoid creating the same supplier twice in Supplier Import.'),
 ('AP_INV_SUPPLIER_EXISTS', 'ERROR', 'Invoice import needs an existing supplier and site (load suppliers first).'),
 ('AP_INV_REMAINING_GT_AMOUNT', 'ERROR', 'The open amount loaded cannot exceed the original invoice.'),
 ('AP_INV_SIGN', 'ERROR', 'INVOICE_TYPE_LOOKUP_CODE must match the sign: STANDARD positive, CREDIT negative.'),
 ('AP_INV_AFTER_CUTOVER', 'WARNING', 'Open-balance conversion covers documents up to the cutover date.'),
 ('AP_INV_CURRENCY_DIFF', 'INFO', 'Invoice currency differs from the supplier site default; confirm it is intended.'),
 ('AR_INV_CUSTOMER_EXISTS', 'ERROR', 'AutoInvoice needs an existing bill-to customer.'),
 ('AR_TRX_SIGN', 'ERROR', 'Credit memo types need negative amounts, invoices and debit memos positive.'),
 ('AR_DUE_GT_ORIGINAL', 'ERROR', 'The amount due loaded cannot exceed the original amount.'),
 ('AR_CUST_NO_CREDIT_LIMIT', 'INFO', 'Customer profile without a credit limit.'),
 ('GL_LINE_DR_AND_CR', 'WARNING', 'A GL_INTERFACE line should carry either ENTERED_DR or ENTERED_CR.'),
 ('GL_LINE_ZERO', 'INFO', 'Zero lines add nothing to the opening balance journal.'),
 ('CE_BALANCE_DATE', 'WARNING', 'Cash opening balances are journal lines at the cutover accounting date.'),
 ('PO_SUPPLIER_EXISTS', 'ERROR', 'Purchase order import needs an existing supplier and site.'),
 ('PO_RECEIVED_GT_ORDERED', 'ERROR', 'Open quantity (ordered - received) would be negative.'),
 ('PO_FULLY_RECEIVED', 'WARNING', 'No open quantity: usually not migrated as an open PO.'),
 ('PO_PRICE_NOT_POSITIVE', 'ERROR', 'PO lines need a positive unit price.'),
 ('PR_NOT_APPROVED', 'WARNING', 'Only approved requisitions are migrated (approved import also needs the approver e-mail).'),
 ('PR_NEED_BY_PAST', 'INFO', 'Need-by date before cutover; confirm the requirement is still valid.'),
 ('GL_TRIAL_BALANCE', 'ERROR', 'Journal Import rejects an unbalanced journal: debits must equal credits per ledger, period and currency.'),
 ('AP_TO_GL', 'WARNING', 'Open AP must equal the GL liability, or the conversion clearing account will not net to zero.'),
 ('AR_TO_GL', 'WARNING', 'Open AR must equal the GL receivable, for the same reason.'),
 ('CASH_TO_GL', 'WARNING', 'Bank balances must equal the GL cash accounts.'),
]

# Keep the reference in step with the catalogue: every model column mapped exactly once.
sys.path.insert(0, __import__('os').path.dirname(__file__))
from model import OBJECTS
_model = {(o['code'], c['name']) for o in OBJECTS for c in o['cols']}
_mapped = [(r[0], r[1]) for r in M]
_missing, _extra = sorted(_model - set(_mapped)), sorted(set(_mapped) - _model)
_dups = sorted({k for k in _mapped if _mapped.count(k) > 1})
if _missing or _extra or _dups:
    raise SystemExit(f'FBDI mapping out of step with tools/model.py: missing {_missing}, extra {_extra}, duplicates {_dups}')
# ...and the rule list in step with the seeded rules (code + severity)
import re as _re
_seed = open(__import__('os').path.join(__import__('os').path.dirname(__file__), '..', 'db', '09_seed_rules.sql'), encoding='utf-8').read()
_seeded = {m.group(1): m.group(2) for m in _re.finditer(
    r"insert into xxx_fv_rules[^;]*?values\s*\(\s*'([A-Z_]+)',\s*'[A-Z_]+',\s*(?:'[A-Z_]+',\s*)?'(ERROR|WARNING|INFO)'", _seed)}
_listed = {r[0]: r[1] for r in RULES}
if _seeded != _listed:
    raise SystemExit(f'Rule list out of step with db/09_seed_rules.sql: '
                     f'{sorted(set(_seeded.items()) ^ set(_listed.items()))}')

wb = Workbook()
hf, hfill = Font(bold=True, color='FFFFFF'), PatternFill('solid', fgColor='1F4E78')
ws = wb.active
ws.title = 'Mapping'
ws.append(['App object', 'App column', 'FBDI template', 'Interface table / sheet', 'FBDI column', 'Notes', 'Column name'])
for r in M:
    ws.append(list(r))
ws2 = wb.create_sheet('FBDI-only fields')
ws2.append(['FBDI template', 'Fields to add when generating the real load file'])
for r in EXTRA:
    ws2.append(list(r))
ws3 = wb.create_sheet('Load order')
ws3.append(['Step', 'Load', 'Why'])
for r in [(1, 'Banks, branches, internal bank accounts', 'Supplier bank accounts and cash accounts depend on them'),
          (2, 'Suppliers > addresses > sites > site assignments > bank accounts', 'AP invoices and POs reference supplier sites'),
          (3, 'Customers (parties, accounts, sites, profiles)', 'AR transactions reference bill-to customers'),
          (4, 'Open AP invoices (remaining amount)', 'Clears to a conversion clearing account'),
          (5, 'Open AR transactions (amount due)', 'Clears to a conversion clearing account'),
          (6, 'Open purchase orders (open quantity)', 'Bypass approval to land in Open status'),
          (7, 'Approved requisitions', 'Needs approver e-mail'),
          (8, 'GL opening balance journal', 'Last, so the clearing accounts net to zero and the trial balance ties')]:
    ws3.append(list(r))
ws4 = wb.create_sheet('Validation vs FBDI')
ws4.append(['App rule', 'Severity', 'FBDI requirement it protects'])
for r in RULES:
    ws4.append(list(r))
for sh in (ws, ws2, ws3, ws4):
    for c in sh[1]:
        c.font, c.fill = hf, hfill
    for col in sh.columns:
        width = min(70, max(len(str(c.value or '')) for c in col) + 2)
        sh.column_dimensions[col[0].column_letter].width = width
        for c in col:
            c.alignment = Alignment(wrap_text=True, vertical='top')
    sh.freeze_panes = 'A2'
wb.save(f'{OUT}/FBDI_Mapping_Reference.xlsx')
print(len(M), 'mappings')
