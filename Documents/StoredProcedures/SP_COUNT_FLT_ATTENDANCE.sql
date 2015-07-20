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
   dStart   Date;
begin
   if to_char(p_date_fr, 'DD') = '16' then
      dStart := to_date ('01' || to_char(p_date_fr, 'MMYYYY'), 'DDMMYYYY');
   else
      dStart := p_date_fr;
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
            nHolSun := nRegSun + 8;
         else
            nRegHol := nRegHol + 8;
         end if;
      else 
         if sf_is_sunday(dDate) = 1 then
            nRegSun := nRegSun + 8;
         end if;  
      end if;
   end loop;   
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
   --sp_count_flt_attendance ('0001', to_date('20070101', 'YYYYMMDD'), to_date('20070115', 'YYYYMMDD'), p_numday, p_regsun, p_reghol, p_holsun );
   --dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) );
   --sp_count_flt_attendance ('0001', to_date('20070101', 'YYYYMMDD'), to_date('20070131', 'YYYYMMDD'), p_numday, p_regsun, p_reghol, p_holsun );
   --dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) );
   sp_count_flt_attendance ('0001', to_date('20070116', 'YYYYMMDD'), to_date('20070131', 'YYYYMMDD'), p_numday, p_regsun, p_reghol, p_holsun );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) );
end;
/
