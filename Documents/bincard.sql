alter table inv_reqslip_hdr add ofc_code varchar2(16) default 'HO';
alter table inv_iss_hdr add ofc_code varchar2(16) default 'HO';
alter table inv_dr_hdr add ofc_code varchar2(16) default 'HO';

CREATE OR REPLACE FUNCTION sf_get_user_ofc(p_username VARCHAR2)
RETURN VARCHAR2 AS
   vOfc pms_employees.ofc_code%type;
   vEID pms_employees.empl_id%type;
BEGIN
   BEGIN
     SELECT ofc_code, empl_id
     INTO   vOfc, vEID
     FROM   PMS_EMPLOYEES
     WHERE  user_code = p_username;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN null;
   END;

   IF vOfc is null THEN
      vOfc := 'HO';
   END IF;
   RETURN vOfc;

END sf_get_user_ofc;


CREATE FUNCTION sf_get_rs_ofc(p_rs_no VARCHAR2)
RETURN VARCHAR2 AS
   vOfc inv_reqslip_hdr.ofc_code%type;
BEGIN
   BEGIN
     SELECT ofc_code
     INTO   vOfc
     FROM   inv_reqslip_hdr
     WHERE  rs_no = p_rs_no;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN null;
   END;

   IF vOfc is null THEN
      vOfc := 'HO';
   END IF;
   RETURN vOfc;

END sf_get_rs_ofc;


CREATE OR REPLACE TRIGGER "TPJ".INV_REQSLIP_HDR_TRG
BEFORE DELETE OR INSERT OR UPDATE
ON INV_REQSLIP_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF INSERTING THEN
     :NEW.ofc_code := sf_get_user_ofc(user);
     insert into inv_reqslip_hdr_log
     values (:new.rs_no, null, :new.status, null, :new.dept_code, null, :new.for_stock, sysdate, user, 'I');
   END IF;
   IF UPDATING THEN
     insert into inv_reqslip_hdr_log
     values (:new.rs_no, :old.status, :new.status, :old.dept_code, :new.dept_code, :old.for_stock, :new.for_stock, sysdate, user, 'U');
   END IF;
END;


CREATE OR REPLACE TRIGGER TPJ.inv_iss_hdr_ins_trg
BEFORE INSERT
ON INV_ISS_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   :NEW.ofc_code := sf_get_rs_ofc(:NEW.rshd_rs_no);
END;


CREATE OR REPLACE TRIGGER TPJ.inv_dr_hdr_ins_trg
BEFORE INSERT
ON INV_DR_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   declare 
      vRSNO Varchar2(30);
   begin
      select rshd_rs_no 
      into   vRSNO
      from   inv_po_hdr
      where  po_no = :NEW.pohd_po_no;
      :NEW.ofc_code := sf_get_rs_ofc(vRSNO);
   exception
      when no_data_found then :NEW.ofc_code := 'HO';
   end;
END;






CREATE OR REPLACE VIEW INV_STOCKS AS
SELECT 'DR' "TRAN_TYPE", drhd.dr_no ref_no, drdt.item_code, drdt.cate_code
       , drdt.itty_code, drdt.itgr_code, drdt.uome_code, drdt.qty
       , drdt.currency, drdt.unit_cost
       , drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --drhd.dt_created ,
         nvl(drhd.dt_modified,drhd.dt_created) dt_created, drhd.supp_code "REFERENCE"
       , drhd.ofc_code
  FROM   inv_dr_dtl drdt, inv_dr_hdr drhd
  WHERE  drhd.dr_no = drdt.drhd_dr_no AND drhd.status = 'POSTED'
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code, isdt.iss_qty, drdt.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --ishd.dt_created,
         ishd.dt_modified dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_dr_dtl drdt, inv_dr_hdr drhd
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    isdt.ref_type = 'DR'
  AND    isdt.ref_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    ishd.status = 'APPROVED'
  AND    drdt.item_code = isdt.item_code
  AND    drdt.cate_code = isdt.cate_code
  AND    drdt.itty_code = isdt.itty_code
  AND    drdt.itgr_code = isdt.itgr_code
  AND    drdt.uome_code = isdt.uome_code
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code, isdt.iss_qty, iware.currency
       , iware.unit_cost, iware.unit_cost unit_cost_php
       ,
         --ishd.dt_created,
         nvl(ishd.dt_modified,ishd.dt_created) dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_item_ware iware
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    ishd.status = 'APPROVED'
  AND    isdt.item_code = iware.item_code
  AND    isdt.cate_code = iware.cate_code
  AND    isdt.itty_code = iware.itty_code
  AND    isdt.itgr_code = iware.itgr_code
  AND    isdt.uome_code = iware.uome_code
  AND    isdt.rshd_rs_no <> 'M000000'
  --and    isdt.item_code = 'RICE'
  AND    isdt.ref_type = 'WR'
  AND    isdt.ref_no = iware.ware_code
  AND    isdt.dr_no = iware.dr_no
  AND    isdt.dr_no = 'STOCK'
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code, isdt.iss_qty, iware.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --ishd.dt_created,
         nvl(ishd.dt_modified,ishd.dt_created) dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt
       , inv_iss_hdr ishd
       , inv_item_ware iware
       , inv_dr_dtl drdt
       , inv_dr_hdr drhd
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    ishd.status = 'APPROVED'
  AND    isdt.item_code = iware.item_code
  AND    isdt.cate_code = iware.cate_code
  AND    isdt.itty_code = iware.itty_code
  AND    isdt.itgr_code = iware.itgr_code
  AND    isdt.uome_code = iware.uome_code
  --and    isdt.item_code = 'RICE'
  AND    isdt.ref_type = 'WR'
  AND    isdt.ref_no = iware.ware_code
  AND    isdt.dr_no = iware.dr_no
  AND    drhd.dr_no = iware.dr_no
  AND    isdt.dr_no <> 'STOCK'
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    drdt.item_code = isdt.item_code
  AND    drdt.cate_code = isdt.cate_code
  AND    drdt.itty_code = isdt.itty_code
  AND    drdt.itgr_code = isdt.itgr_code
  AND    drdt.uome_code = isdt.uome_code
  UNION ALL
  SELECT 'RET', rthd.ret_no, rtdt.item_code, rtdt.cate_code, rtdt.itty_code
       , rtdt.itgr_code, rtdt.uome_code, rtdt.returned_qty, drdt.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --rthd.dt_created,
         nvl(rthd.dt_modified,rthd.dt_created) dt_created, rthd.supp_code
       , drhd.ofc_code
  FROM   inv_retslip_dtl rtdt
       , inv_retslip_hdr rthd
       , inv_dr_dtl drdt
       , inv_dr_hdr drhd
  WHERE  rtdt.rthd_ret_no = rthd.ret_no
  AND    rtdt.drhd_dr_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    rthd.status = 'APPROVED'
  AND    drdt.item_code = rtdt.item_code
  AND    drdt.cate_code = rtdt.cate_code
  AND    drdt.itty_code = rtdt.itty_code
  AND    drdt.itgr_code = rtdt.itgr_code
  AND    drdt.uome_code = rtdt.uome_code
  UNION ALL
  SELECT 'TRANSFER', sthd.st_no, stdt.item_code, stdt.cate_code
       , stdt.itty_code, stdt.itgr_code, stdt.uome_code, stdt.qty
       , NVL ( drdt.currency, 'PHP' ), NVL ( drdt.unit_cost, 0 )
       , drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --sthd.dt_created ,
         nvl(sthd.dt_modified,sthd.dt_created) dt_created, sthd.ware_code
       , drhd.ofc_code
  FROM   inv_st_dtl stdt, inv_st_hdr sthd, inv_dr_dtl drdt, inv_dr_hdr drhd
  WHERE  stdt.sthd_st_no = sthd.st_no
  AND    stdt.dr_no = drhd.dr_no
 
  AND    stdt.dr_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    sthd.status = 'APPROVED'
  AND    sthd.rehd_re_no <> '000000'
  AND    drdt.item_code = stdt.item_code
  AND    drdt.cate_code = stdt.cate_code
  AND    drdt.itty_code = stdt.itty_code
  AND    drdt.itgr_code = stdt.itgr_code
  AND    drdt.uome_code = stdt.uome_code
  UNION ALL
  SELECT 'TRANSFER', sthd.st_no, stdt.item_code, stdt.cate_code
       , stdt.itty_code, stdt.itgr_code, stdt.uome_code, stdt.qty, 'PHP', 0
       , 0 unit_cost_php,
                         --sthd.dt_created ,
                         sthd.dt_modified dt_created, sthd.ware_code
       , 'HO' ofc_code
  FROM   inv_st_dtl stdt, inv_st_hdr sthd
  WHERE  stdt.sthd_st_no = sthd.st_no
  AND    sthd.status = 'APPROVED'
  AND    sthd.rehd_re_no <> '000000'
  UNION ALL
  SELECT 'TRANSFERH', sthd.st_no, stdt.item_code, stdt.cate_code
       , stdt.itty_code, stdt.itgr_code, stdt.uome_code, stdt.qty, 'PHP', 0
       , 0 unit_cost_php,
                         --sthd.dt_created ,
                         nvl(sthd.dt_modified,sthd.dt_created) dt_created, sthd.ware_code
       , 'HO' ofc_code
  FROM   inv_st_dtl stdt, inv_st_hdr sthd
  WHERE  stdt.sthd_st_no = sthd.st_no
  AND    sthd.status = 'APPROVED'
  AND    sthd.rehd_re_no = '000000'
  UNION ALL
  SELECT 'BEG_BAL', '00000', iwbb.item_code, iwbb.cate_code
       , iwbb.itty_code, iwbb.itgr_code, iwbb.uome_code, iwbb.qty, 'PHP', 0
       , 0 unit_cost_php,
                         --iwbb.dt_created ,
                         iwbb.posted_dt dt_created, iwbb.ware_code
       , 'HO' ofc_code
  FROM   inv_item_ware_begbal iwbb
  WHERE  iwbb.posted_dt is not null
  and    iwbb.dr_no = '000000'
/






CREATE OR REPLACE VIEW INV_STOCKS_SUMMARY AS
SELECT   tran_type, ref_no, dt_created, item_code, cate_code, itty_code
         , itgr_code, uome_code, currency, unit_cost
         , DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) out_qty
         , DECODE (tran_type, 'DR',  qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) in_qty
         , SUM  ( DECODE ( tran_type, 'DR', qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance
         , DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) out_cost
         , DECODE (tran_type, 'DR', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) in_cost
         , SUM ( DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost
         , DECODE (tran_type, 'ISS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'RET', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) out_cost_php
         , DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) in_cost_php
         , SUM ( DECODE ( tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost_php
         , REFERENCE
         , OFC_CODE
  FROM     inv_stocks
  ORDER BY item_code
         , cate_code
         , itty_code
         , itgr_code
         , uome_code
         , dt_created
         , tran_type
/





