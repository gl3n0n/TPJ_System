create or replace procedure sp_acc_petty_cash_entries (
      p_pcv_type in varchar2,
      p_pcv_no   in number,
      p_crf_no   in number,
      p_vat_inc  in varchar2,
      p_vat      in number,
      p_empl     in varchar2,
      p_dept     in varchar2
   ) as
   nCheckEWT    Number;
   nCheckVALE   Number;
   nCheckPetty  Number;
   vEWT_Code    Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('EWT');
   vVALE_Code    Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('VALE');
   vPetty_Code  Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
   nVAT         Number(14,6) := 0;
   nVALE        Number(14,6) := 0;
   nTotalDebit  Number(14,6) := 0;
   nItem        Number := 0;
BEGIN
   if p_pcv_type = 'VALE' then
      SELECT count(1) 
      INTO   nCheckVALE
      FROM   acc_pcv_dtl 
      WHERE  pcv_no = p_pcv_no
      AND    acco_code = vVALE_Code;

      SELECT approved_amt 
      INTO   nVale
      FROM   CMS_REQUEST_VALE 
      WHERE  tran_no = p_crf_no;

      begin
         if nCheckVALE = 0 then
               nItem := nItem + 1;
               INSERT INTO acc_pcv_dtl 
                      ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
               VALUES ( p_pcv_no, nItem, vVALE_Code, p_empl, p_dept, 'Vale', nVale, nVale, 0, user, sysdate);
         else
            UPDATE acc_pcv_dtl
            SET    amt    = nVale,
                   credit = 0,
                   debit  = nVale
            WHERE  pcv_no = p_pcv_no
            AND    acco_code = vVALE_Code;
         end if;
      exception
         when OTHERS then
            raise_application_error (-20001, 'ERROR on generating EWT entry: ' || SQLERRM);
      end;
   
   end if;



   select sum(nvl(debit,0)), count(1)
   into   nTotalDebit, nItem
   from   acc_pcv_dtl
   where  pcv_no = p_pcv_no;

   if nTotalDebit > 0 then
      -- Generate EWT Entry
      if (p_vat_inc = 'Y') or (nvl(p_vat,0) > 0) then
         if p_vat_inc = 'Y' then
            nVAT := nvl((nvl(p_vat,0)/100) * (nTotalDebit/sf_get_acc_ewt),0);
         else
            nVAT := nvl((nTotalDebit)*(nvl(p_vat,0)/100),0);
         end if;
         SELECT count(1) 
         INTO   nCheckEWT
         FROM   acc_pcv_dtl 
         WHERE  pcv_no = p_pcv_no
         AND    acco_code = vEWT_Code;
         begin
            if nCheckEWT = 0 then
                  nItem := nItem + 1;
                  INSERT INTO acc_pcv_dtl 
                         ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
                  VALUES ( p_pcv_no, nItem, vEWT_Code, p_empl, p_dept, 'Expanded Withholding Tax', nVAT*-1, 0, nVAT, user, sysdate);
            else
               UPDATE acc_pcv_dtl
               SET    amt    = nVAT*-1,
                      credit = nVAT,
                      debit  = 0
               WHERE  pcv_no = p_pcv_no
               AND    acco_code = vEWT_Code;
            end if;
         exception
            when OTHERS then
               raise_application_error (-20001, 'ERROR on generating EWT entry: ' || SQLERRM);
         end;
      end if;
      
      -- Generate PETTY CASH Entry
      SELECT count(1) 
      INTO   nCheckPetty
      FROM   acc_pcv_dtl 
      WHERE  pcv_no = p_pcv_no
      AND    acco_code = vPetty_Code;
      begin
         if nCheckPetty = 0 then
               nItem := nItem + 1;
               INSERT INTO acc_pcv_dtl 
                      ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
               VALUES ( p_pcv_no, nItem, vPetty_Code, p_empl, p_dept, 'Petty Cash', (nTotalDebit-nVAT)*-1, 0, (nTotalDebit-nVAT), user, sysdate);
         else
            UPDATE acc_pcv_dtl
            SET    amt    = (nTotalDebit-nVAT)*-1,
                   credit = (nTotalDebit-nVAT),
                   debit  = 0
            WHERE  pcv_no = p_pcv_no
            AND    acco_code = vPetty_Code;
         end if;
      exception
         when OTHERS then
            raise_application_error (-20001, 'ERROR on generating PETTY CASH entry: ' || SQLERRM);
      end;
      commit;
   end if;

END sp_acc_petty_cash_entries;
/


create or replace public synonym sp_acc_petty_cash_entries for sp_acc_petty_cash_entries;
exec sp_grant_access('TPJ_ACC%', 'sp_acc_petty_cash_entries');
