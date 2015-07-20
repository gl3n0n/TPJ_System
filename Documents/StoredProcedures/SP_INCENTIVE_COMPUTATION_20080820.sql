create or replace procedure sp_incentive_computation
(
   p_tranno  in number,
   p_year    in varchar2,
   p_mon     in varchar2,
   p_date_fr in date,
   p_date_to in date
)
   as

   --get voyage crew
   cursor vocr is
   select vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked, vocr.basic_rate, vocr.passenger
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <= p_date_to
   and    vocr.dt_embarked >= p_date_fr
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id is not null
   order  by vocr.dt_embarked;

   --get vessel total catch
   cursor mcsu_c ( p_catcher in varchar2, p_start in date, p_end in date ) is
   select sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_catcher = p_catcher
   and    tx_date between p_start and p_end;

   --get vessel catch per source
   cursor dcsu_c ( p_catcher in varchar2, p_start in date, p_end in date ) is
   select fiso_code, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_catcher = p_catcher
   and    tx_date between p_start and p_end
   group  by fiso_code;

   --get vessel lighted
   cursor dcsu_l ( p_lighted in varchar2, p_start in date, p_end in date ) is
   select fiso_code, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_lighted = p_lighted
   and    tx_date between p_start and p_end
   group  by  fiso_code;

   --get vessel surveyed
   cursor dcsu_s ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   select fiso_code, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_surveyed = p_surveyed
   and    tx_date between p_start and p_end
   group  by fiso_code;

   --get vessel catch per day
   cursor dcsu_d ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   select tx_date, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_surveyed = p_surveyed
   and    tx_date between p_start and p_end
   group  by tx_date;

   --get vessel delivered per day
   -- cursor drsu_d ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   -- select tx_date, sum(total_catch) total_catch
   -- from   cms_catches_dr_dtls
   -- where  vess_surveyed = p_surveyed
   -- and    tx_date between p_start and p_end
   -- group  by tx_date;

   dStart       Date;
   dEnd         Date;
   nTotalCatch  Number(12,2);
   nDummy       Number;
   n300_600_cnt Number;
   nRate        pys_employee_incentives.rate%type;
   nBasis       pys_employee_incentives.basis%type;
   nAmt         pys_employee_incentives.amt%type;
   vErrMsg      varchar2(2000);

   d_empl_id    Varchar2(16) := 'A00001';
   
begin
   -- CATCHER
   select count(1) into nDummy
   from   cms_daily_catch_summary
   where  tx_date between  p_date_fr and p_date_to;

   if nDummy > 0 then
      delete from cms_daily_catch_summary where  tx_date between  p_date_fr and p_date_to;
   end if;

   begin
      insert into cms_daily_catch_summary
             (
             tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code, total_catch, created_by, dt_created
             )
      select tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code,
             sum(nvl(tot_jmb_catch,0) + nvl(tot_lrg_catch,0) + nvl(tot_reg_catch,0)  + nvl(tot_med_catch,0) + nvl(tot_sml_catch,0)) total_catch, user, sysdate
      from   cms_catches_log
      where  tx_date between p_date_fr and p_date_to
      group  by tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code;
      commit;
   exception
      when others then
         vErrMsg := SQLERRM;
         raise_application_error (-20001, vErrMsg);
   end;

   -- CARRIER
   -- select count(1) into nDummy
   -- from   cms_daily_delivery_summary
   -- where  tx_date between  p_date_fr and p_date_to;

   -- if nDummy > 0 then
   --    delete from cms_daily_catch_summary where  tx_date between  p_date_fr and p_date_to;
   -- end if;

   -- begin
   --    insert into cms_daily_catch_summary
   --           (
   --           tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code, total_catch, created_by, dt_created
   --           )
   --    select tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code,
   --           sum(nvl(tot_jmb_catch,0) + nvl(tot_lrg_catch,0) + nvl(tot_reg_catch,0)  + nvl(tot_med_catch,0) + nvl(tot_sml_catch,0)) total_catch, user, sysdate
   --    from   cms_catches_log
   --    where  tx_date between p_date_fr and p_date_to
   --    group  by tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code;
   --    commit;
   -- exception
   --    when others then
   --       vErrMsg := SQLERRM;
   --       raise_application_error (-20001, vErrMsg);
   -- end;

   for i in vocr loop

      if i.passenger <> 'Y' then

         dStart := greatest(nvl(i.dt_embarked, p_date_fr),p_date_fr);
         dEnd   := least(nvl(i.dt_disembarked, p_date_to),p_date_to);

         -- total catch
         for j in mcsu_c ( i.vessel, dStart, dEnd ) loop
            nTotalCatch := j.total_catch;
         end loop;

         -- catcher per source
         for j in dcsu_c ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_catcher_rate ( j.fiso_code, i.rank_code, nTotalCatch );
            if i.empl_empl_id = d_empl_id then
               dbms_output.put_line ('check carrier rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || to_char(j.total_catch) || ',nTotalCatch:' || to_char(nTotalCatch));
            end if;
            if j.total_catch > 0 and nRate > 0 then
               sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno );
            end if;
         end loop;

         -- lighted
         for j in dcsu_l ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_lighted_rate ( j.fiso_code, i.rank_code, nTotalCatch);
            if i.empl_empl_id = d_empl_id then
               dbms_output.put_line ('check lighted rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || to_char(j.total_catch) || ',nTotalCatch:' || to_char(nTotalCatch));
            end if;
            if j.total_catch > 0 and nRate > 0 then
               sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTED', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, j.total_catch*nRate, p_tranno );
            end if;
         end loop;

         -- surveyed
         for j in dcsu_s ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_surveyed_rate ( j.fiso_code, i.rank_code, nTotalCatch );
            if i.empl_empl_id = d_empl_id then
               dbms_output.put_line ('check surveyed rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || to_char(j.total_catch) || ',nTotalCatch:' || to_char(nTotalCatch));
            end if;
            if j.total_catch > 0 and nRate > 0 then
               sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'SURVEYED', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, j.total_catch*nRate, p_tranno );
            end if;
         end loop;

         -- 300/600
         n300_600_cnt := 0;
         for j in dcsu_d ( i.vessel, dStart, dEnd ) loop
            if sf_is_fullmoon ( j.tx_date ) = 1 then
               if j.total_catch >= 300 then
                  n300_600_cnt := n300_600_cnt + 1;
               end if;
            else
               if j.total_catch >= 600 then
                  n300_600_cnt := n300_600_cnt + 1;
               end if;
            end if;
         end loop;
         nRate := sf_300_600_rate ( i.rank_code, n300_600_cnt );
         if i.empl_empl_id = d_empl_id then
            dbms_output.put_line ('check surveyed rate:' || to_char(nRate) || ',i.rank_code:' ||  i.rank_code || ',n300_600_cnt:' || to_char(n300_600_cnt));
         end if;
         if n300_600_cnt > 0  and nRate > 0 then
            sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, '300_600', i.vessel, i.rank_code, null, n300_600_cnt, nRate, n300_600_cnt*nRate, p_tranno );
         end if;

         -- carrier/delivery
         -- for j in dcsu_c ( i.vessel, dStart, dEnd ) loop
         --    nRate := sf_get_catcher_rate ( j.fiso_code, i.rank_code, j.total_catch );
         --    --dbms_output.put_line ('check carrier rate:' || to_char(nRate) || ',' || j.fiso_code || ',' ||  i.rank_code || ',' || to_char(j.total_catch));
         --    if j.total_catch > 0 and nRate > 0 then
         --       sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno );
         --    end if;
         -- end loop;

      end if;

   end loop;

   commit;

exception
   when others then
      vErrMsg := SQLERRM;
      raise_application_error (-20001, vErrMsg);

end sp_incentive_computation;
/
