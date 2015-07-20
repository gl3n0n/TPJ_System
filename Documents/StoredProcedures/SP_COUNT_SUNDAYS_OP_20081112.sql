create or replace procedure sp_count_sundays_op
(
   p_empl_id in  varchar2, 
   p_date_fr in  date,
   p_date_to in  date,
   p_outer   in  varchar2,
   p_days    out number,
   p_date    out date,
   p_rate    out number
) is
   dChkDate     Date;
   dLastSunday  Date;
   nCtr  Number := 0;
   nUpTO Number := 0;
   nDummy Number;
   nBasic  Number(12,4);
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
            dLastSunday := dChkDate;
         exception
            when no_data_found then null;
         end;
      end if;
   end loop;

   if nCtr > 0 then
      begin
         select nvl(a_basic_rate,basic_rate)
         into   nBasic
         from   pys_payroll_dtl_log
         where  empl_empl_id = p_empl_id
         and    pay_date = dLastSunday;
      exception
         when no_data_found then nBasic := 0;
      end;
   end if;

   p_days := nCtr;
   p_date := dLastSunday;
   p_rate := nBasic;

end sp_count_sundays_op;
/
