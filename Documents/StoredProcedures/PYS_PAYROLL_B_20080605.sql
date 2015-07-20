create or replace view pys_payroll_b as
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 
       max(basic_rate) basic_rate,
       --max(no_days) no_days,
       sum(nvl(no_days,0)) no_days,
       max(amt) amt,
       sum(ot) ot,
       max(cola) cola,
       max(pagibig) pagibig,
       max(pagibig_loan) pagibig_loan,
       max(sal_loan) sal_loan,
       max(sss) sss,
       max(sss_loan) sss_loan,
       max(philhealth) philhealth,
       max(whtax) whtax,
       max(vale) vale,
       max(title) title,
       max(nvl(vess_code, ' ')) vess_code,
       max(nvl(dept_code,' ')) dept_code,
       max(nvl(sal_freq,'AAAA')) sal_freq,
       max(latest_vess) latest_vess
from
(
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate, no_days, amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'REG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HOL')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HOL-FLT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL-FLT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HS')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HS-FLT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS-FLT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HS-OFC')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-OFC')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-SUN')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-SUN-FLT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN-FLT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, amt COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'HDMF LOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, amt VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'VALE'
)
group by pahd_payroll_no, period_fr, period_to, empl_empl_id

