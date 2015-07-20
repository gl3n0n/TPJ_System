alter table acc_pcr_hdr add jv_no number(12);

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
          ( jv_no, jv_date, jv_status, particular, prepared_by, dt_prepared, created_by, dt_created )
   values ( nJV_No, trunc(sysdate), 'NEW', 'PCR #' || to_char(p_pcr_no,'B000009') || ' DTD ' || to_char(dMin, 'MM/DD') || ' TO ' || to_char(dMax, 'MM/DD') , sf_get_empl(user), sysdate, user, sysdate);
   for i in (select pcv_no, acco_code, particulars, amt 
             from   acc_pcr_dtl 
             where  pcr_no = p_pcr_no )
   loop
      nItemNo := nItemNo + 1;
      insert into acc_jv_dtl
             ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created )
      values ( nJV_No, nItemNo, i.acco_code, 'PCR', i.pcv_no, i.particulars, i.amt, 0, user, sysdate );
      nDebit := nDebit + i.amt;
   end loop;
   -- create credit entry
   begin
      nItemNo := nItemNo + 1;
      insert into acc_jv_dtl
             ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created )
      values ( nJV_No, nItemNo, SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH'), 'PCR', p_pcr_no, 'PCR# ' || to_char(p_pcr_no, 'B000009'), 0, nDebit, user, sysdate );
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

create public synonym sp_acc_pcr_posting for sp_acc_pcr_posting;
grant execute on sp_acc_pcr_posting to TPJ_ACC_SUPER_USER;

create or replace procedure sp_acc_jv_posting (
    p_jvno in  number,
    p_date in  date,
    p_acco in  varchar2,
    p_part in  varchar2,
    p_debt in  number,
    p_crdt in  number
   )
   as 
begin
   if SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH') = p_acco then
      insert into acc_petty_cash 
             ( tx_date, ref_type, ref_code, ref_desc, amt, debit, credit, created_by, dt_created )
      values ( p_date, 'JV', lpad(to_char(p_jvno),6,'0'), p_part, p_crdt, p_debt, p_crdt, user, sysdate );
   end if;
end sp_acc_jv_posting;
/
create public synonym sp_acc_jv_posting for sp_acc_jv_posting;
grant execute on sp_acc_jv_posting to TPJ_ACC_SUPER_USER;

create or replace procedure sp_acc_pc_replenishment (
   p_pcr in number
   ) is
   vSundry        Varchar2(16) := NULL;
   nCash_amt      Number(12,2) := 0;
   nMeals_amt     Number(12,2) := 0;
   nTranspo_amt   Number(12,2) := 0;
   nFuels_amt     Number(12,2) := 0;
   nFinancial_amt Number(12,2) := 0;
   nSupplies_amt  Number(12,2) := 0;
   nTaxes_amt     Number(12,2) := 0;
   nRepair_amt    Number(12,2) := 0;
   nVale_amt      Number(12,2) := 0;
   nAdvances_amt  Number(12,2) := 0;
   nMisc_amt      Number(12,2) := 0;
   nSundry_amt    Number(12,2) := 0;
BEGIN

   for i in (select a.pcv_no, a.item_no, a.acco_code, a.particulars, a.amt, a.empl_empl_id, a.dept_code, b.pcv_date 
             from   acc_pcv_dtl a, acc_pcv_hdr b 
             where  a.pcv_no = b.pcv_no 
             and    b.pcv_status = 'APPROVED')
   loop
      if i.acco_code = sf_get_acc_sysparam_charval ('CASH ACCOUNT CODE') then
         nCash_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('MEALS ACCOUNT CODE') then
         nMeals_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('TRANSPO ACCOUNT CODE') then
         nTranspo_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('FUELS ACCOUNT CODE') then
         nFuels_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('FINANCIAL ACCOUNT CODE') then
         nFinancial_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('SUPPLIES ACCOUNT CODE') then
         nSupplies_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('TAXES ACCOUNT CODE') then
         nTaxes_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('REPAIR ACCOUNT CODE') then
         nRepair_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('VALE ACCOUNT CODE') then
         nVale_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('ADVANCES ACCOUNT CODE') then
         nAdvances_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('MISC ACCOUNT CODE') then
         nMisc_amt := i.amt;
      else
         vSundry     := i.acco_code;
         nSundry_amt := i.amt;
      end if;

      insert into acc_pcr_dtl 
             ( pcr_no, pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, cash_amt, meals_amt, transpo_amt,
               fuels_amt, financial_amt, supplies_amt, taxes_amt, repair_amt, vale_amt, advances_amt, misc_amt, sundry, sundry_amt,
               pcv_date, created_by, dt_created
             )
      values ( p_pcr, i.pcv_no, i.item_no, i.acco_code, i.empl_empl_id, i.dept_code, i.particulars, i.amt, nCash_amt, nMeals_amt, nTranspo_amt,
               nFuels_amt, nFinancial_amt, nSupplies_amt, nTaxes_amt, nRepair_amt, nVale_amt, nAdvances_amt, nMisc_amt, vSundry, nSundry_amt,
               i.pcv_date, user, sysdate 
             );

      nCash_amt      := 0;
      nMeals_amt     := 0;
      nTranspo_amt   := 0;
      nFuels_amt     := 0;
      nFinancial_amt := 0;
      nSupplies_amt  := 0;
      nTaxes_amt     := 0;
      nRepair_amt    := 0;
      nVale_amt      := 0;
      nAdvances_amt  := 0;
      nMisc_amt      := 0;
      vSundry        := NULL;
      nSundry_amt    := 0;

   end loop;

   for j in (select pcv_no from acc_pcr_dtl where pcr_no = p_pcr group by pcv_no)
   loop
      update acc_pcv_hdr
      set    pcv_status = 'POSTED'
      where  pcv_no = j.pcv_no;
   end loop;

   commit;
END sp_acc_pc_replenishment;          
/
show err


