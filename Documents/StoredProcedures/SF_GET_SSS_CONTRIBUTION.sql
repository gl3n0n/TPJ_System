create or replace function sf_get_sss_contribution 
   ( p_salary in number
   ) 
   return number is
   nAmt Number;
begin
   select sss_ee 
   into   nAmt
   from   pys_sss_table
   where  p_salary between salary_fr and salary_to;
   return nAmt;    
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your SSS contribution table. No range for this salary - ' || to_char(p_salary));
   when too_many_rows then
      raise_application_error (-20001, 'Check your SSS contribution table. Too many range for this salary - ' || to_char(p_salary));
end sf_get_sss_contribution;
/
