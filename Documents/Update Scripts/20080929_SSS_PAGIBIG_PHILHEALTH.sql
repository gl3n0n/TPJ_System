declare
   nSSS_ER Number(10,2);
   nSSS_EC Number(10,2);
   nSSS    Number(10,2);
begin
   for i in (select empl_empl_id, basic_rate nSalaryG, amt nSSS
             from   PYS_PAYROLL_DTL 
             WHERE  pahd_payroll_no = 20080930 
             AND    adj_approval ='Y' 
             and    paty_code = 'SSS'
            )
   loop
      -- compute SSS
      nSSS_ER := 0;
      nSSS_EC := 0;
      BEGIN
         sp_get_sss_contribution_er_ee (i.nSalaryG, nSSS, nSSS_ER, nSSS_EC);
         INSERT INTO PYS_SSS_CONTRIBUTION
                ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, created_by, dt_created )
         VALUES ( to_date('20080901','YYYYMMDD'), to_date('20080930','YYYYMMDD'), i.empl_empl_id, i.nSSS, nSSS_ER, NVL(nSSS_EC,0), USER, SYSDATE );
      EXCEPTION
         WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - sss contribution for ' || i.empl_empl_id || '/' ||  i.nSSS || '/' || nSSS_ER || '/' || nSSS_EC || '/' || TO_CHAR(i.nSalaryG));
      
      END;
   end loop;
end;
/

declare
   nPagibig_ER Number(10,2);
   nPagibig    Number(10,2);
begin
   for i in (select empl_empl_id, basic_rate nSalaryG, amt nPagibig
             from   PYS_PAYROLL_DTL 
             WHERE  pahd_payroll_no = 20080930 
             AND    adj_approval ='Y' 
             and    paty_code = 'PHILHEALTH'
            )
   loop
      -- compute Pag-ibig
      nPagibig_ER := 0;  
      BEGIN
         sp_get_pagibig_ee_er (i.nSalaryG, nPagibig, nPagibig_ER);
         INSERT INTO PYS_PAGIBIG_CONTRIBUTION
                ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
         VALUES ( to_date('20080901','YYYYMMDD'), to_date('20080930','YYYYMMDD'), i.empl_empl_id, i.nPagibig, nPagibig_ER, USER, SYSDATE );
      
      END;
   end loop;
end;
/

declare
   nPhHealth     Number(10,2);
   nPhHealth_ER  Number(10,2);
begin
   for i in (select empl_empl_id, basic_rate nSalaryG, amt nPhHealth
             from   PYS_PAYROLL_DTL 
             WHERE  pahd_payroll_no = 20080930 
             AND    adj_approval ='Y' 
             and    paty_code = 'PAGIBIG'
            )
   loop
      -- compute Philhealth
      BEGIN
         nPhHealth_ER := 0;
         sp_get_philhealth_ee_er (i.nSalaryG, nPhHealth, nPhHealth_ER);
         -- populate pag-ibig ER and EE contribution
         INSERT INTO PYS_PHILHEALTH_CONTRIBUTION
                ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
         VALUES ( to_date('20080901','YYYYMMDD'), to_date('20080930','YYYYMMDD'), i.empl_empl_id, i.nPhHealth, nPhHealth_ER, USER, SYSDATE );
     END;
   end loop;
end;
/
