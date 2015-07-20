create or replace function sf_get_fix_tax
   ( p_effdate in  date,
     p_salary  in  number
   )
   return number is
   nFix   Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
   dEffDate Date;
begin
   if p_salary is null then
      nBTax := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_rates
      where  p_salary between salary_fr and salary_to
      and    eff_date <= p_effdate;

      select fix_tax, base_tax, over_pct
      into   nFix, nBTax, nRate
      from   pys_tax_rates
      where  eff_date = dEffDate
      and    p_salary between salary_fr and salary_to;
   end if;
   return nFix;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_fix_tax;
/
