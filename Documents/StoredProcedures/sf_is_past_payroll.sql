create or replace function sf_is_past_payroll (p_date in date) return number is
   dPeriodTo date;
begin
   if p_date <= to_date('20120825', 'YYYYMMDD') then
      return 1;
   else
      return 0;
   end if;
   begin
      select period_to
      into   dPeriodTo
      from   pys_payroll_hdr
      where  p_date between (period_fr-5) and (period_to-5);
      if (dPeriodTo+1) < trunc(sysdate) then
         return 1;
      end if;
   exception
      when no_data_found then null;
   end;
   return 1;
end sf_is_past_payroll;
/
