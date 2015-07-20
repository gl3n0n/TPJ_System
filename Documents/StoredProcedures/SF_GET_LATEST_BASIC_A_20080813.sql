create or replace function sp_get_latest_basic_a (
   p_empl_id in varchar2,
   p_period_to in date
   ) return number
as
   dStart Date;
   dEnd   Date;
   vVess  Varchar2(16);
   nBasic Number(12,2);
   nCola  Number(12,2);
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

   select max(basic_rate)
   into   nBasic
   from   pys_payroll_a
   where  period_to between dStart and dEnd
   and    empl_empl_id = p_empl_id
   and    basic_rate <> 0 
   and    vess_code = vVess;

   select max(cola_pay)
   into   nCola
   from   pys_payroll_dtl_log
   where  pay_date between dStart and dEnd
   and    empl_empl_id = p_empl_id
   and    vess_code = vVess;

   return nBasic+nCola;
exception
   when others then return null;
end sp_get_latest_basic_a;
/
