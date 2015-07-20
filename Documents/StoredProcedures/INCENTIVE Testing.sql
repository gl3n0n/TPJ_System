begin
   delete from pys_employee_incentives where inhd_tran_no = 20080101;
   commit;
   sp_incentive_computation ( 20080101, '2008', '01', to_date('20080101', 'YYYYMMDD'), to_date('20080131', 'YYYYMMDD'));
end;


select tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code,
       sum(nvl(tot_jmb_catch,0) + nvl(tot_lrg_catch,0) + nvl(tot_reg_catch,0)  + nvl(tot_med_catch,0) + nvl(tot_sml_catch,0)) total_catch, user, sysdate
from   cms_catches_log
where  tx_date between to_date('20080101', 'YYYYMMDD') and to_date('20080131', 'YYYYMMDD') 
group  by tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code;

   select empl_empl_id, dety_code, seq_no, amt, start_date, end_date
   from   pys_deductions
   where  empl_empl_id in (select empl_empl_id from PYS_EMPLOYEE_INCENTIVES)
   and    end_date  <= to_date('20080131', 'YYYYMMDD') 
   and    start_date <= to_date('20080131', 'YYYYMMDD') 
   and    dety_code = 'VALE'

UPDATE pys_deductions SET START_DATE=to_date('20080118', 'YYYYMMDD'), END_DATE=to_date('20080118', 'YYYYMMDD') WHERE SEQ_NO = 464

SELECT * FROM PYS_EMPLOYEE_INCENTIVES


   select vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <=  to_date('20080131', 'YYYYMMDD') 
   and    vocr.dt_embarked <=  to_date('20080131', 'YYYYMMDD') 
   and    vocr.dt_disembarked is null
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id is not null
   union
   select vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <=  to_date('20080131', 'YYYYMMDD') 
   and    vocr.dt_embarked <=  to_date('20080131', 'YYYYMMDD') 
   and    vocr.dt_disembarked is not null
   and    vocr.dt_disembarked >=  to_date('20080101', 'YYYYMMDD') 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id is not null
   order  by empl_empl_id,dt_embarked;

select * from cms_daily_catch_summary

select * from PYS_INCENTIVE_HDR

select * from pys_employee_incentives where empl_empl_id = 'R00003'

select fiso_code, sum(total_catch) total_catch
from   cms_daily_catch_summary
where  vess_catcher = '16'
and    tx_date between to_date('20080101', 'YYYYMMDD') and to_date('20080131', 'YYYYMMDD') 
group  by fiso_code

select fiso_code, sum(total_catch) total_catch
from   cms_daily_catch_summary
where  vess_lighted = '16'
and    tx_date between to_date('20080101', 'YYYYMMDD') and to_date('20080131', 'YYYYMMDD') 
group  by  fiso_code;