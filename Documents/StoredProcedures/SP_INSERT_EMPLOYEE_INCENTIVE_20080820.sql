create or replace procedure sp_insert_employee_incentive
(
   p_empl_id      varchar2,
   p_year         varchar2,
   p_mo           varchar2,
   p_start        date,
   p_end          date,
   p_inty_code    varchar2,
   p_vess_code    varchar2,
   p_rank_code    varchar2,
   p_fiso_code    varchar2,
   p_basis        number,
   p_rate         number,
   p_amt          number,
   p_inhd_tran_no number
) as

   vErrMsg      varchar2(2000);

begin
   insert into pys_employee_incentives
          (
            empl_empl_id, year, mo, period_fr, period_to, inty_code, fiso_code, vess_code, rank_code,
            basis, rate, amt, inhd_tran_no, dt_created, created_by
          )
   values (
            p_empl_id, p_year, p_mo, p_start, p_end, p_inty_code, p_fiso_code, p_vess_code, p_rank_code,
            p_basis, p_rate, p_amt, p_inhd_tran_no, trunc(sysdate), user
          );
   commit;
exception
   when dup_val_on_index then null;
   when others then
      vErrMsg := SQLERRM;
      raise_application_error (-20001, vErrMsg);
end sp_insert_employee_incentive;
/
