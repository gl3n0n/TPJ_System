alter table cms_fishing_sources add (display_seq number default 0 not null, status varchar2(12) default 'ACTIVE' not null);

alter table cms_daily_catch_summary add surveyed_by varchar2(16);
alter table cms_daily_catch_summary add surveyed_by_vess varchar2(16);
alter table cms_daily_catch_summary add time_setted date;
alter table CMS_DAILY_CATCH_SUMMARY drop constraint DCSU_UK;
alter table pys_employee_incentives add vess_code_2 varchar2(16);

select vess.code, vess.name, sum(emin.amt) amt
from   cms_vessels vess, (
select vess_code code
      ,sum(emin.amt) amt
from  pys_employee_incentives
where inhd_tran_no = :p_tran_no
and   inty_code = '300_600'
) emin
where emin.vess_code(+) = vess.code
and   vess.status <> 'DC'
group by vess.code, vess.name
order by 2

alter table pys_employee_incentives modify inty_code null;
alter table pys_employee_incentives add dety_code varchar2(16);
alter table pys_employee_incentives add dedu_seq_no NUMBER(12);
alter table pys_employee_incentives add l_vess_code varchar2(16);
alter table pys_employee_incentives add l_rank_code varchar2(16);

