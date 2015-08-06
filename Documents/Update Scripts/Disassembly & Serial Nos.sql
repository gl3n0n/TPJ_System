grant SELECT ANY DICTIONARY to tpj;
create or replace function sf_is_conceal_amount ( 
   p_user in VARCHAR2
)  RETURN VARCHAR2 IS
   vIsConceal char(1) := 'N';
   vStr varchar2(512);
BEGIN
   BEGIN
      select 'Y'
      into   vIsConceal
      from   dba_role_privs
      where  granted_role = 'TPJ_INV_CONCEAL_AMOUNT'
      and    grantee = p_user;
   EXCEPTION
      when no_data_found then 
         vIsConceal := 'N';
   END;
   return vIsConceal;
END sf_is_conceal_amount;
/
show err

create public synonym sf_is_conceal_amount for sf_is_conceal_amount;
select 'grant execute on sf_is_conceal_amount ' || role || ';' from dba_roles where role like 'TPJ_INV%';

alter table inv_po_dtl add core_charge NUMBER(12,4) default 0;
alter table inv_vessels add (downloaded varchar2(1) default 'N', dt_downloaded date);
alter table inv_warehouse add (downloaded varchar2(1) default 'N', dt_downloaded date);
alter table pms_employees add (downloaded varchar2(1) default 'N', dt_downloaded date);



DROP TABLE INV_DISASSEMBLY_DTL;
CREATE TABLE INV_DISASSEMBLY_DTL
   (ITTY_CODE VARCHAR2(16) NOT NULL,
    CATE_CODE VARCHAR2(16) NOT NULL,
    ITGR_CODE VARCHAR2(16) NOT NULL,
    ITEM_CODE VARCHAR2(16) NOT NULL,
    STATUS VARCHAR2(12) DEFAULT 'FOR APPROVAL' NOT NULL,
    UOME_CODE VARCHAR2(16) NOT NULL,
    NEW_ITEM VARCHAR2(16) NOT NULL,
    NEW_NAME VARCHAR2(128) NOT NULL,
    NEW_UOME VARCHAR2(16) NOT NULL,
    NEW_CATE VARCHAR2(16) NOT NULL,
    NEW_ITTY VARCHAR2(16) NOT NULL,
    NEW_ITGR VARCHAR2(16) NOT NULL,
    ACCE_CODE VARCHAR2(16),
    BRAN_CODE VARCHAR2(16),
    COLO_CODE VARCHAR2(16),
    MATE_CODE VARCHAR2(16),
    MODL_CODE VARCHAR2(16),
    SHAP_CODE VARCHAR2(16),
    ISZE_CODE VARCHAR2(16),
    SOUR_CODE VARCHAR2(16),
    VOLT_CODE VARCHAR2(16),
    ILOC_CODE VARCHAR2(16),
    TYPE_CODE VARCHAR2(16),
    SERIAL_NO VARCHAR2(64),
    PART_NO VARCHAR2(64),
    QTY NUMBER(12,4) DEFAULT 0 NOT NULL,
    REMARKS VARCHAR2(128),
    CREATED_BY VARCHAR2(32) NOT NULL,
    DT_CREATED DATE NOT NULL,
    MODIFIED_BY VARCHAR2(32),
    DT_MODIFIED DATE,
    APPROVED_BY VARCHAR2(32),
    DT_APPROVED DATE,
    CANCELLED_BY VARCHAR2(32),
    DT_CANCELLED DATE,
     CONSTRAINT RSDA_PK PRIMARY KEY (CATE_CODE, ITTY_CODE, ITGR_CODE, ITEM_CODE, NEW_ITEM, NEW_UOME),
     CONSTRAINT RSDA_ITEM_FK FOREIGN KEY (CATE_CODE, ITTY_CODE, ITGR_CODE, ITEM_CODE)
      REFERENCES INV_ITEMS (CATE_CODE, ITTY_CODE, ITGR_CODE, CODE),
     CONSTRAINT RSDA_UOME_FK FOREIGN KEY (UOME_CODE)
      REFERENCES INV_UNIT_OF_MEASURE (CODE),
     CONSTRAINT RSDA_NEW_UOME_FK FOREIGN KEY (NEW_UOME)
      REFERENCES INV_UNIT_OF_MEASURE (CODE)
   );

create public synonym INV_DISASSEMBLY_DTL for INV_DISASSEMBLY_DTL;
select 'grant select on INV_DISASSEMBLY_DTL to ' || role || ';' from dba_roles where role like 'TPJ_INV%READ';
select 'grant select,insert,update,delete on INV_DISASSEMBLY_DTL to ' || role || ';' sql_text from dba_roles where role like 'TPJ_INV%WRITE';
grant select,insert,update,delete on INV_DISASSEMBLY_DTL to TPJ_INV_SUPER_USER;


create or replace view inv_iss_vw as
select a.iss_no, a.iss_date, a.status, a.vess_code, 
       b.rshd_rs_no rs_no, b.item_code, b.cate_code, b.itty_code, b.itgr_code, b.uome_code, b.iss_qty, 
       b.re_qty, b.tr_qty, a.dt_approved, a.dt_received, b.ref_type, b.ref_no, b.dr_no, a.received_by
from inv_iss_hdr a, inv_iss_dtl b
where a.iss_no = b.ishd_iss_no
and   a.status <> 'CANCELLED';


CREATE TABLE INV_ITEM_SERIAL_NOS (
  SEQ_NO NUMBER NOT NULL,
  ISS_NO VARCHAR2(16) NOT NULL,
  REF_TYPE VARCHAR2(16) NOT NULL,
  REF_NO VARCHAR2(16) NOT NULL,
  DR_NO VARCHAR2(16) NOT NULL,
  ITTY_CODE VARCHAR2(16) NOT NULL,
  CATE_CODE VARCHAR2(16) NOT NULL,
  ITGR_CODE VARCHAR2(16) NOT NULL,
  ITEM_CODE VARCHAR2(16) NOT NULL,
  UOME_CODE VARCHAR2(16) NOT NULL,
  VESS_CODE VARCHAR2(16) NOT NULL,
  SERIAL_NO VARCHAR2(64),
  PART_NO VARCHAR2(64),
  QTY NUMBER(12,4) DEFAULT 0 NOT NULL,
  REMARKS VARCHAR2(128),
  CREATED_BY VARCHAR2(32) NOT NULL,
  DT_CREATED DATE NOT NULL,
  MODIFIED_BY VARCHAR2(32),
  DT_MODIFIED DATE,
   CONSTRAINT IISN_PK PRIMARY KEY (SEQ_NO),
   CONSTRAINT IISN_UK unique (ITEM_CODE,UOME_CODE,SERIAL_NO,PART_NO)
);

CREATE SEQUENCE INV_ITEM_SERIAL_NOS_SEQ minvalue 1 maxvalue 999999999999999999999999999 start with 1 increment by 1 nocache;

create public synonym INV_ITEM_SERIAL_NOS for INV_ITEM_SERIAL_NOS;
create public synonym INV_ITEM_SERIAL_NOS_SEQ for INV_ITEM_SERIAL_NOS_SEQ;


select 'grant select on INV_ITEM_SERIAL_NOS to ' || role || ';' from dba_roles where role like 'TPJ_INV%READ' union
select 'grant select on INV_ITEM_SERIAL_NOS_SEQ to ' || role || ';' from dba_roles where role like 'TPJ_INV%READ' union
select 'grant select,insert,update,delete on INV_ITEM_SERIAL_NOS to ' || role || ';' sql_text from dba_roles where role like 'TPJ_INV%WRITE' union
select 'grant select on INV_ITEM_SERIAL_NOS_SEQ to ' || role || ';' sql_text from dba_roles where role like 'TPJ_INV%WRITE';
grant select,insert,update,delete on INV_ITEM_SERIAL_NOS to TPJ_INV_SUPER_USER;
grant select on INV_ITEM_SERIAL_NOS_SEQ to TPJ_INV_SUPER_USER;





Add Serial# and Part# on RS and PO, RecievingRR, Issuance.
Add alert/notification on RS if serial# entered is not for the vessel.
Add delete on Serial no entries...
Create new role for Accounting officer to edit RR unit cost(cannot be more than PO item cost) and discount...
Purchase Order printing, 
Report on all core charges, Item, PO, RR, RR Date, Return Date
Disassembly should be separate module, should have post button, and cancel button for apof.
Report on Disassembly




create or replace function sf_is_vessel_item ( 
   p_item in VARCHAR2,
   p_uome in VARCHAR2,
   p_cate in VARCHAR2,
   p_itty in VARCHAR2,
   p_itgr in VARCHAR2
)  RETURN VARCHAR2 IS
   vVessCode varchar(32);
BEGIN
   BEGIN
      select vess_code
      into   vVessCode
      from   inv_item_serial_nos 
      where  item_code = p_item
      and    uome_code = p_uome
      and    cate_code = p_cate
      and    itty_code = p_itty
      and    itgr_code = p_itgr
      and    rownum = 1;
   EXCEPTION
      when no_data_found then 
         vVessCode := NULL;
   END;
   return vVessCode;
END sf_is_vessel_item;
/
show err

create public synonym sf_is_vessel_item for sf_is_vessel_item;
select 'grant execute on sf_is_vessel_item to ' || role || ';' from dba_roles where role like 'TPJ_INV%';


create ROLE TPJ_INV_RR_EDIT_COST;

create or replace function sf_is_allowed_to_edit_amount ( 
   p_user in VARCHAR2
)  RETURN VARCHAR2 IS
   vIsAllowed char(1) := 'N';
BEGIN
   BEGIN
      select 'Y'
      into   vIsAllowed
      from   dba_role_privs
      where  granted_role = 'TPJ_INV_RR_EDIT_COST'
      and    grantee = p_user;
   EXCEPTION
      when no_data_found then 
         vIsAllowed := 'N';
   END;
   return vIsAllowed;
END sf_is_allowed_to_edit_amount;
/
show err

create public synonym sf_is_allowed_to_edit_amount for sf_is_allowed_to_edit_amount;
select 'grant execute on sf_is_allowed_to_edit_amount to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

create or replace procedure sp_post_item_disassembly ( 
   p_item in VARCHAR2,
   p_uome in VARCHAR2,
   p_cate in VARCHAR2,
   p_itty in VARCHAR2,
   p_itgr in VARCHAR2
)  IS
BEGIN
   insert into inv_items ( itty_code, itgr_code, cate_code, code, name, 
                           supp_code, acce_code, bran_code, colo_code, 
                           mate_code, modl_code, shap_code, isze_code, 
                           sour_code, volt_code, uome_code, iloc_code, 
                           tot_qty, bal_qty, po_unit_cost, supp_unit_cost, 
                           created_by, dt_created, modified_by, dt_modified, 
                           beg_bal_qty, beg_bal_uc, type_code, 
                           serial_no, part_no, active_stat, downloaded)
   select new_itty, new_itgr, new_cate, new_item, new_name, 
                           null, acce_code, bran_code, colo_code, 
                           mate_code, modl_code, shap_code, isze_code, 
                           sour_code, volt_code, new_uome, iloc_code, 
                           qty, qty, 0, 0, 
                           user, sysdate, null, null, 
                           qty, 0, type_code, 
                           serial_no, part_no, 'Y', 'N'
   from   inv_disassembly_dtl
   where  status = 'FOR APPROVAL'
   and    item_code = p_item
   and    uome_code = p_uome
   and    cate_code = p_cate
   and    itty_code = p_itty
   and    itgr_code = p_itgr;

   insert into inv_items_log 
        ( itty_code, itgr_code, cate_code, code, 
          uome_code, iloc_code, beg_bal_qty, beg_bal_uc,
          tot_qty, bal_qty, po_unit_cost, supp_unit_cost, 
          created_by, dt_created, modified_by, dt_modified 
          )
   select new_itty, new_itgr, new_cate, new_item, 
          new_uome, iloc_code, qty, 0,
          qty, qty, 0, 0, 
          user, sysdate, null, null
   from   inv_disassembly_dtl
   where  status = 'FOR APPROVAL'
   and    item_code = p_item
   and    uome_code = p_uome
   and    cate_code = p_cate
   and    itty_code = p_itty
   and    itgr_code = p_itgr;

   insert into inv_item_ware
         (WARE_CODE, DR_NO, ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE,
          QTY, QTY_AVAIL, QTY_ALLOC, UNIT_COST, CURRENCY, DISCOUNT, BIN_NO,
          CREATED_BY, DT_CREATED, MODIFIED_BY, DT_MODIFIED )
   select '00002', '000000', new_itty, new_itgr, new_cate, new_item, new_uome,
          qty, qty, 0, 0, '', 0, 'GN99',
          user, sysdate, null, null
   from   inv_disassembly_dtl
   where  status = 'FOR APPROVAL'
   and    item_code = p_item
   and    uome_code = p_uome
   and    cate_code = p_cate
   and    itty_code = p_itty
   and    itgr_code = p_itgr;

   insert into inv_stocks 
        ( tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
          qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created,
          reference, ofc_code)
   select 'BEG_BAL', '000000', new_item, new_cate, new_itty, new_itgr, new_uome,
          qty, 0, 'PHP', 0, 0, sysdate,
          '00002', 'HO'
   from   inv_disassembly_dtl
   where  status = 'FOR APPROVAL'
   and    item_code = p_item
   and    uome_code = p_uome
   and    cate_code = p_cate
   and    itty_code = p_itty
   and    itgr_code = p_itgr;

   update inv_disassembly_dtl
   set    status = 'POSTED',
          approved_by = sf_get_empl(user),
          dt_approved = sysdate
   where  status = 'FOR APPROVAL'
   and    item_code = p_item
   and    uome_code = p_uome
   and    cate_code = p_cate
   and    itty_code = p_itty
   and    itgr_code = p_itgr;

   commit;

EXCEPTION
   WHEN OTHERS THEN 
      rollback;
      raise_application_error(-20001, 'Error creating new items.');
END sp_post_item_disassembly;
/
show err

create public synonym sp_post_item_disassembly for sp_post_item_disassembly;
select 'grant execute on sp_post_item_disassembly to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

create or replace procedure sp_cancel_item_disassembly ( 
   p_item in VARCHAR2,
   p_uome in VARCHAR2,
   p_cate in VARCHAR2,
   p_itty in VARCHAR2,
   p_itgr in VARCHAR2
)  IS
   nRsCount Number;
   nStCount Number;
BEGIN
   select count(1)
   into   nRsCount
   from   inv_reqslip_dtl d, inv_reqslip_hdr h
   where  d.rshd_rs_no = h.rs_no
   and    h.status <> 'CANCELLED'
   and    item_code = p_item
   and    uome_code = p_uome
   and    cate_code = p_cate
   and    itty_code = p_itty
   and    itgr_code = p_itgr;

   if nRsCount = 0 then
      select count(1)
      into   nStCount
      from   inv_stocks
      where  item_code = p_item
      and    uome_code = p_uome
      and    cate_code = p_cate
      and    itty_code = p_itty
      and    itgr_code = p_itgr;
   end if;

   if (nStCount >= 1) or (nRsCount>=1) then
      BEGIN
         delete from inv_item_ware
         where  item_code = p_item
         and    uome_code = p_uome
         and    cate_code = p_cate
         and    itty_code = p_itty
         and    itgr_code = p_itgr;
      EXCEPTION
         WHEN OTHERS THEN 
            rollback;
            raise_application_error(-20002, 'Error deleting inv_item_ware.');
      END;
      
      BEGIN
         delete from inv_items_log
         where  code = p_item
         and    uome_code = p_uome
         and    cate_code = p_cate
         and    itty_code = p_itty
         and    itgr_code = p_itgr;
      EXCEPTION
         WHEN OTHERS THEN 
            rollback;
            raise_application_error(-20001, 'Error deleting inv_items_log.');
      END;

      BEGIN
         delete from inv_stocks 
         where  item_code = p_item
         and    uome_code = p_uome
         and    cate_code = p_cate
         and    itty_code = p_itty
         and    itgr_code = p_itgr
         and    tran_type = 'BEG_BAL';
      EXCEPTION
         WHEN OTHERS THEN 
            rollback;
            raise_application_error(-20003, 'Error deleting inv_item_ware.');
      END;

      BEGIN
         delete from inv_items
         where  code = p_item
         and    uome_code = p_uome
         and    cate_code = p_cate
         and    itty_code = p_itty
         and    itgr_code = p_itgr;
      EXCEPTION
         WHEN OTHERS THEN 
            rollback;
            raise_application_error(-20004, 'Error deleting inv_item_ware.');
      END;
      
      commit;
   else
      raise_application_error(-20005, 'Cannot delete item, transactions were already been made.');
   end if;
END sp_cancel_item_disassembly;
/
show err

create public synonym sp_cancel_item_disassembly for sp_cancel_item_disassembly;
select 'grant execute on sp_cancel_item_disassembly to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

alter table wms_wts_picked add (
  rs_no          varchar2(16)
 ,iss_no         varchar2(16)
 ,rr_no          varchar2(16)
 ,rr_unit_cost   number(12,2)
 ,rr_total_amt   number(12,2)
);

alter table inv_ware_transfer_dtl add (
  rs_no          varchar2(16)
 ,iss_no         varchar2(16)
 ,rr_no          varchar2(16)
 ,rr_unit_cost   number(12,2)
 ,rr_total_amt   number(12,2)
);

alter table inv_packing_list_dtl add (
  rs_no          varchar2(16)
 ,iss_no         varchar2(16)
 ,rr_no          varchar2(16)
 ,rr_unit_cost   number(12,2)
 ,rr_total_amt   number(12,2)
);

alter table inv_ware_transfer_dtl drop primary key;
alter table inv_ware_transfer_dtl add constraint wrdt_pk primary key (tran_no, cate_code, itty_code, itgr_code, item_code, uome_code, iss_no, rr_no, rs_no);

alter table inv_packing_list_dtl drop primary key;
alter table inv_packing_list_dtl add constraint pcld_pk primary key (tran_no, wts_tran_no, cate_code, itty_code, itgr_code, item_code, uome_code, iss_no, rr_no, rs_no);

CREATE OR REPLACE PROCEDURE SP_PROCESS_WMS_WTS_PICKED as
begin
   insert into inv_ware_transfer_hdr
         (TRAN_NO, TRAN_DATE, WARE_CODE_O, WARE_CODE_D,
          STATUS, CREATED_BY, DT_CREATED, OFC_CODE)
   select st_no, to_date(st_date,'YYYY/MM/DD'), warehouse_fr, warehouse_to,
          'PENDING', user, sysdate, 'HO'
   from   wms_wts_picked
   where   process_flag = 'N'
   group by st_no, to_date(st_date,'YYYY/MM/DD'), warehouse_fr, warehouse_to;

   insert into inv_ware_transfer_dtl
         (tran_no, item_code, itty_code, cate_code, itgr_code, uome_code,
          ware_code_o, ware_code_d, created_by, dt_created, qty, approved_qty,
          vess_code, rs_no, iss_no, rr_no, rr_unit_cost, rr_total_amt)
   select a.st_no, a.item_code, b.itty_code, b.cate_code, b.itgr_code, a.uom,
          warehouse_fr, warehouse_to, user, sysdate, qty, approved_qty, 
          intended_for, rs_no, iss_no, rr_no, rr_unit_cost, rr_total_amt
   from wms_wts_picked a, inv_items b
   where  a.item_code = b.code
   and    a.process_flag = 'N';

   update wms_wts
   set    process_flag = 'Y'
   where  process_flag = 'N';

   commit;

end sp_process_wms_wts_picked;
/

create public synonym sp_process_wms_wts_picked for sp_process_wms_wts_picked;
select 'grant execute on sp_process_wms_wts_picked to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

CREATE OR REPLACE PROCEDURE SP_GENERATE_PACKING_LIST (p_tran_no in varchar2, p_wrhd_no in varchar2, p_iss_no in varchar2, p_wrhd_dt in date) as
begin
   if p_wrhd_no is not null and p_iss_no is null then
      insert into inv_packing_list_dtl
            (tran_no, wts_tran_no, item_code, itty_code, cate_code, itgr_code, uome_code, qty, approved_qty, vess_code,
             remarks, rs_no, iss_no, rr_no, rr_unit_cost, rr_total_amt, created_by, dt_created)
      select p_tran_no, d.tran_no, d.item_code, d.itty_code, d.cate_code, d.itgr_code, d.uome_code, d.qty, d.approved_qty, d.vess_code,
             d.remarks, d.rs_no, d.iss_no, d.rr_no, d.rr_unit_cost, d.rr_total_amt, user, sysdate
      from   inv_ware_transfer_dtl d, inv_ware_transfer_hdr h
      where  d.tran_no = h.tran_no
      and    h.status = 'APPROVED'
      and    d.pl_tran_no is null
      and    d.iss_no is null
      and    d.tran_no = p_wrhd_no;

      update inv_ware_transfer_dtl
      set    pl_tran_no = p_tran_no
      where  pl_tran_no is null
      and    iss_no is null
      and    tran_no = p_wrhd_no
      and    exists (select 1 from inv_ware_transfer_hdr h where h.status = 'APPROVED' and inv_ware_transfer_dtl.tran_no = h.tran_no);
   elsif p_iss_no is not null and p_wrhd_no is null and p_wrhd_dt is null then
      insert into inv_packing_list_dtl
            (tran_no, wts_tran_no, item_code, itty_code, cate_code, itgr_code, uome_code, qty, approved_qty, vess_code,
             remarks, rs_no, iss_no, rr_no, rr_unit_cost, rr_total_amt, created_by, dt_created)
      select  p_tran_no, null, d.item_code, d.itty_code, d.cate_code, d.itgr_code, d.uome_code, d.iss_qty, d.iss_qty, h.vess_code,
             d.notes, d.rshd_rs_no, h.iss_no, r.drhd_dr_no, r.unit_cost, r.total_cost, user, sysdate
      from   inv_iss_dtl d, inv_iss_hdr h, inv_dr_dtl r
      where  d.ishd_iss_no = h.iss_no
      and    d.item_code = r.item_code
      and    d.uome_code = r.uome_code
      and    d.itty_code = r.itty_code
      and    d.cate_code = r.cate_code
      and    d.itgr_code = r.itgr_code
      and    d.ref_type = 'DR'
      and    d.ref_no = r.drhd_dr_no
      and    d.dr_no = r.drhd_dr_no
      and    h.status = 'APPROVED'
      and    h.iss_no = p_iss_no;
      dbms_output.put_line('check 2');
   elsif (p_wrhd_no is not null or p_iss_no is not null) and (p_wrhd_dt is null) then
      insert into inv_packing_list_dtl
            (tran_no, wts_tran_no, item_code, itty_code, cate_code, itgr_code, uome_code, qty, approved_qty, vess_code,
             remarks, rs_no, iss_no, rr_no, rr_unit_cost, rr_total_amt, created_by, dt_created)
      select p_tran_no, d.tran_no, d.item_code, d.itty_code, d.cate_code, d.itgr_code, d.uome_code, d.qty, d.approved_qty, d.vess_code,
             d.remarks, d.rs_no, d.iss_no, d.rr_no, d.rr_unit_cost, d.rr_total_amt, user, sysdate
      from   inv_ware_transfer_dtl d, inv_ware_transfer_hdr h
      where  d.tran_no = h.tran_no
      and    h.status = 'APPROVED'
      and    d.pl_tran_no is null
      and    d.iss_no like nvl(p_iss_no, '%')
      and    d.tran_no like nvl(p_wrhd_no, '%');
      dbms_output.put_line('check 3');

      update inv_ware_transfer_dtl
      set    pl_tran_no = p_tran_no
      where  pl_tran_no is null
      and    iss_no like nvl(p_iss_no, '%')
      and    tran_no like nvl(p_wrhd_no, '%')
      and    exists (select 1 from inv_ware_transfer_hdr h
                     where h.status = 'APPROVED'
                     and   inv_ware_transfer_dtl.tran_no = h.tran_no);
   else
      dbms_output.put_line('check 11');
      insert into inv_packing_list_dtl
            (tran_no, wts_tran_no, item_code, itty_code, cate_code, itgr_code, uome_code, qty, approved_qty, vess_code,
             remarks, rs_no, iss_no, rr_no, rr_unit_cost, rr_total_amt, created_by, dt_created)
      select p_tran_no, d.tran_no, d.item_code, d.itty_code, d.cate_code, d.itgr_code, d.uome_code, d.qty, d.approved_qty, d.vess_code,
             d.remarks, d.rs_no, d.iss_no, d.rr_no, d.rr_unit_cost, d.rr_total_amt, user, sysdate
      from   inv_ware_transfer_dtl d, inv_ware_transfer_hdr h
      where  d.tran_no = h.tran_no
      and    h.status = 'APPROVED'
      and    d.pl_tran_no is null
      and    d.iss_no like nvl(p_iss_no, '%')
      and    d.tran_no like nvl(p_wrhd_no, '%')
      and    h.tran_date = p_wrhd_dt;
      dbms_output.put_line('check 21');

      update inv_ware_transfer_dtl
      set    pl_tran_no = p_tran_no
      where  pl_tran_no is null
      and    iss_no like nvl(p_iss_no, '%')
      and    tran_no like nvl(p_wrhd_no, '%')
      and    exists (select 1 from inv_ware_transfer_hdr h
                     where h.status = 'APPROVED'
                     and   inv_ware_transfer_dtl.tran_no = h.tran_no
                     and   h.tran_date=p_wrhd_dt);
   end if;

   commit;
end sp_generate_packing_list;
/

create public synonym sp_generate_packing_list for sp_generate_packing_list;
select 'grant execute on sp_generate_packing_list to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

create view inv_re_vw as
select a.re_no, a.dt_returned re_date, a.status, b.rshd_rs_no rs_no, b.ishd_iss_no iss_no, b.drhd_dr_no dr_no, b.item_code, b.cate_code, b.itty_code, b.itgr_code,
       b.uome_code, b.returned_qty re_qty, a.dt_approved, b.dr_no ref_dr_no, b.ref_type
from   inv_re_hdr a, inv_re_dtl b
where  a.re_no = b.rehd_re_no
and    a.status <> 'CANCELLED'
/
create public synonym inv_re_vw for inv_re_vw;
select 'grant select on inv_re_vw to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

create or replace view inv_core_charge_vw as
select h.po_no po_no,
       h.po_date po_date,
       h.supp_code supp_code,
       h.currency currency, 
       id.vess_code vess_code, 
       d.rshd_rs_no rs_no, 
       dr.dr_no dr_no, 
       id.iss_no iss_no, 
       re.re_no re_no, 
       d.item_code, 
       get_item_desc(d.item_code, d.cate_code, d.itty_code, d.itgr_code) item_name, 
       upper(get_item_desc(d.item_code, d.cate_code, d.itty_code, d.itgr_code)) item_name_upper, 
       d.cate_code,
       d.itty_code,
       d.itgr_code,
       d.uome_code,
       d.approved_qty po_qty,
       dr.qty dr_qty,
       dr.dr_date dr_date,
       id.iss_qty iss_qty,
       id.iss_date,
       re.re_qty re_qty,
       re.re_date,
       d.core_charge
from   inv_po_dtl d, inv_po_hdr h, inv_dr_vw dr, inv_iss_vw id, inv_re_vw re
where  d.pohd_po_no= h.po_no
and    h.status = 'APPROVED'
and    d.core_charge > 0 
and    d.pohd_po_no = dr.po_no (+)
and    d.rshd_rs_no = dr.rs_no (+)
and    d.item_code = dr.item_code (+)
and    d.uome_code = dr.uome_code (+)
and    d.cate_code = dr.cate_code (+)
and    d.itty_code = dr.itty_code (+)
and    d.itgr_code = dr.itgr_code (+)
and    dr.rs_no    = id.rs_no (+)
and    dr.dr_no    = id.dr_no (+)
and    dr.item_code = id.item_code (+)
and    dr.uome_code = id.uome_code (+)
and    dr.cate_code = id.cate_code (+)
and    dr.itty_code = id.itty_code (+)
and    dr.itgr_code = id.itgr_code (+)
and    id.rs_no    = re.rs_no (+)
and    id.dr_no    = re.dr_no (+)
and    id.iss_no   = re.iss_no (+)
and    id.item_code = re.item_code (+)
and    id.uome_code = re.uome_code (+)
and    id.cate_code = re.cate_code (+)
and    id.itty_code = re.itty_code (+)
and    id.itgr_code = re.itgr_code (+)
order by h.po_date, h.supp_code, d.item_code
/

create public synonym inv_core_charge_vw for inv_core_charge_vw;
select 'grant select on inv_core_charge_vw to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

select po_no po_no,
       po_date po_date,
       supp_code supp_code,
       currency currency, 
       vess_code vess_code, 
       dr_no dr_no, 
       dr_date dr_date, 
       iss_no iss_no, 
       iss_date iss_date, 
       re_no re_no, 
       re_date re_date, 
       item_code, 
       cate_code,
       itty_code,
       itgr_code,
       uome_code,
       po_qty,
       dr_qty,
       iss_qty,
       re_qty,
       core_charge
from   inv_core_charge_vw
order by po_date, supp_code, item_code

exec sp_cancel_item_disassembly('CYLH55-001', 'PCS', 'HRD', 'SCREW', 'HRD-SCREW');
exec sp_process_wms_wts_picked();

update inv_disassembly_dtl set status='POSTED';
update inv_disassembly_dtl set status='FOR APPROVAL', approved_by=null,dt_approved=null,cancelled_by=null, dt_cancelled=null where new_item='CYLH55-001';
select * from inv_items where code like 'CYLH55-%';

create view inv_rs_vw as
select h.rs_no, h.rs_date, h.rs_type, h.vess_code, h.status,
       d.item_code, d.uome_code, d.cate_code, d.itty_code, d.itgr_code, d.approved_qty rs_qty 
from   inv_reqslip_dtl d, inv_reqslip_hdr h
where  d.rshd_rs_no = h.rs_no
and    h.status <> 'CANCELLED'
/
create public synonym inv_rs_vw for inv_rs_vw;
select 'grant select on inv_rs_vw to ' || role || ';' from dba_roles where role like 'TPJ_INV%';

create or replace view inv_disassembly_vw as 
select d.new_item item_code, d.new_uome uome_code, d.new_cate cate_code, d.new_itty itty_code, d.new_itgr itgr_code, d.qty, d.serial_no, d.part_no,
       get_item_desc(d.new_item, d.new_cate, d.new_itty, d.new_itgr) item_name, 
       upper(get_item_desc(d.new_item, d.new_cate, d.new_itty, d.new_itgr)) item_name_upper, 
       rsv.rs_no, rsv.rs_qty, rsv.vess_code rs_intended_for, rsv.rs_date, rsv.rs_type, rsv.status rs_status,
       isv.iss_no is_no, isv.iss_qty is_qty, isv.vess_code is_intended_for, isv.iss_date is_date, isv.status is_status
from   inv_disassembly_dtl d, 
       inv_rs_vw rsv,
       inv_iss_vw isv
where  d.status = 'POSTED'
and    d.new_item = rsv.item_code (+)
and    d.new_uome = rsv.uome_code (+)
and    d.new_cate = rsv.cate_code (+)
and    d.new_itty = rsv.itty_code (+)
and    d.new_itgr = rsv.itgr_code (+)
and    rsv.item_code = isv.item_code (+)
and    rsv.uome_code = isv.uome_code (+)
and    rsv.cate_code = isv.cate_code (+)
and    rsv.itty_code = isv.itty_code (+)
and    rsv.itgr_code = isv.itgr_code (+)
and    rsv.rs_no = isv.rs_no (+)
/

create public synonym inv_disassembly_vw for inv_disassembly_vw;
select 'grant select on inv_disassembly_vw to ' || role || ';' from dba_roles where role like 'TPJ_INV%';


alter table INV_PACKING_LIST_HDR add (
  origin VARCHAR2(16),
  van_no VARCHAR2(32),
  etd    date,
  eta    date
 );

