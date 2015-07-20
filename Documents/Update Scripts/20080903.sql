select emp.empl_id,                                               select emp.empl_id,                                                                                                        
       pay.period_to d_period_to,                                        decode(:P_VESSEL,'_OFC',sp_get_latest_period_b (emp.empl_id ,pay.period_to, :P_PAY_NO),pay.period_to) d_period_to,  
       sum(pay.ot) d_amt,                                                sum(pay.ot) d_amt,                                                                                                  
       sum(pay.pagibig) pagibig,                                         sum(pay.pagibig) pagibig,                                                                                           
       sum(pay.pagibig_loan) pagibig_loan,                               sum(pay.pagibig_loan) pagibig_loan,                                                                                 
       0 sal_loan, sum(pay.sss) sss,                                     0 sal_loan, sum(pay.sss) sss,                                                                                       
       sum(pay.sss_loan) sss_loan,                                       sum(pay.sss_loan) sss_loan,                                                                                         
       sum(pay.philhealth) philhealth,                                   sum(pay.philhealth) philhealth,                                                                                     
       sum(pay.whtax) whtax,                                             sum(pay.whtax) whtax,                                                                                               
       0 ot, sum(pay.cola) d_cola,                                       0 ot, sum(pay.cola) d_cola,                                                                                         
       sum(pay.vale) vale,                                               sum(pay.vale) vale,                                                                                                 
       sum(pay.no_days) d_no_days                                        sum(pay.no_days) d_no_days                                                                                          
from   pms_employees emp, pys_payroll_summary_b pay               from   pms_employees emp, pys_payroll_b pay                                                                                
where  pay.empl_empl_id = emp.empl_id                             where  pay.empl_empl_id = emp.empl_id                                                                                      
and    pay.pahd_payroll_no = :P_PAY_NO                            and    pay.pahd_payroll_no = :P_PAY_NO                                                                                     
and    pay.basic_rate = 0                                         and    pay.basic_rate = 0                                                                                                  
&CF_VESSEL                                                        &CF_VESSEL                                                                                                                 
group by emp.empl_id, decode(:P_VESSEL,'_OFC',                    group by emp.empl_id, decode(:P_VESSEL,'_OFC',sp_get_latest_period_b (emp.empl_id ,pay.period_to, :P_PAY_NO),pay.period_to)
      sp_get_latest_period_b (emp.empl_id ,pay.period_to, 
      :P_PAY_NO),pay.period_to)

select emp.empl_id       h_empl_id, 
          pay.payroll_no pay_no,
          emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name h_fullname,
          pay.title      h_title, 
          pay.basic_rate h_basic_rate, 
          period_to      h_period_to,
          pay.no_days    h_no_days, 
          pay.amt        h_amt, 
          pay.sal_freq   h_sal_freq, 
          pay.dept_code  h_dept,
          pat.ot_amt     d_ot,
          pay.ot_days    d_ot_days,
          pay.pag_ibig_amt  pagibig,          
          pay.pag_ibig_loan pagibig_loan,
          0              sal_loan
          pay.sss_amt    sss,      
          pay.sss_loan   sss_loan,        
          pay.medicare   philhealth,    
          pay.whtax      whtax,              
          0              ot, 
          pay.cola       d_cola,        
          pay.vale       vale
from   pms_employees emp, pys_payroll_summary_b pay
where  pay.empl_empl_id = emp.empl_id
and    pay.pahd_payroll_no = :P_PAY_NO
&CF_VESSEL
group by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name, emp.empl_id, pay.title, pay.basic_rate, pay.period_to, pay.pahd_payroll_no
order by  emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name, pay.period_to asc


drop table pys_payroll_summary;
create table pys_payroll_summary (
   payroll_no    number(8) not null,
   period_fr     date not null,
   period_to     date not null,
   empl_id       varchar2(16) not null,
   dept_code     varchar2(16) not null,
   vess_code     varchar2(16),
   sal_freq      varchar2(16),
   title         varchar2(32),
   basic_rate    number(8,2) not null,
   no_days       number(8,4) not null,
   amount        number(8,2) not null,
   cola_amt      number(8,2) not null,
   cola_day      number(8,4) not null,
   cola_rate     number(8,2) not null,
   ot_amt        number(8,2) not null,
   ot_day        number(8,4) not null,
   pag_ibig_amt  number(8,2) not null,
   pag_ibig_loan number(8,2) not null,
   sss_amt       number(8,2) not null,
   sss_loan      number(8,2) not null,
   medicare      number(8,2) not null,
   whtax         number(8,2) not null,
   vale          number(8,2) not null,
   net_amount    number(8,2) not null,
   basic_rate_g  number(8,2) not null,
   amount_g      number(8,2) not null,
   l_basic_rate  number(8,2),
   l_vess_code   varchar2(16),
   l_title       varchar2(32),
   l_basic_rate_a  number(8,2),
   l_vess_code_a   varchar2(16),
   l_title_a       varchar2(32)
);

create index pasu_payno_idx on pys_payroll_summary(payroll_no);
create index pasu_empl_idx on pys_payroll_summary(empl_id, payroll_no);


truncate table pys_payroll_summary;
exec SP_PAYROLL_SUMMARY(20080115);
exec SP_PAYROLL_SUMMARY(20080131);
exec SP_PAYROLL_SUMMARY(20080215);
exec SP_PAYROLL_SUMMARY(20080229);
exec SP_PAYROLL_SUMMARY(20080315);
exec SP_PAYROLL_SUMMARY(20080331);
exec SP_PAYROLL_SUMMARY(20080415);
exec SP_PAYROLL_SUMMARY(20080430);
exec SP_PAYROLL_SUMMARY(20080515);
exec SP_PAYROLL_SUMMARY(20080531);
exec SP_PAYROLL_SUMMARY(20080615);
exec SP_PAYROLL_SUMMARY(20080630);
exec SP_PAYROLL_SUMMARY(20080715);
exec SP_PAYROLL_SUMMARY(20080731);
exec SP_PAYROLL_SUMMARY(20080815);
exec SP_PAYROLL_SUMMARY(20080831);
exec SP_PAYROLL_SUMMARY(20080915);
exec SP_PAYROLL_SUMMARY_EMPL(20080915, 'T00021');

select empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g
from   pys_payroll_summary
where  empl_id = 'Q00004'
and    payroll_no in (20080815, 20080831)
order  by payroll_no desc, period_to desc

select nvl(sum(no_days),0) cola_days, nvl(sum(amt),0) cola_amt
from   pys_payroll_dtl
where  pahd_payroll_no  in (20080815, 20080831)
and    empl_empl_id = 'Q00004'
and    paty_code like 'COLA';

select empl_id, max(period_to) period_to, max(sal_freq) sal_freq, max(dept_code) dept_code, 
       sum(cola_amt) cola_amt, sum(cola_day) cola_day, sum(no_days)
from   pys_payroll_summary
where  empl_id = 'Q00004'
and    payroll_no in (20080815, 20080831)
group  by empl_id
                   
select basic_rate, title, vess_code
                    from   pys_payroll_dtl_log
                    where  empl_empl_id = 'C00019'
                    and    payroll_no = 20080831
                    order  by pay_date desc

select empl_id empl_empl_id, sum(net_amount) net_amt, sum(no_days) no_days, count(1) nRec
             from   pys_payroll_summary
             where  payroll_no = 20080131
             group  by empl_id 
             having sum(net_amount) < 0 

select empl_empl_id, period_fr, period_to, basic_rate, no_days, amt, dept_code, title, vess_code, sal_freq
from   pys_payroll_dtl
where  pahd_payroll_no = 20080115
and    paty_code like 'REG%'
and    dept_code is null
order  by  empl_empl_id, period_to desc

select empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq, min(period_fr) period_fr, sum(no_days), sum(amt)
from   pys_payroll_dtl
where  pahd_payroll_no = 20080831
and    paty_code like 'REG%'
and    empl_empl_id = 'O00003'
group by empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq
order  by  empl_empl_id, period_to desc
             
             
select vocr.voya_vess_code, vocr.empl_empl_id, empl.last_name || ',  ' || empl.first_name || '  ' || empl.middle_name full_name
from   cms_voyage_crew vocr, pms_employees empl
where  vocr.voya_vess_code = :cahd.vess_surveyed
and    vocr.empl_empl_id = empl.empl_id
group by vocr.empl_empl_id, empl.last_name || ',  ' || empl.first_name || '  ' || empl.middle_name 
union
select vocr.voya_vess_code, vocr.empl_empl_id, empl.last_name || ',  ' || empl.first_name || '  ' || empl.middle_name full_name
from   cms_voyage_crew vocr, pms_employees empl
where  vocr.voya_vess_code = :cahd.vess_code
and    vocr.empl_empl_id = empl.empl_id
group by vocr.empl_empl_id, empl.last_name || ',  ' || empl.first_name || '  ' || empl.middle_name 
order by 3




select emp.empl_id, emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name emp_fullname,
       pay.l_title_a title, 
       pay.l_basic_rate_a basic_rate, 
       sum(pay.no_days) no_days_2, 
       decode(max(pay.dept_code) , 'FL', sum(pay.no_days),1) no_days, 
       decode(max(sal_freq), 'MONTHLY',  decode(max(pay.dept_code) , 'FL', l_basic_rate_a * sum(pay.no_days), l_basic_rate_a ) , 
                                         decode(max(pay.dept_code) , 'FL', l_basic_rate_a * sum(pay.no_days), l_basic_rate_a ) ) amt, 
       sum(pay.pagibig) pagibig, 
       sum(pay.pagibig_loan) pagibig_loan, 
       sum(pay.sal_loan) sal_loan, 
       sum(pay.sss) sss, 
       sum(pay.sss_loan) sss_loan, 
       sum(pay.philhealth) philhealth, 
       sum(pay.whtax) whtax
from   pms_employees emp, pys_payroll_summary pay
where  pay.empl_empl_id = emp.empl_id
and    pay.period_to between :P_PERIOD_FR and :P_PERIOD_TO
&CF_VESSEL
group by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name, emp.empl_id
having  max(pay.l_basic_rate_a) > 0
order by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name

