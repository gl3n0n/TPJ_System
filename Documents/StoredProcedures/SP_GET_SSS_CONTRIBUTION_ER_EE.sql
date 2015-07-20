create or replace procedure sp_get_sss_contribution_er_ee
   ( p_salary in  number,
     p_ee     out number,
     p_er     out number,
     p_ecer   out number
   ) 
   is
   nER Number(8,2);
   nEC Number(8,2);
   nECER Number(8,2);
begin

   select sss_er, sss_ee, ec_er 
   into   nER, nEC, nECER
   from   pys_sss_table
   where  p_salary between salary_fr and salary_to;

   p_ee   := nEC;   
   p_er   := nER;   
   p_ecer := nECER;   

exception
   when no_data_found then
      if p_salary <= 1000 then
         p_ee := 0;
         p_er := 0;
         p_er := 0;
      else 
         raise_application_error (-20001, 'Check your SSS contribution table. No range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
      end if;
   when too_many_rows then
      select sss_er, sss_ee, tc_er 
      into   nER, nEC, nECER
      from   pys_sss_table
      where  p_salary between salary_fr and salary_to
      and rownum = 1;
      p_ee   := nEC;   
      p_er   := nER;   
      p_ecer := nECER;   
      --raise_application_error (-20001, 'Check your SSS contribution table. Too many range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
end sp_get_sss_contribution_er_ee;
/
