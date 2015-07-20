alter table pys_payroll_dtl modify no_days number(10,5);
alter table pys_payroll_dtl_log  modify ndays number(10,5);
alter table pys_payroll_dtl_log  modify ndays number(10,5);
alter table pys_payroll_dtl_log  modify ot_pay number(10,5);
alter table pys_payroll_dtl_log  modify su_pay number(10,5);
alter table pys_payroll_dtl_log  modify ho_pay number(10,5);
alter table pys_payroll_dtl_log  modify hs_pay number(10,5);
alter table pys_payroll_dtl_log  modify ht_pay number(10,5);
alter table pys_payroll_dtl_log  modify a_ot_pay number(10,5);
alter table pys_payroll_dtl_log  modify a_su_pay number(10,5);
alter table pys_payroll_dtl_log  modify a_ho_pay number(10,5);
alter table pys_payroll_dtl_log  modify a_hs_pay number(10,5);
alter table pys_payroll_dtl_log  modify a_ht_pay number(10,5);



  DROP TABLE PYS_PAYROLL_DTL_ADJ_LOG;
  CREATE TABLE PYS_PAYROLL_DTL_ADJ_LOG
   (    PAHD_PAYROLL_NO NUMBER(8,0) NOT NULL,
        SEQ_NO NUMBER(12,0) NOT NULL,
        EMPL_EMPL_ID VARCHAR2(16) NOT NULL,
        PATY_CODE VARCHAR2(16),
        DEDU_SEQ_NO NUMBER(12,0),
        DETY_CODE VARCHAR2(16),
        PERIOD_FR DATE,
        PERIOD_TO DATE,
        NO_DAYS NUMBER(10,5),
        BASIC_RATE NUMBER(10,2) DEFAULT 0 NOT NULL,
        BASIC_RATE_G NUMBER(10,2) DEFAULT 0 NOT NULL,
        AMT NUMBER(10,2) NOT NULL,
        AMT_G NUMBER(10,2) DEFAULT 0 NOT NULL,
        POSI_CODE VARCHAR2(16),
        VESS_CODE VARCHAR2(16),
        TITLE VARCHAR2(32),
        DEPT_CODE VARCHAR2(16),
        LATEST_VESS VARCHAR2(16),
        SAL_FREQ VARCHAR2(16),
        A_PERIOD_FR DATE,
        A_PERIOD_TO DATE,
        A_NO_DAYS NUMBER(10,5),
        A_BASIC_RATE NUMBER(10,2) DEFAULT 0 NOT NULL,
        A_BASIC_RATE_G NUMBER(10,2) DEFAULT 0 NOT NULL,
        A_AMT NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
        A_AMT_G NUMBER(10,2) DEFAULT 0 NOT NULL ENABLE,
        A_POSI_CODE VARCHAR2(16),
        A_VESS_CODE VARCHAR2(16),
        A_TITLE VARCHAR2(32),
        A_DEPT_CODE VARCHAR2(16),
        A_LATEST_VESS VARCHAR2(16),
        A_SAL_FREQ VARCHAR2(16),
        PAY_FLAG VARCHAR2(4) DEFAULT 'ADD',
        ADJ_ACTION VARCHAR2(12) DEFAULT 'UPDATE' NOT NULL,
        ADJ_REMARKS VARCHAR2(128),
        ADJ_APPROVAL VARCHAR2(1),
        ADJ_APPROVED_BY VARCHAR2(32),
        ADJ_APPROVED_DT DATE,
        ADJUSTED VARCHAR2(1) DEFAULT 'N' NOT NULL,
        CREATED_BY VARCHAR2(32) NOT NULL,
        DT_CREATED DATE NOT NULL,
        MODIFIED_BY VARCHAR2(32),
        DT_MODIFIED DATE,
         CONSTRAINT PDJL_PK PRIMARY KEY (PAHD_PAYROLL_NO, SEQ_NO),
         CONSTRAINT PDJL_DEDU_FK FOREIGN KEY (DEDU_SEQ_NO)
          REFERENCES PYS_DEDUCTIONS (SEQ_NO) ENABLE,
         CONSTRAINT PDJL_DETY_FK FOREIGN KEY (DETY_CODE)
          REFERENCES PYS_DEDUCTION_TYPES (CODE) ENABLE,
         CONSTRAINT PDJL_EMPL_FK FOREIGN KEY (EMPL_EMPL_ID)
          REFERENCES PMS_EMPLOYEES (EMPL_ID) ENABLE,
         CONSTRAINT PDJL_PAHD_FK FOREIGN KEY (PAHD_PAYROLL_NO)
          REFERENCES PYS_PAYROLL_HDR (PAYROLL_NO) ENABLE,
         CONSTRAINT PDJL_PATY_FK FOREIGN KEY (PATY_CODE)
          REFERENCES PYS_PAYROLL_TYPES (CODE) ENABLE
   );
   