# Fusion Data Readiness: pre-Fusion validation with Claude (APEX 26.1 demo)

Consultants upload the client's migration files (GL opening balances, suppliers, open AP, customers, open AR, bank balances, open POs, open requisitions). The app:

- **validates** each file against a configurable catalogue: required values, types, formats, allowed values, duplicates, cross-file references, and sign rules;
- **reconciles** the sub-ledgers to the GL: trial balance, AP to the liability account, AR to receivables, bank to cash;
- uses **Claude** to map unknown headers (including Arabic ones), to write a readiness report with insights in English or Arabic, and to answer questions in a chat.

Numbers and pass/fail results always come from SQL. Claude explains them.

## Quick start
1. `sql -name <conn> @db/install.sql` as the workspace parsing schema on ATP.
2. Create the Generative AI Service `CLAUDE` (Anthropic Claude) and the AI Agent. See `docs/APP_SPEC.md` §0.
3. Open this folder in VS Code and let Claude Code build the APEX pages from `docs/APP_SPEC.md`. It reads `CLAUDE.md` first.
4. Run the demo with the files in `samples/`.

## Demo script (about 10 minutes)
1. **New batch** "ACME KSA – Mock 1", cutover 2026-12-31.
2. **Upload** `Demo_Migration_Pack.xlsx` and `Open_Requisitions.csv`. Eight objects are detected automatically from the sheet names, and the "Notes" sheet is flagged.
3. **Validate**. Readiness shows NOT_READY. Point out FILE_MISSING_COLUMN on Suppliers.
4. Open the Suppliers mapping and click **Suggest with Claude**. The Arabic header maps to ALTERNATE_NAME and "Supplier Classification" maps to SUPPLIER_TYPE, each with a confidence and a reason. Re-validate.
5. **Results**:
   - the trial balance is out by 3,250.00
   - open AP is 12,500.00 more than GL 21100
   - EUR invoices have no GL balance
   - ask the Issues report in plain words: "VAT problems for suppliers"
6. **AI Report** in English, then regenerate it in Arabic. Show the module cards, the insights (near-duplicate supplier, "Net 30" casing, fully received POs, unapproved requisitions, old open invoices) and "What Claude received", which proves no IBANs or full files were sent.
7. **Ask Claude**: "What should the client fix first?" and «لماذا لا يتطابق رصيد الموردين مع الأستاذ العام؟»

## Extending
- Add an object or column: edit `tools/model.py`, then run `python tools/model.py .` and deploy `db/02` and `db/08`.
- Add a business rule without deploying code: on the Admin › Rules page, add a ROW_SQL or RECON query and click **Test rule**.
