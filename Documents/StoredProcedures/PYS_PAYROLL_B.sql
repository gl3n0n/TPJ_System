create or replace view PYS_PAYROLL_B as
select period_fr, period_to, empl_empl_id,
       max(basic_rate) basic_rate,
       max(no_days) no_days,
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
       max(nvl(dept_code,' ')) dept_code
from
(
select period_fr, period_to, empl_empl_id, basic_rate, no_days, amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code	
from   pys_payroll_dtl
where  paty_code = 'REG'
union all
select period_fr, period_to, empl_empl_id, basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code like 'OT%'
union all
select period_fr, period_to, empl_empl_id, basic_rate, no_days, 0 amt, 0 OT, amt COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'PAGLOAN'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, 0 VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
union all
select period_fr, period_to, empl_empl_id, null basic_rate, null no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, amt VALE, title, vess_code, dept_code
from   pys_payroll_dtl
where  paty_code = 'VALE'
)
group by period_fr, period_to, empl_empl_id
/
