create or replace function sf_get_tax_base
   ( p_empl_id in  varchar2,
     p_taxtype in  varchar2,
     p_salary  in  number
   )
   return number is
   nBSal  Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
begin
   if p_taxtype is null then
      nBTax := 0;
   else
      select salary_fr, base_tax, over_pct
      into   nBSal, nBTax, nRate
      from   pys_withholding_tax
      where  taty_code = p_taxtype
      and    p_salary between salary_fr and salary_to;
   end if;
   return nvl(nBTax,0)*12;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_tax_base;
/
