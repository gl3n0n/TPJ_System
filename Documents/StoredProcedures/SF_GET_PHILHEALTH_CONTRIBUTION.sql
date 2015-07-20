create or replace function sf_get_philhealth_contribution 
   ( p_salary in number
   ) 
   return number is
   nAmt Number;
begin
   select ee_share 
   into   nAmt
   from   pys_philhealth_table
   where  p_salary between salary_fr and salary_to;
   return nAmt;    
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Philhealth contribution table. No range for this salary - ' || to_char(p_salary));
   when too_many_rows then
      raise_application_error (-20001, 'Check your Philhealth contribution table. Too many range for this salary - ' || to_char(p_salary));
end sf_get_philhealth_contribution;
/
