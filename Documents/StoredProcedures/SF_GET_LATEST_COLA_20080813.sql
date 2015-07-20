create or replace function SF_GET_LATEST_COLA (
   p_empl_id in  varchar2,
   p_date_fr in  date
  ) return number as
  nAmt  Number(12,2);
  dDate Date;
begin
   -- get latest record
   select sum(amt)
   into   nAmt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date)
                      from pys_employee_salary
                      where empl_empl_id = p_empl_id
                      and eff_st_date <= p_date_fr);

   return nvl(nAmt,0);
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_colafor employee ' || p_empl_id || ' ' || SQLERRM);
end SF_GET_LATEST_COLA;
/
