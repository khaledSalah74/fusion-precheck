"""Offline pre-check of a migration pack against the XXX_FV catalogue. It mirrors what the
app does today: object detection (sheet name, then header scoring), auto-mapping, the
built-in checks of xxx_fv_rules_pkg, every seeded ROW_SQL rule and every reconciliation,
and the readiness score. A separate "FBDI load notes" section lists what still has to be
prepared when the validated data is turned into Oracle Fusion FBDI files (not app issues).

Usage (repo root):
  python tools/check_pack.py <pack.xlsx | file.csv> [more files ...] [cutover YYYY-MM-DD] [--ignore "Sheet A,Sheet B"]
Several files are checked as one batch (e.g. Demo_Migration_Pack.xlsx Open_Requisitions.csv).
--ignore mirrors the app's "Ignore sheet" action for sheets that are not migration data.

Keep in sync with: tools/model.py (catalogue), db/05_xxx_fv_rules_pkg.sql (built-in checks,
readiness), db/04_xxx_fv_file_adapter_pkg.sql (detection, mapping) and the ROW_SQL/RECON rows
in xxx_fv_rules (db/09_seed_rules.sql)."""
import argparse, csv, os, re, sys
from collections import Counter, defaultdict
from datetime import date
from decimal import Decimal
from openpyxl import load_workbook
sys.path.insert(0, os.path.dirname(__file__))
from model import OBJECTS

# Arabic headers and values must print on a Windows console / pipe (cp1252 by default)
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

ap_ = argparse.ArgumentParser()
ap_.add_argument('paths', nargs='+', help='pack files, optionally followed by the cutover date')
ap_.add_argument('--ignore', default='', help='comma-separated sheet/file names to ignore')
args = ap_.parse_args()
paths = list(args.paths)
cutover = date.fromisoformat(paths.pop()) if re.match(r'^\d{4}-\d{2}-\d{2}$', paths[-1]) else date(2026, 12, 31)
ignored = {s.strip() for s in args.ignore.split(',') if s.strip()}

NUM = re.compile(r'^-?[0-9]+(\.[0-9]+)?$')                     # same regexp as the engine and the views
norm = lambda s: re.sub(r'[^A-Za-z0-9]+', '_', (s or '').strip()).strip('_').upper()
objs = {o['code']: o for o in OBJECTS}                           # all seeded objects are enabled
issues = []      # (severity, rule, object, line, message); line None = file/batch level
add = lambda sev, rule, obj, line, msg: issues.append((sev, rule, obj, line, msg))


def num(v):
    """Typed-view number: only plain digits with '.' convert, anything else is NULL."""
    return Decimal(v) if v and NUM.match(v) else None


def dt(v, fmt='YYYY-MM-DD'):
    """Approximates Oracle's lenient to_date/validate_conversion for the column's format:
    YYYY-MM-DD and YYYY/MM/DD accept any or no separator and 1-2 digit month/day."""
    if not v:
        return None
    m = re.match(r'^(\d{4})\D?(\d{1,2})\D?(\d{1,2})$', v.strip()) if fmt in ('YYYY-MM-DD', 'YYYY/MM/DD') else None
    try:
        return date(int(m.group(1)), int(m.group(2)), int(m.group(3))) if m else None
    except ValueError:
        return None


def detect_by_name(name):
    n = norm(name)
    return next((o['code'] for o in sorted(OBJECTS, key=lambda o: o['code']) if n in (o['code'], o['alias'])), None)


def detect_by_headers(headers):
    """xxx_fv_file_adapter_pkg.suggest_object: each header scores 1/(objects it matches);
    a clear win needs score >= 1.5 and >= 1.5 x the runner-up."""
    cand = defaultdict(set)
    for o in OBJECTS:
        for c in o['cols']:
            cand[c['name']].add(o['code'])
            for a in c['aliases']:
                cand[a].add(o['code'])
    score = defaultdict(Decimal)
    for h in {norm(h) for h in headers if norm(h)}:
        for code in cand.get(h, ()):
            score[code] += Decimal(1) / len(cand[h])
    ranked = sorted(score.items(), key=lambda kv: (-kv[1], kv[0]))
    if ranked and ranked[0][1] >= Decimal('1.5') and (len(ranked) == 1 or ranked[0][1] >= Decimal('1.5') * ranked[1][1]):
        return ranked[0][0]
    return None


# ----------------------------------------------------------------------------- read the pack
sheets = []
for path in paths:
    if path.lower().endswith('.xlsx'):
        for ws in load_workbook(path).worksheets:
            sheets.append((ws.title, [[('' if c is None else str(c)) for c in r] for r in ws.iter_rows(values_only=True)]))
    else:
        with open(path, encoding='utf-8-sig') as f:
            sheets.append((os.path.splitext(os.path.basename(path))[0], list(csv.reader(f))))

data = defaultdict(list)          # object -> staged lines (dict column -> value, _line)
provided = set()                  # objects with at least one file (even an empty one)
detected = []                     # (sheet, object, how)
for title, rows in sheets:
    if title in ignored:
        detected.append((title, None, 'ignored'))
        continue
    headers = rows[0] if rows else []
    code, how = detect_by_name(title), 'sheet name'
    if code is None:
        code, how = detect_by_headers(headers), 'headers'
    detected.append((title, code, how if code else 'unknown'))
    if code is None:
        add('WARNING', 'FILE_UNKNOWN_OBJECT', None, None, title)
        continue
    provided.add(code)
    o = objs[code]
    cols = {c['name']: c for c in o['cols']}
    alias = {a: c['name'] for c in o['cols'] for a in c['aliases']}
    mapping = {}                  # auto_map: header = column name or alias; first header wins
    for i, h in enumerate(headers):
        if not h:
            continue
        t = norm(h) if norm(h) in cols else alias.get(norm(h))
        if t and t not in mapping.values():
            mapping[i] = t
        else:
            add('INFO', 'FILE_UNMAPPED_COLUMN', code, None, h)
    for c in o['cols']:
        if c['req'] and c['name'] not in mapping.values():
            add('ERROR', 'FILE_MISSING_COLUMN', code, None, c['name'])
    lines = 0
    for ln, r in enumerate(rows[1:], 2):
        rec = {mapping[i]: v.strip() for i, v in enumerate(r) if i in mapping and v and v.strip()}
        if not rec:               # blank rows are not staged
            continue
        lines += 1
        rec['_line'] = ln
        data[code].append(rec)
        for cn, c in cols.items():
            if cn not in mapping.values():
                continue
            v = rec.get(cn)
            if v is None:
                if c['req']:
                    add('ERROR', 'COL_REQUIRED', code, ln, cn)
                continue
            # first failing check per cell, in the engine's order
            if c['dtype'] == 'NUMBER' and not NUM.match(v):
                add('ERROR', 'COL_NUMBER', code, ln, f'{cn}={v}')
            elif c['dtype'] == 'DATE' and dt(v, c['fmt']) is None:
                add('ERROR', 'COL_DATE', code, ln, f'{cn}={v}')
            elif c['length'] and len(v) > c['length']:
                add('ERROR', 'COL_MAX_LENGTH', code, ln, f'{cn} len {len(v)} > {c["length"]}')
            elif c['regex'] and not re.search(c['regex'], v):
                add('ERROR', 'COL_PATTERN', code, ln, f'{cn}={v}')
            elif c['allowed'] and v not in c['allowed']:
                add('ERROR', 'COL_ALLOWED_VALUE', code, ln, f'{cn}={v}')
    if lines == 0:
        add('WARNING', 'FILE_EMPTY', code, None, title)

# duplicate business keys: across all files of an object, one issue per duplicated line
for code, recs in data.items():
    uk = [c['name'] for c in sorted((c for c in objs[code]['cols'] if c['uk']), key=lambda c: c['uk'])]
    if not uk:
        continue
    keyf = lambda r: tuple(r.get(x) or '<empty>' for x in uk)
    counts = Counter(keyf(r) for r in recs)
    for r in recs:
        if counts[keyf(r)] > 1:
            add('ERROR', 'COL_DUPLICATE_KEY', code, r['_line'], f'{"+".join(uk)} = {" | ".join(keyf(r))} x{counts[keyf(r)]}')

for o in OBJECTS:
    if o['code'] not in provided:
        add('INFO', 'BATCH_OBJECT_MISSING', o['code'], None, o['name'])

# ----------------------------------------------------------------------------- ROW_SQL rules
# A plug-in rule runs only when the batch has a file for the rule's object.
S, AP, C, AR, G, B, PO, PR = (data[k] for k in ['AP_SUPPLIERS', 'AP_INVOICES', 'AR_CUSTOMERS', 'AR_INVOICES',
                                               'GL_BALANCES', 'CE_BANK_ACCOUNTS', 'PO_ORDERS', 'PR_REQUISITIONS'])
sup = {s.get('SUPPLIER_NUMBER') for s in S if s.get('SUPPLIER_NUMBER')}
cus = {c.get('CUSTOMER_NUMBER') for c in C if c.get('CUSTOMER_NUMBER')}
stop = r' (CO|COMPANY|LTD|LLC|EST|ESTABLISHMENT|THE|TRADING|GROUP) '
key = lambda n: re.sub(stop, ' ', re.sub(stop, ' ', ' ' + re.sub('[^A-Z0-9]+', ' ', n.upper()) + ' ')).replace(' ', '')

for s in S:                                                                       # AP_SUP_VAT_MISSING
    if s.get('COUNTRY') == 'SA' and not s.get('TAX_REGISTRATION_NUMBER') and s.get('SUPPLIER_TYPE') != 'EMPLOYEE':
        add('WARNING', 'AP_SUP_VAT_MISSING', 'AP_SUPPLIERS', s['_line'], s.get('SUPPLIER_NUMBER'))
for s1 in S:                                                                      # AP_SUP_SIMILAR_NAME (per pair)
    for s2 in S:
        if (s1.get('SUPPLIER_NAME') and s2.get('SUPPLIER_NAME') and key(s1['SUPPLIER_NAME']) == key(s2['SUPPLIER_NAME'])
                and s1.get('SUPPLIER_NUMBER') != s2.get('SUPPLIER_NUMBER')):
            add('WARNING', 'AP_SUP_SIMILAR_NAME', 'AP_SUPPLIERS', s1['_line'], f"{s1.get('SUPPLIER_NUMBER')} ~ {s2.get('SUPPLIER_NUMBER')}")
sup_cur = defaultdict(set)
for s in S:
    sup_cur[s.get('SUPPLIER_NUMBER')].add(s.get('INVOICE_CURRENCY'))
for i in AP:
    a, r = num(i.get('INVOICE_AMOUNT')), num(i.get('AMOUNT_REMAINING'))
    idate = dt(i.get('INVOICE_DATE'))
    if i.get('SUPPLIER_NUMBER') and i['SUPPLIER_NUMBER'] not in sup:
        add('ERROR', 'AP_INV_SUPPLIER_EXISTS', 'AP_INVOICES', i['_line'], i['SUPPLIER_NUMBER'])
    if a is not None and r is not None and abs(r) > abs(a):
        add('ERROR', 'AP_INV_REMAINING_GT_AMOUNT', 'AP_INVOICES', i['_line'], i.get('INVOICE_NUMBER'))
    if a is not None and ((i.get('INVOICE_TYPE') == 'CREDIT' and a > 0) or (i.get('INVOICE_TYPE') in ('STANDARD', 'PREPAYMENT') and a < 0)):
        add('ERROR', 'AP_INV_SIGN', 'AP_INVOICES', i['_line'], i.get('INVOICE_NUMBER'))
    if idate and idate > cutover:
        add('WARNING', 'AP_INV_AFTER_CUTOVER', 'AP_INVOICES', i['_line'], i.get('INVOICE_NUMBER'))
    if i.get('SUPPLIER_NUMBER') in sup and i.get('INVOICE_CURRENCY') not in sup_cur[i['SUPPLIER_NUMBER']]:
        add('INFO', 'AP_INV_CURRENCY_DIFF', 'AP_INVOICES', i['_line'], i.get('INVOICE_NUMBER'))
for t in AR:
    a, d = num(t.get('ORIGINAL_AMOUNT')), num(t.get('AMOUNT_DUE'))
    if t.get('CUSTOMER_NUMBER') and t['CUSTOMER_NUMBER'] not in cus:
        add('ERROR', 'AR_INV_CUSTOMER_EXISTS', 'AR_INVOICES', t['_line'], t['CUSTOMER_NUMBER'])
    if a is not None and ((t.get('TRANSACTION_TYPE') == 'CM' and a > 0) or (t.get('TRANSACTION_TYPE') in ('INV', 'DM') and a < 0)):
        add('ERROR', 'AR_TRX_SIGN', 'AR_INVOICES', t['_line'], t.get('TRANSACTION_NUMBER'))
    if a is not None and d is not None and abs(d) > abs(a):
        add('ERROR', 'AR_DUE_GT_ORIGINAL', 'AR_INVOICES', t['_line'], t.get('TRANSACTION_NUMBER'))
for c in C:
    if (num(c.get('CREDIT_LIMIT')) or 0) == 0:
        add('INFO', 'AR_CUST_NO_CREDIT_LIMIT', 'AR_CUSTOMERS', c['_line'], c.get('CUSTOMER_NUMBER'))
for g in G:
    dr, cr = num(g.get('ENTERED_DR')) or 0, num(g.get('ENTERED_CR')) or 0
    if dr and cr:
        add('WARNING', 'GL_LINE_DR_AND_CR', 'GL_BALANCES', g['_line'], g.get('ACCOUNT_COMBINATION'))
    if not dr and not cr:
        add('INFO', 'GL_LINE_ZERO', 'GL_BALANCES', g['_line'], g.get('ACCOUNT_COMBINATION'))
for b in B:                                                                       # NULL date is not flagged
    bd = dt(b.get('BALANCE_DATE'))
    if bd and bd != cutover:
        add('WARNING', 'CE_BALANCE_DATE', 'CE_BANK_ACCOUNTS', b['_line'], b.get('ACCOUNT_NAME'))
for p in PO:
    q, r, price = num(p.get('QUANTITY')), num(p.get('QUANTITY_RECEIVED')), num(p.get('UNIT_PRICE'))
    if p.get('SUPPLIER_NUMBER') and p['SUPPLIER_NUMBER'] not in sup:
        add('ERROR', 'PO_SUPPLIER_EXISTS', 'PO_ORDERS', p['_line'], p['SUPPLIER_NUMBER'])
    if q is not None and r is not None and r > q:
        add('ERROR', 'PO_RECEIVED_GT_ORDERED', 'PO_ORDERS', p['_line'], p.get('PO_NUMBER'))
    if q is not None and r is not None and r == q:
        add('WARNING', 'PO_FULLY_RECEIVED', 'PO_ORDERS', p['_line'], p.get('PO_NUMBER'))
    if price is not None and price <= 0:
        add('ERROR', 'PO_PRICE_NOT_POSITIVE', 'PO_ORDERS', p['_line'], p.get('PO_NUMBER'))
for r in PR:
    if r.get('APPROVAL_STATUS') and r['APPROVAL_STATUS'] != 'APPROVED':
        add('WARNING', 'PR_NOT_APPROVED', 'PR_REQUISITIONS', r['_line'], r.get('REQUISITION_NUMBER'))
    nb = dt(r.get('NEED_BY_DATE'))
    if nb and nb < cutover:
        add('INFO', 'PR_NEED_BY_PAST', 'PR_REQUISITIONS', r['_line'], r.get('REQUISITION_NUMBER'))

# ----------------------------------------------------------------------------- reconciliations
recon = []       # (rule, severity, label, currency, source, target, tolerance)
if 'GL_BALANCES' in provided:
    tb = defaultdict(lambda: [Decimal(0), Decimal(0)])
    for g in G:
        k = (g.get('LEDGER_NAME'), g.get('PERIOD_NAME'), g.get('CURRENCY'))
        tb[k][0] += num(g.get('ENTERED_DR')) or 0
        tb[k][1] += num(g.get('ENTERED_CR')) or 0
    for k, (dr, cr) in tb.items():
        recon.append(('GL_TRIAL_BALANCE', 'ERROR', f'Trial balance {k[0]} {k[1]}', k[2], dr, cr, Decimal('0.01')))


def gl_net(nat, sign):
    out = {}
    for g in G:
        parts = [x for x in (g.get('ACCOUNT_COMBINATION') or '').split('-') if x]   # regexp_substr '[^-]+'
        if len(parts) > 2 and parts[2] == nat:
            out[g.get('CURRENCY')] = out.get(g.get('CURRENCY'), Decimal(0)) + \
                ((num(g.get('ENTERED_DR')) or 0) - (num(g.get('ENTERED_CR')) or 0)) * sign
    return out


def sub(rows, cur, amt):
    out = {}
    for r in rows:
        v = num(r.get(amt))
        if v is not None:                           # SUM ignores NULLs; all-NULL group stays NULL
            out[r.get(cur)] = (out.get(r.get(cur)) or Decimal(0)) + v
        else:
            out.setdefault(r.get(cur), None)
    return out


for rule, obj, rows, cur, amt, nat, sign, label in [
        ('AP_TO_GL', 'AP_INVOICES', AP, 'INVOICE_CURRENCY', 'AMOUNT_REMAINING', '21100', -1, 'Open AP vs GL liability 21100'),
        ('AR_TO_GL', 'AR_INVOICES', AR, 'CURRENCY', 'AMOUNT_DUE', '11300', 1, 'Open AR vs GL receivables 11300'),
        ('CASH_TO_GL', 'CE_BANK_ACCOUNTS', B, 'CURRENCY', 'OPENING_BALANCE', '11100', 1, 'Bank balances vs GL cash 11100')]:
    if obj not in provided:
        continue
    s, g = sub(rows, cur, amt), gl_net(nat, sign)
    for c in sorted(set(s) | set(g), key=lambda x: x or ''):
        recon.append((rule, 'WARNING', label, c, s.get(c), g.get(c), Decimal('1')))
for rule, sev, label, cur, a, b, tol in recon:
    if abs((a or 0) - (b or 0)) > tol:
        add(sev, rule, None, None, f'{label} [{cur}]: {a} vs {b}')

# ----------------------------------------------------------------------------- readiness (get_readiness)
line_count = sum(len(v) for v in data.values())
error_lines = {(i[2], i[3]) for i in issues if i[0] == 'ERROR' and i[3] is not None}
level_errors = sum(1 for i in issues if i[0] == 'ERROR' and i[3] is None)
score = 0 if line_count == 0 else max(0, round(100 * (line_count - len(error_lines)) / line_count) - 5 * level_errors)
cnt = Counter(i[0] for i in issues)
readiness = 'NOT_READY' if cnt['ERROR'] else 'READY_WITH_WARNINGS' if cnt['WARNING'] else 'READY'

# ----------------------------------------------------------------------------- FBDI load notes
# Not app issues: what the FBDI conversion has to handle for data that passes validation.
notes = []
date_values = sum(1 for code, recs in data.items() for c in objs[code]['cols'] if c['dtype'] == 'DATE'
                  for r in recs if r.get(c['name']))
if date_values:
    notes.append(f'{date_values} date values are YYYY-MM-DD here; FBDI templates expect YYYY/MM/DD.')
zero_ap = [i.get('INVOICE_NUMBER') for i in AP if num(i.get('AMOUNT_REMAINING')) == 0]
if zero_ap:
    notes.append(f'{len(zero_ap)} AP invoices have AMOUNT_REMAINING 0: nothing to load as an open balance ({", ".join(zero_ap[:5])}).')
credits = sum(1 for i in AP if i.get('INVOICE_TYPE') == 'CREDIT')
if credits:
    notes.append(f'{credits} AP credit memos: load with INVOICE_TYPE_LOOKUP_CODE = CREDIT and a negative amount.')
zero_ar = [t.get('TRANSACTION_NUMBER') for t in AR if num(t.get('AMOUNT_DUE')) == 0]
if zero_ar:
    notes.append(f'{len(zero_ar)} AR transactions have AMOUNT_DUE 0: nothing open to load ({", ".join(zero_ar[:5])}).')
cms = sum(1 for t in AR if t.get('TRANSACTION_TYPE') == 'CM')
if cms:
    notes.append(f'{cms} AR credit memos need a credit memo transaction type in AutoInvoice.')
open_po = [p for p in PO if num(p.get('QUANTITY')) is not None and num(p.get('QUANTITY_RECEIVED') or '0') is not None]
closed = [p.get('PO_NUMBER') for p in open_po if num(p['QUANTITY']) - (num(p.get('QUANTITY_RECEIVED') or '0') or 0) <= 0]
if open_po:
    notes.append(f'{len(open_po) - len(closed)} PO lines load with open quantity = QUANTITY - QUANTITY_RECEIVED'
                 + (f'; {len(closed)} have no open quantity.' if closed else '.'))
approved = sum(1 for r in PR if r.get('APPROVAL_STATUS') == 'APPROVED')
if approved:
    notes.append(f'{approved} approved requisition lines: approved import needs an approver e-mail, '
                 'which is not a column in this template; add it when generating the FBDI file.')
fx = Counter(g.get('CURRENCY') for g in G if g.get('CURRENCY') not in (None, 'SAR'))
if fx:
    notes.append('GL lines in foreign currency (' + ', '.join(f'{k} {v}' for k, v in sorted(fx.items()))
                 + ') need a conversion type and rate, or accounted amounts, in GL_INTERFACE.')
if G:
    notes.append('ACCOUNT_COMBINATION is split into SEGMENT1..SEGMENT4 and LEDGER_NAME is resolved to LEDGER_ID '
                 f'for GL_INTERFACE; ACCOUNTING_DATE = {cutover:%Y/%m/%d}.')

# ----------------------------------------------------------------------------- report
print('Sheets:')
for title, code, how in detected:
    print(f'  {title or "(csv)":24} -> {code or "-":17} ({how})')
print('Rows:', {k: len(v) for k, v in data.items()})
print('\nReconciliations:')
for rule, sev, label, cur, a, b, tol in recon:
    status = 'MATCHED' if abs((a or 0) - (b or 0)) <= tol else 'DIFF'
    print(f'  {rule:17} {cur}  source {a}  target {b}  {status}')
print(f"\nIssues: ERROR {cnt['ERROR']}  WARNING {cnt['WARNING']}  INFO {cnt['INFO']}")
for (sev, rule), n in sorted(Counter((i[0], i[1]) for i in issues).items()):
    print(f'  {sev:7} {rule:28} {n}')
for i in issues[:40]:
    print('   ', i)
print(f'\nPredicted readiness: {readiness} (score {score}, {line_count} lines)')
print('\nFBDI load notes (not validation issues):')
for n in notes:
    print('  -', n)
