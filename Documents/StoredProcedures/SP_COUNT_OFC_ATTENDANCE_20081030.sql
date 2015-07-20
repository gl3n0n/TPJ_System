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

   dEmplID      varchar2(16) := p_dEmplID;
   nDays        Number(10,5) := 0;
   nADays       Number(10,5) := 0;
   nSalaryR     Number(12,4) := 0;
   nASalaryR    Number(12,4) := 0;
   nSeqNo       Number;
   vSalFreq     Varchar2(12);
   dPeriodFr    Date;
   dPeriodTo    Date;
   bIsEndOfMonth Boolean;

begin

   nSeqNo := p_seq_no;

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dPeriodFr := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dPeriodFr := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if p_isMonthly = 'Y' then
      vSalFreq := 'MONTHLY';
   else
      vSalFreq := 'SEMI-MO';
   end if;

   -- regular days
   for j in ( select posi_code,
                     title,
                     max(basic_rate) basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(decode(OT_PAY,0,0,OT_PAY))   nOtDays,
                     sum(OT_PAY*BASIC_RATE)      nOtPay,
                     sum(decode(SU_PAY,0,0,SU_PAY))   nSuDays,
                     sum(SU_PAY*BASIC_RATE)      nSuPay,
                     sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                     sum(HO_PAY*BASIC_RATE)      nHoPay,
                     sum(decode(HT_PAY,0,0,HT_PAY))   nHSDays,
                     sum(HT_PAY*BASIC_RATE)      nHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code, oport
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.dept_code=' || j.dept_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if;

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      if j.oport = 'Y' then
         --issue: for outer port (numdays should always be 15 if, with complete attendance) malabo to
         if j.nNumday >= ((p_date_to-p_date_fr)+1) and
            j.nActDay = ((p_date_to-p_date_fr)+1)
         then
            if p_isMonthly = 'Y' then      -- 15 plus sundays and holidays
               nDays := 15 + sf_count_sundays(p_empl_id, dPeriodFr, dPeriodTo);
            else
               nDays := j.nActDay;  -- outer port are based on actual days
            end if;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP', nDays*j.basic_rate, nDays, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP', j.nSalaryR, j.nNumDay, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      else
         -- issue: monthly but non-managers re increases (numdays should always be 15 if, with complete attendance)
         if j.nNumday >= ((p_date_to-p_date_fr)+1) and
            j.nActDay = ((p_date_to-p_date_fr)+1) and
            p_isMonthly = 'Y'
         then
            nDays := 15 + sf_count_sundays(p_empl_id, dPeriodFr, dPeriodTo); --(j.nNumday-j.nActDay);
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nDays*j.basic_rate, nDays, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', j.nSalaryR, j.nNumDay, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      end if;

   end loop;


   -- regular days (cola)
   for j in ( select posi_code,
                     title,
                     dept_code,
                     min(pay_date) dStart,
                     max(pay_date) dEnd,
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
         if p_isMonthly = 'Y' and j.nColaDay > 15 then
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', 15*(j.nColaPay/j.nColaDay), 15, j.nColaPay/j.nColaDay, j.dept_code, user, sysdate, 'ADD', vSalFreq );
         else
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', j.nColaPay, j.nColaDay, j.nColaPay/j.nColaDay, j.dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
      end if;

   end loop;

   -- regular days (overtime)
   for j in ( select posi_code,
                     title,
                     decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE) basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(decode(OT_PAY,0,0,OT_PAY))   nOtDays,
                     sum(OT_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nOtPay,
                     sum(decode(SU_PAY,0,0,SU_PAY))   nSuDays,
                     sum(SU_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nSuPay,
                     sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                     sum(HO_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHoPay,
                     sum(decode(HT_PAY,0,0,HT_PAY))   nHSDays,
                     sum(HT_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dPeriodFr and dPeriodTo
              group  by  posi_code, title, dept_code, oport, decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE)
             )
   loop

      if j.nOtPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-OFC', j.nOtPay, j.nOtDays, j.basic_rate*p_Overtm_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

      if j.nSuPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-SUN-OFC', j.nSuPay, j.nSuDays, j.basic_rate*p_Sunday_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

      if j.nHoPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-OFC', j.nHoPay, j.nHoDays, j.basic_rate*p_Holiday_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq  );
      end if;

      if j.nHSPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-EXC', j.nHSPay, j.nHSDays, j.basic_rate*p_HolSun_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

   end loop;

   -- adjustments
   for j in ( select posi_code,
                     title,
                     dept_code,
                     oport,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate,
                     min(pay_date)                 dStart,
                     max(pay_date)                 dEnd,
                     sum(nDays)                    nNumday,
                     sum(AMT)                      nSalaryR,
                     0   nSuDays,
                     0   nSuPay,
                     0   nHoDays,
                     0   nHoPay,
                     0   nHSDays,
                     0   nHSPay,
                     sum(A_nDays)                  nANumday,
                     sum(A_AMT)                    nASalaryR,
                     0   nASuDays,
                     0   nASuPay,
                     0   nAHoDays,
                     0   nAHoPay,
                     0   nAHSDays,
                     0   nAHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dPeriodFr and (p_date_fr-1)
              and    a_ndays > 0
              group  by posi_code,
                     title,
                     dept_code,
                     oport,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate)
   loop
      -- insert attendance summary
      if j.basic_rate = 0 and j.a_basic_rate > 0 then

         if j.a_oport = 'Y' then
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      else
         if (j.basic_rate - j.a_basic_rate) <> 0 or (j.nNumDay-j.nANumday) <> 0 then
            if j.a_oport = 'Y' then
               if j.a_oport <> j.oport then
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               else
                  if j.basic_rate > 0 and j.a_basic_rate = 0 then
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  else
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  end if;
               end if;
            else
              if j.a_oport <> j.oport then
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, decode(j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay,0,0,j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays), j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               else
                  if j.basic_rate > 0 and j.a_basic_rate = 0 then
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  else
                     if (p_isMonthly = 'Y') and  TO_CHAR(j.dEnd,'DD') >= '28' then
                        if TO_CHAR(j.dEnd,'DD') = '31' then
                           nDays     := j.nANumday - 1;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR - j.basic_rate;
                           nASalaryR := j.nASalaryR - j.a_basic_rate;
                        elsif TO_CHAR(j.dEnd,'DD') < '30' then
                           nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                           nADays    := nDays;
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
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', (nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay), (nADays+j.nASuDays+j.nAHoDays+j.nAHSDays), j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  end if;
               end if;
            end if;
         end if;
      end if;
   end loop;

   -- adjustment (cola)
   for j in ( select a_posi_code,
                     a_title,
                     a_dept_code,
                     a_basic_rate,
                     min(pay_date)   dStart,
                     max(pay_date)   dEnd,
                     sum(cola_day)   nColaDay,
                     sum(cola_pay)   nColaPay,
                     sum(a_cola_day) nAColaDay,
                     sum(a_cola_pay) nAColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              --and    (cola_day-a_cola_day) <> 0
              and    pay_date between dPeriodFr and (p_date_fr-1)
              group  by a_posi_code,
                     a_title,
                     a_dept_code,
                     a_basic_rate )
   loop
      if ((j.nAColaPay-j.nColaPay) <> 0) or ((j.nAColaDay-j.nColaDay) <> 0) then
         nSeqNo := nSeqNo + 1;
         if (p_isMonthly = 'Y') and TO_CHAR(j.dEnd,'DD') >= '28' then
if p_dEmplID = p_empl_id then
   dbms_output.put_line('Ano ba nagyari dito sa taas... dPeriodFr=' || to_char(dPeriodFr) || ',j.nAColaPay=' || to_char(j.nAColaPay) || ',j.nColaPay=' || to_char(j.nColaPay) ||
                                                       ',j.nAColaDay=' || to_char(j.nAColaDay) || ',j.nColaDay=' || to_char(j.nColaDay));
end if;
            if TO_CHAR(j.dEnd,'DD') = '31' then
               nDays    := (greatest(j.nAColaDay-1,0)-(j.nColaDay-1));
               if nDays = 0 then
                  nDays := greatest(j.nAColaDay-1,0);
                  nSalaryR := (j.nAColaPay-j.nColaPay)-((j.nAColaPay-j.nColaPay)/j.nAColaDay);
               else
                  nSalaryR := nDays*((j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay));
               end if;
            elsif TO_CHAR(j.dEnd,'DD') < '30' then
               nDays    := (greatest(j.nAColaDay-(30-to_number(TO_CHAR(j.dEnd,'DD'))),0)-(j.nColaDay-(30-to_number(TO_CHAR(j.dEnd,'DD')))));
               if nDays = 0 then
                  nDays := greatest(j.nAColaDay-(30-to_number(TO_CHAR(j.dEnd,'DD'))),0);
                  nSalaryR :=  (j.nAColaPay-j.nColaPay)-((j.nAColaPay-j.nColaPay)/j.nAColaDay);
               else
                  nSalaryR :=  nDays*((j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay));
               end if;
            else
               nDays    := (j.nAColaDay-j.nColaDay);
               nSalaryR := (j.nAColaPay-j.nColaPay);
            end if;
if p_dEmplID = p_empl_id then
   dbms_output.put_line('Ano ba nagyari dito sa baba... nDays=' || to_char(nDays) || ',nSalaryR=' || to_char(nSalaryR));
end if;
            if nDays <> 0 then
               insert into pys_payroll_dtl
                     ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', nSalaryR, nDays, nSalaryR/nDays, j.a_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
            end if;
         else
            if (j.nAColaDay-j.nColaDay) <> 0 then
               insert into pys_payroll_dtl
                     ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
            end if;
         end if;
         --insert into pys_payroll_dtl
         --      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

   end loop;

   p_o_seq_no    := nSeqNo;

exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);

end sp_count_ofc_attendance;
/
