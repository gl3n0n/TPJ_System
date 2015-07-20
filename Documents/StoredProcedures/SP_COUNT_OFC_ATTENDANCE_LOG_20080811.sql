create or replace procedure sp_count_ofc_attendance_log
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
   p_dEmplID    in  varchar2

) is

   dEmplID      varchar2(16) := p_dEmplID;
   vSalFreq     Varchar2(12);
   dAm_time_in  date;
   nNum_Hours   Number(10,5) := 0;
   nOT_Hours    Number(10,5) := 0;
   vOuter_Port  Varchar2(12);
   vIsOuterPort Varchar2(12);

   nBasicR      Number(10,5) := 0;
   nCola        Number(10,5) := 0;
   nOvertm      Number(10,5) := 0;
   nRegHol      Number(10,5) := 0;
   nRegSun      Number(10,5) := 0;
   nRegDay      Number(10,5) := 0;
   nHolSun      Number(10,5) := 0;
   nSuOT        Number(10,5) := 0;
   nHoOT        Number(10,5) := 0;
   nHSOT        Number(10,5) := 0;
   nEnd         Number(10,5) := 0;
   dChkDate     Date;
   dTmpDate     Date;
   dStart       Date;
   dEnd         Date;

begin

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   if p_empl_id = dEmplID then
      dbms_output.put_line ('ofc 1: dEmplID=' || dEmplID || ', dStart: ' || to_char(dStart) || ', dEnd: ' || to_char(dEnd) || ',p_basic_r:' || to_char(p_basic_r) || ',p_basic_g:' || to_char(p_basic_g));
   end if;

   if p_isMonthly = 'Y' then
      vSalFreq := 'MONTHLY';
   else
      vSalFreq := 'SEMI-MO';
   end if;

   -- check every day
   nEnd := (p_date_to - dStart) + 1;
   for j in 1..nEnd loop
      dChkDate := (dStart-1) + j;
      if dChkDate <= dEnd then
         begin
            select am_time_in, num_hours, ot_hours, outer_port
            into   dAm_time_in, nNum_Hours, nOT_Hours, vOuter_Port
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dChkDate;

            if dEmplID = p_empl_id then
               dbms_output.put_line ('ofc 2: dChkDate= ' || to_char(dChkDate) || ',dAm_time_in=' || to_char(dAm_time_in) ||
                                     ',nNum_Hours=' || to_char(nNum_Hours) ||
                                     ',vOuter_Port=' || vOuter_Port || ',vIsOuterPort=' || vIsOuterPort );
            end if;
         exception
            when no_data_found then
               nNum_Hours  := 0;
               nOT_Hours   := 0;
               vOuter_Port := 'N';
            when others then
               raise_application_error (-20001, 'Error on sp_count_ofc_attendance_log-get employee attendance' || p_empl_id || ' ' || SQLERRM);
         end;
      else
         vOuter_Port := nvl(vIsOuterPort, 'N');
         if nvl(vIsOuterPort,'N') = 'Y' then
            nNum_Hours  := 8;
            nOT_Hours   := 0;
         elsif sf_is_sunday (dChkDate) = 0 then
            nNum_Hours  := 8;
            nOT_Hours   := 0;
         else
            nNum_Hours  := 0;
            nOT_Hours   := 0;
         end if;
      end if;

      if dEmplID = p_empl_id then
         dbms_output.put_line ('ofc 3: dChkDate= ' || to_char(dChkDate) || ',dAm_time_in=' || to_char(dAm_time_in) ||
                               ',nNum_Hours=' || to_char(nNum_Hours) || ',nOT_Hours=' || to_char(nOT_Hours) ||
                               ',vOuter_Port=' || vOuter_Port || ',vIsOuterPort=' || vIsOuterPort );
      end if;

      if nNum_Hours > 0 then
         if sf_is_sunday (dChkDate) = 1 then
            if sf_is_holiday (dChkDate) = 1 then
               if dAm_time_in is not null then
                  if nNum_Hours >= 4  then
                     nRegDay := 1;
                     nRegHol := 1;
                     nHSOT  := (nOT_Hours/8);
                  else
                     nRegDay := 1;
                     nRegHol := (nNum_Hours/4);
                  end if;
               else
                  nRegDay := 1;
               end if;
            else
               if nNum_Hours >= 4  then
                  nRegDay := 1;
                  if p_IsMonthly='N' and vOuter_Port='N' then
                     nSuOT := (nOT_Hours/8);
                  end if;
               else
                  nRegDay := nRegDay + (nNum_Hours/4);
               end if;
            end if;
         elsif sf_is_holiday (dChkDate) = 1 then
            if dAm_time_in is not null then
               nRegDay := 1;
               if nNum_Hours >= 6  then
                  nRegHol := 1;
                  nHoOT := (nOT_Hours/8);
               else
                  nRegHol := (nNum_Hours/6);
               end if;
            else
               nRegDay := 1;
            end if;
         else
            -- Overtime
            if nNum_Hours >= 8  then
               nRegDay := 1;
            else
               nRegDay := (nNum_Hours/8);
            end if;
            nOvertm := (nOT_Hours/8);
         end if;
      else
         if sf_is_holiday (dChkDate) = 1 then
            nRegDay := 1;
         end if;

         -- Monthly but non-managers (sundays are counted)
         if p_isMonthly = 'Y' and (sf_is_sunday (dChkDate) = 1) then
            nRegDay := 1;
         end if;
      end if;

      nOvertm  := ( p_Overtm_RO  * nOvertm );
      nRegSun  := ( p_Sunday_RO  * nRegSun );
      nRegHol  := ( p_Holiday_RO * nRegHol );
      nSuOT    := ( p_HolSun_RO  * nSUOT );
      nHoOT    := ( p_HolSun_RO  * nHoOT );
      nHsOT    := ( p_HolSun_RO  * nHsOT );

      if vOuter_Port = 'Y' then
         nBasicR  := p_Outer_RO * p_basic_r;
      else
         nBasicR  := p_basic_r;
      end if;

      if (nRegDay+nOvertm+nRegSun+nRegHol+nSuOT+nHoOT+nHsOT) > 0 then

         -- check if with cola
         nCola := sf_get_latest_cola (p_empl_id, dChkDate);

         if dEmplID = p_empl_id then
            dbms_output.put_line ('check: nRegDay=' || to_char(nRegDay) || ',nRegSun=' || to_char(nRegSun) || ',nRegHol =' || to_char(nRegHol ) ||
                                  ',nOvertm=' || to_char(nOvertm) || ',nHolOT=' || to_char(nHoOT) || ',nCola=' || to_char(nCola) ||
                                  ',nBasicR =' || to_char(nBasicR ) || ',p_basic_r =' || to_char(p_basic_r ));
         end if;

         -- create payroll log
         if dChkDate < p_date_fr then    -- check assumed dates from previous payroll
            update pys_payroll_dtl_log
            set    a_dept_code    = p_dept_code,
                   a_posi_code    = p_posi_code,
                   a_basic_rate   = nBasicR,
                   a_basic_rate_g = p_basic_g,
                   a_ndays        = nRegDay,
                   a_amt          = nBasicR*nRegDay,
                   a_amt_g        = p_basic_g/2,
                   ot_pay         = nOvertm,
                   --ot_su_pay      = nSuOT,
                   --ot_ho_pay      = nHoOT,
                   ht_pay         = nHsOT,
                   a_oport        = vOuter_Port,
                   su_pay         = nRegSun,
                   ho_pay         = nRegHol,
                   hs_pay         = 0,
                   a_cola_pay     = nCola,
                   modified_by    = user,
                   dt_modified    = sysdate
            where empl_empl_id = p_empl_id
            and   pay_date = dChkDate;
            if sql%NOTFOUND then
               insert into pys_payroll_dtl_log
                      ( payroll_no, empl_empl_id, pay_date, a_dept_code, a_posi_code, sal_freq,
                        a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, a_ot_pay, a_hs_pay, a_oport,
                        a_su_pay, a_ho_pay, a_ht_pay, a_cola_pay, a_ndays, created_by, dt_created
                      )
               values ( p_payno, p_empl_id, dChkDate, p_dept_code, p_posi_code, vSalFreq,
                        nBasicR, p_basic_g, nBasicR*nRegDay, p_basic_g/2, nOvertm, 0, vOuter_Port,
                        nRegSun, nRegHol, nHoOT, nCola, nRegDay, user, sysdate
                      );
            end if;
         else

            insert into pys_payroll_dtl_log
                   ( payroll_no, empl_empl_id, pay_date, dept_code, posi_code, sal_freq,
                     basic_rate, basic_rate_g, amt, amt_g, ot_pay, ht_pay, oport,
                     su_pay, ho_pay, hs_pay, cola_pay, ndays, created_by, dt_created
                   )
            values ( p_payno, p_empl_id, dChkDate, p_dept_code, p_posi_code, vSalFreq,
                     nBasicR, p_basic_g, nBasicR*nRegDay, p_basic_g/2, nOvertm, 0, vOuter_Port,
                     nRegSun, nRegHol, nHoOT, nCola, nRegDay, user, sysdate
                   );
         end if; -- <if dChkDate < p_date_fr then>
      end if; -- <(nRegDay+nOvertm+nRegSun+nRegHol+nHolOT) > 0>

      if dChkDate = dEnd then
         vIsOuterPort := vOuter_Port;
      end if;

      -- reset variables
      dAm_time_in := null;
      nNum_Hours  := 0;
      nOT_Hours   := 0;
      vOuter_Port := 'N';
      nOvertm     := 0;
      nRegDay     := 0;
      nRegSun     := 0;
      nRegHol     := 0;
      nSuOT       := 0;
      nHoOT       := 0;
      nHsOT       := 0;
      nBasicR     := 0;
      nCola       := 0;

   end loop; -- <for j in 1..nEnd loop>

end sp_count_ofc_attendance_log;
/
