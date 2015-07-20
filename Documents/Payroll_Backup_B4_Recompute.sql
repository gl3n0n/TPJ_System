-- create backup
   create table PYS_PAYROLL_DTL_201207312 AS select * from PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731;
   create table PYS_PAY_DTL_ADJ_LOG_201207312 AS select * from PYS_PAYROLL_DTL_ADJ_LOG WHERE pahd_payroll_no = 20120731;
   create table PYS_SSS_CONT_201207312 AS select * from PYS_SSS_CONTRIBUTION WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   create table PYS_PAGIBIG_CONT_201207312 AS select * from PYS_PAGIBIG_CONTRIBUTION WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   create table PYS_PHILHEALTH_CONT_201207312 AS select * from PYS_PHILHEALTH_CONTRIBUTION WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   create table PYS_PAYROLL_DTL_LOG_201207312 AS select * from PYS_PAYROLL_DTL_LOG WHERE payroll_no = 20120731 AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   create table PYS_PAYROLL_SUMMARY_201207312 AS select * from PYS_PAYROLL_SUMMARY WHERE  payroll_no = 20120731;
   create table PYS_13TH_MO_SUMMARY_201207312 AS select * from PYS_13TH_MONTH_SUMMARY;

   select count(1) from PYS_PAYROLL_DTL_20120731;
   select count(1) from PYS_PAY_DTL_ADJ_LOG_20120731;
   select count(1) from PYS_SSS_CONT_20120731;
   select count(1) from PYS_PAGIBIG_CONT_20120731;
   select count(1) from PYS_PHILHEALTH_CONT_20120731;
   select count(1) from PYS_PAYROLL_DTL_LOG_20120731;
   select count(1) from PYS_PAYROLL_SUMMARY_20120731;
   select count(1) from PYS_13TH_MO_SUMMARY_20120731;


-- for restore (delete then re-insert)
   delete from PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731;
   delete from PYS_PAYROLL_DTL_ADJ_LOG WHERE pahd_payroll_no = 20120731;
   delete from PYS_SSS_CONTRIBUTION WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   delete from PYS_PAGIBIG_CONTRIBUTION WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   delete from PYS_PHILHEALTH_CONTRIBUTION WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id  IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   delete from PYS_PAYROLL_DTL_LOG WHERE payroll_no = 20120731 AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   delete from PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731;
   delete from PYS_PAYROLL_DTL_ADJ_LOG WHERE pahd_payroll_no = 20120731;
   delete from PYS_PAYROLL_SUMMARY WHERE  payroll_no = 20120731;
   delete from PYS_13TH_MONTH_SUMMARY;


   insert into PYS_PAYROLL_DTL select * from PYS_PAYROLL_DTL_20120731;
   insert into PYS_PAYROLL_DTL_ADJ_LOG select * from PYS_PAY_DTL_ADJ_LOG_20120731;
   insert into PYS_SSS_CONTRIBUTION select * from PYS_SSS_CONT_20120731 WHERE period_to = to_date('20120731', 'YYYYMMDD') AND empl_empl_id IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731);
   insert into PYS_PAGIBIG_CONTRIBUTION select * from PYS_PAGIBIG_CONT_20120731;
   insert into PYS_PHILHEALTH_CONTRIBUTION select * from PYS_PHILHEALTH_CONT_20120731;
   insert into PYS_PAYROLL_DTL_LOG select * from PYS_PAYROLL_DTL_LOG_20120731;
   insert into PYS_PAYROLL_SUMMARY select * from PYS_PAYROLL_SUMMARY_20120731;
   insert into PYS_13TH_MONTH_SUMMARY select * from PYS_13TH_MO_SUMMARY_20120731;


-- drop
   drop table PYS_PAYROLL_DTL_20120731;
   drop table PYS_PAY_DTL_ADJ_LOG_20120731;
   drop table PYS_SSS_CONT_20120731;
   drop table PYS_PAGIBIG_CONT_20120731;
   drop table PYS_PHILHEALTH_CONT_20120731;
   drop table PYS_PAYROLL_DTL_LOG_20120731;
   drop table PYS_PAYROLL_SUMMARY_20120731;
   drop table PYS_13TH_MO_SUMMARY_20120731;

   delete from PYS_PAYROLL_DTL WHERE pahd_payroll_no = 20120731 and empl_empl_id = 'S00038';
   insert into PYS_PAYROLL_DTL select * from PYS_PAYROLL_DTL_201207312 WHERE pahd_payroll_no = 20120731 and empl_empl_id = 'S00038';
   delete from PYS_PAYROLL_SUMMARY WHERE  payroll_no = 20120731 and empl_id = 'S00038';
   insert into PYS_PAYROLL_SUMMARY select * from PYS_PAYROLL_SUMMARY_201207312 WHERE payroll_no = 20120731 and empl_id = 'S00038';
   delete from PYS_13TH_MONTH_SUMMARY WHERE empl_empl_id = 'S00038' and period_to =;
   