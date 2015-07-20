alter table inv_po_hdr modify REMARKS varchar2(2000);

CREATE OR REPLACE VIEW ACC_INV_RR_DTL AS
SELECT drhd.dr_no dr_no, drhd.supp_code supp_code, drhd.pohd_po_no po_no
       , pohd.rshd_rs_no rs_no, drhd.invoice_no invoice_no
       , drhd.dr_date dr_date, drhd.rr_amt rr_amt, drhd.rr_paid rr_paid
       , pohd.currency po_currency, pohd.terms po_terms, drhd.cpa_amt
       , drhd.supp_dr_no, drhd.invoice_dt, drhd.ap_no
       , drhd.addtl_disc
  FROM   inv_dr_hdr drhd, inv_po_hdr pohd
  WHERE  drhd.pohd_po_no = pohd.po_no AND drhd.status = 'POSTED'
/

create or replace function sp_acc_get_rr_discount (p_po_no in varchar2) return number as
   nDiscount Number; 
begin
   select sum(discount)
   into  nDiscount
   from  inv_dr_dtl
   where pohd_po_no = p_po_no; 
   return nvl(nDiscount,0);
end sp_acc_get_rr_discount;
/

create or replace procedure sp_acc_apv_download_inv (
   p_period_fr date, 
   p_period_to date, 
   p_ap_no     varchar2,
   p_inv_type  varchar2,
   p_supp_code varchar2
  ) as
  vStatus Varchar2(16);
   nItem   Number;
   nrr_conv ACC_AP_INV_DTL.rr_conv%type;
BEGIN
   if (p_period_fr is null) or (p_period_to is null)   then
      RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - Please enter period to download...');
   end if;

   for a in (
      SELECT rr_no 
      FROM acc_ap_inv_dtl
      WHERE  ap_no = p_ap_no
      AND    is_selected = 'N')
   loop
      if p_inv_type = 'PO' then
         UPDATE inv_dr_hdr
         SET    ap_no = null
         WHERE  dr_no = a.rr_no
         AND    ap_no = p_ap_no;
      else
         UPDATE inv_jo_dr_hdr
         SET    ap_no = null
         WHERE  jo_dr_no = a.rr_no
         AND    ap_no = p_ap_no; 
      end if;
   end loop;

   DELETE FROM acc_ap_inv_dtl
   WHERE  ap_no = p_ap_no
   AND    is_selected = 'N';

   if p_inv_type = 'PO' then
      for a in ( SELECT rr_no 
                 FROM   acc_ap_inv_dtl
                 WHERE  ap_no = p_ap_no
                 AND    po_no like 'JO%')
      loop
         UPDATE inv_jo_dr_hdr
         SET    ap_no = null
         WHERE  jo_dr_no = a.rr_no
         AND    ap_no = p_ap_no; 
      end loop;
      DELETE FROM acc_ap_inv_dtl
      WHERE  ap_no = p_ap_no
      AND    po_no LIKE 'JO%';  
   end if;
   
   if p_inv_type = 'JO' then
      for a in ( SELECT rr_no 
                 FROM   acc_ap_inv_dtl
                 WHERE  ap_no = p_ap_no
                 AND    po_no not LIKE 'JO%')
      loop
         update inv_dr_hdr
         set    ap_no = null
         where  dr_no = a.rr_no
         and    ap_no = p_ap_no; 
      end loop;
      DELETE FROM acc_ap_inv_dtl
      WHERE  ap_no = p_ap_no
      AND    po_no not like 'JO%';
   end if;
   
   DELETE FROM acc_ap_advances acad
   WHERE ap_no = p_ap_no;

   SELECT nvl(max(item_no),0)
   INTO   nItem
   FROM   acc_ap_inv_dtl
   WHERE  ap_no = p_ap_no;

   nrr_conv := 0;
   
   if p_inv_type = 'PO' then
      for i in (SELECT drhd.dr_no rr_no,
                       drhd.po_no po_no,
                       drhd.rs_no rs_no,
                       nvl(drhd.dr_date, drhd.invoice_dt) rr_date,
                       nvl(drhd.invoice_no, drhd.supp_dr_no) invoice_no,
                       drhd.rr_amt-nvl(drhd.addtl_disc,0) rr_amt,
                       drhd.rr_paid rr_paid,
                       drhd.po_currency, 
                       sf_get_inv_adv_payment('PO',drhd.po_no) cpa_amt,
                       sf_get_inv_adv_payment_php('PO',drhd.po_no) cpa_amt_php,
                       sf_get_retslip_amt(drhd.dr_no) ret_amt,
                       ap_no
                FROM   acc_inv_rr_dtl drhd
                WHERE  drhd.supp_code = p_supp_code
                AND    ap_no is null
                AND    drhd.dr_date BETWEEN p_period_fr AND p_period_to 
                --AND    drhd.po_terms <> 'COD'
                AND    not exists (
                       SELECT 1 
                       FROM   acc_ap_inv_dtl apin
                       WHERE  apin.rr_no = drhd.dr_no
                       AND    apin.ap_no = p_ap_no
                       )
                ORDER  BY DRHD.DR_DATE)
      loop
         nItem := nItem + 1;
         if i.po_currency = 'PHP' then
              nrr_conv := 1;
         else
              nrr_conv := 0;
         end if;
         INSERT INTO ACC_AP_INV_DTL 
                ( item_no, ap_no, rr_no, rs_no, po_no, invoice_no, amount, amount_net, rr_date, created_by, dt_created, rr_conv, cpa_amt, cpa_amt_php, ret_amt, ret_amt_php)
         VALUES ( nItem, p_ap_no, i.rr_no, i.rs_no, i.po_no, i.invoice_no, i.rr_amt, i.rr_amt - (i.cpa_amt_php+i.ret_amt), i.rr_date, user, sysdate, nrr_conv, i.cpa_amt, i.cpa_amt_php, i.ret_amt, i.ret_amt);
         nrr_conv := 0;
         update inv_dr_hdr
               set    ap_no = p_ap_no
               where  dr_no = i.rr_no
               and    ap_no is null;
      end loop;
   end if;
   
   if p_inv_type = 'JO' then
      for i in (SELECT drhd.jo_dr_no dr_no, 
                       drhd.supp_code supp_code, 
                       drhd.johd_jo_no jo_no, 
                       johd.jshd_js_no js_no, 
                       drhd.supp_dr_no invoice_no, 
                       nvl(drhd.invoice_dt,drhd.jo_dr_date) dr_date, 
                       drhd.rr_amt rr_amt, 
                       drhd.rr_paid rr_paid, 
                       'PHP' po_currency, 
                       sf_get_inv_adv_payment('JO',drhd.johd_jo_no) cpa_amt
                FROM   inv_jo_dr_hdr drhd, 
                       inv_jo_hdr johd 
                WHERE  drhd.johd_jo_no = johd.jo_no 
                AND    drhd.status='APPROVED'
                AND    drhd.supp_code = p_supp_code
                --AND   johd.terms <> 'COD'
                -- modified 20101208 as per ms sonia used invoice date
                --AND   drhd.jo_dr_date BETWEEN p_period_fr AND p_period_to 
                AND    drhd.invoice_dt between p_period_fr and p_period_to 
                AND    drhd.ap_no is null
                AND    not exists ( SELECT 1 
                                    FROM   acc_ap_inv_dtl apin
                                    WHERE  apin.rr_no = drhd.jo_dr_no
                                    AND    apin.ap_no = p_ap_no
                                   )
                ORDER  BY DRHD.JO_DR_DATE )
      loop
         nItem := nItem + 1;
         if i.po_currency = 'PHP' then
              nrr_conv := 1;
         else
              nrr_conv := 0;
         end if;
         INSERT INTO acc_ap_inv_dtl 
                ( item_no, ap_no, rr_no, rs_no, po_no, invoice_no, amount, amount_net, rr_date, created_by, dt_created, rr_conv, cpa_amt, cpa_amt_php)
         VALUES ( nItem, p_ap_no, i.dr_no, i.js_no, 'jo'||i.jo_no, i.invoice_no, i.rr_amt, i.rr_amt-i.cpa_amt, i.dr_date, user, sysdate, nrr_conv, i.cpa_amt, i.cpa_amt );
         nrr_conv := 0;
         UPDATE inv_jo_dr_hdr
         SET    ap_no = p_ap_no
         WHERE  jo_dr_no = i.dr_no
         AND    ap_no is null; 
      end loop;
   end if;
   commit;
END sp_acc_apv_download_inv;
/

create or replace procedure sp_acc_apv_post_inv (
  p_ap_no in varchar2,
  p_drhd_curr in varchar2
  ) as
   vPeriod_to           acc_ap_hdr.period_to%type;
   vAp_Date             acc_ap_hdr.ap_date%type;
   vInv_Type            acc_ap_hdr.inv_type%type;
   vRef_AP_No           acc_ap_hdr.ref_ap_no%type;
   vVat                 acc_ap_hdr.vat%type;
   vVat_Inc             acc_ap_hdr.vat_inc%type;
   vAp_Discount         acc_ap_hdr.ap_discount%type;
   vAp_Disc_Amt         acc_ap_hdr.ap_disc_amt%type;
   vAp_Oth_Disc_Amt     acc_ap_hdr.ap_oth_disc_amt%type;
   vUnused_Adv          acc_ap_hdr.unused_adv%type;    
   vUnused_Adv_Php      acc_ap_hdr.unused_adv_php%type;
   vTotal_Amount        number(16,4);
   vTotal_Amount_Net    number(16,4);
   vTotal_Ret_Amt       number(16,4);
   vTotal_Ret_Amt_Php   number(16,4);
   vTotal_FX_Amount     number(16,4);
   vTotal_Amount_Net_FX number(16,4);
   vStatus      Varchar2(16);
   nDummy       Number;
   nVat         number(16,2);
   nVatphp      number(16,2);
   nAmtPhp      number(16,2);
   nDiscphp     number(16,2);
   nAmt         number(16,2);
   nDisc        number(16,2);
   nDisc_oth    number(16,2);
   nDisc_othphp number(16,2);
   nItem        Number := 1;
   vAP_Accnt    Varchar2(16):= '60001';
   vMaterial    Varchar2(16):= '903';
   vRepair      Varchar2(16):= '923';
   vDisc_Acct   Varchar2(16):= '944.1';
   vVAT_Acct    Varchar2(16):= '60005';
   vAdv_acct    Varchar2(16):= '40004';
   vSus_Acct    Varchar2(16):= '10010';
   vCurr_Code   varchar2(16);
   vInvType     varchar2(16);
   nSus         number(16,2);
   nSusPhp      number(16,2);
   nAdv         number(16,2);
   nAdvPhp      number(16,2);
   nSus1        number(16,2);
   nSusPhp1     number(16,2);
   nAdv1        number(16,2);
   nAdvPhp1     number(16,2);
   v_RefAp      char(1) := 'N';
   vCurr        varchar2(30);
   dCurrDate    date;
   nForex       Number;
BEGIN
   -- clear apv details
   delete from acc_ap_dtl where ap_no = p_ap_no;
   
   select period_to, ap_discount, ap_disc_amt, ap_oth_disc_amt, ap_date, 
          vat, vat_inc, inv_type, ref_ap_no, unused_adv, unused_adv_php
   into   vPeriod_to, vAp_Discount, vAp_Disc_Amt, vAp_Oth_Disc_Amt, vAp_Date, 
          vVat, vVat_Inc, vInv_Type, vRef_AP_No, vUnused_Adv, vUnused_Adv_Php
   from   acc_ap_hdr
   where  ap_no = p_ap_no;

   select sum(amount), sum(amount_net), sum(ret_amt), sum(ret_amt_php), sum(fx_amount), sum(fx_amount-(cpa_amt+ret_amt))
   into   vTotal_Amount, vTotal_Amount_Net, vTotal_Ret_Amt, vTotal_Ret_Amt_PHP, vTotal_FX_Amount, vTotal_Amount_Net_FX
   from   acc_ap_inv_dtl
   where  ap_no = p_ap_no;

   if vInv_Type = 'PO' then
      vInvType := 'PO';
   else
      vInvType := 'JO';
   end if;
   
   vCurr_Code := p_drhd_curr;
   
   --msg_alert ('check nAMT  -> ' || to_char(vTotal_Amount_Net), 'I', FALSE);
   nAmtPhp  := vTotal_Amount_Net;
   nDiscphp := (vTotal_Amount_Net*(vAp_Discount/100)) + (vAp_Disc_Amt*sf_get_fx_rate(vCurr_Code, vAp_Date));
   nAmt     := vTotal_Amount_Net_fx;
   nDisc    := (vTotal_Amount_Net_fx*(vAp_Discount/100)) + vAp_Disc_Amt;

   -- Other discount
   nDisc_oth    := nvl(vAp_Oth_Disc_Amt,0);
   nDisc_othphp := nvl(vAp_Oth_Disc_Amt,0)*sf_get_fx_rate(vCurr_Code, vAp_Date);

   insert into acc_ap_dtl (
            item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
            debit, credit, debit_php, credit_php, created_by, dt_created)
   values ( nitem, p_ap_no, decode(vInv_Type,'PO',vMaterial,vRepair), vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
            vTotal_FX_Amount-nvl(vTotal_Ret_Amt,0), 0, vTotal_Amount-nvl(vTotal_Ret_Amt_PHP,0), 0, user, sysdate);
          
   if vAp_Discount > 0 or vAp_Disc_Amt > 0 then
      nitem := nitem + 1; 
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
               debit, credit, debit_php, credit_php, created_by, dt_created)
      values ( nitem, p_ap_no, vDisc_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
               0, nDisc, 0, nDiscphp, user, sysdate);
   end if;
  
   if nDisc_oth > 0 then
      nitem := nitem + 1; 
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
               debit, credit, debit_php, credit_php, created_by, dt_created)
      values ( nitem, p_ap_no, vDisc_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
               0, nDisc_oth, 0, nDisc_othphp, user, sysdate);
   end if;

   if vVat_Inc = 'Y' or vVat > 0 then
            
      if vVat_Inc = 'Y' then
          nVat    := nvl((nvl(vVat,0)/100) * (vTotal_FX_Amount / sf_get_acc_ewt),0);
          nVatphp := nvl((nvl(vVat,0)/100) * (vTotal_Amount    / sf_get_acc_ewt),0);
      else
          nVat    := nvl((vTotal_FX_Amount) * (nvl(vVat,0)/100),0);
          nVatphp := nvl((vTotal_Amount)    * (nvl(vVat,0)/100),0);
      end if;
      /* -- commented out by rollie 20100118
         -- as per ms sonia, vat should look into total amount not net total amount
      */    
      nitem := nitem + 1;         
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vVAT_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
               0, nVat, 0, nVatphp, user, sysdate  );
          
   end if;
       
   dbms_output.put_line('nAmt:' || to_char(nAmt) || 'nVat:' || to_char(nVat) || '^nDisc:' || to_char(nDisc) || '^nDisc_oth:' || to_char(nDisc_oth));
   nAmt    := nAmt    - round((nvl(nVat,0)    + nvl(nDisc,0) + nvl(nDisc_oth,0)),2);
   nAmtPhp := nAmtPhp - round((nvl(nVatphp,0) + nvl(nDiscphp,0) + nvl(nDisc_othphp,0)),2);
   
   delete from acc_ap_oth_dtl where ap_no = p_ap_no; 
   
   for a in (select is_selected, po_no from acc_ap_inv_dtl where ap_no = p_ap_no)
   loop
       if nvl(a.is_selected,'N') = 'N' then
          delete from acc_ap_advances
          where  ap_no    = p_ap_no
          and    po_no    = replace(a.po_no,'JO','')
          and    inv_type = vInv_Type;
       else
          sp_pop_inv_adv_payment(p_ap_no, vInv_Type, replace(a.po_no,'JO','') );
       end if;
   end loop;
   
   delete from acc_ap_advances acad
   where  ap_no    = p_ap_no
   and    inv_type = vInv_Type
   and    not exists (select 1 
                      from   acc_ap_inv_dtl apid, acc_ap_hdr aphd
                      where  apid.ap_no = acad.ap_no
                      and    aphd.ap_no = apid.ap_no 
                      and    replace(apid.po_no,'JO','') = acad.po_no
                      and    acad.inv_type = aphd.inv_type);
   
   for a in (SELECT rr_no FROM acc_ap_inv_dtl
             WHERE  ap_no = p_ap_no
             AND    is_selected = 'N')
   loop
      if vInv_Type = 'PO' then
         update inv_dr_hdr
         set    ap_no = null
         where  dr_no = a.rr_no
         and    ap_no = p_ap_no;
      else
         update inv_jo_dr_hdr
         set    ap_no = null
         where  jo_dr_no = a.rr_no
         and    ap_no = p_ap_no; 
      end if;
   end loop;
   
   delete from acc_ap_inv_dtl where ap_no = p_ap_no and is_selected = 'N';
   
   dbms_output.put_line('nAmt:' || to_char(nAmt) || '^nAmtPhp:' || to_char(nAmtPhp));
   -- get balance from previous ap transaction
   if vRef_AP_No is not null then
        for a in ( select unused_adv_php, unused_adv
                   from   acc_ap_hdr
                   where  ap_no = vRef_AP_No )
        loop
           dbms_output.put_line('unused_adv:' || to_char(trunc(a.unused_adv,2)) || '^a.unused_adv_php:' || to_char(trunc(a.unused_adv_php,2)));
           insert into acc_ap_advances(
                   ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
           values (p_ap_no, 'AP', vRef_AP_No, vInvType, '0', a.unused_adv, user, sysdate, a.unused_adv_php);
           nitem := nitem + 1; 
           insert into acc_ap_dtl (
                   item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
                   debit, credit, debit_php, credit_php, created_by, dt_created )
           values (nitem, p_ap_no, vAP_Accnt, vInvType, vInvType || '#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
                   0, greatest((trunc(nAmt,2) - trunc(a.unused_adv,2)),0), 0, greatest((trunc(nAmtPhp,2) - trunc(a.unused_adv_php,2)),0), user, sysdate);
           v_RefAp := 'Y';           
        end loop;      
   end if;
   
   if v_RefAp = 'N' then
      nitem := nitem + 1; 
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vAP_Accnt, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
               0, greatest(nAmt,0), 0, greatest(nAmtPhp,0), user, sysdate  );
   end if;

   nSus    := 0;
   nSusPhp := 0;
   nAdv    := 0;
   nAdvPhp := 0;
   
   for a in ( select ref_type, ref_code, adv_amount, adv_amount_php, inv_type, po_no
              from   acc_ap_advances
              where  ap_no = p_ap_no )
   loop
       -- get currency
       if a.ref_type = 'CV' then
          for a in ( SELECT pohd.currency
                     FROM   acc_ap_inv_dtl apidt, inv_po_hdr pohd 
                     WHERE  apidt.is_selected= 'y'
                     AND    pohd.po_no = apidt.po_no
                     AND   (apidt.rs_no LIKE 'M%' OR apidt.rs_no LIKE 'O%')
                     AND    apidt.ap_no = p_ap_no
                     UNION ALL
                     SELECT 'PHP'
                     FROM   acc_ap_inv_dtl apidt, inv_jo_hdr johd 
                     WHERE  apidt.is_selected= 'Y'
                     AND    johd.jo_no = apidt.po_no
                     AND   (apidt.rs_no NOT LIKE 'M%' AND apidt.rs_no NOT LIKE 'O%')
                     AND    apidt.ap_no = p_ap_no
                     UNION ALL
                     SELECT apidt.invoice_curr
                     FROM   acc_ap_oth_dtl apidt
                     WHERE  apidt.is_selected= 'Y'
                     AND    apidt.AP_NO = p_ap_no )
          loop
             vCurr := a.currency;
             exit;
          end loop;
       end if;

       if a.ref_type = 'CV' then
          for b1 in ( select cpdt.acco_code, cpdt.amount, cpdt.cpa_no 
                      from   acc_cv_cpa_dtl cvcp, acc_cpa_dtl cpdt
                      where  cpdt.acco_code in (vSus_Acct, vAdv_acct)
                      and    cvcp.cv_no    = a.ref_code
                      and    cpdt.cpa_no   = cvcp.cpa_no
                      and    cpdt.ref_type = a.inv_type
                      and    cpdt.ref_code = a.po_no )
          loop
             if b1.acco_code = vSus_Acct then
                nSus    := nSus    + b1.amount;
                nSusPhp := nSusPhp + b1.amount;
             end if;
             if b1.acco_code = vAdv_acct then
                if vCurr <> 'PHP' then
                   begin
                      select h.cv_date 
                      into   dCurrDate
                      from   acc_cv_cpa_dtl a, acc_cv_hdr h 
                      where  h.cv_no = a.cv_no 
                      and    a.cpa_no = b1.cpa_no
                      and   rownum = 1;
                   exception
                      when others then   
                         RAISE_APPLICATION_ERROR(-20002, 'Error getting CV date...');      
                   end;
                   nForex := sf_get_fx_rate (vCurr, dCurrDate);
                   nAdv   := nAdv    + (b1.amount/nForex);
                else
                   nAdv    := nAdv    + b1.amount;
                end if;
                nAdvPhp := nAdvPhp + b1.amount;
             end if;
          end loop;
       end if;

       if a.ref_type = 'JV' then
          for b1 in ( select acco_code, debit, debit_php from acc_jv_dtl
                      where  acco_code in (vSus_Acct, vAdv_acct)
                      and    jv_no = a.ref_code
                      and    ref_type = a.inv_type
                      and    ref_code = a.po_no )
          loop
             if b1.acco_code = vSus_Acct then
                nSus    := nSus    + b1.debit;
                nSusPhp := nSusPhp + b1.debit_php;
             end if;
             if b1.acco_code = vAdv_acct then
                nAdv    := nAdv    + b1.debit;
                nAdvPhp := nAdvPhp + b1.debit_php;
             end if;
          end loop;
       end if;
       
       if a.ref_type = 'AP' then
          nAdv    := nAdv    + a.adv_amount;
          nAdvPhp := nAdvPhp + a.adv_amount_php;
       end if;

       if a.ref_type = 'PCV' then
          for b1 in  ( select amt
                       from   acc_pcv_dtl pcdt
                       where  pcdt.acco_code = vAdv_acct
                       and    pcdt.pcv_no    = a.ref_code )
          loop
             nAdv    := nAdv    + a.adv_amount;
             nAdvPhp := nAdvPhp + a.adv_amount_php; 
             exit;
          end loop;
       end if;
   end loop;
   --40004
   --10010
   
   nSus1    := nSus;
   nSusPhp1 := nSusPhp;
   nAdv1    := nAdv;
   nAdvPhp1 := nAdvPhp;
   
   if nSus <> 0 and nSusPhp <> 0 then         
      nitem := nitem + 1; 
      
      if vTotal_FX_Amount < nSus then
          nSus1 := vTotal_FX_Amount;
      end if;
      if vTotal_Amount < nSusPhp then
          nSusPhp1 := vTotal_Amount;
      end if;
        
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vSus_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
               0, nSus1, 0, nSusPhp1, user, sysdate);
   end if;
   
   if nAdv <> 0 and nAdvPhp <> 0 then
      nitem := nitem + 1; 
      if (vTotal_FX_Amount - nvl(nSus,0)) < nAdv then
          nAdv1 := (vTotal_FX_Amount - nvl(nSus,0));
      end if;
      if (vTotal_Amount - nvl(nSusPhp,0)) < nAdvPhp then
          nAdvPhp1 := (vTotal_Amount - nvl(nSusPhp,0));
      end if;
        
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc, 
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vAdv_acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType, 
               0, nAdv1, 0, nAdvPhp1, user, sysdate);
   end if;
   
   vUnused_Adv     := greatest(((nAdv + nSus)-(vTotal_FX_Amount)),0);
   vUnused_Adv_Php := greatest(((nAdvPhp + nSusPhp)-(vTotal_Amount)),0);
   
   -- get unused advance payments from APV
   for a in  ( select unused_adv, unused_adv_php
               from   acc_ap_hdr
               where  ap_status = 'APPROVED'
               and    ap_no > vRef_AP_No
               and    ap_no < p_ap_no
               and    unused_adv > 0
               and    unused_adv_php > 0
               order  by ap_no desc )
   loop
     vUnused_Adv     := vUnused_Adv + a.unused_adv;
     vUnused_Adv_Php := vUnused_Adv_Php + a.unused_adv_php;
     exit;
   end loop;
   commit;
END sp_acc_apv_post_inv;
/

create public synonym sp_acc_apv_post_inv for sp_acc_apv_post_inv;
create public synonym sp_acc_apv_download_inv for sp_acc_apv_download_inv;
create public synonym sp_acc_get_rr_discount for sp_acc_get_rr_discount;

grant execute on sp_acc_apv_post_inv to TPJ_ACC_SUPER_USER;
grant execute on sp_acc_apv_download_inv to TPJ_ACC_SUPER_USER;
grant execute on sp_acc_get_rr_discount to TPJ_ACC_SUPER_USER;

grant execute on sp_acc_apv_post_inv to TPJ_ACC_AP_WRITE;
grant execute on sp_acc_apv_download_inv to TPJ_ACC_AP_WRITE;
grant execute on sp_acc_get_rr_discount to TPJ_ACC_AP_WRITE;
