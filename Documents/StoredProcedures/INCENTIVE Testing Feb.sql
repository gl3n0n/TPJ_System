begin
  Sp_Incentive_Computation (20090228, '2009', '02', to_date('02-01-2009', 'MM-DD-YYYY'), to_date('02-28-2009', 'MM-DD-YYYY'));
end;

   SELECT tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_CATCHER = 'MACMAC'
   AND    tx_date BETWEEN to_date('19-FEB-09') AND to_date('28-FEB-09')
   AND    time_setted < to_date('28-FEB-09')
   
   
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, NVL(dt_disembarked,to_date('02-28-2009', 'MM-DD-YYYY')) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess
   WHERE  vocr.voya_voyage_date <= to_date('02-28-2009', 'MM-DD-YYYY')
   AND    vocr.dt_embarked <= to_date('02-28-2009', 'MM-DD-YYYY')
   AND    vocr.dt_disembarked IS NULL
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id IS NOT NULL order by vocr.empl_empl_id


select emin.empl_empl_id
         ,emp.last_name || ',  ' || first_name || '  ' || middle_name empl_name
         ,emin.vess_code vess_code
         ,vess.name vess_name
         ,emin.rank_code d_rank_code
         ,emin.rate d_rate
         ,emin.basis d_basis
         ,emin.period_fr  d_period_fr
         ,emin.period_to d_period_to
         ,sum(emin.amt) amt
from  pys_employee_incentives emin, 
        cms_vessels vess, 
        pms_employees emp
where inhd_tran_no = 20090228
and   inty_code = '300_600'
and   emin.vess_code = vess.code
and   emin.empl_empl_id = emp.empl_id
and   emin.vess_code = '76'
group by emin.empl_empl_id, emin.vess_code, emp.last_name || ',  ' || first_name || '  ' || middle_name, vess.name,
         emin.rank_code,emin.rate,emin.basis,emin.period_fr,emin.period_to


   
   