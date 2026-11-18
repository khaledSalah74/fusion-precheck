"""Builds a CLEAN migration pack that should pass every XXX_FV rule (target: READY).
Values follow Oracle Fusion FBDI conventions: invoice type vs sign (CREDIT negative),
credit/debit memo transaction types, open balances only (remaining / due amounts),
open PO lines (received < ordered), approved requisitions, a journal that balances
per currency, real ISO 13616 IBAN check digits and the KSA VAT format.
Plain numbers only (digits and "."; the app rejects thousands separators) and
YYYY-MM-DD dates (FBDI wants YYYY/MM/DD; convert when generating the FBDI files).
The approver e-mail that approved-requisition import needs is not a template column.
Columns, aliases, lengths and allowed values come from tools/model.py: every header is
the column name in Title Case, which the app normalises back to the column name.
Cutover date for the batch: 2026-12-31.
Usage (repo root): python tools/make_valid_pack.py [out_dir]
Check it:          python tools/check_pack.py samples/Valid_Migration_Pack.xlsx"""
import random, sys
from datetime import date, timedelta
from decimal import Decimal
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill, Alignment

random.seed(2026)
OUT = sys.argv[1] if len(sys.argv) > 1 else 'samples'
CUTOVER = date(2026, 12, 31)
L, P = 'KSA Primary Ledger', 'Dec-26'
D = lambda x: Decimal(str(x)).quantize(Decimal('0.01'))
iso = lambda d: d.strftime('%Y-%m-%d')


def iban(bank_code):
    bban = bank_code + ''.join(random.choice('0123456789') for _ in range(18))
    num = int(bban + '2810' + '00')               # S=28, A=10, then 00
    return f'SA{98 - num % 97:02d}{bban}'


def vat():
    return '3' + ''.join(random.choice('0123456789') for _ in range(13)) + '3'


TERMS_DAYS = {'IMMEDIATE': 0, 'NET 30': 30, 'NET 45': 45, 'NET 60': 60}

# --------------------------------------------------------------------------- suppliers
SUP = [  # name, arabic, type, country, currency, bank code
    ('Al Majd Office Furniture', 'المجد للأثاث المكتبي', 'SUPPLIER', 'SA', 'SAR', '80'),
    ('Rawabi IT Services', 'روابي لخدمات تقنية المعلومات', 'SUPPLIER', 'SA', 'SAR', '10'),
    ('Najm Facility Care', 'نجم للعناية بالمرافق', 'CONTRACTOR', 'SA', 'SAR', '20'),
    ('Sahel Logistics', 'الساحل للخدمات اللوجستية', 'SUPPLIER', 'SA', 'SAR', '45'),
    ('Thuraya Printing Press', 'مطبعة الثريا', 'SUPPLIER', 'SA', 'SAR', '05'),
    ('Wahat Catering', 'الواحات للإعاشة', 'SUPPLIER', 'SA', 'SAR', '80'),
    ('Barq Electrical Contracting', 'برق للمقاولات الكهربائية', 'CONTRACTOR', 'SA', 'SAR', '30'),
    ('Masar Travel', 'مسار للسفر والسياحة', 'SUPPLIER', 'SA', 'SAR', '15'),
    ('Afaq Training Center', 'مركز آفاق للتدريب', 'SUPPLIER', 'SA', 'SAR', '60'),
    ('Diyar Security Services', 'ديار للخدمات الأمنية', 'CONTRACTOR', 'SA', 'SAR', '10'),
    ('Nakheel Landscaping', 'النخيل لتنسيق الحدائق', 'CONTRACTOR', 'SA', 'SAR', '20'),
    ('Qimam Stationery', 'قمم للقرطاسية', 'SUPPLIER', 'SA', 'SAR', '80'),
    ('Rimal Water Supply', 'رمال لتوريد المياه', 'SUPPLIER', 'SA', 'SAR', '45'),
    ('Sanabel Medical Supplies', 'سنابل للمستلزمات الطبية', 'SUPPLIER', 'SA', 'SAR', '05'),
    ('Tamkeen HR Consulting', 'تمكين للاستشارات الإدارية', 'CONTRACTOR', 'SA', 'SAR', '30'),
    ('Watan Telecom', 'وطن للاتصالات', 'SUPPLIER', 'SA', 'SAR', '10'),
    ('Yusr Cleaning', 'يسر للنظافة', 'CONTRACTOR', 'SA', 'SAR', '15'),
    ('Zahra Fuel Station', 'محطة الزهراء للوقود', 'SUPPLIER', 'SA', 'SAR', '60'),
    ('Asala Steel Industries', 'أصالة للصناعات الحديدية', 'SUPPLIER', 'SA', 'SAR', '20'),
    ('Bayan Legal Advisory', 'بيان للاستشارات القانونية', 'CONTRACTOR', 'SA', 'SAR', '80'),
    ('Saudi Post Corporate', 'البريد السعودي - الشركات', 'GOVERNMENT', 'SA', 'SAR', '10'),
    ('Muhammad Al-Qahtani', 'محمد القحطاني', 'EMPLOYEE', 'SA', 'SAR', '80'),
    ('Cloudpeak Software Inc', None, 'SUPPLIER', 'US', 'USD', None),
    ('Northgate Analytics LLC', None, 'SUPPLIER', 'US', 'USD', None),
    ('Rheinwerk Engineering GmbH', None, 'SUPPLIER', 'DE', 'EUR', None),
    ('Creek Marine Supplies FZE', None, 'SUPPLIER', 'AE', 'AED', None),
    ('Jumeirah Events LLC', None, 'SUPPLIER', 'AE', 'AED', None),
]
suppliers = []
for i, (name, ar, stype, ctry, cur, bank) in enumerate(SUP, 1):
    no = f'SUP-{10000 + i}'
    bu = 'UAE BU' if ctry == 'AE' else 'KSA BU'
    terms = 'IMMEDIATE' if stype == 'EMPLOYEE' else random.choice(['NET 30', 'NET 45', 'NET 60'])
    email = ''.join(ch for ch in name.lower() if ch.isalnum())[:14] + '.ap@example.com'
    suppliers.append(dict(SUPPLIER_NUMBER=no, SUPPLIER_NAME=name, ALTERNATE_NAME=ar or '',
                          SUPPLIER_TYPE=stype,
                          TAX_REGISTRATION_NUMBER=vat() if ctry == 'SA' and stype != 'EMPLOYEE' else '',
                          COUNTRY=ctry, BUSINESS_UNIT=bu, SITE_NAME='MAIN', PAYMENT_TERMS=terms,
                          INVOICE_CURRENCY=cur, BANK_IBAN=iban(bank) if bank else '', EMAIL=email))

# --------------------------------------------------------------------------- AP invoices
ap = []
for s in suppliers:
    n = 1 if s['SUPPLIER_TYPE'] == 'EMPLOYEE' else random.choice([2, 2, 3])
    for k in range(n):
        inv_date = CUTOVER - timedelta(days=random.randrange(5, 200))
        amt = D(random.randrange(1500, 95000) + random.choice([0, 0.5, 0.75]))
        rem = amt if random.random() < 0.7 else D(amt * Decimal(random.choice(['0.25', '0.5', '0.6'])))
        ap.append(dict(INVOICE_NUMBER=f"{s['SUPPLIER_NUMBER'][-3:]}-INV-{2600 + k + 1}",
                       SUPPLIER_NUMBER=s['SUPPLIER_NUMBER'], BUSINESS_UNIT=s['BUSINESS_UNIT'],
                       INVOICE_TYPE='STANDARD', INVOICE_DATE=iso(inv_date),
                       INVOICE_CURRENCY=s['INVOICE_CURRENCY'], INVOICE_AMOUNT=str(amt), AMOUNT_REMAINING=str(rem),
                       DUE_DATE=iso(inv_date + timedelta(days=TERMS_DAYS[s['PAYMENT_TERMS']])),
                       LIABILITY_ACCOUNT='01-000-21100-00',
                       DESCRIPTION=f"{s['SUPPLIER_NAME'][:40]} - {inv_date.strftime('%b %Y')}"))
# credit memos: negative amount and remaining (FBDI: CREDIT must be negative)
for idx, s in enumerate([suppliers[1], suppliers[4], suppliers[11]], 1):
    amt = D(-random.randrange(800, 6000))
    ap.append(dict(INVOICE_NUMBER=f"{s['SUPPLIER_NUMBER'][-3:]}-CM-{2690 + idx}", SUPPLIER_NUMBER=s['SUPPLIER_NUMBER'],
                   BUSINESS_UNIT=s['BUSINESS_UNIT'], INVOICE_TYPE='CREDIT', INVOICE_DATE=iso(CUTOVER - timedelta(days=20 + idx)),
                   INVOICE_CURRENCY=s['INVOICE_CURRENCY'], INVOICE_AMOUNT=str(amt), AMOUNT_REMAINING=str(amt),
                   DUE_DATE=iso(CUTOVER - timedelta(days=20 + idx)), LIABILITY_ACCOUNT='01-000-21100-00',
                   DESCRIPTION='Credit for returned goods'))

# --------------------------------------------------------------------------- customers
CUS = ['Al Safwa Retail', 'Dar Al Shifa Hospital', 'Eastern Region Municipality', 'Khaleej Contracting',
       'Najran Agricultural Co', 'Red Sea Ports Authority', 'Hijaz Hospitality', 'AlUla Heritage Tours',
       'Al Jouf Schools', 'Taif Rose Perfumes', 'Kharj Dairy Farms', 'Qassim Dates Factory',
       'Rabigh Industrial Services', 'Jubail Polymers', 'Baha Healthcare Clinics', 'Arar Transport Fleet',
       'Tabuk Energy Systems', 'Dhahran Innovation Park', 'Ahsa Food Processing', 'Madinah Book Distributors',
       'Yanbu Desalination Services', 'Sudair Solar Park', 'Abha Mountain Resorts', 'Fahad Al-Shammari', 'Noura Al-Otaibi']
customers = []
for i, n in enumerate(CUS, 1):
    person = n in ('Fahad Al-Shammari', 'Noura Al-Otaibi')
    customers.append(dict(CUSTOMER_NUMBER=f'CUS-{20000 + i}', CUSTOMER_NAME=n,
                          ACCOUNT_TYPE='PERSON' if person else 'ORGANIZATION',
                          TAX_REGISTRATION_NUMBER='' if person else vat(), COUNTRY='SA', BUSINESS_UNIT='KSA BU',
                          BILL_TO_SITE='HEAD OFFICE', PAYMENT_TERMS=random.choice(['NET 30', 'NET 45', 'NET 60']),
                          CREDIT_LIMIT=str(random.choice([20000, 50000]) if person else random.choice([150000, 300000, 750000, 1500000])),
                          CURRENCY='SAR'))

# --------------------------------------------------------------------------- AR transactions
ar = []
seq = 0
for c in customers:
    for _ in range(random.choice([1, 2, 3])):
        seq += 1
        d = CUTOVER - timedelta(days=random.randrange(3, 150))
        amt = D(random.randrange(3000, 180000))
        due = amt if random.random() < 0.75 else D(amt * Decimal('0.5'))
        ar.append(dict(TRANSACTION_NUMBER=f'AR-26-{seq:05d}', CUSTOMER_NUMBER=c['CUSTOMER_NUMBER'],
                       TRANSACTION_TYPE='INV', TRANSACTION_DATE=iso(d),
                       DUE_DATE=iso(d + timedelta(days=TERMS_DAYS[c['PAYMENT_TERMS']])), CURRENCY='SAR',
                       ORIGINAL_AMOUNT=str(amt), AMOUNT_DUE=str(due), RECEIVABLE_ACCOUNT='01-000-11300-00'))
for k, (ttype, amt) in enumerate([('CM', -4200), ('CM', -1750), ('CM', -9800), ('DM', 2500), ('DM', 640)], 1):
    c = customers[k * 3]
    ar.append(dict(TRANSACTION_NUMBER=f'{ttype}-26-{k:04d}', CUSTOMER_NUMBER=c['CUSTOMER_NUMBER'], TRANSACTION_TYPE=ttype,
                   TRANSACTION_DATE=iso(CUTOVER - timedelta(days=10 + k)), DUE_DATE=iso(CUTOVER - timedelta(days=10 + k)),
                   CURRENCY='SAR', ORIGINAL_AMOUNT=f'{amt}.00', AMOUNT_DUE=f'{amt}.00', RECEIVABLE_ACCOUNT='01-000-11300-00'))

# --------------------------------------------------------------------------- bank accounts
banks = []
for bank, branch, acct, cur, code, bal in [
        ('Al Rajhi Bank', 'Olaya Main Branch', 'Operations Account SAR', 'SAR', '80', '5482310.45'),
        ('Saudi National Bank', 'King Fahd Road Branch', 'Payroll Account SAR', 'SAR', '10', '1875000.00'),
        ('Riyad Bank', 'Jeddah Tahlia Branch', 'Collections Account SAR', 'SAR', '20', '964205.30'),
        ('Saudi National Bank', 'King Fahd Road Branch', 'Operations Account USD', 'USD', '10', '318450.00'),
        ('Riyad Bank', 'Jeddah Tahlia Branch', 'Operations Account EUR', 'EUR', '20', '92300.00')]:
    ib = iban(code)
    banks.append(dict(BANK_NAME=bank, BRANCH_NAME=branch, ACCOUNT_NAME=acct, ACCOUNT_NUMBER=ib[-12:], IBAN=ib,
                      CURRENCY=cur, GL_CASH_ACCOUNT='01-000-11100-00', OPENING_BALANCE=bal, BALANCE_DATE=iso(CUTOVER)))

# --------------------------------------------------------------------------- purchase orders (open lines only)
ITEMS = [('Laptop 14 inch business model', 'IT.HARDWARE', 4200), ('Network switch 48 port', 'IT.HARDWARE', 9800),
         ('ERP user licence - annual', 'IT.SOFTWARE', 1450), ('Antivirus subscription - annual', 'IT.SOFTWARE', 320),
         ('Implementation consulting day', 'SERVICES.CONSULTING', 5400), ('HVAC preventive maintenance visit', 'FACILITIES.MAINTENANCE', 2600),
         ('Elevator maintenance - quarterly', 'FACILITIES.MAINTENANCE', 7800), ('A4 copy paper - box of 5 reams', 'OFFICE.SUPPLIES', 95),
         ('Toner cartridge black', 'OFFICE.SUPPLIES', 410)]
sa_suppliers = [s for s in suppliers if s['COUNTRY'] == 'SA' and s['SUPPLIER_TYPE'] != 'EMPLOYEE']
po = []
for p in range(1, 13):
    s = random.choice(sa_suppliers)
    for ln in range(1, random.choice([2, 3, 4]) + 1):
        name, cat, price = random.choice(ITEMS)
        qty = random.choice([4, 10, 20, 40, 100])
        rec = random.choice([0, 0, 0, qty // 4, qty // 2])
        po.append(dict(PO_NUMBER=f'PO-26-{5000 + p}', LINE_NUMBER=str(ln), SUPPLIER_NUMBER=s['SUPPLIER_NUMBER'],
                       BUSINESS_UNIT='KSA BU', BUYER_EMAIL='buyer.ksa@example.com', ITEM_DESCRIPTION=name, CATEGORY=cat,
                       QUANTITY=str(qty), QUANTITY_RECEIVED=str(rec), UNIT_PRICE=f'{price}.00', CURRENCY='SAR',
                       NEED_BY_DATE=iso(date(2027, random.choice([1, 2, 3]), random.choice([10, 20, 28])))))

# --------------------------------------------------------------------------- requisitions (approved only)
pr = []
for r in range(1, 16):
    for ln in (1, 2):
        name, cat, price = random.choice(ITEMS)
        pr.append(dict(REQUISITION_NUMBER=f'REQ-26-{8000 + r}', LINE_NUMBER=str(ln),
                       REQUESTER_EMAIL=f'employee{r:02d}@example.com', BUSINESS_UNIT='KSA BU', ITEM_DESCRIPTION=name,
                       CATEGORY=cat, QUANTITY=str(random.choice([1, 2, 5, 10])), UNIT_PRICE=f'{price}.00', CURRENCY='SAR',
                       NEED_BY_DATE=iso(date(2027, random.choice([1, 2, 3, 4]), random.choice([5, 15, 25]))),
                       APPROVAL_STATUS='APPROVED'))

# --------------------------------------------------------------------------- GL opening balances, balanced per currency
def total(rows, cur_key, amt_key, cur):
    return sum((Decimal(r[amt_key]) for r in rows if r[cur_key] == cur), Decimal('0'))

gl = []
def gl_line(acct, cur, amount, desc):
    """positive amount = debit, negative = credit"""
    amount = D(amount)
    if amount == 0:
        return
    gl.append(dict(LEDGER_NAME=L, PERIOD_NAME=P, ACCOUNT_COMBINATION=acct, CURRENCY=cur,
                   ENTERED_DR=str(amount) if amount > 0 else '', ENTERED_CR=str(-amount) if amount < 0 else '',
                   DESCRIPTION=desc))

currencies = ['SAR', 'USD', 'EUR', 'AED']
for cur in currencies:
    cash = total(banks, 'CURRENCY', 'OPENING_BALANCE', cur)
    arr = total(ar, 'CURRENCY', 'AMOUNT_DUE', cur)
    app = total(ap, 'INVOICE_CURRENCY', 'AMOUNT_REMAINING', cur)
    lines_before = len(gl)
    gl_line('01-000-11100-00', cur, cash, f'Cash and bank balances {cur}')
    gl_line('01-000-11300-00', cur, arr, f'Trade receivables {cur}')
    if cur == 'SAR':
        gl_line('01-000-12100-00', cur, 865000, 'Prepayments')
        gl_line('01-000-14100-00', cur, 2418750.60, 'Inventory')
        gl_line('01-000-15100-00', cur, 11250000, 'Property, plant and equipment - cost')
        gl_line('01-000-15900-00', cur, -3187500, 'Accumulated depreciation')
        gl_line('01-000-22100-00', cur, -512400, 'Accrued expenses')
        gl_line('01-000-23100-00', cur, -286315.25, 'VAT payable')
        gl_line('01-000-31100-00', cur, -8000000, 'Share capital')
    gl_line('01-000-21100-00', cur, -app, f'Trade payables {cur}')
    dr = sum((Decimal(r['ENTERED_DR'] or 0) for r in gl[lines_before:]), Decimal('0'))
    cr = sum((Decimal(r['ENTERED_CR'] or 0) for r in gl[lines_before:]), Decimal('0'))
    gl_line('01-000-32100-00', cur, cr - dr, f'Retained earnings {cur}')

# --------------------------------------------------------------------------- write workbook
SHEETS = [
    ('GL Opening Balances', gl, ['LEDGER_NAME', 'PERIOD_NAME', 'ACCOUNT_COMBINATION', 'CURRENCY', 'ENTERED_DR', 'ENTERED_CR', 'DESCRIPTION']),
    ('Suppliers', suppliers, list(suppliers[0].keys())),
    ('Open AP Invoices', ap, list(ap[0].keys())),
    ('Customers', customers, list(customers[0].keys())),
    ('Open AR Invoices', ar, list(ar[0].keys())),
    ('Bank Accounts', banks, list(banks[0].keys())),
    ('Open Purchase Orders', po, list(po[0].keys())),
    ('Open Requisitions', pr, list(pr[0].keys())),
]
wb = Workbook()
wb.remove(wb.active)
hf, hfill = Font(bold=True, color='FFFFFF'), PatternFill('solid', fgColor='1F4E78')
for title, rows, cols in SHEETS:
    ws = wb.create_sheet(title)
    ws.append([c.replace('_', ' ').title() for c in cols])      # "Supplier Number" -> SUPPLIER_NUMBER after normalisation
    for r in rows:
        ws.append([r[c] for c in cols])
    for c in ws[1]:
        c.font, c.fill = hf, hfill
    for row in ws.iter_rows(min_row=2):
        for c in row:
            c.number_format = '@'
    for i, c in enumerate(cols, 1):
        width = max([len(c)] + [len(str(r[c])) for r in rows]) + 2
        ws.column_dimensions[ws.cell(1, i).column_letter].width = min(45, width)
    ws.freeze_panes = 'A2'
wb.save(f'{OUT}/Valid_Migration_Pack.xlsx')

if __name__ == '__main__':
    print({t: len(r) for t, r, _ in SHEETS})
