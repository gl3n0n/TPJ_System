begin
   delete from pys_sss_contribution where period_to >= to_date('20080815','YYYYMMDD');
   delete from pys_pagibig_contribution where period_to >= to_date('20080815','YYYYMMDD');
   delete from pys_philhealth_contribution where period_to >= to_date('20080815','YYYYMMDD');
   delete from pys_sss_contri_dtl where psch_payroll_no >= 20080815;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no >= 20080815;
   delete from pys_health_contri_dtl where phch_payroll_no >= 20080815;                
   delete from PYS_PAYROLL_DTL where pahd_payroll_no >= 20080815;       
   delete from PYS_PAYROLL_DTL_LOG where payroll_no >= 20080815;
   commit;
end;
   delete from pys_sss_contri_dtl where psch_payroll_no = 20080715;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no = 20080715;
   delete from pys_health_contri_dtl where phch_payroll_no = 20080715;                
   delete from PYS_PAYROLL_DTL where pahd_payroll_no = 20080715;       
   delete from PYS_PAYROLL_DTL_LOG where payroll_no = 20080731;
   commit;
end;
   sp_payroll_computation_a (20080630, '2008','06',to_date('20080615','YYYYMMDD'),to_date('20080630','YYYYMMDD')); 
   commit;
   sp_payroll_computation_a (20080715, '2008','07',to_date('20080701','YYYYMMDD'),to_date('20080715','YYYYMMDD')); 
   commit;
end;

select * from pys_payroll_dtl_log where empl_empl_id = 'M00038' order by pay_date desc

select empl_empl_id, att_date, outer_port, num_hours, ot_hours, am_time_in 
from pms_attendance_records where empl_empl_id = 'C00029' order by att_date desc


begin
   delete from pys_sss_contribution where period_to = to_date('20080731','YYYYMMDD');
   delete from pys_pagibig_contribution where period_to = to_date('20080731','YYYYMMDD');
   delete from pys_philhealth_contribution where period_to = to_date('20080731','YYYYMMDD');

   delete from pys_sss_contri_dtl where psch_payroll_no = 20080731;
   delete from pys_pagibig_contri_dtl where ppch_payroll_no = 20080731;
   delete from pys_health_contri_dtl where phch_payroll_no = 20080731;
   delete from PYS_PAYROLL_DTL where pahd_payroll_no = 20080731;       
   delete from PYS_PAYROLL_DTL_LOG where payroll_no = 20080731;       
   commit;

   sp_payroll_computation_a (20080731, '2008','07',to_date('20080716','YYYYMMDD'),to_date('20080731','YYYYMMDD')); 
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
   where  vocr.voya_voyage_date <= to_date('20080615','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080615','YYYYMMDD')
   and    vocr.dt_disembarked is null 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.empl_empl_id = 'R00022'
   and    vocr.passenger = 'N'
   union
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080615','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080615','YYYYMMDD')
   and    vocr.dt_disembarked is not null 
   and    vocr.dt_disembarked >= to_date('20080526','YYYYMMDD')
   and    vocr.dt_disembarked <> (to_date('20080526','YYYYMMDD')-1) -- end of month
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.empl_empl_id = 'R00022'
   and    vocr.passenger = 'N'
   order  by dt_embarked desc
   
select empl_empl_id, count(1) from (
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080630','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080630','YYYYMMDD')
   and    vocr.dt_disembarked is null 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.passenger = 'N'
   union
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= to_date('20080630','YYYYMMDD')
   and    vocr.dt_embarked <= to_date('20080630','YYYYMMDD')
   and    vocr.dt_disembarked is not null 
   and    vocr.dt_disembarked >= to_date('20080526','YYYYMMDD')
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