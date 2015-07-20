CREATE OR REPLACE FORCE VIEW PYS_EMPL_LATEST_VOYAGE AS
select a.empl_empl_id, a.dt_embarked, a.dt_disembarked,
       a.voya_vess_code vess_code, a.rank_code, a.title,
       a.basic_rate, a.basic_rate_g, a.voya_voyage_date voyage_date, a.seq_no,
       decode(a.dt_disembarked, NULL, 'EMBARKED', 'DISEMBARKED') status
from   cms_voyage_crew a, 
      (select crew.empl_empl_id, max(crew.dt_embarked) dt_embarked 
       from   cms_voyage_crew crew, cms_voyages voya 
       where crew.voya_vess_code = voya.vess_code 
       and   crew.voya_voyage_date = voya.voyage_date 
       and   voya.voyage_status <> 'CANCELLED' group by crew.empl_empl_id) b
where a.empl_empl_id = b.empl_empl_id
and   a.dt_embarked = b.dt_embarked
order by a.empl_empl_id;


CREATE OR REPLACE FORCE VIEW PYS_EMPL_LATEST_MOVEMENT AS
select a.empl_empl_id, a.eff_st_date dt_embarked,
       a.to_vess_code vess_code, a.to_posi_code posi_code, a.to_basic_rate basic_rate,
       a.fr_vess_code, a.fr_posi_code, a.fr_basic_rate, a.eff_en_date, a.tran_no,
       decode(a.to_vess_code, NULL, 'DISEMBARKED', 'EMBARKED') status
from pms_employee_movements a, (select empl_empl_id, max(eff_st_date) eff_st_date 
                                from pms_employee_movements 
                                where py_status='POSTED' 
                                group by empl_empl_id) b
where a.empl_empl_id = b.empl_empl_id
and   a.eff_st_date = b.eff_st_date
order by a.empl_empl_id;



CREATE OR REPLACE VIEW PYS_EMPL_SALDIFF AS
select a.empl_empl_id empl_id, c.last_name, c.first_name, c.middle_name,  a.dt_embarked m_embarked_dt, 
       a.vess_code m_vessel, a.posi_code m_position, a.basic_rate m_basic_rate, a.tran_no m_tran_no,
       b.vess_code c_vessel, b.rank_code c_position, b.basic_rate c_basic_rate, b.seq_no c_seq_no, b.voyage_date c_voyage_date,
       a.basic_rate-b.basic_rate sal_diff
from pys_empl_latest_voyage b, pys_empl_latest_movement a, pms_employees c
where a.empl_empl_id = b.empl_empl_id
and   a.dt_embarked = b.dt_embarked
and   a.empl_empl_id = c.empl_id
order by a.empl_empl_id;
