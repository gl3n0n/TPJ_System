-- Miral, Cerilo               M00026 18reg 15cola
-- Paragatos, Rodrigo          P00015 15reg 15cola
-- Cuetara, Elorde Villavan    C00034 15reg 15cola
-- Manansala, Jose Sunga jr    M00038 15reg 15cola 3regadj 3cola  Embarked=26-Jul

UPDATE pys_payroll_dtl_log SET cola_day=1,cola_pay=5 where empl_empl_id = 'M00026' and pay_date = to_date('20080727', 'YYYYMMDD');
UPDATE pys_payroll_dtl_log SET cola_day=1,cola_pay=5 where empl_empl_id = 'P00015' and pay_date = to_date('20080727', 'YYYYMMDD');
commit;


UPDATE pys_payroll_dtl_adj_log set adj_approval='N',adj_approved_by=null,adj_approved_dt=null where empl_empl_id = 'C00034' and pahd_payroll_no = 20080815;
UPDATE pys_payroll_dtl set adj_approval='N',adj_approved_by=null,adj_approved_dt=null where empl_empl_id = 'C00034' and pahd_payroll_no = 20080815;
commit;



select seq_no, paty_code, no_days from pys_payroll_dtl_adj_log where empl_empl_id = 'C00034' and pahd_payroll_no = 20080815;
select seq_no, paty_code, no_days, a_no_days  from pys_payroll_dtl_adj_log where empl_empl_id = 'C00034' and pahd_payroll_no = 20080815;
