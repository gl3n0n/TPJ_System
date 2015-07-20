update pys_payroll_dtl 
set amt_g = amt_g * -1
where paty_code = 'REG-ADJ' and amt < 0 and amt_g > 0 and dept_code = 'FL';
commit;


CREATE TABLE PYS_13TH_MONTH_SUMMARY
 (    EMPL_ID    VARCHAR2(16) NOT NULL,
      PERIOD_FR  DATE NOT NULL,
      PERIOD_TO  DATE NOT NULL,
      DEPT_CODE  VARCHAR2(16) NOT NULL,
      VESS_CODE  VARCHAR2(16),
      TITLE      VARCHAR2(32),
      m_13_amt   NUMBER(8,2) default 0,
      silp_amt   NUMBER(8,2) default 0,
      m_13_amt_a NUMBER(8,2) default 0,
      silp_amt_a NUMBER(8,2) default 0,
      constraint p13su_pk primary key (EMPL_ID, PERIOD_FR, PERIOD_TO)
 ) ;

alter table pys_tax_header add non_tax_13th number(8,2) default 0;
update pys_tax_header set non_tax_13th=30000;
commit;
