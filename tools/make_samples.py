"""Builds the demo migration pack with deliberate data problems.
GL balances are derived from the sub-ledger files so the reconciliations land on
known outcomes: AP SAR off by exactly 12,500.00, EUR AP has no GL balance,
trial balance off by 3,250.00, AR and cash reconcile."""
import csv, random, re, sys
from decimal import Decimal
from openpyxl import Workbook
from openpyxl.styles import Font, PatternFill

random.seed(26)
OUT = sys.argv[1] if len(sys.argv) > 1 else 'samples'
CUTOVER = '2026-12-31'
NUM_RE = re.compile(r'^-?[0-9]+(\.[0-9]+)?$')

def d(x):
    return Decimal(str(x)).quantize(Decimal('0.01'))

def parsed(v):
    """What the engine sees: invalid numbers become NULL (0 in sums)."""
    return Decimal(v) if v and NUM_RE.match(v) else Decimal('0')

def iban():
    return 'SA' + ''.join(random.choice('0123456789') for _ in range(22))

def vat():
    return '3' + ''.join(random.choice('0123456789') for _ in range(13)) + '3'

# ----------------------------------------------------------------- suppliers
sup_names = [
    ('Al-Rajhi Trading Co.', 'شركة الراجحي للتجارة'), ('Gulf Office Supplies', 'الخليج للأدوات المكتبية'),
    ('Najd IT Solutions', 'نجد لحلول تقنية المعلومات'), ('Red Sea Logistics', 'البحر الأحمر للخدمات اللوجستية'),
    ('Riyadh Facilities Management', 'الرياض لإدارة المرافق'), ('Desert Consulting Group', 'مجموعة الصحراء للاستشارات'),
    ('Eastern Province Electric', 'كهرباء المنطقة الشرقية'), ('Tabuk Catering Est.', 'مؤسسة تبوك للإعاشة'),
    ('Jeddah Print House', 'دار جدة للطباعة'), ('Oasis Cleaning Services', 'الواحة لخدمات النظافة'),
    ('Makkah Security Co.', 'شركة مكة للحراسات'), ('Dammam Steel Works', 'الدمام لأعمال الحديد'),
    ('Asir Travel Agency', 'وكالة عسير للسفر'), ('Hail Water Company', 'شركة حائل للمياه'),
    ('Medina Furniture', 'المدينة للأثاث'), ('Qassim Fuel Station', 'محطة القصيم للوقود'),
    ('Global Software LLC', None), ('Euro Tech GmbH', None),
    ('AL RAJHI TRADING COMPANY', 'الراجحي للتجارة'), ('Khobar Telecom', 'الخبر للاتصالات'),
    ('Yanbu Chemicals', 'ينبع للكيماويات'), ('Abha Medical Supplies', 'أبها للمستلزمات الطبية'),
    ('Ministry Liaison Office', 'مكتب الارتباط الوزاري'), ('Ahmed Al-Ghamdi (Employee)', 'أحمد الغامدي'),
    ('Dubai Trading FZE', None),
]
headers_sup = ['Vendor No', 'Vendor Name', 'اسم المورد بالعربي', 'Supplier Classification', 'VAT Number',
               'Country', 'Business Unit', 'Site Name', 'Payment Terms', 'Invoice Currency', 'Bank IBAN', 'Email']
suppliers = []
for i, (en, ar) in enumerate(sup_names, 1):
    no = f'S{1000 + i}'
    country, bu, cur = 'SA', 'KSA BU', 'SAR'
    stype = 'SUPPLIER'
    if en.startswith('Global Software'):
        country, cur = 'US', 'USD'
    if en.startswith('Euro Tech'):
        country, cur = 'DE', 'EUR'
    if en.startswith('Dubai Trading'):
        country, bu, cur = 'AE', 'UAE BU', 'AED'
    if 'Ministry' in en:
        stype = 'GOVERNMENT'
    if 'Employee' in en:
        stype = 'EMPLOYEE'
    if 'Consulting' in en or 'Security' in en:
        stype = 'CONTRACTOR'
    suppliers.append([no, en, ar or '', stype, vat() if country == 'SA' and stype != 'EMPLOYEE' else '',
                      country, bu, 'MAIN', random.choice(['NET 30', 'NET 45', 'NET 60']), cur,
                      iban() if country == 'SA' else '', f'ap@{re.sub("[^a-z]", "", en.lower())[:12]}.com'])
# deliberate problems
suppliers[4][1] = ''                                  # missing name
suppliers[2][4] = suppliers[2][4][:-1]                # VAT 14 digits
suppliers[9][4] = '1' + suppliers[9][4][1:]           # VAT wrong first digit
suppliers[11][4] = ''                                 # SA supplier, no VAT
suppliers[15][4] = ''                                 # SA supplier, no VAT
suppliers[6][10] = 'SA03 8000 0000 6080 1016 7519'    # IBAN with spaces
for k in (1, 7, 13):
    suppliers[k][8] = 'Net 30'                        # casing
suppliers[12][11] = 'travel.asir.com'                 # bad e-mail
suppliers[20][5] = 'KSA'                              # bad country code
suppliers[21][7] = 'MAIN WAREHOUSE AND DISTRIBUTION CENTRE - RIYADH'   # > 40 chars
suppliers.append(list(suppliers[6]))                  # exact duplicate S1007 / MAIN
sup_no = {r[0] for r in suppliers}

# ----------------------------------------------------------------- AP invoices
headers_ap = ['Invoice Number', 'Supplier Number', 'Business Unit', 'Invoice Type', 'Invoice Date',
              'Invoice Currency', 'Invoice Amount', 'Amount Remaining', 'Due Date', 'Liability Account', 'Description']
ap = []
sar_sups = [r[0] for r in suppliers[:16] if r[9] == 'SAR']
dates = ['2023-03-15', '2023-11-02', '2024-02-20', '2024-08-09', '2025-01-30', '2025-06-18',
         '2025-10-05', '2026-03-12', '2026-07-21', '2026-09-30', '2026-11-15', '2026-12-10']
for i in range(1, 33):
    s = sar_sups[i % len(sar_sups)]
    amt = d(random.randrange(3000, 180000) + random.choice([0, 0.5, 0.25]))
    rem = amt if i % 3 else d(amt * Decimal('0.4'))
    dt = dates[i % len(dates)]
    ap.append([f'INV-{24000 + i}', s, 'KSA BU', 'STANDARD', dt, 'SAR', str(amt), str(rem),
               dt, '01-000-21100-00',
               f'Services {dt[:7]}'])
for i, (amt, rem) in enumerate([(45000, 45000), (12000, 6000), (8800, 8800), (150000, 150000), (2500, 2500), (61000, 30500)], 1):
    ap.append([f'GS-{900 + i}', 'S1017', 'KSA BU', 'STANDARD', '2026-10-0' + str(i), 'USD', f'{amt}.00', f'{rem}.00',
               '2026-12-0' + str(i), '01-000-21100-00', 'Software subscription'])
ap.append(['ET-7781', 'S1018', 'KSA BU', 'STANDARD', '2026-08-14', 'EUR', '18000.00', '18000.00', '2026-10-14', '01-000-21100-00', 'Engineering services'])
ap.append(['ET-7790', 'S1018', 'KSA BU', 'STANDARD', '2026-11-20', 'EUR', '12000.00', '12000.00', '2027-01-20', '01-000-21100-00', 'Engineering services'])
# deliberate problems
ap.append(['INV-24990', 'S1099', 'KSA BU', 'STANDARD', '2026-06-01', 'SAR', '7200.00', '7200.00', '2026-07-01', '01-000-21100-00', 'Unknown vendor'])
ap.append(['INV-24991', 'S1099', 'KSA BU', 'STANDARD', '2026-06-15', 'SAR', '4100.00', '4100.00', '2026-07-15', '01-000-21100-00', 'Unknown vendor'])
ap[3][7] = str(d(Decimal(ap[3][6]) + 1000))           # remaining > amount
ap[5][4] = '2027-01-05'                               # after cutover
ap[8][4] = '31/10/2026'                               # bad date format
ap[10][7] = '12,500.00'                               # thousands separator
ap.append(['CM-3301', 'S1002', 'KSA BU', 'CREDIT', '2026-11-28', 'SAR', '2300.00', '2300.00', '2026-12-28', '01-000-21100-00', 'Returned goods'])
ap[12][9] = '01-000-2110-00'                          # bad account format
ap.append(list(ap[14]))                               # duplicate invoice
ap[2][5] = 'USD'                                      # currency differs from supplier

# ----------------------------------------------------------------- AR
headers_cust = ['Customer Number', 'Customer Name', 'Account Type', 'VAT Number', 'Country', 'Business Unit',
                'Bill To Site', 'Payment Terms', 'Credit Limit', 'Currency']
cust_names = ['Saudi Retail Group', 'Al Noor Hospital', 'Riyadh Municipality', 'Gulf Contracting', 'Najran Farms',
              'Jazan Port Authority', 'Hijaz Hotels', 'Al Ula Tourism Co', 'Sakaka Schools', 'Taif Roses Est',
              'Al Kharj Dairy', 'Unaizah Dates', 'Rabigh Refining', 'Jubail Petrochem', 'Al Baha Clinics',
              'Arar Transport', 'Qurayyat Trading', 'Dhahran Tech Park', 'Hofuf Agriculture', 'Mohammed Al-Harbi']
customers = []
for i, n in enumerate(cust_names, 1):
    person = n == 'Mohammed Al-Harbi'
    customers.append([f'C{2000 + i}', n, 'PERSON' if person else 'ORGANIZATION', '' if person else vat(), 'SA', 'KSA BU',
                      'HQ', random.choice(['NET 30', 'NET 60']), str(random.choice([50000, 100000, 250000, 500000])), 'SAR'])
customers[3][8] = '0'; customers[8][8] = '0'; customers[15][8] = ''
customers[5][6] = ''                                   # missing bill-to
customers[11][4] = 'Saudi Arabia'                      # bad country
customers[13][3] = '30012345678'                       # bad VAT
cust_no = {c[0] for c in customers}

headers_ar = ['Transaction Number', 'Customer Number', 'Transaction Type', 'Transaction Date', 'Due Date',
              'Currency', 'Original Amount', 'Amount Due', 'Receivable Account']
ar = []
for i in range(1, 29):
    c = customers[i % len(customers)][0]
    amt = d(random.randrange(2000, 220000))
    due = amt if i % 4 else d(amt / 2)
    dt = dates[(i + 3) % len(dates)]
    ar.append([f'AR-{51000 + i}', c, 'INV', dt, dt, 'SAR', str(amt), str(due), '01-000-11300-00'])
ar.append(['CM-51901', 'C2004', 'CM', '2026-11-30', '2026-11-30', 'SAR', '-4500.00', '-4500.00', '01-000-11300-00'])
ar.append(['CM-51902', 'C2007', 'CM', '2026-12-05', '2026-12-05', 'SAR', '3200.00', '3200.00', '01-000-11300-00'])   # sign error
ar.append(['AR-51950', 'C2099', 'INV', '2026-10-10', '2026-11-10', 'SAR', '9900.00', '9900.00', '01-000-11300-00'])   # unknown customer
ar[6][7] = str(d(Decimal(ar[6][6]) + 500))             # due > original

# ----------------------------------------------------------------- bank
headers_bank = ['Bank Name', 'Branch Name', 'Account Name', 'Account Number', 'IBAN', 'Currency',
                'GL Cash Account', 'Opening Balance', 'Balance Date']
bank = [
    ['Al Rajhi Bank', 'Olaya Riyadh', 'Operations SAR', '608010167519', iban(), 'SAR', '01-000-11100-00', '4875320.55', CUTOVER],
    ['Saudi National Bank', 'King Fahd Rd', 'Payroll SAR', '100200300400', iban(), 'SAR', '01-000-11100-00', '1250000.00', CUTOVER],
    ['Riyad Bank', 'Jeddah Main', 'Collections SAR', '2233445566', 'SA4420000002233445566', 'SAR', '01-000-11100-00', '732118.40', '2026-12-30'],
    ['Saudi National Bank', 'King Fahd Rd', 'Operations USD', '100200300999', iban(), 'USD', '01-000-11100-00', '215400.00', CUTOVER],
]

# ----------------------------------------------------------------- PO
headers_po = ['PO Number', 'Line No', 'Supplier Number', 'Business Unit', 'Buyer Email', 'Item Description',
              'Category', 'Quantity', 'Quantity Received', 'Unit Price', 'Currency', 'Need By Date']
items = [('Laptop 14 inch', 'IT.HARDWARE', 3800), ('Annual ERP licence', 'IT.SOFTWARE', 125000),
         ('HVAC maintenance visit', 'FACILITIES.MAINTENANCE', 2400), ('A4 paper box', 'OFFICE.SUPPLIES', 95),
         ('Data migration consulting day', 'SERVICES.CONSULTING', 5200), ('Network switch', 'IT.HARDWARE', 9100)]
po = []
for p in range(1, 9):
    s = random.choice(sar_sups)
    for ln in range(1, 4):
        it = random.choice(items)
        q = random.choice([2, 5, 10, 20, 40])
        rec = random.choice([0, 0, q // 2])
        po.append([f'PO-{5000 + p}', str(ln), s, 'KSA BU', 'buyer@client.sa', it[0], it[1], str(q), str(rec),
                   f'{it[2]}.00', 'SAR', '2027-02-15'])
po[1][8] = str(int(po[1][7]) + 5)                       # received > ordered
for k in (4, 9, 15):
    po[k][8] = po[k][7]                                  # fully received
po[7][2] = 'S1077'                                       # unknown supplier
po[11][9] = '0.00'                                       # zero price
po[18][6] = 'IT HARDWARE'                                # bad category
po = po[:25]

# ----------------------------------------------------------------- PR (CSV)
headers_pr = ['Requisition Number', 'Line Number', 'Requester Email', 'Business Unit', 'Item Description',
              'Category', 'Quantity', 'Unit Price', 'Currency', 'Need By Date', 'Approval Status']
pr = []
statuses = ['APPROVED'] * 12 + ['PENDING'] * 6 + ['REJECTED'] * 2
for i in range(20):
    it = random.choice(items)
    pr.append([f'REQ-{8000 + i // 2}', str(i % 2 + 1), f'user{i}@client.sa', 'KSA BU', it[0], it[1],
               str(random.choice([1, 3, 6, 12])), f'{it[2]}.00', 'SAR',
               random.choice(['2026-10-15', '2026-11-30', '2027-01-20', '2027-03-01']), statuses[i]])
pr[4][2] = 'user4.client.sa'                             # bad email

# ----------------------------------------------------------------- GL derived from sub-ledgers
def total(rows, cur_idx, amt_idx, cur):
    return sum((parsed(r[amt_idx]) for r in rows if r[cur_idx] == cur), Decimal('0'))

ap_sar = total(ap, 5, 7, 'SAR'); ap_usd = total(ap, 5, 7, 'USD')
ar_sar = total(ar, 5, 7, 'SAR')
cash_sar = total(bank, 5, 7, 'SAR'); cash_usd = total(bank, 5, 7, 'USD')

L, P = 'KSA Primary Ledger', 'Dec-26'
gl = [
    [L, P, '01-000-11100-00', 'SAR', str(cash_sar), '', 'Cash and bank'],
    [L, P, '01-000-11300-00', 'SAR', str(ar_sar), '', 'Trade receivables'],
    [L, P, '01-000-12100-00', 'SAR', '845000.00', '', 'Prepayments'],
    [L, P, '01-000-14100-00', 'SAR', '2310450.00', '', 'Inventory'],
    [L, P, '01-000-15100-00', 'SAR', '9650000.00', '', 'Property, plant and equipment'],
    [L, P, '01-000-15900-00', 'SAR', '', '2140000.00', 'Accumulated depreciation'],
    [L, P, '01-000-21100-00', 'SAR', '', str(ap_sar - Decimal('12500.00')), 'Trade payables'],
    [L, P, '01-000-22100-00', 'SAR', '', '415300.00', 'Accrued expenses'],
    [L, P, '01-000-23100-00', 'SAR', '120000.00', '35000.00', 'VAT control'],     # DR and CR on one line
    [L, P, '01-000-31100-00', 'SAR', '', '5000000.00', 'Share capital'],
    [L, P, '01-000-12100-00', 'SAR', '15000.00', '', 'Prepayments (second line)'],   # duplicate key
    [L, 'DEC-26', '01-000-61100-00', 'SAR', '', '', 'Bad period name, zero line'],
    [L, P, '01-000-2110-00', 'SAR', '', '0.00', 'Bad account format'],
    [L, P, '01-000-11100-00', 'USD', str(cash_usd), '', 'Cash USD'],
    [L, P, '01-000-21100-00', 'USD', '', str(ap_usd), 'Trade payables USD'],
]
dr = sum((parsed(r[4]) for r in gl if r[3] == 'SAR' and r[1] == P), Decimal('0'))
cr = sum((parsed(r[5]) for r in gl if r[3] == 'SAR' and r[1] == P), Decimal('0'))
plug = dr - cr - Decimal('3250.00')                      # leave the TB out by 3,250.00
gl.append([L, P, '01-000-32100-00', 'SAR', '', str(plug), 'Retained earnings'])
usd_plug = cash_usd - ap_usd
gl.append([L, P, '01-000-32100-00', 'USD', '' if usd_plug > 0 else str(-usd_plug),
           str(usd_plug) if usd_plug > 0 else '', 'Retained earnings USD'])
headers_gl = ['Ledger Name', 'Period Name', 'Account Combination', 'Currency', 'Entered Dr', 'Entered Cr', 'Description']

# ----------------------------------------------------------------- write
wb = Workbook()
wb.remove(wb.active)
hdr_font, hdr_fill = Font(bold=True, color='FFFFFF'), PatternFill('solid', fgColor='1F4E78')

def sheet(name, headers, rows):
    ws = wb.create_sheet(name)
    ws.append(headers)
    for r in rows:
        ws.append([str(v) if v is not None else '' for v in r])
    for c in ws[1]:
        c.font, c.fill = hdr_font, hdr_fill
    for row in ws.iter_rows(min_row=2):
        for c in row:
            c.number_format = '@'
    for i, h in enumerate(headers, 1):
        ws.column_dimensions[ws.cell(1, i).column_letter].width = max(12, min(40, len(h) + 6))
    ws.freeze_panes = 'A2'

sheet('GL Opening Balances', headers_gl, gl)
sheet('Suppliers', headers_sup, suppliers)
sheet('Open AP Invoices', headers_ap, ap)
sheet('Customers', headers_cust, customers)
sheet('Open AR Invoices', headers_ar, ar)
sheet('Bank Accounts', headers_bank, bank)
sheet('Open Purchase Orders', headers_po, po)
ws = wb.create_sheet('Notes')
ws.append(['Demo migration pack for the XXX_FV pre-Fusion validation app.'])
ws.append(['Every sheet contains deliberate data problems. Dates are text in YYYY-MM-DD.'])
wb.save(f'{OUT}/Demo_Migration_Pack.xlsx')

with open(f'{OUT}/Open_Requisitions.csv', 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f)
    w.writerow(headers_pr)
    w.writerows(pr)

print('AP SAR', ap_sar, 'AP USD', ap_usd, 'AR SAR', ar_sar, 'cash SAR', cash_sar, 'cash USD', cash_usd)
print('rows', len(gl), len(suppliers), len(ap), len(customers), len(ar), len(bank), len(po), len(pr))
