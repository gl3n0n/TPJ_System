CREATE TABLE "CMS_OP_VALE_HDR"
 (    "TRAN_NO" VARCHAR2(16) NOT NULL ENABLE,
      "TX_DATE" DATE NOT NULL ENABLE,
      "REMARKS" VARCHAR2(256),
      "CREATED_BY" VARCHAR2(32),
      "DATE_MODIFIED" DATE,
      "MODIFIED_BY" VARCHAR2(32),
      "DATE_CREATED" DATE,
      "STATUS" VARCHAR2(16) DEFAULT 'FOR APPROVAL',
      "APPROVED_BY" VARCHAR2(16),
      "DT_APPROVED" DATE,
      "PY_STATUS" VARCHAR2(16) DEFAULT 'FOR APPROVAL',
      "POSTED_BY" VARCHAR2(16),
      "DT_POSTED" DATE,
      "CHECKED_BY" VARCHAR2(16),
      "DT_CHECKED" DATE,
      "MSG_RECEIVED_BY" VARCHAR2(16),
      "DT_MSG_RECEIVED" DATE,
      "PREPARED_BY" VARCHAR2(16),
      "DT_PREPARED" DATE,
       CONSTRAINT "OPVH_PK" PRIMARY KEY ("TRAN_NO")
 );



CREATE TABLE "CMS_OP_VALE_DTL"
 (    "TRAN_NO" VARCHAR2(16) NOT NULL ENABLE,
      "EMPL_EMPL_ID" VARCHAR2(16) NOT NULL ENABLE,
      "VESS_CODE" VARCHAR2(16),
      "POSI_CODE" VARCHAR2(16),
      "REQUESTED_AMT" NUMBER(8,2) DEFAULT 0 NOT NULL ENABLE,
      "APPROVED_AMT" NUMBER(8,2) DEFAULT 0 NOT NULL ENABLE,
      "APPROVED_FLAG" VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
      "REMARKS" VARCHAR2(256),
      "CREATED_BY" VARCHAR2(32),
      "DATE_MODIFIED" DATE,
      "MODIFIED_BY" VARCHAR2(32),
      "DATE_CREATED" DATE,
      "DT_PREPARED" DATE,
       CONSTRAINT "OPVD_PK" PRIMARY KEY ("TRAN_NO", "EMPL_EMPL_ID"),
       CONSTRAINT "OPVD_OPVH_FK" FOREIGN KEY ("TRAN_NO")
        REFERENCES "CMS_OP_VALE_HDR" ("TRAN_NO") ENABLE
       --CONSTRAINT "OPVD_EMPL_FK" FOREIGN KEY ("EMPL_EMPL_ID")
       -- REFERENCES "PMS_EMPLOYEES" ("EMPL_ID") ENABLE,
       --CONSTRAINT "OPVD_POSI_FK" FOREIGN KEY ("POSI_CODE")
       -- REFERENCES "PMS_POSITIONS" ("CODE") ENABLE,
       --CONSTRAINT "OPVD_VESS_FK" FOREIGN KEY ("VESS_CODE")
       -- REFERENCES "CMS_VESSELS" ("CODE") ENABLE
 );


create or replace public synonym CMS_OP_VALE_HDR for CMS_OP_VALE_HDR;
create or replace public synonym CMS_OP_VALE_DTL for CMS_OP_VALE_DTL;

exec sp_grant_access('TPJ_CMS%', 'CMS_OP_VALE%');
exec sp_grant_access('TPJ_PYS%', 'CMS_OP_VALE%');


alter table pys_payroll_dtl modify BASIC_RATE number(12,4);
alter table pys_payroll_dtl modify BASIC_RATE_G number(12,4);
alter table pys_payroll_dtl modify AMT number(12,4);
alter table pys_payroll_dtl modify AMT_G number(12,4);
alter table PYS_PAYROLL_SUMMARY modify BASIC_RATE number(12,4);
alter table PYS_PAYROLL_SUMMARY modify BASIC_RATE_G number(12,4);
alter table PYS_PAYROLL_SUMMARY modify L_BASIC_RATE number(12,4);
alter table PYS_PAYROLL_SUMMARY modify L_BASIC_RATE number(12,4);
alter table PYS_PAYROLL_SUMMARY modify AMOUNT number(12,4);
alter table PYS_PAYROLL_SUMMARY modify AMOUNT_G number(12,4);

alter table PYS_PAYROLL_DTL_LOG modify BASIC_RATE number(12,4);
alter table PYS_PAYROLL_DTL_LOG modify BASIC_RATE_G number(12,4);
alter table PYS_PAYROLL_DTL_LOG modify AMT number(12,4);
alter table PYS_PAYROLL_DTL_LOG modify AMT_G number(12,4);

revoke insert, delete on PMS_DEPARTMENTS from TPJ_PMS_MAINTENANCE_WRITE;
revoke insert, delete on PMS_RANKS from TPJ_PMS_MAINTENANCE_WRITE;
grant insert, update, delete on PMS_DEPARTMENTS to TPJ_PYS_MAINTENANCE_WRITE;
grant insert, update, delete on PMS_RANKS to TPJ_PYS_MAINTENANCE_WRITE;
grant insert, update, delete on PMS_DEPARTMENTS to TPJ_PYS_SUPER_USER;
grant insert, update, delete on PMS_RANKS to TPJ_PYS_SUPER_USER;


CREATE TABLE "CMS_REQUEST_VALE"
 (    "TRAN_NO" VARCHAR2(16) NOT NULL ENABLE,
      "TX_DATE" DATE NOT NULL ENABLE,
      "EMPL_EMPL_ID" VARCHAR2(16) NOT NULL ENABLE,
      "DEPT_CODE" VARCHAR2(16),
      "VESS_CODE" VARCHAR2(16),
      "POSI_CODE" VARCHAR2(16),
      "REQUESTED_AMT" NUMBER(8,2) DEFAULT 0 NOT NULL ENABLE,
      "APPROVED_AMT" NUMBER(8,2) DEFAULT 0 NOT NULL ENABLE,
      "REMARKS" VARCHAR2(256),
      "CREATED_BY" VARCHAR2(32),
      "DATE_MODIFIED" DATE,
      "MODIFIED_BY" VARCHAR2(32),
      "DATE_CREATED" DATE,
      "STATUS" VARCHAR2(16) DEFAULT 'FOR APPROVAL',
      "APPROVED_BY" VARCHAR2(16),
      "DT_APPROVED" DATE,
      "PY_STATUS" VARCHAR2(16) DEFAULT 'FOR APPROVAL',
      "POSTED_BY" VARCHAR2(16),
      "DT_POSTED" DATE,
      "CHECKED_BY" VARCHAR2(16),
      "DT_CHECKED" DATE,
      "MSG_RECEIVED_BY" VARCHAR2(16),
      "DT_MSG_RECEIVED" DATE,
      "PREPARED_BY" VARCHAR2(16),
      "DT_PREPARED" DATE,
       CONSTRAINT "CRVA_PK" PRIMARY KEY ("TRAN_NO")
 );

create or replace public synonym CMS_REQUEST_VALE for CMS_REQUEST_VALE;
exec sp_grant_access('TPJ_CMS%', 'CMS_REQUEST_VALE');
exec sp_grant_access('TPJ_PYS%', 'CMS_REQUEST_VALE');
exec sp_grant_access('TPJ_ACC%', 'CMS_REQUEST_VALE');
exec sp_grant_access('TPJ_PYS%', 'SPELL_NUMBER');
create or replace public synonym SPELL_NUMBER for SPELL_NUMBER;

alter table CMS_OP_VALE_HDR add curr_code varchar2(16) default 'PHP';
alter table CMS_OP_VALE_HDR add curr_conv number(12,6) default 0;

CREATE TABLE "ACC_REMITTANCES"
 (    "TRAN_NO" VARCHAR2(16) NOT NULL ENABLE,
      "TX_DATE" DATE NOT NULL ENABLE,
      "CURR_CODE" VARCHAR2(16) NOT NULL,
      "REMIT_AMT" NUMBER(8,2) DEFAULT 0 NOT NULL ENABLE,
      "ACCOUNT_NAME" VARCHAR2(64) NOT NULL,
      "ACCOUNT_NO" VARCHAR2(32) NOT NULL,
      "BANK_NAME" VARCHAR2(64) NOT NULL,
      "BANK_BRANCH" VARCHAR2(32) NOT NULL,
      "REF_TYPE" VARCHAR2(16) NOT NULL,
      "REF_CODE" VARCHAR2(16) NOT NULL,
      "STATUS" VARCHAR2(16) DEFAULT 'FOR APPROVAL',
      "REMARKS" VARCHAR2(256),
      "PREPARED_BY" VARCHAR2(16),
      "DT_PREPARED" DATE,
      "APPROVED_BY" VARCHAR2(16),
      "DT_APPROVED" DATE,
      "CREATED_BY" VARCHAR2(32),
      "DATE_MODIFIED" DATE,
      "MODIFIED_BY" VARCHAR2(32),
      "DATE_CREATED" DATE,
       CONSTRAINT "ACRE_PK" PRIMARY KEY ("TRAN_NO")
 );

create or replace public synonym ACC_REMITTANCES for ACC_REMITTANCES;
exec sp_grant_access('TPJ_ACC%', 'ACC_REMITTANCES');

alter table ACC_REMITTANCES add address_to varchar2(16);
alter table ACC_REMITTANCES add address_to_name varchar2(128);



CREATE TABLE "ACC_PCR_CASH_SUMMARY"
 (    "TX_DATE" DATE NOT NULL ENABLE,
      "TX_DESC" VARCHAR2(64),
      "PCR_NO" NUMBER(12,0),
      "BEG_BAL" NUMBER(12,2) DEFAULT 0 NOT NULL ENABLE,
      "CASHIER_CASH_COUNT" NUMBER(12,2) DEFAULT 0 NOT NULL ENABLE,
      "VAULT_CASH_COUNT" NUMBER(12,2) DEFAULT 0 NOT NULL ENABLE,
      "ACTUAL_CASH_COUNT" NUMBER(12,2) DEFAULT 0 NOT NULL ENABLE,
      "DT_FROM" DATE,
      "DT_TO" DATE,
      "APPROVED_BY" VARCHAR2(32),
      "DT_APPROVED" DATE,
      "PREPARED_BY" VARCHAR2(32),
      "DT_PREPARED" DATE,
      "CREATED_BY" VARCHAR2(32) NOT NULL ENABLE,
      "DT_CREATED" DATE NOT NULL ENABLE,
      "MODIFIED_BY" VARCHAR2(32),
      "DT_MODIFIED" DATE,
       CONSTRAINT "APCS_PK" PRIMARY KEY ("TX_DATE")
 );
create or replace public synonym ACC_PCR_CASH_SUMMARY for ACC_PCR_CASH_SUMMARY;
exec sp_grant_access('TPJ_ACC%', 'ACC_PCR_CASH_SUMMARY');
 

CREATE TABLE "ACC_PCR_CASH_SUMMARY_JVCV"
 (    "TX_DATE"     DATE NOT NULL ENABLE,
      "REF_TYPE"    VARCHAR2(4) NOT NULL ENABLE,
      "REF_CODE"    NUMBER(12,0) NOT NULL ENABLE,
      "REF_DATE"    DATE,
      "TX_AMT"      NUMBER(12,2) DEFAULT 0 NOT NULL,
      "REF_DESC"    VARCHAR2(256) NOT NULL ENABLE,
      "CREATED_BY"  VARCHAR2(32) NOT NULL ENABLE,
      "DT_CREATED"  DATE NOT NULL ENABLE,
      "MODIFIED_BY" VARCHAR2(32),
      "DT_MODIFIED" DATE,
       CONSTRAINT "CSJV_PK" PRIMARY KEY ("TX_DATE", "REF_TYPE", "REF_CODE"),
       CONSTRAINT "CSJV_APCS_FK" FOREIGN KEY ("TX_DATE")
        REFERENCES "ACC_PCR_CASH_SUMMARY" ("TX_DATE") ENABLE
 );
create or replace public synonym ACC_PCR_CASH_SUMMARY_JVCV for ACC_PCR_CASH_SUMMARY_JVCV;
exec sp_grant_access('TPJ_ACC%', 'ACC_PCR_CASH_SUMMARY_JVCV');
 

CREATE TABLE "ACC_PCR_CASH_SUMMARY_PCV"
 (    "TX_DATE"     DATE NOT NULL ENABLE,
      "CASH_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "MEALS_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "TRANSPO_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "FUELS_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "FINANCIAL_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "SUPPLIES_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "TAXES_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "REPAIR_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "VALE_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "ADVANCES_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "MISC_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "SUNDRY" VARCHAR2(22),
      "SUNDRY_AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "CREATED_BY" VARCHAR2(32) NOT NULL ENABLE,
      "DT_CREATED" DATE NOT NULL ENABLE,
      "MODIFIED_BY" VARCHAR2(32),
      "DT_MODIFIED" DATE,
       CONSTRAINT "CSPC_PK" PRIMARY KEY ("TX_DATE"),
       CONSTRAINT "CSPC_APCS_FK" FOREIGN KEY ("TX_DATE")
        REFERENCES "ACC_PCR_CASH_SUMMARY" ("TX_DATE") ENABLE
 );              
create or replace public synonym ACC_PCR_CASH_SUMMARY_PCV for ACC_PCR_CASH_SUMMARY_PCV;
exec sp_grant_access('TPJ_ACC%', 'ACC_PCR_CASH_SUMMARY_PCV');
 
CREATE TABLE "ACC_PCR_CASH_SUMMARY_DENO"
 (    "TX_DATE"     DATE NOT NULL ENABLE,
      "DENO" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "QTY" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "AMT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "CREATED_BY" VARCHAR2(32) NOT NULL ENABLE,
      "DT_CREATED" DATE NOT NULL ENABLE,
      "MODIFIED_BY" VARCHAR2(32),
      "DT_MODIFIED" DATE,
       CONSTRAINT "CSDE_PK" PRIMARY KEY ("TX_DATE", "DENO"),
       CONSTRAINT "CSDE_APCS_FK" FOREIGN KEY ("TX_DATE")
        REFERENCES "ACC_PCR_CASH_SUMMARY" ("TX_DATE") ENABLE
 );              

create or replace public synonym ACC_PCR_CASH_SUMMARY_DENO for ACC_PCR_CASH_SUMMARY_DENO;
exec sp_grant_access('TPJ_ACC%', 'ACC_PCR_CASH_SUMMARY_DENO');

create or replace public synonym SP_ACC_PCR_REPLENISHMENT for SP_ACC_PCR_REPLENISHMENT;
exec sp_grant_access('TPJ_ACC%', 'SP_ACC_PCR_REPLENISHMENT');
create or replace public synonym SP_ACC_PCR_JV for SP_ACC_PCR_JV;
exec sp_grant_access('TPJ_ACC%', 'SP_ACC_PCR_JV');

create or replace view acc_pcv_unreplenished as
select a.pcv_no, 
       b.pcr_no, 
       a.item_no, 
       a.acco_code, 
       a.particulars, 
       a.amt, 
       a.empl_empl_id, 
       a.dept_code, 
       b.pcv_date, 
       b.pcv_payee,
       b.pcv_status
from   acc_pcv_dtl a, acc_pcv_hdr b
where  a.pcv_no = b.pcv_no
and    a.amt > 0
union
select a.pcv_no, 
       b.pcr_no, 
       a.item_no, 
       a.acco_code, 
       a.particulars, 
       a.amt, 
       a.empl_empl_id, 
       a.dept_code, 
       b.pcv_date, 
       b.pcv_payee,
       b.pcv_status
from   acc_pcv_dtl a, acc_pcv_hdr b
where  a.pcv_no = b.pcv_no
and    b.pcv_status = 'REPLENISHED'
and    a.amt > 0
;

create or replace public synonym ACC_PCV_UNREPLENISHED for ACC_PCV_UNREPLENISHED;
exec sp_grant_access('TPJ_ACC%', 'ACC_PCV_UNREPLENISHED');


CREATE TABLE "ACC_PCR_RECEIPTS"
 (    "PCR_NO"      NUMBER(12,0) NOT NULL ENABLE,
      "REF_TYPE"    VARCHAR2(4) NOT NULL ENABLE,
      "REF_CODE"    NUMBER(12,0) NOT NULL ENABLE,
      "TX_DATE"     DATE,
      "TX_AMT"      NUMBER(12,2) DEFAULT 0 NOT NULL,
      "REF_DESC"    VARCHAR2(256),
      "CREATED_BY"  VARCHAR2(32) NOT NULL ENABLE,
      "DT_CREATED"  DATE NOT NULL ENABLE,
      "MODIFIED_BY" VARCHAR2(32),
      "DT_MODIFIED" DATE,
       CONSTRAINT "PRRE_PK" PRIMARY KEY ("PCR_NO", "REF_TYPE", "REF_CODE"),
       CONSTRAINT "PRRE_PRHD_FK" FOREIGN KEY ("PCR_NO")
        REFERENCES "ACC_PCR_HDR" ("PCR_NO") ENABLE
 );
create or replace public synonym ACC_PCR_RECEIPTS for ACC_PCR_RECEIPTS;
exec sp_grant_access('TPJ_ACC%', 'ACC_PCR_RECEIPTS');
 

DROP TABLE "ACC_PCR_JV";
DROP public synonym ACC_PCR_JV;
drop  procedure sp_acc_pcr_jv;
drop  public synonym sp_acc_pcr_jv;
DROP TABLE ACC_PCR_CASH_SUMMARY_PCV;
drop  public synonym ACC_PCR_CASH_SUMMARY_PCV;

alter table acc_jv_dtl add pcr_no number(12);
alter table acc_cv_dtl add pcr_no number(12);
alter table ACC_PCR_RECEIPTS modify REF_DESC null;


alter table CMS_REQUEST_VALE add vess_code varchar2(16);

delete cg_ref_codes where rv_domain = 'CRVA_STATUS';
insert into cg_ref_codes values ('CRVA_STATUS','APPROVED', NULL, NULL,'Approved');
insert into cg_ref_codes values ('CRVA_STATUS','FOR APPROVAL', NULL, NULL,'For Approval');
commit;

delete cg_ref_codes where rv_domain = 'CRVA_PY_STATUS';
insert into cg_ref_codes values ('CRVA_PY_STATUS','POSTED', NULL, NULL,'Posted');
insert into cg_ref_codes values ('CRVA_PY_STATUS','FOR POSTING', NULL, NULL,'For Posting');
commit;
update CMS_REQUEST_VALE set status='FOR APPROVAL', PY_STATUS='FOR POSTING';
commit;


create or replace public synonym SF_GET_ACC_EWT for SF_GET_ACC_EWT;
exec sp_grant_access('TPJ_ACC%', 'SF_GET_ACC_EWT');



create or replace view acc_vale_listing as
select v.tran_no, 
       v.tx_date, 
       v.status,
       v.empl_empl_id,
       v.vess_code,
       v.approved_amt,
       v.requested_amt
from  CMS_REQUEST_VALE v
where v.STATUS = 'APPROVED'
union
select v.tran_no, 
       v.tx_date, 
       v.status,
       null empl_empl_id,
       max(d.vess_code) vess_code,
       sum(d.approved_amt) approved_amt,
       sum(d.requested_amt) requested_amt
from  CMS_OP_VALE_HDR v, CMS_OP_VALE_DTL d
WHERE v.tran_no = d.tran_no
AND   v.status = 'APPROVED'
AND   v.released_outside = 'N'
group by  v.tran_no, 
       v.tx_date,
       v.status
order by tran_no, tx_date;

create or replace public synonym ACC_VALE_LISTING for ACC_VALE_LISTING;
exec sp_grant_access('TPJ_ACC%', 'ACC_VALE_LISTING');
