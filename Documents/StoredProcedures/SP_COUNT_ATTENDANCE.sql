create or replace procedure sp_count_attendance
(
   p_type    in  varchar2, 
   p_empl_id in  varchar2, 
   p_date_fr in  date, 
   p_date_to in  date, 
   p_numday  out number, 
   p_overtm  out number, 
   p_regsun  out number, 
   p_reghol  out number, 
   p_holsun  out number, 
   p_cola    out number

) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_period_fr in date, p_period_to in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date between p_period_fr and p_period_to
   order  by att_date;


   nNumHrs  Number := 0;
   nOvertm  Number := 0;
   nRegHol  Number := 0;
   nHolSun  Number := 0;
   nRegSun  Number := 0;
   nCOLA    Number := 0;
   nUpTO    Number := 0;
   bHolSun  Boolean;
   nDay     Number :=0;
   dDate    Date := p_date_fr;
   dTxDate  Date;
   dStart   Date;
   dEnd     Date;
   nTmpHrs  Number := 0;
   nDeduct  Number := 0;
   nAssume  Number := 0;
begin

   if p_type = 'FLT' then

      nUpTo := (p_date_to-p_date_fr)+1; 
      
      dDate := p_date_fr;
      for i in 1..nUpTo loop
         nDay    := nDay + 1;
         dDate := dDate + (nDay-1);
         nNumHrs := nNumHrs + 8;
         nCOLA := nCOLA + 1;
         if sf_is_holiday (dDate) = 1 then
            if sf_is_sunday(dDate) = 1 then
               nHolSun := nRegSun + 8;
            else
               nRegHol := nRegHol + 8;
            end if;
         else 
            if sf_is_sunday(dDate) = 1 then
               nRegSun := nRegSun + 8;
            --else 
            --   nNumHrs := nNumHrs + 8;
            end if;  
         end if;
      end loop;
      
   else

      -- set up cutoff date
      if to_char(p_date_fr, 'DD') = '01' then
         dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      else
         dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '11', 'YYYYMMDD');
      end if;

      if to_char(p_date_to, 'DD') = '15' then
         dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      else
         dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      end if;

      for j in atre ( p_empl_id, dStart, dEnd ) loop

         nDay  := nDay + 1;
         dDate := j.tx_date;
         if sf_is_holiday (dDate) = 1 then

            if sf_is_sunday (dDate) = 1 then
               nHolSun := nRegSun + j.num_hours + j.ot_hours;
               if j.num_hours >= 6  then
                  nCOLA := nCOLA + 1;
               end if;
            else
               nRegHol := nRegHol + j.num_hours + j.ot_hours;
               if j.num_hours >= 4  then
                  nCOLA := nCOLA + 1;
               end if;
            end if;

         else

            if sf_is_sunday (dDate) = 1 then
               nRegSun := nRegSun + j.num_hours + j.ot_hours;
               if j.num_hours >= 4  then
                  nCOLA := nCOLA + 1;
               end if;
            else
               if to_char(dDate, 'fmMonth') = to_char(p_date_to, 'fmMonth') then
                  nNumHrs  := nNumHrs + j.num_hours;
                  nCOLA := nCOLA + 1;
               end if;  
               -- Overtime
               nOvertm := nOvertm + j.ot_hours;
            end if;  

         end if;

      end loop;

      -- ADD from Cutoff date to End of Month
      nUpTo   := (p_date_to-dEnd); 
      nAssume := 0;  
      for i in 1..nUpTo loop
         dDate := dEnd + i;
         if sf_is_sunday (dDate) = 0 then
            nAssume := nAssume + 8;
            nCOLA := nCOLA + 1;
         end if;
         dbms_output.put_line ('check date: ' || to_char(dDate) || ', ' || to_char(nAssume));
      end loop;
      -- end Cutoff date

      -- LESS from previous Cutoff date to End of previous Month
      nUpTo   := (p_date_fr-dStart); 
      nTmpHrs := 0;  
      nDeduct := 0;  
      for i in 1..nUpTo loop
         dDate := dStart + (i-1);
         -- check if not SUNDAY
         if (sf_is_sunday (dDate) = 0) and (sf_is_holiday (dDate) = 0) then
            begin
               select num_hours
               into   nTmpHrs 
               from   pms_attendance_records
               where  empl_empl_id = p_empl_id
               and    att_date = dDate;
            exception
               when no_data_found then 
                  nTmpHrs := 0;
                  nCOLA := nCOLA - 1;
            end;
            if nTmpHrs < 8 then
               nDeduct := nDeduct + (8-nTmpHrs);
            end if;
         end if;
      end loop;
      -- end Cutoff date

   end if; -- end of OFC/FLT

   p_numday  := ((nNumHrs+nAssume)-nDeduct)/8;
   p_cola    := nCOLA;
   if p_type = 'FLT' then
      p_overtm  := nOvertm/8;
      p_regsun  := nRegSun/8;
      p_reghol  := nRegHol/8;
      p_holsun  := nHolSun/8;
   else
      p_overtm  := nOvertm;
      p_regsun  := nRegSun;
      p_reghol  := nRegHol;
      p_holsun  := nHolSun;
   end if;

end sp_count_attendance;
/
show err

set serveroutput on
declare
   p_numday  number; 
   p_overtm  number; 
   p_regsun  number; 
   p_reghol  number; 
   p_holsun  number; 
   p_cola    number;
begin
   sp_count_attendance ('FLT', '0001', to_date('20070101', 'YYYYMMDD'), to_date('20070115', 'YYYYMMDD'), p_numday, p_overtm, p_regsun, p_reghol, p_holsun, p_cola );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_overtm) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) || ':' || to_char(p_cola)  );
end;
/

   select att_date tx_date, num_hours, ot_hours, 
          sf_is_holiday (att_date) holiday,
          sf_is_sunday (att_date) sunday
   from   pms_attendance_records
   where  empl_empl_id = '00364'
   and    att_date between to_date('20061226', 'YYYYMMDD') and to_date('20070110', 'YYYYMMDD')
   order  by att_date;

   select sum(num_hours), sum(num_hours)/8, sum(ot_hours)
   from   pms_attendance_records
   where  empl_empl_id = '00364'
   and    sf_is_holiday (att_date) = 0
   and    sf_is_sunday (att_date) = 0
   and    att_date between to_date('20061226', 'YYYYMMDD') and to_date('20070110', 'YYYYMMDD');

declare
   p_numday  number; 
   p_overtm  number; 
   p_regsun  number; 
   p_reghol  number; 
   p_holsun  number; 
   p_cola    number;
begin
   sp_count_attendance ('OFC', '00364', to_date('20070101', 'YYYYMMDD'), to_date('20070115', 'YYYYMMDD'), p_numday, p_overtm, p_regsun, p_reghol, p_holsun, p_cola );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_overtm) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) || ':' || to_char(p_cola)  );
   sp_count_attendance ('OFC', '00364', to_date('20070101', 'YYYYMMDD'), to_date('20070131', 'YYYYMMDD'), p_numday, p_overtm, p_regsun, p_reghol, p_holsun, p_cola );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_overtm) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) || ':' || to_char(p_cola)  );
end;
/

