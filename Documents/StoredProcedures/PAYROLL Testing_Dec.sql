begin
   sp_payroll_computation_a (20081115, '2008','11',to_date('20081101','YYYYMMDD'),to_date('20081115','YYYYMMDD')); 
   commit;
end;

begin
   sp_payroll_computation_a (20081130, '2008','11',to_date('20081116','YYYYMMDD'),to_date('20081130','YYYYMMDD')); 
   commit;
end;

select * from pms_employees where empl_id = 'M00026'
select * from pys_employee_salary where empl_empl_id = 'M00026'

select * from pys_payroll_dtl
where  empl_empl_id = 'M00026'
and    pahd_payroll_no in  (20081215,20081231)

select * from pys_payroll_summary
where  empl_id = 'M00026'
and    payroll_no in (20081215,20081231)


select empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq, 
                    min(period_fr) period_fr, sum(no_days) no_days, sum(amt) amt, 
                    max(basic_rate_g) basic_rate_g, max(amt_g) amt_g, max(paty_code) paty_code
             from   pys_payroll_dtl
             where  pahd_payroll_no = 20081231
             and    empl_empl_id = 'T00019'
             and    paty_code like 'REG%'
             group  by empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq
             order  by empl_empl_id, period_to desc
             
select nvl(sum(no_days),0) ot_days, nvl(sum(amt),0) ot_amt
       from   pys_payroll_dtl
       where  pahd_payroll_no = 20081231
       and    empl_empl_id = 'T00019'
       and    paty_code like 'OT%'
       and    period_to between to_date('20081211','YYYYMMDD') and to_date('20081215','YYYYMMDD')

       
select * from pys_sss_contribution where period_to = to_date('20080930','YYYYMMDD') and empl_empl_id = 'V00001'
select * from pys_philhealth_contribution where period_to = to_date('20080930','YYYYMMDD') 

select * from pys_payroll_dtl_log
where  empl_empl_id = 'T00019'
and    payroll_no in (20081215,20081231)
order by pay_date

select emp.empl_id, emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name emp_fullname,
       max(pay.l_title_a) title, 
       max(pay.l_basic_rate_a) basic_rate, 
       sum(pay.no_days) no_days_2, 
       decode(max(pay.dept_code) , 'FL', sum(pay.no_days),1) no_days, 
       decode(max(sal_freq), 'MONTHLY',  decode(max(pay.dept_code) , 'FL', max(pay.l_basic_rate_a) * sum(pay.no_days), max(pay.l_basic_rate_a)) , 
                                         decode(max(pay.dept_code) , 'FL', max(pay.l_basic_rate_a)* sum(pay.no_days), max(pay.l_basic_rate_a)) ) amt, 
       sum(pay.pag_ibig_amt) pagibig, 
       sum(pay.pag_ibig_loan) pagibig_loan, 
       0 sal_loan, 
       sum(pay.sss_amt) sss, 
       sum(pay.sss_loan) sss_loan, 
       sum(pay.medicare) philhealth, 
       sum(pay.whtax) whtax
from   pms_employees emp, pys_payroll_summary pay, pys_payroll_hdr pahd
where  pay.empl_id = emp.empl_id
and     pay.empl_id = 'T00019'
and     pay.payroll_no = pahd.payroll_no
and     pahd.period_to between to_date('20081201','YYYYMMDD') and to_date('20081231','YYYYMMDD')
group by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name, emp.empl_id
having  max(pay.l_basic_rate_a) > 0
order by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name


select pay.*
from   pms_employees emp, pys_payroll_summary pay, pys_payroll_hdr pahd
where  pay.empl_id = emp.empl_id
and     pay.empl_id = 'T00019'
and     pay.payroll_no = pahd.payroll_no
and     pahd.period_to between to_date('20081201','YYYYMMDD') and to_date('20081231','YYYYMMDD')


select * from pys_payroll_dtl_log
where  empl_empl_id = 'V00001'
and    payroll_no in (20081015,20080930)

select sf_get_latest_embark('S00007', to_date('20080912','YYYYMMDD')) from dual

select * from cms_voyage_crew where empl_empl_id = 'S00007' order by dt_embarked

select *
from   pms_attendance_records a
where  a.empl_empl_id = 'M00026' 
and    a.att_date between to_date('20080826', 'YYYYMMDD') and to_date('20080915','YYYYMMDD') 


update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where (empl_empl_id,pay_date) in (
select empl_empl_id, pay_date, vess_code, dept_code from pys_payroll_dtl_log where pay_date between to_date('20080826', 'YYYYMMDD') and to_date('20080831','YYYYMMDD') and cola_day=0 and dept_code <> 'FL' 
)
commit

select empl_empl_id, att_date, outer_port, num_hours, ot_hours, am_time_in 
from pms_attendance_records where empl_empl_id = 'D00016' order by att_date desc

--Adjustment Pay
select posi_code,
       title,
       dept_code,
       oport,
       basic_rate,
       a_posi_code,
       a_title,
       a_dept_code,
       a_oport,
       a_basic_rate,
       min(pay_date)                 dStart,
       max(pay_date)                 dEnd,
       sum(nDays)                    nNumday,
       sum(AMT)                      nSalaryR,
       sum(A_nDays)                  nANumday,
       sum(A_AMT)                    nASalaryR
from   pys_payroll_dtl_log
where  empl_empl_id = 'M00026'
and    pay_date between to_date('20080826', 'YYYYMMDD') and to_date('20080831','YYYYMMDD')
and    a_ndays > 0
group  by posi_code,
       title,
       dept_code,
       oport,
       basic_rate,
       a_posi_code,
       a_title,
       a_dept_code,
       a_oport,
       a_basic_rate

--Adjustment OT's
select posi_code,
       title,
       decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE) basic_rate,
       dept_code,
       oport,
       min(pay_date)               dStart,
       max(pay_date)               dEnd,
       sum(decode(nDays,0,0,1))    nActDay,
       sum(nDays)                  nNumday,
       sum(AMT)                    nSalaryR,
       sum(decode(OT_PAY,0,0,OT_PAY))   nOtDays,
       sum(OT_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nOtPay,
       sum(decode(SU_PAY,0,0,SU_PAY))   nSuDays,
       sum(SU_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nSuPay,
       sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
       sum(HO_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHoPay,
       sum(decode(HT_PAY,0,0,HT_PAY))   nHSDays,
       sum(HT_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHSPay
from   pys_payroll_dtl_log
where  empl_empl_id = 'L00012'
and    pay_date  between to_date('20080826', 'YYYYMMDD') and to_date('20080910','YYYYMMDD')
group  by  posi_code, title, dept_code, oport, decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE) 

select * from pys_payroll_a a
where a.empl_empl_id = 'E00010'
and   a.pahd_payroll_no = 20080831

select payroll_no, period_fr
from   pys_payroll_hdr
where  period_fr =  to_date('20080416','YYYYMMDD')


    select pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, posi_code, title, 
           basic_rate, vess_code, dept_code, sal_freq, latest_vess
    from   pys_payroll_dtl
    where  empl_empl_id = 'O00003'
    and    paty_code like 'REG%'
    and    pahd_payroll_no <= 20080831
    order  by period_to desc

PAYSLIP (OT)
select a.empl_empl_id int_empl_id, 
         a.paty_code int_paty_code, 
         b.description int_code, 
         ' ' int_fiso,
         a.basic_rate int_rate, 
         decode(a.dept_code,'FL',a.no_days/sf_get_ot_rates(a.paty_code),
                                 (a.no_days/sf_get_ot_rates(a.paty_code))*8) int_qty, 
         a.amt int_amt, vess_code int_vess_code, dept_code int_dept_code  
from   pys_payroll_dtl a, pys_payroll_types b
where  a.paty_code like 'OT%'
and    a.paty_code = b.code
and    a.pahd_payroll_no = 20080915
and    a.empl_empl_id = 'L00012'

--Adjustment COLA
select posi_code,
       title,
       dept_code,
       a_posi_code,
       a_title,
       a_dept_code,
       min(pay_date)   dStart,
       max(pay_date)   dEnd,
       sum(cola_day)   nColaDay,
       sum(cola_pay)   nColaPay,
       sum(a_cola_day) nAColaDay,
       sum(a_cola_pay) nAColaPay
from   pys_payroll_dtl_log
where  empl_empl_id = 'M00026'
and    pay_date between to_date('20080826', 'YYYYMMDD') and to_date('20080831','YYYYMMDD')
group  by posi_code,
       title,
       dept_code,
       a_posi_code,
       a_title,
       a_dept_code,
       a_oport,
       a_basic_rate
       
select a_posi_code,
       a_title,
       a_dept_code,
       a_basic_rate,
       min(pay_date)   dStart,
       max(pay_date)   dEnd,
       sum(cola_day)   nColaDay,
       sum(cola_pay)   nColaPay,
       sum(a_cola_day) nAColaDay,
       sum(a_cola_pay) nAColaPay
from   pys_payroll_dtl_log
where  empl_empl_id = 'M00026'
and    pay_date between to_date('20080826', 'YYYYMMDD') and to_date('20080831','YYYYMMDD')
group  by a_posi_code,
       a_title,
       a_dept_code,
       a_basic_rate
       
begin
   sp_payroll_summary (20080115);
   sp_payroll_summary (20080131);
   sp_payroll_summary (20080215);
   sp_payroll_summary (20080229);
   sp_payroll_summary (20080315);
   sp_payroll_summary (20080331);
   sp_payroll_summary (20080415);
   sp_payroll_summary (20080430);
   sp_payroll_summary (20080515);
   sp_payroll_summary (20080531);
   sp_payroll_summary (20080615);
   sp_payroll_summary (20080630);
   sp_payroll_summary (20080715);
   sp_payroll_summary (20080731);
   sp_payroll_summary (20080815);
   sp_payroll_summary (20080831);
   sp_payroll_summary (20080915);
   sp_payroll_summary (20080930);
   sp_payroll_summary (20081015);
   sp_payroll_summary (20081031);
end;

select * from pms_employees where last_name = 'VALENCIA'

exec sp_recompute_13month (20071215, 20071231);
exec sp_recompute_13month (20080115, 20080131);
exec sp_recompute_13month (20080215, 20080229);
exec sp_recompute_13month (20080315, 20080331);
exec sp_recompute_13month (20080415, 20080430);
exec sp_recompute_13month (20080515, 20080531);
exec sp_recompute_13month (20080615, 20080630);
exec sp_recompute_13month (20080715, 20080731);
exec sp_recompute_13month (20080815, 20080831);
exec sp_recompute_13month (20080915, 20080930);
exec sp_recompute_13month (20081015, 20081031);
exec sp_recompute_13month (20081115, 20081130);


begin
 sp_recompute_13month (20071215, 20071231);
 sp_recompute_13month (20080115, 20080131);
 sp_recompute_13month (20080215, 20080229);
 sp_recompute_13month (20080315, 20080331);
 sp_recompute_13month (20080415, 20080430);
 sp_recompute_13month (20080515, 20080531);
 sp_recompute_13month (20080615, 20080630);
 sp_recompute_13month (20080715, 20080731);
 sp_recompute_13month (20080815, 20080831);
 sp_recompute_13month (20080915, 20080930);
 sp_recompute_13month (20081015, 20081031);
 sp_recompute_13month (20081115, 20081130);
 commit;
end;

select * from  pys_13th_month_summary where empl_id = 'A00001'


select empl_id s_empl_id, basic_rate s_basic_rate, sum(nMon) n_mon from (
                      select pay.empl_id, to_char(pahd.period_to,'YYYYMM') cur_mon, 
                             decode(max(pay.dept_code),'FL',nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate),'MA-CREW',max(pay.l_basic_rate_a)-max(pay.cola_rate),nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))/30)  basic_rate, 
                             decode(greatest(sum(pay.no_days),15),15,.5,1) nMon
                      from   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
                      where  pay.payroll_no = pahd.payroll_no
                      and    pay.empl_id = 'A00001'
                      group  by pay.empl_id, to_char(pahd.period_to,'YYYYMM') 
        )
group  by empl_id , basic_rate
order by basic_rate
                      