create or replace procedure sp_get_basic_rate (
   p_empl_id in varchar2,
   p_date_fr in date,
   p_date_to in date,
   p_basic_r out number,
   p_basic_g out number,
   p_salfreq out varchar
  )  is

   cursor x is
   select eff_st_date, eff_en_date, basic_rate, basic_rate_g, sal_freq
   from   pys_employee_salary
   where  eff_st_date >= p_date_fr
   and     empl_empl_id = p_empl_id
   order  by eff_st_date;

   cursor y is
   select eff_st_date, eff_en_date, basic_rate, basic_rate_g, sal_freq 
   from   pys_employee_salary
   where  empl_empl_id = p_empl_id
   order  by eff_st_date desc;

   nBasicR  Number(8,2);
   nBasicG  Number(8,2);
   vSalFreq	Varchar2(16);
begin

   select basic_rate, basic_rate_g, sal_freq  
   into   nBasicR, nBasicG, vSalFreq
   from   pys_employee_salary
   where  eff_st_date >= p_date_fr
   and    eff_en_date >= p_date_to
   and    empl_empl_id = p_empl_id;

   p_basic_r := nvl(nBasicR,0);
   p_basic_g := nvl(nBasicG,0);
   p_salfreq := nvl(vSalFreq,'SEMI-MO');

exception
   when no_data_found then 
      begin
         nBasicR := 0;
         for i in x loop
            nBasicR  := i.basic_rate;
            nBasicG  := i.basic_rate_g;
            vSalFreq := i.sal_freq;
            if i.eff_en_date <= p_date_to then
               exit;
            end if;
         end loop;
         if nBasicR = 0 then 
            for i in y loop
               nBasicR  := i.basic_rate;
               nBasicG  := i.basic_rate_g;
               vSalFreq := i.sal_freq;
               exit;
            end loop;
         end if;

         p_basic_r := nvl(nBasicR,0);
         p_basic_g := nvl(nBasicG,0);
         p_salfreq := nvl(vSalFreq,'SEMI-MO');
      end;

   when too_many_rows then
      select basic_rate, basic_rate_g, sal_freq 
      into   nBasicR, nBasicG, vSalFreq
      from   pys_employee_salary
      where  eff_st_date >= p_date_fr
      and    eff_en_date >= p_date_to
      and    empl_empl_id = p_empl_id
      and    rownum = 1;
      
      p_basic_r := nvl(nBasicR,0);
      p_basic_g := nvl(nBasicG,0);
      p_salfreq := nvl(vSalFreq,'SEMI-MO');

end sp_get_basic_rate;
/
show err

set serveroutput on
declare
   p_basic_r number;
   p_basic_g number;
   p_salfreq varchar2(16);
begin
   sp_get_basic_rate ('00364', to_date('20070101', 'YYYYMMDD'), to_date('20070115', 'YYYYMMDD'), p_basic_r, p_basic_g, p_salfreq );
   dbms_output.put_line ('check out: ' || p_salfreq || ':' || to_char(p_basic_r) || ':' || to_char(p_basic_g) );
end;
/
