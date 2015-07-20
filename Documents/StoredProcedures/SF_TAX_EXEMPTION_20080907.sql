create or replace function sf_tax_exemption
   ( p_tax_type in varchar2 )
   return number is
   nWTax  Number;
begin
   if p_tax_type = 'S' then
      nWTax := 25000;
   elsif substr(p_tax_type,1,2) = 'ME' then
      if nvl(substr(p_tax_type,3,1),0)<>'0' then
         nWTax := 32000 + (to_number(substr(p_tax_type,3,1))*8000 );
      else
         nWTax := 32000;
      end if;
   elsif substr(p_tax_type,1,2) = 'HF' then
      if nvl(substr(p_tax_type,3,1),0)<>'0' then
         nWTax := 25000 + (to_number(substr(p_tax_type,3,1))*8000 );
      else
         nWTax := 25000;
      end if;
   elsif p_tax_type = 'Z' then
      nWTax := 32000;
   else
      nWTax := 20000;
   end if;
   return nvl(nWTax,0);
exception
   when others then
      return 0;
end sf_tax_exemption;
/
