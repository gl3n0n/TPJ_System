create or replace procedure sp_get_ofc_ot_rates (
   p_reg out number,
   p_sun out number,
   p_hol out number,
   p_hs  out number,
   p_outer  out number
  ) is

   nOtR         Number(6,3);
   nSundayR     Number(6,3);
   nHolidayR    Number(6,3);
   nHolSunR     Number(6,3);
   nOuterR      Number(6,3);

begin
   begin 
      select rate into nOtR from pys_payroll_types where code = 'OT-OFC';
   exception
      when no_data_found then nOtR:= 0;
   end;

   begin 
      select rate into nSundayR from pys_payroll_types where code = 'OT-SUN-OFC';
   exception
      when no_data_found then nSundayR := 0;
   end;

   begin 
      select rate into nHolidayR from pys_payroll_types where code = 'OT-HOL-OFC';
   exception
      when no_data_found then nHolidayR := 0;
   end;

   begin 
      select rate into nHolSunR from pys_payroll_types where code = 'OT-HS-OFC';
   exception
      when no_data_found then nHolSunR := 0;
   end;

   begin 
      select rate into nOuterR from pys_payroll_types where code = 'REG-OP-OFC';
   exception
      when no_data_found then nOuterR := 0;
   end;

   p_reg := nOtR;
   p_sun := nSundayR;
   p_hol := nHolidayR;
   p_hs  := nHolSunR;
   p_outer := nOuterR; 

end sp_get_ot_rates;
/
show err
