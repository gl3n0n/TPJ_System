create or replace procedure sp_count_ofc_attendance
(
   p_empl_id    in  varchar2, 
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2, 
   p_date_fr    in  date, 
   p_date_to    in  date, 
   p_dept_code  in  varchar2, 
   p_posi_code  in  varchar2, 
   p_isMonthly  in  varchar2,    -- monthly but non-manager
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Overtm_RO  in  number,
   p_Sunday_RO  in  number,
   p_Holiday_RO in  number,
   p_HolSun_RO  in  number,
   p_Outer_RO   in  number,
   p_OutAd_RO   in  number,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2, 
   p_numday     out number, 
   p_tsalaryg   out number, 
   p_otpay      out number, 
   p_supay      out number, 
   p_hopay      out number, 
   p_hspay      out number,
   p_OPPay      out number,
   p_OAPay      out number,
   p_Allowance  out number,
   p_o_seq_no   out number
   
) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_period_fr in date, p_period_to in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date between p_period_fr and p_period_to
   union
   select tx_date, null, null, null, null, 6, 0, 'N'
   from   pys_holidays
   where  tx_date between p_period_fr and p_period_to
   and    tx_date not in (select att_date from pms_attendance_records where empl_empl_id = p_empl_id and att_date between p_period_fr and p_period_to)
   order  by tx_date;

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, amt, eff_st_date --max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select eff_st_date 
                         from pys_employee_salary
                         where empl_empl_id = p_empl_id
                         and eff_en_date is null) -- added by thess 1/7/08-- p_effectivity
   group  by empl_empl_id, allo_code, amt, eff_st_date;

   nNumHrs   Number (7,3) := 0;
   nOvertm   Number (7,3) := 0;
   nRegHol   Number (7,3) := 0;
   nHolOT    Number (7,3) := 0;
   nRegSun   Number (7,3) := 0;
   nCOLA     Number (7,3) := 0;
   nUpTO     Number := 0;
   bHolSun   Boolean;
   nDay      Number (5,2) := 0;
   dDate     Date := p_date_fr;
   dTxDate   Date;
   dStart    Date;
   dEnd      Date;
   nTmpHrs   Number (7,3) := 0;
   nDeduct   Number (7,3) := 0;
   nAssume   Number (7,3) := 0;
   nOuterNo  Number (7,3) := 0;
   nOuterAd  Number (7,3) := 0;
   dOuterFr  Date;
   dOuterTo  Date;
   dOutadFr  Date;
   dOutadTo  Date;
   onOuter   Boolean;

   -- for Outer port Overtime rate
   nOPOvertm    Number (7,3) := 0;
   nOPRegHol    Number (7,3) := 0;
   nOPHolOT     Number (7,3) := 0;
   nOPOtPay     Number(8,2) := 0;
   nOPHoPay     Number(8,2) := 0;
   nOPHSPay     Number(8,2) := 0;
   nOPOvertm_R  Number(8,3) := 0;
   nOPHoliday_R Number(8,3) := 0;
   nOPHolOT_R   Number(8,3) := 0;
   nOPSunday    Number(8,3) := 0;
   
   nSeqNo       Number;
   nSalaryR     Number(8,2) := 0;
   nSalaryG     Number(8,2) := 0;
   nSunday_R    Number(8,3) := 0;
   nHoliday_R   Number(8,3) := 0;
   nHolOT_R    Number(8,3) := 0;
   nOuter_R     Number(8,3) := 0;
   nOutAd_R     Number(8,3) := 0;
   nOtPay       Number(8,2) := 0;
   nSuPay       Number(8,2) := 0;
   nHoPay       Number(8,2) := 0;
   nHSPay       Number(8,2) := 0;
   nOPPay       Number(8,2) := 0;
   nOPAdj       Number(8,2) := 0;
   nOvertm_R    Number(8,3) := 0;
   nAllowances  Number(8,2) := 0;
   dTmpDate     Date;
   bNoOuterAdj  Boolean := FALSE;
   vSalFreq     Varchar2(16);
   
   nSunday_T    Varchar2(16) := 'OT-SUN-OFC';
   nHoliday_T   Varchar2(16) := 'OT-HOL-OFC';
   nHolOT_T     Varchar2(16) := 'OT-HOL-EXC';
   dEmplID      varchar2(16) := p_dEmplID;

begin

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 1: dEmplID=' || dEmplID || ', dStart: ' || to_char(dStart) || ', dEnd: ' || to_char(dEnd) || ',p_basic_r:' || to_char(p_basic_r) || ',p_basic_g:' || to_char(p_basic_g));
   end if;
   
   if p_isMonthly = 'Y' then 
      vSalFreq := 'MONTHLY'; 
   else 
      vSalFreq := 'SEMI-MO'; 
   end if;

   for j in atre ( p_empl_id, dStart, dEnd ) loop

      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 2: j.tx_date: ' || to_char(j.tx_date) || ' j.num_hours: ' || to_char(j.num_hours) || ' j.outer_port:' || j.outer_port || ' j.ot_hours:' || to_char(j.ot_hours) || ',nNumHrs:' || to_char(nNumHrs));
      end if;
      nDay  := nDay + 1;
      dDate := j.tx_date;
      nTmpHrs := 0;
      onOuter := FALSE;
      if j.outer_port = 'Y' then

         if dDate >= p_date_fr then
            nOuterNo := nOuterNo + 1;
            if dOuterFr is null then
               dOuterFr := j.tx_date;
            end if;
            dOuterTo := j.tx_date;
            onOuter := TRUE;
         else
            -- these were already assumed from previous payroll 
            if dDate = dStart then
               bNoOuterAdj := TRUE;
            end if;
            if bNoOuterAdj then
               -- no adjustment; nothing to compute
               null;
            else
               nOuterAd := nOuterAd + 1;
               if dOutadFr is null then
                  dOutadFr := j.tx_date;
               end if;
               dOutadTo := j.tx_date;
            end if;
         end if;

         -- sunday 15+Sundays
         if sf_is_sunday (dDate) = 1 then
            if j.num_hours >= 0  then
               nOPSunday := nOPSunday + 1;
            end if;
         end if;

         -- holiday
         if sf_is_holiday (dDate) = 1 then
            if j.am_time_in is not null then
               if j.num_hours >= 6  then
                  nOPRegHol := nOPRegHol + 8;
                  nOPHolOT := nOPHolOT + j.ot_hours;
               else 
                  nOPRegHol := nOPRegHol + ((j.num_hours/6)*8);
               end if;
            end if;
         end if;

         -- Overtime
         if j.num_hours >= 8  then
            nOPOvertm := nOPOvertm + j.ot_hours;
         end if;

      else
         if sf_is_sunday (dDate) = 1 then
            if sf_is_holiday (dDate) = 1 then
               if j.am_time_in is not null then
                  if j.num_hours >= 4  then
                     nTmpHrs := nTmpHrs + 8;
                     nRegHol := nRegHol + 8;
                     nHolOT := nHolOT + j.ot_hours;
                  else 
                     nTmpHrs := nTmpHrs + 8;
                     nRegHol := nRegHol + (j.num_hours/4)*(8);
                  end if;
               else
                  nTmpHrs := nTmpHrs + 8;
               end if; 
            else
               if j.num_hours >= 4  then
                  nTmpHrs := nTmpHrs + 8;
                  if p_IsMonthly='N' then
                     nRegSun := nRegSun + j.ot_hours;
                  end if;
               else 
                  nTmpHrs := nTmpHrs + ((j.num_hours/4)*(8));
               end if;
            end if; 
         elsif sf_is_holiday (dDate) = 1 then
            if j.am_time_in is not null then
               if j.num_hours >= 6  then
                  nTmpHrs := nTmpHrs + 8;
                  nRegHol := nRegHol + 8;
                  nHolOT := nHolOT + j.ot_hours;
               else 
                  nRegHol := ((j.num_hours/6)*8);
               end if;
            else
               nTmpHrs := nTmpHrs + 8;
            end if;
         else
            -- Overtime
            if j.num_hours >= 8  then
               nTmpHrs := 8;
            else
               nTmpHrs := j.num_hours;
            end if;
            nOvertm := nOvertm + j.ot_hours;
         end if;  

         -- count only days from start of period to cutoff date
         if dDate >= p_date_fr then
            nNumHrs  := nNumHrs + nTmpHrs;
         -- except sunday and holiday falls on previous assume days, should be included on current payroll.
         elsif (sf_is_holiday (dDate) = 1) or 
               (sf_is_sunday (dDate) = 1) 
         then
            nNumHrs  := nNumHrs + nTmpHrs;
         end if;  

      end if;

   end loop;
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 3: nNumHrs: ' || to_char(nNumHrs/8) || ',nOuterNo:' || to_char(nOuterNo) || 
                            ' nRegHol: ' || to_char(nRegHol/8) || ' nRegSun: ' || to_char(nRegSun/8)  ||
                            ' nHolOT: ' || to_char(nHolOT/8)  || ',dEnd:' || to_char(dEnd));
   end if;

   -- ADD from Cutoff date to End of Month
   nUpTo   := (p_date_to-dEnd); 
   nAssume := 0;  
   for i in 1..nUpTo loop
      dDate := dEnd + i;
      if onOuter then
         nAssume := nAssume + 8;
      elsif sf_is_sunday (dDate) = 0 then
         nAssume := nAssume + 8;
      end if;
   end loop;
   -- end Cutoff date
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check nAssume: ' || to_char(nAssume) );
   end if;

   -- LESS from previous Cutoff date to End of previous Month
   nUpTo   := (p_date_fr-dStart); 
   nTmpHrs := 0;  
   nDeduct := 0;  
   for i in 1..nUpTo loop
      dDate := dStart + (i-1);
      -- check if not SUNDAY and not HOLIDAY
      if (sf_is_sunday (dDate) = 0) and (sf_is_holiday (dDate) = 0) then
         begin
            select num_hours
            into   nTmpHrs 
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dDate;
         exception
            when no_data_found then 
               nTmpHrs := 0;
         end;
         if nTmpHrs < 8 then
            nDeduct := nDeduct + (8-nTmpHrs);
         end if;
      end if;
   end loop;
   -- end Cutoff date
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check nDeduct: ' || to_char(nDeduct) );
   end if;

   if onOuter then
      nOuterNo := (nOuterNo+(nAssume/8)); 
      nNumHrs  := (nNumHrs-nDeduct)/8; 
      if nOuterNo >= 15 and p_IsMonthly='Y' then
         nOuterNo := 15 + nOPSunday;
      end if;
   else
      nNumHrs := ((nNumHrs+nAssume)-nDeduct)/8;
      if nNumHrs >= 14 and p_IsMonthly='Y' then
         nNumHrs := nNumHrs + 1;
      end if;
   end if;

   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 4: nNumHrs: ' || to_char(nNumHrs) || ' nOvertm_R: ' || to_char(nOvertm_R) || 
                            ' nSunday_R: ' || to_char(nSunday_R)  || ' nHoliday_R: ' || to_char(nHoliday_R) ||
                            ' nHolOT_R: ' || to_char(nOuter_R)  || ' nHoliday_R: ' || to_char(nOutAd_R));
   end if;

   -- compute attendance 
   begin
      nSeqNo  := nSeqNo + 1;
    
      nSalaryR := p_basic_r * nNumHrs;
      -- all office staff has fixed monthly government rate
      nSalaryG := p_basic_g/2;

      if nNumHrs <> 0 then
         insert into pys_payroll_dtl 
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, 'REG', nSalaryR, nNumHrs, p_basic_r, nSalaryG, p_basic_g, p_dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;
   end;

   -- use outerport rate
   nOvertm_R  := ( p_Overtm_RO * p_basic_r );  
   nSunday_R  := ( p_Sunday_RO * p_basic_r );  
   nHoliday_R := ( p_Holiday_RO * p_basic_r ); 
   nHolOT_R  := ( p_HolSun_RO * p_basic_r );
   nOuter_R   := ( p_Outer_RO * p_basic_r );
   nOutAd_R   := ( p_OutAd_RO * p_basic_r );
   nOPOvertm_R  := ( p_Overtm_RO * nOuter_R  );  
   nOPHoliday_R := ( p_Holiday_RO * nOuter_R  ); 
   nOPHolOT_R  := ( p_HolSun_RO * nOuter_R  );

   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 5: p_basic_r: ' || to_char(p_basic_r) || ' nOvertm_R: ' || to_char(nOvertm_R) || 
                            ' nSunday_R: ' || to_char(nSunday_R)  || ' nHoliday_R: ' || to_char(nHoliday_R) ||
                            ' nHolOT_R: ' || to_char(nOuter_R)  || ' nHoliday_R: ' || to_char(nOutAd_R));
   end if;

   if nOuterNo > 0 then
      nSeqNo := nSeqNo + 1;
      nOPPay := nOuter_R * nOuterNo;
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, dOuterFr, dOuterTo, nSeqNo, p_empl_id, p_posi_code, 'REG-OP', nOPPay, nOuterNo, nOuter_R, nSalaryG, p_basic_g, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;
   
   if nOuterAd > 0 then
      nSeqNo := nSeqNo + 1;
      nOPAdj := nOutAd_R * nOuterAd;
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, dOutAdFr, dOutAdTo, nSeqNo, p_empl_id, p_posi_code, 'REG-OP-ADJ', nOPAdj, nOuterAd, nOutAd_R, nOPAdj, nOutAd_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;
   
   if nOvertm > 0 then
      nSeqNo := nSeqNo + 1;
      nOtPay := nOvertm_R * (nOvertm/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, 'OT-OFC', nOtPay, (nOvertm/8), nOvertm_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;
   
   if nRegSun > 0 then
      nSeqNo := nSeqNo + 1;
      nSuPay := nSunday_R * (nRegSun/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nSunday_T, nSuPay, (nRegSun/8), nSunday_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;
   
   if nRegHol > 0 then
      nSeqNo := nSeqNo + 1;
      nHoPay := nHoliday_R * (nRegHol/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHoliday_T, nHoPay, (nRegHol/8), nHoliday_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;
   
   if nHolOT > 0 then
      nSeqNo := nSeqNo + 1;
      nHSPay := nHolOT_R * (nHolOT/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHolOT_T, nHSPay, (nHolOT/8), nHolOT_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;

   -- Outer port Overtime, Reg Holiday, and Holiday OT
   if nOPOvertm > 0 then
      nSeqNo := nSeqNo + 1;
      nOPOtPay := nOPOvertm_R * (nOPOvertm/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, 'OT-OFC', nOPOtPay, (nOPOvertm/8), nOPOvertm_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;
   
   if nOPRegHol > 0 then
      nSeqNo := nSeqNo + 1;
      nOPHoPay := nOPHoliday_R * (nOPRegHol/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHoliday_T, nOPHoPay, (nOPRegHol/8), nOPHoliday_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;

   if nOPHolOT > 0 then
      nSeqNo := nSeqNo + 1;
      nOPHSPay := nOPHolOT_R * (nHolOT/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHolOT_T, nOPHSPay, (nOPHolOT/8), nOPHolOT_R, null, p_dept_code, user, sysdate, 'ADD', vSalFreq );
   end if;

   -- get allowances (OFC)
   dTmpDate := sf_latest_allowance_date (p_empl_id, p_date_fr);
   if dTmpDate is not null then
      for x in allo (p_empl_id, dTmpDate) loop 
         nSeqNo := nSeqNo + 1;
         nAllowances := nAllowances + (x.amt*(nNumHrs+nOuterNo));
         insert into pys_payroll_dtl 
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, x.allo_code, (x.amt*(nNumHrs+nOuterNo)), (nNumHrs+nOuterNo), x.amt, p_dept_code, user, sysdate, 'ADD', vSalFreq );
      end loop;
   end if;

   p_numday    := nNumHrs;
   p_tsalaryg  := nSalaryG;
   p_SuPay     := nSuPay;
   p_OTPay     := nOtPay+nOPOtPay;
   p_HoPay     := nHoPay+nHoPay;
   p_HSPay     := nHSPay+nHSPay;
   p_OPPay     := nOPPay;
   p_OAPay     := nOPAdj;
   p_Allowance := nAllowances;
   p_o_seq_no  := nSeqNo;

   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 6: p_numday: ' || to_char(p_numday) || ' p_tsalaryg: ' || to_char(p_tsalaryg) || 
                            ' p_SuPay: ' || to_char(p_SuPay)  || ' p_HoPay: ' || to_char(p_HoPay) ||
                            ' p_HSPay: ' || to_char(p_HSPay)  || ' p_OPPay: ' || to_char(p_OPPay) ||
                            ' p_OAPay: ' || to_char(p_OAPay)  || ' p_Allowance: ' || to_char(p_Allowance));
   end if;

end sp_count_ofc_attendance;
/
