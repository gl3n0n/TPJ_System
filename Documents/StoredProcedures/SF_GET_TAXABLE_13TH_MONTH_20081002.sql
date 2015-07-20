create or replace function sf_get_taxable_13th_month
   ( p_empl_id in  varchar2,
     p_effdate in  date
   )
   return number is
   nSalary  Number(8,2);
   nTaxable Number(8,2);
   nTax13th Number(8,2);
   dEffDate Date;
begin
   if p_empl_id is null then
      nTaxable := 0;
   else
      select max(eff_date) 
      into   dEffDate
      from   pys_tax_header
      where  eff_date <= p_effdate;
      
      nTax13th := 0;
      if dEffDate is not null then
         select non_tax_13th
         into   nTax13th
         from   pys_tax_header
         where eff_date = dEffDate;
      end if;

      if nSalary > nTax13th and nTax13th > 0 then
         select m_13_amt_a 
         into   nSalary 
         from   pys_13th_month_summary
         where  empl_id = p_empl_id
         and    p_effdate between PERIOD_FR and PERIOD_TO;

         nTaxable := nSalary-nTax13th;
      else
         nTaxable := 0;
      end if;

   end if;
   return nTaxable;

exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_taxable_13th_month;
/
