CREATE OR REPLACE VIEW ACC_INV_PCV_DTL AS
SELECT po_no,
       rs_no rshd_rs_no,
       po_date,
       sum(po_amt) po_amt,
       sum(pcv_amt) pcv_amt
from (
-- PO
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       SUM(approved_qty*unit_cost*((100-discount)/100)) po_amt,
       pohd.pcv_amt pcv_amt,
       'PO# ' || pohd.po_no ref_src
FROM   INV_PO_HDR pohd, INV_PO_DTL podt
WHERE  pohd.po_no = podt.pohd_po_no
AND    pohd.status = 'APPROVED'
AND    pohd.po_date > add_months(sysdate, -12)
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'PO' || pohd.po_no)
GROUP BY pohd.rshd_rs_no, pohd.po_no, pohd.po_date, pohd.pcv_amt
HAVING SUM(approved_qty*unit_cost*((100-discount)/100)) > pohd.pcv_amt
UNION ALL
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       0 po_amt,
       cpdt.amount pcv_amt,
       'CPA ' || to_char(cpdt.cpa_no) ref_src
FROM   acc_cpa_dtl cpdt, acc_cpa_hdr cphd, inv_po_hdr pohd
WHERE  cpdt.ref_code = pohd.po_no
AND    pohd.po_date > add_months(sysdate, -12)
AND    cpdt.cpa_no = cphd.cpa_no
AND    cpdt.ref_type = 'PO'
AND    cphd.cpa_status <> 'CANCELLED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'PO' || pohd.po_no)
UNION ALL
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       0 po_amt,
       apin.amount pcv_amt,
       'AP# ' || to_char(aphd.ap_no) ref_src
FROM   acc_ap_hdr aphd, inv_po_hdr pohd, acc_ap_inv_dtl apin
WHERE  apin.po_no = pohd.po_no
and    pohd.po_date > add_months(sysdate, -12)
AND    aphd.ap_no = apin.ap_no
and    apin.is_selected = 'Y'
and    apin.amount > 0
AND    aphd.ap_status <> 'CANCELLED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'PO' || pohd.po_no)
UNION ALL
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       0 po_amt,
       jvdt.debit_php pcv_amt,
       'JV# ' || to_char(jvhd.jv_no) ref_src
FROM   acc_jv_dtl jvdt, acc_jv_hdr jvhd, inv_po_hdr pohd
WHERE  jvdt.jv_no = jvhd.jv_no
AND    pohd.po_date > add_months(sysdate, -12)
AND    jvdt.ref_type = 'PO'
AND    jvdt.ref_code = pohd.po_no
AND    jvdt.debit_php > 0
AND    jvdt.acco_code = '40004'
AND    jvhd.jv_status <> 'CANCELLED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'PO' || pohd.po_no)
-- JO
UNION ALL
SELECT 'JO' || johd.jo_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       SUM(jodt.qty*jodt.unit_price*DECODE(jodt.cate_code,'LBR',((100-labor_discount)/100),((100-matrl_discount)/100))) po_amt,
       johd.pcv_amt pcv_amt,
       'JO' || johd.jo_no ref_src
FROM   inv_jo_hdr johd, inv_jo_dtl jodt
WHERE  johd.jo_no = jodt.johd_jo_no
AND    johd.jo_date > add_months(sysdate, -12)
AND    johd.status = 'APPROVED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'JO' || johd.jo_no)
GROUP BY johd.jshd_js_no, johd.jo_no, johd.jo_date, johd.pcv_amt
HAVING SUM(jodt.qty*jodt.unit_price*DECODE(jodt.cate_code,'LBR',((100-labor_discount)/100),((100-matrl_discount)/100))) > johd.pcv_amt
UNION ALL
SELECT 'JO' || johd.jo_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       0 po_amt,
       cpdt.amount pcv_amt,
       'CPA ' || to_char(cpdt.cpa_no) ref_src
FROM   acc_cpa_dtl cpdt, acc_cpa_hdr cphd, inv_jo_hdr johd
WHERE  cpdt.cpa_no = cphd.cpa_no
AND    johd.jo_date > add_months(sysdate, -12)
AND    cpdt.ref_type = 'JO'
AND    cpdt.ref_code = johd.jo_no
AND    cphd.cpa_status <> 'CANCELLED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'JO' || johd.jo_no)
UNION ALL
SELECT apin.po_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       0 po_amt,
       apin.amount pcv_amt,
       'AP# ' || to_char(aphd.ap_no) ref_src
FROM   acc_ap_hdr aphd, acc_ap_inv_dtl apin, inv_jo_hdr johd
WHERE  aphd.ap_no = apin.ap_no
and    johd.jo_date > add_months(sysdate, -12)
AND    ('JO' || johd.jo_no) = apin.po_no
and    apin.amount > 0
and    apin.is_selected = 'Y'
and    apin.po_no like 'JO%'
AND    aphd.ap_status <> 'CANCELLED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = johd.jo_no)
UNION ALL
SELECT 'JO' || johd.jo_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       0 po_amt,
       jvdt.debit_php pcv_amt,
       'JV# ' || to_char(jvhd.jv_no) ref_src
FROM   acc_jv_dtl jvdt, acc_jv_hdr jvhd, inv_jo_hdr johd
WHERE  jvdt.jv_no = jvhd.jv_no
AND    johd.jo_date > add_months(sysdate, -12)
AND    jvdt.ref_type = 'JO'
AND    jvdt.ref_code = johd.jo_no
AND    jvdt.debit_php > 0
AND    jvdt.acco_code = '40004'
AND    jvhd.jv_status <> 'CANCELLED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'JO' || johd.jo_no)
) GROUP BY po_no,
        rs_no,
        po_date
/

create index pcid_idx on acc_pcv_inv_dtl (po_no)
/

create index cpdt_ref_idx on acc_cpa_dtl(ref_type, ref_code)
/

create index apin_po_idx on acc_ap_inv_dtl (po_no)
/



