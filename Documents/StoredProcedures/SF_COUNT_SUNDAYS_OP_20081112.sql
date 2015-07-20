create or replace function sf_count_sundays_op
(
   p_empl_id in varchar2, 
   p_date_fr in date,
   p_date_to in date,
   p_outer   in varchar2
)
   return number is
   dChkDate Date;
   nCtr  Number := 0;
   nUpTO Number := 0;
   nDummy Number;
begin
   nUpTo := (p_date_to-p_date_fr)+1;
   dChkDate := p_date_fr -1;
   for i in 1..nUpTo loop
      dChkDate := dChkDate + 1;
      if sf_is_sunday (dChkDate) = 1 then
         begin
            select num_hours
            into   nDummy
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dChkDate
            and    outer_port = p_outer;
            nCtr := nCtr + 1;
         exception
            when no_data_found then null;
         end;
      end if;
   end loop;
   return nCtr;
end sf_count_sundays_op;
/
