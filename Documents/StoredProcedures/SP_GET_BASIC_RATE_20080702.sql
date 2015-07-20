create or replace procedure sp_get_basic_rate (
   p_empl_id in varchar2,
   p_date_fr in date,
   p_date_to in date,
   p_basic_r out number,
   p_basic_g out number,
   p_salfreq out varchar,
   p_ismanager out varchar
  )  is

   cursor x is
   select eff_st_date, eff_en_date, basic_rate, basic_rate_g, sal_freq
   from   pys_employee_salary
   --where  eff_st_date >= p_date_fr
   where eff_st_date <= p_date_fr --modified by thess 1/7/2008
   and     empl_empl_id = p_empl_id
   order  by eff_st_date;

   cursor y is
   select eff_st_date, eff_en_date, basic_rate, basic_rate_g, sal_freq
   from   pys_employee_salary
   where  empl_empl_id = p_empl_id
   and eff_en_date is null -- added by thess 1/7/2008
   order  by eff_st_date desc;

   nBasicR    Number(8,2);
   nBasicG    Number(8,2);
   vSalFreq   Varchar2(16);
   vIsManager Varchar2(1);
begin

   for i in (select eff_st_date, basic_rate, basic_rate_g, sal_freq, is_manager
             from   pys_employee_salary
             where  empl_empl_id = p_empl_id
             order  by eff_st_date desc
             )
   loop
      if p_date_to >= i.eff_st_date then
         nBasicR    := i.basic_rate;
         nBasicG    := i.basic_rate_g;
         vSalFreq   := i.sal_freq;
         vIsManager := i.is_manager;
         exit;
      end if;
   end loop; 
   
   p_basic_r   := nvl(nBasicR,0);
   p_basic_g   := nvl(nBasicG,0);
   p_salfreq   := nvl(vSalFreq,'SEMI-MO');
   p_ismanager := nvl(vIsManager,'N');
end sp_get_basic_rate;
/
