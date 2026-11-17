# CLAUDE.md: XXX_FV Pre-Fusion Data Validation (demo)

## What this is
This is an Oracle APEX 26.1 app on ATP. Before Fusion FBDI loads, consultants upload the client's master data and opening balance files (GL, AP, AR, CE, PO, PR). The app validates them with configurable rules, reconciles the sub-ledgers to the GL, and uses **Claude** (an APEX Generative AI Service with static ID `CLAUDE`) to:
1. suggest column mappings for headers it doesn't recognise, including Arabic ones,
2. write a readiness report with insights, in English or Arabic,
3. answer questions about a batch in the "Ask Claude" chat.

**Design rule: SQL decides, Claude explains.** Validation results and the readiness score are deterministic SQL. Claude only receives aggregated facts (profiles, counts, at most 3 example issues per rule, and reconciliation totals). It never receives whole files. Sensitive columns (IBAN, account numbers) are masked before anything leaves the database, and mapping uses value "shapes" where digits become 9.

## Environment
- DB: ATP. Connection for SQLcl MCP: `<FILL_ME: saved connection name>`, using the APEX workspace parsing schema.
- APEX 26.1.6. Workspace `<FILL_ME>`, app ID `<FILL_ME>`.
- SQLcl: `C:\Users\dell\.vscode\extensions\oracle.sql-developer-26.3.1-win32-x64\dbtools\sqlcl\bin\sql.exe`. This path changes when the extension updates.
- `APEX_AI` needs an APEX session. To test the AI from SQLcl, run this first:
  ```sql
  begin apex_session.create_session(p_app_id => <APP_ID>, p_page_id => 1, p_username => 'KHALED'); end;
  /
  ```

## Repository layout
```
db/01_tables.sql              data model, constraints, indexes
db/02_views.sql               GENERATED typed pivot views (one per object)
db/03_xxx_fv_const_log.sql    constants, error codes, autonomous logger
db/04_xxx_fv_file_adapter_pkg APEX_DATA_PARSER adapter: documents -> files -> headers -> staging
db/05_xxx_fv_rules_pkg.sql    core rules engine (pure SQL/PLSQL, no APEX)
db/06_xxx_fv_ai_pkg.sql       APEX_AI adapter: context JSON, report, mapping suggestions
db/07_xxx_fv_batch_api.sql    entry API for APEX: locking, status transitions, orchestration
db/08_seed_config.sql         GENERATED objects/columns/allowed values/aliases
db/09_seed_rules.sql          statuses, transitions, built-in + custom rules (ROW_SQL, RECON)
db/10_xxx_fv_rules_tst.sql    utPLSQL suite
db/install.sql / uninstall.sql
docs/APP_SPEC.md              page-by-page APEX spec. Build the app from this.
samples/                      demo files with deliberate problems
tools/model.py                source of truth for objects/columns -> regenerates 02 and 08
tools/make_samples.py         rebuilds the demo files
tools/simulate.py             Python re-implementation that predicts the demo results
apex/                         APEXlang export of the app (once created)
```

## Layers (do not break)
```
APEX pages ──> xxx_fv_batch_api ──> xxx_fv_file_adapter_pkg (APEX_DATA_PARSER)
                                ├─> xxx_fv_rules_pkg        (core, no APEX/HTTP)
                                └─> xxx_fv_ai_pkg           (APEX_AI -> Claude)
shared: xxx_fv_const_pkg, xxx_fv_log_pkg
```

## Team rules (non-negotiable; see the oracle-refactor-review skill for the full catalog)
- **No COMMIT in any package.** APEX commits at the end of the request. The only commit is inside `xxx_fv_log_pkg.error` (an autonomous transaction).
- `WHEN OTHERS` always calls `xxx_fv_log_pkg.error(...)` and then `RAISE`. The only exceptions are the two status-code APIs in `xxx_fv_ai_pkg`, which use `SAVEPOINT`/`ROLLBACK TO` and return `x_return_status`.
- Bind variables everywhere. The only dynamic SQL is the plug-in rule wrapper in `xxx_fv_rules_pkg`, and it binds every value.
- Use ANSI joins (`JOIN ... ON`), never comma joins with `(+)`.
- Status changes go only through `xxx_fv_batch_api` (`begin_change`/`set_status` plus `xxx_fv_status_transitions`).
- Write set-based SQL first. When you need a loop, add a comment saying why.
- Use the codes and error numbers in `xxx_fv_const_pkg`; don't hard-code them.
- Core code (`xxx_fv_rules_pkg`) never reads `V('APP_USER')`, `SYSDATE` for logic, or any `APEX_*` package. Pass the context in instead.
- APEX pages are thin. Each process calls one `xxx_fv_batch_api` procedure, plus at most a few lines of UI glue.
- Make targeted edits. Don't reformat or restructure code you weren't asked to change.
- Don't edit `02_views.sql` or `08_seed_config.sql` by hand. Change `tools/model.py`, then run `python tools/model.py .` from the repo root.
- Every change to `xxx_fv_rules_pkg` needs a utPLSQL test. Write it first and see it fail.

## Build order (for Claude Code)
1. **Install the DB layer.** In a terminal: `sql -name <CONN> @db/install.sql`. Then check that `user_errors` has no rows for `XXX_FV%`, and fix compile errors one at a time. The code has not been compiled yet. The most likely spots are `APEX_DATA_PARSER` parameter names and the JSON functions in `xxx_fv_ai_pkg`.
2. If utPLSQL is installed, run `@db/10_xxx_fv_rules_tst.sql` and then `exec ut.run('xxx_fv_rules_tst')`.
3. Smoke-test the parser without the UI. Load `samples/Demo_Migration_Pack.xlsx` into a BLOB (for example from `apex_application_static_files`, or with an upload through the app), call `xxx_fv_batch_api.add_document`, then `validate_batch`. Compare the results with **Expected demo results** below.
4. **The user creates the Generative AI Service by hand** (APP_SPEC §0). Don't try to script API keys.
5. **Build the app with APEXlang.**
   - Create an empty app in the builder.
   - `apex export -applicationid <APP_ID> -exptype APEXLANG -dir apex`
   - Add the pages from `docs/APP_SPEC.md` by editing the APEXlang files.
   - `apex validate`, then `apex import`.
   - In SQLcl 26.x, run `help skills` to install Oracle's APEXlang skills for agents before generating pages.
   - Work one page at a time, and validate and import after each page.
6. Export a split copy to Git after each working step (PLT-03).

## Expected demo results (from tools/simulate.py)
Upload `Demo_Migration_Pack.xlsx` and `Open_Requisitions.csv`. The first validation shows:
- **Notes** sheet: FILE_UNKNOWN_OBJECT (WARNING).
- **Suppliers**: the headers "اسم المورد بالعربي" and "Supplier Classification" are not mapped, which gives FILE_MISSING_COLUMN for SUPPLIER_TYPE (ERROR). After **Suggest with Claude**, they should map to ALTERNATE_NAME and SUPPLIER_TYPE.
- Supplier errors:
  - duplicate S1007/MAIN
  - empty name
  - 2 bad VAT numbers
  - an IBAN with spaces
  - "Net 30" casing ×3
  - a bad e-mail
  - country "KSA"
  - a site name longer than 40 characters
  - similar names: Al-Rajhi Trading Co. and AL RAJHI TRADING COMPANY
  - 2 SA suppliers without VAT
- AP invoices:
  - 2 invoices for unknown supplier S1099
  - an amount remaining greater than the invoice amount
  - an invoice dated after cutover
  - date `31/10/2026`
  - amount `12,500.00`
  - a positive CREDIT
  - a duplicate invoice
  - a bad liability account
- Reconciliations:

  | Reconciliation | Currency | Result |
  |---|---|---|
  | Trial balance Dec-26 | SAR | **DIFF 3,250.00** (ERROR) |
  | Trial balance Dec-26 | USD | MATCHED |
  | AP vs GL 21100 | SAR | **DIFF 12,500.00** |
  | AP vs GL 21100 | USD | MATCHED |
  | AP vs GL 21100 | EUR | **DIFF 30,000.00** (no GL balance) |
  | AR vs GL 11300 | SAR | MATCHED |
  | Cash vs GL 11100 | SAR and USD | MATCHED |
- PO:
  - received greater than ordered
  - 3 lines fully received
  - an unknown supplier
  - a zero price
  - category "IT HARDWARE"
- PR: 8 lines not approved, a bad e-mail, need-by dates already past.
- Readiness: **NOT_READY**.

## Don'ts
- Don't send raw file rows or unmasked sensitive values to the AI.
- Don't add `COMMIT`, autonomous transactions or HTTP calls outside the places listed above.
- Don't put validation logic in APEX pages or in Claude prompts. Add a rule row in `xxx_fv_rules` instead.
- Don't store API keys anywhere except APEX Web Credentials.
