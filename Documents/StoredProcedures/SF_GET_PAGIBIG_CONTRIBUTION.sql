create or replace function sf_get_pagibig_contribution 
   ( p_salary in number
   ) 
   return number is
   nAmt Number;
begin
   if p_salary >= 5000 then
      nAmt := 100;
   elsif p_salary > 2500 and p_salary < 5000 then  
      nAmt := p_salary * .01;
   else
      nAmt := 25;
   end if;
   return nAmt;
end sf_get_pagibig_contribution;
/
