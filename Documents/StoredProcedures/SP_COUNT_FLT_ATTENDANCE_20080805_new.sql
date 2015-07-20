create or replace procedure sp_count_flt_attendance
(
   p_empl_id    in  varchar2,
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_Sunday_RF  in  number,
   p_Holiday_RF in  number,
   p_HolSun_RF  in  number,
   p_sal_freq   in  varchar2,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2, 
   p_latestvess  out varchar2, 
   p_latesttitle out varchar2, 
   p_o_seq_no   out number

) is

   dEmplID      Varchar2(16) := p_dEmplID;
   nSalaryR     Number(8,2) := 0;
   nSeqNo       Number;
   nNumDay      Number(8,2) := 0;
   dPeriodFr    Date;
   dPeriodTo    Date;
   vLatestVess  Varchar2(32);
   vLatestTitle Varchar2(32);
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

   -- get latest vessel 
   for i in ( select vess_code, title
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              order  by pay_date desc
            )
   loop
      vLatestVess  := i.vess_code; 
      vLatestTitle := i.title;
   end loop;

   -- set latest vess
   update pys_payroll_dtl_log
   set    latest_vess = vLatestVess
   where  empl_empl_id = p_empl_id
   and    pay_date between p_date_fr and p_date_to;

   -- regular days
   for j in ( select posi_code,
                     title,
                     basic_rate,
                     vess_code,
                     min(pay_date)               dStart,   
                     max(pay_date)               dEnd,     
                     count(1)                    nNumday,  
                     sum(AMT)                    nSalaryR, 
                     sum(decode(SU_PAY,0,0,1))   nSuDays,  
                     sum(SU_PAY*BASIC_RATE)      nSuPay,   
                     sum(decode(HO_PAY,0,0,1))   nHoDays,  
                     sum(HO_PAY*BASIC_RATE)      nHoPay,   
                     sum(decode(HS_PAY,0,0,1))   nHSDays,  
                     sum(HS_PAY*BASIC_RATE)      nHSPay,   
                     sum(decode(COLA_PAY,0,0,1)) nColaDays,
                     sum(COLA_PAY)               nCola     
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, basic_rate, vess_code
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.vess_code=' || j.vess_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if; 

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
      values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', j.nSalaryR, j.nNumDay, j.basic_rate, j.nSalaryR, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
      
      if bIsEndOfMonth then
      
         if j.nSuPay > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-SUN-FLT', j.nSuPay, j.nSuDays, j.basic_rate*p_Sunday_RF, j.vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
      
         if j.nHoPay > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-FLT', j.nHoPay, j.nHoDays, j.basic_rate*p_Holiday_RF, j.vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
      
         if j.nHSPay > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HS-FLT', j.nHSPay, j.nHSDays, j.basic_rate*p_HolSun_RF, j.vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;

         if j.nCola > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HS-FLT', j.nCola, j.nColaDays, j.nCola/j.nColaDays, j.vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;

      end if;

   end loop;

   -- adjustments
   for j in ( select posi_code,
                     title,
                     vess_code,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_vess_code,
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
                     vess_code,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_vess_code,
                     a_basic_rate)
   loop
      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      if j.basic_rate = 0 and j.a_basic_rate > 0 then
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );

         if (j.nASuPay-j.nSuPay) <> 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-SUN-FLT', j.nASuPay, j.nASuDays, j.a_basic_rate*p_Sunday_RF, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
         
         if (j.nAHoPay-j.nHoPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HOL-FLT', j.nAHoPay, j.nAHoDays, j.a_basic_rate*p_Holiday_RF, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
         
         if (j.nAHSPay-j.nHSPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nAHSPay, j.nAHSDays, j.a_basic_rate*p_HolSun_RF, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
         
         if (j.nACola-j.nCola) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nACola, j.nAColaDays, j.nACola/j.nAColaDays, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
      else
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (j.nASalaryR-j.nSalaryR), j.nNumDay, (j.a_basic_rate-j.basic_rate), (j.nASalaryR-j.nSalaryR), (j.a_basic_rate-j.basic_rate), j.a_vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );

         if (j.nASuPay-j.nSuPay) <> 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-SUN-FLT', j.nASuPay-j.nSuPay, j.nASuDays, (j.a_basic_rate-j.basic_rate)*p_Sunday_RF, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
         
         if (j.nAHoPay-j.nHoPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HOL-FLT', j.nAHoPay-j.nHoPay, j.nAHoDays, (j.a_basic_rate-j.basic_rate)*p_Holiday_RF, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
         
         if (j.nAHSPay-j.nHSPay) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'OT-HS-FLT', j.nHSPay-j.nAHSPay, j.nAHSDays, (j.a_basic_rate-j.basic_rate)*p_HolSun_RF, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
         
         if (j.nACola-j.nCola) > 0 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nACola, j.nAColaDays, j.nACola/j.nAColaDays, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
      end if;

   end loop;

   p_o_seq_no    := nSeqNo;
   p_latestvess  := vLatestVess;
   p_latesttitle := vLatestTitle;


exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);
end sp_count_flt_attendance;
/
show err
