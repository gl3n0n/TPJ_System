create or replace procedure SP_COUNT_FLT_ATTENDANCE_LOG
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
   p_dEmplID    in  varchar2, 
   p_sal_freq   in  varchar2

) is

   dEmplID      varchar2(16) := p_dEmplID;
   dLatestEmbarked   Date;
   dLatestDismbarked Date;
   vLatestVessel     Varchar2(16);
   vLatestPosition   Varchar2(32);  
   vLatestTitle      Varchar2(32);
   nLatestBasic      Number(8,2);
   nLatestBasicG     Number(8,2);
   
   nCola      Number(8,2);
   nRegHol    Number := 0;
   nHolSun    Number := 0;
   nRegSun    Number := 0;
   nEnd       Number := 0;
   dChkDate   Date;
   dTmpDate   Date;
   dStart     Date;
   dEnd       Date;
   vOnBoard   Varchar2(1);

begin

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   -- check every day
   nEnd := (p_date_to - dStart) + 1;
   for j in 1..nEnd loop
      dChkDate := (dStart-1) + j;
      if dLatestEmbarked is null then
         dTmpDate := sf_get_latest_embark(p_empl_id, dChkDate);
         if dTmpDate is not null then  
            begin
               select vocr.dt_embarked, vocr.dt_disembarked, vocr.voya_vess_code, 
                      empl.posi_code, vocr.title, vocr.basic_rate, vocr.basic_rate_g
               into   dLatestEmbarked, dLatestDismbarked, vLatestVessel, 
                      vLatestPosition, vLatestTitle, nLatestBasic, nLatestBasicG
               from   cms_voyage_crew vocr, 
                      cms_vessels vess, 
                      pms_employees empl
               where  vocr.voya_voyage_date <= dTmpDate
               and    vocr.dt_embarked = dTmpDate
               and    vocr.voya_vess_code = vess.code
               and    vocr.empl_empl_id = empl.empl_id
               and    vocr.empl_empl_id = p_empl_id
               and    vocr.passenger = 'N';
            exception
               when no_data_found then 
                  -- set latest embark and disembark to backdate, so as not to allow to compute 
                  dLatestEmbarked   := to_date('19000101', 'YYYYMMDD');
                  dLatestDismbarked := to_date('19000101', 'YYYYMMDD');
               when others then 
                  raise_application_error (-20001, 'Error on sp_count_flt_attendance_log-get service for employee ' || p_empl_id || ' ' || SQLERRM);
            end;
         else
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         end if;
      end if; -- <if dLatestEmbarked is null then>

      -- check if on board
      if dChkDate between dLatestEmbarked and nvl(dLatestDismbarked, dChkDate+2) then
         vOnBoard := 'Y'; 
      else 
         if (dChkDate > dEnd) and dTmpDate is not null then  -- check if still on actual payroll period (10 and 25)
            vOnBoard := 'Y'; 
         else 
            vOnBoard := 'N'; 
         end if;
      end if;

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: dChkDate=' || to_char(dChkDate) || ',dLatestEmbarked=' || to_char(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || to_char(dLatestDismbarked) || ',vOnBoard=' || vOnBoard );
      end if; 

      if vOnBoard = 'Y' then
         -- check if pay date is sunday or holiday
         if sf_is_holiday (dChkDate) = 1 then
            if sf_is_sunday(dChkDate) = 1 then
               nHolSun := p_HolSun_RF;
            else
               nRegHol := p_Holiday_RF;
            end if;
         else
            if sf_is_sunday(dChkDate) = 1 then
               nRegSun := p_Sunday_RF;
            end if;
         end if;
         
         -- check if with cola
         nCola := sf_get_latest_cola (p_empl_id, dChkDate);
         
         if dEmplID = p_empl_id then
            dbms_output.put_line ('check: nRegSun=' || to_char(nRegSun) || ',nRegHol =' || to_char(nRegHol ) ||
                                  ',nHolSun=' || to_char(nHolSun) || ',nCola=' || to_char(nCola) );
         end if; 

         -- create payroll log
         if dChkDate < p_date_fr then    -- check assumed dates from previous payroll
            update pys_payroll_dtl_log
            set    a_vess_code    = vLatestVessel, 
                   a_posi_code    = vLatestPosition, 
                   a_title        = vLatestTitle,
                   a_basic_rate   = nLatestBasic,
                   a_basic_rate_g = nLatestBasic, 
                   a_amt          = nLatestBasic, 
                   a_amt_g        = nLatestBasic, 
                   a_ot_pay       = 0, 
                   a_ht_pay       = 0, 
                   a_oport        = 'N',
                   a_su_pay       = nRegSun, 
                   a_ho_pay       = nRegHol, 
                   a_hs_pay       = nHolSun, 
                   a_cola_pay     = nCola,
                   modified_by    = user, 
                   dt_modified    = sysdate
            where empl_empl_id = p_empl_id
            and   pay_date = dChkDate; 
            if sql%NOTFOUND then
               insert into pys_payroll_dtl_log 
                      ( payroll_no, empl_empl_id, pay_date, dept_code, a_vess_code, a_posi_code, a_title, sal_freq, 
                        latest_vess, a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, a_ot_pay, a_ht_pay, a_oport,
                        a_su_pay, a_ho_pay, a_hs_pay, a_cola_pay, created_by, dt_created
                      ) 
               values ( p_payno, p_empl_id, dChkDate, 'FL', vLatestVessel, vLatestPosition, vLatestTitle, p_sal_freq,
                        vLatestVessel, nLatestBasic, nLatestBasic, nLatestBasic, nLatestBasic, 0, 0, 'N',
                        nRegSun, nRegHol, nHolSun, nCola, user, sysdate
                      );
            end if;
         else
            insert into pys_payroll_dtl_log 
                   ( payroll_no, empl_empl_id, pay_date, dept_code, vess_code, posi_code, title, sal_freq, 
                     latest_vess, basic_rate, basic_rate_g, amt, amt_g, ot_pay, ht_pay, oport,
                     su_pay, ho_pay, hs_pay, cola_pay, created_by, dt_created
                   ) 
            values ( p_payno, p_empl_id, dChkDate, 'FL', vLatestVessel, vLatestPosition, vLatestTitle, p_sal_freq,
                     vLatestVessel, nLatestBasic, nLatestBasic, nLatestBasic, nLatestBasic, 0, 0, 'N',
                     nRegSun, nRegHol, nHolSun, nCola, user, sysdate
                   );
         end if; -- <if dChkDate < p_date_fr then>
      end if; -- <if vOnBoard = 'Y' then>

      -- check if next pay date crew is still on board
      if (dChkDate+1) between dLatestEmbarked and nvl(dLatestDismbarked, dChkDate+2) then
         null; -- still on duty
      else 
         if (dChkDate+1) > dEnd and dTmpDate is not null then    -- check if still on actual payroll period (10 and 25)
            null; -- assume crew still on duty
         else 
            dLatestEmbarked   := null;
            dLatestDismbarked := null;
            vLatestVessel     := null;
            vLatestPosition   := null;
            vLatestTitle      := null; 
            nLatestBasic      := null;
            nLatestBasicG     := null; 
         end if;
      end if;
      nHolSun := 0;
      nRegHol := 0;
      nRegSun := 0;

   end loop; -- <for j in 1..nEnd loop>


exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance_log employee ' || p_empl_id || ' ' || SQLERRM);
end SP_COUNT_FLT_ATTENDANCE_LOG;
/
show err
