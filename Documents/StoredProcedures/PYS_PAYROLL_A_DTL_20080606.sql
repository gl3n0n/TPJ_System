CREATE TABLE PYS_PAYROLL_A_DTL
 (    PAYROLL_MO NUMBER(8,0),
      EMPL_EMPL_ID VARCHAR2(16),
      BASIC_RATE NUMBER,
      NO_DAYS NUMBER,
      AMT NUMBER,
      PAGIBIG NUMBER,
      PAGIBIG_LOAN NUMBER,
      SAL_LOAN NUMBER,
      SSS NUMBER,
      SSS_LOAN NUMBER,
      PHILHEALTH NUMBER,
      WHTAX NUMBER,
      TITLE VARCHAR2(32),
      VESS_CODE VARCHAR2(16),
      DEPT_CODE VARCHAR2(16),
      OT NUMBER,
      COLA NUMBER,
      SAL_FREQ VARCHAR2(16),
      LATEST_VESS VARCHAR2(32)
 );

create index pay_idx on PYS_PAYROLL_A_DTL (PAYROLL_MO, empl_empl_id);


 create or replace function sf_get_whtax_a
   ( p_empl_id in varchar2,
     p_salary  in number
   )
   return number is
   nBSal  Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
   vTatyCode Varchar2(16);
begin
   select taty_code
   into   vTatyCode
   from   pms_employees
   where  empl_id = p_empl_id;

   if vTatyCode is null then
      raise_application_error (-20001, 'No assigned Tax Type for employee  - ' || p_empl_id);
   end if;

   select salary_fr, base_tax, over_pct
   into   nBSal, nBTax, nRate
   from   pys_withholding_tax
   where  taty_code = vTatyCode
   and    p_salary between salary_fr and salary_to;

   if nRate > 0 then
      nWTax := nBTax + ((p_salary - nBSal) * (nRate/100));
   else
      nWTax := nBTax;
   end if;
   return nWTax;
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Withholding tax table. No range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   when too_many_rows then
      raise_application_error (-20001, 'Check your Withholding tax table. Too many range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
end sf_get_whtax_a;
/
