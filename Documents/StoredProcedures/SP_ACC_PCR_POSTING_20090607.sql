create or replace procedure sp_acc_pcr_posting (
    p_pcr_no   in  number,
    p_pcr_desc in  varchar2
   )
   as
   nJV_No  Number;
   nItemNo Number := 0;
   nDebit  Number(12,2) := 0;
   dMin    Date;
   dMax    Date;
begin
   -- create JV header
   select acc_jv_seq.nextval into nJV_No  from dual;

   select min(pcv_date), max(pcv_date)
   into   dMin, dMax
   from   acc_pcr_dtl
   where  pcr_no = p_pcr_no;

   insert into acc_jv_hdr
          ( jv_no, jv_date, jv_status, particular, curr_code, prepared_by, dt_prepared, created_by, dt_created )
   values ( nJV_No, trunc(sysdate), 'NEW', 'PCR #' || to_char(p_pcr_no,'B000009') || ' DTD ' || to_char(dMin, 'MM/DD') || ' TO ' || to_char(dMax, 'MM/DD') , 'PHP', sf_get_empl(user), sysdate, user, sysdate);
   for i in (select pcv_no, acco_code, particulars, amt
             from   acc_pcr_dtl
             where  pcr_no = p_pcr_no )
   loop
      nItemNo := nItemNo + 1;
      insert into acc_jv_dtl
             ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created )
      values ( nJV_No, nItemNo, i.acco_code, 'PCV', to_char(i.pcv_no, 'B000009'), i.particulars, i.amt, 0, user, sysdate );
      nDebit := nDebit + i.amt;
   end loop;
   -- create credit entry
   begin
      nItemNo := nItemNo + 1;
      insert into acc_jv_dtl
             ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created )
      values ( nJV_No, nItemNo, SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH'), 'PCR',  to_char(p_pcr_no, 'B000009'), 'PCR# ' || to_char(p_pcr_no, 'B000009'), 0, nDebit, user, sysdate );
   exception
      when others then
         raise_application_error (-20001, SQLERRM || ' for PCV_NO ' || to_char(p_pcr_no, 'B000009') );
   end;
   update acc_pcr_hdr
   set    jv_no = nJV_No
   where  pcr_no = p_pcr_no;
   commit;
end sp_acc_pcr_posting;
/
