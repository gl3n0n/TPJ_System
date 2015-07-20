create or replace procedure sp_count_mgr_attendance_new
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

   nNumHrs    Number (7,3) := 0;
   nDays      Number(10,5) := 0;
   nADays     Number(10,5) := 0;
   nSalaryR   Number(12,4) := 0;
   nASalaryR  Number(12,4) := 0;
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
   nBasicR    Number(12,5);

   nSeqNo       Number;
   nSalaryG     Number(12,4) := 0;
   nSunday_R    Number(8,3) := 0;
   nHoliday_R   Number(8,3) := 0;
   nHolSun_R    Number(8,3) := 0;
   nSuPay       Number(12,4) := 0;
   nHoPay       Number(12,4) := 0;
   nHSPay       Number(12,4) := 0;
   nAllowances  Number(12,4);
   nTSalaryG    Number(12,4) := 0;
   nTSuPay      Number(12,4) := 0;
   nTHoPay      Number(12,4) := 0;
   nTHSPay      Number(12,4) := 0;
   nTNumDay     Number := 0;
   nTRegSun     Number := 0;
   nTRegHol     Number := 0;
   nTHolSun     Number := 0;
   dTmpDate     Date;
   o_basic_r    Number(10,5) := 0;
   o_basic_g    Number(10,5) := 0;
   o_salfreq    Varchar2(12);
   o_ismanager  Varchar2(12);
   nColaPay     Number(10,5) := 0;
   nColaDay     Number(10,5) := 0;
   dColaEff     Date;
   vOuter_Port  Varchar2(1) := 'N';

   nHolOT    Number (7,3) := 0;
   nHolOT_R     Number(8,3) := 0;
   nSunday_T    Varchar2(16) := 'OT-SUN-OFC';
   nHoliday_T   Varchar2(16) := 'OT-HOL-OFC';
   nHolOT_T     Varchar2(16) := 'OT-HOL-EXC';
   dEmplID      varchar2(16) := p_dEmplID;
   nCola        number(10,5) := 0;
   bFirst       Boolean := TRUE;
begin

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   nUpto := (p_date_to - dStart)+1;
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 1: p_empl_id=' || p_empl_id || ',dStart=' || to_char(dStart) || ',dEnd=' || to_char(dEnd) || ' nUpto=' || to_char(nUpto));
   end if;
   for k in 1..nUpto loop
      dDate := (dStart-1) + k;
      nTmpHrs := 0;
      if sf_is_sunday (dDate) = 1 then
         if sf_is_holiday (dDate) = 1 then
            for j in atre (p_empl_id, dDate) loop
               if j.num_hours > 0  then  -- if present
                  nRegHol := nRegHol + 8;
               end if;
            end loop;
         else
            for j in atre (p_empl_id, dDate) loop
               if j.num_hours > 0  then    -- if present
                  nTmpHrs := nTmpHrs + 8;
               end if;
            end loop;
         end if;
      elsif sf_is_holiday (dDate) = 1 then
         for j in atre (p_empl_id, dDate) loop
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

      if dDate < dEnd then
         sp_latest_get_basic_rate (p_empl_id, dDate, o_basic_r, o_basic_g, o_salfreq, o_ismanager);
      else
         sp_latest_get_basic_rate (p_empl_id, dEnd, o_basic_r, o_basic_g, o_salfreq, o_ismanager);
      end if;

      nNumDay    := (nNumHrs/8);
      nSuPay     := p_Sunday_RF * (nRegSun/8);
      nHoPay     := p_Holiday_RF * (nRegHol/8);
      nHSPay     := p_HolSun_RF * (nHolOT/8);
      nBasicR    := o_basic_r/30;

      -- check if with cola
      sp_get_latest_cola (p_empl_id, dDate, nColaPay, dColaEff);
      if nColaPay > 0 and dColaEff <= dEnd then
         nColaDay := 1;
         nColaPay := nColaPay;
      else
         nColaPay := 0;
         nColaDay := 0;
      end if;

      -- create payroll log
      if dDate < p_date_fr then    -- check assumed dates from previous payroll
         update pys_payroll_dtl_log
         set    a_dept_code    = p_dept_code,
                a_posi_code    = p_posi_code,
                a_basic_rate   = nBasicR,
                a_basic_rate_g = o_basic_g,
                a_ndays        = 1,
                a_amt          = nBasicR,
                a_amt_g        = o_basic_g/2,
                su_pay         = nSuPay,
                ho_pay         = nHoPay,
                hs_pay         = nHSPay,
                a_oport        = vOuter_Port,
                a_cola_pay     = nColaPay,
                a_cola_day     = nColaDay,
                modified_by    = user,
                dt_modified    = sysdate
         where empl_empl_id = p_empl_id
         and   pay_date = dDate;
         if sql%NOTFOUND then
            insert into pys_payroll_dtl_log
                   ( payroll_no, empl_empl_id, pay_date, a_dept_code, a_posi_code, sal_freq,
                     a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, ot_pay, hs_pay, oport,
                     su_pay, ho_pay, ht_pay, a_cola_pay, a_cola_day, a_ndays, created_by, dt_created
                   )
            values ( p_payno, p_empl_id, dDate, p_dept_code, p_posi_code, o_salfreq,
                     nBasicR, o_basic_g, nBasicR, o_basic_g/2, 0, nHSPay, vOuter_Port,
                     nSuPay, nHoPay, 0, nColaPay, nColaDay, 1, user, sysdate
                   );
         end if;
      else

         begin
            insert into pys_payroll_dtl_log
                   ( payroll_no, empl_empl_id, pay_date, dept_code, posi_code, sal_freq,
                     basic_rate, basic_rate_g, amt, amt_g, ot_pay, ht_pay, oport,
                     su_pay, ho_pay, hs_pay, cola_pay, cola_day, ndays, created_by, dt_created
                   )
            values ( p_payno, p_empl_id, dDate, p_dept_code, p_posi_code, o_salfreq,
                     nBasicR, o_basic_g, nBasicR, o_basic_g/2, 0, nHSPay, vOuter_Port,
                     nSuPay, nHoPay, 0, nColaPay, nColaDay, 1, user, sysdate
                   );
         exception
            when dup_val_on_index then
               update pys_payroll_dtl_log
               set    dept_code    = p_dept_code,
                      posi_code    = p_posi_code,
                      basic_rate   = nBasicR,
                      basic_rate_g = o_basic_g,
                      ndays        = 1,
                      amt          = nBasicR,
                      amt_g        = o_basic_g/2,
                      oport        = vOuter_Port,
                      su_pay       = nSuPay,
                      ho_pay       = nHoPay,
                      hs_pay       = nHSPay,
                      cola_pay     = nColaPay,
                      cola_day     = nColaDay,
                      modified_by  = user,
                      dt_modified  = sysdate
               where empl_empl_id = p_empl_id
               and   pay_date = dDate;
         end;
      end if; -- <if dChkDate < p_date_fr then>

      nNumDay    := 0;
      nSuPay     := 0;
      nHoPay     := 0;
      nHSPay     := 0;
      nRegSun    := 0;
      nRegHol    := 0;
      nHolOT     := 0;

   end loop;


   -- regular days
   for j in ( select posi_code,
                     title,
                     max(basic_rate) basic_rate,
                     max(basic_rate_g) basic_rate_g,
                     dept_code,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(cola_day)               nColaDay,
                     sum(cola_pay)               nColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.dept_code=' || j.dept_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if;

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      if  j.nNumday > 15 then
         nDays := 15;
      else
         if TO_CHAR(j.dEnd,'DD') <= '30' then
            nDays := 15;
         else
            nDays := j.nNumday;
         end if;
      end if;
      if bFirst then
         if j.dEnd > dEnd then
            nDays := nDays + sf_count_sundays(p_empl_id, dStart, dEnd);
         else
            nDays := nDays + sf_count_sundays(p_empl_id, dStart, j.dEnd);
         end if;
      else
         if j.dEnd > dEnd then
            nDays := nDays + sf_count_sundays(p_empl_id, j.dStart, dEnd);
         else
            nDays := nDays + sf_count_sundays(p_empl_id, j.dStart, j.dEnd);
         end if;
      end if;

      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
      values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nDays*j.basic_rate, nDays, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', 'MONTHLY' );

      bFirst := FALSE;

   end loop;

   -- regular days (cola)
   for j in ( select posi_code,
                     title,
                     dept_code,
                     min(pay_date) dStart,
                     max(pay_date) dEnd,
                     max(cola_pay) nColaRate,
                     sum(cola_day) nColaDay,
                     sum(cola_pay) nColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    cola_pay > 0
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code
             )
   loop

      if j.nColaPay > 0 and j.nColaDay > 0 then
         nSeqNo := nSeqNo + 1;
         if  j.nColaDay > 15 then
            nColaDay := 15;
            nColaPay := 15*j.nColaRate;
         else
            nColaDay := j.nColaDay;
            nColaPay := j.nColaPay;
         end if;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', nColaPay, nColaDay, j.nColaRate, j.dept_code, user, sysdate, 'ADD', 'MONTHLY'  );
      end if;

   end loop;

   -- regular days (overtime)
   for j in ( select posi_code,
                     title,
                     max(decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE)) basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                     sum(HO_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHoPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dStart and dEnd
              group  by  posi_code, title, dept_code, oport
             )
   loop

      if j.nHoPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-OFC', j.nHoPay, j.nHoDays, j.basic_rate, j.dept_code, user, sysdate, 'ADD', 'MONTHLY'   );
      end if;

   end loop;



   -- adjustments
   for j in ( select posi_code,
                     title,
                     dept_code,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_basic_rate,
                     min(pay_date)                 dStart,
                     max(pay_date)                 dEnd,
                     sum(nDays)                    nNumday,
                     sum(AMT)                      nSalaryR,
                     sum(A_nDays)                  nANumday,
                     sum(A_AMT)                    nASalaryR
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dStart and (p_date_fr-1)
              and    (basic_rate-a_basic_rate) <> 0
              group  by posi_code,
                     title,
                     dept_code,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_basic_rate)
   loop
      if (j.basic_rate - j.a_basic_rate) <> 0 or (j.nNumDay-j.nANumday) <> 0 then
         if TO_CHAR(j.dEnd,'DD') >= '28' then
            if TO_CHAR(j.dEnd,'DD') = '31' then
               nDays     := j.nANumday - 1;
               nADays    := nDays;
               nSalaryR  := j.nSalaryR - j.basic_rate;
               nASalaryR := j.nASalaryR - j.a_basic_rate;
            elsif TO_CHAR(j.dEnd,'DD') < '30' then
               nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
               nADays    := 15;
               nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
               nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
            else
               nDays     := j.nANumday;
               nADays    := nDays;
               nSalaryR  := j.nSalaryR;
               nASalaryR := j.nASalaryR;
            end if;
         else
            nDays     := j.nNumday;
            nADays    := j.nANumday;
            nSalaryR  := j.nSalaryR;
            nASalaryR := j.nASalaryR;
         end if;

         nSeqNo  := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nASalaryR, nADays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', 'MONTHLY' );
         nSeqNo  := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR)*-1, nDays*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', 'MONTHLY' );
      end if;
   end loop;

   -- adjustment (cola)
   for j in ( select posi_code,
                     title,
                     dept_code,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     min(pay_date)   dStart,
                     max(pay_date)   dEnd,
                     sum(cola_day)   nColaDay,
                     sum(cola_pay)   nColaPay,
                     sum(a_cola_day) nAColaDay,
                     sum(a_cola_pay) nAColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    a_cola_day <> 0
              and    pay_date between dStart and (p_date_fr-1)
              group  by posi_code,
                     title,
                     dept_code,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate )
   loop
      if (j.nAColaPay-j.nColaPay) <> 0 and (j.nAColaDay-j.nColaDay) <> 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
      end if;

   end loop;

   p_numday    := 0;
   p_tsalaryg  := 0;
   p_SuPay     := 0;
   p_HoPay     := 0;
   p_HSPay     := 0;
   p_Allowance := 0;
   p_o_seq_no  := nSeqNo;

end sp_count_mgr_attendance_new;
/
