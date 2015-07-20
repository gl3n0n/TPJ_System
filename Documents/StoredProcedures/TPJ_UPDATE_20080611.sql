alter table pys_payroll_dtl add whtax number(10,2) default 0 not null;

begin
   for i in (select pahd_payroll_no, empl_empl_id, sum(no_days) ndays, max(basic_rate) nrate, sum(sss+pagibig+philhealth) dedu
             from   pys_payroll_a
             where  period_to between to_date('20080531', 'YYYYMMDD') and to_date('20080531','YYYYMMDD')
             group by  pahd_payroll_no, empl_empl_id
             having  sum(no_days) > 0 
             and     max(basic_rate) > 0)
   loop
      update pys_payroll_dtl
      set    whtax = sf_get_whtax_a(empl_empl_id, (i.ndays*i.nrate-(i.dedu)))
      where  empl_empl_id = i.empl_empl_id
      and    pahd_payroll_no = i.pahd_payroll_no
      and    paty_code='REG';
   end loop;
end;
/

commit;
