create or replace procedure SP_PYS_REVERSE_ADJUSTMENT (
   p_payroll_no varchar2,
   p_empl_empl_id varchar2) as
begin
   for i in (select empl_empl_id, seq_no, paty_code, basic_rate, amt, basic_rate_g, amt_g 
             from pys_payroll_dtl_adj_log 
             where empl_empl_id =p_empl_empl_id 
             and pahd_payroll_no = p_payroll_no)
   loop
      update pys_payroll_dtl
      set    basic_rate    = i.basic_rate, 
             amt           = i.amt, 
             basic_rate_g  = i.basic_rate_g, 
             amt_g         = i.amt_g,
             adj_approval    = 'N',
             adj_approved_by = null,
             adj_approved_dt = null
      where  pahd_payroll_no = p_payroll_no
      and    seq_no = i.seq_no;
   end loop;

   update pys_payroll_dtl_adj_log 
   set    adj_approval    = 'N',
          adj_approved_by = null,
          adj_approved_dt = null
   where empl_empl_id = p_empl_empl_id
   and   pahd_payroll_no = p_payroll_no;

   commit;

end sp_pys_reverse_adjustment;
/
