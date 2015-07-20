create or replace procedure sp_acc_pcr_receipts (
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
             and    a.pcr_no is null
             and    b.jv_date between p_date_fr and p_date_to)
   loop
      begin
         insert into acc_pcr_receipts
                ( pcr_no, ref_type, ref_code, ref_desc, tx_amt, tx_date, created_by, dt_created )
         values ( p_pcr, 'JV', i.jv_no, i.particulars, i.jv_amt, i.jv_date, user, sysdate );
      exception
         when dup_val_on_index then null;
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_receipts - jv_no:' || to_char(i.jv_no));
      end;

   end loop;

   for i in (select a.cv_no, a.acco_code, a.ref_desc particulars, a.debit cv_amt, b.cv_date
             from   acc_cv_dtl a, acc_cv_hdr b
             where  a.cv_no = b.cv_no
             and    b.cv_status = 'APPROVED'
             and    a.debit > 0
             and    a.acco_code = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH')
             and    a.pcr_no is null
             and    b.cv_date between p_date_fr and p_date_to)
   loop
      begin
         insert into acc_pcr_receipts
                ( pcr_no, ref_type, ref_code, ref_desc, tx_amt, tx_date, created_by, dt_created )
         values ( p_pcr, 'CV', i.cv_no, i.particulars, i.cv_amt, i.cv_date, user, sysdate );
      exception
         when dup_val_on_index then null;
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_receipts - cv_no:' || to_char(i.cv_no));
      end;

   end loop; 

   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_jv ');
END sp_acc_pcr_receipts;
/
