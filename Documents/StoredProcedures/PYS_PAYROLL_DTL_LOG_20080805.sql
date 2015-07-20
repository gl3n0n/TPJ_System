drop TABLE PYS_PAYROLL_DTL_LOG;

CREATE TABLE PYS_PAYROLL_DTL_LOG
 (    EMPL_EMPL_ID   VARCHAR2(16) NOT NULL,
      PAY_DATE       DATE,
      DEPT_CODE      VARCHAR2(16),
      VESS_CODE      VARCHAR2(16),
      POSI_CODE      VARCHAR2(16),
      TITLE          VARCHAR2(32),
      SAL_FREQ       VARCHAR2(16) DEFAULT 'SEMI-MO' NOT NULL,
      LATEST_VESS    VARCHAR2(32),
      BASIC_RATE     NUMBER(10,2) DEFAULT 0 NOT NULL,
      BASIC_RATE_G   NUMBER(10,2) DEFAULT 0 NOT NULL,
      NDAYS          NUMBER(10,3) DEFAULT 0 NOT NULL,
      AMT            NUMBER(10,2) DEFAULT 0 NOT NULL,
      AMT_G          NUMBER(10,2) DEFAULT 0 NOT NULL,
      OT_PAY         NUMBER(10,3) DEFAULT 0 NOT NULL,
      SU_PAY         NUMBER(10,3) DEFAULT 0 NOT NULL,
      HO_PAY         NUMBER(10,3) DEFAULT 0 NOT NULL,
      HS_PAY         NUMBER(10,3) DEFAULT 0 NOT NULL,
      HT_PAY         NUMBER(10,3) DEFAULT 0 NOT NULL,
      COLA_PAY       NUMBER(10,3) DEFAULT 0 NOT NULL,
      OPORT          VARCHAR2(1)  DEFAULT 'N' NOT NULL,
      A_VESS_CODE    VARCHAR2(16),
      A_DEPT_CODE    VARCHAR2(16),
      A_POSI_CODE    VARCHAR2(16),
      A_TITLE        VARCHAR2(32),
      A_BASIC_RATE   NUMBER(10,2) DEFAULT 0 NOT NULL,
      A_BASIC_RATE_G NUMBER(10,2) DEFAULT 0 NOT NULL,
      A_NDAYS        NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_AMT          NUMBER(10,2) DEFAULT 0 NOT NULL,
      A_AMT_G        NUMBER(10,2) DEFAULT 0 NOT NULL,
      A_OT_PAY       NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_SU_PAY       NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_HO_PAY       NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_HS_PAY       NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_HT_PAY       NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_COLA_PAY     NUMBER(10,3) DEFAULT 0 NOT NULL,
      A_OPORT        VARCHAR2(1)  DEFAULT 'N' NOT NULL,
      PAYROLL_NO     NUMBER NOT NULL,
      CREATED_BY     VARCHAR2(32) NOT NULL,
      DT_CREATED     DATE NOT NULL,
      MODIFIED_BY    VARCHAR2(32),
      DT_MODIFIED    DATE,
       CONSTRAINT    PADL_PK PRIMARY KEY (EMPL_EMPL_ID, PAY_DATE),
       CONSTRAINT    PADL_EMPL_FK FOREIGN KEY (EMPL_EMPL_ID)
                     REFERENCES PMS_EMPLOYEES (EMPL_ID),
       CONSTRAINT    PADL_VESS_FK FOREIGN KEY (VESS_CODE)
                     REFERENCES CMS_VESSELS (CODE)
 );

create index padl_pay_date_idx on pys_payroll_dtl_log (PAY_DATE);
create index padl_payroll_no_idx on pys_payroll_dtl_log (PAYROLL_NO);
alter table pys_payroll_dtl modify no_days number(8,3);