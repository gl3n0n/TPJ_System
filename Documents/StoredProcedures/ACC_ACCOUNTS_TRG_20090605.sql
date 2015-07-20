alter table acc_banks drop constraint ACBN_ACCO_FK;

CREATE OR REPLACE TRIGGER acc_accounts_trg
BEFORE INSERT 
ON ACC_ACCOUNTS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   nPos Number;
BEGIN
   IF replace(upper(:new.name),' ','') like 'CASHINBANK%' then
      nPos := instr(upper(:new.name), 'BANK', 1, 1);
      insert into acc_banks 
             (code, name, account_type, acco_code, created_by, dt_created)
      values (:new.code, ltrim(replace(substr(:new.name, nPos+5), '-',' ')), 'CURRENT', :new.code, user, sysdate);
   END IF;
EXCEPTION
   when dup_val_on_index then null;
END acc_accounts_trg;
/


CREATE OR REPLACE TRIGGER acc_accounts_upd_trg
BEFORE UPDATE 
ON ACC_ACCOUNTS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   nPos Number;
BEGIN
   IF replace(upper(:new.name),' ','') like 'CASHINBANK%' then
      nPos := instr(upper(:new.name), 'BANK', 1, 1);
      insert into acc_banks 
             (code, name, account_type, acco_code, created_by, dt_created)
      values (:new.code, ltrim(replace(substr(:new.name, nPos+5), '-',' ')), 'CURRENT', :new.code, user, sysdate);
   END IF;
EXCEPTION
   when dup_val_on_index then null;
END acc_accounts_upd_trg;
/




create table acc_cv_check_dtl 
 (    CV_NO NUMBER(12,0) NOT NULL,
      BANK_CODE VARCHAR2(16),
      PRNACCT_DESC VARCHAR2(64),
      PRNACCT_AMT NUMBER(10,2),
      PRNBANK_NAME VARCHAR2(64),
      PRNCHECK_NO VARCHAR2(32),
      PRNCHECK_DATE DATE,
      PRNCHECK_AMT NUMBER(10,2),
      CREATED_BY VARCHAR2(32) NOT NULL,
      DT_CREATED DATE NOT NULL,
      MODIFIED_BY VARCHAR2(32),
      DT_MODIFIED DATE,
       CONSTRAINT CVCD_PK PRIMARY KEY (CV_NO, BANK_CODE),
       CONSTRAINT CVCD_CVHD_FK FOREIGN KEY (CV_NO)
        REFERENCES ACC_CV_HDR (CV_NO),
       CONSTRAINT CVCD_BANK_FK FOREIGN KEY (BANK_CODE)
        REFERENCES ACC_BANKS (CODE)
 );

