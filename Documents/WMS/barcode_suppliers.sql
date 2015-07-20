set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo D:\systems\oracle\WSM\barcode_suppliers2.sql
select decode(supp_code,'exit', 'exit' || chr(10), '' ||
       'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\MASTER\suppliershdr_' || supp_code || '.txt' || chr(10) || 
       'select code || chr(9) || ''"'' || name || ''"'' || chr(9) || ''"'' || address || ''"'' || chr(9) || ''"'' || tel_no || ''"'' || chr(9) || ''"'' || fax_no || ''"'' || chr(9) || ''"'' || contact_person || ''"'' || chr(9) || to_char(dt_created, ''DD-MON-YYYY'') line_desc' || chr(10) || 
       'from inv_suppliers ' || chr(10) ||
       'where code=''' || supp_code || '''' || chr(10) ||
        'order by code;' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_suppliers set downloaded=''Y'', dt_downloaded=sysdate where supp_code = ''' || supp_code || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@D:\systems\oracle\WSM\barcode_suppliers.sql' || chr(10))  sql_text
from   (select nvl(min(supp_code),'exit') supp_code from inv_wsm_suppliers where downloaded='N' order by dt_created) 
where rownum = 1;

spoo off
@D:\systems\oracle\WSM\barcode_suppliers2.sql
exit