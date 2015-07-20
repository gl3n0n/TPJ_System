create or replace function sf_is_fullmoon
(
   p_date in date
)  return number is

   nDummy Number;

begin

   select 1 into nDummy
   from   pys_fullmoon
   where  tx_date between (p_date-1) and (p_date+1);

   return 1;

exception
   when no_data_found then
      return 0;

end sf_is_fullmoon;
/
