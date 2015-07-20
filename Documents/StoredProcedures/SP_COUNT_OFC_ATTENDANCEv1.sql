create or replace procedure sp_count_ofc_attendance
(
   p_empl_id  in  varchar2, 
   p_date_fr  in  date, 
   p_date_to  in  date, 
   p_numday   out number, 
   p_overtm   out number, 
   p_regsun   out number, 
   p_reghol   out number, 
   p_holsun   out number, 
   p_outer_no out number,
   p_outer_fr out date, 
   p_outer_to out date, 
   p_outer_ad out number,     -- adjustment
   p_outad_fr out date, 
   p_outad_to out date 
) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_period_fr in date, p_period_to in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date between p_period_fr and p_period_to
   union
   select tx_date, null, null, null, null, 6, 0, 'N'
   from   pys_holidays
   where  tx_date between p_period_fr and p_period_to
   and    tx_date not in (select att_date from pms_attendance_records where empl_empl_id = p_empl_id and att_date between p_period_fr and p_period_to)
   order  by tx_date;

   nNumHrs   Number (7,3) := 0;
   nOvertm   Number (7,3) := 0;
   nRegHol   Number (7,3) := 0;
   nHolSun   Number (7,3) := 0;
   nRegSun   Number (7,3) := 0;
   nCOLA     Number (7,3) := 0;
   nUpTO     Number := 0;
   bHolSun   Boolean;
   nDay      Number (5,2) := 0;
   dDate     Date := p_date_fr;
   dTxDate   Date;
   dStart    Date;
   dEnd      Date;
   nTmpHrs   Number (7,3) := 0;
   nDeduct   Number (7,3) := 0;
   nAssume   Number (7,3) := 0;
   nOuterNo  Number (7,3) := 0;
   nOuterAd  Number (7,3) := 0;
   dOuterFr  Date;
   dOuterTo  Date;
   dOutadFr  Date;
   dOutadTo  Date;
begin

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   for j in atre ( p_empl_id, dStart, dEnd ) loop

      nDay  := nDay + 1;
      dDate := j.tx_date;
      nTmpHrs := 0;
      if j.outer_port = 'Y' then
         if dDate >= p_date_fr then
            nOuterNo := nOuterNo + 1;
            if dOuterFr is null then
               dOuterFr := j.tx_date;
            end if;
            dOuterTo := j.tx_date;
         else
            nOuterAd := nOuterAd + 1;
            if dOutadFr is null then
               dOutadFr := j.tx_date;
            end if;
            dOutadTo := j.tx_date;
         end if;
      else
         if sf_is_sunday (dDate) = 1 then
            if j.num_hours >= 4  then
               nTmpHrs := 8;
               nRegSun := nRegSun + j.ot_hours;
            else 
               nTmpHrs := (j.num_hours/4)*(8);
            end if;
         
         elsif sf_is_holiday (dDate) = 1 then
            if j.num_hours >= 6  then
               nTmpHrs := 8;
               nRegHol := nRegHol + j.ot_hours;
            else 
               nTmpHrs := ((j.num_hours/6)*8);
            end if;
         
         else
            -- Overtime
            if j.num_hours >= 8  then
               nTmpHrs := 8;
            else
               nTmpHrs := j.num_hours;
            end if;
            nOvertm := nOvertm + j.ot_hours;
         end if;  

         if dDate >= p_date_fr then
            nNumHrs  := nNumHrs + nTmpHrs;
         end if;  

      end if;

   end loop;

   -- ADD from Cutoff date to End of Month
   nUpTo   := (p_date_to-dEnd); 
   nAssume := 0;  
   for i in 1..nUpTo loop
      dDate := dEnd + i;
      if sf_is_sunday (dDate) = 0 then
         nAssume := nAssume + 8;
      end if;
   end loop;
   -- end Cutoff date
   -- dbms_output.put_line ('check nAssume: ' || to_char(nAssume) );

   -- LESS from previous Cutoff date to End of previous Month
   nUpTo   := (p_date_fr-dStart); 
   nTmpHrs := 0;  
   nDeduct := 0;  
   for i in 1..nUpTo loop
      dDate := dStart + (i-1);
      -- check if not SUNDAY and not HOLIDAY
      if (sf_is_sunday (dDate) = 0) and (sf_is_holiday (dDate) = 0) then
         begin
            select num_hours
            into   nTmpHrs 
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dDate;
         exception
            when no_data_found then 
               nTmpHrs := 0;
         end;
         if nTmpHrs < 8 then
            nDeduct := nDeduct + (8-nTmpHrs);
         end if;
      end if;
   end loop;
   -- end Cutoff date
   -- dbms_output.put_line ('check nDeduct: ' || to_char(nDeduct) );

   p_numday  := ((nNumHrs+nAssume)-nDeduct)/8;
   p_overtm  := nOvertm;
   p_regsun  := nRegSun;
   p_reghol  := nRegHol;
   p_holsun  := nHolSun;

   -- for outer port
   p_outer_no := nOuterNo;
   p_outer_fr := dOuterFr;
   p_outer_to := dOuterTo;
   p_outer_ad := nOuterAd;
   p_outad_fr := dOutadFr;
   p_outad_to := dOutadTo;

end sp_count_ofc_attendance;
/
show err


select att_date tx_date, num_hours, ot_hours, 
       sf_is_holiday (att_date) holiday,
       sf_is_sunday (att_date) sunday, outer_port
from   pms_attendance_records
where  empl_empl_id = '00368'
and    att_date between to_date('20061226', 'YYYYMMDD') and to_date('20070126', 'YYYYMMDD')
order  by att_date;

select sum(num_hours), sum(num_hours)/8, sum(ot_hours)
from   pms_attendance_records
where  empl_empl_id = '00368'
and    sf_is_holiday (att_date) = 0
and    sf_is_sunday (att_date) = 0
and    att_date between to_date('20061226', 'YYYYMMDD') and to_date('20070126', 'YYYYMMDD');

declare
   p_numday   number(7,3); 
   p_overtm   number(7,3); 
   p_regsun   number(7,3); 
   p_reghol   number(7,3); 
   p_holsun   number(7,3); 
   p_outer_no number(7,3);
   p_outer_fr date;
   p_outer_to date;
   p_outer_ad number(7,3);
   p_outad_fr date;
   p_outad_to date;
begin
   sp_count_ofc_attendance ('00368', to_date('20070101', 'YYYYMMDD'), to_date('20070115', 'YYYYMMDD'), p_numday, p_overtm, p_regsun, p_reghol, p_holsun, 
                                     p_outer_no, p_outer_fr, p_outer_to, p_outer_ad, p_outad_fr, p_outad_to );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_overtm) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) || ':' || 
                                     to_char(p_outer_no) || ':' || to_char(p_outer_fr) || ':' || to_char(p_outer_to) || ':' || to_char(p_outer_ad) || ':' || to_char(p_outad_fr) || ':' || 
                                     to_char(p_outad_to) );
   sp_count_ofc_attendance ('00368', to_date('20070116', 'YYYYMMDD'), to_date('20070131', 'YYYYMMDD'), p_numday, p_overtm, p_regsun, p_reghol, p_holsun, 
                                     p_outer_no, p_outer_fr, p_outer_to, p_outer_ad, p_outad_fr, p_outad_to );
   dbms_output.put_line ('check out: ' || to_char(p_numday) || ':' || to_char(p_overtm) || ':' || to_char(p_regsun) || ':' || to_char(p_reghol) || ':' || to_char(p_holsun) || ':' || 
                                     to_char(p_outer_no) || ':' || to_char(p_outer_fr) || ':' || to_char(p_outer_to) || ':' || to_char(p_outer_ad) || ':' || to_char(p_outad_fr) || ':' || 
                                     to_char(p_outad_to) );
end;
/

