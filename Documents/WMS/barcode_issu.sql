set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo barcode_iss3.sql
select decode(iss_no,'exit', 'exit' || chr(10), 'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\ISSUANCE\' || iss_no || 'H.txt' || chr(10) || 
       'select iss_no || chr(9) || to_char(iss_date, ''DD-MON-RRRR'') || chr(9) || rshd_rs_no || chr(9) || ISS_TYPE || chr(9) || nvl(ware_code,'' '') || chr(9) || ''"'' || SF_GET_EMPL_NAME(ISSUED_TO) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(RECEIVED_BY) || ''"'' line_desc' || chr(10) || 
       'from INV_ISS_HDR ' || chr(10) ||
       'where iss_no=''' || iss_no || '''' || chr(10) ||
       'order by iss_no;' || chr(10) ||
       'spoo off' || chr(10) ||
       'spoo D:\import\ISSUANCE\' || iss_no || 'D.txt' || chr(10) || 
       'select ISHD_ISS_NO || chr(9) || ITTY_CODE || chr(9) || ITGR_CODE || chr(9) || CATE_CODE  || chr(9) || ITEM_CODE || chr(9) || ISS_QTY  || chr(9) || UOME_CODE line_desc' || chr(10) ||
       'from INV_ISS_DTL' || chr(10) ||
       'where   ishd_iss_no=''' || iss_no || ''';' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_iss set downloaded=''Y'' where iss_no = ''' || iss_no || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@barcode_iss.sql' || chr(10))  sql_text
from   (select nvl(min(iss_no),'exit') iss_no from inv_wsm_iss where downloaded = 'N' order by dt_created) 
where rownum = 1;

spoo off
@barcode_iss3.sql
exit
