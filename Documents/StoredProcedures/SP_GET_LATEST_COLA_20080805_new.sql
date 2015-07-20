create or replace procedure SP_GET_LATEST_COLA (
   p_empl_id in  varchar2,
   p_date_fr in  date,
   p_amt     out number,
   p_eff     out date 
  ) as
  nAmt  Number(12,2);
  dDate Date;
begin
   -- get latest record
   select amt, eff_st_date
   into   nAmt, dDate
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date) 
                      from pys_employee_salary
                      where empl_empl_id = p_empl_id
                      and eff_st_date <= p_date_fr);

   p_amt := nAmt;
   p_eff := dDate;
exception
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_colafor employee ' || p_empl_id || ' ' || SQLERRM);
end SP_GET_LATEST_COLA;
/
show err
