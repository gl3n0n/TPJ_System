create or replace procedure sp_acc_pop_ap_sum(p_date_fr date, p_date_to date) as
  v_ewt_code      varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('EWT');
  v_ap_code       varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('AP ACCOUNT CODE');
  v_matrl_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('SUPPLIES ACCOUNT CODE');
  v_repair_code   varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('REPAIR ACCOUNT CODE');
  v_nets_code     varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('NETS ACCOUNT CODE');
  v_fuels_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('FUELS ACCOUNT CODE');
  v_lubri_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('LUBRICANTS ACCOUNT CODE');
  v_comm_code     varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('COMMUNICATIONS ACCOUNT CODE');
  v_security_code varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('SECURITY ACCOUNT CODE');
  v_ofc_code      varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('OFFICE ACCOUNT CODE');
  v_ewt_amt       number(14,4) := 0;
  v_ap_amt        number(14,4) := 0;
  v_matrl_amt     number(14,4) := 0;
  v_repair_amt    number(14,4) := 0;
  v_nets_amt      number(14,4) := 0;
  v_fuels_amt     number(14,4) := 0;
  v_lubri_amt     number(14,4) := 0;
  v_comm_amt      number(14,4) := 0;
  v_security_amt  number(14,4) := 0;
  v_ofc_amt       number(14,4) := 0;  
begin
  delete from acc_ap_summary 
  where  userid = user;
  delete from acc_ap_summary_sundry 
  where  userid = user;
  commit;
  
  for a in 
    (
    select d.acco_code, d.debit_php, d.credit_php, h.supp_code, h.ap_no, h.ap_date
    from   acc_ap_hdr h, acc_ap_dtl d
    where  h.ap_no = d.ap_no
    and    h.ap_status <> 'CANCELLED'
    and    h.ap_date >= p_date_fr
    and    h.ap_date <= p_date_to
    )
  loop
    v_ewt_amt       := 0;  
    v_ap_amt        := 0;  
    v_matrl_amt     := 0;  
    v_repair_amt    := 0;  
    v_nets_amt      := 0;  
    v_fuels_amt     := 0;  
    v_lubri_amt     := 0;  
    v_comm_amt      := 0;  
    v_security_amt  := 0;  
    v_ofc_amt       := 0;  

    if a.acco_code = v_ewt_code then
       v_ewt_amt := a.credit_php - a.debit_php;
    elsif a.acco_code = v_ap_code then
       v_ap_amt := a.credit_php - a.debit_php;
    elsif a.acco_code = v_matrl_code then
       v_matrl_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_repair_code then
       v_repair_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_nets_code then
       v_nets_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_fuels_code then
       v_fuels_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_lubri_code then
       v_lubri_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_comm_code then
       v_comm_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_security_code then
       v_security_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_ofc_code then
       v_ofc_amt := a.debit_php - a.credit_php;
    else
       insert into acc_ap_summary_sundry(ap_no, sundry, credit, debit, userid)
       values (a.ap_no, sf_acc_get_account_name(a.acco_code), a.credit_php, a.debit_php, user);
    end if;
    
    insert into acc_ap_summary (ap_no, ap_date, supp_code, expanded_amt, ap_amt, matrl_amt, 
                                repair_amt, nets_amt, fuel_amt, lub_amt, comm_amt, ofc_amt, userid)
    values (a.ap_no, a.ap_date, a.supp_code, v_ewt_amt, v_ap_amt, v_matrl_amt, 
                                v_repair_amt, v_nets_amt, v_fuels_amt, v_lubri_amt, v_comm_amt, v_ofc_amt, user);
                                
  end loop;
  commit;
end; 
/
