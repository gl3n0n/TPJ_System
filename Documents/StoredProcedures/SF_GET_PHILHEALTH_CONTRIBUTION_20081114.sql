create or replace function sf_get_philhealth_contribution
   ( p_salary in number,
     p_effdate in date
   )
   return number is
   nAmt Number;
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_philhealth_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching Philhealth effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select ee_share
   into   nAmt
   from   pys_philhealth_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;
   return nAmt;
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Philhealth contribution table. No range for this salary - ' || to_char(p_salary));
   when too_many_rows then
      raise_application_error (-20001, 'Check your Philhealth contribution table. Too many range for this salary - ' || to_char(p_salary));
end sf_get_philhealth_contribution;
/
