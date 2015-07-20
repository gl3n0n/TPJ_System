--update status header to APPROVED
--form should not be editable anymore
--update table PMS_EMPLOYEE_MOVEMENTS fields APPROVED_BY and DT_APPROVED to user and sysdate
DECLARE
   vStatus Varchar2(16);
   vemmoStatus Varchar2(16);
   vsalfreq varchar2(16);
   vismanager varchar2(1);
BEGIN
    begin
      select status into vemmoStatus from PMS_EMPLOYEE_MOVEMENTS where tran_no = :EMMO.tran_no;
   exception
      when no_data_found then
         msg_alert('Please save Employee Movement first.','E',FALSE);
         RETURN;
   end;

   if vemmoStatus <> 'APPROVED' then
      msg_alert ('Cannot post not yet Approved Employee Movement.', 'E', TRUE);
   end if;

   begin
      select py_status into vStatus from PMS_EMPLOYEE_MOVEMENTS where tran_no = :EMMO.tran_no;
   exception
      when no_data_found then
         msg_alert('Please save Employee Movement first.','E',FALSE);
         RETURN;
   end;
   if vStatus in ('POSTED', 'CANCELLED') then
      msg_alert ('Transaction already been ' || vStatus || ', changes are not allowed.', 'E', TRUE);
   end if;
   if :system.form_status in ('CHANGED','NEW') then
      msg_alert('Please save Employee Movement first.','E',FALSE);
      RETURN;
   end if;

   -- get salary info
   begin
      for a in (
            select sal_freq, is_manager
            from   pys_employee_salary
            where  empl_empl_id = :emmo.empl_empl_id
            order by eff_st_date desc)
      loop
            vsalfreq := a.sal_freq;
            vismanager := a.is_manager;
            exit;
      end loop;
      vsalfreq := nvl(vsalfreq,'SEMI-MO');
      vismanager := nvl(vismanager,'N');
   end;
   
   -- preliminary test
   -- crew
   if :emmo.fr_vess_code is not null or :emmo.to_vess_code is not null then
      if :emmo.fr_vess_code is null then      
         declare 
            vembarked char(1);
            vrankcode varchar2(16);
            vbasicrate    number;
            vranktitle varchar2(64);
            vvessname varchar2(64);    
            vdtembarked date;
            vvesscodec varchar2(64);     
         begin
            vembarked := 'N';
            SELECT vess.name, voya.vess_code into vVessName, vVessCodeC
            FROM   cms_voyage_crew voyac, cms_voyages voya, cms_vessels vess
            WHERE  voyac.voya_voyage_date = voya.voyage_date
            AND    voyac.voya_vess_code = voya.vess_code
            and    voya.vess_code = vess.code
            AND    voyac.empl_empl_id = :emmo.empl_empl_id
            and    voyac.dt_disembarked is null
            AND    voyage_end_date IS NULL;
            if vVessCodeC <> nvl(:emmo.fr_vess_code, 'x') then
               msg_alert('Employee ' || :emmo.empl_empl_id || ' is currently in vessel '||vvessname || '.', 'E', TRUE);
            end if;
         exception
            when no_data_found then null;
            when too_many_rows then
               msg_alert ('Employee ' || :emmo.empl_empl_id || ' is currently in 2 or more vessels','E', TRUE);
         end;
      else
         declare 
            vBasicRate  number;
            vDtEmbarked date;
            nRetr       number;
         begin
            sp_is_valid_crew(:emmo.empl_empl_id, :emmo.fr_vess_code, :emmo.fr_posi_code, vBasicRate, vDtEmbarked, nRetr);
            if nRetr = 0 then
               msg_alert ('Employee ' || :emmo.empl_empl_id || ' is not the '||:emmo.fr_posi_name||' in vessel '||:emmo.fr_vess_name,'E', TRUE); 
            end if;
            if nRetr = 2 then
               msg_alert ('Employee ' || :emmo.empl_empl_id || ' is currently in 2 or more vessels','E', TRUE);
            end if;
            if vBasicRate <> :emmo.fr_basic_rate then
                msg_alert ('Employee''s rate is not the same with position '||:emmo.fr_posi_name||' in vessel '||:emmo.fr_vess_name,'E', TRUE); 
            end if;
            if vDtEmbarked > :emmo.eff_st_date then
                msg_alert ('Crew Date disembarked should be later than date embarked','E', TRUE); 
            end if; 
         end;
      end if;
   end if;
   
   -- passenger
   if :emmox.fr_vess_code is not null or :emmox.to_vess_code is not null then
      if :emmox.fr_vess_code is null then
         declare 
            vembarked char(1);
            vvessname varchar2(64);     
            vvesscodec varchar2(64);     
         begin
            vembarked := 'N';
            SELECT 'Y', vess.name, voya.vess_code into vembarked, vvessname, vVessCodeC
            FROM   cms_voyage_pax voyac, cms_voyages voya, cms_vessels vess
            WHERE  voyac.voya_voyage_date = voya.voyage_date
            AND    voyac.voya_vess_code = voya.vess_code
            and    voya.vess_code = vess.code
            AND    voyac.empl_empl_id = :emmo.empl_empl_id
            and    voyac.dt_disembarked is null
            AND    ((voyage_end_date is null) or ((voyage_end_date >= trunc(:emmo.eff_st_date) AND voyage_date <= trunc(:emmo.eff_st_date))));
            if vVessCodeC <> nvl(:emmo.fr_vess_code, 'x') then
               msg_alert ('Employee ' || :emmo.empl_empl_id || ' is currently a passenger of vessel '||vvessname,'E', TRUE);
            end if;

         exception
            when no_data_found then
               null;
            when too_many_rows then
               msg_alert ('Employee ' || :emmo.empl_empl_id || ' is currently a passenger of 2 or more vessels','E', TRUE);
         end;  
      else
         declare 
            vBasicRate  number;
            vDtEmbarked date;
            nRetr       number;
         begin
            sp_is_valid_pax(:emmo.empl_empl_id, :emmox.fr_vess_code, :emmox.fr_posi_code, vBasicRate, vDtEmbarked, nRetr);
            if nRetr = 0 then
                    msg_alert ('Employee ' || :emmo.empl_empl_id || ' is not currently a passenger of vessel '||:emmox.fr_vess_name,'E', TRUE);
            end if;
            if nRetr = 2 then
                    msg_alert ('Employee ' || :emmo.empl_empl_id || ' is currently a passenger of 2 or more vessels','E', TRUE);
            end if;
            if vDtEmbarked > :emmo.eff_st_date then
               msg_alert ('Passenger Date disembarked should be later than date embarked','E', TRUE); 
            end if; 
         end;
      end if;
       
   end if;
   -- end prelimanary test
   
   -- posting
   -- crew
   if :emmo.fr_vess_code is not null or :emmo.to_vess_code is not null then
      if :emmo.fr_vess_code is not null then
         --msg_alert('Crew From','I',FALSE); 
         declare
            vdisembark char(1);
            vembark    char(1);
            vfrrankcode  varchar2(16);
            vfrranktitle  varchar2(64);
            vtorankcode  varchar2(16);
            vtoranktitle  varchar2(64);
         begin
            begin
               select rank.code, rank.title into vfrrankcode, vfrranktitle
               from   pms_ranks rank, pms_positions posi
               where  posi.rank_code = rank.code
               and    posi.code = :emmo.fr_posi_code
               and    rownum = 1;
            exception
               when no_data_found then
                  msg_alert(' From Position Name does not exist.','E',TRUE);
            end;
             
            -- insert into audit log
            insert into pms_empl_move_log (MODULE, TRAN_NO, EMPL_ID, VESS_CODE, POSI_CODE, BASIC_RATE, DT_DISEMBARKED, DT_EMBARKED, STATUS, PY_STATUS, CREATED, DT_CREATED)             
            select 'PYST120', :emmo.tran_no, cvc.empl_empl_id, cvc.voya_vess_code, :emmo.fr_posi_code, cvc.basic_rate, (:emmo.eff_st_date-DECODE(:emmo.to_vess_code,NULL,0,1)), cvc.dt_embarked, :EMMO.status, 'POSTED', user, sysdate             
            from   cms_voyage_crew cvc
            where  cvc.voya_vess_code = :emmo.fr_vess_code
            and    cvc.empl_empl_id   = :emmo.empl_empl_id
            and    cvc.voya_voyage_date <= :emmo.eff_st_date
            and    cvc.rank_code      = vfrrankcode
            and    cvc.basic_rate     = :emmo.fr_basic_rate
            and    cvc.dt_disembarked is null
            and    exists (select    1 from cms_voyages voya
                           where   voya.vess_code = :emmo.fr_vess_code
                           and     voya.voyage_date = cvc.voya_voyage_date
                           and     voya.vess_code = cvc.voya_vess_code
                           and     voya.voyage_end_date is null);
                               
            update cms_voyage_crew cvc
            set    cvc.dt_disembarked = (:emmo.eff_st_date-DECODE(:emmo.to_vess_code,NULL,0,1)),
                   cvc.tran_no_disembarked = (:emmo.tran_no)
            where  cvc.voya_vess_code = :emmo.fr_vess_code
            and    cvc.empl_empl_id   = :emmo.empl_empl_id
            and    cvc.voya_voyage_date <= :emmo.eff_st_date
            and    cvc.rank_code      = vfrrankcode
            and    cvc.basic_rate     = :emmo.fr_basic_rate
            and    cvc.dt_disembarked is null
            and    exists (select    1 from cms_voyages voya
                           where   voya.vess_code = :emmo.fr_vess_code
                           and     voya.voyage_date = cvc.voya_voyage_date
                           and     voya.vess_code = cvc.voya_vess_code
                           and     voya.voyage_end_date is null);
         end;
      end if;
    
      if :emmo.to_vess_code is not null then
         --msg_alert('Crew To','I',FALSE); 
         declare
            vdisembark char(1);
            vembark    char(1);
            vfrrankcode  varchar2(16);
            vfrranktitle  varchar2(64);
            vtorankcode  varchar2(16);
            vtoranktitle  varchar2(64);
            vvoyage_dt date;
            vvoyage_end_date date;
            vseq       number;
         begin
            begin
               select rank.code, rank.title into vtorankcode, vtoranktitle
               from   pms_ranks rank, pms_positions posi
               where  posi.rank_code = rank.code
               and    posi.code = :emmo.to_posi_code
               and    rownum = 1;
            exception
               when no_data_found then
                  msg_alert(' To Position Name does not exist.','E',TRUE);                        
            end;
         
            begin
               select voyage_date, voyage_end_date
               into   vvoyage_dt, vvoyage_end_date
               from   cms_voyages
               where  vess_code = :emmo.to_vess_code
               and    trunc(:emmo.eff_st_date) between voyage_date and nvl(voyage_end_date,to_date('20990101','YYYYMMDD'));
            exception
               when no_data_found then
                  rollback;
                  msg_alert('No Open schedule voyage for vessel '||initcap(:emmo.to_vess_name),'E',TRUE);
                  return;
            end;
                  
            if vvoyage_dt is null then
               rollback;
               msg_alert('No Open schedule voyage for vessel '||initcap(:emmo.to_vess_name),'E',TRUE);
               return;
            end if;
                 
            begin
               select max(cvc.seq_no)+1 into vseq
               from   cms_voyage_crew cvc--, cms_voyages voya
               where  cvc.voya_vess_code = :emmo.to_vess_code
               and    cvc.voya_voyage_date = vvoyage_dt;
               --and    cvc.voya_voyage_date <= :emmo.eff_st_date
               --and    cvc.voya_vess_code = voya.vess_code
               --and    cvc.voya_voyage_date = voya.voyage_date
               --and    voya.voyage_end_date is null
               --and    exists (select    1 from cms_voyages voya
               --               where   voya.vess_code = :emmo.to_vess_code
               --               and     voya.voyage_date = cvc.voya_voyage_date
               --               and     voya.vess_code = cvc.voya_vess_code
               --               and     voya.voyage_end_date is null);
            exception
               when no_data_found then
                  rollback;
                  msg_alert('No Open schedule voyage for vessel '||initcap(:emmo.to_vess_name),'E',TRUE);
                  return;
            end;
                
            if vseq is null then
               vseq := 1;
            end if;
                
            begin                     
               insert into pms_empl_move_log (MODULE, TRAN_NO, EMPL_ID, VESS_CODE, POSI_CODE, BASIC_RATE, DT_DISEMBARKED, DT_EMBARKED, STATUS, PY_STATUS, CREATED, DT_CREATED)             
               values ('PYST120',:emmo.tran_no, :emmo.empl_empl_id, :emmo.to_vess_code, :emmo.to_posi_code, :emmo.to_basic_rate, :emmo.eff_en_date, :emmo.eff_st_date, :EMMO.status, 'POSTED', user, sysdate);
               --pause;
               insert into pys_employee_salary
                      (EMPL_EMPL_ID, EFF_ST_DATE, POSI_CODE, DEPT_CODE, BASIC_RATE, CREATED_BY, DT_CREATED, 
                       BASIC_RATE_G, SAL_FREQ, IS_MANAGER) 
               values (:emmo.empl_empl_id, :emmo.eff_st_date, :emmo.to_posi_code, :emmo.to_dept_code, :emmo.to_basic_rate, SF_GET_EMPL(user), sysdate,
                       :emmo.to_basic_rate*decode(vsalfreq,'MONTHLY',30,1), vsalfreq, vismanager);
               --pause;
               if vvoyage_end_date is not null then
                  msg_alert('Voyage for Vessel '||:emmo.to_vess_name||' had already been ended on '||to_char(vvoyage_end_date,'Month DD, YYYY'),'E',FALSE);
                  insert into cms_voyage_crew(voya_vess_code, voya_voyage_date, empl_empl_id, 
                          created_by, dt_created, rank_code, title, 
                          seq_no, dt_embarked, dt_disembarked, passenger, 
                          basic_rate, basic_rate_g,  tran_no_embarked, tran_no_disembarked) 
                  values (:emmo.to_vess_code,vvoyage_dt, :emmo.empl_empl_id, 
                          user, sysdate, vtorankcode, vtoranktitle,
                          vseq, :emmo.eff_st_date, vvoyage_end_date, 'N', 
                          :emmo.to_basic_rate, :emmo.to_basic_rate, :emmo.tran_no, :emmo.tran_no);                           
               else
                  insert into cms_voyage_crew(voya_vess_code, voya_voyage_date, empl_empl_id, 
                          created_by, dt_created, rank_code, title, 
                          seq_no, dt_embarked, dt_disembarked, passenger, 
                          basic_rate, basic_rate_g,  tran_no_embarked) 
                  values (:emmo.to_vess_code,vvoyage_dt, :emmo.empl_empl_id, 
                          user, sysdate, vtorankcode, vtoranktitle,
                            vseq, :emmo.eff_st_date, :emmo.eff_en_date, 'N', 
                            :emmo.to_basic_rate, :emmo.to_basic_rate, :emmo.tran_no);
               end if;      
            end;
         end;
      end if;
   end if;
   
   
   --passenger
   if :emmox.fr_vess_code is not null or :emmox.to_vess_code is not null then
      if :emmox.fr_vess_code is not null then
         declare
            vdisembark char(1);
            vembark    char(1);
            vfrrankcode  varchar2(16);
            vfrranktitle  varchar2(64);
            vtorankcode  varchar2(16);
            vtoranktitle  varchar2(64);
         begin
            begin
               select rank.code, rank.title into vfrrankcode, vfrranktitle
               from   pms_ranks rank, pms_positions posi
               where  posi.rank_code = rank.code
               and    posi.code = :emmox.fr_posi_code
               and    rownum = 1;
            exception
               when no_data_found then
                  msg_alert('Passenger From Position Name does not exist.','E',TRUE);
            end;
              
            -- insert into audit log
            insert into pms_empl_pax_log (MODULE, TRAN_NO, EMPL_ID, VESS_CODE, POSI_CODE, BASIC_RATE, DT_DISEMBARKED, DT_EMBARKED, STATUS, PY_STATUS, CREATED, DT_CREATED)             
            select 'PYST120', :emmo.tran_no, cvc.empl_empl_id, cvc.voya_vess_code, :emmox.fr_posi_code, cvc.basic_rate, (:emmo.eff_st_date-DECODE(:emmox.to_vess_code,NULL,0,1)), cvc.dt_embarked, :EMMO.status, 'POSTED', user, sysdate             
            from   cms_voyage_pax cvc
            where  cvc.voya_vess_code = :emmox.fr_vess_code
            and    cvc.empl_empl_id   = :emmo.empl_empl_id
            and    cvc.voya_voyage_date <= :emmo.eff_st_date
            and    cvc.rank_code      = vfrrankcode
            --and    cvc.basic_rate     = :emmo.fr_basic_rate
            and    cvc.dt_disembarked is null
            and    exists (select    1 from cms_voyages voya
                           where   voya.vess_code = :emmox.fr_vess_code
                           and     voya.voyage_date = cvc.voya_voyage_date
                           and     voya.vess_code = cvc.voya_vess_code
                           and     voya.voyage_end_date is null);
                                
            update cms_voyage_pax cvc
            set    cvc.dt_disembarked = (:emmo.eff_st_date-DECODE(:emmox.to_vess_code,NULL,0,1)),
                   cvc.tran_no_disembarked = (:emmo.tran_no)
            where  cvc.voya_vess_code = :emmox.fr_vess_code
            and    cvc.empl_empl_id   = :emmo.empl_empl_id
            and    cvc.voya_voyage_date <= :emmo.eff_st_date
            and    cvc.rank_code      = vfrrankcode
            --and    cvc.basic_rate     = :emmo.fr_basic_rate
            and    cvc.dt_disembarked is null
            and    exists (select    1 from cms_voyages voya
                           where   voya.vess_code = :emmox.fr_vess_code
                           and     voya.voyage_date = cvc.voya_voyage_date
                           and     voya.vess_code = cvc.voya_vess_code
                           and     voya.voyage_end_date is null);
         end;
      end if;
        
      if :emmox.to_vess_code is not null then
         declare
            vdisembark char(1);
            vembark    char(1);
            vfrrankcode  varchar2(16);
            vfrranktitle  varchar2(64);
            vtorankcode  varchar2(16);
            vtoranktitle  varchar2(64);
            vvoyage_dt date;
            vvoyage_end_dt date;
            vseq       number;
         begin
            begin
               select rank.code, rank.title into vtorankcode, vtoranktitle
               from   pms_ranks rank, pms_positions posi
               where  posi.rank_code = rank.code
               and    posi.code = :emmox.to_posi_code
               and    rownum = 1;
            exception
               when no_data_found then
                  msg_alert('Passenger To Position Name does not exist.','E',TRUE);
                  return;
            end;
                
            begin
               select voyage_date, voyage_end_date
               into   vvoyage_dt, vvoyage_end_dt 
               from   cms_voyages
               where  vess_code = :emmox.to_vess_code
               and    trunc(:emmo.eff_st_date) between voyage_date and nvl(voyage_end_date,to_date('20990101'));
            exception
               when no_data_found then
                  rollback;
                  msg_alert('No Open schedule voyage for vessel '||initcap(:emmox.to_vess_name),'E',TRUE);
                  return;
            end;
                  
            if vvoyage_dt is null then
               rollback;
               msg_alert('No Open schedule voyage for vessel '||initcap(:emmox.to_vess_name),'E',TRUE);                   
            end if;                 
                
            begin
               select max(seq_no)+1 into vseq
               from   cms_voyage_pax cvc
               where  cvc.voya_vess_code = :emmox.to_vess_code
               and    cvc.voya_voyage_date = vvoyage_dt;
               --and    cvc.voya_voyage_date <= :emmo.eff_st_date
               --and    exists (select    1 from cms_voyages voya
               --               where   voya.vess_code = :emmox.to_vess_code
               --              and     voya.voyage_date = cvc.voya_voyage_date
               --               and     voya.vess_code = cvc.voya_vess_code
               --               and     voya.voyage_end_date is null);
            exception
               when no_data_found then
                  vseq := 1;
            end;
             
            if vseq is null then
               vseq := 1;
            end if;
               
            begin
               --message(:emmox.to_vess_code||','||vvoyage_dt||','||vseq);
               --message(:emmox.to_vess_code||','||vvoyage_dt||','||vseq);
               insert into pms_empl_pax_log (MODULE, TRAN_NO, EMPL_ID, VESS_CODE, POSI_CODE, BASIC_RATE, DT_DISEMBARKED, DT_EMBARKED, STATUS, PY_STATUS, CREATED, DT_CREATED)             
               values ('PYST120',:emmo.tran_no, :emmo.empl_empl_id, :emmox.to_vess_code, :emmox.to_posi_code, :emmo.to_basic_rate, :emmo.eff_en_date, :emmo.eff_st_date, :EMMO.status, 'POSTED', user, sysdate);
               if vvoyage_end_dt is not null then
                  insert into cms_voyage_pax(voya_vess_code, voya_voyage_date, empl_empl_id, 
                          created_by, dt_created, 
                          rank_code, title, seq_no, dt_embarked, dt_disembarked, 
                          basic_rate, basic_rate_g, tran_no_embarked, tran_no_disembarked) 
                  values (:emmox.to_vess_code,vvoyage_dt, :emmo.empl_empl_id, user, sysdate,
                          vtorankcode, vtoranktitle, vseq, :emmo.eff_st_date, vvoyage_end_dt,
                          :emmo.to_basic_rate, :emmo.to_basic_rate, :emmo.tran_no, :emmo.tran_no);                    
               else
                  insert into cms_voyage_pax(voya_vess_code, voya_voyage_date, empl_empl_id, 
                          created_by, dt_created, 
                          rank_code, title, seq_no, dt_embarked, dt_disembarked, 
                          basic_rate, basic_rate_g, tran_no_embarked) 
                  values (:emmox.to_vess_code,vvoyage_dt, :emmo.empl_empl_id, user, sysdate,
                          vtorankcode, vtoranktitle, vseq, :emmo.eff_st_date, :emmo.eff_en_date,
                          :emmo.to_basic_rate, :emmo.to_basic_rate, :emmo.tran_no);                 
               end if;
            end;   
         end;
      end if;   
   end if;
   
   :EMMO.py_status := 'POSTED';
   :EMMO.posted_by := sf_get_empl(user);
   :EMMO.dt_posted := sysdate;

   commit;
   if form_success then
   msg_alert('Transaction Posted.', 'I', FALSE);

   set_block_property('EMMO',UPDATE_ALLOWED,PROPERTY_FALSE);
   set_block_property('EMOA',UPDATE_ALLOWED,PROPERTY_FALSE);
   set_block_property('EMOA',INSERT_ALLOWED,PROPERTY_FALSE);
   set_block_property('EMOA',DELETE_ALLOWED,PROPERTY_FALSE); 
   end if;
END;
