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
   p_seq_no     in  number,
   p_dEmplID    in  varchar2, 
   p_sal_freq   in  varchar2,
   p_numday     out number,
   p_tsalaryg   out number,
   p_supay      out number,
   p_hopay      out number,
   p_hspay      out number,
   p_Allowance  out number,
   p_latestvess  out varchar2, 
   p_latesttitle out varchar2, 
   p_o_seq_no   out number

) is

   -- greatest(vocr.dt_embarked,p_date_fr) start_date,
   -- least(nvl(vocr.dt_disembarked,p_date_to),p_date_to) end_date,
   cursor att_flt (p_sta in date, p_end in date) is
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= p_end
   and    vocr.dt_embarked <= p_end
   and    vocr.dt_disembarked is null
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.empl_empl_id = p_empl_id
   and    vocr.passenger = 'N'
   union
   select vocr.empl_empl_id, vocr.rowid row_id, vocr.dt_embarked, vocr.dt_disembarked,
          vocr.passenger, vocr.voya_vess_code, empl.posi_code posi_code, vocr.title,
          vocr.voya_voyage_date, vocr.basic_rate, vocr.basic_rate_g
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= p_end
   and    vocr.dt_embarked <= p_end
   and    vocr.dt_disembarked is not null
   and    vocr.dt_disembarked >= p_sta
   and    vocr.dt_disembarked <> (to_date(to_char(p_date_fr,'YYYYMM"01"'), 'YYYYMMDD')-1)   -- end of previous month only
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    vocr.empl_empl_id = p_empl_id
   and    vocr.passenger = 'N'
   order  by dt_embarked desc;

   --get allowances (FLT)
   cursor allo_flt ( p_empl_id in varchar2,  p_vessel in varchar2,  p_voya_date in varchar2 ) is
   select allo_code, amount amt
   from   cms_crew_allowances
   where  empl_empl_id = p_empl_id
   and    voya_vess_code = p_vessel
   and    voya_voyage_date  >= (select max (eff_en_date) from pys_employee_allowances where eff_en_date <= p_date_to); --= p_voya_date; -- modified by thess 1/7/08

   --compute adjustment (FLT)
   cursor adj_flt is
   select pahd_payroll_no, seq_no, period_fr, period_to, basic_rate, amt, basic_rate_g, amt_g, adj_flag, no_days, sal_freq
   from   pys_payroll_dtl
   where  empl_empl_id = p_empl_id
   and    paty_code LIKE 'REG%'
   and    pahd_payroll_no = p_payno
   order  by period_fr desc, period_to desc;

   nNumDay    Number := 0;
   nRegHol    Number := 0;
   nHolSun    Number := 0;
   nRegSun    Number := 0;
   nUpTO      Number := 0;
   dDate      Date;
   dStart     Date;
   dend       Date;
   dFirstDay  Date;
   dPrevStart Date;
   dPrevend   Date;
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
   nAllowances  Number(8,2) := 0;
   nTSalaryG    Number(8,2) := 0;
   nTSuPay      Number(8,2) := 0;
   nTHoPay      Number(8,2) := 0;
   nTHSPay      Number(8,2) := 0;
   nTNumDay     Number := 0;
   nTRegSun     Number := 0;
   nTRegHol     Number := 0;
   nTHolSun     Number := 0;

   vPaty        Varchar2(16);
   vAdjFlag     Varchar2(1);
   bAdjustment  Boolean := FALSE;
   dPrevRateR   Number(8,2);
   dPrevRateG   Number(8,2);
   nTSalAdj     Number(8,2) := 0;

   -- Adjustment computation variables
   nAUpTO      Number := 0;
   dADate      Date;
   dAStart     Date;
   dAEnd       Date;
   nAHolSun    Number := 0;
   nARegHol    Number := 0;
   nARegSun    Number := 0;
   nANumDay    Number := 0;
   nAdjPay     Number(8,2) := 0;
   nARate      Number(8,2) := 0;
   nADays      Number(8,2) := 0;
   nASuPay     Number(8,2) := 0;
   nAHoPay     Number(8,2) := 0;
   nAHSPay     Number(8,2) := 0;
   bNormalTrans Boolean := TRUE;
   vLatestVess  Varchar2(32);
   vLatestTitle Varchar2(32);
   bContinuous   Boolean := FALSE;

   dEmplID      varchar2(16) := p_dEmplID;

begin

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dFirstDay := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dFirstDay := to_date(to_char(p_date_fr, 'YYYYMM') || '01', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   if p_empl_id in (dEmplID) then
      dbms_output.put_line ('check -1: ' || p_empl_id || ': dEnd=' || to_char(dEnd) || ': dFirstDay=' || to_char(dFirstDay)  || ': p_sal_freq=' || p_sal_freq);
   end if;

   for j in att_flt(dFirstDay, dEnd) loop

      if p_empl_id in (dEmplID) then
         dbms_output.put_line ('check 0: ' || p_empl_id || ': embarked=' || to_char(j.dt_embarked) || ': dFirstDay=' || to_char(dFirstDay) || ': disembarked=' || to_char(j.dt_disembarked) || ': rowid=' || to_char(j.row_id));
      end if;
      -- check start date
      vAdjFlag := 'N';
      bNormalTrans := TRUE;
      if bIsEndOfMonth then
         if j.dt_embarked between add_months(dEnd,-1) and p_date_fr  then
            dStart := j.dt_embarked;
         else
            dStart := dFirstDay;
         end if;
      else
         dStart := p_date_fr;
      end if;
      if j.dt_embarked > dFirstDay then
         -- if embarked is equal to previous cut-off (10th day), not adjustment
         dStart := j.dt_embarked;
         bNormalTrans := FALSE;
      else
         -- if than dFirstDay but greater than 26 of previous month
         if j.dt_embarked >= to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD') then
            dStart := j.dt_embarked;
         end if;
      end if;

      -- check end date
      if (j.dt_disembarked is null) or
         (  (j.dt_disembarked is not null) and
            (j.dt_disembarked > p_date_to) )    -- dito nagsubok
            --(j.dt_disembarked >= dEnd) )    -- ito ang sinubukan
      then
         dEnd := p_date_to;
      elsif j.dt_disembarked < p_date_to then
         dEnd := j.dt_disembarked;
         bNormalTrans := FALSE;
         if j.dt_disembarked < p_date_fr then
            -- for feb changes
            -- modify start date if disembarks after previous payroll cut-off. (scenario disembark Jan.26)
            dEnd := p_date_fr;
            if j.dt_embarked > dFirstDay then
               dStart := j.dt_embarked;
            else
               dStart := dFirstDay-1;
            end if;
            -- for feb changes
            vAdjFlag := 'Y';
            bAdjustment := TRUE;
         end if;
      end if;

      if p_empl_id in (dEmplID) then
         dbms_output.put_line ('check 1: ' || p_empl_id || ': start=' || to_char(dStart) || ': End=' || to_char(dEnd) || ': dPrevStart=' || to_char(dPrevStart) || ': dFirstDay=' || to_char(dFirstDay) || ': RecCtr=' || to_char(nRecCtr));
      end if;

      if nRecCtr >= 1 then
         if dStart = p_date_fr then
            if dStart = j.dt_disembarked then
               dStart := j.dt_disembarked;
            --else 
               --dStart := dFirstDay;
            end if;
         end if;
         -- case: crew disembarked after start of payroll sched 
         if dEnd >= dPrevStart then      -- disembarked gt start dt/latest appt 
            dEnd := dPrevStart-1;
         else
            if dEnd = p_date_fr then     -- disembarked eq to start date
               dEnd := p_date_fr;
            else                         -- disembarked lt start dt/latest appt 
               if dPrevStart=to_date(to_char(p_date_fr, 'YYYYMM') || '10', 'YYYYMMDD') and bIsEndOfMonth then    -- service is continous no need to compute, no adjustment
                  vAdjFlag := 'N';
                  bAdjustment := FALSE;
                  bContinuous := TRUE;
               end if;
               --if bIsEndOfMonth then
                  dEnd := j.dt_disembarked;
               --else
               --   dEnd := p_date_fr-1;
               --end if;
            end if;
         end if;
      else
         vLatestVess  := j.voya_vess_code;
         vLatestTitle := j.title;
      end if;

      if p_empl_id in (dEmplID) then
         dbms_output.put_line ('check 2: ' || p_empl_id || ': start=' || to_char(dStart) || ': End=' || to_char(dEnd) || ': Day=' || to_char((dEnd-dStart)) || ': RecCtr=' || to_char(nRecCtr));
      end if;
      -- check total days
      if bIsEndOfMonth then
         if (dEnd-dStart) >= 0 then
            nUpTO := (dEnd-dStart) + 1;
            dDate := dStart - 1;
            if p_empl_id in (dEmplID) then
               dbms_output.put_line ('check20: ' || p_empl_id || ': dDate' || to_char(dDate) || ': dStart' || to_char(dStart) || ': nNumDay=' || to_char(nNumDay));
            end if;
            for i in 1..nUpTo loop
               dDate := dDate + 1;
               if dStart >= (p_date_fr -6) then       -- embarked after first payday cutoff (after 10thday of the month)
                  if dStart = to_date(to_char(p_date_fr, 'YYYYMM') || '10', 'YYYYMMDD')  then
                     if p_date_fr <= dDate then
                        nNumDay := nNumDay + 1;
                     end if; 
                  else
                     if (p_date_fr -6) <= dDate then
                        nNumDay := nNumDay + 1;
                     end if;
                  end if;
               elsif p_date_fr <= dDate then
                  nNumDay := nNumDay + 1;
               end if;
               if sf_is_holiday (dDate) = 1 then
                  if sf_is_sunday(dDate) = 1 then
                     nHolSun := nHolSun + 1 ;
                  else
                     nRegHol := nRegHol + 1;
                  end if;
               else
                  if sf_is_sunday(dDate) = 1 then
                     nRegSun := nRegSun + 1;
                  end if;
               end if;
            end loop;
            if p_empl_id in (dEmplID) then
               dbms_output.put_line ('check21: ' || p_empl_id || ': p_date_fr' || to_char(p_date_fr) || ': dDate' || to_char(dDate) || ': nNumDay=' || to_char(nNumDay));
            end if;
            -- check if dt_embarked is between 11 to 15. after cut-off.   
            if dDate < p_date_fr then        
               if dDate > (p_date_fr-6) then        -- updated due to transfers on Jan. 5, no adjustment needed...
                  nNumDay := (dDate-p_date_fr) + 1;
               end if;            
            end if;            
            if p_empl_id in (dEmplID) then
               dbms_output.put_line ('check22: ' || p_empl_id || ': dDate' || to_char(dDate) || ': nNumDay=' || to_char(nNumDay));
            end if;
         else
            nUpTO := (abs(dEnd-dStart))-1;
            dDate := dEnd;
            for i in 1..nUpTo loop
               dDate := dDate  + 1;
               nNumDay := nNumDay - 1;
               if sf_is_holiday (dDate) = 1 then
                  if sf_is_sunday(dDate) = 1 then
                     nHolSun := nHolSun - 1 ;
                  else
                     nRegHol := nRegHol - 1;
                  end if;
               else
                  if sf_is_sunday(dDate) = 1 then
                     nRegSun := nRegSun - 1;
                  end if;
               end if;
            end loop;
         end if;
      else
         if vAdjFlag = 'Y' then
            dStart := dStart + 1;
            dEnd   := p_date_fr - 1;
            nUpTO := (dEnd-dStart) +1;
            nNumDay := nNumDay + nUpTO;
            -- for feb chages (Jan 26 disembark)
            if dEnd between dFirstDay and p_date_fr then
               nNumDay := nNumDay * -1;
            end if;
            -- for feb chages (Jan 26 disembark)
         else
            if (dEnd-dStart) >= 0 then
               nUpTO := (dEnd-dStart) +1;
               nNumDay := nNumDay + nUpTO;
            else
               nUpTO := (abs(dEnd-dStart) - 1) * -1;
               nNumDay := nNumDay + nUpTO;
            end if;
         end if;
      end if;

      -- handling of monthly wager... should be fixed to 15 days except when there are transfers or breaks...
      if p_sal_freq = 'MONTHLY' then 
         if bNormalTrans then 
            nNumDay := 15;
         else  -- not Normal - with breaks/transfers
            if dEnd = p_date_to then
               if to_char(p_date_to, 'DD') = '31' then
                  nNumDay := nNumDay - 1;
               elsif to_char(p_date_to, 'DD') = '28' then
                  nNumDay := nNumDay + 2;
               elsif to_char(p_date_to, 'DD') = '29' then 
                  nNumDay := nNumDay + 1;
               end if;
            end if;
         end if;
      end if;
      
      if j.empl_empl_id in (dEmplID) then
         dbms_output.put_line ('check 3: ' || p_empl_id || ': start' || to_char(dStart) || ': End=' || to_char(dEnd) || 
                               ': nNumDay=' || to_char(nNumDay) || ': vAdjFlag=' || vAdjFlag || 
                               ': j.basic_rate=' || j.basic_rate || ': j.basic_rate_g=' || j.basic_rate_g  || 
                               ': p_Sunday_RF=' || p_Sunday_RF );
      end if;
      -- compute attendance
      begin
         nSeqNo  := nSeqNo + 1;

         if p_sal_freq = 'MONTHLY' then 
            --nSalaryR   := (j.basic_rate/30) * nNumDay;
            nSalaryR   := j.basic_rate * nNumDay;   -- basic rate for monthly employee are encoded as regular or daily
            nSalaryG   := nSalaryR;
            if nvl(j.basic_rate_g,0) > 0 then
               --nSalaryG   := (j.basic_rate_g/30) * nNumDay;   -- basic rate for monthly employee are encoded as regular or daily
               nSalaryG   := (j.basic_rate_g) * nNumDay;   -- basic rate for monthly employee are encoded as regular or daily
            end if;
            nSunday_R  := ( p_Sunday_RF * j.basic_rate );
            nHoliday_R := ( p_Holiday_RF * j.basic_rate );
            nHolSun_R  := ( p_HolSun_RF * j.basic_rate );
         else
            nSalaryR   := j.basic_rate * nNumDay;
            nSalaryG   := nSalaryR;
            if nvl(j.basic_rate_g,0) > 0 then
               nSalaryG   := j.basic_rate_g * nNumDay;
            end if;
            nSunday_R  := ( p_Sunday_RF * j.basic_rate );
            nHoliday_R := ( p_Holiday_RF * j.basic_rate );
            nHolSun_R  := ( p_HolSun_RF * j.basic_rate );
         end if;

         if vAdjFlag = 'N' then
            vPaty := 'REG';
         else
            vPaty := 'REG-ADJ';
            if dEnd > p_date_fr then
               update pys_payroll_dtl
               set   no_days = no_days - nNumDay,
                     amt     = nvl(decode(sal_freq,'MONTHLY', basic_rate/30,  basic_rate) * (no_days - nNumDay),0),
                     amt_g   = nvl(decode(sal_freq,'MONTHLY', basic_rate_g/30,  basic_rate_g) * (no_days - nNumDay),0),
                     period_fr = period_fr + nNumDay
               where  pahd_payroll_no = p_payno
               and    empl_empl_id = j.empl_empl_id
               and    paty_code = 'REG';
            end if;
         end if;

         if bContinuous then
            nNumDay := 0;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess  )
            values ( p_payno, p_year, p_mon, p_date_fr, dEnd, nSeqNo, j.empl_empl_id, j.posi_code, j.title, vPaty, 0, nNumDay, j.basic_rate, 0, decode(j.basic_rate_g,0,j.basic_rate,j.basic_rate_g), j.voya_vess_code, 'FL', user, sysdate, 'ADD', vAdjFlag, p_sal_freq, vLatestVess );
         else
            if dEnd > p_date_fr then
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess  )
               values ( p_payno, p_year, p_mon, p_date_fr, dEnd, nSeqNo, j.empl_empl_id, j.posi_code, j.title, vPaty, nSalaryR, nNumDay, j.basic_rate, nSalaryG, decode(j.basic_rate_g,0,j.basic_rate,j.basic_rate_g), j.voya_vess_code, 'FL', user, sysdate, 'ADD', vAdjFlag, p_sal_freq, vLatestVess );
            else
               insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess  )
               values ( p_payno, p_year, p_mon, dStart, dEnd, nSeqNo, j.empl_empl_id, j.posi_code, j.title, vPaty, nSalaryR, nNumDay, j.basic_rate, nSalaryG, decode(j.basic_rate_g,0,j.basic_rate,j.basic_rate_g), j.voya_vess_code, 'FL', user, sysdate, 'ADD', vAdjFlag, p_sal_freq, vLatestVess );
            end if; 
         end if; 
      end;

      if bIsEndOfMonth then
         if nRegSun > 0 then
            nSeqNo := nSeqNo + 1;
            nSuPay := nSunday_R * nRegSun;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_Vess )
            values ( p_payno, p_year, p_mon, dStart, dEnd, nSeqNo, j.empl_empl_id, j.posi_code, j.title, 'OT-SUN-FLT', nSuPay, nRegSun, nSunday_R, j.voya_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;

         if nRegHol > 0 then
            nSeqNo := nSeqNo + 1;
            nHoPay := nHoliday_R * nRegHol;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, dStart, dEnd, nSeqNo, j.empl_empl_id, j.posi_code, j.title, 'OT-HOL-FLT', nHoPay, nRegHol, nHoliday_R, j.voya_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;

         if nHolSun > 0 then
            nSeqNo := nSeqNo + 1;
            nHSPay := nHolSun_R * nHolSun;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, dStart, dEnd, nSeqNo, j.empl_empl_id, j.posi_code, j.title, 'OT-HS-FLT', nHSPay, nHolSun, nHolSun_R, j.voya_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end if;
      end if;
      nTSalaryG := nTSalaryG + nSalaryG;
      nTSuPay   := nTSuPay   + nvl(nSupay,0);
      nTHoPay   := nTHoPay   + nvl(nHoPay,0);
      nTHSPay   := nTHSPay   + nvl(nHSPay,0);
      nTNumDay  := nTNumDay  + nNumDay;
      nTRegSun  := nTRegSun  + nRegSun;
      nTRegHol  := nTRegHol  + nRegHol;
      nTHolSun  := nTHolSun  + nHolSun;

      if nRecCtr = 0 then
         -- get allowances (FLT)
         for x in allo_flt ( j.empl_empl_id, j.voya_vess_code,  j.voya_voyage_date  ) loop
            nSeqNo := nSeqNo + 1;
            nAllowances := nAllowances + (x.amt*nNumDay);
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, j.empl_empl_id, j.posi_code, j.title, x.allo_code, (x.amt*nNumDay), nNumDay, x.amt, j.voya_vess_code, 'FL', user, sysdate, 'ADD', p_sal_freq, vLatestVess );
         end loop;
      end if;

      nNumDay  := 0;
      nRegSun  := 0;
      nRegHol  := 0;
      nHolSun  := 0;
      nRecCtr     := nRecCtr + 1;
      dPrevStart  := dStart;
      dPrevEnd    := dEnd;
      bContinuous := FALSE; 
   end loop;

   nRecCtr := 0;
   -- check if there are adjustment
   if bAdjustment then
      for i in adj_flt loop
         nRecCtr := nRecCtr + 1;
         if p_empl_id in (dEmplID) then
            dbms_output.put_line ('check 4: ' || p_empl_id || ':i.period_fr=' || to_char(i.period_fr) || ': i.period_to=' || to_char(i.period_to) ||
                                  ': i.basic_rate=' || to_char(i.basic_rate) || ': i.basic_rate_g=' || to_char(i.basic_rate_g) ||
                                  ': no_days=' || to_char(i.no_days) || ': adj_flag='|| i.adj_flag);
         end if;
         if i.adj_flag ='Y' then
            nAHolSun := 0;
            nARegHol := 0;
            nARegSun := 0;
            nANumDay := 0;
            nASuPay  := 0;
            nAHoPay  := 0;
            nAHSPay  := 0;
            dAStart  := NULL;
            dAEnd    := NULL;
            if bIsEndOfMonth then
               -- checking if assumed days falls on disembarked date.
               if i.no_days > 0 then
                  dAStart := i.period_to;
                  dAEnd   := p_date_fr;
                  if dAStart = dAEnd then
                     nAUpTO  := 1;
                  else
                     nAUpTO  := (dAEnd-dAStart)-1;
                  end if; 
                  dADate  := i.period_to;
                  for i in 1..nAUpTO loop
                     dADate := dADate + 1;
                     nANumDay := nANumDay + 1;
                     if sf_is_holiday (dADate) = 1 then
                        if sf_is_sunday(dADate) = 1 then
                           nAHolSun := nAHolSun + 1 ;
                        else
                           nARegHol := nARegHol + 1;
                        end if;
                     else
                        if sf_is_sunday(dADate) = 1 then
                           nARegSun := nRegSun + 1;
                        end if;
                     end if;
                  end loop;
               else
                  -- if assumed days falls on disembarked date.
                  dAStart := i.period_to+1;
                  dAEnd   := p_date_fr;
                  if dAStart between (p_date_fr-5) and p_date_fr then  -- if embarked falls 11 to 15
                     nANumDay := (dAEnd - dAStart)*-1;
                  else 
                     nANumDay := i.no_days;
                  end if;
                  if dAStart between (p_date_fr-5) and p_date_fr then  -- if embarked falls 11 to 15
                     dPrevRateG := 0;
                     dPrevRateR := 0;
                  end if;

                  -- do not change rate, no adjustment for report B puposes. (e.g. transfers Jan5)
                  if bIsEndOfMonth and dAStart >= to_date(to_char(p_date_fr,'"01"MMYYYY'), 'DDMMYYYY') then
                     dPrevRateG := 0;
                     dPrevRateR := 0;
                  end if;

               end if;
            else
               dAStart := i.period_fr;
               dAEnd   := i.period_to;
               nAUpTO := (dAEnd-dAStart) + 1;
               dADate := i.period_fr - 1;
               for i in 1..nAUpTO loop
                  dADate := dADate + 1;
                  nANumDay := nANumDay + 1;
                  if sf_is_holiday (dADate) = 1 then
                     if sf_is_sunday(dADate) = 1 then
                        nAHolSun := nAHolSun + 1 ;
                     else
                        nARegHol := nARegHol + 1;
                     end if;
                  else
                     if sf_is_sunday(dADate) = 1 then
                        nARegSun := nRegSun + 1;
                     end if;
                  end if;
               end loop;
               -- for feb chages (Jan 26 disembark)
               if dAEnd < p_date_fr then 
                  nANumDay := nANumDay * -1;
                  nARegSun := nARegSun * -1;
                  nARegHol := nARegHol * -1;
                  nAHolSun := nAHolSun * -1;
                  dPrevRateG := 0;
                  dPrevRateR := 0;
               end if;              
               -- for feb chages (Jan 26 disembark)
            end if;
            if bIsEndOfMonth then
               if i.sal_freq = 'MONTHLY' then
                  -- basic pay for monthly employees are also encoded daily.
                  nARate  := dPrevRateR - (i.basic_rate);
                  nASuPay := (p_Sunday_RF * (i.basic_rate)) * nARegSun;
                  nAHoPay := 0; --(p_Sunday_RF * (i.basic_rate)) * nARegHol;
                  nAHSPay := 0; --(p_Sunday_RF * (i.basic_rate)) * nAHolSun;
                  nADays  := (p_Sunday_RF*nARegSun) + nANumDay;
               else
                  nARate  := dPrevRateR - i.basic_rate;
                  nASuPay := (p_Sunday_RF * i.basic_rate) * nARegSun;
                  nAHoPay := 0; --(p_Sunday_RF * i.basic_rate) * nARegHol;
                  nAHSPay := 0; --(p_Sunday_RF * i.basic_rate) * nAHolSun;
                  nADays  := (p_Sunday_RF*nARegSun) + nANumDay;
               end if;
            else
               if i.sal_freq = 'MONTHLY' then
                  --nARate  := dPrevRateR - (i.basic_rate/30); -- change during feb fixes
                  nARate  := dPrevRateR - (i.basic_rate);
               else
                  nARate  := dPrevRateR - i.basic_rate;
               end if; 
               --nASuPay := (p_Sunday_RF * nARate) * nARegSun; -- change during feb fixes
               --nAHoPay := (p_Sunday_RF * nARate) * nARegHol; -- change during feb fixes
               --nAHSPay := (p_Sunday_RF * nARate) * nAHolSun; -- change during feb fixes
               nASuPay := (p_Sunday_RF * abs(nARate)) * nARegSun;
               nAHoPay := (p_Sunday_RF * abs(nARate)) * nARegHol;
               nAHSPay := (p_Sunday_RF * abs(nARate)) * nAHolSun;
               nADays  := (p_Sunday_RF*nARegSun) + (p_Holiday_RF*nARegHol) + (p_HolSun_RF*nAHolSun) + nANumDay;
            end if;
            --nAdjPay := nASuPay + nAHoPay + nAHSPay + (abs(nARate) * nANumDay); -- change during feb fixes
            nAdjPay := nASuPay + nAHoPay + nAHSPay + (abs(nARate) * nANumDay);

            if p_empl_id in (dEmplID) then
               dbms_output.put_line ('check 5: ' || p_empl_id || ': nANumDay=' || to_char(nANumDay)|| ': nADays=' || to_char(nADays) || 
                                     ': nARegSun=' || to_char(nARegSun) || 
                                     ': nARegHol=' ||  to_char(nARegHol) || ': nAHolSun=' || to_char(nAHolSun) ||
                                     ': nASuPay=' || to_char(nASuPay) || ': nAHoPay=' || to_char(nAHoPay) ||
                                     ': nAHSPay=' || to_char(nAHSPay) || ': nAdjPay='|| nAdjPay ||
                                     ': dPrevRateR=' || to_char(dPrevRateR) || ': dPrevRateG=' || to_char(dPrevRateG) ||
                                     ': dAStart=' || to_char(dAStart) || ': dAEnd=' || to_char(dAEnd) ||
                                     ': i.period_to='|| to_char(i.period_to));
            end if;

            update pys_payroll_dtl
            set    period_fr = dAStart,
                   period_to = dAEnd-1,
                   --basic_rate = abs(nvl(nvl(dPrevRateR,0) - decode(sal_freq,'MONTHLY',i.basic_rate/30,i.basic_rate),0)),
                   --basic_rate_g = abs(nvl(nvl(dPrevRateG,0) - decode(sal_freq,'MONTHLY',i.basic_rate_g/30,i.basic_rate_g),0)),
                   basic_rate = abs(nvl(nvl(dPrevRateR,0) - decode(sal_freq,'MONTHLY',i.basic_rate,i.basic_rate),0)),
                   basic_rate_g = abs(nvl(nvl(dPrevRateG,0) - decode(sal_freq,'MONTHLY',i.basic_rate_g/30,i.basic_rate_g),0)),
                   amt_g   = nvl(abs(nvl(dPrevRateG,0) - decode(sal_freq,'MONTHLY',i.basic_rate_g,i.basic_rate_g)) * nADays,0),
                   amt     = nvl(nAdjPay,0),
                   no_days = nADays
            where  pahd_payroll_no = i.pahd_payroll_no
            and    seq_no = i.seq_no;

            update pys_payroll_dtl
            set    period_fr = dAStart,
                   period_to = dAEnd-1
            where  pahd_payroll_no = i.pahd_payroll_no
            and    paty_code not like 'REG%'
            and    empl_empl_id = p_empl_id
            and    period_to = i.period_to;
            
            if p_empl_id in (dEmplID) then
               dbms_output.put_line ('check 6: ' || p_empl_id || ': dAStart=' || to_char(dAStart) || ':dAEnd-1=' || to_char(dAEnd-1) || 
                                     ': i.period_to=' ||  to_char(i.period_to) || ': nAHolSun=' || to_char(nAHolSun) ||
                                     ': nASuPay=' || to_char(nASuPay) || ': nAHoPay=' || to_char(nAHoPay) ||
                                     ': nAHSPay=' || to_char(nAHSPay) || ': nAdjPay='|| nAdjPay ||
                                     ': dPrevRateR=' || to_char(dPrevRateR) || ': dPrevRateG=' || to_char(dPrevRateG) ||
                                     ': dAStart=' || to_char(dAStart) || ': dAEnd=' || to_char(dAEnd) ||
                                     ': i.period_to='|| to_char(i.period_to));
            end if;

            if i.sal_freq = 'MONTHLY' then
               nTSalAdj := nTSalAdj + ((dPrevRateG - (i.basic_rate_g/30)) * i.no_days);
            else
               nTSalAdj := nTSalAdj + ((dPrevRateG - i.basic_rate_g) * i.no_days);
            end if;
         else
            if nRecCtr = 1 then
               if i.sal_freq = 'MONTHLY' then
                  --dPrevRateR := nvl(i.basic_rate/30,0);
                  --dPrevRateG := nvl(i.basic_rate_g/30,0);
                  dPrevRateR := nvl(i.basic_rate,0);
                  dPrevRateG := nvl(i.basic_rate_g,0);
                  dPrevStart := i.period_fr;
                  dPrevEnd   := i.period_to;
               else
                  dPrevRateR := nvl(i.basic_rate,0);
                  dPrevRateG := nvl(i.basic_rate_g,0);
                  dPrevStart := i.period_fr;
                  dPrevEnd   := i.period_to;
               end if;
            end if;
         end if;
      end loop;
      begin
         select sum(amt_g) into nTSalaryG
         from   pys_payroll_dtl
         where  pahd_payroll_no = p_payno
         and    empl_empl_id = p_empl_id
         and    paty_code like 'REG%';
      exception
         when no_data_found then nTSalaryG := 0;
      end;
      begin
         select amt into nAllowances
         from   pys_payroll_dtl
         where  pahd_payroll_no = p_payno
         and    empl_empl_id = p_empl_id
         and    paty_code = 'COLA';
      exception
         when no_data_found then nAllowances := 0;
      end;
   end if;

   p_numday    := nTNumDay;
   p_tsalaryg  := nTSalaryG;
   p_SuPay     := nTSuPay;
   p_HoPay     := nTHoPay;
   p_HSPay     := nTHSPay;
   p_Allowance := nAllowances;
   p_o_seq_no  := nSeqNo;
   p_latestvess  := vLatestVess;
   p_latesttitle := vLatestTitle;


end sp_count_flt_attendance;
/
