create or replace function sf_get_surveyed_rate
(
   --p_fiso  in varchar2,
   --p_rank  in varchar2,
   p_catch in number
)  return number is
   nRate   pys_incentives.rate%type;
begin
   select rate
   into   nRate
   from   pys_incentives
   where  inty_code = 'SURVEYED'
   and    p_catch between range_fr and range_to
   and    rownum = 1;
   return nRate;
exception
   when no_data_found then
      return 0;
end sf_get_surveyed_rate;
/
