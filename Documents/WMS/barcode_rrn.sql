set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo barcode_rr3.sql
select decode(rr_no,'exit', 'exit' || chr(10), 'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\RECEIVING\' || rr_no || 'H.txt' || chr(10) || 
       'select dr_no || chr(9) || to_char(dr_date, ''DD-MON-RRRR'') || chr(9) || ''"'' || SF_GET_EMPL_NAME(RECEIVED_BY) || ''"'' || chr(9) || supp_code || chr(9) || RR_AMT line ' || chr(10) ||
       'from INV_DR_HDR ' || chr(10) ||
       'where dr_no=''' || rr_no || '''' || chr(10) ||
       'order by dr_no;' || chr(10) ||
       'spoo off' || chr(10) ||
       'spoo D:\import\RECEIVING\' || rr_no || 'D.txt' || chr(10) || 
       'select drhd_dr_no || chr(9) || item_code || chr(9) || qty || chr(9) || uome_code|| chr(9) || total_cost line' || chr(10) ||
       'from INV_DR_DTL' || chr(10) ||
       'where   drhd_dr_no=''' || rr_no || ''';' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_rr set downloaded=''Y'' where rr_no = ''' || rr_no || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@barcode_rr.sql' || chr(10)) sql_text
from   (select nvl(min(rr_no),'exit') rr_no from inv_wsm_rr where downloaded = 'N' order by dt_created) 
where rownum = 1;

spoo off
@barcode_rr3.sql
exit
