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
                     basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,   
                     max(pay_date)               dEnd,     
                     sum(AMT/BASIC_RATE)         nNumday,  
                     sum(AMT)                    nSalaryR, 
                     sum(decode(OT_PAY,0,0,1))   nOtDays,  
                     sum(OT_PAY*BASIC_RATE)      nOtPay,   
                     sum(decode(SU_PAY,0,0,1))   nSuDays,  
                     sum(SU_PAY*BASIC_RATE)      nSuPay,   
                     sum(decode(HO_PAY,0,0,1))   nHoDays,  
                     sum(HO_PAY*BASIC_RATE)      nHoPay,   
                     sum(decode(HT_PAY,0,0,1))   nHSDays,  
                     sum(HT_PAY*BASIC_RATE)      nHSPay,   
                     sum(decode(COLA_PAY,0,0,1)) nColaDays,
                     sum(COLA_PAY)               nCola     
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, basic_rate, dept_code, oport
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.dept_code=' || j.dept_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if; 

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      if j.oport = 'Y' then 
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP', j.nSalaryR, j.nNumDay, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
      else
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', j.nSalaryR, j.nNumDay, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
      end if; 
      
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

      if j.nCola > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', j.nCola, j.nColaDays, j.nCola/j.nColaDays, j.dept_code, user, sysdate, 'ADD', vSalFreq );
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
                     count(1)                      nNumday,  
                     sum(AMT)                      nSalaryR, 
                     sum(decode(SU_PAY,0,0,1))     nSuDays,  
                     sum(SU_PAY*BASIC_RATE)        nSuPay,   
                     sum(decode(HO_PAY,0,0,1))     nHoDays,  
                     sum(HO_PAY*BASIC_RATE)        nHoPay,   
                     sum(decode(HS_PAY,0,0,1))     nHSDays,  
                     sum(HS_PAY*BASIC_RATE)        nHSPay,   
                     sum(decode(COLA_PAY,0,0,1))   nColaDays,
                     sum(COLA_PAY)                 nCola,
                     sum(A_AMT)                    nASalaryR, 
                     sum(decode(A_SU_PAY,0,0,1))   nASuDays,  
                     sum(A_SU_PAY*A_BASIC_RATE)    nASuPay,   
                     sum(decode(A_HO_PAY,0,0,1))   nAHoDays,  
                     sum(A_HO_PAY*A_BASIC_RATE)    nAHoPay,   
                     sum(decode(A_HS_PAY,0,0,1))   nAHSDays,  
                     sum(A_HS_PAY*A_BASIC_RATE)    nAHSPay,   
                     sum(decode(A_COLA_PAY,0,0,1)) nAColaDays,
                     sum(A_COLA_PAY)               nACola     
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dPeriodFr and (p_date_fr-1) 
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
      nSeqNo  := nSeqNo + 1;
      if j.basic_rate = 0 and j.a_basic_rate > 0 then

         if j.a_oport = 'Y' then 
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if; 

         if (j.nASuPay-j.nSuPay) <> 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-SUN-FLT', j.nASuPay, j.nASuDays, j.a_basic_rate*p_Sunday_RO, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
         
         if (j.nAHoPay-j.nHoPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HOL-FLT', j.nAHoPay, j.nAHoDays, j.a_basic_rate*p_Holiday_RO, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
         
         if (j.nAHSPay-j.nHSPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nAHSPay, j.nAHSDays, j.a_basic_rate*p_HolSun_RO, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
         
         if (j.nACola-j.nCola) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nACola, j.nAColaDays, j.nACola/j.nAColaDays, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
      else
         if j.a_oport = 'Y' then 
            if j.a_oport <> j.oport then 
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               nSeqNo  := nSeqNo + 1;
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
            else
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR-j.nSalaryR, j.nNumDay, j.a_basic_rate-j.basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
            end if;
         else
            if j.a_oport <> j.oport then 
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               nSeqNo  := nSeqNo + 1;
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
            else
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR-j.nSalaryR, j.nNumDay, j.a_basic_rate-j.basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
            end if;
         end if; 

         if (j.nASuPay-j.nSuPay) <> 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-SUN-FLT', j.nASuPay-j.nSuPay, j.nASuDays, (j.a_basic_rate-j.basic_rate)*p_Sunday_RO, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
         
         if (j.nAHoPay-j.nHoPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HOL-FLT', j.nAHoPay-j.nHoPay, j.nAHoDays, (j.a_basic_rate-j.basic_rate)*p_Holiday_RO, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
         
         if (j.nAHSPay-j.nHSPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nHSPay-j.nAHSPay, j.nAHSDays, (j.a_basic_rate-j.basic_rate)*p_HolSun_RO, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
         
         if (j.nACola-j.nCola) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nACola, j.nAColaDays, j.nACola/j.nAColaDays, j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;
      end if;

   end loop;

   p_o_seq_no    := nSeqNo;

exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);

end sp_count_ofc_attendance;
/
