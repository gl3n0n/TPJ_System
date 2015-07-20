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
          vocr.dt_embarked, nvl(dt_disembarked,p_date_to) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <= p_date_to
   and    vocr.dt_embarked <= p_date_to
   and    vocr.dt_disembarked is null
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id is not null
   union
   select vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <= p_date_to
   and    vocr.dt_embarked <= p_date_to
   and    vocr.dt_disembarked is not null
   and    vocr.dt_disembarked >= p_date_fr
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id is not null
   order  by dt_embarked;

   cursor vocr_e (p_empl_id in varchar2) is
   select vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, nvl(dt_disembarked,p_date_to) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <= p_date_to
   and    vocr.dt_embarked <= p_date_to
   and    vocr.dt_disembarked is null
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = p_empl_id
   union
   select vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   from   cms_voyage_crew vocr, cms_vessels vess
   where  vocr.voya_voyage_date <= p_date_to
   and    vocr.dt_embarked <= p_date_to
   and    vocr.dt_disembarked is not null
   and    vocr.dt_disembarked >= p_date_fr
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = p_empl_id
   order  by dt_embarked;

   --get vessel total catch
   cursor mcsu_c ( p_catcher in varchar2, p_start in date, p_end in date ) is
   select sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_catcher = p_catcher
   and    tx_date between p_start and p_end
   and    time_setted < p_end;

   --get vessel catch per source
   cursor dcsu_c ( p_catcher in varchar2, p_start in date, p_end in date ) is
   select fiso_code, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_catcher = p_catcher
   and    tx_date between p_start and p_end
   and    time_setted < p_end
   group  by fiso_code;

   --get vessel lightboat
   cursor dcsu_l ( p_lighted in varchar2, p_start in date, p_end in date ) is
   select vess_lighted, vess_surveyed, fiso_code, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_lighted = p_lighted
   and    tx_date between p_start and p_end
   and    time_setted < p_end
   group  by  vess_lighted, vess_surveyed, fiso_code
   union
   select vess_lighted, vess_surveyed, fiso_code, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_surveyed = p_lighted
   and    tx_date between p_start and p_end
   and    time_setted < p_end
   group  by vess_lighted, vess_surveyed, fiso_code;

   --get vessel surveyed
   cursor dcsu_s ( p_surveyed_by in varchar2, p_start in date, p_end in date ) is
   select tx_date, surveyed_by, vess_catcher, surveyed_by_vess, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  surveyed_by = p_surveyed_by
   and    tx_date between p_start and p_end
   and    time_setted < p_end
   group  by  tx_date, surveyed_by, vess_catcher, surveyed_by_vess;

   --get vessel catch per day
   cursor dcsu_d ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   select tx_date, sum(total_catch) total_catch
   from   cms_daily_catch_summary
   where  vess_surveyed = p_surveyed
   and    tx_date between p_start and p_end
   and    time_setted < p_end
   group  by tx_date;

   --get vessel delivered per day
   -- cursor drsu_d ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   -- select tx_date, sum(total_catch) total_catch
   -- from   cms_catches_dr_dtls
   -- where  vess_surveyed = p_surveyed
   -- and    tx_date between p_start and p_end
   -- group  by tx_date;

   cursor dedu (p_empl_id in varchar2 ) is
   select empl_empl_id, dety_code, seq_no, amt
   from   pys_deductions
   where  empl_empl_id = p_empl_id
   and    end_date  <= p_date_to
   and    start_date >= p_date_fr
   --and    no_payday > 0
   and    dety_code = ('VALE'); -- VALE should be deducted from Incentives

   dStart       Date;
   dEnd         Date;
   nTotalCatch  Number(12,2);
   nDummy       Number;
   n300_600_cnt Number;
   nRate        pys_employee_incentives.rate%type;
   nBasis       pys_employee_incentives.basis%type;
   nAmt         pys_employee_incentives.amt%type;
   vErrMsg      varchar2(2000);
   nCheck       number;
   nCATCHER     number;
   nLIGHTBOAT   number;
   nLighted     number:= 0;
   nSurveyed    number:= 0;

   d_empl_id    Varchar2(16) := 'B00003';

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
             tx_date, time_setted, vess_catcher, vess_surveyed, vess_lighted, fiso_code, surveyed_by, surveyed_by_vess, total_catch, created_by, dt_created
             )
      select chdr.tx_date, to_date(to_char(chdr.tx_date, 'YYYYMMDD') || to_char(chdr.time_setted, 'HH24MI'), 'YYYYMMDDHH24MI') time_setted, 
             chdr.vess_code vess_catcher, chdr.vess_surveyed, chdr.vess_lighted, clog.fiso_code, chdr.surveyed_by, chdr.surveyed_by_vess,
             sum(nvl(clog.tot_jmb_catch,0) + nvl(clog.tot_lrg_catch,0) + nvl(clog.tot_reg_catch,0)  + nvl(clog.tot_med_catch,0) + nvl(clog.tot_sml_catch,0)) total_catch, user, sysdate
      from   cms_catches_log clog, cms_catches_hdr chdr
      where  clog.cahd_tx_no = chdr.tx_no
      and    chdr.tx_date between p_date_fr and p_date_to
      group  by chdr.tx_date, to_date(to_char(chdr.tx_date, 'YYYYMMDD') || to_char(chdr.time_setted, 'HH24MI'), 'YYYYMMDDHH24MI'), 
            chdr.vess_code, chdr.vess_surveyed, chdr.vess_lighted, clog.fiso_code, chdr.surveyed_by, chdr.surveyed_by_vess;
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

      nCATCHER    := 0 ;
      nLIGHTBOAT  := 0 ;
      nTotalCatch := 0;

      if i.passenger <> 'Y' then

         if i.dt_embarked < p_date_fr then
            dStart := p_date_fr;
         else
            dStart := i.dt_embarked ;
         end if;

         if i.dt_disembarked >= p_date_to then
            dEnd := p_date_to;
         else
            dEnd := i.dt_disembarked ;
         end if;

         -- total catch
         -- scenarios: rate should be based on total catch provided vessels
         nTotalCatch := 0;
         for k in vocr_e ( i.empl_empl_id ) loop
            if i.vess_type = k.vess_type then
               for j in mcsu_c ( i.vessel, dStart, dEnd ) loop
                  nTotalCatch := nTotalCatch + j.total_catch;
               end loop;
            end if;
         end loop;

         -- catcher per source
         for j in dcsu_c ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_catcher_rate ( j.fiso_code, i.rank_code, nTotalCatch );
            if i.empl_empl_id = d_empl_id then
               dbms_output.put_line ('check carrier rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || to_char(j.total_catch) || ',nTotalCatch:' || to_char(nTotalCatch));
            end if;
            if j.total_catch > 0 and nRate > 0 then
               sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, null, null, null );
            end if;
            nCATCHER := nCATCHER + (nRate);
         end loop;
         if nCATCHER > 0 then
            for j in (select code from cms_fishing_sources where status = 'ACTIVE') loop
               begin
                  select 1 into nCheck
                  from   pys_employee_incentives
                  where  YEAR          = p_year
                  and    MO            = p_mon 
                  and    INTY_CODE     = 'CATCHER'
                  and    EMPL_EMPL_ID  = i.empl_empl_id
                  and    VESS_CODE     = i.vessel
                  and    FISO_CODE     = j.code
                  and    RANK_CODE     = i.rank_code;
               exception
                  when no_data_found then
                     sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, null, null, null );
               end;
            end loop;
         end if;

         -- lighted
         -- scenarios for catcher with lighted and/or surveyed, applicable only for PAYAO
         -- if catcher is entitled for lighted and surveyed 15% of lighted + surveyed
         -- if catcher is entitled for lighted 5% of lighted + surveyed
         -- if catcher is entitled for surveyed 10% of lighted + surveyed
         nLighted  := 0;
         nSurveyed := 0;
         for j in dcsu_l ( i.vessel, dStart, dEnd ) loop
            -- total catch is divided to lighted and surveyed
            nLighted  := j.total_catch/2;
            nSurveyed := j.total_catch/2;
            if i.vess_type = 'CATCHER' then
               if j.fiso_code = 'PAYAO' then
            if i.empl_empl_id = d_empl_id then
               dbms_output.put_line ('check lighted&surveyed rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',i.vess_type:' || i.vess_type || ',j.fiso_code :' || j.fiso_code );
            end if;
                  if j.vess_lighted = j.vess_surveyed then
                     nRate := sf_get_lighted_rate ( j.fiso_code, i.rank_code, nTotalCatch);
                     if j.total_catch > 0 and nRate > 0 then
                        sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, ((nLighted*.15)+nSurveyed), nRate, ((nLighted*.15)+nSurveyed)*nRate, p_tranno, null, null, null );
                     end if;
                     nLIGHTBOAT := nLIGHTBOAT + (((nLighted*.15)+nSurveyed)*nRate);
                  elsif j.vess_lighted = i.vessel then
                     nRate := sf_get_lighted_rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                     if j.total_catch > 0 and nRate > 0 then
                        sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nLighted*.05), nRate, (nLighted*.05)*nRate, p_tranno, null, null, null );
                     end if;
                     nLIGHTBOAT := nLIGHTBOAT + ((nLighted*.05)*nRate);
                  elsif j.vess_surveyed = i.vessel then
                     nRate := sf_get_lighted_rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                     if j.total_catch > 0 and nRate > 0 then
                        sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nSurveyed*.10), nRate, (nSurveyed*.10)*nRate, p_tranno, null, null, null );
                     end if;
                     nLIGHTBOAT := nLIGHTBOAT + ((nSurveyed*.10)*nRate);
                  end if;
               end if;
               if i.empl_empl_id = d_empl_id then
                  dbms_output.put_line ('check lighted rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || to_char(j.total_catch) || ',i.vess_type:' || i.vess_type);
               end if;
            else
               if j.vess_lighted = j.vess_surveyed then
                  nRate := sf_get_lighted_rate ( j.fiso_code, i.rank_code, nTotalCatch);
                  if j.total_catch > 0 and nRate > 0 then
                     sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, null, null, null );
                  end if;
                  nLIGHTBOAT := nLIGHTBOAT + (j.total_catch*nRate);
               else
                  nRate := sf_get_lighted_rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                  if j.total_catch > 0 and nRate > 0 then
                     sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, nLighted*nRate, p_tranno, null, null, null );
                  end if;
                  nLIGHTBOAT := nLIGHTBOAT + (nLighted*nRate);
               end if;
               if i.empl_empl_id = d_empl_id then
                  dbms_output.put_line ('check lighted rate:' || to_char(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || to_char(j.total_catch) || ',nTotalCatch:' || to_char(nTotalCatch));
               end if;
            end if;
         end loop;
         if i.empl_empl_id = d_empl_id then
            dbms_output.put_line ('check LIGHTBOAT:' || to_char(nRate) || ',i.vess_type:' || i.vess_type || ',i.rank_code:' ||  i.rank_code || ',nLIGHTBOAT:' || to_char(nLIGHTBOAT) || ',nTotalCatch:' || to_char(nTotalCatch));
         end if;
         if nLIGHTBOAT > 0 then
            if i.vess_type <> 'CATCHER' then
               for j in (select code from cms_fishing_sources where status = 'ACTIVE') loop
                  begin
                     select 1 into nCheck
                     from   pys_employee_incentives
                     where  YEAR          = p_year
                     and    MO            = p_mon 
                     and    INTY_CODE     = 'LIGHTBOAT'
                     and    EMPL_EMPL_ID  = i.empl_empl_id
                     and    VESS_CODE     = i.vessel
                     and    FISO_CODE     = j.code
                     and    RANK_CODE     = i.rank_code;
                  exception
                     when no_data_found then
                        sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, null, null, null );
                  end;
               end loop;
            end if;
         end if;
         
         -- Surveyed By
         for j in dcsu_s ( i.empl_empl_id, dStart, dEnd ) loop
            nRate := sf_get_surveyed_rate ( j.total_catch );
            if i.empl_empl_id = d_empl_id then
               dbms_output.put_line ('check surveyed rate:' || to_char(nRate) || ',i.rank_code:' ||  i.rank_code || ',n300_600_cnt:' || to_char(n300_600_cnt));
            end if;
            if nRate > 0 then
               sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, j.tx_date, j.tx_date, 'SURVEYED', j.vess_catcher, i.rank_code, null, j.total_catch, nRate, j.total_catch * nRate, p_tranno, j.surveyed_by_vess, null, null );
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
            sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, '300_600', i.vessel, i.rank_code, null, n300_600_cnt, nRate, n300_600_cnt*nRate, p_tranno, null, null, null );
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

   for x in (select empl_empl_id, sum(decode(inty_code,'CATCHER',amt,'LIGHTBOAT', amt, 0)) amt  
             from   pys_employee_incentives
             where  inhd_tran_no = p_tranno
             group  by empl_empl_id
            )
   loop
      for i in (select empl_empl_id, period_to, period_fr, vess_code vessel, rank_code
                from   pys_employee_incentives
                where  inhd_tran_no = p_tranno
                and    empl_empl_id = x.empl_empl_id
                order  by period_to desc, period_fr desc
               )
      loop
         if (x.amt > 0) then
            for z in dedu (i.empl_empl_id) loop
               sp_insert_employee_incentive ( i.empl_empl_id, p_year, p_mon, p_date_fr, p_date_to, null, i.vessel, i.rank_code, null, z.amt, 1, z.amt, p_tranno, null, z.dety_code, z.seq_no );
            end loop;
         end if;
         update pys_employee_incentives
         set    l_vess_code = i.vessel,
                l_rank_code = i.rank_code
         where  empl_empl_id = x.empl_empl_id
         and    inhd_tran_no = p_tranno;
         exit;
      end loop;
   end loop;

   commit;

exception
   when others then
      vErrMsg := SQLERRM;
      raise_application_error (-20001, vErrMsg);

end sp_incentive_computation;
/
