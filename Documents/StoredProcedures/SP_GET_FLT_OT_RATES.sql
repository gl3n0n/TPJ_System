create or replace procedure sp_get_flt_ot_rates (
   p_sun out number,
   p_hol out number,
   p_hs  out number
  ) is

   nSundayR     Number(6,3);
   nHolidayR    Number(6,3);
   nHolSunR     Number(6,3);

begin
   begin 
      select rate into nSundayR from pys_payroll_types where code = 'OT-SUN-FLT';
   exception
      when no_data_found then nSundayR := 0;
   end;

   begin 
      select rate into nHolidayR from pys_payroll_types where code = 'OT-HOL-FLT';
   exception
      when no_data_found then nHolidayR := 0;
   end;

   begin 
      select rate into nHolSunR from pys_payroll_types where code = 'OT-HS-FLT';
   exception
      when no_data_found then nHolSunR := 0;
   end;

   p_sun := nSundayR;
   p_hol := nHolidayR;
   p_hs  := nHolSunR;

end sp_get_flt_ot_rates;
/
show err

