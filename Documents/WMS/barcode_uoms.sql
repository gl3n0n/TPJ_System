set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo D:\systems\oracle\WSM\barcode_uoms2.sql
select decode(uome_code,'exit', 'exit' || chr(10), '' ||
       'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\MASTER\uomhdr_' || uome_code || '.txt' || chr(10) || 
       'select code || chr(9) || name || chr(9) || created_by || chr(9) || to_char(dt_created, ''DD-MON-YYYY'') line_desc' || chr(10) || 
       'from inv_unit_of_measure ' || chr(10) ||
       'where code=''' || uome_code || '''' || chr(10) ||
        'order by code;' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_uoms set downloaded=''Y'', dt_downloaded=sysdate where uome_code = ''' || uome_code || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@D:\systems\oracle\WSM\barcode_uoms.sql' || chr(10))  sql_text
from   (select nvl(min(uome_code),'exit') uome_code from inv_wsm_uoms order by dt_created) 
where rownum = 1;

spoo off
@D:\systems\oracle\WSM\barcode_uoms2.sql
exit
