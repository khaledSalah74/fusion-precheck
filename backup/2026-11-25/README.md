# Backup 2026-11-25: Fusion Data Readiness (app 200)

Taken from ATP `TAMIMIATPTST` (Jeddah), schema and workspace `OTL_INTEG_TST`, APEX 26.1.6, before the app and its database objects were removed from that test database.

## Contents

| Path | What | Use |
|---|---|---|
| `app/f200.sql` | APEX application export (classic, installable). Includes pages, shared components, the Guru Hits stylesheet and logo (static files), ACL roles and role assignments | App Builder → Import, or SQLcl |
| `ddl/xxx_fv_schema_ddl.sql` | DDL of all 36 XXX_FV objects as generated from the live database (17 tables, 8 views, 6 package specs, 5 bodies) | Cross-check / emergency rebuild. The normal install is `db/install.sql` |
| `data/config_inserts.sql` | Configuration as INSERTs: objects, columns, allowed values, aliases, statuses, transitions | Same content as `db/08_seed_config.sql` / `09_seed_rules.sql` at backup time |
| `data/*.json` | Every table as JSON (SQLcl `sqlformat json`): rules, batches, files, mappings, staging, issues, reconciliations, AI reports and chats, error log | Reference / audit; reload with SQLcl `load` or a small script if ever needed |
| `data/xxx_fv_documents_meta.json` | Metadata of the 3 uploaded documents. The BLOBs themselves are not exported: they are byte-identical to `samples/Demo_Migration_Pack.xlsx` (21,648 bytes), `samples/Open_Requisitions.csv` (2,304) and `samples/Valid_Migration_Pack.xlsx` (28,061) | Re-upload the samples |

The application source in APEXlang is in the repository under `apex/` (the source of truth). `f200.sql` is the same app as a classic export, for instances where you prefer App Builder import.

## Restore on another instance

1. **Database objects** (as the APEX workspace parsing schema):
   ```
   sql <user>@<connect> @db/install.sql
   @db/11_smoke_test.sql        -- expect: SMOKE TEST PASSED (9 checks)
   ```
2. **Generative AI Service** (by hand, Workspace Utilities → Generative AI Services):
   - provider Anthropic Claude, Static ID **`CLAUDE`**, a current Claude model;
   - a new Web Credential holding the API key. Never put the key in code.
3. **Application**, one of:
   - `apex import -input apex -workspace <WS>` from the repository (APEXlang), after editing `apex/deployments/default.json` (workspace name, app id); or
   - App Builder → Import → `backup/2026-11-25/app/f200.sql`.

   Then check that `staticFiles.apexFilesPath` / Image Prefix matches the target APEX version (it is set to the 26.1.6 CDN).
4. Grant your user the **ADMIN** role (Shared Components → Application Access Control) for the admin pages.
5. Demo data: create a batch, upload the files in `samples/`, Validate. Expected results are in `CLAUDE.md`.

The app needs no app-level AI Attributes: every AI call names the `CLAUDE` service explicitly.
