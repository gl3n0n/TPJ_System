create or replace procedure sp_acc_pcr_jv (
   p_pcr in number,
   p_date_fr in date,
   p_date_to in date
   ) is
BEGIN
   for i in (select a.jv_no, a.acco_code, a.ref_desc particulars, a.debit jv_amt, b.jv_date
             from   acc_jv_dtl a, acc_jv_hdr b
             where  a.jv_no = b.jv_no
             and    b.jv_status = 'APPROVED'
             and    a.debit > 0
             and    a.acco_code = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH')
             and    b.jv_date between p_date_fr and p_date_to)
   loop
      begin
         insert into acc_pcr_jv
                ( pcr_no, jv_no, acco_code, ref_desc, jv_amt, jv_date, created_by, dt_created )
         values ( p_pcr, i.jv_no, i.acco_code, i.particulars, i.jv_amt, i.jv_date, user, sysdate );
      exception
         when dup_val_on_index then null;
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_jv - pcv_no:' || to_char(i.jv_no));
      end;

   end loop;

   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_jv ');
END sp_acc_pcr_jv;
/
