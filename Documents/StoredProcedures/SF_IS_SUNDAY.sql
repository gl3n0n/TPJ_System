create or replace function sf_is_sunday
(
   p_date in  date
) return number is
begin

   if to_char(p_date, 'fmDAY') = 'SUNDAY' then
      return 1;
   else
      return 0;
   end if;
end sf_is_sunday;
/
show err

set serveroutput on
begin
   if sf_is_sunday (to_date('20070101', 'YYYYMMDD')) = 1 then
      dbms_output.put_line ( 'check : Sunday' );
   else
      dbms_output.put_line ( 'check : not Sunday' );
   end if;
end;
/

