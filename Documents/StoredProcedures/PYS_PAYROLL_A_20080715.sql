create or replace view pys_payroll_a as
select pahd_payroll_no, period_fr, period_to, empl_empl_id,
       max(basic_rate) basic_rate,
       --max(no_days) no_days,
       sum(no_days) no_days,
       max(amt) amt,
       max(pagibig) pagibig,
       max(pagibig_loan) pagibig_loan,
       max(sal_loan) sal_loan,
       max(sss) sss,
       max(sss_loan) sss_loan,
       max(philhealth) philhealth,
       max(whtax) whtax,
       max(title) title,
       max(nvl(vess_code, ' ')) vess_code,
       max(nvl(dept_code,' ')) dept_code,
       sum(ot) ot,
       max(cola) cola,
       max(sal_freq) sal_freq,
       max(latest_vess) latest_vess
from
(
select pahd_payroll_no, period_fr, period_to, empl_empl_id, decode(sal_freq,'MONTHLY',basic_rate_g/30,basic_rate_g) basic_rate, no_days, amt_g amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'REG%'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL-FLT')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL-OFC')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS-FLT')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS-OFC')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-OFC')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN-FLT')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN-OFC')) no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, amt COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
--where  paty_code = 'PAGLOAN' modified by thess 1/14/2008
where dety_code='HDMF LOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
)
group by pahd_payroll_no, period_fr, period_to, empl_empl_id

