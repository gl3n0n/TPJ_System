create or replace procedure sp_acc_pop_jv_sum(p_date_fr date, p_date_to date) as
  v_pc_code         varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
  v_sal_code        varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('SALARIES ACCOUNT CODE');
  --v_matrl_code      varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('SUPPLIES ACCOUNT CODE');
  v_repair_code     varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('REPAIR ACCOUNT CODE');
  v_meal_code       varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('MEALS ACCOUNT CODE');
  v_financial_code  varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('FINANCIAL ACCOUNT CODE');
  v_adv_code        varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('ADVANCES ACCOUNT CODE');
  v_adv_marina_code varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('ADVANCES MARINA CODE');
  v_adv_pcg_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('ADVANCES PCG CODE');
  v_transpo_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('TRANSPO ACCOUNT CODE');
  v_cash_bpi_amt    number(14,4) := 0;
  v_pc_amt          number(14,4) := 0;
  v_sal_amt         number(14,4) := 0;
  v_matrl_amt       number(14,4) := 0;
  v_repair_amt      number(14,4) := 0;
  v_meal_amt        number(14,4) := 0;
  v_financial_amt   number(14,4) := 0;
  v_adv_amt         number(14,4) := 0;
  v_adv_marina_amt  number(14,4) := 0;
  v_adv_pcg_amt     number(14,4) := 0;
  v_transpo_amt     number(14,4) := 0;
  v_sun_cre_amt     number(14,4) := 0;
  v_sun_deb_amt     number(14,4) := 0;
begin
  delete from acc_jv_summary
  where  userid = user;
  delete from acc_jv_summary_sundry
  where  userid = user;
  commit;
  for a in
    (
    select d.acco_code, d.debit_php, d.credit_php, h.particular, h.jv_no, h.jv_date
    from   acc_jv_hdr h, acc_jv_dtl d
    where  h.jv_no = d.jv_no
    and    h.jv_status <> 'CANCELLED'
    and    h.jv_date >= p_date_fr
    and    h.jv_date <= p_date_to
    )
  loop
      v_cash_bpi_amt    := 0;
      v_pc_amt          := 0;
      v_sal_amt         := 0;
      v_matrl_amt       := 0;
      v_repair_amt      := 0;
      v_meal_amt        := 0;
      v_financial_amt   := 0;
      v_adv_amt         := 0;
      v_adv_marina_amt  := 0;
      v_adv_pcg_amt     := 0;
      v_transpo_amt     := 0;
      v_sun_cre_amt     := 0;
      v_sun_deb_amt     := 0;
    if a.acco_code = '10002' then
       v_cash_bpi_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_pc_code then
       v_pc_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_sal_code then
       v_sal_amt := a.debit_php - a.credit_php;
    --elsif a.acco_code = v_matrl_code then
    --   v_matrl_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_repair_code then
       v_repair_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_meal_code then
       v_meal_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_financial_code then
       v_financial_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_adv_code then
       v_adv_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_adv_marina_code then
       v_adv_marina_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_adv_pcg_code then
       v_adv_pcg_amt := a.debit_php - a.credit_php;
    elsif a.acco_code = v_transpo_code then
       v_transpo_amt := a.debit_php - a.credit_php;
    else
       if a.credit_php < 0 then
          v_sun_deb_amt := v_sun_deb_amt + abs(a.credit_php);
       else
          v_sun_cre_amt := v_sun_cre_amt + a.credit_php;
       end if;
       if a.debit_php < 0 then
          v_sun_cre_amt := v_sun_cre_amt + abs(a.debit_php);
       else
          v_sun_deb_amt := v_sun_deb_amt + a.debit_php;
       end if;
       insert into acc_jv_summary_sundry(jv_no, sundry, debit, credit, userid, acco_code)
       values (a.jv_no, sf_acc_get_account_name(a.acco_code), v_sun_deb_amt, v_sun_cre_amt, user, a.acco_code);
    end if;
    insert into acc_jv_summary
       (jv_no, jv_date, particular, cash_bpi_amt, pc_amt, salaries_amt,
        meals_amt, financial_amt, repairs_amt, rep_amt, rep_marina_amt, rep_pcg_amt,
        transpo_amt, userid)
    values
       (a.jv_no, a.jv_date, a.particular, v_cash_bpi_amt, v_pc_amt, v_sal_amt,
        v_meal_amt, v_financial_amt, v_repair_amt, v_adv_amt, v_adv_marina_amt, v_adv_pcg_amt,
        v_transpo_amt, user);
  end loop;
  commit;
end sp_acc_pop_jv_sum;
