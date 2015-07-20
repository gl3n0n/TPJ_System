create or replace procedure sp_count_flt_attendance
(
   p_empl_id in  varchar2, 
   p_date_fr in  date, 
   p_date_to in  date, 
   p_numday  out number, 
   p_regsun  out number, 
   p_reghol  out number, 
   p_holsun  out number

) is
   nNumHrs  Number := 0;
   nRegHol  Number := 0;
   nHolSun  Number := 0;
   nRegSun  Number := 0;
   nUpTO    Number := 0;
   nDay     Number := 0;
   dDate    Date;
   dStart    Date;
   dEnd      Date;
   nTmpHrs   Number (7,3) := 0;
   nDeduct   Number (7,3) := 0;
   nAssume   Number (7,3) := 0;
begin
   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;


   nUpTo := (p_date_to-dStart)+1; 
   dDate := dStart;
   for i in 1..nUpTo loop
      nDay  := nDay + 1;
      dDate := dDate + (nDay-1);
      if dDate >= p_date_fr then
         nNumHrs := nNumHrs + 8;
      end if; 
      if sf_is_holiday (dDate) = 1 then
         if sf_is_sunday(dDate) = 1 then
            nHolSun := nHolSun + 8;
         else
            nRegHol := nRegHol + 8;
         end if;
      else 
         if sf_is_sunday(dDate) = 1 then
            nRegSun := nRegSun + 8;
         end if;  
      end if;
   end loop;   

   -- ADD from Cutoff date to End of Month
   nUpTo   := (p_date_to-dEnd); 
   nAssume := 0;  
   for i in 1..nUpTo loop
      dDate := dEnd + i;
      if (sf_is_sunday (dDate) = 1) then
         if (sf_is_holiday (dDate) = 1) then
            nHolSun := nHolSun + 8;
         else
            nRegSun := nRegSun + 8;
         end if;
      else
         if (sf_is_holiday (dDate) = 1) then
            nRegHol := nRegHol + 8;
         else
            nNumHrs := nNumHrs + 8;
         end if;
      end if;
   end loop;
   -- end Cutoff date
   -- dbms_output.put_line ('check nAssume: ' || to_char(nAssume) );

   -- LESS from previous Cutoff date to End of previous Month
   nUpTo   := (p_date_fr-dStart); 
   nTmpHrs := 0;  
   nDeduct := 0;  
   for i in 1..nUpTo loop
      dDate := dStart + (i-1);
      if (sf_is_sunday (dDate) = 1) then
         if (sf_is_holiday (dDate) = 1) then
            nHolSun := nHolSun + 8;
         else
            nRegSun := nRegSun + 8;
         end if;
      else
         if (sf_is_holiday (dDate) = 1) then
            nRegHol := nRegHol + 8;
         else
            nNumHrs := nNumHrs + 8;
         end if;
      end if;
   end loop;
   -- end Cutoff date

   p_numday  := nNumHrs/8;
   if to_char(p_date_fr, 'DD') = '01' then
      p_regsun  := 0;
      p_reghol  := 0;
      p_holsun  := 0;
   else
      p_regsun  := nRegSun/8;
      p_reghol  := nRegHol/8;
      p_holsun  := nHolSun/8;
   end if;
end sp_count_flt_attendance;
/
show err

set serveroutput on
declare
   p_numday  number; 
   p_regsun  number; 
   p_reghol  number; 
   p_holsun  number; 
begin
   --sp_count_flt_attendance ('00191', to_date('20070101', 'YYYYMMDD'), to_date('20070115', 'YYYYMMDD'), p_numday, p_regsun, p_reghol, p_holsun );
   --dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) );
   sp_count_flt_attendance ('00191', to_date('20080401', 'YYYYMMDD'), to_date('20080415', 'YYYYMMDD'), p_numday, p_regsun, p_reghol, p_holsun );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) );
   sp_count_flt_attendance ('00191', to_date('20080416', 'YYYYMMDD'), to_date('20080430', 'YYYYMMDD'), p_numday, p_regsun, p_reghol, p_holsun );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) );
end;
/
