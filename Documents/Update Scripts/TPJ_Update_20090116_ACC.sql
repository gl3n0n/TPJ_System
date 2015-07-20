DROP TABLE "ACC_JV_INV_DTL";
DROP PUBLIC SYNONYM "ACC_JV_INV_DTL";

CREATE TABLE "TPJ"."ACC_AP_INV_DTL"
 (    "AP_NO" NUMBER(12,0) NOT NULL ENABLE,
      "ITEM_NO" NUMBER(4,0) NOT NULL ENABLE,
      "RR_NO" VARCHAR2(16) NOT NULL ENABLE,
      "RS_NO" VARCHAR2(16),
      "PO_NO" VARCHAR2(32),
      "INVOICE_NO" VARCHAR2(256) NOT NULL ENABLE,
      "RR_AMOUNT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "AMOUNT" NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
      "RR_DATE" DATE,
      "IS_SELECTED" VARCHAR2(1) DEFAULT 'N' NOT NULL ENABLE,
      "CREATED_BY" VARCHAR2(32) NOT NULL ENABLE,
      "DT_CREATED" DATE NOT NULL ENABLE,
      "MODIFIED_BY" VARCHAR2(32),
      "DT_MODIFIED" DATE,
       CONSTRAINT "APIN_PK" PRIMARY KEY ("AP_NO", "ITEM_NO")
USING INDEX PCTFREE 10 INITRANS 2 MAXTRANS 255
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
TABLESPACE "USERS"  ENABLE,
       CONSTRAINT "APIN_APHD_FK" FOREIGN KEY ("AP_NO")
        REFERENCES "TPJ"."ACC_AP_HDR" ("AP_NO") ENABLE
 ) PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 NOCOMPRESS LOGGING
STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1 BUFFER_POOL DEFAULT)
TABLESPACE "USERS";

PROMPT Creating Foreign Key on 'ACC_AP_INV_DTL'
ALTER TABLE ACC_AP_INV_DTL ADD (CONSTRAINT
 APIN_DRHD_FK FOREIGN KEY 
  (RR_NO) REFERENCES INV_DR_HDR
  (DR_NO))
/


alter table acc_ap_hdr add (
  supp_Code varchar2(16),
  period_fr date,
  period_to date,
  particulars varchar2(256),
  vat_inc varchar2(1) default 'N' not null
);

alter table acc_ap_hdr modify (
   ap_ref_no null
);

alter table inv_dr_hdr add (
	 rr_amt  number(12,2) default 0 not null,
	 rr_paid number(12,2) default 0 not null
);

begin
	for i in (select h.dr_no rr_no, sum(d.total_cost) rr_amt
	          from   inv_dr_hdr h, inv_dr_dtl d
	          where  h.dr_no = d.drhd_dr_no
	          group  by h.dr_no)
   loop
      update inv_dr_hdr 
      set    rr_amt = i.rr_amt
      where  dr_no = i.rr_no;
   end loop;
end;
/

alter table acc_cpa_dtl modify acco_code null;
alter table acc_cpa_dtl add amount number(12,2) default 0 not null;

alter table acc_cv_hdr modify (
	bank_code null,
	comp_code null
);

alter table acc_banks modify acco_code null;

exec sp_grant_access('TPJ_ACC%', 'SP_ACC%');
exec sp_grant_access('TPJ_ACC%', 'ACC%');
