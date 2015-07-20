create or replace procedure sp_get_pagibig_ee_er
   ( p_salary in  number,
     p_ee     out number,
     p_er     out number
   ) 
   is
   nEE Number;
   nER Number;
begin

   if p_salary >= 5000 then
      nEE := 100;
      nER := 100;
   elsif p_salary > 2500 and p_salary < 5000 then  
      nEE := p_salary * .01;
      nER := p_salary * .02;
   else
      nEE := 25;
      nER := 50;
   end if;

   p_ee := nEE;
   p_er := nER;

end sp_get_pagibig_ee_er;
/
