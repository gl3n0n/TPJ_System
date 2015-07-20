select empl_empl_id, count(1)
              from   pys_payroll_dtl_adj_log
              where  pahd_payroll_no = 20080831
              and    adj_approval = 'Y'
group by empl_empl_id

begin
   for i in (select no_days, basic_rate, amt, basic_rate_g, amt_g, empl_empl_id, pahd_payroll_no, seq_no
              from   pys_payroll_dtl_adj_log
              where  pahd_payroll_no = 20080831
              and    adj_approval = 'Y' )
   loop
      update pys_payroll_dtl 
      set    no_days = nvl(i.no_days,0),
             basic_rate = nvl(i.basic_rate,0),
             amt = nvl(i.amt,0),
             basic_rate_g = nvl(i.basic_rate_g,0),
             amt_g = nvl(i.amt_g,0),
             adj_approval    = 'N',
             adj_approved_by = NULL,
             adj_approved_dt = NULL
      where empl_empl_id = i.empl_empl_id
      and   pahd_payroll_no = i.pahd_payroll_no
      and   seq_no = i.seq_no;

      update pys_payroll_dtl_adj_log 
      set    adj_approval    = 'N',
             adj_approved_by = NULL,
             adj_approved_dt = NULL
      where empl_empl_id = i.empl_empl_id
      and   pahd_payroll_no = i.pahd_payroll_no
      and   seq_no = i.seq_no;

   end loop;
end;
/
