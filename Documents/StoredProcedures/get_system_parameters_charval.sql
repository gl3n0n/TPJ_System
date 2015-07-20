create or replace function get_system_parameters_charval (p_code in varchar2) return varchar2 as
   vName varchar2(128);
begin
   select option_char_value
   into   vName
   from   ap_system_parameters
   where  option_code = p_code;
   return vName;
exception
   when no_data_found then
      raise_application_error (-20001, 'Invalid system paramater code...');
end get_system_parameters_charval;
/
show err


-- tpj_acctg owned
-- create synonym on tpj
create synonym get_system_parameters_charval for tpj_acctg.get_system_parameters_charval;


alter table PYS_PAYROLL_BREAK add bank varchar2(12);
update pys_payroll_break set bank='MBTC';
alter table PYS_PAYROLL_BREAK  modify  bank not null;


