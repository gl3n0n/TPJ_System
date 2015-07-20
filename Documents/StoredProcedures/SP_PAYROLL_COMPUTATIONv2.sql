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
   select b.empl_id empl_empl_id, b.basic_rate, b.basic_rate basic_rate_g, b.taty_code, b.posi_code posi_code, null title,
          null start_date, null end_date, 0 num_days, 0 num_hours, 0 ot_hours, 
          'OFC' empl_type, null voya_vess_code, null voya_voyage_date, null crew_no, b.dept_code dept_code
   from   pms_employees b
   where  exists (select 1 
   from   pms_attendance_records a
   where  a.empl_empl_id = b.empl_id
   AND    a.att_date between p_period_fr and p_period_to )
   union
   select vocr.empl_empl_id empl_empl_id, vocr.basic_rate, vocr.basic_rate_g, empl.taty_code, empl.posi_code posi_code, vocr.title,
          greatest(vocr.dt_embarked,p_period_fr) start_date, least(nvl(vocr.dt_disembarked,p_period_to),p_period_to) end_date, 
          ((least(nvl(vocr.dt_disembarked,p_period_to),p_period_to))-(greatest(vocr.dt_embarked,p_period_fr)))+1 num_days, 
          (((least(nvl(vocr.dt_disembarked,p_period_to),p_period_to))-(greatest(vocr.dt_embarked,p_period_fr)))+1) * 8 num_hours,
          0 ot_hours, 'FLT' empl_type, vocr.voya_vess_code voya_vess_code, vocr.voya_voyage_date, seq_no creq_no, null dept_code
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date between p_period_fr and p_period_to
   and    vocr.dt_embarked <= p_period_to
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   union
   select b.empl_id empl_empl_id, b.basic_rate, b.basic_rate basic_rate_g, b.taty_code, b.posi_code posi_code, null title,
          null start_date, null end_date, 0 num_days, 0 num_hours, 0 ot_hours, 
          'OFC' empl_type, null voya_vess_code, null voya_voyage_date, null crew_no, b.dept_code dept_code
   from   pms_employees b
   where  exists (select 1 
   from   pys_employee_salary a
   where  a.empl_empl_id = b.empl_id
   AND    a.sal_freq = 'MONTHLY');

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = p_effectivity
   group  by empl_empl_id, allo_code;

   --get allowances (FLT)
   cursor allo_flt ( p_empl_id in varchar2,  p_vessel in varchar2,  p_voya_date in varchar2 ) is
   select allo_code, amount amt
   from   cms_crew_allowances
   where  empl_empl_id = p_empl_id
   and    voya_vess_code = p_vessel
   and    voya_voyage_date = p_voya_date;

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
   and    start_date <= p_date_to 
   and    no_payday > 0;

   nSeqNo       Number;
   bNoDeduction Boolean;

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

   -- Overtime Rates per employee
   nOvertm_R    Number(8,3);
   nSunday_R    Number(8,3);
   nHoliday_R   Number(8,3);
   nHolSun_R    Number(8,3);
   nOuter_R     Number(8,3);
   nOutAd_R     Number(8,3);
   nSunday_T    Varchar2(16);
   nHoliday_T   Varchar2(16);
   nHolSun_T    Varchar2(16);

   -- Actual OT rendered (actual num hours)
   nOvertm      Number(5,2);
   nSunday      Number(5,2);
   nHoliday     Number(5,2);
   nHolSun      Number(5,2);
   nOuterNo     Number(5,2);
   nOuterAdj    Number(5,2);

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
   nSalaryR     Number(8,2);
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
   nAllowances  Number(5,2);
   dOuterFr     Date;
   dOuterTo     Date;
   dOutAdFr     Date;
   dOutAdTo     Date;
   dTmpDate     Date;

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
      bNoDeduction := TRUE;
   else
      bNoDeduction := FALSE;
   end if;

   if bNoDeduction then


      for i in attr ( p_date_fr, p_date_to ) loop

         -- check if Employee has assigned Tax Type 
         if i.taty_code is not null then
      
            -- get basic rate and salary mode/frequency
            if i.empl_type = 'OFC' then
               sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq );
            else 
               if i.basic_rate = 0 then
                  sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq );
               else 
                  nBasicR  := i.basic_rate;
                  nBasicG  := i.basic_rate_g;
                  vSalFreq := 'SEMI-MO';
               end if;
            end if;

               -- check attendance 
               if i.empl_type = 'OFC' then
                  sp_count_ofc_attendance ( i.empl_empl_id, p_date_fr, p_date_to, nNumHrs, nOvertm, nSunday, nHoliday, nHolSun, nOuterNo, dOuterFr, dOuterTo, nOuterAdj, dOutAdFr, dOutAdTo );
                  -- convert to hourly rate
                  nOvertm_R  := ( nOvertm_RO * nBasicR ) / 8;  
                  nSunday_R  := ( nSunday_RO * nBasicR ) / 8;  
                  nHoliday_R := ( nHoliday_RO * nBasicR ) / 8; 
                  nHolSun_R  := ( nHolSun_RO * nBasicR ) / 8;
                  nOuter_R   := ( nOuter_RO * nBasicR );
                  nOutAd_R   := ( nOutAd_RO * nBasicR );
                  nSunday_T  := 'OT-SUN-OFC'; 
                  nHoliday_T := 'OT-HOL-OFC'; 
                  nHolSun_T  := 'OT-HS-OFC';
               else
                  sp_count_flt_attendance ( i.empl_empl_id, i.start_date, i.end_date, nNumHrs, nSunday, nHoliday, nHolSun );
                  nOuterNo := 0;  nOuterAdj := 0;  nOvertm := 0;  nSunday := 0;  nHoliday := 0;  nHolSun  := 0;
               end if; 

               -- compute attendance 
               begin
                  nSeqNo  := nSeqNo + 1;
                  if vSalFreq = 'SEMI-MO' then
                     nSalaryR := nBasicR * nNumHrs;
                     nSalaryG := nBasicG * nNumHrs;
                  else
                     nSalaryR := nBasicR/2;
                     nSalaryG := nBasicG/2;
                     nOvertm := 0;  nSunday := 0;  nHoliday := 0;  nHolSun  := 0;
                  end if;

                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, i.title, 'REG', nSalaryR, nNumHrs, nBasicR, nSalaryG, nBasicG, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );

               end;
               
               if nOuterNo > 0 then
                  nSeqNo := nSeqNo + 1;
                  nOPPay := nOuter_R * nOuterNo;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, dOuterFr, dOuterTo, nSeqNo, i.empl_empl_id, i.posi_code, 'REG-OP', nOPPay, nOuterNo, nOuter_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               if nOuterAdj > 0 then
                  nSeqNo := nSeqNo + 1;
                  nOPAdj := nOutAd_R * nOuterAdj;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, dOutAdFr, dOutAdTo, nSeqNo, i.empl_empl_id, i.posi_code, 'REG-OP-ADJ', nOPAdj, nOuterAdj, nOutAd_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               if nOvertm > 0 then
                  nSeqNo := nSeqNo + 1;
                  nOtPay := nOvertm_R * nOvertm;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'OT-OFC', nOtPay, nOvertm, nOvertm_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               if nSunday > 0 then
                  nSeqNo := nSeqNo + 1;
                  nSuPay := nSunday_R * nSunday;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, nSunday_T, nSuPay, nSunday, nSunday_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               if nHoliday > 0 then
                  nSeqNo := nSeqNo + 1;
                  nHoPay := nHoliday_R * nHoliday;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, nHoliday_T, nHoPay, nHoliday, nHoliday_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               if nHolSun > 0 then
                  nSeqNo := nSeqNo + 1;
                  nHSPay := nHolSun_R * nHolSun;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, nHolSun_T, nHSPay, nHolSun, nHolSun_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               -- get allowances (OFC)
               if i.empl_type = 'OFC' then
                  dTmpDate := sf_latest_allowance_date (i.empl_empl_id, p_date_fr);
                  if dTmpDate is not null then
                     for x in allo (i.empl_empl_id, dTmpDate) loop 
                        nSeqNo := nSeqNo + 1;
                        insert into pys_payroll_dtl 
                               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                        values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*(nNumHrs+nOuterNo)), (nNumHrs+nOuterNo), x.amt, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
                     end loop;
                  end if;
               else
                  for x in allo_flt ( i.empl_empl_id, i.voya_vess_code,  i.voya_voyage_date  ) loop 
                     nSeqNo := nSeqNo + 1;
                     insert into pys_payroll_dtl 
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                     values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*(nNumHrs+nOuterNo)), (nNumHrs+nOuterNo), x.amt, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
                  end loop;
               end if;
            
         end if;
      end loop;

   else         

      -- get Max Previous Start
      select max(period_fr)
      into   dPrevStart
      from   pys_payroll_dtl;

      for i in attr ( dPrevStart, p_date_to ) loop
      
         if i.taty_code is not null then   -- START: Check Tax Type
      
            -- get previous salary
            begin
               select sum(amt_g), sum(no_days)
               into   nPrevSal, nPrevDays 
               from   pys_payroll_dtl
               where  empl_empl_id = i.empl_empl_id
               and    period_fr    = dPrevStart
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
               and    period_fr    = dPrevStart
               and    paty_code not like 'REG%';
            exception 
               when no_data_found then 
                  nPrevAllo := 0;
            end;

             -- get basic rate
            if i.empl_type = 'OFC' and vSalFreq = 'SEMI-MO' then
               sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq );
               nOvertm_R  := ( nOvertm_RO * nBasicR ) / 8;  
               nSunday_R  := ( nSunday_RO * nBasicR ) / 8;  
               nHoliday_R := ( nHoliday_RO * nBasicR ) / 8; 
               nHolSun_R  := ( nHolSun_RO * nBasicR ) / 8;        
               nOuter_R   := ( nOuter_RO * nBasicR );        
               nOutAd_R   := ( nOutAd_RO * nBasicR );
               nSunday_T  := 'OT-SUN-OFC'; 
               nHoliday_T := 'OT-HOL-OFC'; 
               nHolSun_T  := 'OT-HS-OFC';
               sp_count_ofc_attendance ( i.empl_empl_id, p_date_fr, p_date_to, nNumHrs, nOvertm, nSunday, nHoliday, nHolSun, nOuterNo, dOuterFr, dOuterTo, nOuterAdj, dOutAdFr, dOutAdTo  );
            else 
               if ( i.basic_rate = 0 ) or 
                  ( i.empl_type = 'OFC' and vSalFreq = 'MONTHLY')
               then
                  sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq );
               else 
                  nBasicR := i.basic_rate;
                  nBasicG := i.basic_rate_g;
               end if;
               sp_count_flt_attendance ( i.empl_empl_id, i.start_date, i.end_date, nNumHrs, nSunday, nHoliday, nHolSun );
               nSunday_R  := nSunday_RF  * nBasicR;  
               nHoliday_R := nHoliday_RF * nBasicR; 
               nHolSun_R  := nHolSun_RF  * nBasicR;  
               nOuterNo := 0;  nOuterAdj := 0;  nOvertm := 0;
               nSunday_T  := 'OT-SUN-FLT'; 
               nHoliday_T := 'OT-HOL-FLT'; 
               nHolSun_T  := 'OT-HS-FLT';
            end if;

            -- compute attendance 
            begin
               nSeqNo    := nSeqNo + 1;
               nSalaryR  := nBasicR * nNumHrs;
               nSalaryG  := nBasicG * nNumHrs;

               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, i.title, 'REG', nSalaryR, nNumHrs, nBasicR, nSalaryG, nBasicG, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );

               if nOuterNo > 0 then            
                  nSeqNo := nSeqNo + 1;
                  nOPPay := nOuterNo * nOuter_R;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, dOuterFr, dOuterTo, nSeqNo, i.empl_empl_id, i.posi_code, i.title, 'REG-OP', nOPPay, nOuterNo, nOuter_R, nSalaryG, nBasicG, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

               if nOuterAdj > 0 then
                  nSeqNo := nSeqNo + 1;
                  nOPAdj := nOutAd_R * nOuterAdj;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, dOutAdFr, dOutAdTo, nSeqNo, i.empl_empl_id, i.posi_code, 'REG-OP-ADJ', nOPAdj, nOuterAdj, nOutAd_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
               
               if nOvertm > 0 then
                  nSeqNo := nSeqNo + 1;
                  nOtPay := nOvertm_R * nOvertm;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'OT-OFC', nOtPay, nOvertm, nOvertm_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

               if nSunday > 0 then
                  nSeqNo := nSeqNo + 1;
                  nSuPay := nSunday_R * nSunday;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, nSunday_T, nSuPay, nSunday, nSunday_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
            
               if nHoliday > 0 then
                  nSeqNo := nSeqNo + 1;
                  nHoPay := nHoliday_R * nHoliday;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, nHoliday_T, nHoPay, nHoliday, nHoliday_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

               if nHolSun > 0 then
                  nSeqNo := nSeqNo + 1;
                  nHSPay := nHolSun_R * nHolSun;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, nHolSun_T, nHSPay, nHolSun, nHolSun_R, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

            end;
            
            -- get allowances (OFC)
            if i.empl_type = 'OFC' then
               dTmpDate := sf_latest_allowance_date (i.empl_empl_id, p_date_fr);
               if dTmpDate is not null then
                  nAllowances := 0;
                  for x in allo (i.empl_empl_id, dTmpDate) loop 
                     nSeqNo := nSeqNo + 1;
                     nAllowances := nAllowances + (x.amt*nNumHrs);
                     insert into pys_payroll_dtl 
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                     values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*(nNumHrs+nOuterNo)), nNumHrs, x.amt, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
                  end loop;
               end if;
            else
               nAllowances := 0;
               for x in allo_flt ( i.empl_empl_id, i.voya_vess_code,  i.voya_voyage_date ) loop 
                  nSeqNo := nSeqNo + 1;
                  nAllowances := nAllowances + (x.amt*nNumHrs);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*(nNumHrs+nOuterNo)), nNumHrs, x.amt, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end loop;
            end if;
            
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

            begin
               nSalaryG   := nSalaryG + nvl(nOPPay,0)  + nvl(nOPAdj,0) + nvl(nOtPay,0) + nvl(nSuPay,0) + nvl(nHoPay,0) + nvl(nHsPay,0) + nvl(nPrevSal,0) + nvl(nPrevAllo,0) + nvl(nAllowances,0);
            end;

            -- Employees with no Government rate are excluded from taxes/deductions
            if nvl(nBasicG,0) > 0  then    -- START: No Deduction for Employees with no Government rate

               -- compute SSS
               begin
               
                  nSeqNo := nSeqNo + 1;
                  sp_get_sss_contribution_er_ee (nSalaryG, nSSS, nSSS_ER, nSSS_EC);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'SSS', nSSS, 0, i.voya_vess_code, i.dept_code, user, sysdate, 'LESS' );
               
                  -- populate sss ER and EE contribution
                  insert into pys_sss_contribution 
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, created_by, dt_created )
                  values ( dPrevStart, p_date_to, i.empl_empl_id, nSSS, nSSS_ER, nvl(nSSS_EC,0), user, sysdate );
               
               end;
               
               -- compute Pag-ibig
               begin
               
                  nSeqNo := nSeqNo + 1;
                  -- nPagibig := sf_get_pagibig_contribution(nBasic);
                  sp_get_pagibig_ee_er (nSalaryG, nPagibig, nPagibig_ER);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'PAGIBIG', nPagibig, 0, i.voya_vess_code, i.dept_code, user, sysdate, 'LESS' );
               
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
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'PHILHEALTH', nPhHealth, 0, i.voya_vess_code, i.dept_code, user, sysdate, 'LESS' );
               
                  -- populate pag-ibig ER and EE contribution
                  insert into pys_philhealth_contribution 
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
                  values ( dPrevStart, p_date_to, i.empl_empl_id, nPhHealth, nPhHealth_ER, user, sysdate );
               
               end;
               
               -- compute WH TAX
               begin
                  nSeqNo   := nSeqNo + 1;
                  nTaxable := nvl(nSalaryG,0) - (nSSS + nPagibig + nPhHealth);
                  nWhTax   := sf_get_whtax(i.empl_empl_id, i.taty_code, nTaxable);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'WHTAX', nWhTax, 0, i.voya_vess_code, i.dept_code, user, sysdate, 'LESS' );
               end;
               
               -- get loans/deductions
               for z in dedu (i.empl_empl_id) loop 
                  nSeqNo := nSeqNo + 1;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.voya_vess_code, i.dept_code, user, sysdate, 'LESS' );
               end loop;

            end if;                        -- END : No Deduction for Employees with no Government rate

         end if;                           -- END: Check Tax Type

      end loop;

   end if;

end sp_payroll_computation_a;
/
show err
