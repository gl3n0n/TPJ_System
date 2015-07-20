create or replace function sp_get_latest_vessel_b (
   p_empl_id in varchar2,
   p_pay_no in number
   ) return varchar2
as
   dStart Date;
   dEnd   Date;
   vVess  Varchar2(16);
begin
   for i in (select latest_vess from pys_payroll_dtl
             where  pahd_payroll_no = p_pay_no
             and    empl_empl_id = p_empl_id
             order  by period_to desc )
   loop
      vVess := i.latest_vess;
      exit;
   end loop;
   return nvl(vVess, ' ');
end sp_get_latest_vessel_b;
/
