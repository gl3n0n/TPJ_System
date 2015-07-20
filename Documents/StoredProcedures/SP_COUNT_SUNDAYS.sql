create or replace function sf_count_sundays 
(
   p_date_fr in date, 
   p_date_to in date
) 
   return number is
   nCtr  Number := 0;
   nUpTO Number := 0;
begin
   nUpTo := (p_date_to-p_date_fr); 
   for i in 1..nUpTo loop
      if to_char(p_date_fr +1, 'fmDAY') = 'SUNDAY' then
         nCtr := nCtr + 1;
      end if;  
   end loop;
   return nCtr; 
end sf_count_sundays;
/
show err
