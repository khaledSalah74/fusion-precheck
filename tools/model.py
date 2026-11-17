"""Single source of truth for the demo object/column catalogue.
Generates db/02_views.sql and db/08_seed_config.sql so seed, views and samples never drift."""

COA_RE = r'^[0-9]{2}-[0-9]{3}-[0-9]{5}-[0-9]{2}$'
COA_HINT = 'Company(2)-CostCenter(3)-Account(5)-Intercompany(2), e.g. 01-000-21100-00'
VAT_RE = r'^3[0-9]{13}3$'
VAT_HINT = 'KSA VAT number: 15 digits, starts and ends with 3'
IBAN_RE = r'^SA[0-9]{22}$'
IBAN_HINT = 'Saudi IBAN: SA followed by 22 digits, no spaces'
EMAIL_RE = r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
EMAIL_HINT = 'Valid e-mail address'
CTRY_RE = r'^[A-Z]{2}$'
CTRY_HINT = 'ISO 3166 two-letter country code'

BU = ['KSA BU', 'UAE BU']
CUR = ['SAR', 'USD', 'EUR', 'AED']
TERMS = ['IMMEDIATE', 'NET 30', 'NET 45', 'NET 60']
CATS = ['IT.HARDWARE', 'IT.SOFTWARE', 'SERVICES.CONSULTING', 'FACILITIES.MAINTENANCE', 'OFFICE.SUPPLIES']

def col(name, dtype='VARCHAR2', length=None, req=False, uk=None, regex=None, hint=None,
        sens=False, allowed=None, aliases=None, desc=None, fmt=None, view_col=None):
    # view_col: column alias in the typed view when the name clashes with the fixed
    # batch_id / file_id / line_number columns (line_number is the staging file row).
    return dict(name=name, dtype=dtype, length=length, req=req, uk=uk, regex=regex, hint=hint,
                sens=sens, allowed=allowed or [], aliases=aliases or [], desc=desc,
                view_col=(view_col or name).lower(),
                fmt=fmt or ('YYYY-MM-DD' if dtype == 'DATE' else None))

OBJECTS = [
    dict(code='GL_BALANCES', module='GL', name='GL Opening Balances', alias='GL_OPENING_BALANCES',
         target='GL journal import (GlInterface FBDI) - balances journal', order=10,
         desc='Trial balance at cutover, one line per ledger / period / account / currency.',
         view='xxx_fv_gl_balances_v',
         cols=[
             col('LEDGER_NAME', length=30, req=True, uk=1, allowed=['KSA Primary Ledger'], aliases=['LEDGER']),
             col('PERIOD_NAME', length=15, req=True, uk=2, regex=r'^[A-Z][a-z]{2}-[0-9]{2}$', hint='Fusion period name, e.g. Dec-26', aliases=['PERIOD']),
             col('ACCOUNT_COMBINATION', length=100, req=True, uk=3, regex=COA_RE, hint=COA_HINT, aliases=['ACCOUNT', 'GL_ACCOUNT', 'CODE_COMBINATION']),
             col('CURRENCY', length=3, req=True, uk=4, allowed=CUR, aliases=['CURRENCY_CODE']),
             col('ENTERED_DR', 'NUMBER', aliases=['DEBIT', 'DR']),
             col('ENTERED_CR', 'NUMBER', aliases=['CREDIT', 'CR']),
             col('DESCRIPTION', length=240),
         ]),
    dict(code='AP_SUPPLIERS', module='AP', name='Suppliers', alias='SUPPLIERS',
         target='Supplier import (PozSuppliersInt, sites, bank accounts)', order=20,
         desc='Supplier master with one site per row and the remit-to bank account.',
         view='xxx_fv_ap_suppliers_v',
         cols=[
             col('SUPPLIER_NUMBER', length=30, req=True, uk=1, aliases=['VENDOR_NO', 'VENDOR_NUMBER', 'SUPPLIER_NO']),
             col('SUPPLIER_NAME', length=360, req=True, aliases=['VENDOR_NAME']),
             col('ALTERNATE_NAME', length=360, desc='Supplier name in Arabic or another alternate name'),
             col('SUPPLIER_TYPE', length=30, req=True, allowed=['SUPPLIER', 'CONTRACTOR', 'GOVERNMENT', 'EMPLOYEE'], aliases=['VENDOR_TYPE']),
             col('TAX_REGISTRATION_NUMBER', length=20, regex=VAT_RE, hint=VAT_HINT, aliases=['VAT_NUMBER', 'VAT_NO', 'TRN']),
             col('COUNTRY', length=2, req=True, regex=CTRY_RE, hint=CTRY_HINT),
             col('BUSINESS_UNIT', length=240, req=True, allowed=BU, aliases=['BU']),
             col('SITE_NAME', length=40, req=True, uk=2, aliases=['SUPPLIER_SITE', 'SITE']),
             col('PAYMENT_TERMS', length=50, req=True, allowed=TERMS, aliases=['TERMS']),
             col('INVOICE_CURRENCY', length=3, req=True, allowed=CUR, aliases=['CURRENCY']),
             col('BANK_IBAN', length=34, regex=IBAN_RE, hint=IBAN_HINT, sens=True, aliases=['IBAN']),
             col('EMAIL', length=240, regex=EMAIL_RE, hint=EMAIL_HINT, aliases=['EMAIL_ADDRESS']),
         ]),
    dict(code='AP_INVOICES', module='AP', name='Open AP Invoices', alias='OPEN_AP_INVOICES',
         target='Payables invoice import (ApInvoicesInterface FBDI)', order=30,
         desc='Unpaid and partially paid supplier invoices at cutover.',
         view='xxx_fv_ap_invoices_v',
         cols=[
             col('INVOICE_NUMBER', length=50, req=True, uk=2, aliases=['INVOICE_NUM', 'INVOICE_NO']),
             col('SUPPLIER_NUMBER', length=30, req=True, uk=1, aliases=['VENDOR_NO', 'VENDOR_NUMBER']),
             col('BUSINESS_UNIT', length=240, req=True, allowed=BU, aliases=['BU']),
             col('INVOICE_TYPE', length=30, req=True, allowed=['STANDARD', 'CREDIT', 'PREPAYMENT']),
             col('INVOICE_DATE', 'DATE', req=True),
             col('INVOICE_CURRENCY', length=3, req=True, allowed=CUR, aliases=['CURRENCY']),
             col('INVOICE_AMOUNT', 'NUMBER', req=True, aliases=['AMOUNT']),
             col('AMOUNT_REMAINING', 'NUMBER', req=True, aliases=['OPEN_AMOUNT', 'BALANCE']),
             col('DUE_DATE', 'DATE'),
             col('LIABILITY_ACCOUNT', length=100, req=True, regex=COA_RE, hint=COA_HINT),
             col('DESCRIPTION', length=240),
         ]),
    dict(code='AR_CUSTOMERS', module='AR', name='Customers', alias='CUSTOMERS',
         target='Customer import (HZ bulk import FBDI)', order=40,
         desc='Customer accounts with bill-to site.',
         view='xxx_fv_ar_customers_v',
         cols=[
             col('CUSTOMER_NUMBER', length=30, req=True, uk=1, aliases=['CUSTOMER_NO', 'ACCOUNT_NUMBER']),
             col('CUSTOMER_NAME', length=360, req=True),
             col('ACCOUNT_TYPE', length=30, req=True, allowed=['ORGANIZATION', 'PERSON']),
             col('TAX_REGISTRATION_NUMBER', length=20, regex=VAT_RE, hint=VAT_HINT, aliases=['VAT_NUMBER', 'TRN']),
             col('COUNTRY', length=2, req=True, regex=CTRY_RE, hint=CTRY_HINT),
             col('BUSINESS_UNIT', length=240, req=True, allowed=BU, aliases=['BU']),
             col('BILL_TO_SITE', length=40, req=True),
             col('PAYMENT_TERMS', length=50, req=True, allowed=TERMS, aliases=['TERMS']),
             col('CREDIT_LIMIT', 'NUMBER'),
             col('CURRENCY', length=3, req=True, allowed=CUR),
         ]),
    dict(code='AR_INVOICES', module='AR', name='Open AR Transactions', alias='OPEN_AR_INVOICES',
         target='AutoInvoice import (RaInterfaceLinesAll FBDI)', order=50,
         desc='Open receivables (invoices, credit memos, debit memos) at cutover.',
         view='xxx_fv_ar_invoices_v',
         cols=[
             col('TRANSACTION_NUMBER', length=50, req=True, uk=1, aliases=['TRX_NUMBER', 'INVOICE_NUMBER']),
             col('CUSTOMER_NUMBER', length=30, req=True),
             col('TRANSACTION_TYPE', length=10, req=True, allowed=['INV', 'CM', 'DM'], aliases=['TRX_TYPE']),
             col('TRANSACTION_DATE', 'DATE', req=True, aliases=['TRX_DATE']),
             col('DUE_DATE', 'DATE'),
             col('CURRENCY', length=3, req=True, allowed=CUR),
             col('ORIGINAL_AMOUNT', 'NUMBER', req=True, aliases=['AMOUNT']),
             col('AMOUNT_DUE', 'NUMBER', req=True, aliases=['OPEN_AMOUNT', 'BALANCE']),
             col('RECEIVABLE_ACCOUNT', length=100, req=True, regex=COA_RE, hint=COA_HINT),
         ]),
    dict(code='CE_BANK_ACCOUNTS', module='CE', name='Bank Accounts and Balances', alias='BANK_ACCOUNTS',
         target='Bank account import + opening balance', order=60,
         desc='Internal bank accounts with cash balance at cutover.',
         view='xxx_fv_ce_bank_accounts_v',
         cols=[
             col('BANK_NAME', length=360, req=True),
             col('BRANCH_NAME', length=360, req=True),
             col('ACCOUNT_NAME', length=100, req=True),
             col('ACCOUNT_NUMBER', length=30, req=True, uk=1, sens=True),
             col('IBAN', length=34, regex=IBAN_RE, hint=IBAN_HINT, sens=True),
             col('CURRENCY', length=3, req=True, allowed=CUR),
             col('GL_CASH_ACCOUNT', length=100, req=True, regex=COA_RE, hint=COA_HINT),
             col('OPENING_BALANCE', 'NUMBER', req=True),
             col('BALANCE_DATE', 'DATE', req=True),
         ]),
    dict(code='PO_ORDERS', module='PO', name='Open Purchase Orders', alias='OPEN_PURCHASE_ORDERS',
         target='Purchase order import (PoHeadersInterfaceOrder FBDI)', order=70,
         desc='Open PO lines (not fully received / billed) at cutover.',
         view='xxx_fv_po_orders_v',
         cols=[
             col('PO_NUMBER', length=30, req=True, uk=1),
             col('LINE_NUMBER', 'NUMBER', req=True, uk=2, aliases=['LINE_NO', 'LINE'], view_col='PO_LINE_NUMBER'),
             col('SUPPLIER_NUMBER', length=30, req=True, aliases=['VENDOR_NO']),
             col('BUSINESS_UNIT', length=240, req=True, allowed=BU, aliases=['BU']),
             col('BUYER_EMAIL', length=240, regex=EMAIL_RE, hint=EMAIL_HINT),
             col('ITEM_DESCRIPTION', length=240, req=True),
             col('CATEGORY', length=100, req=True, allowed=CATS),
             col('QUANTITY', 'NUMBER', req=True, aliases=['QTY']),
             col('QUANTITY_RECEIVED', 'NUMBER', aliases=['QTY_RECEIVED']),
             col('UNIT_PRICE', 'NUMBER', req=True, aliases=['PRICE']),
             col('CURRENCY', length=3, req=True, allowed=CUR),
             col('NEED_BY_DATE', 'DATE'),
         ]),
    dict(code='PR_REQUISITIONS', module='PR', name='Open Requisitions', alias='OPEN_REQUISITIONS',
         target='Requisition import (PorReqHeadersInterfaceAll FBDI)', order=80,
         desc='Approved requisition lines not yet converted to a PO.',
         view='xxx_fv_pr_requisitions_v',
         cols=[
             col('REQUISITION_NUMBER', length=30, req=True, uk=1, aliases=['REQ_NUMBER', 'REQ_NO']),
             col('LINE_NUMBER', 'NUMBER', req=True, uk=2, aliases=['LINE_NO', 'LINE'], view_col='REQ_LINE_NUMBER'),
             col('REQUESTER_EMAIL', length=240, req=True, regex=EMAIL_RE, hint=EMAIL_HINT),
             col('BUSINESS_UNIT', length=240, req=True, allowed=BU, aliases=['BU']),
             col('ITEM_DESCRIPTION', length=240, req=True),
             col('CATEGORY', length=100, req=True, allowed=CATS),
             col('QUANTITY', 'NUMBER', req=True, aliases=['QTY']),
             col('UNIT_PRICE', 'NUMBER', aliases=['PRICE']),
             col('CURRENCY', length=3, req=True, allowed=CUR),
             col('NEED_BY_DATE', 'DATE'),
             col('APPROVAL_STATUS', length=20, req=True, allowed=['APPROVED', 'PENDING', 'REJECTED'], aliases=['STATUS']),
         ]),
]


def q(s):
    return 'null' if s is None else "'" + str(s).replace("'", "''") + "'"


def num(n):
    return 'null' if n is None else str(n)


# Same number test as the rules engine (^-?[0-9]+(\.[0-9]+)?$): to_number on its own
# silently accepts "12,500.00", so a value flagged as invalid would still be summed.
NUM_EXPR = ("to_number(max(case when v.column_name = '{c}' "
            "and regexp_like(v.cell_value, '^-?[0-9]+(\\.[0-9]+)?$') then v.cell_value end) "
            "default null on conversion error, '999999999999999999990D9999999999', "
            "'NLS_NUMERIC_CHARACTERS=''.,''')")
DATE_EXPR = ("to_date(max(case when v.column_name = '{c}' then v.cell_value end) "
             "default null on conversion error, '{fmt}')")
TXT_EXPR = "max(case when v.column_name = '{c}' then v.cell_value end)"


def views_sql():
    out = ['-- =============================================================================',
           '-- XXX_FV  typed pivot views over staging, one per object (generated from gen/model.py)',
           '-- Values that fail conversion become NULL here; the column checks report them.',
           '-- =============================================================================', '']
    for o in OBJECTS:
        lines = []
        for c in o['cols']:
            if c['dtype'] == 'NUMBER':
                e = NUM_EXPR.format(c=c['name'])
            elif c['dtype'] == 'DATE':
                e = DATE_EXPR.format(c=c['name'], fmt=c['fmt'])
            else:
                e = TXT_EXPR.format(c=c['name'])
            lines.append(f"       {e} as {c['view_col']}")
        out.append(f"create or replace view {o['view']} as")
        out.append('select f.batch_id,')
        out.append('       l.file_id,')
        out.append('       l.line_number,')
        out.append(',\n'.join(lines))
        out.append('  from xxx_fv_files f')
        out.append('  join xxx_fv_stage_lines l')
        out.append('    on l.file_id = f.file_id')
        out.append('  left join xxx_fv_stage_values v')
        out.append('    on v.file_id = l.file_id')
        out.append('   and v.line_number = l.line_number')
        out.append(f" where f.object_code = '{o['code']}'")
        out.append(' group by f.batch_id, l.file_id, l.line_number;')
        out.append('')
    return '\n'.join(out)


def seed_sql():
    out = ['-- =============================================================================',
           '-- XXX_FV  seed: objects, columns, allowed values, header aliases',
           '-- (generated from gen/model.py; demo templates inspired by Fusion FBDI objects,',
           '--  not the full FBDI column lists - extend per client)',
           '-- =============================================================================', '']
    for o in OBJECTS:
        out.append('insert into xxx_fv_objects (object_code, module_code, object_name, sheet_alias, fusion_target, load_order, description)')
        out.append(f"values ({q(o['code'])}, {q(o['module'])}, {q(o['name'])}, {q(o['alias'])}, {q(o['target'])}, {o['order']}, {q(o['desc'])});")
    out.append('')
    for o in OBJECTS:
        for i, c in enumerate(o['cols'], 1):
            out.append('insert into xxx_fv_columns (object_code, column_name, column_seq, data_type, max_length, date_format, '
                       'is_required, unique_key_seq, regex_pattern, pattern_hint, is_sensitive, description)')
            out.append(f"values ({q(o['code'])}, {q(c['name'])}, {i * 10}, {q(c['dtype'])}, {num(c['length'])}, {q(c['fmt'])}, "
                       f"{q('Y' if c['req'] else 'N')}, {num(c['uk'])}, {q(c['regex'])}, {q(c['hint'])}, "
                       f"{q('Y' if c['sens'] else 'N')}, {q(c['desc'])});")
        out.append('')
    for o in OBJECTS:
        for c in o['cols']:
            for v in c['allowed']:
                out.append(f"insert into xxx_fv_column_values (object_code, column_name, allowed_value) values ({q(o['code'])}, {q(c['name'])}, {q(v)});")
    out.append('')
    for o in OBJECTS:
        for c in o['cols']:
            for a in c['aliases']:
                out.append(f"insert into xxx_fv_column_aliases (object_code, alias_norm, column_name) values ({q(o['code'])}, {q(a)}, {q(c['name'])});")
    out.append('')
    return '\n'.join(out)


if __name__ == '__main__':
    import sys
    base = (sys.argv[1] if len(sys.argv) > 1 else '.')
    open(f'{base}/db/02_views.sql', 'w', newline='\n').write(views_sql())
    open(f'{base}/db/08_seed_config.sql', 'w', newline='\n').write(seed_sql())
    print('ok')
