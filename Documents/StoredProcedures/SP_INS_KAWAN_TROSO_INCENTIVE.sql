create or replace procedure sp_ins_kawan_troso_incentive
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
   p_inhd_tran_no number,
   p_vess_code_2  varchar2
) as

   vErrMsg      varchar2(2000);
   d_empl_id    varchar2(20) := 'G00017';
begin
   insert into pys_kawan_troso_incentives
          (
            empl_empl_id, year, mo, period_fr, period_to, inty_code, fiso_code, vess_code, rank_code,
            basis, rate, amt, inhd_tran_no, vess_code_2, dt_created, created_by
          )
   values (
            p_empl_id, p_year, p_mo, p_start, p_end, p_inty_code, p_fiso_code, p_vess_code, p_rank_code,
            p_basis, p_rate, p_amt, p_inhd_tran_no, p_vess_code_2, trunc(sysdate), user
          );
   commit;
exception
   when dup_val_on_index then 
      IF p_empl_id = d_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check insert p_inty_code:' || p_inty_code || ',p_vess_code:' || p_vess_code || ',p_fiso_code:' ||  p_fiso_code || ',p_basis:' || TO_CHAR(p_basis));
      END IF;
   when others then
      vErrMsg := SQLERRM;
      raise_application_error (-20001, vErrMsg);
end sp_ins_kawan_troso_incentive;
