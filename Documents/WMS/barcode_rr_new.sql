set feedback off
set head off
set lines 1012
set pages 0
col sql_text form a1024
spoo /home/oracle/scripts/barcode_rr2.sql
select decode(rr_no,'exit', 'exit' || chr(10), 'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo /home/oracle/scripts/' || rr_no ||to_char(sysdate, 'YYYYMMDDMISS') || '.txt' || chr(10) || 
       'select a.dr_no || chr(9) || to_char(a.dr_date, ''DD-MON-RRRR'') || chr(9) || a.status || chr(9) || a.supp_code || chr(9) || ''"'' || SF_GET_EMPL_NAME(d.REQUESTED_BY) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(a.RECEIVED_BY) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(a.PREPARED_BY) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(a.POSTED_BY) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(a.REMARKS) || ''"'' || chr(9) || a.INVOICE_NO || chr(9) || a.SUPP_DR_NO || chr(9) || b.RSHD_RS_NO || chr(9) || d.VESS_CODE || chr(9) || rownum || chr(9) || b.item_code || chr(9) || b.qty || chr(9) || b.uome_code ' || chr(10) ||
       'from INV_DR_HDR a, INV_DR_DTL b, INV_REQSLIP_DTL c, INV_REQSLIP_HDR d' || chr(10) ||
       'where a.dr_no=''' || rr_no || '''' || chr(10) ||
       'and a.dr_no=b.drhd_dr_no' || chr(10) ||
       'and b.rshd_rs_no=c.rshd_rs_no' || chr(10) ||
       'and b.item_code=c.item_code' || chr(10) ||
       'and b.cate_code=c.cate_code' || chr(10) ||
       'and b.itty_code=c.itty_code' || chr(10) ||
       'and b.itgr_code=c.itgr_code' || chr(10) ||
       'and c.rshd_rs_no=d.rs_no' || chr(10) ||
       'order by a.dr_no;' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_rr set downloaded=''Y'' where rr_no = ''' || rr_no || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@barcode_rrn.sql' || chr(10)) sql_text
from   (select nvl(min(rr_no),'exit') rr_no from inv_wsm_rr where downloaded = 'N' order by dt_created) 
where rownum = 1;

spoo off
@/home/oracle/scripts/barcode_rr2.sql
exit

select * from (select * from inv_wsm_rr order by DT_CREATED desc) where rownum < 10;
select * from inv_wsm_rr where downloaded='N';

update inv_wsm_rr set downloaded='N' where RR_NO='071378';
update inv_wsm_rr set downloaded='N' where RR_NO='071377';
update inv_wsm_rr set downloaded='N' where RR_NO='071376';

       'spoo D:\import\RECEIVING\' || rr_no ||to_char(sysdate, 'YYYYMMDDMISS') || '.txt' || chr(10) || 
       'spoo /home/oracle/scripts' || rr_no ||to_char(sysdate, 'YYYYMMDDMISS') || '.txt' || chr(10) || 




set feedback off
set head off
set lines 1012
set pages 0
col sql_text form a1024
spoo /home/oracle/scripts/barcode_rr_jo2.sql
select decode(jo_dr_no,'exit', 'exit' || chr(10), 'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo /home/oracle/scripts/' || jo_dr_no || to_char(sysdate, 'YYYYMMDDMISS') || '.txt' || chr(10) || 
       'select a.jo_dr_no || chr(9) || to_char(a.jo_dr_date, ''DD-MON-RRRR'') || chr(9) || a.status || chr(9) || a.supp_code || chr(9) || a.johd_jo_no || chr(9) || ''"'' || get_item_desc(a.ITEM_CODE, a.CATE_CODE, a.ITTY_CODE, a.ITGR_CODE) || ''"'' || chr(9) || ''"'' || v.NAME ||  ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(b.REQUESTED_BY) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(a.received_by) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(a.prepared_by) || ''"'' ||  chr(9) || ''"'' || SF_GET_EMPL_NAME(a.approved_by) || ''"'' || chr(9) || ''"'' || a.remarks || ''"'' || chr(9) || a.SUPP_DR_NO || b.JSHD_JS_NO || chr(9) || b.INTENDED_FOR || chr(9) || ROWNUM || chr(9) || a.ITEM_CODE || chr(9) || a.QTY || chr(9) || a.UOME_CODE line_desc' || chr(10) ||      
       'from INV_JO_DR_HDR a, INV_JO_HDR b, INV_VESSELS v ' || chr(10) ||
       'where a.jo_dr_no=''' || jo_dr_no || '''' || chr(10) ||
       'and  a.johd_jo_no=b.jo_no' || chr(10) ||
       'and  a.intended_for=v.code' || chr(10) ||
       'order by a.jo_dr_no;' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_jo_rr set downloaded=''Y'', dt_downloaded=sysdate where jo_dr_no = ''' || jo_dr_no || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@/home/oracle/scripts/barcode_rr_jo.sql' || chr(10))  sql_text
from   (select nvl(min(jo_dr_no),'exit') jo_dr_no from inv_wsm_jo_rr where downloaded = 'N' order by dt_created) 
where rownum = 1;

spoo off
@/home/oracle/scripts/barcode_rr_jo2.sql
exit


select * from (select * from inv_wsm_jo_rr order by DT_CREATED desc) where rownum < 10;
select * from inv_wsm_jo_rr where downloaded='N';

update inv_wsm_jo_rr set downloaded='N' where JO_DR_NO='007992';
update inv_wsm_jo_rr set downloaded='N' where JO_DR_NO='007993';
update inv_wsm_jo_rr set downloaded='N' where JO_DR_NO='007994';

select a.jo_dr_no || chr(9) || to_char(a.jo_dr_date, 'DD-MON-RRRR') || chr(9) || a.status || chr(9) || a.supp_code || chr(9) || a.johd_jo_no || chr(9) || '"' || get_item_desc(a.ITEM_CODE, a.CATE_CODE, a.ITTY_CODE, a.ITGR_CODE) || '"' || chr(9) || '"' || v.NAME ||  '"' || chr(9) || '"' || SF_GET_EMPL_NAME(b.REQUESTED_BY) || '"' || chr(9) || '"' || SF_GET_EMPL_NAME(a.received_by) || '"' || chr(9) || '"' || SF_GET_EMPL_NAME(a.prepared_by) || '"' ||  chr(9) || '"' || SF_GET_EMPL_NAME(a.approved_by) || '"' || chr(9) || '"' || a.remarks || '"' || chr(9) || a.SUPP_DR_NO || b.JSHD_JS_NO || chr(9) || b.INTENDED_FOR || chr(9) || ROWNUM || chr(9) || a.ITEM_CODE || chr(9) || a.QTY || chr(9) || a.UOME_CODE line_desc                                                                                                                                                    
from INV_JO_DR_HDR a, INV_JO_HDR b, INV_VESSELS v
where a.jo_dr_no='007994'
and  a.johd_jo_no=b.jo_no
and  b.intended_for = v.code
order by a.jo_dr_no;

select a.jo_dr_no || chr(9) || to_char(a.jo_dr_date, 'DD-MON-RRRR') || chr(9) || a.status || chr(9) || a.supp_code || chr(9) || a.johd_jo_no || chr(9) || '"' || get_item_desc(a.ITEM_CODE, a.CATE_CODE, a.ITTY_CODE, a.ITGR_CODE) || '"' || chr(9) || '"' ||  a.INTENDED_FOR ||  '"' || chr(9) || '"' || SF_GET_EMPL_NAME(b.REQUESTED_BY) || '"' || chr(9) || '"' || SF_GET_EMPL_NAME(a.received_by) || '"' || chr(9) || '"' || SF_GET_EMPL_NAME(a.prepared_by) || '"' ||  chr(9) || '"' || SF_GET_EMPL_NAME(a.approved_by) || '"' || chr(9) || '"' || a.remarks || '"' || chr(9) || a.SUPP_DR_NO || b.JSHD_JS_NO || chr(9) || b.INTENDED_FOR || chr(9) || ROWNUM || chr(9) || a.ITEM_CODE || chr(9) || a.QTY || chr(9) || a.UOME_CODE line_desc                                                                                                                                                    
from INV_JO_DR_HDR a, INV_JO_HDR b
where a.jo_dr_no='007994'
and  a.johd_jo_no=b.jo_no
order by a.jo_dr_no;

spoo off                                                                                                                                                                                                                                    
update inv_wsm_jo_rr set downloaded='Y', dt_downloaded=sysdate where jo_dr_no = '007994';                                                                                                                                                   
commit;                                                                                                                                                                                                                                     
