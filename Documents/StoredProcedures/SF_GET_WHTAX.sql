create or replace function sf_get_whtax
   ( p_empl_id in varchar2,
     p_taxtype in varchar2,
     p_salary  in number
   ) 
   return number is
   nBSal  Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
begin
   if p_taxtype is null then
      raise_application_error (-20001, 'No assigned Tax Type for employee  - ' || p_empl_id);
   end if;
   select salary_fr, base_tax, over_pct
   into   nBSal, nBTax, nRate
   from   pys_withholding_tax
   where  taty_code = p_taxtype 
   and    p_salary between salary_fr and salary_to;
   if nRate > 0 then
      nWTax := nBTax + ((p_salary - nBSal) * (nRate/100));
   else
      nWTax := nBTax;    
   end if;
   return nWTax;
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Withholding tax table. No range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   when too_many_rows then
      raise_application_error (-20001, 'Check your Withholding tax table. Too many range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
end sf_get_whtax;
/
