create or replace procedure sp_acc_pc_replenishment (
   p_pcr in number,
   p_date_fr in date,
   p_date_to in date
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
             and    b.pcv_status = 'POSTED'
             and    b.pcv_date between p_date_fr and p_date_to)
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

      begin
         insert into acc_pcr_dtl
                ( pcr_no, pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, cash_amt, meals_amt, transpo_amt,
                  fuels_amt, financial_amt, supplies_amt, taxes_amt, repair_amt, vale_amt, advances_amt, misc_amt, sundry, sundry_amt,
                  pcv_date, created_by, dt_created
                )
         values ( p_pcr, i.pcv_no, i.item_no, i.acco_code, i.empl_empl_id, i.dept_code, i.particulars, i.amt, nCash_amt, nMeals_amt, nTranspo_amt,
                  nFuels_amt, nFinancial_amt, nSupplies_amt, nTaxes_amt, nRepair_amt, nVale_amt, nAdvances_amt, nMisc_amt, vSundry, nSundry_amt,
                  i.pcv_date, user, sysdate
                );
      exception
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment ' || i.empl_empl_id || ' pcv_no:' || to_char(i.pcv_no)); 
      end;
                
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
      set    pcv_status = 'REPLENISHED'
      where  pcv_no = j.pcv_no;
   end loop;

   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment '); 
END sp_acc_pc_replenishment;
/
