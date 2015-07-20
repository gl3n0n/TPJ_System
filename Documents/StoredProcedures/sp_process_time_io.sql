create or replace procedure sp_process_time_io (p_batch in number) as
   nTime Number(12,4);
   dStaTm  Date;
   dEndTm  Date;
   dActIn  Date;
   dActOut Date;
   vRemarks Varchar2(255);
begin
   for i in ( select b.empl_id, a.tx_date, min(a.tx_time) time_in, max(a.tx_time) time_out
              from   time_in_time_out_log a, pms_employees b
              where  a.card_no = b.biometrics_card_no
              and    a.batch_no = p_batch  
              group  by b.empl_id, a.tx_date )
   loop
      vRemarks := NULL;
      nTime   := NULL;
      dStaTm  := NULL;
      dEndTm  := NULL;
      dActIn  := NULL;
      dActOut := NULL;
      begin
         dStaTm := to_date(to_char(i.time_in,'YYYYMMDD') || '0800', 'YYYYMMDDHH24MI'); 
         dEndTm := to_date(to_char(i.time_in,'YYYYMMDD') || '1700', 'YYYYMMDDHH24MI'); 
         if dStaTm > i.time_in then
            dActIn := dStaTm;
         else
            dActIn := i.time_in;
         end if;
         if i.time_in > dEndTm then
            dActOut := dEndTm;
         else
            dActOut := i.time_out;
         end if;

         nTime := ((dActOut-dActIn) * 24)-1;

         --  for late
         if i.time_in > (dStaTm - (5/60/24)) then
            nTime := nTime - 1;
            vRemarks := 'LATE';
         end if;

         if nTime > 8 then
            nTime := 8;
         else
            nTime := greatest(nTime,0);
         end if; 
         insert into pms_attendance_records 
                ( empl_empl_id, att_date, am_time_in, pm_time_out, num_hours, ot_hours, dt_created, created_by, nd_hours, outer_port, batch_no, remarks )
         values ( i.empl_id, i.tx_date, i.time_in, i.time_out, nTime, 0, sysdate, user, 0, 'N', p_batch, vRemarks );
      exception
         when others then raise_application_error (-20001, 'Employee ID - ' || i.empl_id || ' : ' || SQLERRM);
      end;
   end loop;
   commit;
end;
/
