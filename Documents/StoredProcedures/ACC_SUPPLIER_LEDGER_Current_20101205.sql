CREATE OR REPLACE VIEW ACC_SUPPLIER_LEDGER AS
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       ,
         --acc_cv_check_dtl ccdt,
         acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvhd.cv_no not in (select cv_no from acc_cv_dtl cvdt where cvdt.cv_no = cvhd.cv_no and cvdt.acco_code = '60005')
  UNION ALL
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cv_check_dtl ccdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  ccdt.cv_no = cvhd.cv_no
  AND    cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '60005'
  UNION ALL
  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, pchd.pcv_no, 'PCV', NULL, NULL
       , pchd.pcv_date, pcid.amount, 0, null
  FROM   acc_pcv_inv_dtl pcid, acc_pcv_hdr pchd, inv_po_hdr pohd
  WHERE  pchd.pcv_no = pcid.pcv_no
  AND    pchd.pcv_status = 'REPLENISHED'
  AND    pcid.amount > 0
  AND    pohd.po_no = pcid.po_no
  UNION ALL

  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit debit, 0 credit , null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , johd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_jo_hdr johd
  WHERE  jvdt.ref_type = 'JO'
  AND    jvdt.ref_code = johd.jo_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_po_hdr pohd
  WHERE  jvdt.ref_type = 'PO'
  AND    jvdt.ref_code = pohd.po_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT   cvhd.cv_date i_rr_date, aphd.ap_payee_type
         , aphd.ap_payee_code i_supp_code, NULL i_po_no, 0 i_amount
         , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no
         , 0 i_rr_amt, NULL i_is_selected, NULL i_inv_type, cvhd.cv_no, 'CV'
         , NULL, NULL, NULL
         , SUM ( DECODE (
               apdt.acco_code
             , '60001', apdt.credit
             , 0
             ) ) ap_amt
         , SUM ( DECODE (
               apdt.acco_code
             , '60005', apdt.credit
             , 0
             ) ) ap_ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  FROM     acc_ap_hdr aphd
         , acc_ap_dtl apdt
         , acc_cv_hdr cvhd
         ,
           --acc_cv_check_dtl cvcd,
           acc_cpa_dtl cpdt
         , acc_cpa_hdr cphd
         , acc_cv_cpa_dtl cvcp
  WHERE    aphd.ap_no = apdt.ap_no(+)
--and     cvhd.cv_no = cvcd.cv_no
  AND      cvcp.cv_no = cvhd.cv_no
  AND      cphd.cpa_no = cpdt.cpa_no
  AND      cphd.cpa_no = cvcp.cpa_no
  AND      cpdt.ref_type = 'APV'
  AND      cpdt.ref_code = aphd.ap_no
  AND      aphd.ap_status = 'APPROVED'
  AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
  GROUP BY cvhd.cv_no, cvhd.cv_date, aphd.ap_payee_type, aphd.ap_payee_code, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  UNION ALL
  SELECT i_rr_date, i_payee_type, i_supp_code, i_po_no, i_amount, i_ap_no
       , i_rr_no, i_rs_no, i_inv_no, i_rr_amt, i_is_selected, i_inv_type
       , NULL, NULL, NULL, NULL, NULL, 0, 0, null
  FROM   acc_supplier_ledger_dtl

