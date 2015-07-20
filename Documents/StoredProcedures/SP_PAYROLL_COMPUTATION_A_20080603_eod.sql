create or replace procedure sp_payroll_computation_a
(
   p_payno   in number,
   p_year    in varchar2,
   p_mon     in varchar2,
   p_date_fr in date, 
   p_date_to in date
)  
   as

   --get attendance record
   cursor attr (p_period_fr in date, p_period_to in date ) is
   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code, 
          'OFC' empl_type,  b.dept_code dept_code, 'SEMI-MO' sal_freq
   from   pms_employees b
   where  exists (select 1 
   from   pms_attendance_records a
   where  a.empl_empl_id = b.empl_id
   and    a.att_date between p_period_fr and p_period_to )
   and    exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= p_period_to 
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'SEMI-MO'
   )
   union
   select vocr.empl_empl_id empl_empl_id, empl.taty_code, empl.posi_code posi_code, 
          'FLT' empl_type, 'FL' dept_code, 'SEMI-MO' sal_freq
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= p_period_to 
   and    vocr.dt_embarked <= p_period_to
   and   (vocr.dt_disembarked is null 
   or    (vocr.dt_disembarked is not null and vocr.dt_disembarked >= p_period_fr) ) 
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    not exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= p_period_to 
      and    d.empl_empl_id = vocr.empl_empl_id )
      and    c.empl_empl_id = vocr.empl_empl_id
      and    c.sal_freq = 'MONTHLY'   
   )
   group  by vocr.empl_empl_id, empl.taty_code, empl.posi_code, 
          'FLT', NULL
   union
   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          decode(b.dept_code,'FL', 'FLT', 'OFC') empl_type, b.dept_code dept_code,  'MONTHLY' sal_freq
   from   pms_employees b
   where  exists (
      select 1 
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= p_period_to 
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'MONTHLY'   
   );
  
   --get voyage crew
   cursor vocr is
   select empl_empl_id, dt_embarked, dt_disembarked
   from   cms_voyage_crew
   where  dt_embarked < p_date_fr 
   and    dt_disembarked <= p_date_to
   union
   select empl_empl_id, dt_embarked, dt_disembarked
   from   cms_voyage_crew
   where  dt_embarked between p_date_fr and p_date_to;

   --get employee incentive
   cursor emin (p_empl_id in varchar2) is
   select empl_empl_id, inty_code, fiso_code, vess_code, basis, rate, year, mo, amt
   from   pys_employee_incentives
   where  empl_empl_id = p_empl_id
   and    year = to_char(p_date_to, 'YYYY')
   and    mo = to_char(p_date_to, 'MM');

   --get employee deductions
   cursor dedu (p_empl_id in varchar2) is
   select empl_empl_id, dety_code, seq_no, amt
   from   pys_deductions 
   where  empl_empl_id = p_empl_id
   and    end_date  >= p_date_to
   and    start_date <= p_date_to
   --and    no_payday > 0
   and    dety_code <> ('VALE'); -- not to include VALE in Payroll deductions; should be deducted from Incentives

   nSeqNo         Number;
   bWithDeduction Boolean;
   nPayNo         Number(8);

   -- Overtime Rates for OFC and FLT
   nOvertm_RO   Number(8,3);
   nSunday_RO   Number(8,3);
   nHoliday_RO  Number(8,3);
   nHolSun_RO   Number(8,3);
   nOuter_RO    Number(8,3);
   nOutAd_RO    Number(8,3);
   nOvertm_RF   Number(8,3);
   nSunday_RF   Number(8,3);
   nHoliday_RF  Number(8,3);
   nHolSun_RF   Number(8,3);

   -- Actual OT pay 
   nOtPay       Number(8,2);
   nSuPay       Number(8,2);
   nHoPay       Number(8,2);
   nHSPay       Number(8,2);
   nOPPay       Number(8,2);
   nOPAdj       Number(8,2);

   -- Employee Basic Rates and Computed Salary
   vSalFreq     varchar2(16);
   nBasicR      Number(8,2);
   nBasicG      Number(8,2);
   nSalaryG     Number(8,2);

   -- Deductions
   nSSS         Number(8,2);
   nSSS_ER      Number(8,2);
   nSSS_EC      Number(8,2);
   nPagibig     Number(8,2);
   nPagibig_ER  Number(8,2);
   nPhHealth    Number(8,2);
   nPhHealth_ER Number(8,2);
   nTaxable     Number(8,2);
   nWhTax       Number(8,2);

   -- From Previous Pay Sched
   dPrevStart   Date;
   nPrevSal     Number(8,2);
   nPrevAllo    Number(8,2);
   nPrevDays    Number(8,2);

   nNumHrs      Number(5,2);
   nAllowances  Number(8,2);
   nDeduction   Number(8,2) := 0;
   nVale        Number(8,2) := 0;
begin

   -- get Max SeqNo
   select nvl(max(seq_no),0)
   into   nSeqNo
   from   pys_payroll_dtl
   where  pahd_payroll_no = p_payno;

   -- get OFC and FLT Overtime Rate
   sp_get_ofc_ot_rates ( nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO);
   sp_get_flt_ot_rates ( nSunday_RF, nHoliday_RF, nHolSun_RF );

   -- check pay period
   if p_date_to <= to_date(to_char(p_date_to, 'YYYYMM') || '15', 'YYYYMMDD') then

      bWithDeduction := FALSE;
      dPrevStart      := p_date_fr;

   else

      bWithDeduction := TRUE;

      -- get Max Previous Start
      select payroll_no, period_fr
      into   nPayNo, dPrevStart
      from   pys_payroll_hdr
      where  period_fr = to_date(to_char(p_date_to, 'YYYYMM') || '01', 'YYYYMMDD');
      --(
      --   select max(period_fr) 
      --   from   pys_payroll_dtl
      --   where  period_fr < p_date_fr
      --);

   end if;


   for i in attr ( dPrevStart, p_date_to ) loop

      --if bWithDeduction then
      --   dbms_output.put_line (i.empl_empl_id || ',' || i.empl_type);
      --end if;

      nSalaryG   := 0; 
      nOPPay     := 0; 
      nOPAdj     := 0;
      nOtPay     := 0;
      nSuPay     := 0;
      nHoPay     := 0;
      nHsPay     := 0;
      nAllowances := 0;
      nPrevSal   := 0;
      nPrevAllo  := 0;
      
      -- get basic rate and salary mode/frequency
      -- check attendance 
      vSalFreq := i.sal_freq;
      if i.empl_type = 'OFC' then
         sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq );
      end if; 
      
       -- check if Employee has assigned Tax Type 
      if i.taty_code is not null then         -- START: Tax Type checking (no Deduction loop)
      
         if i.empl_type = 'OFC' then
            if vSalFreq = 'MONTHLY' then
               sp_count_mgr_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to, 
                                         i.dept_code, i.posi_code, nBasicR, nBasicG, 
                                         nSunday_RF, nHoliday_RF, nHolSun_RF, 
                                         nSeqNo, nNumHrs, nSalaryG, nSuPay, nHoPay, nHSPay, nAllowances, nSeqNo);
            else
               sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to, 
                                         i.dept_code, i.posi_code, nBasicR, nBasicG, 
                                         nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                         nSeqNo, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
            end if;
         else
            sp_count_flt_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to, 
                                      nSunday_RF, nHoliday_RF, nHolSun_RF, 
                                      nSeqNo, vSalFreq, nNumHrs, nSalaryG, nSuPay, nHoPay, nHSPay, nAllowances, nSeqNo);
         end if; 


         -- Start Compution for deductions
         -- No Deduction for Employees with no Government rate

         --if i.empl_empl_id = '0002' then
         --   dbms_output.put_line ('check:' || i.empl_empl_id || '/' || 'nSalaryG   ' || to_char(nSalaryG) );
         --end if;

         if (bWithDeduction) and (nvl(nSalaryG,0) > 0) then  

            -- get previous salary
            begin
               select sum(amt_g), sum(no_days)
               into   nPrevSal, nPrevDays 
               from   pys_payroll_dtl
               where  empl_empl_id = i.empl_empl_id
               and    pahd_payroll_no = nPayNo
               and    paty_code like 'REG%';
            exception 
               when no_data_found then 
                  nPrevSal  := 0;
                  nPrevDays := 0;
            end;
            
            -- get previous Allowances and Overtimes
            begin
               select sum(amt)
               into   nPrevAllo
               from   pys_payroll_dtl
               where  empl_empl_id = i.empl_empl_id
               and    pahd_payroll_no = nPayNo
               and    paty_code not like 'REG%';
            exception 
               when no_data_found then 
                  nPrevAllo := 0;
            end;

            -- Taxable/Deductible Salary is gross of the ff:
            --    nSalaryG - regular/basic paycomputed using government rate 
            --    nOPPay   - computed amount for outer port
            --    nOPAdj   - computed overtime pay from previous pay day (ot adjustment)
            --    nOtPay   - computed overtime pay
            --    nSuPay   - Sunday overtime pay
            --    nHoPay   - Holiday overtime pay
            --    nHsPay   - Holiday falls on Sunday overtime pay
            --    nPrevSal - Salary from previous pay day (every 15th using the Government rate)
            --    nPrevAllo - Allowances from previous pay day (every 15th)
            --    nAllowances - Total allowance from current pay day
            
            --if i.empl_empl_id = '00145' then
            --   dbms_output.put_line ('emplID:' || i.empl_empl_id || '/' || 'nSalaryG:   ' || to_char(nSalaryG) ||  ', nOPPay:' || to_char(nvl(nOPPay,0)) || ', nOPAdj:' || to_char(nvl(nOPAdj,0)) || ', nOtPay:' || to_char(nvl(nOtPay,0)) || ', ' || 
            --                         'nSuPay:' || to_char(nvl(nSuPay,0)) || ', nHoPay:' || to_char(nvl(nHoPay,0)) || ', nHsPay:' || to_char(nvl(nHsPay,0)) || ', nAllowances:' || to_char(nvl(nAllowances,0)) || ', ' || 
            --                         'nPrevSal:' || to_char(nvl(nPrevSal,0)) || ', nPrevAllo:' || to_char(nvl(nPrevAllo,0)) );
            --end if;
            
            begin
               nSalaryG   := nSalaryG 
                           + nvl(nOPPay,0)  
                           + nvl(nOPAdj,0) 
                           + nvl(nOtPay,0) 
                           + nvl(nSuPay,0) 
                           + nvl(nHoPay,0) 
                           + nvl(nHsPay,0) 
                           + nvl(nPrevSal,0) 
                           + nvl(nPrevAllo,0) 
                           + nvl(nAllowances,0);
            end;
            
            --if i.empl_empl_id = '00145' then
            --   dbms_output.put_line ('emplID:' || i.empl_empl_id || '/' || 'nSalaryG   ' || to_char(nSalaryG) );
            --end if;
           
            -- compute SSS
            begin
            
               nSeqNo := nSeqNo + 1;
               if nSalaryG >= 1000 then   -- added by thess 04042008 to filter salaries less than 1000
                  sp_get_sss_contribution_er_ee (nSalaryG, nSSS, nSSS_ER, nSSS_EC);
               end if;   
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'SSS', nSSS, nSalaryG, i.dept_code, user, sysdate, 'LESS' );
            
               -- populate sss ER and EE contribution
               insert into pys_sss_contribution 
                      ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, created_by, dt_created )
               values ( dPrevStart, p_date_to, i.empl_empl_id, nSSS, nSSS_ER, nvl(nSSS_EC,0), user, sysdate );
             
            exception
               when OTHERS then
                  raise_application_error (-20001, SQLERRM || ' ERROR - sss contribution for ' || i.empl_empl_id || ' period: ' || to_char(dPrevStart) || '-' || to_char(p_date_to) || nSSS || '/' || nSSS_ER || '/' || nSSS_EC || '/' || to_char(nSalaryG)); 
           
            end;
            
            -- compute Pag-ibig
            begin
         
               nSeqNo := nSeqNo + 1;
               -- nPagibig := sf_get_pagibig_contribution(nBasic);
               sp_get_pagibig_ee_er (nSalaryG, nPagibig, nPagibig_ER);
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'PAGIBIG', nPagibig, nSalaryG, i.dept_code, user, sysdate, 'LESS' );
         
               -- populate pag-ibig ER and EE contribution
               insert into pys_pagibig_contribution 
                      ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
               values ( dPrevStart, p_date_to, i.empl_empl_id, nPagibig, nPagibig_ER, user, sysdate );              
         
            end;
            
            -- compute Philhealth
            begin
            
               nSeqNo := nSeqNo + 1;
               --nPhHealth := sf_get_philhealth_contribution(nBasic);
               sp_get_philhealth_ee_er (nSalaryG, nPhHealth, nPhHealth_ER);
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'PHILHEALTH', nPhHealth, nSalaryG, i.dept_code, user, sysdate, 'LESS' );
            
               -- populate pag-ibig ER and EE contribution
               insert into pys_philhealth_contribution 
                      ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
               values ( dPrevStart, p_date_to, i.empl_empl_id, nPhHealth, nPhHealth_ER, user, sysdate );              
                          
            end;
            
            -- compute WH TAX
            begin
             
               nSeqNo   := nSeqNo + 1;
               nTaxable := nvl(nSalaryG,0) - (nSSS + nPagibig + nPhHealth);
               if nTaxable >= 0 then  -- added by thess 04042008 to validate net taxable salary
                  nWhTax   := sf_get_whtax(i.empl_empl_id, i.taty_code, nTaxable);
               end if;  
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'WHTAX', nWhTax, nTaxable, i.dept_code, user, sysdate, 'LESS' );
               
            end;
            
            for z in dedu (i.empl_empl_id) loop 
               nSeqNo := nSeqNo + 1;
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, user, sysdate, 'LESS' );
               nDeduction := nvl(nDeduction,0) + z.amt;
            end loop;
         
            --nVale := nSalaryG-(nWhTax+nPhHealth+nPagibig+nSSS+nDeduction);
            --if nVale < 0 then
            --   begin
            --      insert into pys_deductions (seq_no, empl_empl_id, dety_code, start_date, end_date, no_payday, amt, frequency, total_amt)
            --      values (DEDU_SEQ.NEXTVAL, i.empl_empl_id, 'VALE', p_date_to, p_date_to+1, 1, nVale, 'MONTHLY', nVale);
            --   end;
            --end if;
         end if;                        -- END : Deduction Computation -- No Deduction for Employees with no Government rate

      end if;                           -- END: Tax Type checking  (no Deduction loop)

   end loop;

end sp_payroll_computation_a;
/
