create or replace procedure sp_crew_on_laot (
   p_asof   Date ) 
   as
   dP_Start Date;
   dStart   Date;
   dEnd     Date;
   nMos     Number := 0;
   vMinVess Varchar2(16);
   vMintitl Varchar2(32);
   vMinDate Date;
   vMaxVess Varchar2(16);
   vMaxtitl Varchar2(32);
   vMaxDate Date;
   bOneYear Boolean;
   bRegenerate Boolean;
   nCnt     Number;
   dCreated Date;
begin
   select count(1), trunc(max(dt_created)) 
   into   nCnt, dCreated
   from   pms_crew_on_laot
   where  dt_asof = p_asof;

   bRegenerate := TRUE;
   if nCnt > 0 then
      if dCreated = trunc(sysdate) then
         bRegenerate := FALSE;
      else
         delete from pms_crew_on_laot
         where dt_asof = p_asof;
      end if;
   end if;

   if bRegenerate then
      dP_Start := add_months(p_asof, -12);
      for i in (select empl_empl_id, min(dt_embarked) dt_embarked from (
                select empl_empl_id, max(dt_embarked) dt_embarked 
                from   cms_voyage_crew
                where  dt_embarked <= dP_Start
                group  by empl_empl_id
                union  
                select empl_empl_id, min(dt_embarked) dt_embarked 
                from   cms_voyage_crew
                where  dt_embarked >= dP_Start
                group  by empl_empl_id )
                group  by empl_empl_id)
      loop
         for j in (select voya_vess_code, title, dt_embarked, dt_disembarked
                   from   cms_voyage_crew
                   where  empl_empl_id = i.empl_empl_id 
                   and    dt_embarked >= i.dt_embarked                 
                   order  by dt_embarked )
         loop
            if dStart is null then
               dStart   := j.dt_embarked;
               dEnd     := j.dt_disembarked;
               vMinVess := j.voya_vess_code;
               vMintitl := j.title;
               vMinDate := j.dt_embarked;
            else
               if (dEnd+1) <> j.dt_embarked then 
                  bOneYear := FALSE;
                  exit; 
               else
                  bOneYear := TRUE;
                  dStart := j.dt_embarked;
                  dEnd   := j.dt_disembarked;
               end if;
            end if;
            nMos := nMos + months_between(nvl(j.dt_disembarked,p_asof), j.dt_embarked);
            vMaxVess := j.voya_vess_code;
            vMaxtitl := j.title;
            vMaxDate := j.dt_embarked;
            if p_asof < j.dt_embarked then
               exit; 
            end if;
            if (j.dt_disembarked is not null) and (p_asof < j.dt_disembarked) then
               exit; 
            end if;
         end loop;
         if bOneYear and nMos >= 12 then
            insert into pms_crew_on_laot (dt_asof, empl_empl_id, earliest_vess_code, earliest_title, earliest_dt_embarked, 
                                                                 latest_vess_code, latest_title, latest_dt_embarked, dt_created )
            values (p_asof, i.empl_empl_id, vMinVess, vMintitl, vMinDate, vMaxVess, vMaxtitl, vMaxDate, sysdate );
         end if;
         -- reset values
         dStart   := null;
         dEnd     := null;
         nMos     := 0;
         vMinVess := null;
         vMintitl := null;
         vMinDate := null;
         vMaxVess := null;
         vMaxtitl := null;
         vMaxDate := null;
         bOneYear := FALSE;
      end loop;
   end if;
   commit;
end sp_crew_on_laot;
/
show err

drop table pms_crew_on_laot;
create table pms_crew_on_laot (
	 dt_asof      date not null, 
	 empl_empl_id varchar2(16) not null, 
	 earliest_vess_code varchar2(16), 
	 earliest_title varchar2(32), 
	 earliest_dt_embarked date, 
	 latest_vess_code varchar2(16), 
	 latest_title varchar2(32), 
	 latest_dt_embarked date,
   dt_created date,
	 constraint crol_pk primary key (dt_asof, empl_empl_id)
);

CREATE PUBLIC SYNONYM pms_crew_on_laot FOR pms_crew_on_laot;
CREATE PUBLIC SYNONYM sp_crew_on_laot FOR sp_crew_on_laot;

GRANT EXECUTE ON sp_crew_on_laot TO PUBLIC;
GRANT INSERT, UPDATE, DELETE, SELECT ON pms_crew_on_laot TO PUBLIC;
