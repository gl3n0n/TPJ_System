create or replace function sf_is_holiday
(
   p_date in  date
) return number is
   nDay Number :=0;
begin

   --get holidays
   select 1
   into   nDay
   from   pys_holidays
   where  tx_date = trunc(p_date);
   --where  to_char(tx_date, 'MMDD') = to_char(p_date, 'MMDD');

   return 1;

exception
   when no_data_found then
      return 0;
end sf_is_holiday;
/
show err

set serveroutput on
begin
   if sf_is_holiday (to_date('20070101', 'YYYYMMDD')) = 1 then
      dbms_output.put_line ( 'check : Holiday' );
   else
      dbms_output.put_line ( 'check : not Holiday' );
   end if;
end;
/

