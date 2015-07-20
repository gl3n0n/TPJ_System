create or replace procedure sp_payroll_computation
(
   p_payno   in number,
   p_year    in varchar2,
   p_mon     in varchar2,
   p_date_fr in date, 
   p_date_to in date
)  
   as

   --get attendance record
   cursor attr (p_period_fr in date, p_period_to in date ) is
   select a.empl_empl_id, b.basic_rate, b.taty_code, b.posi_code posi_code, null title,
          min(a.att_date) start_date, max(a.att_date) end_date, 
          count(a.att_date) num_days, sum(a.num_hours) num_hours, sum(nvl(a.ot_hours,0)) ot_hours, 
          'OFC' empl_type, null voya_vess_code, null voya_voyage_date, null crew_no, b.dept_code dept_code
   from   pms_attendance_records a, pms_employees b
   where  a.empl_empl_id = b.empl_id
   AND    a.att_date between p_period_fr and p_period_to
   group  by a.empl_empl_id, b.basic_rate, b.taty_code, b.posi_code, b.dept_code
   union
   select vocr.empl_empl_id empl_empl_id, vocr.basic_rate, empl.taty_code, empl.posi_code posi_code, vocr.title,
          least(nvl(vocr.dt_disembarked,p_date_to), p_date_to) start_date, greatest(nvl(vocr.dt_embarked,p_date_fr),p_date_fr) end_date,
          (least(nvl(vocr.dt_disembarked,p_date_to), p_date_to)-greatest(nvl(vocr.dt_embarked,p_date_fr),p_date_fr))+1 num_days, 
          ((least(nvl(vocr.dt_disembarked,p_date_to), p_date_to)-greatest(nvl(vocr.dt_embarked,p_date_fr),p_date_fr))+1) * 8 num_hours, 
          0 ot_hours, 'FLT' empl_type, vocr.voya_vess_code voya_vess_code, vocr.voya_voyage_date, seq_no creq_no, null dept_code
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date between p_period_fr and p_period_to
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id;

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = p_effectivity
   group  by empl_empl_id, allo_code;

   --get allowances (FLT)
   cursor allo_flt ( p_empl_id in varchar2,  p_vessel in varchar2,  p_voya_date in varchar2 ) is
   select allo_code, amount amt
   from   cms_crew_allowances
   where  empl_empl_id = p_empl_id
   and    voya_vess_code = p_vessel
   and    voya_voyage_date = p_voya_date;

   --get voyage crew
   cursor vocr is
   select empl_empl_id, dt_embarked, dt_disembarked
   from   cms_voyage_crew
   where  dt_embarked < p_date_fr 
   and    dt_disembarked <= p_date_to
   union
   select empl_empl_id, dt_embarked, dt_disembarked
   from   cms_voyage_crew
   where  dt_embarked between p_date_fr and p_date_to;

   --get employee incentive
   cursor emin (p_empl_id in varchar2) is
   select empl_empl_id, inty_code, fiso_code, vess_code, basis, rate, year, mo, amt
   from   pys_employee_incentives
   where  empl_empl_id = p_empl_id
   and    year = to_char(p_date_to, 'YYYY')
   and    mo = to_char(p_date_to, 'MM');

   --get employee deductions
   cursor dedu (p_empl_id in varchar2) is
   select empl_empl_id, dety_code, seq_no, amt
   from   pys_deductions
   where  empl_empl_id = p_empl_id
   and    start_date <= p_date_to 
   and    no_payday > 0;

   nSeqNo       Number;
   nBasic       Number(8,2);
   nBasicR      Number(8,2);
   nSalary      Number(8,2);
   nSSS         Number(8,2);
   nSSS_ER      Number(8,2);
   nSSS_EC      Number(8,2);
   nPagibig     Number(8,2);
   nPagibig_ER  Number(8,2);
   nPhHealth    Number(8,2);
   nPhHealth_ER Number(8,2);
   nTaxable     Number(8,2);
   nWhTax       Number(8,2);
   bNoDeduction Boolean;
   dPrevStart   Date;
   nPrevSal     Number(8,2);
   nPrevAllo    Number(8,2);
   nOvertm      Number;
   nSunday      Number;
   nHoliday     Number;
   nHolSun      Number;
   nCOLA        Number;
   nAllowances  Number;
   nOvertmR     Number(6,3);
   nSundayR     Number(6,3);
   nHolidayR    Number(6,3);
   nHolSunR     Number(6,3);
   nOtPay       Number(8,2);
   nSuPay       Number(8,2);
   nHoPay       Number(8,2);
   nHsPay       Number(8,2);
   bWithAllowance Boolean;
   dTmpDate     Date;
begin
   -- check pay period
   if p_date_to <= to_date(to_char(p_date_to, 'YYYYMM') || '15', 'YYYYMMDD') then
      bNoDeduction := TRUE;
   else
      bNoDeduction := FALSE;
   end if;

   -- get Max SeqNo
   select nvl(max(seq_no),0)
   into   nSeqNo
   from   pys_payroll_dtl
   where  pahd_payroll_no = p_payno;

   if bNoDeduction then

      for i in attr ( p_date_fr, p_date_to ) loop

         if i.taty_code is not null then
      
            -- get basic rate
            if i.empl_type = 'OFC' then
               nBasicR := sf_get_basic_rate (i.empl_empl_id, p_date_fr, p_date_to );
            else 
               if i.basic_rate = 0 then
                  nBasicR := sf_get_basic_rate (i.empl_empl_id, p_date_fr, p_date_to );
               else 
                  nBasicR := i.basic_rate;
               end if;
            end if;

            -- compute attendance 
            begin
               nSeqNo  := nSeqNo + 1;
               nBasic  := nBasicR * i.num_days;
               nSalary := nBasic;
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, i.title, 'REG', nBasic, i.num_days, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
            end;
      
            -- get allowances (OFC)
            if i.empl_type = 'OFC' then
               bWithAllowance := TRUE;
               begin
                  select min(eff_st_date) into dTmpDate 
                  from   pys_employee_allowances
                  where  empl_empl_id = i.empl_empl_id
                  and    eff_st_date >= p_date_fr;
               exception 
                  when no_data_found then
                     begin
                        select max(eff_st_date) into dTmpDate 
                        from   pys_employee_allowances
                        where  empl_empl_id = i.empl_empl_id
                        and    eff_st_date <= p_date_fr;
                     exception 
                        when no_data_found then 
                           bWithAllowance := FALSE;
                     end;
               end;
               if bWithAllowance then
                  for x in allo (i.empl_empl_id, dTmpDate) loop 
                     nSeqNo := nSeqNo + 1;
                     insert into pys_payroll_dtl 
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                     values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*i.num_days), i.num_days, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
                  end loop;
               end if;
            else
               for x in allo_flt ( i.empl_empl_id, i.voya_vess_code,  i.voya_voyage_date  ) loop 
                  nSeqNo := nSeqNo + 1;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*i.num_days), i.num_days, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end loop;
            end if;
            
         end if;
      end loop;

   else         

      -- get Max Previous Start
      select max(period_fr)
      into   dPrevStart
      from   pys_payroll_dtl;

      -- get OT Rate
      sp_get_ot_rates (nOvertmR, nSundayR, nHolidayR, nHolSunR);
      
      for i in attr ( dPrevStart, p_date_to ) loop
      
         if i.taty_code is not null then
      
            -- get basic rate
            if i.empl_type = 'OFC' then
               nBasicR := sf_get_basic_rate (i.empl_empl_id, p_date_fr, p_date_to );
            else 
               if i.basic_rate = 0 then
                  nBasicR := sf_get_basic_rate (i.empl_empl_id, p_date_fr, p_date_to );
               else 
                  nBasicR := i.basic_rate;
               end if;
            end if;

            -- get previous salary and Allowances
            begin
               select amt
               into   nPrevSal 
               from   pys_payroll_dtl
               where  empl_empl_id = i.empl_empl_id
               and    period_fr    = dPrevStart
               and    paty_code = 'REG';
            exception 
               when no_data_found then 
                  nPrevSal := 0;
               when too_many_rows then 
                  select amt
                  into   nPrevSal 
                  from   pys_payroll_dtl
                  where  empl_empl_id = i.empl_empl_id
                  and    period_fr    = dPrevStart
                  and    paty_code = 'REG'
                  and    rownum = 1;
            end;

            -- get previous salary and Allowances
            begin
               select sum(amt)
               into   nPrevAllo 
               from   pys_payroll_dtl
               where  empl_empl_id = i.empl_empl_id
               and    period_fr    = dPrevStart
               and    paty_code <> 'REG';
            exception 
               when no_data_found then 
                  nPrevAllo := 0;
            end;

            -- compute attendance 
            begin
               nSeqNo    := nSeqNo + 1;
               nBasic    := nBasicR * i.num_days;

               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, i.title, 'REG', nBasic, i.num_days, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
            
               sp_count_holidays (i.empl_type, i.empl_empl_id, dPrevStart, p_date_to, nOvertm, nSunday, nHoliday, nHolSun, nCOLA );

               if nOvertm > 0 then
                  nSeqNo := nSeqNo + 1;
                  nOtPay := ((nBasicR/8)*nOvertmR) * i.ot_hours;
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'OT', nOtPay, i.ot_hours, ((nBasicR/8)*nOvertmR), i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

               if nSunday > 0 then
                  nSeqNo := nSeqNo + 1;
                  nSuPay := (nBasicR*nSundayR) * (nSunday);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'OT-SUN', nSuPay, (nSunday), (nBasicR*nSundayR), i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;
            
               if nHoliday > 0 then
                  nSeqNo := nSeqNo + 1;
                  nHoPay := (nBasicR*nHolidayR) * (nHoliday);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'OT-HOL', nHoPay, (nHoliday), (nBasicR*nHolidayR), i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

               if nHolSun > 0 then
                  nSeqNo := nSeqNo + 1;
                  nHsPay := (nBasicR*nHolSunR) * (nHolSun);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'OT-HS', nHsPay, (nHolSun), (nBasicR*nHolSunR), i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end if;

            end;
            
            -- get allowances (OFC)
            if i.empl_type = 'OFC' then
               bWithAllowance := TRUE;
               begin
                  select min(eff_st_date) into dTmpDate 
                  from   pys_employee_allowances
                  where  empl_empl_id = i.empl_empl_id
                  and    eff_st_date >= p_date_fr;
               exception 
                  when no_data_found then
                     begin
                        select max(eff_st_date) into dTmpDate 
                        from   pys_employee_allowances
                        where  empl_empl_id = i.empl_empl_id
                        and    eff_st_date <= p_date_fr;
                     exception 
                        when no_data_found then 
                           bWithAllowance := FALSE;
                     end;
               end;
               if bWithAllowance then
                  nAllowances := 0;
                  for x in allo (i.empl_empl_id, dTmpDate) loop 
                     nSeqNo := nSeqNo + 1;
                     nAllowances := nAllowances + (x.amt*(i.num_days+nvl(nCOLA,0)));
                     insert into pys_payroll_dtl 
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                     values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*(i.num_days+nvl(nCOLA,0))), i.num_days, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
                  end loop;
               end if;
            else
               nAllowances := 0;
               for x in allo_flt ( i.empl_empl_id, i.voya_vess_code,  i.voya_voyage_date ) loop 
                  nSeqNo := nSeqNo + 1;
                  nAllowances := nAllowances + (x.amt*i.num_days);
                  insert into pys_payroll_dtl 
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
                  values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, x.allo_code, (x.amt*i.num_days), i.num_days, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'ADD' );
               end loop;
            end if;
            
            begin
               nSalary   := (nBasic + nvl(nOtPay,0) + nvl(nSuPay,0) + nvl(nHoPay,0) + nvl(nHsPay,0)) + nvl(nPrevSal,0) + nvl(nPrevAllo,0) + nAllowances;
            end;

            -- compute SSS
            begin
            
               nSeqNo := nSeqNo + 1;
               sp_get_sss_contribution_er_ee (nSalary, nSSS, nSSS_ER, nSSS_EC);
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'SSS', nSSS, user, sysdate, 'LESS' );
            
               -- populate sss ER and EE contribution
               insert into pys_sss_contribution 
                      ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, created_by, dt_created )
               values ( dPrevStart, p_date_to, i.empl_empl_id, nSSS, nSSS_ER, nvl(nSSS_EC,0), user, sysdate );
            
            end;
            
            -- compute Pag-ibig
            begin
            
               nSeqNo := nSeqNo + 1;
               -- nPagibig := sf_get_pagibig_contribution(nBasic);
               sp_get_pagibig_ee_er (nSalary, nPagibig, nPagibig_ER);
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'PAGIBIG', nPagibig, user, sysdate, 'LESS' );
            
               -- populate pag-ibig ER and EE contribution
               insert into pys_pagibig_contribution 
                      ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
               values ( dPrevStart, p_date_to, i.empl_empl_id, nPagibig, nPagibig_ER, user, sysdate );
            
            end;
            
            -- compute Philhealth
            begin
            
               nSeqNo := nSeqNo + 1;
               --nPhHealth := sf_get_philhealth_contribution(nBasic);
               sp_get_philhealth_ee_er (nSalary, nPhHealth, nPhHealth_ER);
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'PHILHEALTH', nPhHealth, user, sysdate, 'LESS' );
            
               -- populate pag-ibig ER and EE contribution
               insert into pys_philhealth_contribution 
                      ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
               values ( dPrevStart, p_date_to, i.empl_empl_id, nPhHealth, nPhHealth_ER, user, sysdate );
            
            end;

            -- compute WH TAX
            begin
               nSeqNo   := nSeqNo + 1;
               nTaxable := nvl(nSalary,0) - (nSSS + nPagibig + nPhHealth);
               nWhTax   := sf_get_whtax(i.empl_empl_id, i.taty_code, nTaxable);
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, 'WHTAX', nWhTax, nBasicR, i.voya_vess_code, i.dept_code, user, sysdate, 'LESS' );
            end;

            -- get loans/deductions
            for z in dedu (i.empl_empl_id) loop 
               nSeqNo := nSeqNo + 1;
               insert into pys_payroll_dtl 
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, created_by, dt_created, pay_flag )
               values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, user, sysdate, 'LESS' );
            end loop;

         end if;
      end loop;

   end if;

end sp_payroll_computation;
/
show err
