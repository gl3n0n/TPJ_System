begin
   delete from pys_sss_contribution ;
   delete from pys_pagibig_contribution;
   delete from pys_philhealth_contribution;

   delete from pys_sss_contri_dtl;
   delete from pys_pagibig_contri_dtl;
   delete from pys_health_contri_dtl;                
   delete from PYS_PAYROLL_DTL;
   delete from PYS_PAYROLL_DTL_LOG;  
   delete from PYS_PAYROLL_DTL_ADJ_LOG;  
   commit;
end;

   sp_payroll_computation_a (20080115, '2008','01',to_date('20080101','YYYYMMDD'),to_date('20080115','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080131, '2008','01',to_date('20080116','YYYYMMDD'),to_date('20080131','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080215, '2008','02',to_date('20080201','YYYYMMDD'),to_date('20080215','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080229, '2008','02',to_date('20080216','YYYYMMDD'),to_date('20080229','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080315, '2008','03',to_date('20080301','YYYYMMDD'),to_date('20080315','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080331, '2008','03',to_date('20080316','YYYYMMDD'),to_date('20080331','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080415, '2008','04',to_date('20080401','YYYYMMDD'),to_date('20080415','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080430, '2008','04',to_date('20080416','YYYYMMDD'),to_date('20080430','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080515, '2008','05',to_date('20080501','YYYYMMDD'),to_date('20080515','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080531, '2008','05',to_date('20080516','YYYYMMDD'),to_date('20080531','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080615, '2008','06',to_date('20080601','YYYYMMDD'),to_date('20080615','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080630, '2008','06',to_date('20080616','YYYYMMDD'),to_date('20080630','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080715, '2008','07',to_date('20080701','YYYYMMDD'),to_date('20080715','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080731, '2008','07',to_date('20080716','YYYYMMDD'),to_date('20080731','YYYYMMDD')); 
   commit;
end;


begin
   delete from pys_sss_contri_dtl where psch_payroll_no = 20080115;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no = 20080115;
   delete from pys_health_contri_dtl where phch_payroll_no = 20080115;                
   delete from PYS_PAYROLL_DTL where pahd_payroll_no = 20080115;  
   delete from PYS_PAYROLL_DTL_LOG where payroll_no = 20080115;  
   sp_payroll_computation_a (20080115, '2008','01',to_date('20080101','YYYYMMDD'),to_date('20080115','YYYYMMDD')); 
   commit;
end;

select * from pys_payroll_dtl_log where empl_empl_id = 'M00032' order by pay_date desc

select empl_empl_id, att_date, outer_port, num_hours, ot_hours, am_time_in 
from pms_attendance_records where empl_empl_id = 'M00032' order by att_date desc

select posi_code,
                              title,
                              decode(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE) basic_rate,
                              vess_code,
                              min(pay_date) dStart,
                              max(pay_date) dEnd
                       from   pys_payroll_dtl_log
                       where  empl_empl_id = 'C00020'
                       and    pay_date between to_date('20080101','YYYYMMDD') and to_date('20080131','YYYYMMDD')
                       group  by  posi_code, title, decode(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE), vess_code

begin
   delete from pys_sss_contribution where period_to = to_date('20080131','YYYYMMDD');
   delete from pys_pagibig_contribution where period_to = to_date('20080131','YYYYMMDD');
   delete from pys_philhealth_contribution where period_to = to_date('20080131','YYYYMMDD');

   delete from pys_sss_contri_dtl where psch_payroll_no = 20080131;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no = 20080131;
   delete from pys_health_contri_dtl where phch_payroll_no = 20080131;                
   delete from PYS_PAYROLL_DTL where pahd_payroll_no = 20080131;       
   delete from PYS_PAYROLL_DTL_LOG where payroll_no = 20080131;  
   sp_payroll_computation_a (20080131, '2008','01',to_date('20080116','YYYYMMDD'),to_date('20080131','YYYYMMDD')); 
   commit;
end;

begin
  sp_payroll_computation_a (20080215, '2008','02',to_date('20080201','YYYYMMDD'),to_date('20080215','YYYYMMDD')); 
  commit;
end;

begin
  sp_payroll_computation_a (20080229, '2008','02',to_date('20080216','YYYYMMDD'),to_date('20080229','YYYYMMDD')); 
  commit;
end;

begin
  sp_payroll_computation_a (20080331, '2008','03',to_date('20080316','YYYYMMDD'),to_date('20080331','YYYYMMDD')); 
  commit;
end;

begin
  sp_payroll_computation_a (4152008, '2008','04',to_date('20080401','YYYYMMDD'),to_date('20080415','YYYYMMDD')); 
  commit;
end;

begin
  sp_payroll_computation_a (4302008, '2008','04',to_date('20080416','YYYYMMDD'),to_date('20080430','YYYYMMDD')); 
  commit;
end;

begin
  sp_payroll_computation_a (5152008, '2008','01',to_date('20080501','YYYYMMDD'),to_date('20080515','YYYYMMDD')); 
  commit;
end;

begin
  sp_payroll_computation_a (20080531, '2008','01',to_date('20080516','YYYYMMDD'),to_date('20080531','YYYYMMDD')); 
  commit;
end;

begin
   delete from pys_sss_contri_dtl where psch_payroll_no = 20080115;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no = 20080115;
   delete from pys_health_contri_dtl where phch_payroll_no = 20080115;                
   delete from PYS_PAYROLL_DTL where pahd_payroll_no = 20080115;       
end;

begin
   delete from pys_sss_contribution where period_to = to_date('20080131','YYYYMMDD');
   delete from pys_pagibig_contribution where period_to = to_date('20080131','YYYYMMDD');
   delete from pys_philhealth_contribution where period_to = to_date('20080131','YYYYMMDD');

   delete from pys_sss_contri_dtl where psch_payroll_no = 20080131;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no = 20080131;
   delete from pys_health_contri_dtl where phch_payroll_no = 20080131;                
   delete from PYS_PAYROLL_DTL where pahd_payroll_no = 20080131;       
   commit;
end;
      
select payroll_no, period_fr
from   pys_payroll_hdr
where  period_fr =  to_date('20080416','YYYYMMDD')


select period_fr, period_to, paty_code, amt_g, no_days
select *
from   pys_payroll_dtl
where  empl_empl_id = 'M00020'
and    pahd_payroll_no = 4152008
and    paty_code like 'REG%'

select * from pys_sss_contribution where period_to = to_date('20080430','YYYYMMDD')

   cursor att_flt (p_sta in date, p_end in date) is
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080125','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080125','YYYYMMDD')
   and    vocr.dt_disembarked is null 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.empl_empl_id = 'A00023'
   and    vocr.passenger = 'N'
   union
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080125','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080125','YYYYMMDD')
   and    vocr.dt_disembarked is not null 
   and    vocr.dt_disembarked >= to_date('20071226','YYYYMMDD')
   and    vocr.dt_disembarked <> (to_date('20071226','YYYYMMDD')-1) -- end of month
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.empl_empl_id = 'A00023'
   and    vocr.passenger = 'N'
   order  by dt_embarked desc
   
select empl_empl_id, count(1) from (
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080430','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080430','YYYYMMDD')
   and    vocr.dt_disembarked is null 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.passenger = 'N'
   union
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080430','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080430','YYYYMMDD')
   and    vocr.dt_disembarked is not null 
   and    vocr.dt_disembarked >= to_date('20080326','YYYYMMDD')
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.passenger = 'N'
   order  by empl_empl_id, dt_embarked desc   
) 
group by empl_empl_id
having count(1)>1

select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code, 
       'OFC' empl_type,  b.dept_code dept_code
from   pms_employees b
where  b.empl_id = '00260'
and    exists (select 1 
from   pms_attendance_records a
where  a.empl_empl_id = b.empl_id
and    a.att_date between to_date('20080301','YYYYMMDD') and to_date('20080331','YYYYMMDD') )
and    exists (select 1 
from   pys_employee_salary a
where  a.empl_empl_id = b.empl_id
and    a.sal_freq = 'SEMI-MO' )

   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          'OFC' empl_type, b.dept_code dept_code
   from   pms_employees b
   where  exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= to_date('20080131','YYYYMMDD')
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'MONTHLY'   )
      
      
   cursor allo_flt ( p_empl_id in varchar2,  p_vessel in varchar2,  p_voya_date in varchar2 ) is
   select eff_st_date, allo_code, amt amt
   from   pys_employee_allowances
   where  empl_empl_id = '0002'
   and    eff_st_date  = (select max (eff_st_date) from pys_employee_allowances where eff_st_date <= to_date('20080430','YYYYMMDD'))

   
declare
  nBasicR   Number(8,3);
  nBasicG   Number(8,3);
  vSalFreq  Varchar2(16);
begin
  sp_get_basic_rate ( '00260', to_date('20080301','YYYYMMDD'), to_date('20080331','YYYYMMDD'), nBasicR, nBasicG, vSalFreq );
  dbms_output.put_line ('check:' || to_char(nBasicR) || ',' || to_char(nBasicG) || ',' || vSalFreq);
end;

   --get attendance record
select * from (
   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code, 
          'OFC' empl_type,  b.dept_code dept_code
   from   pms_employees b
   where  exists (select 1 
   from   pms_attendance_records a
   where  a.empl_empl_id = b.empl_id
   and    a.att_date between to_date('20080401','YYYYMMDD')  and to_date('20080430','YYYYMMDD')  )
   and    exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= to_date('20080430','YYYYMMDD') 
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'SEMI-MO'
   )
   union
   select vocr.empl_empl_id empl_empl_id, empl.taty_code, empl.posi_code posi_code, 
          'FLT' empl_type, null dept_code
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080430','YYYYMMDD') 
   and    vocr.dt_embarked <= to_date('20080430','YYYYMMDD')
   and   (vocr.dt_disembarked is null 
   or    (vocr.dt_disembarked is not null and vocr.dt_disembarked >= to_date('20080401','YYYYMMDD')) ) 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    not exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= to_date('20080430','YYYYMMDD') 
      and    d.empl_empl_id = vocr.empl_empl_id )
      and    c.empl_empl_id = vocr.empl_empl_id
      and    c.sal_freq = 'MONTHLY'   
   )
   group  by vocr.empl_empl_id, empl.taty_code, empl.posi_code, 
          'FLT', NULL
   union
   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          'OFC' empl_type, b.dept_code dept_code
   from   pms_employees b
   where  exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= to_date('20080430','YYYYMMDD') 
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'MONTHLY'   
   )
)
where empl_empl_id = '00257'


select * from pys_payroll_dtl where empl_empl_id = 'A00023'
select * from pys_payroll_b where empl_empl_id = 'C00019'
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate, no_days, amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  empl_empl_id = 'C00019'

  select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = 'M00026'
   and    att_date between to_date('20071226', 'YYYYMMDD') and to_date('20080110', 'YYYYMMDD')
   union
   select tx_date, null, null, null, null, 6, 0, 'N'
   from   pys_holidays
   where  tx_date between to_date('20071226', 'YYYYMMDD') and to_date('20080110', 'YYYYMMDD')
   and    tx_date not in (select att_date from pms_attendance_records where empl_empl_id = 'M00026' and att_date between to_date('20071226', 'YYYYMMDD') and to_date('20080110', 'YYYYMMDD'))
   order  by tx_date
   


select * from pys_employee_salary where sal_freq = 'MONTHLY'   and is_manager = 'Y'
select * from pys_deductions where dt_created>= trunc(sysdate)
delete from pys_deductions where dt_created>= trunc(sysdate) and amt < 0
commit

select * from pys_payroll_a where empl_empl_id = 'L00002'
commit


select emp.empl_id h_empl_id, pay.pahd_payroll_no  pay_no,
          emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name h_fullname,
          pay.title h_title, 
          pay.basic_rate h_basic_rate, 
          period_to h_period_to,
          sum(pay.no_days) h_no_days, 
          sum(pay.amt) h_amt, 
          max(pay.sal_freq) h_sal_freq, 
          max(pay.dept_code) h_dept
from   pms_employees emp, pys_payroll_b pay
where  pay.empl_empl_id = emp.empl_id
and     pay.basic_rate <> 0 
and    pay.pahd_payroll_no = 20080131
and    pay.latest_vess = '79'
group by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name, emp.empl_id, pay.title, pay.basic_rate, pay.period_to, pay.pahd_payroll_no
union
select emp.empl_id h_empl_id, pay.pahd_payroll_no  pay_no,
          emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name h_fullname,
          pay.title h_title, 
          pay.basic_rate h_basic_rate, 
          period_to h_period_to,
          0 h_no_days, 
          0 h_amt, 
          max(pay.sal_freq) h_sal_freq, 
          max(pay.dept_code) h_dept
from   pms_employees emp, pys_payroll_b pay
where  pay.empl_empl_id = emp.empl_id
and     pay.basic_rate <> 0 
and    pay.pahd_payroll_no = 20080115
and    exists (select 1 from pys_payroll_dtl dtl
where  dtl.empl_empl_id = pay.empl_empl_id
and    dtl.paty_code like 'OT%'
and    dtl.period_to between pay.period_fr and pay.period_to
and    pay.pahd_payroll_no = 20080115
)
group by emp.last_name || ', ' || emp.first_name || ' ' || emp.middle_name, emp.empl_id, pay.title, pay.basic_rate, pay.period_to, pay.pahd_payroll_no
order by  h_fullname, h_period_to asc

