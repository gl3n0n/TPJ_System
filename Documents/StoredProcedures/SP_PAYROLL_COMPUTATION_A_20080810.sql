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
   and    dety_code <> ('VALE'); -- not to include VALE in Payroll deductions for fleet; should be deducted from Incentives

   --get ofc employee deductions
   cursor ofc_dedu (p_empl_id in varchar2) is
   select empl_empl_id, dety_code, seq_no, amt
   from   pys_deductions
   where  empl_empl_id = p_empl_id
   and    end_date  >= p_date_to
   and    start_date <= p_date_to; -- include VALE in Payroll deductions for ofc;

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
   vIsManager   varchar2(2);
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
   vLatestVess  Varchar2(32);
   vLatestTitle Varchar2(32);
   nSalaryG_D   Number(8,2);
   nSalaryG_B   Number(8,2);
   nSalaryG_R   Number(8,2);
   dPeriodTOG   Date;
   bFixMonthly  Boolean;

   dEmplID      varchar2(16) := 'M00002';

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
      dPrevStart     := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      --dPrevStart     := p_date_fr;

   else

      bWithDeduction := TRUE;

      -- get Max Previous Start
      select payroll_no, period_fr
      into   nPayNo, dPrevStart
      from   pys_payroll_hdr
      where  period_fr = to_date(to_char(p_date_to, 'YYYYMM') || '01', 'YYYYMMDD');

   end if;

   dbms_output.put_line ('check M0: dPrevStart:' || to_char(dPrevStart)  || ',p_date_to:' || to_char(p_date_to) );
   for i in attr ( dPrevStart, p_date_to ) loop

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
      vLatestVess := null;
      vLatestTitle := null;
      nSalaryG_D  := 0;
      nSalaryG_B  := 0;
      bFixMonthly := FALSE;

      -- get basic rate and salary mode/frequency
      -- check attendance
      vSalFreq := i.sal_freq;
      if i.empl_type = 'OFC' then
         sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq, vIsManager );
      end if;


      if i.empl_empl_id = dEmplID then
         dbms_output.put_line ('check M00:' || i.empl_empl_id || ',nBasicG:' || to_char(nBasicG) ||
                                ',nBasicR:' || to_char(nBasicR) || ',i.empl_type:' || i.empl_type|| 
                                ',vSalFreq:' || vSalFreq || ',vIsManager:' || vIsManager);
      end if;

       -- check if Employee has assigned Tax Type
      if i.taty_code is not null then         -- START: Tax Type checking (no Deduction loop)

         if i.empl_type = 'OFC' then
            if vSalFreq = 'MONTHLY' then
               if vIsManager = 'Y' then
                  sp_count_mgr_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, nBasicR, nBasicG,
                                            nSunday_RO, nHoliday_RO, nHolSun_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nSuPay, nHoPay, nHSPay, nAllowances, nSeqNo);
               else
                  sp_count_ofc_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                                i.dept_code, i.posi_code, 'Y', nBasicR, nBasicG,
                                                nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO, dEmplID );

                  sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, 'Y', nBasicR, nBasicG,
                                            nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
               end if;
            else
               sp_count_ofc_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                             i.dept_code, i.posi_code, 'N', nBasicR, nBasicG,
                                             nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO, dEmplID );

               sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                         i.dept_code, i.posi_code, 'N', nBasicR, nBasicG,
                                         nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                         nSeqNo, dEmplID, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
            end if;
         else
            sp_count_flt_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                          nSunday_RF, nHoliday_RF, nHolSun_RF, dEmplID, vSalFreq );

            sp_count_flt_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                      nSunday_RF, nHoliday_RF, nHolSun_RF,
                                      vSalFreq, nSeqNo, dEmplID, vLatestVess, vLatestTitle, nSeqNo);
         end if;

         -- Start Compution for deductions
         -- No Deduction for Employees with no Government rate


         if i.empl_empl_id = dEmplID then
            dbms_output.put_line ('check M1:' || i.empl_empl_id || ',nSalaryG:' || to_char(nSalaryG) ||
                                  ',vIsManager:' || vIsManager || ',nPayNo:' || to_char(nPayNo) || ',p_payno:' || to_char(p_payno));
         end if;


         if (bWithDeduction) then

            for k in (select BASIC_RATE_G, basic_rate, dept_code, SAL_FREQ, no_days, period_to
                      from   pys_payroll_dtl
                      where  empl_empl_id = i.empl_empl_id
                      and    pahd_payroll_no = p_payno
                      and    paty_code like 'REG%'
                      union
                      select BASIC_RATE_G, basic_rate, dept_code, SAL_FREQ, no_days, period_to
                      from   pys_payroll_dtl
                      where  empl_empl_id = i.empl_empl_id
                      and    pahd_payroll_no = nPayNo
                      and    paty_code like 'REG%'
                      order  by period_to desc)
            loop
               if i.empl_empl_id = dEmplID then
                  dbms_output.put_line ('check M2a: k.sal_freq:' || k.sal_freq || ',k.dept_code:' || k.dept_code ||
                                        ', k.BASIC_RATE_G:' || to_char(k.BASIC_RATE_G));
               end if;
               if k.sal_freq = 'MONTHLY' then
                  if k.dept_code='FL' then
                     --nSalaryG_B := k.BASIC_RATE_G/30;  -- check crew
                     nSalaryG_B := k.BASIC_RATE;  -- check crew
                  else
                     nSalaryG_B := k.BASIC_RATE_G;
                     bFixMonthly := TRUE;
                  end if;
               else
                  if k.dept_code='FL' then
                     nSalaryG_B := k.BASIC_RATE;
                  else
                     nSalaryG_B := k.BASIC_RATE_G;
                     bFixMonthly := TRUE;
                  end if;
               end if;
               dPeriodTOG := k.period_to;
               exit;
            end loop;
            for k in (select paty_code, sum(no_days) no_days
                      from   pys_payroll_dtl
                      where  pahd_payroll_no = p_payno
                      and    empl_empl_id = i.empl_empl_id
                      group  by paty_code
                      union all
                      select paty_code, sum(no_days) no_days
                      from   pys_payroll_dtl
                      where  pahd_payroll_no = nPayNo
                      and    empl_empl_id = i.empl_empl_id
                      group  by paty_code
                      )
            loop
               if i.empl_empl_id = dEmplID then
                  dbms_output.put_line ('check M2b: k.paty_code:' || k.paty_code || ', k.no_days:' || to_char(k.no_days));
               end if;
               if k.paty_code not like 'REG%' then
                  -- get ot, hol, sun, holsun rates
                  begin
                     select a.rate into nSalaryG_R from pys_payroll_types a where a.code=k.paty_code;
                  exception
                     when others then nSalaryG_R := 1;
                  end;
                  nSalaryG_D := nSalaryG_D + (k.no_days*nSalaryG_R);
               else
                  nSalaryG_D := nSalaryG_D + k.no_days;
               end if;
            end loop;

            if i.empl_empl_id = dEmplID then
               dbms_output.put_line ('check M2: nSalaryG_D:' || to_char(nSalaryG_D) || ',' || 'nSalaryG_B:' || to_char(nSalaryG_B) ||
                                     ', dPrevStart:' || to_char( dPrevStart) || ', p_date_to:' || to_char( p_date_to));
            end if;

            begin
               if dPeriodTOG is null then
                  dPeriodTOG := p_date_to;
               end if;
               if bFixMonthly then
                  nSalaryG   := nvl(nSalaryG_B,0);
               else
                  nSalaryG   := (nvl(nSalaryG_D,0)* nvl(nSalaryG_B,0));
               end if;
            end;

            if i.empl_empl_id = dEmplID then
               dbms_output.put_line ('check M3: nSalaryG:   ' || to_char(nSalaryG) ||  ', nOPPay:' || to_char(nvl(nOPPay,0)) || ', nOPAdj:' || to_char(nvl(nOPAdj,0)) || ', nOtPay:' || to_char(nvl(nOtPay,0)) || ', ' ||
                                     'nSuPay:' || to_char(nvl(nSuPay,0)) || ', nHoPay:' || to_char(nvl(nHoPay,0)) || ', nHsPay:' || to_char(nvl(nHsPay,0)) || ', nAllowances:' || to_char(nvl(nAllowances,0)) || ', ' ||
                                     'nPrevSal:' || to_char(nvl(nPrevSal,0)) || ', nPrevAllo:' || to_char(nvl(nPrevAllo,0)) );
            end if;

            if (nvl(nSalaryG,0) > 0) then
               -- compute SSS
               begin
                  --if nSalaryG >= 1000 then   -- added by thess 04042008 to filter salaries less than 1000
                     nSeqNo := nSeqNo + 1;
                     sp_get_sss_contribution_er_ee (nSalaryG, nSSS, nSSS_ER, nSSS_EC);
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     values ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'SSS', nSSS, nSalaryG, i.dept_code, user, sysdate, 'LESS', vSalFreq, vLatestVess, vLatestTitle );

                     -- populate sss ER and EE contribution
                     insert into pys_sss_contribution
                            ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, created_by, dt_created )
                     values ( dPrevStart, p_date_to, i.empl_empl_id, nSSS, nSSS_ER, nvl(nSSS_EC,0), user, sysdate );
                  --end if;
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
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                  values ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'PAGIBIG', nPagibig, nSalaryG, i.dept_code, user, sysdate, 'LESS', vSalFreq, vLatestVess, vLatestTitle );

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
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_Freq, latest_vess, title )
                  values ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'PHILHEALTH', nPhHealth, nSalaryG, i.dept_code, user, sysdate, 'LESS', vSalFreq, vLatestVess, vLatestTitle );

                  -- populate pag-ibig ER and EE contribution
                  insert into pys_philhealth_contribution
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
                  values ( dPrevStart, p_date_to, i.empl_empl_id, nPhHealth, nPhHealth_ER, user, sysdate );

               end;

               -- compute WH TAX
               begin
                  nTaxable := nvl(nSalaryG,0) - (nSSS + nPagibig + nPhHealth);
                  if nTaxable >= 0 then  -- added by thess 04042008 to validate net taxable salary
                     nSeqNo   := nSeqNo + 1;
                     nWhTax   := sf_get_whtax(i.empl_empl_id, i.taty_code, nTaxable);
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     values ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'WHTAX', nWhTax, nTaxable, i.dept_code, user, sysdate, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                  end if;
               end;

            end if;                     -- END : No salary

            if (nvl(nSalaryG,0) <> 0) then
               -- Deductions
               if i.empl_type = 'FL' then
                  for z in dedu (i.empl_empl_id) loop
                     nSeqNo := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     values ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, user, sysdate, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                     nDeduction := nvl(nDeduction,0) + z.amt;
                  end loop;
               else
                  for z in ofc_dedu (i.empl_empl_id) loop
                     begin
                        nSeqNo := nSeqNo + 1;
                        insert into pys_payroll_dtl
                               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                        values ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, user, sysdate, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                        nDeduction := nvl(nDeduction,0) + z.amt;
                     exception
                        when others then
                           raise_application_error (-20001, SQLERRM || ' ERROR - deductions ' || i.empl_empl_id || ' z.amt: ' || to_char(z.amt) || ',z.dety_code:' || to_char(z.dety_code) );
                     end;
                  end loop;

                  --nVale := nSalaryG-(nWhTax+nPhHealth+nPagibig+nSSS+nDeduction);
                  --if nVale < 0 then
                  --   nVale := nVale * -1;
                  --   begin
                  --      update pys_deductions
                  --      set    total_amt = total_amt + (nVale-amt)
                  --      where  empl_empl_id = i.empl_empl_id
                  --      and    dety_code = 'VALE'
                  --      and    amt <> nVale;
                  --      if sql%NOTFOUND then
                  --         insert into pys_deductions (seq_no, empl_empl_id, dety_code, start_date, end_date, no_payday, amt, frequency, total_amt, dt_created, created_by )
                  --         values (DEDU_SEQ.NEXTVAL, i.empl_empl_id, 'VALE', p_date_to, p_date_to+1, 1, 0, 'MO', nVale, sysdate, user);
                  --      end if;
                  --      insert into pys_deductions_log (empl_empl_id, pahd_payroll_no, amt, dt_created, created_by )
                  --      values (i.empl_empl_id, p_payno, nVale, sysdate, user);
                  --   end;
                  --end if;
               end if;
            end if;
         end if;                        -- END : Deduction Computation -- No Deduction for Employees with no Government rate

      end if;                           -- END: Tax Type checking  (no Deduction loop)

   end loop;

end sp_payroll_computation_a;
/
