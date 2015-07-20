set feedback off
set pages 0
set lines 128
spoo c:\TPJ\BackupScripts\backup2.bat
select 'c:\des_81\bin\exp tpj/prod123@tpj file=c:\TPJ\DUMP\TPJ_SERVER_' || to_char(sysdate, 'YYYYMMDDHH24MISS') || '_FULL.DMP full=y log=c:\TPJ\DUMP\exp.log rows=no'
from dual;
spoo off
exit
