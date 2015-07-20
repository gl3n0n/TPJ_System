create or replace function sf_tax_exemption
   ( p_effdate  in  date,
     p_tax_type in  varchar2
   )
   return number is
   nTot_Exem Number(10,2);
   dEffDate Date;
begin
   if p_tax_type is null then
      nTot_Exem := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_exemptions
      where  taty_code = p_tax_type
      and    eff_date <= p_effdate;

      select tot_exem
      into   nTot_Exem
      from   pys_tax_exemptions
      where  taty_code = p_tax_type
      and    eff_date = dEffDate;
   end if;
   return nTot_Exem;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_tax_exemption;
/
