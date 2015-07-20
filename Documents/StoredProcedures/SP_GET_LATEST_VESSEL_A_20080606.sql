create or replace function sp_get_latest_vessel_a (
   p_empl_id in varchar2,
   p_period_to in date
   ) return varchar2
as
   dStart Date;
   dEnd   Date;
   vVess  Varchar2(16);
begin
   dStart := to_date(to_char(p_period_to, 'YYYYMM"01"'), 'YYYYMMDD');
   dEnd   := last_day(dStart);
   for i in (select latest_vess from pys_payroll_dtl
             where  period_to between dStart and dEnd
             and    empl_empl_id = p_empl_id
             order  by period_to desc )
   loop
      vVess := i.latest_vess;
      exit;
   end loop;
   return nvl(vVess, ' ');
end sp_get_latest_vessel_a;
/
