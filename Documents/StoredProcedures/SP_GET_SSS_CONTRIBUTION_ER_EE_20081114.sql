create or replace procedure sp_get_sss_contribution_er_ee
   ( p_salary  in  number,
     p_effdate in  date,
     p_ee      out number,
     p_er      out number,
     p_ecer    out number,
     p_mocr    out number
   )
   is
   nER Number(8,2);
   nEC Number(8,2);
   nECER Number(8,2);
   nMO_Credit Number(8,2);
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_sss_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching SSS effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select sss_er, sss_ee, ec_er, mo_sal_credit
   into   nER, nEC, nECER, nMO_Credit
   from   pys_sss_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;

   p_ee   := nEC;
   p_er   := nER;
   p_ecer := nECER;
   p_mocr := nMO_Credit;

exception
   when no_data_found then
      if p_salary <= 0 then
         p_ee := 0;
         p_er := 0;
         p_er := 0;
         p_mocr := 0;
      else
         raise_application_error (-20001, 'Check your SSS contribution table. No range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
      end if;
   when too_many_rows then
      select sss_er, sss_ee, tc_er, mo_sal_credit
      into   nER, nEC, nECER, nMO_Credit
      from   pys_sss_table
      where  eff_date = dEffDate
      and    p_salary between salary_fr and salary_to
      and    rownum = 1;
      p_ee   := nEC;
      p_er   := nER;
      p_ecer := nECER;
      p_mocr := nMO_Credit;
      --raise_application_error (-20001, 'Check your SSS contribution table. Too many range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
end sp_get_sss_contribution_er_ee;
/
