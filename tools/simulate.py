"""Python re-implementation of the engine's main rules, used to cross-check the
seed catalogue against the sample files and to predict the demo results."""
import csv, re, sys
from collections import Counter, defaultdict
from decimal import Decimal
from datetime import date
from openpyxl import load_workbook
sys.path.insert(0, __import__('os').path.dirname(__file__))
from model import OBJECTS

base = (sys.argv[1] if len(sys.argv) > 1 else '.')
NUM = re.compile(r'^-?[0-9]+(\.[0-9]+)?$')
norm = lambda s: re.sub(r'[^A-Za-z0-9]+', '_', s.strip()).strip('_').upper()
objs = {o['code']: o for o in OBJECTS}

def detect(name):
    n = norm(name)
    for o in OBJECTS:
        if n in (o['code'], o['alias']):
            return o['code']
    return None

files = []
wb = load_workbook(f'{base}/samples/Demo_Migration_Pack.xlsx')
for ws in wb.worksheets:
    rows = [[('' if c is None else str(c)) for c in r] for r in ws.iter_rows(values_only=True)]
    files.append((ws.title, detect(ws.title), rows))
with open(f'{base}/samples/Open_Requisitions.csv', encoding='utf-8') as f:
    files.append(('Open_Requisitions.csv', detect('Open_Requisitions'), list(csv.reader(f))))

issues = Counter()
data = defaultdict(list)
for title, code, rows in files:
    if code is None:
        issues[('FILE_UNKNOWN_OBJECT', title)] += 1
        continue
    o = objs[code]
    cols = {c['name']: c for c in o['cols']}
    alias = {a: c['name'] for c in o['cols'] for a in c['aliases']}
    mapping, unmapped = {}, []
    for i, h in enumerate(rows[0]):
        n = norm(h)
        t = n if n in cols else alias.get(n)
        if t and t not in mapping.values():
            mapping[i] = t
        elif h:
            unmapped.append(h)
    for h in unmapped:
        issues[('FILE_UNMAPPED_COLUMN', code)] += 1
    for c in o['cols']:
        if c['req'] and c['name'] not in mapping.values():
            issues[('FILE_MISSING_COLUMN', code + '.' + c['name'])] += 1
    for r in rows[1:]:
        rec = {mapping[i]: v.strip() for i, v in enumerate(r) if i in mapping and v.strip()}
        if not rec:
            continue
        data[code].append(rec)
        for cn, c in cols.items():
            if cn not in mapping.values():
                continue
            v = rec.get(cn)
            if v is None:
                if c['req']:
                    issues[('COL_REQUIRED', code + '.' + cn)] += 1
                continue
            if c['dtype'] == 'NUMBER' and not NUM.match(v):
                issues[('COL_NUMBER', code + '.' + cn)] += 1
            elif c['dtype'] == 'DATE' and not re.match(r'^\d{4}-\d{1,2}-\d{1,2}$', v):
                issues[('COL_DATE', code + '.' + cn)] += 1
            elif c['length'] and len(v) > c['length']:
                issues[('COL_MAX_LENGTH', code + '.' + cn)] += 1
            elif c['regex'] and not re.search(c['regex'], v):
                issues[('COL_PATTERN', code + '.' + cn)] += 1
            elif c['allowed'] and v not in c['allowed']:
                issues[('COL_ALLOWED_VALUE', code + '.' + cn)] += 1
    uk = [c['name'] for c in sorted([c for c in o['cols'] if c['uk']], key=lambda c: c['uk'])]
    keys = Counter(tuple(r.get(k, '<empty>') for k in uk) for r in data[code])
    for k, n in keys.items():
        if n > 1:
            issues[('COL_DUPLICATE_KEY', code)] += n
    print(f'{title:22} -> {code or "-":16} rows={len(rows) - 1:3} mapped={len(mapping):2} unmapped={unmapped}')

num = lambda v: Decimal(v) if v and NUM.match(v) else None
def tot(code, cur, amt, filt=lambda r: True):
    out = defaultdict(Decimal)
    for r in data[code]:
        if filt(r) and num(r.get(amt)) is not None:
            out[r.get(cur)] += num(r[amt])
    return dict(out)

gl = data['GL_BALANCES']
def gl_net(acct, sign):
    out = defaultdict(Decimal)
    for r in gl:
        a = r.get('ACCOUNT_COMBINATION', '').split('-')
        if len(a) > 2 and a[2] == acct:
            dr, cr = num(r.get('ENTERED_DR')) or 0, num(r.get('ENTERED_CR')) or 0
            out[r['CURRENCY']] += (dr - cr) * sign
    return dict(out)

print('\nRECON')
tb = defaultdict(lambda: [Decimal(0), Decimal(0)])
for r in gl:
    k = (r.get('PERIOD_NAME'), r.get('CURRENCY'))
    tb[k][0] += num(r.get('ENTERED_DR')) or 0
    tb[k][1] += num(r.get('ENTERED_CR')) or 0
for k, (a, b) in tb.items():
    print('  TB', k, a, b, 'diff', a - b)
print('  AP ', tot('AP_INVOICES', 'INVOICE_CURRENCY', 'AMOUNT_REMAINING'), 'GL', gl_net('21100', -1))
print('  AR ', tot('AR_INVOICES', 'CURRENCY', 'AMOUNT_DUE'), 'GL', gl_net('11300', 1))
print('  CSH', tot('CE_BANK_ACCOUNTS', 'CURRENCY', 'OPENING_BALANCE'), 'GL', gl_net('11100', 1))

sup = {r.get('SUPPLIER_NUMBER') for r in data['AP_SUPPLIERS']}
cus = {r.get('CUSTOMER_NUMBER') for r in data['AR_CUSTOMERS']}
print('\nCUSTOM (approx)')
print('  AP_INV_SUPPLIER_EXISTS', sum(1 for r in data['AP_INVOICES'] if r.get('SUPPLIER_NUMBER') not in sup))
print('  PO_SUPPLIER_EXISTS', sum(1 for r in data['PO_ORDERS'] if r.get('SUPPLIER_NUMBER') not in sup))
print('  AR_INV_CUSTOMER_EXISTS', sum(1 for r in data['AR_INVOICES'] if r.get('CUSTOMER_NUMBER') not in cus))
print('  PR_NOT_APPROVED', sum(1 for r in data['PR_REQUISITIONS'] if r.get('APPROVAL_STATUS') != 'APPROVED'))
print('  PO_FULLY_RECEIVED', sum(1 for r in data['PO_ORDERS'] if r.get('QUANTITY_RECEIVED') == r.get('QUANTITY')))

print('\nBUILT-IN ISSUES')
for k, v in sorted(issues.items()):
    print(f'  {k[0]:22} {k[1]:40} {v}')
