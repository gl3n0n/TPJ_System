create or replace function sf_get_ot_rates (
   p_code in varchar2
 ) return number as
   nRate Number(12,4);
begin
   select rate 
   into   nRate
   from   pys_payroll_types 
   where  code=p_code;
   return nRate;
exception
   when no_data_found then
      return 0;
end sf_get_ot_rates;
/
