create or replace function SF_GET_LATEST_EMBARK (
   p_empl_id in varchar2,
   p_date_fr in date 
  ) return date is
  dLatestEmbark Date;
begin
   -- get latest record
   select max(dt_embarked)
   into   dLatestEmbark
   from   cms_voyage_crew
   where  empl_empl_id = p_empl_id
   and    voya_voyage_date <= p_date_fr
   and    dt_embarked <= p_date_fr;

   return dLatestEmbark;
exception
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_embark for employee ' || p_empl_id || ' ' || SQLERRM);
end SF_GET_LATEST_EMBARK;
/
show err
