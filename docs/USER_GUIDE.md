# Fusion Data Readiness: User Guide

Fusion Data Readiness checks a client's migration files before they are loaded into Oracle Fusion Cloud ERP with FBDI. You upload the files, the app maps and validates them, reconciles the sub-ledgers to the GL, and gives a readiness score. Claude (an AI assistant) explains the results in English or Arabic and answers questions about them.

**The validation itself is plain SQL.** Results and the readiness score are the same every time you run them. Claude only explains them and never decides what passes.

---

## 1. Before you start

| You need | Details |
|---|---|
| An APEX account | App 200 "Fusion Data Readiness", workspace `OTL_INTEG_TST`. Sign in on the login page. |
| The ADMIN role (admins only) | Needed for the Admin menu (objects, columns, rules, error log). Granted under Shared Components → Application Access Control. |
| The client's files | `.xlsx` (one object per sheet) and/or `.csv` (one object per file). Sample files are in `samples/`. |

**File format rules**
- First row = column headers. Headers are matched by name or by a known alias, for example "Vendor No" → `SUPPLIER_NUMBER`. Headers the app doesn't recognise can be mapped by hand or by Claude.
- Name each sheet after its object ("Suppliers", "Open AP Invoices", "GL Opening Balances", ...). If the name isn't recognised, the app guesses the object from the headers.
- Numbers: digits and `.` only, for example `12500.00`. `12,500.00` is reported as invalid and left out of totals.
- Dates: `YYYY-MM-DD`, for example `2026-12-31`.

**Objects the app validates**

| Module | Object | Sheet name |
|---|---|---|
| GL | GL opening balances | GL Opening Balances |
| AP | Suppliers | Suppliers |
| AP | Open AP invoices | Open AP Invoices |
| AR | Customers | Customers |
| AR | Open AR transactions | Open AR Invoices |
| CE | Bank accounts and balances | Bank Accounts |
| PO | Open purchase orders | Open Purchase Orders |
| PR | Open requisitions | Open Requisitions |

---

## 2. The workflow at a glance

```
Batches (1) ─► New batch (2) ─► Files & Mapping (10) ─► Column Mapping (11) ─► Validate
                                                                          │
              Ask Claude (40) ◄── AI Report (30) ◄── Validation Results (20) ◄─┘
                                                     └─► Row Detail (21)
```

Batch status moves **New → Files loaded → Validated → AI report ready**. If you change files or mappings, the batch goes back to *Files loaded* until you validate again.

---

## 3. Step by step

### Step 1: Create a batch (pages 1 and 2)
1. Open **Batches**. Each card is a batch. The colour of its stripe and badge shows readiness: red = not ready, amber = ready with warnings, green = ready, grey = not validated yet.
2. Click **New batch** and fill in:
   - **Batch name** (required), for example "Client X - Mock 1".
   - **Client name** and **Target environment** (DEV / TEST / UAT / PROD).
   - **Cutover date** (required). This is the date of the opening balances. Rules compare invoice dates, bank balance dates and need-by dates with it.
3. Click **Create**. The app opens the new batch on **Files & Mapping**.

### Step 2: Upload files (page 10)
1. Drop the `.xlsx` / `.csv` files on the upload area and click **Upload**.
2. Each sheet becomes one row in the **Files** report:
   - **Object**: the migration object the sheet was matched to.
   - **Rows**: filled in after validation.
   - **Mapped / Unmapped / Missing required**: column mapping status.
   - **Attention**: what to fix, for example *Unknown sheet*, *Missing required columns*, *Ignored*, or *OK*.
3. Actions per row:
   - **Mapping icon**: opens the column mapping for that sheet (step 3).
   - **Ignore / Include**: use **Ignore** for sheets that aren't migration data (notes, cover pages). Ignored sheets are skipped by validation, raise no warning and aren't sent to Claude. **Include** brings a sheet back and detects its object again.
   - **Trash icon**: removes the whole uploaded file (all its sheets) and its results.

### Step 3: Check the column mapping (page 11)
1. The **Object** box shows which object this sheet is. Pick another object and click **Assign object** if it's wrong.
   - If the headers clearly match a different object, a yellow warning offers **Use suggested object** ("The headers of this sheet match GL Opening Balances...").
2. The **Mapping** grid lists each file header with a **Value shape**: the first value with every digit shown as 9, so no real account or VAT numbers are displayed.
3. Change **Mapped column** for any header and click **Save** in the grid toolbar. Required columns are marked with `*`.
4. **Suggest with Claude** maps the headers that are still unmapped, including Arabic headers. It shows "Claude mapped N of M unmapped headers". Each suggestion shows the source (AI), a confidence and a reason. Check the suggestions before you validate.
5. **Required columns still missing** lists what must be mapped before the file can load.

> Claude only receives header names, value shapes and the target column list, never the data rows.

### Step 4: Validate (page 10 → page 20)
Click **Validate** (top right of Files & Mapping). The app reads every sheet, runs all rules and opens **Validation Results**. Validation is repeatable: running it again replaces the previous results.

### Step 5: Review the results (page 20)
- **Batch header** (also on pages 10, 30 and 40): status, readiness score and badge, and the line, error, warning and info counts.
- **Issues by object and severity**: a bar chart.
- **Reconciliations**: sub-ledger totals compared with the GL, per currency.

  | Check | Compares |
  |---|---|
  | Trial balance | debits = credits per ledger, period and currency |
  | AP vs GL 21100 | open AP remaining amounts vs the GL liability account |
  | AR vs GL 11300 | open AR amounts due vs the GL receivables account |
  | Cash vs GL 11100 | bank opening balances vs the GL cash account |

  **MATCHED** = within tolerance. **DIFF** = investigate. "No GL balance" = the GL file has no balance for that account and currency.
- **Issues**: the full list with severity, rule, line, column, bad value, message and **How to fix**. Use the report's search, filters and download. Click a **Line** number to open **Row Detail** (page 21): that line's values (sensitive columns masked) and all of its issues.
- **Run validation** runs the checks again. **Generate AI report** opens page 30.

**Severities**
- **ERROR**: blocks the FBDI load.
- **WARNING**: needs a decision.
- **INFO**: for awareness.

**Readiness**
- **NOT_READY**: any error.
- **READY_WITH_WARNINGS**: warnings only.
- **READY**: no errors or warnings.

**Score** = % of data lines without errors, minus 5 points for each file-level error (missing column, failed reconciliation), never below 0.

### Step 6: AI readiness report (page 30)
1. Choose **English** or **العربية** and click **Generate with Claude**. It takes about 1–2 minutes. The button works once the batch has been validated; otherwise a note tells you to validate first.
2. The report shows:
   - **Executive summary** and readiness explanation.
   - **Modules**: one card per object, with status BLOCKED, WARNING, OK or NOT_PROVIDED, key findings and actions.
   - **Insights**: patterns an experienced consultant would notice, with evidence and impact.
   - **Reconciliation comments**, **Top risks** and **Next steps** (with an owner: client, consultant or both).
   - **What Claude received**: the exact facts sent, for transparency.
   - **History**: every report for the batch. Click a row to reopen it.
3. Switching the language shows the latest report in that language. Arabic reports are shown right-to-left.

### Step 7: Ask Claude (page 40)
Type a question in English or Arabic and click **Ask Claude**, or use a quick button:
- *Top 5 blocking issues*
- *Explain the AP to GL difference*
- *What should the client fix first?*
- *لخص الوضع بالعربي*

Answers usually take 10–20 seconds. Claude answers only from this batch's facts and quotes counts and amounts exactly. The conversation is kept per user and per batch.

---

## 4. Admin pages (ADMIN role)

| Page | Use |
|---|---|
| **Objects** (90) | Enable or disable objects, sheet alias, Fusion target, load order. |
| **Columns** (91) | Pick an object, then maintain its columns (type, length, required, unique key, pattern, sensitive), allowed values and header aliases. |
| **Rules** (92 / 94) | List all rules; open one to change severity, enable it, or edit the SQL of row and reconciliation rules. **Test rule** checks the SQL before you run it on a batch. |
| **Error Log** (93) | Technical errors logged by the database packages, newest first. |

Rule SQL must reference the batch through `join b on b.batch_id = <view>.batch_id`.
- Row rules return `file_id, line_number, column_name, bad_value, message`.
- Reconciliations return `recon_label, currency_code, source_total, target_total`.

---

## 5. Privacy and security
- Claude receives **aggregated facts only**: counts, column profiles, up to 3 example issues per rule, and reconciliation totals. It never receives whole files.
- Sensitive columns (IBAN, bank account numbers) are masked before anything is sent to Claude or shown on screen (`*****1234`).
- The Anthropic API key is stored only in an APEX Web Credential.
- Every page needs a signed-in user. Admin pages need the ADMIN role. Page links are checksum-protected.

---

## 6. Troubleshooting

| Symptom | What to do |
|---|---|
| A sheet shows *Unknown sheet* | Rename the sheet to the object name, assign the object on the mapping page, or **Ignore** it if it isn't data. |
| *Missing required columns* | Open the mapping, map the header by hand or use **Suggest with Claude**. |
| The batch went back to *Files loaded* | Files, mappings or ignore settings changed. Run **Validate** again. |
| "Validate first" on AI Report | Validate the batch, then generate the report. |
| An amount is in the file but missing from a total | It isn't a plain number (for example `12,500.00`). Fix it; it's listed under *Invalid number*. |
| Claude reports an error | Open **Admin → Error Log**. The AI Report **History** also shows failed runs with their error text. |
