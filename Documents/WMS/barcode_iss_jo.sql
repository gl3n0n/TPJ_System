set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo barcode_iss_jo2.sql
select decode(jo_iss_no,'exit', 'exit' || chr(10), 'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\ISSUANCE_JO\' || jo_iss_no || 'H.txt' || chr(10) || 
       'select jiss.joiss_no || chr(9) || to_char(jiss.joiss_date, ''DD-MON-RRRR'') || chr(9) || max(johd.JSHD_JS_NO) || chr(9) || ''"'' || SF_GET_EMPL_NAME(jiss.issued_to) || ''"'' || chr(9) || ''"'' || SF_GET_EMPL_NAME(jiss.received_by)  || ''"'' line_desc' || chr(10) || 
       'from INV_JOISS_HDR JISS, INV_JOISS_DTL JIDT, INV_JO_HDR JOHD ' || chr(10) ||
       'where jiss.joiss_no=''' || jo_iss_no || '''' || chr(10) ||
       'and   jiss.joiss_no=jidt.joishd_joiss_no' || chr(10) ||
       'and   jidt.johd_jo_no=johd.jo_no' || chr(10) ||
       'group by jiss.joiss_no, jiss.joiss_date, jiss.issued_to, jiss.received_by ' || chr(10) ||
       'order by jiss.joiss_no;' || chr(10) ||
       'spoo off' || chr(10) ||
       'spoo D:\import\ISSUANCE_JO\' || jo_iss_no || 'D.txt' || chr(10) || 
       'select JOISHD_JOISS_NO || chr(9) || ITTY_CODE || chr(9) || ITGR_CODE || chr(9) || CATE_CODE || chr(9) || ITEM_CODE || chr(9) || decode(nvl(ISS_QTY,0),0,QTY, ISS_QTY) || chr(9) || UOME_CODE line_desc' || chr(10) ||
       'from INV_JOISS_DTL' || chr(10) ||
       'where   joishd_joiss_no=''' || jo_iss_no || ''';' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_jo_iss set downloaded=''Y'', dt_downloaded=sysdate where jo_iss_no = ''' || jo_iss_no || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@barcode_iss_jo.sql' || chr(10))  sql_text
from   (select nvl(min(jo_iss_no),'exit') jo_iss_no from inv_wsm_jo_iss where downloaded = 'N' order by dt_created) 
where rownum = 1;

spoo off
@barcode_iss_jo2.sql
exit
