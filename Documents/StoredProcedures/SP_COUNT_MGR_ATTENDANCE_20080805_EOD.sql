create or replace procedure sp_count_mgr_attendance
(
   p_empl_id    in  varchar2, 
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2, 
   p_date_fr    in  date, 
   p_date_to    in  date, 
   p_dept_code  in  varchar2, 
   p_posi_code  in  varchar2, 
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Sunday_RF  in  number,
   p_Holiday_RF in  number,
   p_HolSun_RF  in  number,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2, 
   p_numday     out number, 
   p_tsalaryg   out number, 
   p_supay      out number, 
   p_hopay      out number, 
   p_hspay      out number,
   p_Allowance  out number,
   p_o_seq_no   out number

) is
    
   --get attendance
   cursor atre (p_empl_id in varchar2, p_date in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date = p_date;

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, amt, eff_st_date --max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date) 
                         from pys_employee_salary
                         where empl_empl_id = p_empl_id
                         and eff_st_date <= p_effectivity) -- added by thess 1/7/08-- p_effectivity
   group  by empl_empl_id, allo_code, amt, eff_st_date;

   nNumHrs   Number (7,3) := 0;
   nNumDay    Number := 0;
   nRegHol    Number := 0;
   nHolSun    Number := 0;
   nRegSun    Number := 0;
   nUpTO      Number := 0;
   nTmpHrs    Number (7,3) := 0;
   dDate      Date;
   dStart     Date;
   dend       Date; 
   dPrevStart Date;
   dPrevend   Date; 
   dFirstDay  Date;
   nRecCtr    Number := 0;
   bIsEndOfMonth Boolean;

   nSeqNo       Number;
   nSalaryR     Number(8,2) := 0;
   nSalaryG     Number(8,2) := 0;
   nSunday_R    Number(8,3) := 0;
   nHoliday_R   Number(8,3) := 0;
   nHolSun_R    Number(8,3) := 0;
   nSuPay       Number(8,2) := 0;
   nHoPay       Number(8,2) := 0;
   nHSPay       Number(8,2) := 0;
   nAllowances  Number(8,2);
   nTSalaryG    Number(8,2) := 0;
   nTSuPay      Number(8,2) := 0;
   nTHoPay      Number(8,2) := 0;
   nTHSPay      Number(8,2) := 0;
   nTNumDay     Number := 0;
   nTRegSun     Number := 0;
   nTRegHol     Number := 0;
   nTHolSun     Number := 0;
   dTmpDate     Date;

   nHolOT    Number (7,3) := 0;
   nHolOT_R     Number(8,3) := 0;
   nSunday_T    Varchar2(16) := 'OT-SUN-OFC';
   nHoliday_T   Varchar2(16) := 'OT-HOL-OFC';
   nHolOT_T     Varchar2(16) := 'OT-HOL-EXC';
   dEmplID      varchar2(16) := p_dEmplID;

begin  

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   --if to_char(p_date_to,'DD') = '15' then
   --   nUpTo := (p_date_to - dStart) + 1;
   --else  
   --   nUpTo := (p_date_to - dStart) ;
   --end if;

   nUpto := (dEnd - dStart)+1;
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 1: p_empl_id=' || p_empl_id || ',dStart=' || to_char(dStart) || ',dEnd=' || to_char(dEnd) || ' nUpto=' || to_char(nUpto));
   end if;
   for k in 1..nUpto loop
      dDate := (dStart-1) + k;
      nTmpHrs := 0;
      if sf_is_sunday (dDate) = 1 then
         if sf_is_holiday (dDate) = 1 then
            for j in atre (p_empl_id, dDate) loop
               --if j.num_hours >= 4  then
               if j.num_hours > 0  then  -- if present
                  nRegHol := nRegHol + 8;
               end if;
            end loop;
         else
            for j in atre (p_empl_id, dDate) loop
               --if j.num_hours >= 4  then 
               if j.num_hours > 0  then    -- if present
                  nTmpHrs := nTmpHrs + 8;
               end if;
            end loop;
         end if; 
      elsif sf_is_holiday (dDate) = 1 then
         for j in atre (p_empl_id, dDate) loop
            --if j.num_hours >= 6  then
            if j.num_hours > 0  then    -- if present
               nRegHol := nRegHol + 8;
            end if;
         end loop;
      end if;  
      nNumHrs  := nNumHrs + nTmpHrs;
      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 2: dDate=' || to_char(dDate) || ' nNumHrs=' || to_char(nNumHrs) || ' nRegHol=' || to_char(nRegHol) || 
                               ' nTmpHrs=' || to_char(nTmpHrs) || ' Sun:Hol=' || to_char(sf_is_sunday (dDate)) || ':' || to_char(sf_is_holiday (dDate)));
      end if;

   end loop;

   -- compute attendance 
   begin
      nSeqNo     := nSeqNo + 1;
      nNumDay    := 15 + (nNumHrs/8);
      nSalaryR   := nNumDay * (p_basic_r/30);
      nSalaryG   := p_basic_g/2;
      nSunday_R  := ( p_Sunday_RF * (p_basic_r/30) );  
      nHoliday_R := ( p_Holiday_RF * (p_basic_r/30) ); 
      nHolSun_R  := ( p_HolSun_RF * (p_basic_r/30) );
      
      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 3: nNumDay=' || to_char(nNumDay) || ', nSalaryR=' || to_char(nSalaryR) || ', nSalaryG=' || to_char(nSalaryG) || 
                               ',p_Holiday_RF=' || to_char(p_Holiday_RF) || ',p_HolSun_RF=' || to_char(p_HolSun_RF) || 
                               ',nHoliday_R=' || to_char(nHoliday_R) || ',nRegHol=' || to_char(nRegHol));
      end if;

      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, 'REG', nSalaryR, nNumDay, p_basic_r, nSalaryG, p_basic_g, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end;

   if nRegSun > 0 then
      nSeqNo := nSeqNo + 1;
      nSuPay := nSunday_R * (nRegSun/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nSunday_T, nSuPay, (nRegSun/8), nSunday_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;
   
   if nRegHol > 0 then
      nSeqNo := nSeqNo + 1;
      nHoPay := nHoliday_R * (nRegHol/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHoliday_T, nHoPay, (nRegHol/8), nHoliday_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;
   
   if nHolOT > 0 then
      nSeqNo := nSeqNo + 1;
      nHSPay := nHolOT_R * (nHolOT/8);
      insert into pys_payroll_dtl 
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHolOT_T, nHSPay, (nHolOT/8), nHolOT_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   -- get allowances (OFC)
   dTmpDate := p_date_fr; --sf_latest_allowance_date (p_empl_id, p_date_fr);
   if dTmpDate is not null then
      for x in allo (p_empl_id, dTmpDate) loop 
         nSeqNo := nSeqNo + 1;
         nAllowances := nAllowances + (x.amt*nNumDay);
         insert into pys_payroll_dtl 
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, x.allo_code, (x.amt*nNumDay), nNumDay, x.amt, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
      end loop;
   end if;

   p_numday    := nNumDay;
   p_tsalaryg  := nSalaryG;
   p_SuPay     := nSuPay;
   p_HoPay     := nHoPay;
   p_HSPay     := nHSPay;
   p_Allowance := nAllowances;
   p_o_seq_no  := nSeqNo;

end sp_count_mgr_attendance;
/
