set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo D:\systems\oracle\WSM\barcode_rr_jo2.sql
select decode(jo_dr_no,'exit', 'exit' || chr(10), 'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\RECEIVING_JO\' || jo_dr_no || 'H.txt' || chr(10) || 
       'select h.jo_dr_no || chr(9) || to_char(h.jo_dr_date, ''DD-MON-RRRR'') || chr(9)  || ''"'' || SF_GET_EMPL_NAME(h.received_by)  || ''"'' || chr(9) || h.supp_code || chr(9)  || h.rr_amt line_desc' || chr(10) || 
       'from INV_JO_DR_HDR H ' || chr(10) ||
       'where h.jo_dr_no=''' || jo_dr_no || '''' || chr(10) ||
       'order by h.jo_dr_no;' || chr(10) ||
       'spoo off' || chr(10) ||
       'spoo D:\import\RECEIVING_JO\' || jo_dr_no || 'D.txt' || chr(10) || 
       'select JO_DR_NO || chr(9) || ITEM_CODE || chr(9) || QTY  || chr(9) || UOME_CODE || chr(9) || RR_AMT line_desc' || chr(10) ||
       'from INV_JO_DR_HDR ' || chr(10) ||
       'where   jo_dr_no=''' || jo_dr_no || ''';' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_jo_rr set downloaded=''Y'', dt_downloaded=sysdate where jo_dr_no = ''' || jo_dr_no || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@D:\systems\oracle\WSM\barcode_rr_jo.sql' || chr(10))  sql_text
from   (select nvl(min(jo_dr_no),'exit') jo_dr_no from inv_wsm_jo_rr where downloaded = 'N' order by dt_created) 
where rownum = 1;

spoo off
@D:\systems\oracle\WSM\barcode_rr_jo2.sql
exit
