set feedback off
set head off
set lines 312
set pages 0
col sql_text form a1024
spoo D:\systems\oracle\WSM\barcode_items2.sql
select decode(item_code,'exit', 'exit' || chr(10), '' ||
       'set head off' || chr(10) || 
       'set lines 256' || chr(10) || 
       'set feedback off' || chr(10) || 
       'set pages 0' || chr(10) || 
       'spoo D:\import\MASTER\itemshdr_' || item_code || '_' || cate_code || '_' || itty_code || '_' || itgr_code || '.txt' || chr(10) || 
       'select itty_code || chr(9) || itgr_code || chr(9) || cate_code || chr(9) || code || chr(9) || ''"'' || GET_ITEM_DESC(code, cate_code, itty_code, itgr_code)  || ''"'' || chr(9) || tot_qty || chr(9) || bal_qty || chr(9) || uome_code line_desc' || chr(10) || 
       'from INV_ITEMS ' || chr(10) ||
       'where code=''' || item_code || '''' || chr(10) ||
       'and   cate_code=''' || cate_code || '''' || chr(10) ||
       'and   itty_code=''' || itty_code || '''' || chr(10) ||
       'and   itgr_code=''' || itgr_code || '''' || chr(10) ||
       'order by code;' || chr(10) ||
       'spoo off' || chr(10) ||
       'update inv_wsm_items set downloaded=''Y'', dt_downloaded=sysdate where item_code = ''' || item_code || '''' || chr(10) ||
       'and   cate_code=''' || cate_code || '''' || chr(10) ||
       'and   itty_code=''' || itty_code || '''' || chr(10) ||
       'and   itgr_code=''' || itgr_code || ''';' || chr(10) ||
       'commit;' || chr(10) ||
       '@D:\systems\oracle\WSM\barcode_items.sql' || chr(10))  sql_text
from   (select nvl(min(item_code),'exit') item_code, '' cate_code, '' itty_code, '' itgr_code, sysdate dt_created from inv_wsm_items where downloaded = 'N' union all
        select item_code, cate_code, itty_code, itgr_code, dt_created from inv_wsm_items where  downloaded = 'N'
        order by dt_created) 
where rownum = 1;

spoo off
@D:\systems\oracle\WSM\barcode_items2.sql
exit
