# Fusion Data Readiness: Demo Script and Next Steps

Audience: project sponsors, finance leads and migration consultants. Length: about 25 minutes plus Q&A.
Message: **"Find every FBDI load problem before the load, in minutes. SQL decides, Claude explains."**

---

## 1. Prepare (the day before)

| # | Check | How |
|---|---|---|
| 1 | App opens and you can sign in | App 200, workspace `OTL_INTEG_TST` |
| 2 | Your user has the ADMIN role | Shared Components → Application Access Control (for the Admin part of the demo) |
| 3 | Claude works | Batch "Test" → Ask Claude → *Top 5 blocking issues* returns an answer |
| 4 | Engine is healthy | `@db/11_smoke_test.sql` in SQLcl → `SMOKE TEST PASSED (9 checks)` |
| 5 | Demo files ready on the desktop | `samples/Demo_Migration_Pack.xlsx`, `samples/Open_Requisitions.csv`, `samples/Valid_Migration_Pack.xlsx` |
| 6 | Backup batches exist | Batch **"Test"** (demo pack, cutover 2026-11-01, NOT_READY, 76): run **Validate** once, because it is in *Files loaded*. Batch **"Clean pack check"** (cutover 2026-12-31, READY, 100) has its AI report done. |
| 7 | Reports pre-generated | On "Test", generate one English and one Arabic report the day before, because each takes 1–3 minutes. In the demo, show the stored report and start a fresh one only if time allows. |

---

## 2. Demo script

### Part A: The problem (2 min)
- FBDI loads fail late: rejected rows, unbalanced journals, sub-ledgers that don't match the GL. Each failure costs a client round trip and puts the cutover date at risk.
- This app checks the client's files **before** the load, with the same answers every time, and explains the result in business language (English or Arabic).

### Part B: Upload and mapping (6 min)
1. **Batches → New batch**: "Demo live", client "Demo Co", TEST, cutover 2026-11-01 → **Create**.
2. Upload **Demo_Migration_Pack.xlsx** and **Open_Requisitions.csv** → **Upload**. Point out:
   - Each sheet is matched to its Fusion object from the sheet name, or from the headers when the name is unknown.
   - **Notes**: *Unknown sheet* → click **Ignore**: "it's not migration data, so it's skipped."
   - **Suppliers**: *Missing required columns*.
3. Open the **Suppliers** mapping:
   - The *Value shape* column shows digits as 9: the AI never sees real VAT or bank numbers.
   - Click **Suggest with Claude**: the Arabic header "اسم المورد بالعربي" → ALTERNATE_NAME and "Supplier Classification" → SUPPLIER_TYPE, each with a confidence and a reason.
   - Close.

### Part C: Validation and reconciliation (7 min)
4. **Validate** → **Validation Results**.
   - **Header**: NOT_READY, score, and the error, warning and info counts.
   - **Chart**: where the problems are.
   - **Reconciliations**, the finance highlight:

     | Reconciliation | Result | Talking point |
     |---|---|---|
     | Trial balance Dec-26 SAR | DIFF 3,250.00 | Journal won't import until it balances |
     | AP vs GL 21100 SAR | DIFF 12,500.00 | One invoice has "12,500.00": invalid number, left out of the total |
     | AP vs GL 21100 EUR | DIFF 30,000.00, no GL balance | EUR payables with no GL balance |
     | AR, Cash, USD | MATCHED | |
   - **Issues**: search "VAT". Show **How to fix**. Click a line number to show **Row Detail**, with the IBAN masked.
   - Typical findings to call out:
     - suppliers: duplicate S1007/MAIN, "Net 30" casing, country "KSA", a site name longer than 40 characters, Al-Rajhi Trading Co. vs AL RAJHI TRADING COMPANY;
     - AP: unknown supplier S1099, a positive CREDIT, an invoice after cutover;
     - PO: received greater than ordered, a zero price;
     - PR: 8 lines not approved.

### Part D: Claude explains (6 min)
5. **AI Report**: open the pre-generated English report:
   - Executive summary and readiness explanation (the score is SQL's, not Claude's).
   - Module cards (BLOCKED / WARNING / OK), insights with evidence, top risks, next steps with owners.
   - Switch to **العربية**: the same report in Modern Standard Arabic, right to left.
   - **What Claude received**: aggregated facts only, no file rows.
6. **Ask Claude**: use the quick buttons *Explain the AP to GL difference* and *لخص الوضع بالعربي*, then one live question from the audience.

### Part E: The clean pack and configuration (3 min)
7. Open batch **"Clean pack check"**: READY, 100, 0 issues, every reconciliation MATCHED in SAR, USD, EUR and AED. "This is what a load-ready pack looks like."
8. **Admin → Rules**: rules are data. Open AP_INV_SIGN: severity and SQL are editable, and **Test rule** checks the SQL before it runs. New client rules need no code release.

### Part F: Close (1 min)
- Earlier, cheaper discovery of load errors, the same result every time, a bilingual report for the client finance team, and the client's data stays in the database.
- Hand over to next steps.

**If Claude is slow or unavailable:** use the stored reports and chat history (the History region and the conversation list). Validation and reconciliation don't depend on Claude.

---

## 3. Status (2026-11-18)

| Area | Status |
|---|---|
| Database layer (tables, views, 5 packages, 36 rules) | Done, all objects valid |
| APEX app 200, 15 pages, Guru Hits theme | Done |
| Claude: mapping, bilingual report, chat | Done and tested on batch "Test" |
| Clean pack + offline checker + FBDI mapping reference | Done; app and checker agree (READY 0/0/0) |
| Engine smoke test | Done, 9 of 9 pass |
| Ignore non-data sheets | Done |

---

## 4. Next steps

### Short term (before a client pilot)
1. **Official Guru Hits logo**: replace the cropped screenshot with the SVG or transparent PNG.
2. **AI Report → History double header**: reproduce from a screenshot and fix.
3. **Issues report extras**: saved reports *Errors only* and *By rule*; natural-language search once the AI attribute can be kept in source.
4. **AI Attributes in source**: re-test when a newer SQLcl supports the Anthropic provider in APEXlang, then keep `genAI { service: @CLAUDE }` in `application.apx`.
5. **Large files**: run Validate and the AI report in the background (`APEX_BACKGROUND_PROCESS` / an execution chain) with a progress bar.
6. **Push to GitHub** and tag the demo build. Recent commits are local only.

### Medium term (pilot with a client)
7. **FBDI file generation**: turn a READY batch into the FBDI CSV/zip per template. This covers:
   - YYYY/MM/DD dates, account segments and ledger ID;
   - open quantities and open balances;
   - conversion rates for foreign-currency journal lines;
   - an approver e-mail column for approved requisitions;
   - interface keys.

   `check_pack.py` "FBDI load notes" and `FBDI_Mapping_Reference.xlsx` already list what's needed.
8. **Confirm FBDI column limits** marked *Check template* in the mapping reference against the client's Fusion release, and adjust lengths and allowed values in `tools/model.py`.
9. **Client configuration**: business units, chart of accounts pattern, payment terms, categories and currencies from the client's Fusion setup. Today these are demo values in the catalogue.
10. **Re-validation comparison**: show what changed between two validation runs (fixed, new and still-open issues).
11. **Batch sign-off**: approval of a READY batch by the client finance lead, with an audit trail.

### Longer term
12. **More objects**: fixed assets, items, employees and projects, by extending `tools/model.py` and adding rules.
13. **Fusion lookups**: check lookup codes, suppliers and customers against the target Fusion environment through REST, not only within the pack.
14. **Multi-client set-up**: one catalogue per client or project, row-level separation, SSO (social sign-in or SAML).
15. **Operations**: utPLSQL in CI when available; until then the smoke test plus `check_pack.py` on both sample packs in every pull request.

### Decisions needed from the sponsor
- The pilot client and cutover date.
- Whether FBDI file generation (step 7) is in scope for the pilot.
- The target hosting: this ATP test instance or a client-dedicated one.
