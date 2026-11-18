# Fusion Data Readiness: Solution Design

Version: demo build, 2026-11-18. App 200 on ATP (Jeddah region), APEX 26.1.6, Oracle Database 23ai, workspace and parsing schema `OTL_INTEG_TST`.

---

## 1. Purpose and scope

**Problem.** Before an Oracle Fusion Cloud ERP go-live, legacy master data and opening balances are loaded through FBDI. Bad files are usually found late, when Fusion's import programs reject rows: wrong lookup codes, unbalanced journals, sub-ledgers that don't agree with the GL, duplicates, numbers with thousands separators. Each failed load costs a round trip with the client.

**Solution.** A pre-load validation workbench:
1. Consultants upload the client's files as they are (Excel or CSV).
2. The app recognises each sheet's object and maps its columns. Claude helps with headers it doesn't recognise, including Arabic ones.
3. Configurable SQL rules check every value and every cross-file relationship, and reconcile AP, AR and cash to the GL.
4. A deterministic readiness score tells whether the pack can go to FBDI.
5. Claude writes a readiness report (English or Arabic) and answers questions about the batch.

**In scope (demo):** 8 objects across GL, AP, AR, CE, PO and PR (81 columns), and 36 rules: 12 built-in checks, 20 row rules and 4 reconciliations.

**Out of scope (demo):** generating the FBDI CSV/zip files, loading Fusion, multiple clients or tenants. See `DEMO_AND_NEXT_STEPS.md`.

**Design rule: SQL decides, Claude explains.** Every pass/fail result and the score are SQL. Claude never changes a result. It receives aggregated, masked facts only.

---

## 2. Architecture

```
 Browser ── APEX app 200 (Universal Theme + Guru Hits theme layer)
               │   thin pages: each process calls one xxx_fv_batch_api procedure
               ▼
        xxx_fv_batch_api ── locking, status transitions, orchestration
               ├──► xxx_fv_file_adapter_pkg ── APEX_DATA_PARSER: documents → sheets → headers → staging
               ├──► xxx_fv_rules_pkg        ── core engine: built-in checks, plug-in rules, readiness (no APEX/HTTP)
               └──► xxx_fv_ai_pkg           ── APEX_AI → Generative AI Service "CLAUDE" → Anthropic API
        shared: xxx_fv_const_pkg (codes, error numbers), xxx_fv_log_pkg (autonomous error log)
```

| Layer | Component | Responsibility |
|---|---|---|
| UI | APEX pages 1–94 | Display and capture only. No business SQL beyond report queries; no `COMMIT`. |
| API | `xxx_fv_batch_api` | One entry point per user action. Locks the batch (`for update wait 10`), checks the status transition, does the work, sets the status. No-op when nothing changes. |
| Adapter | `xxx_fv_file_adapter_pkg` | Stores documents, splits workbooks into sheets, detects objects, captures headers and value shapes, auto-maps, stages values, ignores sheets. |
| Core | `xxx_fv_rules_pkg` | Clears and recomputes issues and reconciliations for a batch (idempotent). Pure SQL/PL/SQL. |
| AI | `xxx_fv_ai_pkg` | Builds context JSON, calls Claude, validates and stores the response, mapping suggestions, chat. |
| Config | `xxx_fv_objects`, `_columns`, `_column_values`, `_column_aliases`, `_rules` | Catalogue and rules as data; maintained on the Admin pages. |

**Generated code.** `tools/model.py` is the single source of truth for objects and columns. It generates `db/02_views.sql` (typed pivot views) and `db/08_seed_config.sql`.

---

## 3. Data model

| Table | Holds | Key points |
|---|---|---|
| `XXX_FV_BATCHES` | One validation run per client cutover | Status, cutover date, counts, readiness score and status, `row_version` for optimistic locking |
| `XXX_FV_BATCH_STATUSES` / `_STATUS_TRANSITIONS` | Allowed statuses and moves | NEW → FILES_LOADED → VALIDATED → REPORTED (and back to FILES_LOADED on change) |
| `XXX_FV_DOCUMENTS` | Uploaded file (BLOB) | One per upload; deleting it cascades to sheets, mappings, staging and results |
| `XXX_FV_FILES` | One row per sheet (or CSV) | `object_code`, `is_ignored`, `row_count` |
| `XXX_FV_FILE_COLUMNS` | Headers per sheet | Normalised header, value shape, `mapped_column`, `mapping_source` (AUTO / AI / USER), AI confidence and reason |
| `XXX_FV_STAGE_LINES` / `_STAGE_VALUES` | Parsed data, one row per non-empty cell | Values kept as text; typing happens in the views |
| `XXX_FV_*_V` (8 views) | Typed pivot per object | Invalid numbers and dates become NULL. They use the same number test as the checks, so an invalid value is never summed. |
| `XXX_FV_ISSUES` | Every finding | Severity, rule, file, line, column, masked bad value, message |
| `XXX_FV_RECON_RESULTS` | Reconciliations | Source total, target total, difference, MATCHED / DIFF |
| `XXX_FV_AI_REPORTS` | Every AI call | Types BATCH_REPORT, MAPPING and CHAT; context and response JSON, status, error, elapsed ms, user |
| `XXX_FV_ERROR_LOG` | Technical errors | Written by an autonomous transaction (the only commit in the code) |

---

## 4. Processing flow

### 4.1 Upload (`add_uploaded_files` → `add_document` → `register_document`)
1. The file is read from `APEX_APPLICATION_TEMP_FILES` and stored as a document.
2. XLSX: one file row per worksheet (`APEX_DATA_PARSER.GET_XLSX_WORKSHEETS`). CSV: one file row.
3. **Object detection:**
   - **By name:** the normalised sheet or file name equals an object code or sheet alias.
   - **By headers,** if the name doesn't match: each header that matches an object's column or alias scores 1 divided by the number of objects it matches. Distinctive headers such as `LEDGER_NAME` outweigh shared ones such as `CURRENCY`. An object is chosen only on a clear win: score ≥ 1.5 and ≥ 1.5 × the runner-up.
4. **Headers:** captured from line 1. The value shape is the first sample value with digits replaced by `9`.
5. **Auto-map:** a header that equals a column name or a known alias is mapped (source AUTO). If two headers match the same column, the first one wins.

### 4.2 Mapping
- **Manual:** grid edit, `set_mapping` (source USER).
- **Assign object:** remaps from scratch. A header-fit warning suggests the right object when the current one is clearly wrong.
- **Claude:** `suggest_mapping` sends target columns (type, required, format, allowed values) plus the unmapped headers and their value shapes. Suggestions with confidence ≥ 0.5 are applied only to unmapped headers and only to free targets. The message reports "mapped N of M" and flags a likely wrong object.
- **Ignore sheet:** `ignore_file` clears the object, mapping and staging. Ignored sheets are skipped by staging, file checks and the AI context.

### 4.3 Validation (`validate_batch`)
1. Lock the batch and check the move to VALIDATED.
2. Stage every non-ignored sheet: parse it again and replace its staging rows (idempotent).
3. `xxx_fv_rules_pkg.run_all`:
   - **File checks:** unknown sheet, missing or unmapped column, empty file, object not provided.
   - **Required values:** per mapped required column, per line.
   - **Value checks:** one pass over every cell. The first failure is reported: number → date → max length → pattern → allowed value.
   - **Duplicate business keys:** across all files of an object, one issue per duplicated line.
   - **Plug-in rules:** each enabled ROW_SQL or RECON rule whose object has a file in the batch. The SQL is screened and runs with bind variables. A failing rule is logged, reported as an ERROR issue and skipped, so validation still finishes.
4. **Readiness** is calculated and stored on the batch. Status moves to VALIDATED.

### 4.4 Rules catalogue (36)

| Group | Rules |
|---|---|
| File (5) | FILE_UNKNOWN_OBJECT, FILE_MISSING_COLUMN, FILE_UNMAPPED_COLUMN, FILE_EMPTY, BATCH_OBJECT_MISSING |
| Value (7) | COL_REQUIRED, COL_NUMBER, COL_DATE, COL_MAX_LENGTH, COL_PATTERN, COL_ALLOWED_VALUE, COL_DUPLICATE_KEY |
| AP (7) | AP_SUP_VAT_MISSING, AP_SUP_SIMILAR_NAME, AP_INV_SUPPLIER_EXISTS, AP_INV_REMAINING_GT_AMOUNT, AP_INV_SIGN, AP_INV_AFTER_CUTOVER, AP_INV_CURRENCY_DIFF |
| AR (4) | AR_INV_CUSTOMER_EXISTS, AR_TRX_SIGN, AR_DUE_GT_ORIGINAL, AR_CUST_NO_CREDIT_LIMIT |
| GL / CE (3) | GL_LINE_DR_AND_CR, GL_LINE_ZERO, CE_BALANCE_DATE |
| PO / PR (6) | PO_SUPPLIER_EXISTS, PO_RECEIVED_GT_ORDERED, PO_FULLY_RECEIVED, PO_PRICE_NOT_POSITIVE, PR_NOT_APPROVED, PR_NEED_BY_PAST |
| Reconciliations (4) | GL_TRIAL_BALANCE (ERROR, tolerance 0.01), AP_TO_GL, AR_TO_GL, CASH_TO_GL (WARNING, tolerance 1) |

Each rule's link to an FBDI requirement is listed in `samples/FBDI_Mapping_Reference.xlsx`, sheet *Validation vs FBDI*.

### 4.5 Readiness
- **Status:** NOT_READY if any ERROR, READY_WITH_WARNINGS if any WARNING, otherwise READY. INFO doesn't affect it.
- **Score:** `round(100 × (lines − lines with an ERROR) / lines) − 5 × (file/batch-level ERRORs)`, never below 0.

---

## 5. AI integration (Claude)

| Feature | Call | Input to Claude | Output and storage |
|---|---|---|---|
| Mapping suggestion | `xxx_fv_ai_pkg.suggest_mapping` | Target columns, already-mapped list, unmapped headers with value shapes | JSON `mappings[]` → applied to `XXX_FV_FILE_COLUMNS`; row type MAPPING |
| Readiness report | `generate_batch_report` | Batch facts JSON: reconciliations, missing objects, files, issue summary with up to 3 masked examples per rule, column profiles (no sums or min/max for sensitive columns) | JSON report (summary, modules, insights, risks, next steps) → page 30; row type BATCH_REPORT |
| Ask Claude chat | `ask_batch` | Same batch facts plus the user's last 6 turns | Plain-text answer; row type CHAT |

**Implementation notes**
- **Calls:** `APEX_AI.GENERATE` with the Generative AI Service static ID `CLAUDE`, passed explicitly, so no app-level AI attribute is needed. The model is set on the service (currently `claude-opus-5-5`).
- **Response format:** the expected JSON Schema goes into the system prompt. APEX's strict schema validation is not used; it rejected usable answers. The package removes code fences and surrounding text, parses the JSON, and keeps the raw answer in the error message if parsing fails.
- **No temperature:** current Claude models reject the `temperature` parameter.
- **Failures:** the AI APIs return a status code instead of raising. On error they roll back to a savepoint, log the error, save a FAILED row and return `E` with the message, which the page shows.
- **Typical timings:**
  - mapping: about 7 seconds;
  - English report: about 2 minutes;
  - Arabic report: about 2 to 3 minutes;
  - chat answer: about 15 seconds.

---

## 6. Security and compliance
- **Authentication:** Oracle APEX Accounts.
- **Authorization:** `FV_USER` (any signed-in user) on all batch pages, and `FV_ADMIN` (ACL role ADMIN) on pages 90–94.
- **Session state protection:** every ID item is checksum-required at session level, and pages require checksummed arguments. Context items are restricted application items.
- **Data minimisation for AI:** aggregates only, sensitive columns masked, and mapping uses value shapes (digits shown as 9).
- **Secrets:** the API key is held only in the APEX Web Credential "Credentials for claude"; the app source contains only the header name.
- **Plug-in rule SQL:** only admins can edit it. It must be a single SELECT/WITH, and the code (ignoring string literals) is screened for `;`, `FOR UPDATE` and DBMS_/UTL_/APEX_/SYS calls. All values are bound.
- **Transactions:** no `COMMIT` in packages; APEX commits at the end of the request. The only commit is in the autonomous error logger.

---

## 7. User interface
- **Theme:** Universal Theme 26.1 (Iris style) plus `guruhits.css`. Guru Hits red is used only as an accent for primary actions, the active tab, the current menu item and focus outlines. Surfaces are neutral, the type is Inter and Montserrat, and status pills are soft tints.
- **Navigation:** side menu (Batches; Admin → Objects, Columns, Rules, Error Log). Pages 10/20/30/40 share a batch header and tabs.
- **Accessibility:** colour is never the only signal (statuses are spelled out), hover motion respects reduced-motion settings, and icons have hidden text labels.

---

## 8. Build, deployment and testing

| Area | How |
|---|---|
| Source control | GitHub `khaledSalah74/fusion-precheck`; app source as APEXlang under `apex/`, planning files under `.apexlang/` |
| Database install | `sql -name <conn> @db/install.sql`; generated files rebuilt with `python tools/model.py .` |
| App deployment | SQLcl 26.3: `apex validate -input apex`, then `apex import -input apex` (app 200) |
| Engine test | `@db/11_smoke_test.sql`: 9 checks, needs nothing installed, rolls back everything |
| Data test | `tools/check_pack.py` mirrors the engine offline. The clean pack gives READY 0/0/0 both offline and in the app (batch "Clean pack check"). The demo pack matches the app on every rule that doesn't depend on Claude's mapping. |
| Demo data | `tools/make_samples.py` (pack with deliberate errors), `tools/make_valid_pack.py` (clean pack), `tools/make_fbdi_mapping.py` (FBDI reference) |

---

## 9. Known limitations (demo build)
- **AI Attributes and imports:** SQLcl 26.3.1 can't compile Anthropic-provider services in APEXlang, so the app-level AI Attributes setting can't live in source and is cleared by each import. Nothing in the app needs it now, because all AI calls name `CLAUDE` explicitly.
- **AI Report "What Claude received":** shows the first 3,800 characters of the context (the full context is stored).
- **Offline checker:** can't reproduce Claude's mapping suggestions.
- **Logo:** cropped from a screenshot; replace it with the official SVG or PNG.
- **Duplicate header row:** a double header row reported on AI Report → History isn't reproduced yet.
- **FBDI files:** the app validates but doesn't generate them yet. The FBDI load notes list what the generator must add.
