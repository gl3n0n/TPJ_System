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
