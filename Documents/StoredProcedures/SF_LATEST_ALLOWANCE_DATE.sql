create or replace function sf_latest_allowance_date (
   p_empl_id in varchar2,
   p_date_fr in date
  )  return date is

   dTmpDate Date;

begin

   select min(eff_st_date) into dTmpDate 
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date >= p_date_fr;
   
   if dTmpDate is null then
      select max(eff_st_date) into dTmpDate 
      from   pys_employee_allowances
      where  empl_empl_id = p_empl_id
      and    eff_st_date <= p_date_fr;
   end if;

   return dTmpDate;

exception
   when others then 
      raise_application_error (-20001, 'ERROR - retrieval of latest allowance for employee ' || p_empl_id || ' dated ' || to_char(p_date_fr)); 

end sf_latest_allowance_date;
/
show err
