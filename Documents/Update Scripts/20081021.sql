create table cms_catches_log_20081021 as select * from cms_catches_log;
truncate table cms_catches_log;
alter table cms_catches_log drop constraint CALO_CALO_UK;
alter table cms_catches_log add constraint CALO_CALO_UK unique (CAHD_TX_NO, FISH_TYPE, FISO_CODE, FIZE_CODE);
alter table cms_catches_log add fize_code varchar2(16) not null;
alter table cms_catches_log add tot_catch NUMBER(8,2) default 0 not null;

insert into cms_fish_sizes values ('JUMBO', 'JUMBO', 1, 1, 1, user, sysdate, null, null);
insert into cms_fish_sizes values ('LARGE', 'LARGE', 1, 1, 1, user, sysdate, null, null);
insert into cms_fish_sizes values ('MEDIUM', 'MEDIUM', 1, 1, 1, user, sysdate, null, null);
insert into cms_fish_sizes values ('REGULAR', 'REGULAR', 1, 1, 1, user, sysdate, null, null);
insert into cms_fish_sizes values ('BIG', 'BIG', 1, 1, 1, user, sysdate, null, null);
insert into cms_fish_sizes values ('SMALL', 'SMALL', 1, 1, 1, user, sysdate, null, null);
commit;


create table cms_catches_dr_dtls_20081021 as select * from cms_catches_dr_dtls;
truncate table cms_catches_dr_dtls;
alter table cms_catches_dr_dtls add fize_code varchar2(16) not null;
alter table cms_catches_dr_dtls add tot_catch NUMBER(8,2) default 0 not null;
alter table cms_catches_dr_dtls drop constraint CDRD_PK;
alter table cms_catches_dr_dtls add constraint CDRD_PK primary key (CADR_TX_ID, TYFI_FISH, FIZE_CODE);


declare
   nSeq Number;
begin
   for i in (select tx_no from cms_catches_hdr order by 1) loop
      nSeq := 0;
      for j in (select TX_DATE, CAHD_TX_NO, VESS_CATCHER, FISO_CODE, FISH_TYPE, 
                       TOT_JMB_CATCH, TOT_LRG_CATCH, TOT_MED_CATCH, TOT_SML_CATCH,
                       TOT_REG_CATCH, VESS_SURVEYED, VESS_LIGHTED, PAYAO_NO,
                       DT_CREATED, CREATED_BY, DT_MODIFIED, MODIFIED_BY
                from   cms_catches_log_20081021
                where  cahd_tx_no = i.tx_no
               )
      loop
         if j.tot_sml_catch > 0 then
            nSeq := nSeq + 1;
            insert into cms_catches_log 
                   (seq_no, tx_date, cahd_tx_no, vess_catcher, fiso_code, fish_type, fize_code, tot_catch, 
                   	payao_no, vess_surveyed, vess_lighted, created_by, dt_created, modified_by, dt_modified )
            values (nSeq, j.tx_date, j.cahd_tx_no, j.vess_catcher, j.fiso_code, j.fish_type, 'SMALL', j.tot_sml_catch, 
                   	j.payao_no, j.vess_surveyed, j.vess_lighted, j.created_by, j.dt_created, j.modified_by, j.dt_modified );
         end if;
         if j.tot_reg_catch > 0 then
            nSeq := nSeq + 1;
            insert into cms_catches_log 
                   (seq_no, tx_date, cahd_tx_no, vess_catcher, fiso_code, fish_type, fize_code, tot_catch, 
                   	payao_no, vess_surveyed, vess_lighted, created_by, dt_created, modified_by, dt_modified )
            values (nSeq, j.tx_date, j.cahd_tx_no, j.vess_catcher, j.fiso_code, j.fish_type, 'REGULAR', j.tot_reg_catch, 
                   	j.payao_no, j.vess_surveyed, j.vess_lighted, j.created_by, j.dt_created, j.modified_by, j.dt_modified );
         end if;
         if j.tot_med_catch > 0 then
            nSeq := nSeq + 1;
            insert into cms_catches_log 
                   (seq_no, tx_date, cahd_tx_no, vess_catcher, fiso_code, fish_type, fize_code, tot_catch, 
                   	payao_no, vess_surveyed, vess_lighted, created_by, dt_created, modified_by, dt_modified )
            values (nSeq, j.tx_date, j.cahd_tx_no, j.vess_catcher, j.fiso_code, j.fish_type, 'MEDIUM', j.tot_med_catch, 
                   	j.payao_no, j.vess_surveyed, j.vess_lighted, j.created_by, j.dt_created, j.modified_by, j.dt_modified );
         end if;
         if j.tot_lrg_catch > 0 then
            nSeq := nSeq + 1;
            insert into cms_catches_log 
                   (seq_no, tx_date, cahd_tx_no, vess_catcher, fiso_code, fish_type, fize_code, tot_catch, 
                   	payao_no, vess_surveyed, vess_lighted, created_by, dt_created, modified_by, dt_modified )
            values (nSeq, j.tx_date, j.cahd_tx_no, j.vess_catcher, j.fiso_code, j.fish_type, 'LARGE', j.tot_lrg_catch, 
                   	j.payao_no, j.vess_surveyed, j.vess_lighted, j.created_by, j.dt_created, j.modified_by, j.dt_modified );
         end if;
         if j.tot_jmb_catch > 0 then
            nSeq := nSeq + 1;
            insert into cms_catches_log 
                   (seq_no, tx_date, cahd_tx_no, vess_catcher, fiso_code, fish_type, fize_code, tot_catch, 
                   	payao_no, vess_surveyed, vess_lighted, created_by, dt_created, modified_by, dt_modified )
            values (nSeq, j.tx_date, j.cahd_tx_no, j.vess_catcher, j.fiso_code, j.fish_type, 'JUMBO', j.tot_jmb_catch, 
                   	j.payao_no, j.vess_surveyed, j.vess_lighted, j.created_by, j.dt_created, j.modified_by, j.dt_modified );
         end if;
      end loop;
   end loop;
   commit;
end;
/



begin
   for i in (select tx_id from cms_catches_dr order by 1) loop
      for j in (select TX_DATE, CADR_TX_ID, TO_VESS_CODE, FR_VESS_CODE, TYFI_FISH, 
                       TOT_JMB, TOT_LRG, TOT_MED, TOT_SML, TOT_REG, REMARKS,
                       DT_CREATED, CREATED_BY, DT_MODIFIED, MODIFIED_BY
                from   cms_catches_dr_dtls_20081021
                where  cadr_tx_id = i.tx_id
               )
      loop
         if j.tot_sml > 0 then
            insert into cms_catches_dr_dtls 
                   (tx_date, cadr_tx_id, to_vess_code, fr_vess_code, tyfi_fish, 
                    fize_code, tot_catch, remarks, dt_created, created_by, dt_modified, modified_by )
            values (j.tx_date, j.cadr_tx_id, j.to_vess_code, j.fr_vess_code, j.tyfi_fish, 
                    'SMALL', j.tot_sml, j.remarks, j.dt_created, j.created_by, j.dt_modified, j.modified_by );
         end if;
         if j.tot_reg > 0 then
            insert into cms_catches_dr_dtls 
                   (tx_date, cadr_tx_id, to_vess_code, fr_vess_code, tyfi_fish, 
                    fize_code, tot_catch, remarks, dt_created, created_by, dt_modified, modified_by )
            values (j.tx_date, j.cadr_tx_id, j.to_vess_code, j.fr_vess_code, j.tyfi_fish, 
                    'REGULAR', j.tot_reg, j.remarks, j.dt_created, j.created_by, j.dt_modified, j.modified_by );
         end if;
         if j.tot_med > 0 then
            insert into cms_catches_dr_dtls 
                   (tx_date, cadr_tx_id, to_vess_code, fr_vess_code, tyfi_fish, 
                    fize_code, tot_catch, remarks, dt_created, created_by, dt_modified, modified_by )
            values (j.tx_date, j.cadr_tx_id, j.to_vess_code, j.fr_vess_code, j.tyfi_fish, 
                    'MEDIUM', j.tot_med, j.remarks, j.dt_created, j.created_by, j.dt_modified, j.modified_by );
         end if;
         if j.tot_lrg > 0 then
            insert into cms_catches_dr_dtls 
                   (tx_date, cadr_tx_id, to_vess_code, fr_vess_code, tyfi_fish, 
                    fize_code, tot_catch, remarks, dt_created, created_by, dt_modified, modified_by )
            values (j.tx_date, j.cadr_tx_id, j.to_vess_code, j.fr_vess_code, j.tyfi_fish, 
                    'LARGE', j.tot_lrg, j.remarks, j.dt_created, j.created_by, j.dt_modified, j.modified_by );
         end if;
         if j.tot_jmb > 0 then
            insert into cms_catches_dr_dtls 
                   (tx_date, cadr_tx_id, to_vess_code, fr_vess_code, tyfi_fish, 
                    fize_code, tot_catch, remarks, dt_created, created_by, dt_modified, modified_by )
            values (j.tx_date, j.cadr_tx_id, j.to_vess_code, j.fr_vess_code, j.tyfi_fish, 
                    'JUMBO', j.tot_jmb, j.remarks, j.dt_created, j.created_by, j.dt_modified, j.modified_by );
         end if;
      end loop;
   end loop;
   commit;
end;
/
