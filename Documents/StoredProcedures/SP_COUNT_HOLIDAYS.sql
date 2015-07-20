create or replace procedure sp_count_holidays 
(
   p_type    in  varchar2, 
   p_empl_id in  varchar2, 
   p_date_fr in  date, 
   p_date_to in  date, 
   p_overtm  out number, 
   p_regsun  out number, 
   p_reghol  out number, 
   p_holsun  out number, 
   p_cola    out number

) is

   --get holidays
   cursor x ( p_date in date ) is 
   select tx_date 
   from   pys_holidays
   where  tx_date = p_date;

   --get attendance
   cursor atre (p_empl_id in varchar2, p_period_fr in date, p_period_to in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date between p_period_fr and p_period_to
   order  by att_date;


   nOvertm  Number := 0;
   nRegHol  Number := 0;
   nHolSun  Number := 0;
   nRegSun  Number := 0;
   nCOLA    Number := 0;
   nUpTO    Number := 0;
   bHolSun  Boolean;
   nDay     Number :=0;
begin

   if p_type = 'FLT' then

      nUpTo := (p_date_to-p_date_fr); 
      
      for i in 1..nUpTo loop
         nDay := nDay + 1;
         bHolSun := FALSE;
         for i in x ( p_date_fr+(nDay-1) ) loop
            if to_char(i.tx_date, 'fmDAY') = 'SUNDAY' then
               nHolSun := nRegSun + 1;
            else
               nRegHol := nRegHol + 1;
            end if;
            bHolSun := TRUE;
         end loop;
         if not bHolSun then
            if to_char(p_date_fr + (nDay-1), 'fmDAY') = 'SUNDAY' then
               nRegSun := nRegSun + 1;
            end if;  
         end if;  
      end loop;
      
   else

      for j in atre ( p_empl_id, p_date_fr, p_date_to ) loop

         bHolSun := FALSE;
         for i in x ( j.tx_date ) loop
            if to_char(i.tx_date, 'fmDAY') = 'SUNDAY' then
               nHolSun := nRegSun + j.num_hours;
               if j.num_hours >= 8  then
                  nCOLA := nCOLA + 1;
               end if;
            else
               nRegHol := nRegHol + j.num_hours;
            end if;
            bHolSun := TRUE;
         end loop;

         -- if not holiday but fall on Sunday
         if not bHolSun then 
            if to_char(j.tx_date, 'fmDAY') = 'SUNDAY' then            
               nRegSun := nRegSun + j.num_hours;
               if j.num_hours >= 8  then
                  nCOLA := nCOLA + 1;
               end if;
               bHolSun := TRUE;
            end if;
         end if;

         -- if not holiday and not Sunday, regular OT
         if not bHolSun then
             nOvertm := nOvertm + j.num_hours;
         end if;

      end loop;

   end if;

   p_overtm  := nOvertm;
   p_regsun  := nRegSun;
   p_reghol  := nRegHol;
   p_holsun  := nHolSun;
   p_cola    := nCOLA;

end sp_count_holidays;
/
show err

set serveroutput on
declare
   p_overtm  number; 
   p_regsun  number; 
   p_reghol  number; 
   p_holsun  number; 
   p_cola    number;
begin
   sp_count_holidays ('FLT', '0001', to_date('20070101', 'YYYYMMDD'), to_date('20070131', 'YYYYMMDD'), p_overtm, p_regsun, p_reghol, p_holsun, p_cola );
   dbms_output.put_line ('check out: ' || to_char(p_overtm) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) || ':' || to_char(p_cola)  );
end;
/

