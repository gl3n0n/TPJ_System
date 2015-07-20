CREATE OR REPLACE VIEW ACC_SUPPLIER_LEDGER_DTL AS
SELECT   i_inv_type, i_rr_date, i_payee_type, i_supp_code, i_po_no
         , i_amount, i_ap_no, i_rr_no, i_rs_no, i_inv_no, i_rr_amt
         , i_is_selected
  FROM     ( SELECT 'PO' i_inv_type
                  , DECODE (
                      NVL ( aaid.is_selected, 'N' )
                    , 'Y', aaid.ap_no
                    , 999999999999
                    ) i_ap_no
                  , drhd.dr_no i_rr_no, 'SUPP' i_payee_type
                  , drhd.supp_code i_supp_code, drhd.rs_no i_rs_no
                  , NVL ( drhd.invoice_no, drhd.supp_dr_no ) i_inv_no
                  , NVL ( drhd.invoice_dt, drhd.dr_date ) i_rr_date
                  , drhd.rr_amt i_rr_amt, aaid.is_selected i_is_selected
                  , drhd.po_no i_po_no
                  , NVL ( DECODE (
                        aaid.is_selected
                      , 'Y', aaid.amount
                      , 0
                      )
                    , 0 ) i_amount
            FROM   acc_inv_rr_dtl drhd, acc_ap_inv_dtl aaid, acc_ap_hdr aphd
            WHERE  drhd.dr_no = aaid.rr_no
            AND    aphd.ap_no = aaid.ap_no
            AND    aphd.inv_type = 'PO'
            AND    aphd.ap_status <> 'CANCELLED'
            UNION ALL
            SELECT 'PO' i_inv_type, 999999999999 i_ap_no, drhd.dr_no i_rr_no
                 , 'SUPP' i_payee_type, drhd.supp_code i_supp_code
                 , drhd.rs_no i_rs_no
                 , NVL ( drhd.invoice_no, drhd.supp_dr_no ) i_inv_no
                 , NVL ( drhd.invoice_dt, drhd.dr_date ) i_rr_date
                 , drhd.rr_amt i_rr_amt, NULL i_is_selected
                 , drhd.po_no i_po_no, 0 i_amount
            FROM   acc_inv_rr_dtl drhd
            WHERE  NOT EXISTS (SELECT 1
                               FROM   acc_ap_inv_dtl aaid, acc_ap_hdr aphd
                               WHERE  drhd.dr_no = aaid.rr_no
                               AND    aphd.ap_no = aaid.ap_no
                               AND    aphd.inv_type = 'PO'
                               AND    aphd.ap_status <> 'CANCELLED' )
            UNION ALL
            SELECT 'JO' i_inv_type
                 , DECODE (
                     NVL ( aaid.is_selected, 'N' )
                   , 'Y', aaid.ap_no
                   , 999999999999
                   ) i_ap_no
                 , drhd.jo_dr_no i_rr_no, 'SUPP' i_payee_type
                 , drhd.supp_code i_supp_code
                 , ( SELECT jshd_js_no
                    FROM   inv_jo_hdr
                    WHERE  jo_no = johd_jo_no ) i_rs_no
                 , drhd.supp_dr_no i_inv_no
                 , NVL ( drhd.invoice_dt, drhd.jo_dr_date ) i_rr_date
                 , sf_get_repair_cost ( johd_jo_no ) i_rr_amt
                 , aaid.is_selected i_is_selected, drhd.johd_jo_no i_po_no
                 , NVL ( DECODE (
                       aaid.is_selected
                     , 'Y', aaid.amount
                     , 0
                     )
                   , 0 ) i_amount
            FROM   inv_jo_dr_hdr drhd, acc_ap_inv_dtl aaid, acc_ap_hdr aphd
            WHERE  drhd.jo_dr_no = aaid.rr_no AND drhd.status = 'APPROVED'
            AND    aphd.ap_no = aaid.ap_no
            AND    aphd.inv_type = 'JO'
            AND    aphd.ap_status <> 'CANCELLED'
            UNION ALL
            SELECT 'JO' i_inv_type, 999999999999 i_ap_no
                 , drhd.jo_dr_no i_rr_no, 'SUPP' i_payee_type
                 , drhd.supp_code i_supp_code
                 , ( SELECT jshd_js_no
                    FROM   inv_jo_hdr
                    WHERE  jo_no = johd_jo_no ) i_rs_no
                 , drhd.supp_dr_no i_inv_no
                 , NVL ( drhd.invoice_dt, drhd.jo_dr_date ) i_rr_date
                 , sf_get_repair_cost ( johd_jo_no ) i_rr_amt
                 , NULL i_is_selected, drhd.johd_jo_no i_po_no, 0 i_amount
            FROM   inv_jo_dr_hdr drhd
            WHERE  NOT EXISTS ( SELECT 1
                               FROM   acc_ap_inv_dtl aaid, acc_ap_hdr aphd
                               WHERE  drhd.jo_dr_no = aaid.rr_no
                               AND    aphd.ap_no = aaid.ap_no
                               AND    aphd.inv_type = 'JO'  
                               AND    aphd.ap_status <> 'CANCELLED')
            AND    drhd.status = 'APPROVED'
            UNION ALL
            SELECT 'OTHERS' i_inv_type
                 , DECODE (
                     NVL ( aaid.is_selected, 'N' )
                   , 'Y', aaid.ap_no
                   , 999999999999
                   ) i_ap_no
                 , NULL i_rr_no, aphd.ap_payee_type
                 , aphd.ap_payee_code i_supp_code, NULL i_rs_no
                 , aaid.invoice_no i_inv_no, aaid.invoice_date i_rr_date
                 , aaid.invoice_amount i_rr_amt
                 , aaid.is_selected i_is_selected, NULL i_po_no
                 , NVL ( DECODE (
                       aaid.is_selected
                     , 'Y', aaid.amount
                     , 0
                     )
                   , 0 ) i_amount
            FROM   acc_ap_oth_dtl aaid, acc_ap_hdr aphd
            WHERE  aphd.ap_no = aaid.ap_no 
            AND    aphd.ap_status <> 'CANCELLED')
  ORDER BY i_rr_date 
