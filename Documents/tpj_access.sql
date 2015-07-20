declare
   vStr Varchar2(256);
begin
   -- grant select to tpj roles
   for i in (select role from dba_roles where role like 'TPJ_ACC%') loop
      for j in (select object_name, object_type from user_objects 
               where object_name like 'ACC%' and object_type in ('TABLE', 'FUNCTION', 'PROCEDURE', 'VIEW', 'SEQUENCE')
               )
      loop
         if j.object_type IN ('FUNCTION', 'PROCEDURE') then
            vStr := 'grant execute on ' || j.object_name || ' to ' || i.role; 
         elsif j.object_type IN ('SEQUENCE') then
            vStr := 'grant select on ' || j.object_name || ' to ' || i.role; 
         else
            vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role; 
         end if;
         execute immediate(vStr);
      end loop;
   end loop;
end;
/

create or replace procedure sp_grant_access (p_role in varchar2, p_object in varchar2) as
   vStr Varchar2(256);
begin
   -- grant select to tpj roles
   for i in (select granted_role role from user_role_privs where granted_role like p_role) loop
      for j in (select object_name, object_type from user_objects 
               where object_name like p_object and object_type in ('TABLE', 'FUNCTION', 'PROCEDURE', 'VIEW', 'SEQUENCE')
               )
      loop
         if j.object_type IN ('FUNCTION', 'PROCEDURE') then
            vStr := 'grant execute on ' || j.object_name || ' to ' || i.role; 
         else
            if instr(i.role, 'READ', 1, 1) > 0 then
               vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role; 
            else
               vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role; 
            end if;  
         end if;
         execute immediate(vStr);
      end loop;
   end loop;
end sp_grant_access;
/
show err


create or replace procedure sp_grant_read_access (p_role in varchar2, p_object in varchar2) as
   vStr Varchar2(256);
begin
   -- grant select to tpj roles
   for i in (select granted_role role from user_role_privs where granted_role like p_role) loop
      for j in (select object_name, object_type from user_objects 
               where object_name like p_object and object_type in ('TABLE', 'FUNCTION', 'PROCEDURE', 'VIEW', 'SEQUENCE')
               )
      loop
         if j.object_type IN ('FUNCTION', 'PROCEDURE') then
            vStr := 'grant execute on ' || j.object_name || ' to ' || i.role; 
         else
            vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role; 
         end if;
         execute immediate(vStr);
      end loop;
   end loop;
end sp_grant_read_access;
/
show err

exec sp_grant_access('TPJ_ACC%', 'SP_ACC%');
exec sp_grant_access('TPJ_ACC%', 'ACC%');
exec sp_grant_read_access('TPJ_ACC%', 'INV%');

exec sp_grant_access('TPJ_PYS%', 'SF_GET_DELIVERY_RATE');
