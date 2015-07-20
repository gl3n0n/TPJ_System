set feedback off
set pages 0
set lines 128
spoo c:\Project\TPJ\BackupScripts\backup2.bat
select 'c:\orant\des_81\bin\exp tpj/prod123@tpj file=c:\Project\TPJ\DUMP\TPJ_SERVER_' || to_char(sysdate, 'YYYYMMDDHH24MISS') || '.DMP owner=tpj log=c:\Project\TPJ\DUMP\exp_owner.log'
from dual;
spoo off
exit
