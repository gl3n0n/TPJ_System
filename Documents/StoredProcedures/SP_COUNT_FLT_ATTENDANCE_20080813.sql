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
   nSalaryR     Number(8,2)  := 0;
   nSeqNo       Number;
   dPeriodMo    Date;
   dPeriodFr    Date;
   dPeriodTo    Date;
   vLatestVess  Varchar2(32);
   vLatestTitle Varchar2(32);
   vLatestRate  Number(10,3) := 0;
   nDays        Number(10,5) := 0;
   bIsEndOfMonth Boolean;

begin

   nSeqNo := p_seq_no;

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dPeriodFr := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dPeriodMo := to_date(to_char(p_date_fr, 'YYYYMM') || '01', 'YYYYMMDD'); -- for overtimes
      dPeriodFr := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   -- get latest vessel
   for i in ( select vess_code, title, basic_rate
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              order  by pay_date desc
            )
   loop
      vLatestVess  := i.vess_code;
      vLatestTitle := i.title;
      vLatestRate  := i.basic_rate;
      exit;
   end loop;
   if vLatestVess is null then
      -- get latest vessel
      for i in ( select vess_code, title, basic_rate
                 from   pys_payroll_dtl_log
                 where  empl_empl_id = p_empl_id
                 order  by pay_date desc
               )
      loop
         vLatestVess  := i.vess_code;
         vLatestTitle := i.title;
         vLatestRate  := i.basic_rate;
         exit;
      end loop;
   end if;

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
                     sal_freq,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(COLA_PAY)               nCola
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, basic_rate, vess_code, sal_freq
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.vess_code=' || j.vess_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if;

      if j.sal_freq = 'MONTHLY' and bIsEndOfMonth and TO_CHAR(j.dEnd,'DD') >= '28' then
         if TO_CHAR(j.dEnd,'DD') = '31' then
            nDays    := j.nNumday  - 1;
            nSalaryR := j.nSalaryR - j.basic_rate;
         elsif TO_CHAR(j.dEnd,'DD') < '30' then
            nDays    := j.nNumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
            nSalaryR := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
         else
            nDays    := j.nNumday;
            nSalaryR := j.nSalaryR;
         end if;
      else 
         nDays    := j.nNumday;
         nSalaryR := j.nSalaryR;
      end if;

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
      values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nSalaryR, nDays, j.basic_rate, nSalaryR, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );

      if j.nCola > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', (j.nCola/j.nNumday)*nDays, nDays, (j.nCola/j.nNumday), j.vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
      end if;

   end loop;

   if bIsEndOfMonth then

      -- sundays and holidays
      for j in ( select posi_code,
                        title,
                        decode(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE) basic_rate,
                        vess_code,
                        min(pay_date)               dStart,
                        max(pay_date)               dEnd,
                        sum(decode(SU_PAY,0,0,SU_PAY))   nSuDays,
                        sum(SU_PAY*decode(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nSuPay,
                        sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                        sum(HO_PAY*decode(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nHoPay,
                        sum(decode(HS_PAY,0,0,HS_PAY))   nHSDays,
                        sum(HS_PAY*decode(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nHSPay
                 from   pys_payroll_dtl_log
                 where  empl_empl_id = p_empl_id
                 and    pay_date between dPeriodMo and p_date_to          -- 16 to eod
                 group  by  posi_code, title, decode(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE), vess_code
                )
      loop
         if ( j.nSuPay+j.nHoPay+j.nHSPay ) > 0 then
            -- check if there is header...
            for k in (select pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, posi_code, title, basic_rate, vess_code, dept_code, sal_freq, latest_vess
                      from   pys_payroll_dtl
                      where  empl_empl_id = p_empl_id
                      and    j.dEnd between period_fr and period_to
                      and    paty_code like 'REG%'
                      and    pahd_payroll_no <= p_payno
                      order  by period_to desc)
            loop
               if j.dStart between k.period_fr and k.period_to then
                  if k.pahd_payroll_no <> p_payno then
                     nSeqNo := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', 0, 0, j.basic_rate, 0, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
                  end if;
                  exit;
               end if;
            end loop;
         end if;

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
                        sum(nDays)                    nNumday,
                        sum(AMT)                      nSalaryR,
                        sum(COLA_PAY)                 nCola,
                        sum(A_nDays)                  nANumday,
                        sum(A_AMT)                    nASalaryR,
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
         if j.basic_rate = 0 and j.a_basic_rate > 0 then

            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nANumday, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );

            if j.nACola > 0 then
               nSeqNo := nSeqNo + 1;
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nACola, nDays, j.nACola/j.nANumday, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
            end if;
         else
            if (j.basic_rate-j.a_basic_rate) <> 0 then
               if j.basic_rate > 0 and j.a_basic_rate = 0 then
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, j.nSalaryR*-1, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
               else
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, j.nSalaryR, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
               end if;
            end if;

            if (j.nACola-j.nCola) <> 0 then
               nSeqNo := nSeqNo + 1;
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola-j.nCola), (j.nANumDay-j.nNumDay), (j.nACola-j.nCola)/(j.nANumDay-j.nNumDay), j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
            end if;
         end if;

      end loop;

   else
      -- adjustments
      for j in ( select posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        sal_freq,
                        a_basic_rate,
                        min(pay_date)                 dStart,
                        max(pay_date)                 dEnd,
                        sum(nDays)                    nNumday,
                        sum(AMT)                      nSalaryR,
                        sum(decode(SU_PAY,0,0,SU_PAY))     nSuDays,
                        sum(SU_PAY*BASIC_RATE)        nSuPay,
                        sum(decode(HO_PAY,0,0,HO_PAY))     nHoDays,
                        sum(HO_PAY*BASIC_RATE)        nHoPay,
                        sum(decode(HS_PAY,0,0,HS_PAY))     nHSDays,
                        sum(HS_PAY*BASIC_RATE)        nHSPay,
                        sum(COLA_PAY)                 nCola,
                        sum(a_nDays)                  nANumday,
                        sum(A_AMT)                    nASalaryR,
                        sum(decode(A_SU_PAY,0,0,A_SU_PAY))   nASuDays,
                        sum(A_SU_PAY*A_BASIC_RATE)    nASuPay,
                        sum(decode(A_HO_PAY,0,0,A_HO_PAY))   nAHoDays,
                        sum(A_HO_PAY*A_BASIC_RATE)    nAHoPay,
                        sum(decode(A_HS_PAY,0,0,A_HS_PAY))   nAHSDays,
                        sum(A_HS_PAY*A_BASIC_RATE)    nAHSPay,
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
                        sal_freq,
                        a_basic_rate)
      loop
         -- insert attendance summary
         if j.basic_rate = 0 and j.a_basic_rate > 0 then

            if j.sal_freq = 'MONTHLY' and  TO_CHAR(j.dEnd,'DD') >= '28' then
               if TO_CHAR(j.dEnd,'DD') = '31' then
                  nDays    := j.nANumday  - 1;
                  nSalaryR := j.nASalaryR - j.a_basic_rate;
               elsif TO_CHAR(j.dEnd,'DD') < '30' then
                  nDays    := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                  nSalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
               else
                  nDays    := j.nANumday;
                  nSalaryR := j.nASalaryR;
               end if;
            else 
               nDays    := j.nANumday;
               nSalaryR := j.nASalaryR;
            end if;

            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nSalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nDays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, nSalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.a_basic_rate, j.a_vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );

            if j.nACola > 0 then
               nSeqNo := nSeqNo + 1;
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nACola, nDays, j.nACola/nDays, j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
            end if;
         else
            if (j.basic_rate-j.a_basic_rate) <> 0 then
               if j.basic_rate > 0 and j.a_basic_rate = 0 then
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
               else
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nNumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.a_basic_rate, j.a_vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );

                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, j.basic_rate, j.vess_code, 'FL', user, sysdate, 'ADD', 'N', p_sal_freq, vLatestVess );
               end if;
            end if;

            if (j.nACola-j.nCola) <> 0 then
               nSeqNo := nSeqNo + 1;
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola-j.nCola), (j.nANumDay-j.nNumDay), (j.nACola-j.nCola)/(j.nANumDay-j.nNumDay), j.a_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
            end if;
         end if;

      end loop;

   end if;  --<if bIsEndOfMonth then>

   p_o_seq_no    := nSeqNo;
   p_latestvess  := vLatestVess;
   p_latesttitle := vLatestTitle;


exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);
end sp_count_flt_attendance;
/
