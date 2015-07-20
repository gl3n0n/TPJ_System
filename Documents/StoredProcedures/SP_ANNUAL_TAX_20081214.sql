create or replace procedure sp_annual_tax (
   p_pay_no in number, 
   p_date_to in date ) is

   dStart         Date;
   dEnd           Date;
   dEnd2          Date;
   nAmtCola       Number(14,6) := 0;
   nDedAmt        Number(14,6) := 0;
   nWhtax         Number(14,6) := 0;
   nTaxExemption  Number(14,6) := 0;
   nTaxable13Mo   Number(14,6) := 0;
   nTaxableIncome Number(14,6) := 0;
   dEffDate       Date;
   nFixTax        Number(14,6) := 0;
   nBaseTax       Number(14,6) := 0;
   nTaxPct        Number(14,6) := 0;
   nSubjectTax    Number(14,6) := 0;
   nTax           Number(14,6) := 0;

begin
   dStart := to_date(to_char(p_date_to,'YYYY') || '0101', 'YYYYMMDD');
   dEnd   := to_date(to_char(p_date_to,'YYYY') || '1231', 'YYYYMMDD');
   dEnd2  := to_date(to_char(p_date_to,'YYYY') || '1130', 'YYYYMMDD');

   for i in (select emp.empl_id, emp.taty_code tax_type
             from   pms_employees emp, pys_payroll_summary pay, pys_payroll_hdr pad
             where  pay.empl_id = emp.empl_id
             and    pay.payroll_no = pad.payroll_no
             and    pad.period_to between dStart and dEnd
             group by emp.empl_id, emp.taty_code
             )
   loop
      for j in (select to_char(pad.period_to, 'YYYYMM') cur_mon_sort,
                       to_char(pad.period_to, 'fmMonth-YYYY') cur_mon,
                       pay.l_vess_code vessel_nm,
                       pay.dept_code dept_code,
                       pay.l_title title, 
                       pay.l_oport oport, 
                       pay.l_basic_rate_a basic_rate, 
                       (decode(pay.dept_code,'FL', sum(pay.no_days)*(pay.l_basic_rate_a-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(pay.l_basic_rate_a-max(pay.cola_rate)), pay.l_basic_rate_a) +
                       greatest(sum(pay.cola_amt),0) ) amt_cola
                from   pys_payroll_summary pay, pys_payroll_hdr pad
                where  pay.payroll_no = pad.payroll_no
                and    pad.period_to between dStart and dEnd
                and    pay.empl_id = i.empl_id
                group by to_char(pad.period_to, 'YYYYMM'),
                       to_char(pad.period_to, 'fmMonth-YYYY'), pay.l_oport, pay.l_basic_rate_a, pay.l_vess_code,
                       pay.dept_code, pay.l_title
                order by to_char(pad.period_to, 'YYYYMM')
               )
      loop
         nAmtCola := nvl(nAmtCola,0) + j.amt_cola;
      end loop;
   
      for j in (select to_char(pahd.period_to, 'YYYYMM') d_cur_mon_sort,
                       to_char(pahd.period_to, 'fmMonth-YYYY') d_cur_mon,
                       sum(pay.pag_ibig_amt) d_pagibig, 
                       sum(pay.sss_amt) d_sss, 
                       sum(pay.medicare) d_medicare, 
                       sum(pay.whtax) d_whtax
                from   pys_payroll_summary pay, pys_payroll_hdr pahd
                where  pay.payroll_no = pahd.payroll_no
                and    pahd.period_to between dStart and dEnd
                and    pay.empl_id = i.empl_id
                )
      loop
         nDedAmt := nvl(nDedAmt,0) + (j.d_pagibig + j.d_sss + j.d_medicare);
      end loop;

      select sum(pay.whtax) 
      into   nWhtax
      from   pys_payroll_summary pay
      where  pay.period_to between dStart and dEnd2
      and    pay.empl_id = i.empl_id;

      nTaxExemption  := sf_tax_exemption(dEnd, i.tax_type);
      nTaxable13Mo   := sf_get_taxable_13th_month(i.empl_id, dEnd);
      nTaxableIncome := (nAmtCola-nDedAmt) + nTaxable13Mo - nTaxExemption;

      select max(eff_date)
      into   dEffDate
      from   pys_tax_rates
      where  nTaxableIncome between salary_fr and salary_to
      and    eff_date <= dEnd;

      select fix_tax, base_tax, over_pct
      into   nFixTax, nBaseTax, nTaxPct
      from   pys_tax_rates
      where  eff_date = dEffDate
      and    nTaxableIncome between salary_fr and salary_to;

      nSubjectTax    := nTaxableIncome - nBaseTax;
      nTax           := nSubjectTax * (nTaxPct/100);
      nTax           := nTax + nFixTax;

      if nTax > nWhtax then
         update pys_payroll_dtl 
         set    amt = nTax - nWhtax 
         where  empl_empl_id = i.empl_id
         and    pahd_payroll_no = p_pay_no
         and    paty_code = 'WHTAX';

         update pys_payroll_summary
         set    net_amount = net_amount - (nTax - nWhtax),
                whtax = (nTax - nWhtax)
         where  empl_id = i.empl_id
         and    payroll_no = p_pay_no;
      else
         delete pys_payroll_dtl 
         where  empl_empl_id = i.empl_id
         and    pahd_payroll_no = p_pay_no
         and    paty_code = 'WHTAX';
      end if;

      -- reset variables
      nAmtCola       := 0;
      nDedAmt        := 0;
      nWhtax         := 0;
      nTaxExemption  := 0;
      nTaxable13Mo   := 0;
      nTaxableIncome := 0;
      dEffDate       := null;
      nFixTax        := 0;
      nBaseTax       := 0;
      nTaxPct        := 0;
      nSubjectTax    := 0;
      nTax           := 0;

   end loop;
end sp_annual_tax;
/
