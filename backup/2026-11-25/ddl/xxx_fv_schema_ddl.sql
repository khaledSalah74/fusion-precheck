

  CREATE TABLE "XXX_FV_AI_REPORTS"
   (	"REPORT_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"BATCH_ID" NUMBER NOT NULL ENABLE,
	"FILE_ID" NUMBER,
	"REPORT_TYPE" VARCHAR2(20) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"LANGUAGE_CODE" VARCHAR2(2) COLLATE "USING_NLS_COMP" DEFAULT 'EN' NOT NULL ENABLE,
	"STATUS_CODE" VARCHAR2(20) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"SERVICE_STATIC_ID" VARCHAR2(255) COLLATE "USING_NLS_COMP",
	"CONTEXT_JSON" CLOB COLLATE "USING_NLS_COMP",
	"RESPONSE_JSON" CLOB COLLATE "USING_NLS_COMP",
	"ERROR_MESSAGE" VARCHAR2(4000) COLLATE "USING_NLS_COMP",
	"ELAPSED_MS" NUMBER,
	"REQUESTED_BY" VARCHAR2(255) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"REQUESTED_ON" DATE DEFAULT sysdate NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_CK2" CHECK (language_code in ('EN', 'AR')) ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_CK3" CHECK (status_code in ('COMPLETED', 'FAILED')) ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_CK4" CHECK (context_json is json) ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_CK5" CHECK (response_json is json) ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_PK" PRIMARY KEY ("REPORT_ID")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_CK1" CHECK (report_type in ('BATCH_REPORT', 'MAPPING', 'CHAT')) ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_FK1" FOREIGN KEY ("BATCH_ID")
	  REFERENCES "XXX_FV_BATCHES" ("BATCH_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "XXX_FV_AI_REPORTS_FK2" FOREIGN KEY ("FILE_ID")
	  REFERENCES "XXX_FV_FILES" ("FILE_ID") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_BATCHES"
   (	"BATCH_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"BATCH_NAME" VARCHAR2(200) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"CLIENT_NAME" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"TARGET_ENV" VARCHAR2(100) COLLATE "USING_NLS_COMP",
	"CUTOVER_DATE" DATE NOT NULL ENABLE,
	"STATUS_CODE" VARCHAR2(20) COLLATE "USING_NLS_COMP" DEFAULT 'NEW' NOT NULL ENABLE,
	"LINE_COUNT" NUMBER DEFAULT 0 NOT NULL ENABLE,
	"ERROR_COUNT" NUMBER DEFAULT 0 NOT NULL ENABLE,
	"WARNING_COUNT" NUMBER DEFAULT 0 NOT NULL ENABLE,
	"INFO_COUNT" NUMBER DEFAULT 0 NOT NULL ENABLE,
	"READINESS_SCORE" NUMBER(3,0),
	"READINESS_STATUS" VARCHAR2(30) COLLATE "USING_NLS_COMP",
	"LAST_VALIDATED_ON" DATE,
	"ROW_VERSION" NUMBER DEFAULT 1 NOT NULL ENABLE,
	"CREATED_BY" VARCHAR2(255) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"CREATED_ON" DATE DEFAULT sysdate NOT NULL ENABLE,
	"UPDATED_BY" VARCHAR2(255) COLLATE "USING_NLS_COMP",
	"UPDATED_ON" DATE,
	 CONSTRAINT "XXX_FV_BATCHES_CK1" CHECK (readiness_status in ('READY', 'READY_WITH_WARNINGS', 'NOT_READY')) ENABLE,
	 CONSTRAINT "XXX_FV_BATCHES_CK2" CHECK (readiness_score between 0 and 100) ENABLE,
	 CONSTRAINT "XXX_FV_BATCHES_PK" PRIMARY KEY ("BATCH_ID")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_BATCHES_FK1" FOREIGN KEY ("STATUS_CODE")
	  REFERENCES "XXX_FV_BATCH_STATUSES" ("STATUS_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_BATCH_STATUSES"
   (	"STATUS_CODE" VARCHAR2(20) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"STATUS_NAME" VARCHAR2(100) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"DISPLAY_SEQ" NUMBER(3,0) NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_BATCH_STATUSES_PK" PRIMARY KEY ("STATUS_CODE")
  USING INDEX  ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_COLUMNS"
   (	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"COLUMN_NAME" VARCHAR2(60) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"COLUMN_SEQ" NUMBER(3,0) NOT NULL ENABLE,
	"DATA_TYPE" VARCHAR2(10) COLLATE "USING_NLS_COMP" DEFAULT 'VARCHAR2' NOT NULL ENABLE,
	"MAX_LENGTH" NUMBER(5,0),
	"DATE_FORMAT" VARCHAR2(20) COLLATE "USING_NLS_COMP",
	"IS_REQUIRED" VARCHAR2(1) COLLATE "USING_NLS_COMP" DEFAULT 'N' NOT NULL ENABLE,
	"UNIQUE_KEY_SEQ" NUMBER(2,0),
	"REGEX_PATTERN" VARCHAR2(400) COLLATE "USING_NLS_COMP",
	"PATTERN_HINT" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"IS_SENSITIVE" VARCHAR2(1) COLLATE "USING_NLS_COMP" DEFAULT 'N' NOT NULL ENABLE,
	"DESCRIPTION" VARCHAR2(500) COLLATE "USING_NLS_COMP",
	 CONSTRAINT "XXX_FV_COLUMNS_CK1" CHECK (data_type in ('VARCHAR2', 'NUMBER', 'DATE')) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_CK2" CHECK (date_format in ('YYYY-MM-DD', 'YYYY/MM/DD', 'DD-MON-YYYY')) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_CK3" CHECK (data_type <> 'DATE' or date_format is not null) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_CK4" CHECK (is_required in ('Y', 'N')) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_CK5" CHECK (is_sensitive in ('Y', 'N')) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_CK6" CHECK (regexp_like(column_name, '^[A-Z][A-Z0-9_]*$')) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_PK" PRIMARY KEY ("OBJECT_CODE", "COLUMN_NAME")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_COLUMNS_FK1" FOREIGN KEY ("OBJECT_CODE")
	  REFERENCES "XXX_FV_OBJECTS" ("OBJECT_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_COLUMN_ALIASES"
   (	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"ALIAS_NORM" VARCHAR2(100) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"COLUMN_NAME" VARCHAR2(60) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_COLUMN_ALIASES_CK1" CHECK (regexp_like(alias_norm, '^[A-Z0-9_]+$')) ENABLE,
	 CONSTRAINT "XXX_FV_COLUMN_ALIASES_PK" PRIMARY KEY ("OBJECT_CODE", "ALIAS_NORM")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_COLUMN_ALIASES_FK1" FOREIGN KEY ("OBJECT_CODE", "COLUMN_NAME")
	  REFERENCES "XXX_FV_COLUMNS" ("OBJECT_CODE", "COLUMN_NAME") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_COLUMN_VALUES"
   (	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"COLUMN_NAME" VARCHAR2(60) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"ALLOWED_VALUE" VARCHAR2(200) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"MEANING" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	 CONSTRAINT "XXX_FV_COLUMN_VALUES_PK" PRIMARY KEY ("OBJECT_CODE", "COLUMN_NAME", "ALLOWED_VALUE")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_COLUMN_VALUES_FK1" FOREIGN KEY ("OBJECT_CODE", "COLUMN_NAME")
	  REFERENCES "XXX_FV_COLUMNS" ("OBJECT_CODE", "COLUMN_NAME") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_DOCUMENTS"
   (	"DOCUMENT_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"BATCH_ID" NUMBER NOT NULL ENABLE,
	"FILE_NAME" VARCHAR2(400) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"MIME_TYPE" VARCHAR2(255) COLLATE "USING_NLS_COMP",
	"FILE_CONTENT" BLOB NOT NULL ENABLE,
	"UPLOADED_BY" VARCHAR2(255) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"UPLOADED_ON" DATE DEFAULT sysdate NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_DOCUMENTS_PK" PRIMARY KEY ("DOCUMENT_ID")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_DOCUMENTS_FK1" FOREIGN KEY ("BATCH_ID")
	  REFERENCES "XXX_FV_BATCHES" ("BATCH_ID") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_ERROR_LOG"
   (	"LOG_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"LOG_TS" TIMESTAMP (6) DEFAULT systimestamp NOT NULL ENABLE,
	"MODULE" VARCHAR2(200) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"LOG_KEY" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"ERR_STACK" VARCHAR2(4000) COLLATE "USING_NLS_COMP",
	"BACKTRACE" VARCHAR2(4000) COLLATE "USING_NLS_COMP",
	"CALL_STACK" VARCHAR2(4000) COLLATE "USING_NLS_COMP",
	"DB_USER" VARCHAR2(128) COLLATE "USING_NLS_COMP" DEFAULT user NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_ERROR_LOG_PK" PRIMARY KEY ("LOG_ID")
  USING INDEX  ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_FILES"
   (	"FILE_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"BATCH_ID" NUMBER NOT NULL ENABLE,
	"DOCUMENT_ID" NUMBER NOT NULL ENABLE,
	"SHEET_DISPLAY_NAME" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"SHEET_FILE_NAME" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP",
	"ROW_COUNT" NUMBER,
	"STAGED_ON" DATE,
	"IS_IGNORED" VARCHAR2(1) COLLATE "USING_NLS_COMP" DEFAULT 'N' NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_FILES_PK" PRIMARY KEY ("FILE_ID")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_FILES_CK1" CHECK (is_ignored in ('Y', 'N')) ENABLE,
	 CONSTRAINT "XXX_FV_FILES_FK1" FOREIGN KEY ("BATCH_ID")
	  REFERENCES "XXX_FV_BATCHES" ("BATCH_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "XXX_FV_FILES_FK2" FOREIGN KEY ("DOCUMENT_ID")
	  REFERENCES "XXX_FV_DOCUMENTS" ("DOCUMENT_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "XXX_FV_FILES_FK3" FOREIGN KEY ("OBJECT_CODE")
	  REFERENCES "XXX_FV_OBJECTS" ("OBJECT_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_FILE_COLUMNS"
   (	"FILE_ID" NUMBER NOT NULL ENABLE,
	"COLUMN_POSITION" NUMBER(3,0) NOT NULL ENABLE,
	"FILE_HEADER" VARCHAR2(400) COLLATE "USING_NLS_COMP",
	"HEADER_NORM" VARCHAR2(400) COLLATE "USING_NLS_COMP",
	"SAMPLE_SHAPE" VARCHAR2(400) COLLATE "USING_NLS_COMP",
	"MAPPED_COLUMN" VARCHAR2(60) COLLATE "USING_NLS_COMP",
	"MAPPING_SOURCE" VARCHAR2(10) COLLATE "USING_NLS_COMP",
	"AI_CONFIDENCE" NUMBER(3,2),
	"AI_REASON" VARCHAR2(400) COLLATE "USING_NLS_COMP",
	 CONSTRAINT "XXX_FV_FILE_COLUMNS_CK1" CHECK (mapping_source in ('AUTO', 'AI', 'USER')) ENABLE,
	 CONSTRAINT "XXX_FV_FILE_COLUMNS_CK2" CHECK (ai_confidence between 0 and 1) ENABLE,
	 CONSTRAINT "XXX_FV_FILE_COLUMNS_PK" PRIMARY KEY ("FILE_ID", "COLUMN_POSITION")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_FILE_COLUMNS_FK1" FOREIGN KEY ("FILE_ID")
	  REFERENCES "XXX_FV_FILES" ("FILE_ID") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_ISSUES"
   (	"ISSUE_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"BATCH_ID" NUMBER NOT NULL ENABLE,
	"FILE_ID" NUMBER,
	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP",
	"LINE_NUMBER" NUMBER,
	"COLUMN_NAME" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"RULE_CODE" VARCHAR2(40) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"SEVERITY" VARCHAR2(10) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"MESSAGE" VARCHAR2(1000) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"BAD_VALUE" VARCHAR2(400) COLLATE "USING_NLS_COMP",
	"CREATED_ON" DATE DEFAULT sysdate NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_ISSUES_CK1" CHECK (severity in ('ERROR', 'WARNING', 'INFO')) ENABLE,
	 CONSTRAINT "XXX_FV_ISSUES_PK" PRIMARY KEY ("ISSUE_ID")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_ISSUES_FK1" FOREIGN KEY ("BATCH_ID")
	  REFERENCES "XXX_FV_BATCHES" ("BATCH_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "XXX_FV_ISSUES_FK2" FOREIGN KEY ("FILE_ID")
	  REFERENCES "XXX_FV_FILES" ("FILE_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "XXX_FV_ISSUES_FK3" FOREIGN KEY ("RULE_CODE")
	  REFERENCES "XXX_FV_RULES" ("RULE_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_OBJECTS"
   (	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"MODULE_CODE" VARCHAR2(10) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"OBJECT_NAME" VARCHAR2(100) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"SHEET_ALIAS" VARCHAR2(60) COLLATE "USING_NLS_COMP",
	"FUSION_TARGET" VARCHAR2(200) COLLATE "USING_NLS_COMP",
	"LOAD_ORDER" NUMBER(3,0) NOT NULL ENABLE,
	"DESCRIPTION" VARCHAR2(1000) COLLATE "USING_NLS_COMP",
	"IS_ENABLED" VARCHAR2(1) COLLATE "USING_NLS_COMP" DEFAULT 'Y' NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_OBJECTS_CK1" CHECK (is_enabled in ('Y', 'N')) ENABLE,
	 CONSTRAINT "XXX_FV_OBJECTS_CK2" CHECK (module_code in ('GL', 'AP', 'AR', 'CE', 'PO', 'PR', 'FA', 'INV')) ENABLE,
	 CONSTRAINT "XXX_FV_OBJECTS_CK3" CHECK (regexp_like(object_code, '^[A-Z][A-Z0-9_]*$')) ENABLE,
	 CONSTRAINT "XXX_FV_OBJECTS_PK" PRIMARY KEY ("OBJECT_CODE")
  USING INDEX  ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_RECON_RESULTS"
   (	"RECON_ID" NUMBER GENERATED ALWAYS AS IDENTITY MINVALUE 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER  NOCYCLE  NOKEEP  NOSCALE  NOT NULL ENABLE,
	"BATCH_ID" NUMBER NOT NULL ENABLE,
	"RULE_CODE" VARCHAR2(40) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"RECON_LABEL" VARCHAR2(200) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"CURRENCY_CODE" VARCHAR2(15) COLLATE "USING_NLS_COMP",
	"SOURCE_TOTAL" NUMBER,
	"TARGET_TOTAL" NUMBER,
	"DIFFERENCE" NUMBER,
	"STATUS_CODE" VARCHAR2(10) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"CREATED_ON" DATE DEFAULT sysdate NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_RECON_RESULTS_CK1" CHECK (status_code in ('MATCHED', 'DIFF')) ENABLE,
	 CONSTRAINT "XXX_FV_RECON_RESULTS_PK" PRIMARY KEY ("RECON_ID")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_RECON_RESULTS_FK1" FOREIGN KEY ("BATCH_ID")
	  REFERENCES "XXX_FV_BATCHES" ("BATCH_ID") ON DELETE CASCADE ENABLE,
	 CONSTRAINT "XXX_FV_RECON_RESULTS_FK2" FOREIGN KEY ("RULE_CODE")
	  REFERENCES "XXX_FV_RULES" ("RULE_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_RULES"
   (	"RULE_CODE" VARCHAR2(40) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"RULE_TYPE" VARCHAR2(10) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"OBJECT_CODE" VARCHAR2(30) COLLATE "USING_NLS_COMP",
	"SEVERITY" VARCHAR2(10) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"TITLE" VARCHAR2(200) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"FIX_HINT" VARCHAR2(1000) COLLATE "USING_NLS_COMP",
	"RULE_SQL" CLOB COLLATE "USING_NLS_COMP",
	"TOLERANCE" NUMBER DEFAULT 0 NOT NULL ENABLE,
	"RUN_ORDER" NUMBER(4,0) DEFAULT 100 NOT NULL ENABLE,
	"IS_ENABLED" VARCHAR2(1) COLLATE "USING_NLS_COMP" DEFAULT 'Y' NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_RULES_CK1" CHECK (rule_type in ('COLUMN', 'ROW_SQL', 'RECON')) ENABLE,
	 CONSTRAINT "XXX_FV_RULES_CK2" CHECK (severity in ('ERROR', 'WARNING', 'INFO')) ENABLE,
	 CONSTRAINT "XXX_FV_RULES_CK3" CHECK (rule_type = 'COLUMN' or rule_sql is not null) ENABLE,
	 CONSTRAINT "XXX_FV_RULES_CK4" CHECK (is_enabled in ('Y', 'N')) ENABLE,
	 CONSTRAINT "XXX_FV_RULES_CK5" CHECK (tolerance >= 0) ENABLE,
	 CONSTRAINT "XXX_FV_RULES_PK" PRIMARY KEY ("RULE_CODE")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_RULES_FK1" FOREIGN KEY ("OBJECT_CODE")
	  REFERENCES "XXX_FV_OBJECTS" ("OBJECT_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_STAGE_LINES"
   (	"FILE_ID" NUMBER NOT NULL ENABLE,
	"LINE_NUMBER" NUMBER NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_STAGE_LINES_PK" PRIMARY KEY ("FILE_ID", "LINE_NUMBER")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_STAGE_LINES_FK1" FOREIGN KEY ("FILE_ID")
	  REFERENCES "XXX_FV_FILES" ("FILE_ID") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_STAGE_VALUES"
   (	"FILE_ID" NUMBER NOT NULL ENABLE,
	"LINE_NUMBER" NUMBER NOT NULL ENABLE,
	"COLUMN_NAME" VARCHAR2(60) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"CELL_VALUE" VARCHAR2(4000) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_STAGE_VALUES_PK" PRIMARY KEY ("FILE_ID", "LINE_NUMBER", "COLUMN_NAME")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_STAGE_VALUES_FK1" FOREIGN KEY ("FILE_ID")
	  REFERENCES "XXX_FV_FILES" ("FILE_ID") ON DELETE CASCADE ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE TABLE "XXX_FV_STATUS_TRANSITIONS"
   (	"FROM_STATUS" VARCHAR2(20) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	"TO_STATUS" VARCHAR2(20) COLLATE "USING_NLS_COMP" NOT NULL ENABLE,
	 CONSTRAINT "XXX_FV_STATUS_TRANSITIONS_PK" PRIMARY KEY ("FROM_STATUS", "TO_STATUS")
  USING INDEX  ENABLE,
	 CONSTRAINT "XXX_FV_STATUS_TRANSITIONS_FK1" FOREIGN KEY ("FROM_STATUS")
	  REFERENCES "XXX_FV_BATCH_STATUSES" ("STATUS_CODE") ENABLE,
	 CONSTRAINT "XXX_FV_STATUS_TRANSITIONS_FK2" FOREIGN KEY ("TO_STATUS")
	  REFERENCES "XXX_FV_BATCH_STATUSES" ("STATUS_CODE") ENABLE
   )  DEFAULT COLLATION "USING_NLS_COMP" ;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_AP_INVOICES_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "INVOICE_NUMBER", "SUPPLIER_NUMBER", "BUSINESS_UNIT", "INVOICE_TYPE", "INVOICE_DATE", "INVOICE_CURRENCY", "INVOICE_AMOUNT", "AMOUNT_REMAINING", "DUE_DATE", "LIABILITY_ACCOUNT", "DESCRIPTION") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'INVOICE_NUMBER' then v.cell_value end) as invoice_number,
       max(case when v.column_name = 'SUPPLIER_NUMBER' then v.cell_value end) as supplier_number,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'INVOICE_TYPE' then v.cell_value end) as invoice_type,
       to_date(max(case when v.column_name = 'INVOICE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as invoice_date,
       max(case when v.column_name = 'INVOICE_CURRENCY' then v.cell_value end) as invoice_currency,
       to_number(max(case when v.column_name = 'INVOICE_AMOUNT' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as invoice_amount,
       to_number(max(case when v.column_name = 'AMOUNT_REMAINING' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as amount_remaining,
       to_date(max(case when v.column_name = 'DUE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as due_date,
       max(case when v.column_name = 'LIABILITY_ACCOUNT' then v.cell_value end) as liability_account,
       max(case when v.column_name = 'DESCRIPTION' then v.cell_value end) as description
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AP_INVOICES'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_AP_SUPPLIERS_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "SUPPLIER_NUMBER", "SUPPLIER_NAME", "ALTERNATE_NAME", "SUPPLIER_TYPE", "TAX_REGISTRATION_NUMBER", "COUNTRY", "BUSINESS_UNIT", "SITE_NAME", "PAYMENT_TERMS", "INVOICE_CURRENCY", "BANK_IBAN", "EMAIL") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'SUPPLIER_NUMBER' then v.cell_value end) as supplier_number,
       max(case when v.column_name = 'SUPPLIER_NAME' then v.cell_value end) as supplier_name,
       max(case when v.column_name = 'ALTERNATE_NAME' then v.cell_value end) as alternate_name,
       max(case when v.column_name = 'SUPPLIER_TYPE' then v.cell_value end) as supplier_type,
       max(case when v.column_name = 'TAX_REGISTRATION_NUMBER' then v.cell_value end) as tax_registration_number,
       max(case when v.column_name = 'COUNTRY' then v.cell_value end) as country,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'SITE_NAME' then v.cell_value end) as site_name,
       max(case when v.column_name = 'PAYMENT_TERMS' then v.cell_value end) as payment_terms,
       max(case when v.column_name = 'INVOICE_CURRENCY' then v.cell_value end) as invoice_currency,
       max(case when v.column_name = 'BANK_IBAN' then v.cell_value end) as bank_iban,
       max(case when v.column_name = 'EMAIL' then v.cell_value end) as email
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AP_SUPPLIERS'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_AR_CUSTOMERS_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "CUSTOMER_NUMBER", "CUSTOMER_NAME", "ACCOUNT_TYPE", "TAX_REGISTRATION_NUMBER", "COUNTRY", "BUSINESS_UNIT", "BILL_TO_SITE", "PAYMENT_TERMS", "CREDIT_LIMIT", "CURRENCY") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'CUSTOMER_NUMBER' then v.cell_value end) as customer_number,
       max(case when v.column_name = 'CUSTOMER_NAME' then v.cell_value end) as customer_name,
       max(case when v.column_name = 'ACCOUNT_TYPE' then v.cell_value end) as account_type,
       max(case when v.column_name = 'TAX_REGISTRATION_NUMBER' then v.cell_value end) as tax_registration_number,
       max(case when v.column_name = 'COUNTRY' then v.cell_value end) as country,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'BILL_TO_SITE' then v.cell_value end) as bill_to_site,
       max(case when v.column_name = 'PAYMENT_TERMS' then v.cell_value end) as payment_terms,
       to_number(max(case when v.column_name = 'CREDIT_LIMIT' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as credit_limit,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AR_CUSTOMERS'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_AR_INVOICES_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "TRANSACTION_NUMBER", "CUSTOMER_NUMBER", "TRANSACTION_TYPE", "TRANSACTION_DATE", "DUE_DATE", "CURRENCY", "ORIGINAL_AMOUNT", "AMOUNT_DUE", "RECEIVABLE_ACCOUNT") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'TRANSACTION_NUMBER' then v.cell_value end) as transaction_number,
       max(case when v.column_name = 'CUSTOMER_NUMBER' then v.cell_value end) as customer_number,
       max(case when v.column_name = 'TRANSACTION_TYPE' then v.cell_value end) as transaction_type,
       to_date(max(case when v.column_name = 'TRANSACTION_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as transaction_date,
       to_date(max(case when v.column_name = 'DUE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as due_date,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_number(max(case when v.column_name = 'ORIGINAL_AMOUNT' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as original_amount,
       to_number(max(case when v.column_name = 'AMOUNT_DUE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as amount_due,
       max(case when v.column_name = 'RECEIVABLE_ACCOUNT' then v.cell_value end) as receivable_account
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'AR_INVOICES'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_CE_BANK_ACCOUNTS_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "BANK_NAME", "BRANCH_NAME", "ACCOUNT_NAME", "ACCOUNT_NUMBER", "IBAN", "CURRENCY", "GL_CASH_ACCOUNT", "OPENING_BALANCE", "BALANCE_DATE") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'BANK_NAME' then v.cell_value end) as bank_name,
       max(case when v.column_name = 'BRANCH_NAME' then v.cell_value end) as branch_name,
       max(case when v.column_name = 'ACCOUNT_NAME' then v.cell_value end) as account_name,
       max(case when v.column_name = 'ACCOUNT_NUMBER' then v.cell_value end) as account_number,
       max(case when v.column_name = 'IBAN' then v.cell_value end) as iban,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       max(case when v.column_name = 'GL_CASH_ACCOUNT' then v.cell_value end) as gl_cash_account,
       to_number(max(case when v.column_name = 'OPENING_BALANCE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as opening_balance,
       to_date(max(case when v.column_name = 'BALANCE_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as balance_date
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'CE_BANK_ACCOUNTS'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_GL_BALANCES_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "LEDGER_NAME", "PERIOD_NAME", "ACCOUNT_COMBINATION", "CURRENCY", "ENTERED_DR", "ENTERED_CR", "DESCRIPTION") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'LEDGER_NAME' then v.cell_value end) as ledger_name,
       max(case when v.column_name = 'PERIOD_NAME' then v.cell_value end) as period_name,
       max(case when v.column_name = 'ACCOUNT_COMBINATION' then v.cell_value end) as account_combination,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_number(max(case when v.column_name = 'ENTERED_DR' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as entered_dr,
       to_number(max(case when v.column_name = 'ENTERED_CR' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as entered_cr,
       max(case when v.column_name = 'DESCRIPTION' then v.cell_value end) as description
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'GL_BALANCES'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_PO_ORDERS_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "PO_NUMBER", "PO_LINE_NUMBER", "SUPPLIER_NUMBER", "BUSINESS_UNIT", "BUYER_EMAIL", "ITEM_DESCRIPTION", "CATEGORY", "QUANTITY", "QUANTITY_RECEIVED", "UNIT_PRICE", "CURRENCY", "NEED_BY_DATE") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'PO_NUMBER' then v.cell_value end) as po_number,
       to_number(max(case when v.column_name = 'LINE_NUMBER' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as po_line_number,
       max(case when v.column_name = 'SUPPLIER_NUMBER' then v.cell_value end) as supplier_number,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'BUYER_EMAIL' then v.cell_value end) as buyer_email,
       max(case when v.column_name = 'ITEM_DESCRIPTION' then v.cell_value end) as item_description,
       max(case when v.column_name = 'CATEGORY' then v.cell_value end) as category,
       to_number(max(case when v.column_name = 'QUANTITY' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as quantity,
       to_number(max(case when v.column_name = 'QUANTITY_RECEIVED' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as quantity_received,
       to_number(max(case when v.column_name = 'UNIT_PRICE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as unit_price,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_date(max(case when v.column_name = 'NEED_BY_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as need_by_date
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'PO_ORDERS'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE FORCE EDITIONABLE VIEW "XXX_FV_PR_REQUISITIONS_V" ("BATCH_ID", "FILE_ID", "LINE_NUMBER", "REQUISITION_NUMBER", "REQ_LINE_NUMBER", "REQUESTER_EMAIL", "BUSINESS_UNIT", "ITEM_DESCRIPTION", "CATEGORY", "QUANTITY", "UNIT_PRICE", "CURRENCY", "NEED_BY_DATE", "APPROVAL_STATUS") DEFAULT COLLATION "USING_NLS_COMP"  AS
  select f.batch_id,
       l.file_id,
       l.line_number,
       max(case when v.column_name = 'REQUISITION_NUMBER' then v.cell_value end) as requisition_number,
       to_number(max(case when v.column_name = 'LINE_NUMBER' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as req_line_number,
       max(case when v.column_name = 'REQUESTER_EMAIL' then v.cell_value end) as requester_email,
       max(case when v.column_name = 'BUSINESS_UNIT' then v.cell_value end) as business_unit,
       max(case when v.column_name = 'ITEM_DESCRIPTION' then v.cell_value end) as item_description,
       max(case when v.column_name = 'CATEGORY' then v.cell_value end) as category,
       to_number(max(case when v.column_name = 'QUANTITY' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as quantity,
       to_number(max(case when v.column_name = 'UNIT_PRICE' and regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$') then v.cell_value end) default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') as unit_price,
       max(case when v.column_name = 'CURRENCY' then v.cell_value end) as currency,
       to_date(max(case when v.column_name = 'NEED_BY_DATE' then v.cell_value end) default null on conversion error, 'YYYY-MM-DD') as need_by_date,
       max(case when v.column_name = 'APPROVAL_STATUS' then v.cell_value end) as approval_status
  from xxx_fv_files f
  join xxx_fv_stage_lines l
    on l.file_id = f.file_id
  left join xxx_fv_stage_values v
    on v.file_id = l.file_id
   and v.line_number = l.line_number
 where f.object_code = 'PR_REQUISITIONS'
 group by f.batch_id, l.file_id, l.line_number;


  CREATE OR REPLACE EDITIONABLE PACKAGE "XXX_FV_AI_PKG" authid definer as

    -- JSON facts about a validated batch. Also used by the "Ask Claude" agent.
    function get_batch_context (p_batch_id in xxx_fv_batches.batch_id%type) return clob;

    -- JSON facts for mapping one file's unmapped headers.
    function get_mapping_context (p_file_id in xxx_fv_files.file_id%type) return clob;

    -- Status-code APIs (accepted exception to CON-30): on failure they roll back to
    -- their savepoint, log the error, keep a FAILED report row, and return 'E'.
    procedure generate_batch_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2);

    -- x_mapped_count = headers Claude mapped; x_message explains the result
    -- (and flags a likely wrong object when nothing could be mapped).
    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_mapped_count   out number,
        x_return_status  out varchar2,
        x_message        out varchar2);

    -- "Ask Claude" chat: answers one question from the batch facts, with the user's
    -- last turns on this batch as history. Each turn is saved as a CHAT row.
    procedure ask_batch (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_question       in  varchar2,
        p_user           in  varchar2,
        x_answer         out clob,
        x_return_status  out varchar2,
        x_message        out varchar2);

end xxx_fv_ai_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE "XXX_FV_BATCH_API" authid definer as

    procedure create_batch (
        p_batch_name    in  xxx_fv_batches.batch_name%type,
        p_client_name   in  xxx_fv_batches.client_name%type,
        p_target_env    in  xxx_fv_batches.target_env%type,
        p_cutover_date  in  xxx_fv_batches.cutover_date%type,
        p_user          in  varchar2,
        x_batch_id      out xxx_fv_batches.batch_id%type);

    -- Lost-update safe header edit (CON-10): fails if p_row_version is stale.
    procedure update_batch_header (
        p_batch_id      in xxx_fv_batches.batch_id%type,
        p_row_version   in xxx_fv_batches.row_version%type,
        p_batch_name    in xxx_fv_batches.batch_name%type,
        p_client_name   in xxx_fv_batches.client_name%type,
        p_target_env    in xxx_fv_batches.target_env%type,
        p_cutover_date  in xxx_fv_batches.cutover_date%type,
        p_user          in varchar2);

    procedure add_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type);

    -- APEX convenience: p_temp_file_names is the colon-separated value of a
    -- File Browse item stored in APEX_APPLICATION_TEMP_FILES.
    procedure add_uploaded_files (
        p_batch_id         in xxx_fv_batches.batch_id%type,
        p_temp_file_names  in varchar2,
        p_user             in varchar2);

    procedure remove_document (
        p_document_id  in xxx_fv_documents.document_id%type,
        p_user         in varchar2);

    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type,
        p_user         in varchar2);

    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type,
        p_user             in varchar2);

    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2);

    -- Stages every file and runs all rules; replaces previous results (idempotent).
    procedure validate_batch (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_user      in varchar2);

    procedure generate_ai_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2);

    -- Ignore (p_ignored = 'Y') or include again ('N') a sheet; no-op when unchanged.
    procedure ignore_file (
        p_file_id  in xxx_fv_files.file_id%type,
        p_ignored  in xxx_fv_files.is_ignored%type,
        p_user     in varchar2);

    -- Ask Claude chat turn (no status change).
    procedure ask_claude (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_question       in  varchar2,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2);

end xxx_fv_batch_api;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE "XXX_FV_CONST_PKG" authid definer as
    -- batch statuses (rows in xxx_fv_batch_statuses, moves in xxx_fv_status_transitions)
    c_status_new           constant varchar2(20) := 'NEW';
    c_status_files_loaded  constant varchar2(20) := 'FILES_LOADED';
    c_status_validated     constant varchar2(20) := 'VALIDATED';
    c_status_reported      constant varchar2(20) := 'REPORTED';

    -- severities
    c_sev_error            constant varchar2(10) := 'ERROR';
    c_sev_warning          constant varchar2(10) := 'WARNING';
    c_sev_info             constant varchar2(10) := 'INFO';

    -- rule types
    c_rule_type_column     constant varchar2(10) := 'COLUMN';
    c_rule_type_row_sql    constant varchar2(10) := 'ROW_SQL';
    c_rule_type_recon      constant varchar2(10) := 'RECON';

    -- built-in rule codes (rows in xxx_fv_rules, rule_type = COLUMN)
    c_rule_unknown_object  constant varchar2(40) := 'FILE_UNKNOWN_OBJECT';
    c_rule_missing_column  constant varchar2(40) := 'FILE_MISSING_COLUMN';
    c_rule_unmapped_column constant varchar2(40) := 'FILE_UNMAPPED_COLUMN';
    c_rule_empty_file      constant varchar2(40) := 'FILE_EMPTY';
    c_rule_object_missing  constant varchar2(40) := 'BATCH_OBJECT_MISSING';
    c_rule_required        constant varchar2(40) := 'COL_REQUIRED';
    c_rule_number          constant varchar2(40) := 'COL_NUMBER';
    c_rule_date            constant varchar2(40) := 'COL_DATE';
    c_rule_max_length      constant varchar2(40) := 'COL_MAX_LENGTH';
    c_rule_pattern         constant varchar2(40) := 'COL_PATTERN';
    c_rule_allowed_value   constant varchar2(40) := 'COL_ALLOWED_VALUE';
    c_rule_duplicate_key   constant varchar2(40) := 'COL_DUPLICATE_KEY';

    -- recon result status
    c_recon_matched        constant varchar2(10) := 'MATCHED';
    c_recon_diff           constant varchar2(10) := 'DIFF';

    -- readiness
    c_ready                constant varchar2(30) := 'READY';
    c_ready_with_warnings  constant varchar2(30) := 'READY_WITH_WARNINGS';
    c_not_ready            constant varchar2(30) := 'NOT_READY';

    -- column mapping sources
    c_map_auto             constant varchar2(10) := 'AUTO';
    c_map_ai               constant varchar2(10) := 'AI';
    c_map_user             constant varchar2(10) := 'USER';

    -- AI
    c_ai_service_static_id constant varchar2(255) := 'CLAUDE';   -- Workspace Utilities > Generative AI Services
    c_report_batch         constant varchar2(20)  := 'BATCH_REPORT';
    c_report_mapping       constant varchar2(20)  := 'MAPPING';
    c_report_chat          constant varchar2(20)  := 'CHAT';
    c_ai_completed         constant varchar2(20)  := 'COMPLETED';
    c_ai_failed            constant varchar2(20)  := 'FAILED';
    c_lang_en              constant varchar2(2)   := 'EN';
    c_lang_ar              constant varchar2(2)   := 'AR';

    -- parsing
    c_max_file_columns     constant pls_integer   := 60;     -- columns read per sheet/CSV

    -- error codes (CC-05): one registry
    c_err_invalid_transition constant pls_integer := -20101;
    c_err_batch_not_found    constant pls_integer := -20102;
    c_err_unsafe_rule_sql    constant pls_integer := -20103;
    c_err_rule_sql_columns   constant pls_integer := -20104;
    c_err_ai_response        constant pls_integer := -20105;
    c_err_file_not_found     constant pls_integer := -20106;
    c_err_bad_parameter      constant pls_integer := -20107;

    e_invalid_transition exception;
    pragma exception_init (e_invalid_transition, -20101);
    e_batch_not_found exception;
    pragma exception_init (e_batch_not_found, -20102);
    e_unsafe_rule_sql exception;
    pragma exception_init (e_unsafe_rule_sql, -20103);
    e_rule_sql_columns exception;
    pragma exception_init (e_rule_sql_columns, -20104);
    e_ai_response exception;
    pragma exception_init (e_ai_response, -20105);
    e_file_not_found exception;
    pragma exception_init (e_file_not_found, -20106);
    e_bad_parameter exception;
    pragma exception_init (e_bad_parameter, -20107);
end xxx_fv_const_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE "XXX_FV_FILE_ADAPTER_PKG" authid definer as

    -- Normalises a header / sheet / file name to UPPER_SNAKE (used in SQL, hence public).
    function normalize_name (p_text in varchar2) return varchar2 deterministic;

    -- Stores the document, creates one file row per XLSX sheet (or one for a CSV),
    -- detects the object from the sheet/file name, captures headers and auto-maps them.
    procedure register_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type);

    -- Re-points a file to another object and redoes the automatic mapping.
    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type);

    -- Sets (or clears, when p_column_name is null) the target column for one header.
    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type);

    -- Re-reads the file and replaces its staging rows (idempotent).
    procedure stage_file (p_file_id in xxx_fv_files.file_id%type);

    -- Ignore a sheet that is not migration data (notes, cover pages): clears its object,
    -- mapping and staging so no check sees it. p_ignored = 'N' includes it again and
    -- re-runs object detection and auto-mapping.
    procedure set_ignored (
        p_file_id  in xxx_fv_files.file_id%type,
        p_ignored  in xxx_fv_files.is_ignored%type);

    -- Object whose columns/aliases best match the file's headers, or null when there is
    -- no clear winner. Used for detection on upload and to flag a likely wrong object.
    function suggest_object (p_file_id in xxx_fv_files.file_id%type) return varchar2;

end xxx_fv_file_adapter_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE "XXX_FV_LOG_PKG" authid definer as
    -- Records the current error with full stacks. Caller must RAISE afterwards (CON-30).
    procedure error (p_module in varchar2, p_key in varchar2 default null);
end xxx_fv_log_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE "XXX_FV_RULES_PKG" authid definer as

    type t_readiness is record (
        line_count      number,
        error_count     number,
        warning_count   number,
        info_count      number,
        readiness_score number,
        readiness_status varchar2(30));

    -- Deletes previous results for the batch and runs every enabled rule. Idempotent.
    procedure run_all (p_batch_id in xxx_fv_batches.batch_id%type);

    -- Score and status from the current results (deterministic; the AI only explains it).
    function get_readiness (p_batch_id in xxx_fv_batches.batch_id%type) return t_readiness;

    -- Admin "Test rule": raises if the rule SQL is unsafe, does not parse, or lacks the
    -- columns its rule type needs.
    procedure check_rule_sql (p_rule_code in xxx_fv_rules.rule_code%type);

end xxx_fv_rules_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "XXX_FV_AI_PKG" as

    -- -------------------------------------------------------------------------
    c_report_schema constant varchar2(8000) := q'~{
  "type": "object",
  "properties": {
    "executive_summary": { "type": "string" },
    "readiness_explanation": { "type": "string" },
    "modules": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "module": { "type": "string" },
          "object_code": { "type": "string" },
          "status": { "type": "string", "enum": ["OK", "WARNING", "BLOCKED", "NOT_PROVIDED"] },
          "summary": { "type": "string" },
          "key_findings": { "type": "array", "items": { "type": "string" } },
          "actions": { "type": "array", "items": { "type": "string" } }
        },
        "required": ["module", "object_code", "status", "summary", "key_findings", "actions"],
        "additionalProperties": false
      }
    },
    "insights": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "title": { "type": "string" },
          "detail": { "type": "string" },
          "evidence": { "type": "string" },
          "impact": { "type": "string", "enum": ["HIGH", "MEDIUM", "LOW"] }
        },
        "required": ["title", "detail", "evidence", "impact"],
        "additionalProperties": false
      }
    },
    "reconciliation_comments": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "reconciliation": { "type": "string" },
          "comment": { "type": "string" }
        },
        "required": ["reconciliation", "comment"],
        "additionalProperties": false
      }
    },
    "top_risks": { "type": "array", "items": { "type": "string" } },
    "next_steps": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "step": { "type": "string" },
          "owner": { "type": "string", "enum": ["CLIENT", "CONSULTANT", "BOTH"] }
        },
        "required": ["step", "owner"],
        "additionalProperties": false
      }
    }
  },
  "required": ["executive_summary", "readiness_explanation", "modules", "insights",
               "reconciliation_comments", "top_risks", "next_steps"],
  "additionalProperties": false
}~';

    c_mapping_schema constant varchar2(4000) := q'~{
  "type": "object",
  "properties": {
    "mappings": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "column_position": { "type": "integer" },
          "target_column": { "type": "string" },
          "confidence": { "type": "number" },
          "reason": { "type": "string" }
        },
        "required": ["column_position", "target_column", "confidence", "reason"],
        "additionalProperties": false
      }
    }
  },
  "required": ["mappings"],
  "additionalProperties": false
}~';

    -- -------------------------------------------------------------------------
    function report_system_prompt (p_language in varchar2) return clob is
    begin
        return
'You are a senior Oracle Fusion Cloud ERP data-migration consultant. You review the result of a
pre-load validation run (master data and opening balances for GL, AP, AR, Cash Management,
Purchasing and Requisitions) and write the report a project manager and the client finance team read
before FBDI loads start.

Rules:
1. Use only the facts in the JSON context. Never invent records, counts, amounts or rule results.
2. Quote counts and amounts exactly as given. Do not recalculate totals.
3. readiness_score and readiness_status are computed by the system. Explain them; never change them.
4. ERROR blocks the load, WARNING needs a decision, INFO is for awareness.
   Module status: BLOCKED if it has any ERROR, WARNING if only warnings, OK otherwise,
   NOT_PROVIDED when the object appears in missing_objects.
5. Actions must be concrete: name the column, the rule_code and what the client must change.
6. Insights are what an experienced consultant notices beyond single errors: patterns across
   rows (for example inconsistent casing, near-duplicate names), aging of open items, currency mix,
   concentration, reconciliation gaps, objects that look out of scope (fully received POs,
   unapproved requisitions), and data that is valid but suspicious. Each insight cites its evidence
   from the context.
7. Be concise. No marketing language. If the context has no data for a section, return an empty list.
8. ' || case p_language
            when xxx_fv_const_pkg.c_lang_ar then
                'Write every narrative field in Modern Standard Arabic, business register. Keep object codes, '
                || 'rule codes, column names, numbers, dates and currency codes exactly as given (Latin script).'
            else
                'Write in clear business English.'
          end;
    end report_system_prompt;

    -- -------------------------------------------------------------------------
    function mapping_system_prompt return clob is
    begin
        return
'You map spreadsheet headers to Oracle Fusion migration template columns.
For each unmapped header return the best target_column from target_columns, or "" when none fits.
Use the header text (it may be Arabic or abbreviated) and the sample_shape (digits are shown as 9).
Never map to a column listed in already_mapped. Never map two headers to the same target.
confidence is 0..1; use below 0.5 when unsure. reason is one short sentence in English.';
    end mapping_system_prompt;

    -- -------------------------------------------------------------------------
    -- Strips ``` fences and any text around the outermost {...}, then checks it is a JSON
    -- object. On failure the raw answer goes into the error text (saved on the report row).
    function clean_json (p_text in clob) return clob is
        l_text  clob := regexp_replace(p_text, '^\s*```(json)?\s*|\s*```\s*$', '');
        l_start integer;
        l_end   integer;
        l_obj   json_object_t;
    begin
        l_start := dbms_lob.instr(l_text, '{');
        l_end   := dbms_lob.instr(l_text, '}', -1);
        if l_start > 0 and l_end > l_start then
            l_text := dbms_lob.substr(l_text, l_end - l_start + 1, l_start);
        end if;
        l_obj := json_object_t.parse(l_text);
        return l_text;
    exception
        when others then
            raise_application_error(xxx_fv_const_pkg.c_err_ai_response,
                'The AI response is not valid JSON. Raw response: ' || dbms_lob.substr(p_text, 3000, 1));
    end clean_json;

    -- -------------------------------------------------------------------------
    function elapsed_ms (p_started in timestamp with time zone) return number is
        l_diff interval day(3) to second(3) := systimestamp - p_started;
    begin
        return round(extract(day from l_diff) * 86400000 + extract(hour from l_diff) * 3600000
                     + extract(minute from l_diff) * 60000 + extract(second from l_diff) * 1000);
    end elapsed_ms;

    -- -------------------------------------------------------------------------
    function call_ai (
        p_system_prompt in clob,
        p_prompt        in clob,
        p_schema        in clob) return clob
    is
    begin
        -- The schema goes into the instructions instead of p_response_json_schema: APEX_AI's
        -- strict validation (ORA-20959) rejected usable answers and hid the raw text. We parse
        -- leniently ourselves (clean_json + json_table). No p_temperature: current Claude
        -- models reject it (HTTP 400 "temperature is deprecated").
        return clean_json(
                   apex_ai.generate(
                       p_prompt            => p_prompt,
                       p_system_prompt     => p_system_prompt || chr(10) || chr(10)
                                              || 'Respond with exactly one JSON object and nothing else '
                                              || '(no markdown, no commentary). It must follow this JSON Schema:'
                                              || chr(10) || p_schema,
                       p_service_static_id => xxx_fv_const_pkg.c_ai_service_static_id));
    end call_ai;

    -- -------------------------------------------------------------------------
    procedure save_report (
        p_batch_id     in  number,
        p_file_id      in  number,
        p_report_type  in  varchar2,
        p_language     in  varchar2,
        p_status       in  varchar2,
        p_context      in  clob,
        p_response     in  clob,
        p_error        in  varchar2,
        p_elapsed_ms   in  number,
        p_user         in  varchar2,
        x_report_id    out number)
    is
    begin
        insert into xxx_fv_ai_reports (batch_id, file_id, report_type, language_code, status_code,
                                       service_static_id, context_json, response_json, error_message,
                                       elapsed_ms, requested_by)
        values (p_batch_id, p_file_id, p_report_type, p_language, p_status,
                xxx_fv_const_pkg.c_ai_service_static_id, p_context, p_response, substr(p_error, 1, 4000),
                p_elapsed_ms, p_user)
        returning report_id into x_report_id;
    end save_report;

    -- =========================================================================
    -- Context builders (queries only, CC-04)
    -- =========================================================================
    function get_batch_context (p_batch_id in xxx_fv_batches.batch_id%type) return clob is
        l_files    clob;
        l_missing  clob;
        l_profile  clob;
        l_issues   clob;
        l_recon    clob;
        l_json     clob;
    begin
        select json_arrayagg(
                   json_object(
                       'file'             value d.file_name,
                       'sheet'            value f.sheet_display_name,
                       'object_code'      value f.object_code,
                       'object_name'      value o.object_name,
                       'module'           value o.module_code,
                       'rows'             value f.row_count,
                       'unmapped_headers' value (select json_arrayagg(fc.file_header order by fc.column_position returning clob)
                                                   from xxx_fv_file_columns fc
                                                  where fc.file_id = f.file_id
                                                    and fc.mapped_column is null) format json
                       absent on null returning clob)
                   order by o.load_order, f.file_id returning clob)
          into l_files
          from xxx_fv_files f
          join xxx_fv_documents d
            on d.document_id = f.document_id
          left join xxx_fv_objects o
            on o.object_code = f.object_code
         where f.batch_id = p_batch_id
           and f.is_ignored = 'N';

        select json_arrayagg(
                   json_object('object_code' value o.object_code,
                               'object_name' value o.object_name,
                               'module'      value o.module_code returning clob)
                   order by o.load_order returning clob)
          into l_missing
          from xxx_fv_objects o
         where o.is_enabled = 'Y'
           and not exists (select 1
                             from xxx_fv_files f
                            where f.batch_id = p_batch_id
                              and f.object_code = o.object_code);

        with vals as (
            select f.object_code, v.column_name, v.cell_value, count(*) as cnt,
                   row_number() over (partition by f.object_code, v.column_name
                                      order by count(*) desc, v.cell_value) as rn,
                   count(*) over (partition by f.object_code, v.column_name) as distinct_cnt
              from xxx_fv_stage_values v
              join xxx_fv_files f
                on f.file_id = v.file_id
             where f.batch_id = p_batch_id
             group by f.object_code, v.column_name, v.cell_value),
        tops as (
            select vals.object_code, vals.column_name,
                   json_arrayagg(json_object('value' value vals.cell_value, 'count' value vals.cnt)
                                 order by vals.rn returning clob) as top_values
              from vals
              join xxx_fv_columns c
                on c.object_code = vals.object_code
               and c.column_name = vals.column_name
             where vals.rn <= 8
               and vals.distinct_cnt <= 15
               and c.is_sensitive = 'N'
             group by vals.object_code, vals.column_name),
        obj_rows as (
            select f.object_code, sum(nvl(f.row_count, 0)) as total_rows
              from xxx_fv_files f
             where f.batch_id = p_batch_id
               and f.object_code is not null
             group by f.object_code),
        prof as (
            select f.object_code, c.column_name, c.column_seq, c.data_type, c.is_sensitive,
                   count(v.cell_value) as filled,
                   count(distinct v.cell_value) as distinct_cnt,
                   sum(case when c.data_type = 'NUMBER'
                            then to_number(v.cell_value default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') end) as num_sum,
                   min(case when c.data_type = 'NUMBER'
                            then to_number(v.cell_value default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') end) as num_min,
                   max(case when c.data_type = 'NUMBER'
                            then to_number(v.cell_value default null on conversion error, '999999999999999999990D9999999999', 'NLS_NUMERIC_CHARACTERS=''.,''') end) as num_max,
                   min(case when c.data_type = 'DATE'
                            then to_date(v.cell_value default null on conversion error, 'YYYY-MM-DD') end) as date_min,
                   max(case when c.data_type = 'DATE'
                            then to_date(v.cell_value default null on conversion error, 'YYYY-MM-DD') end) as date_max
              from xxx_fv_files f
              join xxx_fv_columns c
                on c.object_code = f.object_code
              left join xxx_fv_stage_values v
                on v.file_id = f.file_id
               and v.column_name = c.column_name
             where f.batch_id = p_batch_id
             group by f.object_code, c.column_name, c.column_seq, c.data_type, c.is_sensitive)
        select json_arrayagg(
                   json_object(
                       'object_code' value p.object_code,
                       'column'      value p.column_name,
                       'type'        value p.data_type,
                       'rows'        value r.total_rows,
                       'filled'      value p.filled,
                       'fill_pct'    value round(100 * p.filled / nullif(r.total_rows, 0), 1),
                       'distinct'    value p.distinct_cnt,
                       'sum'         value case when p.is_sensitive = 'N' then p.num_sum end,
                       'min'         value case when p.is_sensitive = 'N'
                                                then coalesce(to_char(p.num_min), to_char(p.date_min, 'YYYY-MM-DD')) end,
                       'max'         value case when p.is_sensitive = 'N'
                                                then coalesce(to_char(p.num_max), to_char(p.date_max, 'YYYY-MM-DD')) end,
                       'top_values'  value t.top_values format json
                       absent on null returning clob)
                   order by p.object_code, p.column_seq returning clob)
          into l_profile
          from prof p
          join obj_rows r
            on r.object_code = p.object_code
          left join tops t
            on t.object_code = p.object_code
           and t.column_name = p.column_name;

        with grp as (
            select i.object_code, i.rule_code, i.severity, i.column_name, count(*) as cnt
              from xxx_fv_issues i
             where i.batch_id = p_batch_id
             group by i.object_code, i.rule_code, i.severity, i.column_name),
        ex as (
            select i.object_code, i.rule_code, i.column_name, i.line_number, i.bad_value, i.message,
                   row_number() over (partition by i.object_code, i.rule_code, i.column_name
                                      order by i.line_number, i.issue_id) as rn
              from xxx_fv_issues i
             where i.batch_id = p_batch_id),
        exa as (
            select ex.object_code, ex.rule_code, ex.column_name,
                   json_arrayagg(json_object('line'    value ex.line_number,
                                             'value'   value ex.bad_value,
                                             'message' value ex.message absent on null)
                                 order by ex.rn returning clob) as examples
              from ex
             where ex.rn <= 3
             group by ex.object_code, ex.rule_code, ex.column_name)
        select json_arrayagg(
                   json_object(
                       'object_code' value g.object_code,
                       'rule_code'   value g.rule_code,
                       'rule_title'  value r.title,
                       'severity'    value g.severity,
                       'column'      value g.column_name,
                       'count'       value g.cnt,
                       'fix_hint'    value r.fix_hint,
                       'examples'    value e.examples format json
                       absent on null returning clob)
                   order by decode(g.severity, 'ERROR', 1, 'WARNING', 2, 3), g.cnt desc, g.rule_code
                   returning clob)
          into l_issues
          from grp g
          join xxx_fv_rules r
            on r.rule_code = g.rule_code
          left join exa e
            on decode(e.object_code, g.object_code, 1, 0) = 1
           and e.rule_code = g.rule_code
           and decode(e.column_name, g.column_name, 1, 0) = 1;

        select json_arrayagg(
                   json_object('rule_code'     value rr.rule_code,
                               'title'         value ru.title,
                               'label'         value rr.recon_label,
                               'currency'      value rr.currency_code,
                               'source_total'  value rr.source_total,
                               'target_total'  value rr.target_total,
                               'difference'    value rr.difference,
                               'status'        value rr.status_code
                               absent on null returning clob)
                   order by ru.run_order, rr.recon_label returning clob)
          into l_recon
          from xxx_fv_recon_results rr
          join xxx_fv_rules ru
            on ru.rule_code = rr.rule_code
         where rr.batch_id = p_batch_id;

        select json_object(
                   'batch' value json_object(
                       'batch_name'         value b.batch_name,
                       'client'             value b.client_name,
                       'target_environment' value b.target_env,
                       'cutover_date'       value to_char(b.cutover_date, 'YYYY-MM-DD'),
                       'data_lines'         value b.line_count,
                       'errors'             value b.error_count,
                       'warnings'           value b.warning_count,
                       'info'               value b.info_count,
                       'readiness_score'    value b.readiness_score,
                       'readiness_status'   value b.readiness_status
                       absent on null),
                   -- most important first: the Ask Claude chat may only get the first ~30k chars
                   'reconciliations' value l_recon   format json,
                   'missing_objects' value l_missing format json,
                   'files'           value l_files   format json,
                   'issue_summary'   value l_issues  format json,
                   'column_profile'  value l_profile format json
                   absent on null returning clob)
          into l_json
          from xxx_fv_batches b
         where b.batch_id = p_batch_id;

        return l_json;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_batch_not_found, 'Batch ' || p_batch_id || ' not found.');
    end get_batch_context;

    -- -------------------------------------------------------------------------
    function get_mapping_context (p_file_id in xxx_fv_files.file_id%type) return clob is
        l_json clob;
    begin
        select json_object(
                   'object_code' value o.object_code,
                   'object_name' value o.object_name,
                   'fusion_target' value o.fusion_target,
                   'target_columns' value (
                       select json_arrayagg(
                                  json_object(
                                      'column'      value c.column_name,
                                      'type'        value c.data_type,
                                      'required'    value c.is_required,
                                      'description' value c.description,
                                      'format'      value nvl(c.pattern_hint, c.date_format),
                                      'allowed'     value (select json_arrayagg(cv.allowed_value order by cv.allowed_value returning clob)
                                                             from xxx_fv_column_values cv
                                                            where cv.object_code = c.object_code
                                                              and cv.column_name = c.column_name) format json
                                      absent on null returning clob)
                                  order by c.column_seq returning clob)
                         from xxx_fv_columns c
                        where c.object_code = o.object_code) format json,
                   'already_mapped' value (
                       select json_arrayagg(fc.mapped_column order by fc.column_position returning clob)
                         from xxx_fv_file_columns fc
                        where fc.file_id = f.file_id
                          and fc.mapped_column is not null) format json,
                   'unmapped_headers' value (
                       select json_arrayagg(
                                  json_object('column_position' value fc.column_position,
                                              'header'          value fc.file_header,
                                              'sample_shape'    value fc.sample_shape
                                              absent on null returning clob)
                                  order by fc.column_position returning clob)
                         from xxx_fv_file_columns fc
                        where fc.file_id = f.file_id
                          and fc.mapped_column is null) format json
                   absent on null returning clob)
          into l_json
          from xxx_fv_files f
          join xxx_fv_objects o
            on o.object_code = f.object_code
         where f.file_id = p_file_id;
        return l_json;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found,
                'File ' || p_file_id || ' not found or has no object assigned.');
    end get_mapping_context;

    -- =========================================================================
    -- Status-code APIs
    -- =========================================================================
    procedure generate_batch_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_started  timestamp with time zone := systimestamp;
        l_context  clob;
        l_response clob;
        l_error    varchar2(4000);
    begin
        savepoint ai_report_sp;

        l_context  := get_batch_context(p_batch_id);
        l_response := call_ai(
                          p_system_prompt => report_system_prompt(p_language),
                          p_prompt        => 'Validation run context (JSON). Write the report from these facts only.'
                                             || chr(10) || l_context,
                          p_schema        => c_report_schema);

        save_report(p_batch_id, null, xxx_fv_const_pkg.c_report_batch, p_language,
                    xxx_fv_const_pkg.c_ai_completed, l_context, l_response, null,
                    elapsed_ms(l_started), p_user, x_report_id);
        x_return_status := 'S';
    exception
        when others then
            l_error := sqlerrm;
            rollback to ai_report_sp;
            xxx_fv_log_pkg.error('xxx_fv_ai_pkg.generate_batch_report', 'batch ' || p_batch_id);
            save_report(p_batch_id, null, xxx_fv_const_pkg.c_report_batch, nvl(p_language, xxx_fv_const_pkg.c_lang_en),
                        xxx_fv_const_pkg.c_ai_failed, l_context, null, l_error,
                        elapsed_ms(l_started), p_user, x_report_id);
            x_return_status := 'E';
            x_message       := l_error;
    end generate_batch_report;

    -- -------------------------------------------------------------------------
    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_mapped_count   out number,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_started   timestamp with time zone := systimestamp;
        l_batch_id  xxx_fv_files.batch_id%type;
        l_object    xxx_fv_files.object_code%type;
        l_suggested xxx_fv_objects.object_code%type;
        l_unmapped  number;
        l_context   clob;
        l_response  clob;
        l_error     varchar2(4000);
    begin
        savepoint ai_mapping_sp;

        select batch_id, object_code into l_batch_id, l_object from xxx_fv_files where file_id = p_file_id;
        select count(*) into l_unmapped
          from xxx_fv_file_columns
         where file_id = p_file_id
           and mapped_column is null;

        l_context  := get_mapping_context(p_file_id);
        l_response := call_ai(
                          p_system_prompt => mapping_system_prompt,
                          p_prompt        => 'Map the unmapped headers.' || chr(10) || l_context,
                          p_schema        => c_mapping_schema);

        merge into xxx_fv_file_columns fc
        using (select s.column_position, s.target_column, s.confidence, s.reason
                 from (select j.column_position,
                              upper(trim(j.target_column)) as target_column,
                              least(1, greatest(0, round(j.confidence, 2))) as confidence,
                              substr(j.reason, 1, 400) as reason,
                              row_number() over (partition by upper(trim(j.target_column))
                                                 order by j.confidence desc, j.column_position) as rn
                         from json_table(l_response, '$.mappings[*]'
                                  columns (column_position number         path '$.column_position',
                                           target_column   varchar2(100)  path '$.target_column',
                                           confidence      number         path '$.confidence',
                                           reason          varchar2(1000) path '$.reason')) j
                        where j.confidence >= 0.5
                          and trim(j.target_column) is not null) s
                 join xxx_fv_files f
                   on f.file_id = p_file_id
                 join xxx_fv_columns c
                   on c.object_code = f.object_code
                  and c.column_name = s.target_column
                where s.rn = 1
                  and not exists (select 1
                                    from xxx_fv_file_columns x
                                   where x.file_id = p_file_id
                                     and x.mapped_column = s.target_column)) src
           on (fc.file_id = p_file_id and fc.column_position = src.column_position)
         when matched then update
              set fc.mapped_column  = src.target_column,
                  fc.mapping_source = xxx_fv_const_pkg.c_map_ai,
                  fc.ai_confidence  = src.confidence,
                  fc.ai_reason      = src.reason
            where fc.mapped_column is null;
        x_mapped_count := sql%rowcount;

        x_message := 'Claude mapped ' || x_mapped_count || ' of ' || l_unmapped || ' unmapped headers.';
        if x_mapped_count = 0 then
            l_suggested := xxx_fv_file_adapter_pkg.suggest_object(p_file_id);
            if l_suggested is not null and l_suggested <> l_object then
                x_message := x_message || ' The headers look like ' || l_suggested
                             || ', not ' || l_object || '. Check the object assigned to this sheet.';
            end if;
        end if;

        save_report(l_batch_id, p_file_id, xxx_fv_const_pkg.c_report_mapping, xxx_fv_const_pkg.c_lang_en,
                    xxx_fv_const_pkg.c_ai_completed, l_context, l_response, null,
                    elapsed_ms(l_started), p_user, x_report_id);
        x_return_status := 'S';
    exception
        when others then
            l_error := sqlerrm;
            rollback to ai_mapping_sp;
            xxx_fv_log_pkg.error('xxx_fv_ai_pkg.suggest_mapping', 'file ' || p_file_id);
            if l_batch_id is not null then
                save_report(l_batch_id, p_file_id, xxx_fv_const_pkg.c_report_mapping, xxx_fv_const_pkg.c_lang_en,
                            xxx_fv_const_pkg.c_ai_failed, l_context, null, l_error,
                            elapsed_ms(l_started), p_user, x_report_id);
            end if;
            x_return_status := 'E';
            x_message       := l_error;
    end suggest_mapping;

    -- -------------------------------------------------------------------------
    procedure ask_batch (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_question       in  varchar2,
        p_user           in  varchar2,
        x_answer         out clob,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_started   timestamp with time zone := systimestamp;
        l_history   clob;
        l_report_id xxx_fv_ai_reports.report_id%type;
        l_question  clob;
        l_response  clob;
        l_error     varchar2(4000);
    begin
        savepoint ai_chat_sp;
        select json_object('question' value p_question returning clob) into l_question from dual;

        -- last 6 turns of this user on this batch, oldest first
        select listagg('User: ' || json_value(r.context_json, '$.question' returning varchar2(4000))
                       || chr(10) || 'Assistant: '
                       || json_value(r.response_json, '$.answer' returning varchar2(4000) truncate),
                       chr(10) || chr(10) on overflow truncate)
                 within group (order by r.report_id)
          into l_history
          from (select report_id, context_json, response_json
                  from xxx_fv_ai_reports
                 where batch_id = p_batch_id
                   and report_type = xxx_fv_const_pkg.c_report_chat
                   and status_code = xxx_fv_const_pkg.c_ai_completed
                   and requested_by = p_user
                 order by report_id desc
                 fetch first 6 rows only) r;

        x_answer := apex_ai.generate(
            p_prompt            => case when l_history is not null
                                        then 'Conversation so far:' || chr(10) || l_history || chr(10) || chr(10)
                                   end
                                   || 'Question: ' || p_question,
            p_system_prompt     => 'You answer questions about one pre-Fusion data migration validation batch for '
                                   || 'Oracle Fusion Cloud ERP. The batch facts are in the JSON below. Answer only from '
                                   || 'those facts and quote counts and amounts exactly. If the answer is not in the '
                                   || 'facts, say so and point the user to the Results or AI Report page. Reply in the '
                                   || 'language the user writes in (Arabic or English). Keep object codes, rule codes '
                                   || 'and column names in English. Be concise; use short bullet lists where helpful. '
                                   || 'Plain text only, no markdown tables.'
                                   || chr(10) || chr(10) || 'Batch facts (JSON):' || chr(10)
                                   || get_batch_context(p_batch_id),
            p_service_static_id => xxx_fv_const_pkg.c_ai_service_static_id);

        select json_object('answer' value x_answer returning clob) into l_response from dual;
        save_report(p_batch_id, null, xxx_fv_const_pkg.c_report_chat, xxx_fv_const_pkg.c_lang_en,
                    xxx_fv_const_pkg.c_ai_completed, l_question, l_response,
                    null, elapsed_ms(l_started), p_user, l_report_id);
        x_return_status := 'S';
    exception
        when others then
            l_error := sqlerrm;
            rollback to ai_chat_sp;
            xxx_fv_log_pkg.error('xxx_fv_ai_pkg.ask_batch', 'batch ' || p_batch_id);
            save_report(p_batch_id, null, xxx_fv_const_pkg.c_report_chat, xxx_fv_const_pkg.c_lang_en,
                        xxx_fv_const_pkg.c_ai_failed, l_question, null, l_error,
                        elapsed_ms(l_started), p_user, l_report_id);
            x_return_status := 'E';
            x_message       := l_error;
    end ask_batch;

end xxx_fv_ai_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "XXX_FV_BATCH_API" as

    c_module constant varchar2(30) := 'XXX_FV';

    -- -------------------------------------------------------------------------
    -- Serialises work on one batch (CON-11, CON-17) and returns its status.
    procedure lock_batch (
        p_batch_id  in  xxx_fv_batches.batch_id%type,
        x_status    out xxx_fv_batches.status_code%type)
    is
    begin
        select status_code
          into x_status
          from xxx_fv_batches
         where batch_id = p_batch_id
           for update wait 10;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_batch_not_found, 'Batch ' || p_batch_id || ' not found.');
    end lock_batch;

    -- -------------------------------------------------------------------------
    procedure assert_transition (
        p_from  in varchar2,
        p_to    in varchar2)
    is
        l_allowed pls_integer;
    begin
        select count(*)
          into l_allowed
          from xxx_fv_status_transitions
         where from_status = p_from
           and to_status   = p_to;

        if l_allowed = 0 then
            raise_application_error(xxx_fv_const_pkg.c_err_invalid_transition,
                'This action is not allowed while the batch is ' || p_from || ' (needs a move to ' || p_to || ').');
        end if;
    end assert_transition;

    -- -------------------------------------------------------------------------
    -- Locks, checks the move, and returns. Callers do their work, then set_status.
    procedure begin_change (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_to        in varchar2)
    is
        l_status xxx_fv_batches.status_code%type;
    begin
        lock_batch(p_batch_id, l_status);
        assert_transition(l_status, p_to);
    end begin_change;

    -- -------------------------------------------------------------------------
    procedure set_status (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_to        in varchar2,
        p_user      in varchar2)
    is
    begin
        update xxx_fv_batches
           set status_code = p_to,
               row_version = row_version + 1,
               updated_by  = p_user,
               updated_on  = sysdate
         where batch_id = p_batch_id;
    end set_status;

    -- -------------------------------------------------------------------------
    function batch_of_file (p_file_id in xxx_fv_files.file_id%type) return xxx_fv_files.batch_id%type is
        l_batch_id xxx_fv_files.batch_id%type;
    begin
        select batch_id into l_batch_id from xxx_fv_files where file_id = p_file_id;
        return l_batch_id;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found, 'File ' || p_file_id || ' not found.');
    end batch_of_file;

    -- =========================================================================
    procedure create_batch (
        p_batch_name    in  xxx_fv_batches.batch_name%type,
        p_client_name   in  xxx_fv_batches.client_name%type,
        p_target_env    in  xxx_fv_batches.target_env%type,
        p_cutover_date  in  xxx_fv_batches.cutover_date%type,
        p_user          in  varchar2,
        x_batch_id      out xxx_fv_batches.batch_id%type)
    is
    begin
        insert into xxx_fv_batches (batch_name, client_name, target_env, cutover_date, status_code, created_by)
        values (p_batch_name, p_client_name, p_target_env, p_cutover_date, xxx_fv_const_pkg.c_status_new, p_user)
        returning batch_id into x_batch_id;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.create_batch', p_batch_name);
            raise;
    end create_batch;

    -- -------------------------------------------------------------------------
    procedure update_batch_header (
        p_batch_id      in xxx_fv_batches.batch_id%type,
        p_row_version   in xxx_fv_batches.row_version%type,
        p_batch_name    in xxx_fv_batches.batch_name%type,
        p_client_name   in xxx_fv_batches.client_name%type,
        p_target_env    in xxx_fv_batches.target_env%type,
        p_cutover_date  in xxx_fv_batches.cutover_date%type,
        p_user          in varchar2)
    is
    begin
        update xxx_fv_batches
           set batch_name   = p_batch_name,
               client_name  = p_client_name,
               target_env   = p_target_env,
               cutover_date = p_cutover_date,
               row_version  = row_version + 1,
               updated_by   = p_user,
               updated_on   = sysdate
         where batch_id    = p_batch_id
           and row_version = p_row_version;

        if sql%rowcount = 0 then
            raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter,
                'The batch was changed by someone else. Reload the page and try again.');
        end if;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.update_batch_header', to_char(p_batch_id));
            raise;
    end update_batch_header;

    -- -------------------------------------------------------------------------
    procedure add_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type)
    is
    begin
        begin_change(p_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.register_document(p_batch_id, p_file_name, p_mime_type, p_content, p_user, x_document_id);
        set_status(p_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.add_document', p_batch_id || ':' || p_file_name);
            raise;
    end add_document;

    -- -------------------------------------------------------------------------
    procedure add_uploaded_files (
        p_batch_id         in xxx_fv_batches.batch_id%type,
        p_temp_file_names  in varchar2,
        p_user             in varchar2)
    is
        l_document_id xxx_fv_documents.document_id%type;
    begin
        -- one document per uploaded file; each needs its own parse
        for f in (select t.filename, t.mime_type, t.blob_content
                    from apex_application_temp_files t
                   where t.name in (select column_value from table(apex_string.split(p_temp_file_names, ':')))
                   order by t.filename)
        loop
            add_document(p_batch_id, f.filename, f.mime_type, f.blob_content, p_user, l_document_id);
        end loop;
    end add_uploaded_files;

    -- -------------------------------------------------------------------------
    procedure remove_document (
        p_document_id  in xxx_fv_documents.document_id%type,
        p_user         in varchar2)
    is
        l_batch_id xxx_fv_documents.batch_id%type;
    begin
        select batch_id into l_batch_id from xxx_fv_documents where document_id = p_document_id;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        delete from xxx_fv_documents where document_id = p_document_id;   -- files, mappings, staging cascade
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.remove_document', to_char(p_document_id));
            raise;
    end remove_document;

    -- -------------------------------------------------------------------------
    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type,
        p_user         in varchar2)
    is
        l_batch_id xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_current  xxx_fv_files.object_code%type;
    begin
        select object_code into l_current from xxx_fv_files where file_id = p_file_id;
        if l_current = p_object_code or (l_current is null and p_object_code is null) then
            return;   -- nothing changes: keep the batch status (and its results)
        end if;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.assign_object(p_file_id, p_object_code);
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.assign_object', to_char(p_file_id));
            raise;
    end assign_object;

    -- -------------------------------------------------------------------------
    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type,
        p_user             in varchar2)
    is
        l_batch_id xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_current  xxx_fv_file_columns.mapped_column%type;
    begin
        select mapped_column into l_current
          from xxx_fv_file_columns
         where file_id = p_file_id
           and column_position = p_column_position;
        if l_current = p_column_name or (l_current is null and p_column_name is null) then
            return;   -- unchanged row submitted by the grid
        end if;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.set_mapping(p_file_id, p_column_position, p_column_name);
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.set_mapping', p_file_id || ':' || p_column_position);
            raise;
    end set_mapping;

    -- -------------------------------------------------------------------------
    procedure suggest_mapping (
        p_file_id        in  xxx_fv_files.file_id%type,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_batch_id  xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_report_id xxx_fv_ai_reports.report_id%type;
        l_mapped    number;
    begin
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_ai_pkg.suggest_mapping(p_file_id, p_user, l_report_id, l_mapped, x_return_status, x_message);
        if x_return_status = 'S' and l_mapped > 0 then
            set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
        end if;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.suggest_mapping', to_char(p_file_id));
            raise;
    end suggest_mapping;

    -- -------------------------------------------------------------------------
    procedure validate_batch (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_user      in varchar2)
    is
        l_readiness xxx_fv_rules_pkg.t_readiness;
    begin
        begin_change(p_batch_id, xxx_fv_const_pkg.c_status_validated);
        dbms_application_info.set_module(c_module, 'validate batch ' || p_batch_id);   -- CON-07

        -- each file is parsed separately, so staging loops over files (CON-03)
        for f in (select file_id from xxx_fv_files where batch_id = p_batch_id and is_ignored = 'N' order by file_id) loop
            dbms_application_info.set_action('stage file ' || f.file_id);
            xxx_fv_file_adapter_pkg.stage_file(f.file_id);
        end loop;

        dbms_application_info.set_action('run rules');
        xxx_fv_rules_pkg.run_all(p_batch_id);
        l_readiness := xxx_fv_rules_pkg.get_readiness(p_batch_id);

        update xxx_fv_batches
           set line_count        = l_readiness.line_count,
               error_count       = l_readiness.error_count,
               warning_count     = l_readiness.warning_count,
               info_count        = l_readiness.info_count,
               readiness_score   = l_readiness.readiness_score,
               readiness_status  = l_readiness.readiness_status,
               last_validated_on = sysdate
         where batch_id = p_batch_id;

        set_status(p_batch_id, xxx_fv_const_pkg.c_status_validated, p_user);
        dbms_application_info.set_module(null, null);
    exception
        when others then
            dbms_application_info.set_module(null, null);
            xxx_fv_log_pkg.error('xxx_fv_batch_api.validate_batch', to_char(p_batch_id));
            raise;
    end validate_batch;

    -- -------------------------------------------------------------------------
    procedure generate_ai_report (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_language       in  xxx_fv_ai_reports.language_code%type,
        p_user           in  varchar2,
        x_report_id      out xxx_fv_ai_reports.report_id%type,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
    begin
        begin_change(p_batch_id, xxx_fv_const_pkg.c_status_reported);
        xxx_fv_ai_pkg.generate_batch_report(p_batch_id, nvl(p_language, xxx_fv_const_pkg.c_lang_en), p_user,
                                            x_report_id, x_return_status, x_message);
        if x_return_status = 'S' then
            set_status(p_batch_id, xxx_fv_const_pkg.c_status_reported, p_user);
        end if;
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.generate_ai_report', to_char(p_batch_id));
            raise;
    end generate_ai_report;

    -- -------------------------------------------------------------------------
    procedure ask_claude (
        p_batch_id       in  xxx_fv_batches.batch_id%type,
        p_question       in  varchar2,
        p_user           in  varchar2,
        x_return_status  out varchar2,
        x_message        out varchar2)
    is
        l_answer clob;
    begin
        if trim(p_question) is null then
            x_return_status := 'E';
            x_message       := 'Type a question first.';
            return;
        end if;
        xxx_fv_ai_pkg.ask_batch(p_batch_id, substr(p_question, 1, 2000), p_user, l_answer, x_return_status, x_message);
    end ask_claude;

    -- -------------------------------------------------------------------------
    procedure ignore_file (
        p_file_id  in xxx_fv_files.file_id%type,
        p_ignored  in xxx_fv_files.is_ignored%type,
        p_user     in varchar2)
    is
        l_batch_id xxx_fv_files.batch_id%type := batch_of_file(p_file_id);
        l_current  xxx_fv_files.is_ignored%type;
    begin
        if p_ignored not in ('Y', 'N') or p_ignored is null then
            raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter, 'p_ignored must be Y or N.');
        end if;
        select is_ignored into l_current from xxx_fv_files where file_id = p_file_id;
        if l_current = p_ignored then
            return;   -- nothing changes: keep the batch status
        end if;
        begin_change(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded);
        xxx_fv_file_adapter_pkg.set_ignored(p_file_id, p_ignored);
        set_status(l_batch_id, xxx_fv_const_pkg.c_status_files_loaded, p_user);
    exception
        when others then
            xxx_fv_log_pkg.error('xxx_fv_batch_api.ignore_file', p_file_id || ':' || p_ignored);
            raise;
    end ignore_file;

end xxx_fv_batch_api;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "XXX_FV_FILE_ADAPTER_PKG" as

    c_csv  constant varchar2(4) := 'CSV';
    c_xlsx constant varchar2(4) := 'XLSX';

    type t_file_source is record (
        content          blob,
        file_name        xxx_fv_documents.file_name%type,
        sheet_file_name  xxx_fv_files.sheet_file_name%type,
        object_code      xxx_fv_files.object_code%type);

    -- -------------------------------------------------------------------------
    function normalize_name (p_text in varchar2) return varchar2 deterministic is
    begin
        return upper(trim(both '_' from regexp_replace(trim(p_text), '[^A-Za-z0-9]+', '_')));
    end normalize_name;

    -- -------------------------------------------------------------------------
    function file_kind (p_file_name in varchar2) return varchar2 is
    begin
        if lower(p_file_name) like '%.xlsx' then
            return c_xlsx;
        elsif lower(p_file_name) like '%.csv' or lower(p_file_name) like '%.txt' then
            return c_csv;
        end if;
        raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter,
            'Unsupported file type for "' || p_file_name || '". Upload .xlsx or .csv files.');
    end file_kind;

    -- -------------------------------------------------------------------------
    function load_source (p_file_id in xxx_fv_files.file_id%type) return t_file_source is
        l_src t_file_source;
    begin
        select d.file_content, d.file_name, f.sheet_file_name, f.object_code
          into l_src.content, l_src.file_name, l_src.sheet_file_name, l_src.object_code
          from xxx_fv_files f
          join xxx_fv_documents d
            on d.document_id = f.document_id
         where f.file_id = p_file_id;
        return l_src;
    exception
        when no_data_found then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found, 'File ' || p_file_id || ' not found.');
    end load_source;

    -- -------------------------------------------------------------------------
    -- Headers from line 1, plus the "shape" of the first sample value (digits -> 9)
    -- so the AI can suggest a mapping without seeing account or VAT numbers.
    procedure capture_headers (p_file_id in xxx_fv_files.file_id%type) is
        l_src t_file_source := load_source(p_file_id);
    begin
        delete from xxx_fv_file_columns where file_id = p_file_id;

        insert into xxx_fv_file_columns (file_id, column_position, file_header, header_norm, sample_shape)
        select p_file_id,
               c.column_position,
               max(case when c.line_number = 1 then substr(c.cell, 1, 400) end),
               max(case when c.line_number = 1 then substr(xxx_fv_file_adapter_pkg.normalize_name(c.cell), 1, 400) end),
               substr(min(case when c.line_number > 1
                               then lpad(c.line_number, 6, '0') || regexp_replace(c.cell, '[0-9]', '9') end), 7, 60)
          from (select p.line_number,
                       pos.column_position,
                       trim(case pos.column_position
                                when 1 then p.col001
                                when 2 then p.col002
                                when 3 then p.col003
                                when 4 then p.col004
                                when 5 then p.col005
                                when 6 then p.col006
                                when 7 then p.col007
                                when 8 then p.col008
                                when 9 then p.col009
                                when 10 then p.col010
                                when 11 then p.col011
                                when 12 then p.col012
                                when 13 then p.col013
                                when 14 then p.col014
                                when 15 then p.col015
                                when 16 then p.col016
                                when 17 then p.col017
                                when 18 then p.col018
                                when 19 then p.col019
                                when 20 then p.col020
                                when 21 then p.col021
                                when 22 then p.col022
                                when 23 then p.col023
                                when 24 then p.col024
                                when 25 then p.col025
                                when 26 then p.col026
                                when 27 then p.col027
                                when 28 then p.col028
                                when 29 then p.col029
                                when 30 then p.col030
                                when 31 then p.col031
                                when 32 then p.col032
                                when 33 then p.col033
                                when 34 then p.col034
                                when 35 then p.col035
                                when 36 then p.col036
                                when 37 then p.col037
                                when 38 then p.col038
                                when 39 then p.col039
                                when 40 then p.col040
                                when 41 then p.col041
                                when 42 then p.col042
                                when 43 then p.col043
                                when 44 then p.col044
                                when 45 then p.col045
                                when 46 then p.col046
                                when 47 then p.col047
                                when 48 then p.col048
                                when 49 then p.col049
                                when 50 then p.col050
                                when 51 then p.col051
                                when 52 then p.col052
                                when 53 then p.col053
                                when 54 then p.col054
                                when 55 then p.col055
                                when 56 then p.col056
                                when 57 then p.col057
                                when 58 then p.col058
                                when 59 then p.col059
                                when 60 then p.col060
                            end) as cell
                  from table(apex_data_parser.parse(
                                 p_content           => l_src.content,
                                 p_file_name         => l_src.file_name,
                                 p_xlsx_sheet_name   => l_src.sheet_file_name,
                                 p_detect_data_types => 'N',
                                 p_max_rows          => 6)) p
                 cross join (select level as column_position
                               from dual
                            connect by level <= xxx_fv_const_pkg.c_max_file_columns) pos
               ) c
         where c.cell is not null
         group by c.column_position
        having max(case when c.line_number = 1 then c.cell end) is not null;
    end capture_headers;

    -- -------------------------------------------------------------------------
    -- Header = column name, or header = known alias. First header wins on duplicates.
    procedure auto_map (p_file_id in xxx_fv_files.file_id%type) is
    begin
        merge into xxx_fv_file_columns fc
        using (select m.file_id, m.column_position, m.column_name
                 from (select fc2.file_id,
                              fc2.column_position,
                              coalesce(c.column_name, a.column_name) as column_name,
                              row_number() over (partition by coalesce(c.column_name, a.column_name)
                                                 order by fc2.column_position) as rn
                         from xxx_fv_file_columns fc2
                         join xxx_fv_files f
                           on f.file_id = fc2.file_id
                         left join xxx_fv_columns c
                           on c.object_code = f.object_code
                          and c.column_name = fc2.header_norm
                         left join xxx_fv_column_aliases a
                           on a.object_code = f.object_code
                          and a.alias_norm  = fc2.header_norm
                        where fc2.file_id = p_file_id
                          and fc2.mapped_column is null) m
                where m.column_name is not null
                  and m.rn = 1
                  and not exists (select 1
                                    from xxx_fv_file_columns x
                                   where x.file_id = m.file_id
                                     and x.mapped_column = m.column_name)) s
           on (fc.file_id = s.file_id and fc.column_position = s.column_position)
         when matched then update
              set fc.mapped_column  = s.column_name,
                  fc.mapping_source = xxx_fv_const_pkg.c_map_auto;
    end auto_map;

    -- -------------------------------------------------------------------------
    -- Fallback when the sheet/file name names no object: score each object by the
    -- headers that match its columns or aliases. Each header counts 1/(number of objects
    -- it matches), so distinctive headers (LEDGER_NAME) outweigh shared ones (CURRENCY).
    -- Assigns only on a clear win: score >= 1.5 and >= 1.5 x the runner-up.
    function suggest_object (p_file_id in xxx_fv_files.file_id%type) return varchar2 is
        l_object xxx_fv_objects.object_code%type;
    begin
        with hdr as (select distinct fc.header_norm
                       from xxx_fv_file_columns fc
                      where fc.file_id = p_file_id
                        and fc.header_norm is not null),
             cand as (select c.object_code, c.column_name as name_norm from xxx_fv_columns c
                      union
                      select a.object_code, a.alias_norm from xxx_fv_column_aliases a),
             hit as (select distinct h.header_norm, k.object_code
                       from hdr h
                       join cand k
                         on k.name_norm = h.header_norm
                       join xxx_fv_objects o
                         on o.object_code = k.object_code
                        and o.is_enabled = 'Y'),
             scored as (select object_code, sum(wt) as score
                          from (select object_code, 1 / count(*) over (partition by header_norm) as wt
                                  from hit)
                         group by object_code),
             ranked as (select object_code, score,
                               row_number() over (order by score desc, object_code) as rn,
                               lead(score) over (order by score desc, object_code) as next_score
                          from scored)
        select max(r.object_code)
          into l_object
          from ranked r
         where r.rn = 1
           and r.score >= 1.5
           and (r.next_score is null or r.score >= 1.5 * r.next_score);
        return l_object;
    end suggest_object;

    -- -------------------------------------------------------------------------
    procedure detect_by_headers (p_file_id in xxx_fv_files.file_id%type) is
        l_object xxx_fv_objects.object_code%type := suggest_object(p_file_id);
    begin
        if l_object is not null then
            update xxx_fv_files
               set object_code = l_object
             where file_id = p_file_id
               and object_code is null;
        end if;
    end detect_by_headers;

    -- -------------------------------------------------------------------------
    procedure register_document (
        p_batch_id     in  xxx_fv_batches.batch_id%type,
        p_file_name    in  xxx_fv_documents.file_name%type,
        p_mime_type    in  xxx_fv_documents.mime_type%type,
        p_content      in  blob,
        p_user         in  varchar2,
        x_document_id  out xxx_fv_documents.document_id%type)
    is
        l_kind  varchar2(4) := file_kind(p_file_name);
    begin
        insert into xxx_fv_documents (batch_id, file_name, mime_type, file_content, uploaded_by)
        values (p_batch_id, p_file_name, p_mime_type, p_content, p_user)
        returning document_id into x_document_id;

        if l_kind = c_xlsx then
            insert into xxx_fv_files (batch_id, document_id, sheet_display_name, sheet_file_name, object_code)
            select p_batch_id,
                   x_document_id,
                   w.sheet_display_name,
                   w.sheet_file_name,
                   (select min(o.object_code)
                      from xxx_fv_objects o
                     where o.is_enabled = 'Y'
                       and xxx_fv_file_adapter_pkg.normalize_name(w.sheet_display_name) in (o.object_code, o.sheet_alias))
              from table(apex_data_parser.get_xlsx_worksheets(p_content => p_content)) w
             order by w.sheet_sequence;
        else
            insert into xxx_fv_files (batch_id, document_id, object_code)
            select p_batch_id,
                   x_document_id,
                   (select min(o.object_code)
                      from xxx_fv_objects o
                     where o.is_enabled = 'Y'
                       and xxx_fv_file_adapter_pkg.normalize_name(regexp_replace(p_file_name, '\.[^.]*$', '')) in (o.object_code, o.sheet_alias))
              from dual;
        end if;

        -- one parse per sheet: a loop is required because each sheet is read separately (CON-03)
        for f in (select file_id
                    from xxx_fv_files
                   where document_id = x_document_id
                   order by file_id)
        loop
            capture_headers(f.file_id);
            detect_by_headers(f.file_id);
            auto_map(f.file_id);
        end loop;
    end register_document;

    -- -------------------------------------------------------------------------
    procedure clear_staging (p_file_id in xxx_fv_files.file_id%type) is
    begin
        delete from xxx_fv_stage_values where file_id = p_file_id;
        delete from xxx_fv_stage_lines  where file_id = p_file_id;
        update xxx_fv_files
           set row_count = null,
               staged_on = null
         where file_id = p_file_id;
    end clear_staging;

    -- -------------------------------------------------------------------------
    procedure assign_object (
        p_file_id      in xxx_fv_files.file_id%type,
        p_object_code  in xxx_fv_objects.object_code%type)
    is
    begin
        update xxx_fv_files
           set object_code = p_object_code,
               is_ignored  = 'N'                    -- assigning an object includes the sheet again
         where file_id = p_file_id;

        if sql%rowcount = 0 then
            raise_application_error(xxx_fv_const_pkg.c_err_file_not_found, 'File ' || p_file_id || ' not found.');
        end if;

        update xxx_fv_file_columns
           set mapped_column  = null,
               mapping_source = null,
               ai_confidence  = null,
               ai_reason      = null
         where file_id = p_file_id;

        clear_staging(p_file_id);
        auto_map(p_file_id);
    end assign_object;

    -- -------------------------------------------------------------------------
    procedure set_mapping (
        p_file_id          in xxx_fv_file_columns.file_id%type,
        p_column_position  in xxx_fv_file_columns.column_position%type,
        p_column_name      in xxx_fv_file_columns.mapped_column%type)
    is
        l_valid pls_integer;
    begin
        if p_column_name is not null then
            select count(*)
              into l_valid
              from xxx_fv_files f
              join xxx_fv_columns c
                on c.object_code = f.object_code
             where f.file_id = p_file_id
               and c.column_name = p_column_name;

            if l_valid = 0 then
                raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter,
                    'Column ' || p_column_name || ' does not belong to the object of this file.');
            end if;
        end if;

        update xxx_fv_file_columns
           set mapped_column  = p_column_name,
               mapping_source = case when p_column_name is not null then xxx_fv_const_pkg.c_map_user end,
               ai_confidence  = null,
               ai_reason      = null
         where file_id = p_file_id
           and column_position = p_column_position;

        clear_staging(p_file_id);
    end set_mapping;

    -- -------------------------------------------------------------------------
    procedure stage_file (p_file_id in xxx_fv_files.file_id%type) is
        l_src   t_file_source := load_source(p_file_id);
        l_lines pls_integer;
    begin
        clear_staging(p_file_id);

        if l_src.object_code is null then
            return;   -- unknown object: reported by FILE_UNKNOWN_OBJECT, nothing to stage
        end if;

        insert into xxx_fv_stage_values (file_id, line_number, column_name, cell_value)
        select p_file_id, c.line_number, c.mapped_column, substr(c.cell, 1, 4000)
          from (select p.line_number,
                       m.mapped_column,
                       trim(case m.column_position
                                when 1 then p.col001
                                when 2 then p.col002
                                when 3 then p.col003
                                when 4 then p.col004
                                when 5 then p.col005
                                when 6 then p.col006
                                when 7 then p.col007
                                when 8 then p.col008
                                when 9 then p.col009
                                when 10 then p.col010
                                when 11 then p.col011
                                when 12 then p.col012
                                when 13 then p.col013
                                when 14 then p.col014
                                when 15 then p.col015
                                when 16 then p.col016
                                when 17 then p.col017
                                when 18 then p.col018
                                when 19 then p.col019
                                when 20 then p.col020
                                when 21 then p.col021
                                when 22 then p.col022
                                when 23 then p.col023
                                when 24 then p.col024
                                when 25 then p.col025
                                when 26 then p.col026
                                when 27 then p.col027
                                when 28 then p.col028
                                when 29 then p.col029
                                when 30 then p.col030
                                when 31 then p.col031
                                when 32 then p.col032
                                when 33 then p.col033
                                when 34 then p.col034
                                when 35 then p.col035
                                when 36 then p.col036
                                when 37 then p.col037
                                when 38 then p.col038
                                when 39 then p.col039
                                when 40 then p.col040
                                when 41 then p.col041
                                when 42 then p.col042
                                when 43 then p.col043
                                when 44 then p.col044
                                when 45 then p.col045
                                when 46 then p.col046
                                when 47 then p.col047
                                when 48 then p.col048
                                when 49 then p.col049
                                when 50 then p.col050
                                when 51 then p.col051
                                when 52 then p.col052
                                when 53 then p.col053
                                when 54 then p.col054
                                when 55 then p.col055
                                when 56 then p.col056
                                when 57 then p.col057
                                when 58 then p.col058
                                when 59 then p.col059
                                when 60 then p.col060
                            end) as cell
                  from table(apex_data_parser.parse(
                                 p_content           => l_src.content,
                                 p_file_name         => l_src.file_name,
                                 p_xlsx_sheet_name   => l_src.sheet_file_name,
                                 p_detect_data_types => 'N')) p
                 cross join (select column_position, mapped_column
                               from xxx_fv_file_columns
                              where file_id = p_file_id
                                and mapped_column is not null) m
                 where p.line_number > 1) c
         where c.cell is not null;

        insert into xxx_fv_stage_lines (file_id, line_number)
        select distinct file_id, line_number
          from xxx_fv_stage_values
         where file_id = p_file_id;
        l_lines := sql%rowcount;

        update xxx_fv_files
           set row_count = l_lines,
               staged_on = sysdate
         where file_id = p_file_id;
    end stage_file;

    -- -------------------------------------------------------------------------
    procedure set_ignored (
        p_file_id  in xxx_fv_files.file_id%type,
        p_ignored  in xxx_fv_files.is_ignored%type)
    is
    begin
        if p_ignored = 'Y' then
            update xxx_fv_files
               set is_ignored  = 'Y',
                   object_code = null
             where file_id = p_file_id;
            update xxx_fv_file_columns
               set mapped_column  = null,
                   mapping_source = null,
                   ai_confidence  = null,
                   ai_reason      = null
             where file_id = p_file_id;
            clear_staging(p_file_id);
        else
            -- same name detection as register_document, then the header fallback
            update xxx_fv_files f
               set f.is_ignored  = 'N',
                   f.object_code = (select min(o.object_code)
                                      from xxx_fv_objects o
                                      join xxx_fv_documents d
                                        on d.document_id = f.document_id
                                     where o.is_enabled = 'Y'
                                       and xxx_fv_file_adapter_pkg.normalize_name(
                                               coalesce(f.sheet_display_name, regexp_replace(d.file_name, '\.[^.]*$', '')))
                                           in (o.object_code, o.sheet_alias))
             where f.file_id = p_file_id;
            detect_by_headers(p_file_id);
            auto_map(p_file_id);
        end if;
    end set_ignored;

end xxx_fv_file_adapter_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "XXX_FV_LOG_PKG" as
    procedure error (p_module in varchar2, p_key in varchar2 default null) is
        pragma autonomous_transaction;   -- the only autonomous transaction in XXX_FV (CON-38)
    begin
        insert into xxx_fv_error_log (module, log_key, err_stack, backtrace, call_stack)
        values (substr(p_module, 1, 200),
                substr(p_key, 1, 200),
                substr(dbms_utility.format_error_stack, 1, 4000),
                substr(dbms_utility.format_error_backtrace, 1, 4000),
                substr(dbms_utility.format_call_stack, 1, 4000));
        commit;   -- commits only the log row
    end error;
end xxx_fv_log_pkg;
/


  CREATE OR REPLACE EDITIONABLE PACKAGE BODY "XXX_FV_RULES_PKG" as

    c_amount_mask constant varchar2(30) := 'FM999,999,999,999,990.00';

    -- -------------------------------------------------------------------------
    procedure clear_results (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        delete from xxx_fv_issues        where batch_id = p_batch_id;
        delete from xxx_fv_recon_results where batch_id = p_batch_id;
    end clear_results;

    -- -------------------------------------------------------------------------
    -- File-level checks: unknown sheets, missing/unmapped columns, empty files,
    -- objects with no file at all.
    procedure run_file_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        insert into xxx_fv_issues (batch_id, file_id, rule_code, severity, message)
        select f.batch_id, f.file_id, r.rule_code, r.severity,
               'Sheet/file "' || coalesce(f.sheet_display_name, d.file_name) || '" in ' || d.file_name
               || ' does not match any migration object. Assign an object or remove it.'
          from xxx_fv_files f
          join xxx_fv_documents d
            on d.document_id = f.document_id
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_unknown_object
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and f.object_code is null
           and f.is_ignored = 'N';                 -- sheets the user ignored are not migration data

        insert into xxx_fv_issues (batch_id, file_id, object_code, column_name, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, c.column_name, r.rule_code, r.severity,
               'Required column ' || c.column_name || ' is missing or not mapped.'
          from xxx_fv_files f
          join xxx_fv_columns c
            on c.object_code = f.object_code
           and c.is_required = 'Y'
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_missing_column
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and not exists (select 1
                             from xxx_fv_file_columns fc
                            where fc.file_id = f.file_id
                              and fc.mapped_column = c.column_name);

        insert into xxx_fv_issues (batch_id, file_id, object_code, column_name, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, substr(fc.file_header, 1, 200), r.rule_code, r.severity,
               'Column "' || fc.file_header || '" is not mapped to a Fusion field and will be ignored.'
          from xxx_fv_files f
          join xxx_fv_file_columns fc
            on fc.file_id = f.file_id
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_unmapped_column
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and f.object_code is not null
           and fc.mapped_column is null;

        insert into xxx_fv_issues (batch_id, file_id, object_code, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, r.rule_code, r.severity,
               'No data rows found for ' || f.object_code || '.'
          from xxx_fv_files f
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_empty_file
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and f.object_code is not null
           and not exists (select 1 from xxx_fv_stage_lines l where l.file_id = f.file_id);

        insert into xxx_fv_issues (batch_id, object_code, rule_code, severity, message)
        select p_batch_id, o.object_code, r.rule_code, r.severity,
               'No file provided for ' || o.object_name || ' (' || o.module_code || ').'
          from xxx_fv_objects o
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_object_missing
           and r.is_enabled = 'Y'
         where o.is_enabled = 'Y'
           and not exists (select 1
                             from xxx_fv_files f
                            where f.batch_id = p_batch_id
                              and f.object_code = o.object_code);
    end run_file_checks;

    -- -------------------------------------------------------------------------
    procedure run_required_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        -- only for mapped columns; an unmapped required column is reported once at file level
        insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name, rule_code, severity, message)
        select f.batch_id, f.file_id, f.object_code, l.line_number, c.column_name, r.rule_code, r.severity,
               c.column_name || ' is required.'
          from xxx_fv_files f
          join xxx_fv_columns c
            on c.object_code = f.object_code
           and c.is_required = 'Y'
          join xxx_fv_file_columns fc
            on fc.file_id = f.file_id
           and fc.mapped_column = c.column_name
          join xxx_fv_stage_lines l
            on l.file_id = f.file_id
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_required
           and r.is_enabled = 'Y'
         where f.batch_id = p_batch_id
           and not exists (select 1
                             from xxx_fv_stage_values v
                            where v.file_id = l.file_id
                              and v.line_number = l.line_number
                              and v.column_name = c.column_name);
    end run_required_checks;

    -- -------------------------------------------------------------------------
    -- One pass over every non-empty cell: type, length, pattern, allowed list.
    -- The first failing check per cell is reported. Sensitive values are masked.
    procedure run_value_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name,
                                   rule_code, severity, message, bad_value)
        select x.batch_id, x.file_id, x.object_code, x.line_number, x.column_name,
               r.rule_code, r.severity,
               substr(case x.rule_code
                          when xxx_fv_const_pkg.c_rule_number then
                              'Not a valid number: "' || x.shown_value || '". Use digits and "." only, no thousands separators.'
                          when xxx_fv_const_pkg.c_rule_date then
                              'Not a valid date for format ' || x.date_format || ': "' || x.shown_value || '".'
                          when xxx_fv_const_pkg.c_rule_max_length then
                              'Too long: ' || length(x.cell_value) || ' characters (max ' || x.max_length || ').'
                          when xxx_fv_const_pkg.c_rule_pattern then
                              'Invalid format: "' || x.shown_value || '". Expected: ' || nvl(x.pattern_hint, x.regex_pattern) || '.'
                          when xxx_fv_const_pkg.c_rule_allowed_value then
                              'Value "' || x.shown_value || '" is not allowed. Allowed: '
                              || (select listagg(cv.allowed_value, ', ') within group (order by cv.allowed_value)
                                    from xxx_fv_column_values cv
                                   where cv.object_code = x.object_code
                                     and cv.column_name = x.column_name) || '.'
                      end, 1, 1000),
               substr(x.shown_value, 1, 400)
          from (select f.batch_id, f.file_id, f.object_code, v.line_number, v.column_name, v.cell_value,
                       c.date_format, c.max_length, c.regex_pattern, c.pattern_hint,
                       case when c.is_sensitive = 'Y'
                            then lpad(substr(v.cell_value, -4), length(v.cell_value), '*')
                            else v.cell_value
                       end as shown_value,
                       case
                           when c.data_type = 'NUMBER'
                                and not regexp_like(v.cell_value, '^-?[0-9]+(\.[0-9]+)?$')
                               then xxx_fv_const_pkg.c_rule_number
                           when c.data_type = 'DATE'
                                and case c.date_format
                                        when 'YYYY-MM-DD'  then validate_conversion(v.cell_value as date, 'YYYY-MM-DD')
                                        when 'YYYY/MM/DD'  then validate_conversion(v.cell_value as date, 'YYYY/MM/DD')
                                        when 'DD-MON-YYYY' then validate_conversion(v.cell_value as date, 'DD-MON-YYYY', 'NLS_DATE_LANGUAGE=ENGLISH')
                                    end = 0
                               then xxx_fv_const_pkg.c_rule_date
                           when c.max_length is not null
                                and length(v.cell_value) > c.max_length
                               then xxx_fv_const_pkg.c_rule_max_length
                           when c.regex_pattern is not null
                                and not regexp_like(v.cell_value, c.regex_pattern)
                               then xxx_fv_const_pkg.c_rule_pattern
                           when exists (select 1
                                          from xxx_fv_column_values cv
                                         where cv.object_code = c.object_code
                                           and cv.column_name = c.column_name)
                                and not exists (select 1
                                                  from xxx_fv_column_values cv
                                                 where cv.object_code = c.object_code
                                                   and cv.column_name = c.column_name
                                                   and cv.allowed_value = v.cell_value)
                               then xxx_fv_const_pkg.c_rule_allowed_value
                       end as rule_code
                  from xxx_fv_files f
                  join xxx_fv_stage_values v
                    on v.file_id = f.file_id
                  join xxx_fv_columns c
                    on c.object_code = f.object_code
                   and c.column_name = v.column_name
                 where f.batch_id = p_batch_id) x
          join xxx_fv_rules r
            on r.rule_code = x.rule_code
           and r.is_enabled = 'Y';
    end run_value_checks;

    -- -------------------------------------------------------------------------
    -- Duplicate business keys across all files of the same object in the batch.
    procedure run_duplicate_checks (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name,
                                   rule_code, severity, message, bad_value)
        select d.batch_id, d.file_id, d.object_code, d.line_number, substr(d.key_columns, 1, 200),
               r.rule_code, r.severity,
               substr('Duplicate key ' || d.key_columns || ' = ' || d.key_shown
                      || ' appears ' || d.dup_count || ' times.', 1, 1000),
               substr(d.key_shown, 1, 400)
          from (select k.batch_id, k.file_id, k.object_code, k.line_number, k.key_columns, k.key_shown,
                       count(*) over (partition by k.object_code, k.key_value) as dup_count
                  from (select f.batch_id, f.file_id, f.object_code, l.line_number,
                               listagg(c.column_name, '+') within group (order by c.unique_key_seq) as key_columns,
                               listagg(nvl(v.cell_value, '<empty>'), ' | ') within group (order by c.unique_key_seq) as key_value,
                               -- sensitive key parts (bank account numbers) are masked for display
                               listagg(nvl(case when c.is_sensitive = 'Y'
                                                then lpad(substr(v.cell_value, -4), length(v.cell_value), '*')
                                                else v.cell_value
                                           end, '<empty>'), ' | ') within group (order by c.unique_key_seq) as key_shown
                          from xxx_fv_files f
                          join xxx_fv_columns c
                            on c.object_code = f.object_code
                           and c.unique_key_seq is not null
                          join xxx_fv_stage_lines l
                            on l.file_id = f.file_id
                          left join xxx_fv_stage_values v
                            on v.file_id = l.file_id
                           and v.line_number = l.line_number
                           and v.column_name = c.column_name
                         where f.batch_id = p_batch_id
                         group by f.batch_id, f.file_id, f.object_code, l.line_number) k) d
          join xxx_fv_rules r
            on r.rule_code = xxx_fv_const_pkg.c_rule_duplicate_key
           and r.is_enabled = 'Y'
         where d.dup_count > 1;
    end run_duplicate_checks;

    -- -------------------------------------------------------------------------
    -- Rule SQL is admin configuration (code, not values). Values stay bound (CON-01);
    -- the text is screened here and only admins can edit rules (APEX authorization).
    procedure assert_safe_sql (p_rule_code in varchar2, p_sql in clob) is
        -- screen code only: string literals ('...; supplier ...') are blanked first, so text
        -- inside messages cannot trip the ";" / package checks ('' escapes stay balanced)
        l_sql clob := regexp_replace(lower(p_sql), '''[^'']*''', '''''');
    begin
        if not regexp_like(l_sql, '^\s*(select|with)\s')
           or instr(l_sql, ';') > 0
           or regexp_like(l_sql, 'for\s+update')
           or regexp_like(l_sql, '(^|[^a-z0-9_$#])(dbms_|utl_|apex_|htp\.|owa_|sys\.)')
        then
            raise_application_error(xxx_fv_const_pkg.c_err_unsafe_rule_sql,
                'Rule ' || p_rule_code || ': SQL must be one SELECT/WITH query, without ";", '
                || 'FOR UPDATE, or calls to DBMS_/UTL_/APEX_/SYS packages.');
        end if;
    end assert_safe_sql;

    -- -------------------------------------------------------------------------
    procedure run_row_rule (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_rule      in xxx_fv_rules%rowtype)
    is
    begin
        execute immediate
               'insert into xxx_fv_issues (batch_id, file_id, object_code, line_number, column_name, '
            || '                           rule_code, severity, message, bad_value) '
            || 'with b as (select :batch_id as batch_id from dual) '
            || 'select :batch_id2, x.file_id, coalesce(:object_code, f.object_code), x.line_number, '
            || '       substr(x.column_name, 1, 200), :rule_code, :severity, '
            || '       substr(x.message, 1, 1000), substr(x.bad_value, 1, 400) '
            || '  from (' || p_rule.rule_sql || ') x '
            || '  left join xxx_fv_files f on f.file_id = x.file_id'
            using p_batch_id, p_batch_id, p_rule.object_code, p_rule.rule_code, p_rule.severity;
    end run_row_rule;

    -- -------------------------------------------------------------------------
    procedure run_recon_rule (
        p_batch_id  in xxx_fv_batches.batch_id%type,
        p_rule      in xxx_fv_rules%rowtype)
    is
    begin
        execute immediate
               'insert into xxx_fv_recon_results (batch_id, rule_code, recon_label, currency_code, '
            || '                                  source_total, target_total, difference, status_code) '
            || 'with b as (select :batch_id as batch_id from dual) '
            || 'select :batch_id2, :rule_code, substr(x.recon_label, 1, 200), x.currency_code, '
            || '       x.source_total, x.target_total, '
            || '       nvl(x.source_total, 0) - nvl(x.target_total, 0), '
            || '       case when abs(nvl(x.source_total, 0) - nvl(x.target_total, 0)) <= :tolerance '
            || '            then :matched else :diff end '
            || '  from (' || p_rule.rule_sql || ') x'
            using p_batch_id, p_batch_id, p_rule.rule_code, p_rule.tolerance,
                  xxx_fv_const_pkg.c_recon_matched, xxx_fv_const_pkg.c_recon_diff;

        insert into xxx_fv_issues (batch_id, object_code, rule_code, severity, message)
        select rr.batch_id, p_rule.object_code, rr.rule_code, p_rule.severity,
               substr(rr.recon_label || ' [' || nvl(rr.currency_code, '-') || ']: source '
                      || to_char(rr.source_total, c_amount_mask) || ' vs target '
                      || to_char(rr.target_total, c_amount_mask) || ', difference '
                      || to_char(rr.difference, c_amount_mask) || '.', 1, 1000)
          from xxx_fv_recon_results rr
         where rr.batch_id = p_batch_id
           and rr.rule_code = p_rule.rule_code
           and rr.status_code = xxx_fv_const_pkg.c_recon_diff;
    end run_recon_rule;

    -- -------------------------------------------------------------------------
    procedure run_custom_rules (p_batch_id in xxx_fv_batches.batch_id%type) is
        l_rule xxx_fv_rules%rowtype;
        l_err  varchar2(1000);
    begin
        -- one statement per configured rule: a loop is inherent to plug-in rules (CON-03)
        for r in (select ru.rule_code
                    from xxx_fv_rules ru
                   where ru.rule_type in (xxx_fv_const_pkg.c_rule_type_row_sql, xxx_fv_const_pkg.c_rule_type_recon)
                     and ru.is_enabled = 'Y'
                     and (ru.object_code is null
                          or exists (select 1
                                       from xxx_fv_files f
                                      where f.batch_id = p_batch_id
                                        and f.object_code = ru.object_code))
                   order by ru.run_order, ru.rule_code)
        loop
            select * into l_rule from xxx_fv_rules where rule_code = r.rule_code;
            -- one broken plug-in rule must not abort the whole validation: log it, report it
            -- as an ERROR issue on the batch and continue (deliberate exception to log+RAISE)
            savepoint before_rule;
            begin
                assert_safe_sql(l_rule.rule_code, l_rule.rule_sql);
                if l_rule.rule_type = xxx_fv_const_pkg.c_rule_type_row_sql then
                    run_row_rule(p_batch_id, l_rule);
                else
                    run_recon_rule(p_batch_id, l_rule);
                end if;
            exception
                when others then
                    xxx_fv_log_pkg.error('xxx_fv_rules_pkg.run_custom_rules', l_rule.rule_code);
                    l_err := substr('Rule could not run and was skipped: ' || sqlerrm, 1, 1000);
                    rollback to before_rule;
                    insert into xxx_fv_issues (batch_id, object_code, rule_code, severity, message)
                    values (p_batch_id, l_rule.object_code, l_rule.rule_code, xxx_fv_const_pkg.c_sev_error,
                            l_err);
            end;
        end loop;
    end run_custom_rules;

    -- -------------------------------------------------------------------------
    procedure run_all (p_batch_id in xxx_fv_batches.batch_id%type) is
    begin
        clear_results(p_batch_id);
        run_file_checks(p_batch_id);
        run_required_checks(p_batch_id);
        run_value_checks(p_batch_id);
        run_duplicate_checks(p_batch_id);
        run_custom_rules(p_batch_id);
    end run_all;

    -- -------------------------------------------------------------------------
    -- Score = % of data lines with no ERROR, minus 5 points per batch/file-level
    -- ERROR (missing columns, failed reconciliations, ...), floored at 0.
    function get_readiness (p_batch_id in xxx_fv_batches.batch_id%type) return t_readiness is
        l_r            t_readiness;
        l_error_lines  number;
        l_level_errors number;
    begin
        select count(*)
          into l_r.line_count
          from xxx_fv_stage_lines l
          join xxx_fv_files f
            on f.file_id = l.file_id
         where f.batch_id = p_batch_id;

        select count(case when i.severity = xxx_fv_const_pkg.c_sev_error   then 1 end),
               count(case when i.severity = xxx_fv_const_pkg.c_sev_warning then 1 end),
               count(case when i.severity = xxx_fv_const_pkg.c_sev_info    then 1 end),
               count(distinct case when i.severity = xxx_fv_const_pkg.c_sev_error and i.line_number is not null
                                   then i.file_id || ':' || i.line_number end),
               count(case when i.severity = xxx_fv_const_pkg.c_sev_error and i.line_number is null then 1 end)
          into l_r.error_count, l_r.warning_count, l_r.info_count, l_error_lines, l_level_errors
          from xxx_fv_issues i
         where i.batch_id = p_batch_id;

        l_r.readiness_score :=
            case when l_r.line_count = 0 then 0
                 else greatest(0, round(100 * (l_r.line_count - l_error_lines) / l_r.line_count) - 5 * l_level_errors)
            end;

        l_r.readiness_status :=
            case when l_r.error_count > 0   then xxx_fv_const_pkg.c_not_ready
                 when l_r.warning_count > 0 then xxx_fv_const_pkg.c_ready_with_warnings
                 else xxx_fv_const_pkg.c_ready
            end;
        return l_r;
    end get_readiness;

    -- -------------------------------------------------------------------------
    procedure check_rule_sql (p_rule_code in xxx_fv_rules.rule_code%type) is
        l_rule     xxx_fv_rules%rowtype;
        l_cursor   integer;
        l_count    integer;
        l_desc     dbms_sql.desc_tab2;
        l_found    varchar2(4000) := ',';
        l_missing  varchar2(4000);
        l_required sys.odcivarchar2list;
    begin
        begin
            select * into l_rule from xxx_fv_rules where rule_code = p_rule_code;
        exception
            when no_data_found then
                raise_application_error(xxx_fv_const_pkg.c_err_bad_parameter, 'Rule ' || p_rule_code || ' not found.');
        end;

        if l_rule.rule_type = xxx_fv_const_pkg.c_rule_type_column then
            return;   -- built-in rule, logic lives in this package
        end if;

        assert_safe_sql(l_rule.rule_code, l_rule.rule_sql);

        if l_rule.rule_type = xxx_fv_const_pkg.c_rule_type_row_sql then
            l_required := sys.odcivarchar2list('FILE_ID', 'LINE_NUMBER', 'COLUMN_NAME', 'BAD_VALUE', 'MESSAGE');
        else
            l_required := sys.odcivarchar2list('RECON_LABEL', 'CURRENCY_CODE', 'SOURCE_TOTAL', 'TARGET_TOTAL');
        end if;

        -- parse only (no execution) to get the select list
        l_cursor := dbms_sql.open_cursor;
        dbms_sql.parse(l_cursor,
                       'with b as (select 0 as batch_id from dual) select * from (' || l_rule.rule_sql || ') where 1 = 0',
                       dbms_sql.native);
        dbms_sql.describe_columns2(l_cursor, l_count, l_desc);
        dbms_sql.close_cursor(l_cursor);

        for i in 1 .. l_count loop
            l_found := l_found || upper(l_desc(i).col_name) || ',';
        end loop;

        for i in 1 .. l_required.count loop
            if instr(l_found, ',' || l_required(i) || ',') = 0 then
                l_missing := l_missing || ' ' || l_required(i);
            end if;
        end loop;

        if l_missing is not null then
            raise_application_error(xxx_fv_const_pkg.c_err_rule_sql_columns,
                'Rule ' || p_rule_code || ': the query must return the columns' || l_missing || '.');
        end if;
    exception
        when others then
            if l_cursor is not null and dbms_sql.is_open(l_cursor) then
                dbms_sql.close_cursor(l_cursor);
            end if;
            raise;
    end check_rule_sql;

end xxx_fv_rules_pkg;
/

