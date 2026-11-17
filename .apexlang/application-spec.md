# Application Spec: Fusion Data Readiness (APEX 26.1, APEXlang)

Source of requirements: `docs/APP_SPEC.md` (FR ids below follow its section order).
Source of structure: `db/01_tables.sql`, `db/07_xxx_fv_batch_api.sql`, live DB `Tamimi-Test` (schema OTL_INTEG_TST).

## Summary

- Application purpose: validate client master data / opening balance files before Fusion FBDI loads; Claude explains results.
- Target users: migration consultants (FV_USER), configuration admins (FV_ADMIN, ACL role ADMIN).
- Primary workflows: create batch -> upload files -> fix mapping -> validate -> review results -> AI report -> ask Claude.
- Authoritative sources: schema_doc `db/01_tables.sql`; package specs `db/07_xxx_fv_batch_api.sql`, `db/05_xxx_fv_rules_pkg.sql`, `db/06_xxx_fv_ai_pkg.sql`; live_db Tamimi-Test.
- Target app path: `apex/`
- Runtime mode: live DB check (connection `Tamimi-Test`)
- Destination APEX workspace: `OTL_INTEG_TST` (user confirmed; apex_workspace_schemas maps the schema to it)
- App id: 200 (new app)
- Known exclusions: APP_SPEC §0.1 Generative AI Service (created by hand in builder, done). Background execution chain on page 10 is optional in FR and excluded for v1.

## Build Order (one page at a time, validate + import after each)

| Unit | Content | Status |
| --- | --- | --- |
| U1 | App shell (name, AI attribute = CLAUDE, ACL role ADMIN, FV_USER/FV_ADMIN, nav menu, breadcrumbs) + Page 1 Batches | in progress |
| U2 | Page 2 New Batch (modal) | planned |
| U3 | Page 10 Files & Mapping | planned |
| U4 | Page 11 Column Mapping (modal) | planned |
| U5 | Page 20 Validation Results | planned |
| U6 | Page 21 Row Detail (modal) | planned |
| U7 | Page 30 AI Report | planned |
| U8 | AI Agent fv_batch_analyst + Page 40 Ask Claude | planned |
| U9 | Pages 90-93 Admin | planned |

Forward links (page 1 -> 2, 1 -> 10) target pages delivered in later units; navigation entries for admin pages are added with U9.

## Requirement Coverage Matrix

| Requirement ID | Requirement Text / Cue | Planned Page / Region / Action | Frozen Plan Reference | Status | Evidence |
| --- | --- | --- | --- | --- | --- |
| FR-0.2 | App AI attributes service = CLAUDE | set by hand in builder after first import (APP_SPEC §0.2), then captured into source by re-export; `@claude`/`@CLAUDE` do not resolve without the workspace component file | App shell | covered (manual step) | APP_SPEC §0.2, apex validate REFERENCE_NOT_FOUND |
| FR-0.3 | AI Agent fv_batch_analyst with augment-system-prompt tool | shared-components/ai-agents | U8 | covered | APP_SPEC §0.3 |
| FR-0.4 | FV_USER / FV_ADMIN authorization, ACL role ADMIN | authorizations.apx, acl-roles.apx | App shell | covered | APP_SPEC §0.4 |
| FR-0.5 | Session state protection, ID items checksum session level | every ID item | all units | covered | APP_SPEC §0.5 |
| FR-1 | Side menu Batches, Admin > Objects/Columns/Rules/Error Log | lists.apx navigation-menu | App shell + U9 | covered | APP_SPEC §1 |
| FR-1.1 | Batch header region + page tabs on 10/20/30/40 | shared region pattern per page | U3,U5,U7,U8 | covered | APP_SPEC §1 |
| FR-2.1 | Page 1 Batches cards, card -> page 10, New batch -> page 2 | Page 1 | U1 | covered | APP_SPEC §2 Page 1 |
| FR-2.2 | Page 2 New Batch modal, create_batch, branch to 10 | Page 2 | U2 | covered | APP_SPEC §2 Page 2 |
| FR-2.10 | Page 10 upload, files IR, remove, validate | Page 10 | U3 | covered | APP_SPEC §2 Page 10 |
| FR-2.11 | Page 11 assign object, mapping IG, suggest with Claude | Page 11 | U4 | covered | APP_SPEC §2 Page 11 |
| FR-2.20 | Page 20 chart, recon report, issues IR (NL), buttons | Page 20 | U5 | covered | APP_SPEC §2 Page 20 |
| FR-2.21 | Page 21 row values (masked) + line issues | Page 21 | U6 | covered | APP_SPEC §2 Page 21 |
| FR-2.30 | Page 30 AI report regions + generate | Page 30 | U7 | covered | APP_SPEC §2 Page 30 |
| FR-2.40 | Page 40 inline AI assistant + chips | Page 40 | U8 | covered | APP_SPEC §2 Page 40 |
| FR-2.90..93 | Admin Objects, Columns, Rules, Error Log | Pages 90-93 | U9 | covered | APP_SPEC §2 Admin |
| FR-3 | Thin pages, escaping on, no COMMIT, bind variables | all pages | all units | covered | APP_SPEC §3 |

## Source Evidence Matrix (U1)

| Fact Type | Object / Column | Evidence | Detail | Status |
| --- | --- | --- | --- | --- |
| table | XXX_FV_BATCHES (batch_id PK identity, batch_name, client_name, cutover_date, status_code FK, readiness_score 0-100, readiness_status CK READY/READY_WITH_WARNINGS/NOT_READY, error_count, warning_count, created_on) | schema_doc + live_db | 01_tables.sql | ok |
| table | XXX_FV_BATCH_STATUSES (status_code PK, status_name) | schema_doc + live_db | 01_tables.sql | ok |
| fk | XXX_FV_BATCHES.status_code -> XXX_FV_BATCH_STATUSES | schema_doc | xxx_fv_batches_fk1 | ok |
| service | Generative AI service static id CLAUDE | live_db | apex_workspace_remote_servers | ok |
| constant | xxx_fv_const_pkg.c_ai_service_static_id = 'CLAUDE' | schema_doc | 03_xxx_fv_const_log.sql | ok |

## Frozen Application Plan

| Page | Name | Group | Type / Native Pattern | Page Mode | Menu | Breadcrumb Entry | Requirement ID | Primary Source |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Batches | - | Cards | normal | Batches (fa-database) | batches (root) | FR-2.1 | sql (batches join statuses) |
| 2 | New Batch | - | Form (custom process) | modal dialog | - | exempt | FR-2.2 | none (API) |
| 10 | Files & Mapping | Batch | IR + upload | normal | - | files (parent batches) | FR-2.10 | sql |
| 11 | Column Mapping | Batch | IG + form | modal dialog | - | exempt | FR-2.11 | sql |
| 20 | Validation Results | Batch | Chart + CR + IR | normal | - | results (parent batches) | FR-2.20 | sql |
| 21 | Row Detail | Batch | Classic reports | modal dialog | - | exempt | FR-2.21 | sql |
| 30 | AI Report | Batch | Cards/lists from JSON | normal | - | ai-report (parent batches) | FR-2.30 | sql |
| 40 | Ask Claude | Batch | AI assistant inline | normal | - | ask-claude (parent batches) | FR-2.40 | none |
| 90 | Objects | Administration | IR + form | normal | Admin > Objects | objects (root) | FR-2.90 | table |
| 91 | Columns | Administration | IG master-detail | normal | Admin > Columns | columns (root) | FR-2.91 | table |
| 92 | Rules | Administration | IR + form | normal | Admin > Rules | rules (root) | FR-2.92 | table |
| 93 | Error Log | Administration | IR read-only | normal | Admin > Error Log | error-log (root) | FR-2.93 | table |

Page 1 is the home page (replaces scaffold Home). Pages 90-93 require FV_ADMIN; all others FV_USER.

## Frozen Region Plan (U1: Page 1)

| Page | Order | Region Name | Family | Role | Source Shape | Source / Intent | Layout | Columns / Mappings | Links / Actions | Filters | Refresh |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | 10 | Batches | breadcrumb (title-bar) | chrome | none/staticContent | @breadcrumb | breadcrumbBar | - | New batch button -> page 2 (placement: breadcrumb) | - | - |
| 1 | 20 | Migration Batches | cards | report | sql | FR-2.1 query + readiness_css/readiness_label derived columns | body, grid | title=BATCH_NAME, subtitle=CLIENT_NAME, body=status/cutover/counts, badge=READINESS_LABEL, card css=READINESS_CSS (u-danger/u-warning/u-success) | fullCard -> page 10 P10_BATCH_ID=&BATCH_ID. | - | refresh after dialog close (page 2) |

## Application Composition Plan

- Application scope: one app, id 200, alias FUSION-DATA-READINESS.
- Page groups: Administration (90-93), Batch (10-40).
- Shared LOVs: TARGET_ENV (static DEV/TEST/UAT/PROD) with U2.
- Navigation menu: Batches (1) now; Admin parent + 4 children with U9.
- Static files/icons: scaffold icons.

### Breadcrumb Hierarchy

| Page | Entry | Root | Parent Entry | Evidence |
| --- | --- | --- | --- | --- |
| 1 | batches | true | - | FR-2.1 |
| 10 | files | - | batches | FR-1.1 |
| 20 | results | - | batches | FR-1.1 |
| 30 | ai-report | - | batches | FR-1.1 |
| 40 | ask-claude | - | batches | FR-1.1 |
| 90-93 | objects / columns / rules / error-log | true | - | FR-2.90..93 |

## Behavior Coverage

### Modal Targets And Cross-Page Links

| Source Page | Source | Target Page | Target Items | Key Column | Presentation | Close Refresh Region | Req |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1 | Migration Batches full card | 10 | P10_BATCH_ID | BATCH_ID | normal page | - | FR-2.1 |
| 1 | New batch button | 2 | - | - | modal dialog | Migration Batches | FR-2.1 |
| 2 | after create | 10 | P10_BATCH_ID=&P2_BATCH_ID. | BATCH_ID | close dialog + branch | - | FR-2.2 |

### Page-Level Actions

| Page | Label | Target Page | Item Mappings | Placement | Req |
| --- | --- | --- | --- | --- | --- |
| 1 | New batch | 2 | - | breadcrumb | FR-2.1 |

### Security, Guidance, And Empty States

| Page / Region | Type | Behavior | Req |
| --- | --- | --- | --- |
| app | authorization | FV_USER (must not be public user) on user pages; FV_ADMIN (ACL role ADMIN) on 90-93 | FR-0.4 |
| 1 / Migration Batches | no-data | "No batches yet. Click New batch to start." icon fa-database | DW-001 |

## Rich UI Pattern Plan

| Pattern | Page / Region | Native Component | Evidence |
| --- | --- | --- | --- |
| status-colored cards | 1 / Migration Batches | Cards with badge + card cssClasses | FR-2.1 + FR-1.1 (badge colors) + readiness_status check constraint |

## LOVs

- Static: TARGET_ENV DEV/TEST/UAT/PROD (FR-2.2) - U2.
- Dynamic: objects (U4), mapped columns (U4).

## Test Plan (U1)

| Scenario | Pages | Expected | Method |
| --- | --- | --- | --- |
| App shell validates | all | no errors | apex validate (live) |
| Page 1 renders with no batches | 1 | empty-state message | runtime after import |
| Card badge color by readiness | 1 | NOT_READY red, READY_WITH_WARNINGS amber, READY green, null grey | runtime after U3 data |

## Assumptions

- FV_USER = "must not be public user" built-in check (any authenticated user, per FR-0.4).
- Readiness badge label shows score + status, e.g. "35 · NOT_READY"; null score shows "Not validated".

## Known Tooling Limitation: CLAUDE service in APEXlang (2026-11-17)

- `apex export` (APEX 26.1.6) writes `genAIService CLAUDE ( provider: CLAUDE ... )` plus `genAI { service: @CLAUDE }`.
- `apex validate` in SQLcl 26.3.1 rejects `provider: CLAUDE` (accepts only cohere, genericOpenaiApiCompatible, googleGemini, ociGenAI, openai), and `@CLAUDE` does not resolve without that file.
- Workaround: keep the exported files in `.apexlang/workspace-components-export/` (no secrets: header name only) and leave `genAI` out of `application.apx`. The DB package passes `CLAUDE` explicitly to APEX_AI, so the AI report and mapping suggestions do not need the app attribute.
- Affected later: page 20 IR Natural Language and page 40 AI agent/assistant need the app-level service. Re-check a newer SQLcl before U5/U8; otherwise set AI Attributes by hand after the final import.

## Missing Inputs / Blockers

- none for U1. App id 200 availability on the instance is confirmed at import time.
