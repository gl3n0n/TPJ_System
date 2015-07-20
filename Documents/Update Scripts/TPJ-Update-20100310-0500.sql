alter table cms_request_vale add pcv_bal_amt number(12,2) default 0 not null;
alter table cms_op_vale_hdr add pcv_bal_amt number(12,2) default 0 not null;
drop trigger ACC_PCR_HDR_INS_CRF_TRG;
drop trigger ACC_PCR_HDR_UPD_CRF_TRG;


CREATE OR REPLACE VIEW ACC_VALE_LISTING AS
SELECT   'RV' vale_type, v.tran_no, v.tx_date, v.status, v.empl_empl_id, v.vess_code
         , v.approved_amt, v.requested_amt, v.pcv_no, v.pcv_bal_amt
  FROM     cms_request_vale v
  WHERE    v.status = 'APPROVED'
  UNION
  SELECT   'OP' vale_type, v.tran_no, v.tx_date, v.status, NULL empl_empl_id
         , MAX ( d.vess_code ) vess_code, SUM ( d.approved_amt ) approved_amt
         , SUM ( d.requested_amt ) requested_amt, v.pcv_no, v.pcv_bal_amt
  FROM     cms_op_vale_hdr v, cms_op_vale_dtl d
  WHERE    v.tran_no = d.tran_no
  AND      v.status = 'APPROVED'
  AND      v.released_outside = 'N'
  and      d.approved_flag = 'Y'
  GROUP BY v.tran_no, v.tx_date, v.status, v.pcv_no, v.pcv_bal_amt
  ORDER BY tran_no, tx_date

create or replace procedure sp_acc_petty_cash_entries (
      p_pcv_type in varchar2,
      p_pcv_no   in number,
      p_crf_type in varchar2,
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
   nTotalCredit Number(14,6) := 0;
   nTotalVale   Number(14,6) := 0;
   nTotalPCVVale Number(14,6) := 0;
   nItem        Number := 0;
   dValeDate    Date;
BEGIN
   if p_pcv_type = 'VALE' then
      SELECT pcv_date
      INTO   dValeDate
      FROM   acc_pcv_hdr
      WHERE  pcv_no = p_pcv_no;
      if dValeDate >= to_date('20090601', 'YYYYMMDD') then
         SELECT count(1)
         INTO   nCheckVALE
         FROM   acc_pcv_dtl
         WHERE  pcv_no = p_pcv_no
         AND    acco_code = vVALE_Code;

         select sum(debit)
         into   nTotalPCVVale
         from   acc_pcv_dtl a, acc_pcv_hdr b
         where  a.pcv_no = b.pcv_no
         and    b.crf_no = p_crf_no
         and    b.crf_type = p_crf_type
         and    b.pcv_no <> p_pcv_no;

         if p_crf_type = 'RV' then
            SELECT approved_amt-nTotalPCVVale
            INTO   nVale
            FROM   CMS_REQUEST_VALE
            WHERE  tran_no = p_crf_no;
         elsif p_crf_type = 'OP' then
            SELECT SUM (d.approved_amt-nTotalPCVVale) approved_amt
            into   nVale
            FROM   cms_op_vale_hdr v, cms_op_vale_dtl d
            WHERE  v.tran_no = d.tran_no
            and    v.tran_no = p_crf_no
            and    d.approved_flag = 'Y';  
         else
            raise_application_error (-20001, 'ERROR invalid CRF TYPE entry');
         end if;
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

         select sum(debit)
         into   nTotalVale
         from   acc_pcv_dtl a, acc_pcv_hdr b
         where  a.pcv_no = b.pcv_no
         and    b.crf_no = p_crf_no
         and    b.crf_type = p_crf_type;

         if p_crf_type = 'RV' then
            UPDATE CMS_REQUEST_VALE
            SET    pcv_no = p_pcv_no,
                   pcv_bal_amt = nTotalVale
            WHERE  tran_no = p_crf_no;
         elsif p_crf_type = 'OP' then
            UPDATE CMS_OP_VALE_HDR
            SET    pcv_no = p_pcv_no,
                   pcv_bal_amt = nTotalVale
            WHERE  tran_no = p_crf_no;
         end if;

      end if;
   end if;
   select sum(nvl(debit,0)), sum(nvl(credit,0)), count(1)
   into   nTotalDebit, nTotalCredit, nItem
   from   acc_pcv_dtl
   where  pcv_no = p_pcv_no
   and    acco_code <> vPetty_Code;
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
               dbms_output.put_line(nTotalDebit||' - '||nTotalCredit);
               INSERT INTO acc_pcv_dtl
                      ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
               VALUES ( p_pcv_no, nItem, vPetty_Code, p_empl, p_dept, 'Petty Cash', ((nTotalDebit-nTotalCredit)-nVAT)*-1, 0, ((nTotalDebit-nTotalCredit)-nVAT), user, sysdate);
         else
            UPDATE acc_pcv_dtl
            SET    amt    = ((nTotalDebit-nTotalCredit)-nVAT)*-1,
                   credit = ((nTotalDebit-nTotalCredit)-nVAT),
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
