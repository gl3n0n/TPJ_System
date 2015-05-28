  CREATE OR REPLACE FUNCTION "TPJ"."GETURL" (p_report varchar2, p_logon in varchar2) return varchar2 is
begin
   return null;
end;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."GET_ITEM_DESC" (p_item_code VARCHAR2, p_cate_code VARCHAR2, p_itty_code VARCHAR2, p_itgr_code VARCHAR2)
RETURN VARCHAR2
AS
  vname VARCHAR2(1012);
BEGIN
SELECT ITTY.DESCRIPTION ||
       DECODE(ITEM.MATE_CODE, NULL, '', ' ' || MATE.DESCRIPTION) ||
       DECODE(ITEM.ISZE_CODE, NULL, '', ' ' || ISZE.DESCRIPTION) ||
       DECODE(ITEM.VOLT_CODE, NULL, '', ' ' || VOLT.DESCRIPTION) ||
       DECODE(ITEM.BRAN_CODE, NULL, '', ' ' || BRAN.DESCRIPTION) ||
       DECODE(ITEM.MODL_CODE, NULL, '', ' ' || MODL.DESCRIPTION) ||
       DECODE(ITEM.ACCE_CODE, NULL, '', ' ' || ACCE.DESCRIPTION) ||
       DECODE(ITEM.COLO_CODE, NULL, '', ' ' || COLO.DESCRIPTION) ||
       DECODE(ITEM.SHAP_CODE, NULL, '', ' ' || SHAP.DESCRIPTION) ||
       DECODE(ITEM.SOUR_CODE, NULL, '', ' ' || SOUR.DESCRIPTION) ||
       DECODE(ITEM.TYPE_CODE, NULL, '', ' ' || TYPE.NAME) ||
       DECODE(ITEM.SERIAL_NO, NULL, '', ' ' || ITEM.SERIAL_NO) ||
       DECODE(ITEM.PART_NO, NULL, '', ' ' || ITEM.PART_NO) ITEM_NAME
INTO vname
FROM INV_ITEMS ITEM,
     INV_ACCESSORY ACCE,
     INV_BRAND BRAN,
     INV_COLOR COLO,
     INV_MATERIAL MATE,
     INV_MODEL MODL,
     INV_SHAPE SHAP,
     INV_SIZE ISZE,
     INV_VOLTAGE VOLT,
         INV_SOURCE SOUR,
         INV_TYPES TYPE,
         INV_ITEM_TYPES ITTY
WHERE P_ITTY_CODE = ITEM.ITTY_CODE
AND   P_ITGR_CODE = ITEM.ITGR_CODE
AND   P_CATE_CODE = ITEM.CATE_CODE
AND   P_ITEM_CODE = ITEM.CODE
AND   ITTY.CODE = ITEM.ITTY_CODE
AND   ITEM.ACCE_CODE = ACCE.CODE(+)
AND   ITEM.BRAN_CODE = BRAN.CODE(+)
AND   ITEM.COLO_CODE = COLO.CODE(+)
AND   ITEM.MATE_CODE = MATE.CODE(+)
AND   ITEM.MODL_CODE = MODL.CODE(+)
AND   ITEM.SHAP_CODE = SHAP.CODE(+)
AND   ITEM.ISZE_CODE = ISZE.CODE(+)
AND   ITEM.VOLT_CODE = VOLT.CODE(+)
AND   ITEM.SOUR_CODE = SOUR.CODE(+)
AND   ITEM.TYPE_CODE = TYPE.CODE(+);
RETURN vname;
END;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."GET_SUBS_CODE"
 (P_SUBS_DESC IN VARCHAR2
 ,P_SUBS_TYPE IN VARCHAR2
 )
 RETURN NUMBER
 IS
-- PL/SQL Specification
v_subsidiary_code subsidiaries.subsidiary_code%TYPE;
   v_count number := 0;

-- PL/SQL Block
BEGIN
   SELECT COUNT(*)
   INTO v_count
   FROM subsidiaries
   WHERE RTRIM(description) = RTRIM(p_subs_desc)
      AND sutp_subsidiary_type_code = p_subs_type;

   IF v_count = 0 THEN
      SELECT subs_seq.nextval
      INTO v_subsidiary_code
      FROM dual;

      INSERT INTO subsidiaries (
         subsidiary_code,
         sutp_subsidiary_type_code,
         description)
      VALUES (
         v_subsidiary_code,
         p_subs_type,
         p_subs_desc);
   ELSE
      SELECT subsidiary_code
      INTO v_subsidiary_code
      FROM subsidiaries
      WHERE RTRIM(description) = RTRIM(p_subs_desc)
         AND sutp_subsidiary_type_code = p_subs_type;
   END IF;

   RETURN v_subsidiary_code;

EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20001, SUBSTR(SQLERRM, 1, 100) ||
         ' called from GET_SUBS_CODE function.');
END GET_SUBS_CODE;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_300_600_RATE"
(
   p_rank  in varchar2,
   p_catch in number
)  return number is

   nRate   pys_incentives.rate%type;

begin

   select rate
   into   nRate
   from   pys_incentives
   where  inty_code = '300_600'
   and    rank_code = p_rank
   and    p_catch between range_fr and range_to
   and    rownum = 1;

   return nRate;

exception
   when no_data_found then
      return 0;

end sf_300_600_rate;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_ACC_GET_ACCOUNT_NAME" (p_acco_code varchar2) return varchar is
  v_acco_name acc_accounts.name%type;
begin
  select name
  into   v_acco_name
  from   acc_accounts
  where  code = p_acco_code;
  return v_acco_name;
exception
  when no_data_found then
     return p_acco_code;
end;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_ACC_GET_RECEIPT_DTL" (
   p_reftype in varchar2,
   p_refcode in varchar2 ) return varchar2 is
   vDescription Varchar2(512);
begin
   if p_reftype = 'JV' then
      for i in (select ref_code, ref_type from acc_jv_dtl
                where  jv_no = p_refcode
                and    acco_code = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH') )
      loop
         if vDescription is null then
            vDescription := i.ref_type || '-' || i.ref_code;
         else
            vDescription := vDescription || ',' || i.ref_type || '-' || i.ref_code;
         end if;
      end loop;
   elsif p_reftype = 'CV' then
      for i in (select ref_code, ref_type from acc_cv_dtl
                where  cv_no = p_refcode
                and    acco_code = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH') )
      loop
         if vDescription is null then
            vDescription := i.ref_type || '-' || i.ref_code;
         else
            vDescription := vDescription || ',' || i.ref_type || '-' || i.ref_code;
         end if;
      end loop;
   end if;
   return vDescription;
end sf_acc_get_receipt_dtl;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_ACC_PCR_POSTING" (
    p_pcr_no   in  number,
    p_pcr_desc in  varchar2
   ) return Number
   as
   nJV_No  Number;
   nChk_JV_No  Number;
   nItemNo Number := 0;
   nDebit  Number(12,2) := 0;
   vOfc_code Varchar2(16);
   vPettyCashCode Varchar2(16);
   dMin    Date;
   dMax    Date;
begin
   begin
      select jv_no, ofc_code
      into   nChk_JV_No, vOfc_code
      from   acc_pcr_hdr
      where  pcr_no = p_pcr_no;
   exception
      when no_data_found then
         raise_application_error (-20001, 'This PCR PCR No.' || to_char(p_pcr_no, 'B000009')  || ' does not exists.');
      when others then
         raise_application_error (-20001, SQLERRM || ' - PCR No.' || to_char(p_pcr_no, 'B000009'));
   end;

   if nChk_JV_No is not null then
      raise_application_error (-20001, 'This PCR has already been processed and it has a JV No.' || to_char(nChk_JV_No, 'B000009') );
   end if;

   -- create JV header
   select nvl(max(jv_no),0)+1
   into   nJV_No
   from   acc_jv_hdr;
   select min(pcv_date), max(pcv_date)
   into   dMin, dMax
   from   acc_pcr_dtl
   where  pcr_no = p_pcr_no;
   insert into acc_jv_hdr
          ( jv_no, jv_date, jv_status, particular, curr_code, prepared_by, dt_prepared, created_by, dt_created, checked_by, approved_by )
   values ( nJV_No, trunc(sysdate), 'NEW', p_pcr_desc||' PCR#'|| decode(greatest(length(p_pcr_no),6), 6, to_char(p_pcr_no, 'B000009'), to_char(p_pcr_no)), 'PHP', sf_get_empl(user), sysdate, user, sysdate, 'M00020','T00011');

   for i in (select acco_code, sum(nvl(amt,0)) sum_amt
             from   acc_pcr_dtl
             where  pcr_no = p_pcr_no
             group  by acco_code
             --having sum(amt)>0
             )
   loop
      nItemNo := nItemNo + 1;

      if i.sum_amt = 0 then
          insert into acc_jv_dtl
                 ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
          values ( nJV_No, nItemNo, i.acco_code, 'OTH', null, null, 0, 0, user, sysdate, 0, 0);
      else
          insert into acc_jv_dtl
                 ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
          values ( nJV_No, nItemNo, i.acco_code, 'OTH', null, null, decode((nvl(i.sum_amt,0)*-1)/abs(nvl(i.sum_amt,0)),1,0,abs(nvl(i.sum_amt,0))),
                   decode((nvl(i.sum_amt,0)*-1)/abs(nvl(i.sum_amt,0)),1,abs(nvl(i.sum_amt,0)),0), user, sysdate,
                   decode((nvl(i.sum_amt,0)*-1)/abs(nvl(i.sum_amt,0)),1,0,abs(nvl(i.sum_amt,0))),
                   decode((nvl(i.sum_amt,0)*-1)/abs(nvl(i.sum_amt,0)),1,abs(nvl(i.sum_amt,0)),0) );
      end if;

      nDebit := nDebit + i.sum_amt;

   end loop;


   if vOfc_code = 'HO' then
      vPettyCashCode := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
   else
      vPettyCashCode := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH GENSAN');
   end if;

   -- create credit entry
   begin
      nItemNo := nItemNo + 1;
      insert into acc_jv_dtl
             ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
      values ( nJV_No, nItemNo, vPettyCashCode, 'OTH',  NULL, 'PCR# ' || decode(greatest(length(p_pcr_no),6), 6, to_char(p_pcr_no, 'B000009')), 0, nDebit, user, sysdate, 0, nDebit );
   exception
      when others then
         raise_application_error (-20001, SQLERRM || ' for PCV_NO ' || to_char(p_pcr_no, 'B000009') );
   end;
   return nJV_No;
   --update acc_pcr_hdr
   --set    jv_no = nJV_No,
   --       pcv_status  = 'POSTED',
   --       approved_by_sys = sf_get_empl(user),
   --       dt_approved_sys = sysdate
   --where  pcr_no = p_pcr_no;
   --commit;
end sf_acc_pcr_posting;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_CHECK_ITEM_REORDER_QTY" (
   p_item in varchar2,
   p_cate in varchar2,
   p_itty in varchar2,
   p_itgr in varchar2,
   p_uome in varchar2,
   p_avail in number
   ) return number is
   nReorderQty Number;
begin
   select nvl(re_order_qty,0)
   into   nReorderQty
   from   inv_items_log
   where  code = p_item
   and    cate_code = p_cate
   and    itgr_code = p_itgr
   and    itty_code = p_itty
   and    uome_code = p_uome;
   if (nvl(nReorderQty,0) > 0) then
      if (nvl(nReorderQty,0) <= p_avail) then
         begin
            insert into inv_items_reorder_log
                   (item_code, cate_code, itty_code, itgr_code, uome_code, re_order_dt, re_order_qty, avail_qty, created_by, dt_created)
            values (p_item, p_cate, p_itty, p_itgr, p_uome, trunc(sysdate), nReorderQty, p_avail, user, sysdate);
            commit;
         exception
            when dup_val_on_index then null;
         end;
         return 1;
      else
         return 0;
      end if;
   else
      return 0;
   end if;
exception
   when no_data_found then
      return 0;
end sf_check_item_reorder_qty;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_COUNT_HOLIDAY_SUNDAYS"
(
   p_date_fr in date,
   p_date_to in date
)
   return number is
   dChkDate Date;
   nCtr  Number := 0;
   nUpTO Number := 0;
begin
   nUpTo := (p_date_to-p_date_fr)+1;
   dChkDate := p_date_fr -1;
   for i in 1..nUpTo loop
      dChkDate := dChkDate + 1;
      if sf_is_sunday (dChkDate) = 1 then
         nCtr := nCtr + 1;
      end if;
      if sf_is_holiday (dChkDate) = 1 then
         nCtr := nCtr + 1;
      end if;
   end loop;
   return nCtr;
end sf_count_holiday_sundays;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_COUNT_SUNDAYS"
(
   p_empl_id in varchar2,
   p_date_fr in date,
   p_date_to in date
)
   return number is
   dChkDate Date;
   nCtr  Number := 0;
   nUpTO Number := 0;
   nDummy Number;
begin
   nUpTo := (p_date_to-p_date_fr)+1;
   dChkDate := p_date_fr -1;
   for i in 1..nUpTo loop
      dChkDate := dChkDate + 1;
      if sf_is_sunday (dChkDate) = 1 then
         begin
            select num_hours
            into   nDummy
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dChkDate;
            nCtr := nCtr + 1;
         exception
            when no_data_found then null;
         end;
      end if;
   end loop;
   return nCtr;
end sf_count_sundays;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_COUNT_SUNDAYS_OP"
(
   p_empl_id in varchar2,
   p_date_fr in date,
   p_date_to in date,
   p_outer   in varchar2
)
   return number is
   dChkDate Date;
   nCtr  Number := 0;
   nUpTO Number := 0;
   nDummy Number;
begin
   nUpTo := (p_date_to-p_date_fr)+1;
   dChkDate := p_date_fr -1;
   for i in 1..nUpTo loop
      dChkDate := dChkDate + 1;
      if sf_is_sunday (dChkDate) = 1 then
         begin
            select num_hours
            into   nDummy
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dChkDate
            and    outer_port = p_outer;
            nCtr := nCtr + 1;
         exception
            when no_data_found then null;
         end;
      end if;
   end loop;
   return nCtr;
end sf_count_sundays_op;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GENERATE_ITEM_DESCRTIPTION"
   (p_item_type        in varchar2,
    p_mate_description in varchar2,
    p_isze_description in varchar2,
    p_volt_description in varchar2,
    p_bran_description in varchar2,
    p_modl_description in varchar2,
    p_acce_description in varchar2,
    p_colo_description in varchar2,
    p_shap_description in varchar2,
    p_sour_description in varchar2,
    p_type_desc in varchar2,
    p_serial_no in varchar2,
    p_part_no in varchar2
   ) RETURN Varchar2 IS
   vItemDesc Varchar2(512);
BEGIN
   select p_item_type ||
          DECODE(p_mate_description, NULL, '', ' ' || p_mate_description) ||
          DECODE(p_isze_description, NULL, '', ' ' || p_isze_description) ||
          DECODE(p_volt_description, NULL, '', ' ' || p_volt_description) ||
          DECODE(p_bran_description, NULL, '', ' ' || p_bran_description) ||
          DECODE(p_modl_description, NULL, '', ' ' || p_modl_description) ||
          DECODE(p_acce_description, NULL, '', ' ' || p_acce_description) ||
          DECODE(p_colo_description, NULL, '', ' ' || p_colo_description) ||
          DECODE(p_shap_description, NULL, '', ' ' || p_shap_description) ||
          DECODE(p_sour_description, NULL, '', ' ' || p_sour_description) ||
          DECODE(p_type_desc,        NULL, '', ' ' || p_type_desc) ||
          DECODE(p_serial_no,        NULL, '', ' ' || p_serial_no) ||
          DECODE(p_part_no,          NULL, '', ' ' || p_part_no)
    into  vItemDesc
    from  dual;
    return vItemDesc;
exception
    when others then return p_item_type;
END sf_generate_item_descrtiption;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_13TH_MONTH"
   ( p_empl_id in  varchar2,
     p_effdate in  date
   )
   return number is
   nSalary Number;
   dEffDate Date;
begin
   if p_empl_id is null then
      nSalary := 0;
   else
      --select max(eff_date)
      --into   dEffDate
      --from   pys_13th_month_summary
      --where  p_salary between salary_fr and salary_to
      --and    eff_date <= p_effdate;

      --select fix_tax, base_tax, over_pct
      --into   nFix, nBTax, nRate
      --from   pys_tax_rates
      --where  eff_date = dEffDate
      --and    p_salary between salary_fr and salary_to;
      return 0;
   end if;
   return nSalary;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_13th_month;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_ACC_EWT" RETURN NUMBER AS
BEGIN
  FOR a IN (SELECT ewt_num FROM acc_ewt WHERE SYSDATE BETWEEN fr_date AND NVL(TO_DATE,SYSDATE) ORDER BY fr_date, TO_DATE)
  LOOP
    RETURN a.ewt_num;
  END LOOP;
  RAISE_APPLICATION_ERROR(-20001,'Invalid EWT. Please check maintenance of EWT');
END;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_ACC_SYSPARAM_CHARVAL" (
  P_OPTION IN VARCHAR )
RETURN VARCHAR IS
  --
  --
  V_CHAR_VALUE VARCHAR2(80);
BEGIN
     SELECT option_char
     INTO
        v_char_value
     FROM
        acc_system_parameters
     WHERE
        option_code = p_option;
     RETURN v_char_value;
EXCEPTION
     WHEN NO_DATA_FOUND THEN return '';
        --raise_application_error(-20001, 'ERROR - No value retrieved.');
END SF_GET_ACC_SYSPARAM_CHARVAL;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_APP_DIR" return varchar2 as
begin
   return 'C:\DevSuiteHome\forms\tpj\';
end sf_get_app_dir;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_BEGBAL_DT" (
   p_ofc in varchar2,
   p_tran in varchar2,
   p_item in varchar2,
   p_uome in varchar2,
   p_date in date) return date as
   dDtCreated Date;
begin
   if p_ofc = 'HO' then
      select min(dt_created) into dDtCreated
      from   inv_stocks
      where  item_code = p_item
      and    uome_code = p_uome
      and    tran_type = p_tran;
   else
      select min(dt_created) into dDtCreated
      from   inv_stocks_gensan
      where  item_code = p_item
      and    uome_code = p_uome
      and    tran_type = p_tran;
   end if;
   return dDtCreated;
end sf_get_begbal_dt;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_CASHBONUS_RATE"
(
   p_rank  in varchar2,
   p_catch in number,
   p_extra out number
)  return number is

   nRate   pys_incentives.rate%type;
   nExtra  pys_incentives.rate%type;

begin

   select rate, rate_2
   into   nRate, nExtra
   from   pys_incentives
   where  inty_code = 'CASH BONUS'
   and    rank_code = p_rank
   and    p_catch between range_fr and range_to
   and    rownum = 1;

   p_extra := nvl(nExtra,0);
   return nRate;

exception
   when no_data_found then
      p_extra := nvl(nExtra,0);
      return 0;

end sf_get_cashbonus_rate;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_CATCHER_RATE"
(
   p_fiso  in varchar2,
   p_rank  in varchar2,
   p_catch in number
)  return number is

   nRate   pys_incentives.rate%type;

begin

   select rate
   into   nRate
   from   pys_incentives
   where  inty_code = 'CATCHER'
   and    fiso_code = p_fiso
   and    rank_code = p_rank
   and    p_catch between range_fr and range_to
   and    rownum = 1;

   return nRate;

exception
   when no_data_found then
      return 0;

end sf_get_catcher_rate;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_DELIVERY_RATE"
(
   p_rank  in varchar2,
   p_catch in number
)  return number is

   nRate   pys_incentives.rate%type;

begin

   select rate
   into   nRate
   from   pys_incentives
   where  inty_code = 'DELIVERIES'
   and    rank_code = p_rank
   and    p_catch between range_fr and range_to
   and    rownum = 1;

   return nRate;

exception
   when no_data_found then
      return 0;

end sf_get_delivery_rate;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_EMPL" (pusername VARCHAR2)
RETURN VARCHAR2
AS
  vname VARCHAR2(16);
BEGIN
  SELECT empl_id
  INTO   vname
  FROM   PMS_EMPLOYEES
  WHERE  pusername = user_code;
  RETURN vname;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN  pusername;
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_EMPL_CODE" (p_empl_nm VARCHAR2) RETURN VARCHAR2 AS
  vCode VARCHAR2(32);
BEGIN
  SELECT empl_id
  INTO   vCode
  FROM   PMS_EMPLOYEES
  WHERE  last_name || ', ' || first_name || ' ' || middle_name = replace(p_empl_nm, '"', '')
  and rownum  =1;
  RETURN vCode;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN sf_get_empl(user);
END SF_GET_EMPL_CODE;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_EMPL_NAME" (p_empl_id VARCHAR2)
RETURN VARCHAR2
AS
  vname VARCHAR2(512);
BEGIN
  SELECT last_name||', '||first_name||' '||middle_name
  INTO   vname
  FROM   PMS_EMPLOYEES
  WHERE  empl_id = p_empl_id;
  RETURN vname;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN p_empl_id;
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_EMPL_NAME_FIRST" (p_empl_id VARCHAR2)
RETURN VARCHAR2
AS
  vname VARCHAR2(512);
BEGIN
  SELECT first_name||' '||last_name
  INTO   vname
  FROM   PMS_EMPLOYEES
  WHERE  empl_id = p_empl_id;
  RETURN vname;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
     RETURN p_empl_id;
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_EMPL_OFC" (p_username VARCHAR2)
RETURN VARCHAR2 AS
   vOfc pms_employees.ofc_code%type;
   vEID pms_employees.empl_id%type;
   vAOF number;
BEGIN
   BEGIN
     SELECT ofc_code, empl_id
     INTO   vOfc, vEID
     FROM   PMS_EMPLOYEES
     WHERE  user_code = p_username;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN null;
   END;

   IF vOfc is null THEN
      BEGIN
        -- check if approving officer
        SELECT 1
        INTO   vAOF
        FROM   inv_approving_officer
        WHERE  code = vEID;
        vOfc := 'ALL';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN null;
      END;
   END IF;
   RETURN vOfc;

END sf_get_empl_ofc;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_FIX_TAX"
   ( p_effdate in  date,
     p_salary  in  number
   )
   return number is
   nFix   Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
   dEffDate Date;
begin
   if p_salary is null then
      nBTax := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_rates
      where  p_salary between salary_fr and salary_to
      and    eff_date <= p_effdate;

      select fix_tax, base_tax, over_pct
      into   nFix, nBTax, nRate
      from   pys_tax_rates
      where  eff_date = dEffDate
      and    p_salary between salary_fr and salary_to;
   end if;
   return nFix;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_fix_tax;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_FX_RATE" (p_curr_code varchar2, p_fx_date date) return number is
begin

  if p_curr_code = 'PHP' then
     return 1;
  end if;

  for a in
    (
    select fx_value
    from   acc_forex
    where  fx_date = p_fx_date
    and    curr_code = p_curr_code
    )
  loop
    return a.fx_value;
  end loop;

  return 0;
end sf_get_fx_rate;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_INV_ADV_PAYMENT" (p_inv_type varchar, p_po_no varchar2) return number as
  v_adv acc_ap_inv_dtl.cpa_amt%type;
  v_used_adv acc_ap_inv_dtl.cpa_amt%type;
begin
  v_adv := 0;
  v_used_adv := 0;
  if p_inv_type = 'PO' then
      SELECT SUM(nvl(DEBIT,0))
      INTO   v_adv
      FROM (SELECT nvl(sum(jvdt.debit),0) as "DEBIT"
            FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
            WHERE  JVHD.JV_NO = JVDT.JV_NO
            AND    JVHD.JV_STATUS = 'APPROVED'
            AND    JVDT.REF_TYPE = 'PO'
            AND    JVDT.REF_CODE = P_PO_NO
            AND    JVDT.ACCO_CODE = '40004'
            UNION ALL
            SELECT nvl(SUM(nvl(AMOUNT,0)),0) DEBIT
            FROM   ACC_PCV_INV_DTL PCDT, ACC_PCV_HDR PCHD, ACC_PCV_DTL PCDTT
            WHERE  PCHD.PCV_NO = PCDT.PCV_NO
            AND    PCHD.PCV_NO = PCDTT.PCV_NO
            AND    PCHD.PCV_STATUS = 'REPLENISHED'
            AND    PCDT.PO_NO = 'PO'||P_PO_NO
            AND    PCDTT.ACCO_CODE = '40004'
            UNION ALL
            SELECT nvl(SUM(nvl(CPDT.AMOUNT,0)),0)
            FROM   ACC_CV_CPA_DTL JVDT, ACC_CV_HDR JVHD, ACC_CPA_DTL CPDT
            WHERE  JVHD.CV_NO = JVDT.CV_NO
            AND    JVHD.CV_STATUS = 'APPROVED'
            AND    CPDT.REF_TYPE = 'PO'
            AND    CPDT.CPA_NO = JVDT.CPA_NO
            AND    CPDT.REF_CODE = P_PO_NO
            AND    CPDT.ACCO_CODE = '40004' );
      v_adv := nvl(v_adv,0);
      if v_adv > 0 then
         select nvl(sum(nvl(cpa_amt,0)),0)
         into  v_used_adv
         from  ACC_AP_INV_DTL apin, acc_ap_hdr aphd
         where aphd.ap_no = apin.ap_no
         and   apin.po_no = p_po_no
         and   apin.is_selected = 'Y'
         and   (apin.rs_no like 'M%' or apin.rs_no like 'O%')
         and   aphd.ap_status not in ('DISAPPROVED','CANCELLED');
         v_used_adv := nvl(v_used_adv,0);
      end if;
  end if;
  if p_inv_type = 'JO' then
      SELECT SUM(nvl(DEBIT,0))
      INTO   v_adv
      FROM (
            SELECT nvl(SUM(nvl(AMOUNT,0)),0) DEBIT
            FROM   ACC_PCV_INV_DTL PCDT, ACC_PCV_HDR PCHD, ACC_PCV_DTL PCDTT
            WHERE  PCHD.PCV_NO = PCDT.PCV_NO
            AND    PCHD.PCV_NO = PCDTT.PCV_NO
            AND    PCHD.PCV_STATUS = 'REPLENISHED'
            AND    PCDT.PO_NO = 'JO'||P_PO_NO
            AND    PCDTT.ACCO_CODE = '40004'
            UNION ALL
            SELECT nvl(SUM(nvl(CPDT.AMOUNT,0)),0) DEBIT
            FROM   ACC_CV_CPA_DTL JVDT, ACC_CV_HDR JVHD, ACC_CPA_DTL CPDT
            WHERE  JVHD.CV_NO = JVDT.CV_NO
            AND    JVHD.CV_STATUS = 'APPROVED'
            AND    CPDT.REF_TYPE = 'JO'
            AND    CPDT.CPA_NO = JVDT.CPA_NO
            AND    CPDT.REF_CODE = P_PO_NO
            AND    CPDT.ACCO_CODE = '40004'
            UNION
            SELECT sum(jvdt.debit) as "DEBIT"
            FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
            WHERE  JVHD.JV_NO = JVDT.JV_NO
            AND    JVHD.JV_STATUS = 'APPROVED'
            AND    JVDT.REF_TYPE = 'JO'
            AND    JVDT.REF_CODE = P_PO_NO
            GROUP  BY JVHD.JV_NO
            );
      v_adv := nvl(v_adv,0);
      if v_adv > 0 then
         select nvl(sum(nvl(cpa_amt,0)),0)
         into  v_used_adv
         from  ACC_AP_INV_DTL apin, acc_ap_hdr aphd
         where aphd.ap_no = apin.ap_no
         and   apin.po_no = p_po_no
         and   apin.is_selected = 'Y'
         and   (apin.rs_no not like 'M%' and apin.rs_no not like 'O%')
         and   aphd.ap_status not in ('DISAPPROVED','CANCELLED');
         v_used_adv := nvl(v_used_adv,0);
      end if;
  end if;
  dbms_output.put_line(v_adv ||' - '|| v_used_adv);
  RETURN (v_adv - v_used_adv);
end;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_INV_ADV_PAYMENT_PHP" (p_inv_type varchar, p_po_no varchar2) return number as
  v_adv acc_ap_inv_dtl.cpa_amt%type;
  v_used_adv acc_ap_inv_dtl.cpa_amt%type;
begin
  v_adv := 0;
  v_used_adv := 0;
  if p_inv_type = 'PO' then
      SELECT SUM(nvl(DEBIT,0))
      INTO   v_adv
      FROM (SELECT nvl(sum(jvdt.debit_php),0) as "DEBIT"
            FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
            WHERE  JVHD.JV_NO = JVDT.JV_NO
            AND    JVHD.JV_STATUS = 'APPROVED'
            AND    JVDT.REF_TYPE = 'PO'
            AND    JVDT.REF_CODE = P_PO_NO
            AND    JVDT.ACCO_CODE = '40004'
            UNION ALL
            SELECT nvl(SUM(nvl(AMOUNT,0)),0) DEBIT
            FROM   ACC_PCV_INV_DTL PCDT, ACC_PCV_HDR PCHD, ACC_PCV_DTL PCDTT
            WHERE  PCHD.PCV_NO = PCDT.PCV_NO
            AND    PCHD.PCV_NO = PCDTT.PCV_NO
            AND    PCHD.PCV_STATUS = 'REPLENISHED'
            AND    PCDT.PO_NO = 'PO'||P_PO_NO
            AND    PCDTT.ACCO_CODE = '40004'
            UNION ALL
            SELECT nvl(SUM(nvl(CPDT.AMOUNT,0)),0)
            FROM   ACC_CV_CPA_DTL JVDT, ACC_CV_HDR JVHD, ACC_CPA_DTL CPDT
            WHERE  JVHD.CV_NO = JVDT.CV_NO
            AND    JVHD.CV_STATUS = 'APPROVED'
            AND    CPDT.REF_TYPE = 'PO'
            AND    CPDT.CPA_NO = JVDT.CPA_NO
            AND    CPDT.REF_CODE = P_PO_NO
            AND    CPDT.ACCO_CODE = '40004');
      v_adv := nvl(v_adv,0);
      if v_adv > 0 then
         select nvl(sum(nvl(cpa_amt_php,0)),0)
         into  v_used_adv
         from  ACC_AP_INV_DTL apin, acc_ap_hdr aphd
         where aphd.ap_no = apin.ap_no
         and   apin.po_no = p_po_no
         and   apin.is_selected = 'Y'
         and   (apin.rs_no like 'M%' or apin.rs_no like 'O%')
         and   aphd.ap_status not in ('DISAPPROVED','CANCELLED');
         v_used_adv := nvl(v_used_adv,0);
      end if;
  end if;
  if p_inv_type = 'JO' then
      SELECT SUM(nvl(DEBIT,0))
      INTO   v_adv
      FROM (
            SELECT nvl(SUM(nvl(AMOUNT,0)),0) DEBIT
            FROM   ACC_PCV_INV_DTL PCDT, ACC_PCV_HDR PCHD, ACC_PCV_DTL PCDTT
            WHERE  PCHD.PCV_NO = PCDT.PCV_NO
            AND    PCHD.PCV_NO = PCDTT.PCV_NO
            AND    PCHD.PCV_STATUS = 'REPLENISHED'
            AND    PCDT.PO_NO = 'JO'||P_PO_NO
            AND    PCDTT.ACCO_CODE = '40004'
            UNION ALL
            SELECT nvl(SUM(nvl(CPDT.AMOUNT,0)),0) DEBIT
            FROM   ACC_CV_CPA_DTL JVDT, ACC_CV_HDR JVHD, ACC_CPA_DTL CPDT
            WHERE  JVHD.CV_NO = JVDT.CV_NO
            AND    JVHD.CV_STATUS <> 'APPROVED'
            AND    CPDT.REF_TYPE = 'JO'
            AND    CPDT.CPA_NO = JVDT.CPA_NO
            AND    CPDT.REF_CODE = P_PO_NO
            AND    CPDT.ACCO_CODE = '40004'
            UNION
            SELECT sum(jvdt.debit_php) as "DEBIT"
            FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
            WHERE  JVHD.JV_NO = JVDT.JV_NO
            AND    JVHD.JV_STATUS = 'APPROVED'
            AND    JVDT.REF_TYPE = 'JO'
            AND    JVDT.REF_CODE = P_PO_NO
            GROUP  BY JVHD.JV_NO);
      v_adv := nvl(v_adv,0);
      if v_adv > 0 then
         select nvl(sum(nvl(cpa_amt_php,0)),0)
         into  v_used_adv
         from  ACC_AP_INV_DTL apin, acc_ap_hdr aphd
         where aphd.ap_no = apin.ap_no
         and   apin.po_no = p_po_no
         and   apin.is_selected = 'Y'
         and   (apin.rs_no not like 'M%' and apin.rs_no not like 'O%')
         and   aphd.ap_status not in ('DISAPPROVED','CANCELLED');
         v_used_adv := nvl(v_used_adv,0);
      end if;
  end if;
  dbms_output.put_line(v_adv ||' - '|| v_used_adv);
  RETURN (v_adv - v_used_adv);
end sf_get_inv_adv_payment_php;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_ITEM_AVAIL_QTY" (
   p_item in varchar2,
   p_cate in varchar2,
   p_itty in varchar2,
   p_itgr in varchar2,
   p_uome in varchar2,
   p_rsno in varchar2,
   p_ware in varchar2 ) return number is
   nItemQty  number;
   nStockQty number;
   nApprQty  number;
begin
   begin
      if p_ware is null then
         select nvl(sum(qty_avail),0)
         into   nItemQty
         from   inv_item_ware iw
         where  iw.item_code = p_item
         and    iw.cate_code = p_cate
         and    iw.itty_code = p_itty
         and    iw.itgr_code = p_itgr
         and    iw.uome_code = p_uome;
      else
         select nvl(sum(qty_avail),0)
         into   nItemQty
         from   inv_item_ware iw
         where  iw.item_code = p_item
         and    iw.cate_code = p_cate
         and    iw.itty_code = p_itty
         and    iw.itgr_code = p_itgr
         and    iw.uome_code = p_uome
         and    iw.ware_code = p_ware;
      end if;
   exception
      when no_data_found then nItemQty := 0;
   end;

   begin
      if p_ware is null then
         select nvl(sum(rsdt.approved_qty),0)
         into   nApprQty
         from   inv_reqslip_hdr rshd, inv_reqslip_dtl rsdt
         where  rsdt.item_code = p_item
         and    rsdt.cate_code = p_cate
         and    rsdt.itty_code = p_itty
         and    rsdt.itgr_code = p_itgr
         and    rsdt.uome_code = p_uome
         and    rshd.with_stock = 'Y'
         and    rsdt.rshd_rs_no = rshd.rs_no
         and    rshd.rs_no <> nvl(p_rsno,'000000')
         and    rshd.status not in ('DISAPPROVED','CANCELLED')
         and    rshd.rs_iss_status <> 'FULLY ISSUED'
         and    rsdt.ware_code is null;
      else
         select nvl(sum(rsdt.approved_qty),0)
         into   nApprQty
         from   inv_reqslip_hdr rshd, inv_reqslip_dtl rsdt
         where  rsdt.item_code = p_item
         and    rsdt.cate_code = p_cate
         and    rsdt.itty_code = p_itty
         and    rsdt.itgr_code = p_itgr
         and    rsdt.uome_code = p_uome
         and    rshd.with_stock = 'Y'
         and    rsdt.rshd_rs_no = rshd.rs_no
         and    rshd.rs_no <> nvl(p_rsno,'000000')
         and    rshd.status not in ('DISAPPROVED','CANCELLED')
         and    rshd.rs_iss_status <> 'FULLY ISSUED'
         and    rsdt.ware_code = p_ware;
      end if;
   exception
      when no_data_found then nApprQty := 0;
   end;

   nStockQty := greatest(nItemQty - nApprQty,0);

   return nStockQty;

end sf_get_item_avail_qty;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_ITEM_JO_DESC" (p_item_code VARCHAR2, p_cate_code VARCHAR2, p_itty_code VARCHAR2, p_itgr_code VARCHAR2)
RETURN VARCHAR2
AS
  vname VARCHAR2(512);
BEGIN
SELECT DECODE(ITEM.MATE_CODE, NULL, '', ' ' || MATE.DESCRIPTION) ||
       DECODE(ITEM.ISZE_CODE, NULL, '', ' ' || ISZE.DESCRIPTION) ||
       DECODE(ITEM.VOLT_CODE, NULL, '', ' ' || VOLT.DESCRIPTION) ||
       DECODE(ITEM.BRAN_CODE, NULL, '', ' ' || BRAN.DESCRIPTION) ||
       DECODE(ITEM.MODL_CODE, NULL, '', ' ' || MODL.DESCRIPTION) ||
       DECODE(ITEM.ACCE_CODE, NULL, '', ' ' || ACCE.DESCRIPTION) ||
       DECODE(ITEM.COLO_CODE, NULL, '', ' ' || COLO.DESCRIPTION) ||
       DECODE(ITEM.SHAP_CODE, NULL, '', ' ' || SHAP.DESCRIPTION) ||
       DECODE(ITEM.SOUR_CODE, NULL, '', ' ' || SOUR.DESCRIPTION) ||
       DECODE(ITEM.TYPE_CODE, NULL, '', ' ' || TYPE.NAME) ||
       DECODE(ITEM.SERIAL_NO, NULL, '', ' ' || ITEM.SERIAL_NO) ||
       DECODE(ITEM.PART_NO, NULL, '', ' ' || ITEM.PART_NO) ITEM_NAME
INTO vname
FROM INV_ITEMS ITEM,
     INV_ACCESSORY ACCE,
     INV_BRAND BRAN,
     INV_COLOR COLO,
     INV_MATERIAL MATE,
     INV_MODEL MODL,
     INV_SHAPE SHAP,
     INV_SIZE ISZE,
     INV_VOLTAGE VOLT,
         INV_SOURCE SOUR,
         INV_TYPES TYPE,
         INV_ITEM_TYPES ITTY
WHERE P_ITTY_CODE = ITEM.ITTY_CODE
AND   P_ITGR_CODE = ITEM.ITGR_CODE
AND   P_CATE_CODE = ITEM.CATE_CODE
AND   P_ITEM_CODE = ITEM.CODE
AND   ITTY.CODE = ITEM.ITTY_CODE
AND   ITEM.ACCE_CODE = ACCE.CODE(+)
AND   ITEM.BRAN_CODE = BRAN.CODE(+)
AND   ITEM.COLO_CODE = COLO.CODE(+)
AND   ITEM.MATE_CODE = MATE.CODE(+)
AND   ITEM.MODL_CODE = MODL.CODE(+)
AND   ITEM.SHAP_CODE = SHAP.CODE(+)
AND   ITEM.ISZE_CODE = ISZE.CODE(+)
AND   ITEM.VOLT_CODE = VOLT.CODE(+)
AND   ITEM.SOUR_CODE = SOUR.CODE(+)
AND   ITEM.TYPE_CODE = TYPE.CODE(+);
RETURN vname;
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_ITEM_PRICE"
   (p_item_code VARCHAR2,
    p_cate_code VARCHAR2,
        p_itty_code VARCHAR2,
        p_itgr_code VARCHAR2,
        p_uome_code VARCHAR2) RETURN NUMBER
AS
   v_number NUMBER(12,4);
   v_status VARCHAR2(20);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN
    DBMS_OUTPUT.PUT_LINE('p_item_code '|| p_item_code);
    DBMS_OUTPUT.PUT_LINE('p_cate_code '|| p_cate_code);
        DBMS_OUTPUT.PUT_LINE('p_itty_code '|| p_itty_code);
        DBMS_OUTPUT.PUT_LINE('p_itgr_code '|| p_itgr_code);
        DBMS_OUTPUT.PUT_LINE('p_uome_code '|| p_uome_code);

   SELECT MIN(NVL(unit_cost,0)*((100-NVL(discount,0))/100))
   INTO   v_number
   FROM   INV_SUPP_QUOTE suqo
   WHERE  item_code = p_item_code
   AND    item_cate_code = p_cate_code
   AND    item_itty_code = p_itty_code
   AND    item_itgr_code = p_itgr_code
   AND    uome_code = p_uome_code;

   RETURN NVL(v_number,0);
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NVL(v_number,0);
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_JO_DR_STATUS"
   (p_johd_jo_no VARCHAR2) RETURN VARCHAR2
AS
   v_status VARCHAR2(20);
   v_number NUMBER(5,4);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN
   SELECT SUM(jodt.dr_qty)/SUM(jodt.qty)
   INTO   v_number
   FROM   INV_JO_DTL jodt
   WHERE  jodt.johd_jo_no = p_johd_jo_no;

   IF v_number = 0 THEN
      RETURN 'FOR DELIVERY';
   ELSIF v_number > 0 AND v_number < 1 THEN
      RETURN 'PARTIALLY DELIVERED';
   ELSIF v_number = 1 THEN
      RETURN 'FULLY DELIVERED';
   END IF;
   RETURN NULL;
EXCEPTION
   WHEN v_zero_divisor THEN
      RETURN 'WAITING FOR JO';
END Sf_Get_Jo_Dr_Status;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_JS_STATUS"
   (p_js_no VARCHAR2) RETURN VARCHAR2
AS
   vjc VARCHAR2(16);
   vjo VARCHAR2(16);
   vjd VARCHAR2(16);
   vji VARCHAR2(16);
   vst VARCHAR2(16);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN

   SELECT JOCSHD_JOCS_NO, JOHD_JO_NO, JODRHD_JO_DR_NO, JOISHD_JOISS_NO, status
   INTO   vjc, vjo, vjd, vji, vst
   FROM   INV_JS_HDR
   WHERE  js_no = p_js_no;

   IF vjc IS NOT NULL THEN
      IF vjo IS NOT NULL THEN
         IF vjd IS NOT NULL THEN
            IF vji IS NOT NULL THEN
               RETURN 'WITH ISSUANCE';
            ELSE
               RETURN 'WITH DELIVERY';
            END IF;
         ELSE
            RETURN 'WITH PO';
         END IF;
      ELSE
         RETURN 'WITH CANVASS';
      END IF;
   ELSE
      IF vst = 'APPROVED' THEN
             RETURN 'WITH JS';
          ELSE
         RETURN 'FOR JS';
          END IF;
   END IF;
   RETURN NULL;
EXCEPTION
   WHEN v_zero_divisor THEN
      RETURN 'WAITING FOR RS';
   WHEN NO_DATA_FOUND THEN
      RETURN 'WITH REQUEST';
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LATEST_BASIC_RATE_O" (
   p_empl_id in varchar2,
   p_date_fr in date
  )  return number is

   nBasicR    Number(8,2);
   nBasicG    Number(8,2);
   vSalFreq   Varchar2(16);
   vIsManager Varchar2(1);
begin

   for i in (select eff_st_date, basic_rate, basic_rate_g, sal_freq, is_manager
             from   pys_employee_salary
             where  empl_empl_id = p_empl_id
             and    eff_st_date <= p_date_fr
             order  by eff_st_date desc
             )
   loop
      nBasicR    := i.basic_rate;
      nBasicG    := i.basic_rate_g;
      vSalFreq   := i.sal_freq;
      vIsManager := i.is_manager;
      exit;
   end loop;

   return nvl(nBasicR,0);
end sf_get_latest_basic_rate_o;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LATEST_COLA" (
   p_empl_id in  varchar2,
   p_date_fr in  date
  ) return number as
  nAmt  Number(12,2);
  dDate Date;
begin
   -- get latest record
   select sum(amt)
   into   nAmt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date)
                      from pys_employee_salary
                      where empl_empl_id = p_empl_id
                      and eff_st_date <= p_date_fr);

   return nvl(nAmt,0);
exception
   when no_data_found then
      return 0;
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_colafor employee ' || p_empl_id || ' ' || SQLERRM);
end SF_GET_LATEST_COLA;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LATEST_COLA_DESC" (
   p_empl_id in  varchar2,
   p_days in  number,
   p_cola in  number,
   p_date_fr in  date,
   p_date_to in  date
  ) return varchar2 as
  dEffDate Date;
  nDesc    Varchar2(1000);
  nCola    Number;
  nCtr     Number;
  nRCtr    Number;
  nAmt     Number;
begin
   -- get latest record
   select max(eff_st_date)
   into   dEffDate
   from pys_employee_salary
   where empl_empl_id = p_empl_id
   and eff_st_date <= p_date_to;

   select sum(amt), count(1)
   into   nCola, nCtr
   from pys_employee_allowances
   where empl_empl_id = p_empl_id
   and eff_st_date=dEffDate;

      nRCtr := 0;
      nAmt  := 0;
      for i in (select substr(allo_code,1,1) allo_code, amt from pys_employee_allowances where empl_empl_id = p_empl_id and eff_st_date=dEffDate) loop
         nRCtr := nRCtr + 1;
         if nRCtr = nCtr then
            nDesc := nDesc || chr(10) || i.allo_code || ': ' || to_char(p_cola-nAmt);
         else
            if nDesc is null then
               nDesc := i.allo_code || ': ' || to_char(round((i.amt/nCola)*p_cola,2));
            else
               nDesc := nDesc || chr(10) || i.allo_code || ': ' || to_char(round((i.amt/nCola)*p_cola,2));
            end if;
         end if;
         if nCola > 1 then
            nAmt := nAmt + round((i.amt/nCola)*p_cola,2);
         end if;
      end loop;
      return nvl(nDesc, ' ');
exception
   when no_data_found then
      return ' ';
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_cola_desc for employee ' || p_empl_id || ' ' || SQLERRM);
end SF_GET_LATEST_COLA_DESC;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LATEST_EMBARK" (
   p_empl_id in varchar2,
   p_date_fr in date
  ) return date is
  dLatestEmbark Date;
begin
   -- get latest record
   select max(vocr.dt_embarked)
   into   dLatestEmbark
   from   cms_voyages voya, cms_voyage_crew vocr
   where  voya.vess_code = vocr.voya_vess_code
   AND    voya.voyage_date = vocr.voya_voyage_date
   AND    voya.voyage_status <> 'CN'
   AND    vocr.empl_empl_id = p_empl_id
   and    vocr.voya_voyage_date < p_date_fr+1
   and    vocr.dt_embarked < p_date_fr+1;

   return dLatestEmbark;
exception
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_embark for employee ' || p_empl_id || ' ' || SQLERRM);
end SF_GET_LATEST_EMBARK;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LATEST_MACREW_BASIC" (
   p_empl_id   in varchar2,
   p_period_to in date
   ) return number
as
   dStart Date;
   dEnd   Date;
   nRate Number(12,4);
begin
   dStart := to_date(to_char(p_period_to, 'YYYYMM"01"'), 'YYYYMMDD');
   dEnd   := last_day(dStart);
   for i in (select period_to, basic_rate from pys_payroll_dtl
             where  empl_empl_id = p_empl_id
             and    period_to between dStart and dEnd
             and    paty_code like 'REG%'
             order  by period_to desc )
   loop
      nRate := i.basic_rate;
      exit;
   end loop;
   if nRate=0 then
      for i in (select period_to, basic_rate from pys_payroll_dtl
                where  empl_empl_id = p_empl_id
             and    period_to between dStart and dEnd
                order  by period_to desc )
      loop
         nRate := i.basic_rate;
         exit;
      end loop;
   end if;
   return nvl(nRate,0);
end sf_get_latest_macrew_basic;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LIGHTED_RATE"
(
   p_fiso  in varchar2,
   p_rank  in varchar2,
   p_catch in number
)  return number is

   nRate   pys_incentives.rate%type;

begin
   select rate
   into   nRate
   from   pys_incentives
   where  inty_code = 'LIGHTBOAT'
   and    fiso_code = p_fiso
   and    p_catch between range_fr and range_to
   and    rownum = 1;
   return nRate;
exception
   when no_data_found then
      return 0;
end sf_get_lighted_rate;


 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_LOC_ITEM_WARE"
   (p_item_code VARCHAR2,
    p_cate_code VARCHAR2,
 p_itty_code VARCHAR2,
 p_itgr_code VARCHAR2,
 p_uome_code VARCHAR2,
 p_ware_code VARCHAR2,
 p_rshd_rs_no VARCHAR2) RETURN VARCHAR2
AS
   v_number NUMBER(12,4);
   v_wareinfo VARCHAR2(512);
   v_aqty NUMBER(12,4);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN

   FOR a IN (
     SELECT SUM(qty_avail) remain, ware_code, wname
  FROM   INV_ITEM_WARE iw, INV_WAREHOUSE ware
     WHERE  iw.item_code = p_item_code
     AND    iw.cate_code = p_cate_code
  AND    iw.itty_code = p_itty_code
     AND    iw.itgr_code = p_itgr_code
  AND    iw.uome_code = p_uome_code
  AND    iw.ware_code = ware.code
  GROUP BY ware_code,wname)
   LOOP
     v_aqty := 0;
  IF p_ware_code IS NULL THEN
      /*
   SELECT SUM(NVL(rsdt.approved_qty,0)-NVL(rsdt.iss_qty,0))
   INTO   v_aqty
   FROM   inv_reqslip_hdr rshd, inv_reqslip_dtl rsdt
   WHERE  rshd.rs_no = rsdt.rshd_rs_no
   AND    rshd.with_stock = 'Y'
   AND    rsdt.item_code = p_item_code
   AND    rsdt.cate_code = p_cate_code
   AND    rsdt.itty_code = p_itty_code
   AND    rsdt.itgr_code = p_itgr_code
   AND    rsdt.uome_code = p_uome_code
   AND    rshd.status NOT IN ('DISAPPROVED','CANCELLED');
   */
   NULL;
  ELSE
   SELECT SUM(NVL(rsdt.approved_qty,0)-NVL(rsdt.iss_qty,0))
   INTO   v_aqty
   FROM   inv_reqslip_hdr rshd, inv_reqslip_dtl rsdt
   WHERE  rshd.rs_no = rsdt.rshd_rs_no
   AND    rshd.with_stock = 'Y'
   AND    rsdt.item_code = p_item_code
   AND    rsdt.cate_code = p_cate_code
   AND    rsdt.itty_code = p_itty_code
   AND    rsdt.itgr_code = p_itgr_code
   AND    rsdt.uome_code = p_uome_code
   AND    rsdt.ware_code = p_ware_code
   AND    rsdt.ware_code = a.ware_code
   AND    rshd.rs_no <> NVL(p_rshd_rs_no,'M000000')
   AND    rshd.status NOT IN ('DISAPPROVED','CANCELLED');
  END IF;

     IF v_wareinfo IS NULL THEN
        v_wareinfo := a.wname||'('||(NVL(a.remain,0)-NVL(v_aqty,0))||')';
  ELSE
     v_wareinfo := v_wareinfo||', '||a.wname||'('||(NVL(a.remain,0)-NVL(v_aqty,0))||')';
  END IF;
   END LOOP;

   RETURN v_wareinfo;
EXCEPTION
   WHEN NO_DATA_FOUND THEN
      RETURN NVL(v_number,0);
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_NEXT_ISS_TYPE_NO" (p_iss_type in varchar2) return varchar2 is
   nMax Number;
   vPrefix Varchar2(6);
begin
   begin
      select max(substr(iss_type_no, 1, 2)) vPrefix, max(to_number(substr(iss_type_no,3))) nMax
      into   vPrefix, nMax
      from   inv_iss_hdr
      where  iss_type = p_iss_type;
   exception
      when no_data_found then null;
   end;

   if vPrefix is null then
      nMax := 0;
      if p_iss_type = 'OUTER_PORT' then
         vPrefix := 'OP';
      elsif p_iss_type = 'MEMORANDUM' then
         vPrefix := 'MR';
      elsif p_iss_type = 'MAINTENANCE' then
         vPrefix := 'MT';
      elsif p_iss_type = 'CHARGE_IS' then
         vPrefix := 'CH';
      elsif p_iss_type = 'CUSTODIAN' then
         vPrefix := 'CU';
      end if;
   end if;
   nMax := nMax + 1;
   return vPrefix || lpad(to_char(nMax), 6, '0');
end sf_get_next_iss_type_no;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_NEXT_ONBOARD" (
  p_payroll_no VARCHAR2,
  p_empl_id VARCHAR2,
  p_on_board DATE
  ) return date is
BEGIN
  for a in (
    select (on_board-1) next_board
    from  (select  pcl.on_board
           from    pms_crew_list pcl
           where   pcl.payroll_no = p_payroll_no
           and     pcl.empl_id    = p_empl_id
           and     trunc(pcl.on_board) > trunc(p_on_board)
           order   by pcl.on_board desc)
    where   rownum = 1)
  loop
    return a.next_board;
  end loop;
  return to_date('20990101','YYYYMMDD');
END sf_get_next_onboard;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_OT_RATES" (
   p_code in varchar2
 ) return number as
   nRate Number(12,4);
begin
   select rate
   into   nRate
   from   pys_payroll_types
   where  code=p_code;
   return nRate;
exception
   when no_data_found then
      return 0;
end sf_get_ot_rates;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_PAGIBIG_CONTRIBUTION"
   ( p_salary in number
   )
   return number is
   nAmt Number;
begin
   if p_salary >= 5000 then
      nAmt := 100;
   elsif p_salary > 2500 and p_salary < 5000 then
      nAmt := p_salary * .01;
   else
      nAmt := 25;
   end if;
   return nAmt;
end sf_get_pagibig_contribution;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_PAYROLL_COLA" (
   p_empl_id in varchar2,
   p_payno_15 in number,
   p_payno_30 in number
   ) return varchar2
as
   nCola Number;
begin
   select nvl(max(cola_pay),0)
   into   nCola
   from   pys_payroll_dtl_log
   where  empl_empl_id = p_empl_id
   and    payroll_no = p_payno_30;

   if nCola = 0 then
      select nvl(max(cola_pay),0)
      into   nCola
      from   pys_payroll_dtl_log
      where  empl_empl_id = p_empl_id
      and    payroll_no = p_payno_15;
   end if;

   return nCola;

end sf_get_payroll_cola;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_PCV_AP_NO" (p_ref_type in varchar2, p_pcv_no in number, p_acco_code in varchar2) return number as
   nAP_NO number;
begin
   select ap_no into nAP_NO
   from   ACC_AP_PCV_JV_ADVANCES
   where  ref_type = p_ref_type
   and    acco_code = p_acco_code
   and    ref_code = to_char(p_pcv_no)
   and    IS_SELECTED = 'Y';
   return nAP_NO;

exception
   when no_data_found then return null;
   when others then raise_application_error (-20001, SQLERRM || ' - ' || p_ref_type || '-' || to_char(p_pcv_no));
end;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_PHILHEALTH_CONTRIBUTION"
   ( p_salary in number,
     p_effdate in date
   )
   return number is
   nAmt Number;
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_philhealth_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching Philhealth effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select ee_share
   into   nAmt
   from   pys_philhealth_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;
   return nAmt;
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Philhealth contribution table. No range for this salary - ' || to_char(p_salary));
   when too_many_rows then
      raise_application_error (-20001, 'Check your Philhealth contribution table. Too many range for this salary - ' || to_char(p_salary));
end sf_get_philhealth_contribution;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_PO_ADV_PAYMENT" (p_po_no varchar2) return number as
  v_adv acc_ap_inv_dtl.cpa_amt%type;
  v_used_adv acc_ap_inv_dtl.cpa_amt%type;
begin
  v_adv := 0;
  v_used_adv := 0;
  SELECT SUM(nvl(DEBIT,0))
  INTO   v_adv
  FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
  WHERE  JVHD.JV_NO = JVDT.JV_NO
  AND    JVHD.JV_STATUS = 'APPROVED'
  AND    JVDT.REF_TYPE = 'PO'
  AND    JVDT.REF_CODE = P_PO_NO;
  if v_adv > 0 then
     select sum(nvl(amount,0))
     into  v_used_adv
     from  ACC_AP_INV_DTL apin, acc_ap_hdr aphd
     where aphd.ap_no = apin.ap_no
     and   apin.po_no = p_po_no
     and   aphd.ap_status not in ('DISAPPROVED','CANCELLED');
  end if;
  RETURN (v_adv - v_used_adv);
end;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_PO_DR_STATUS"
   (p_pohd_po_no VARCHAR2) RETURN VARCHAR2
AS
   v_status VARCHAR2(20);
   v_number NUMBER(5,4);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN
   SELECT SUM(decode(clr_po_item,'Y',podt.approved_qty,podt.dr_qty))/SUM(podt.approved_qty)
   INTO   v_number
   FROM   INV_PO_DTL podt
   WHERE  podt.pohd_po_no = p_pohd_po_no;

   IF v_number = 0 THEN
      RETURN 'FOR DELIVERY';
   ELSIF v_number > 0 AND v_number < 1 THEN
      RETURN 'PARTIALLY DELIVERED';
   ELSIF v_number = 1 THEN
      RETURN 'FULLY DELIVERED';
   END IF;
   RETURN NULL;
EXCEPTION
   WHEN v_zero_divisor THEN
      RETURN 'WAITING FOR PO';
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_REPAIR_COST" (p_jo_no IN VARCHAR2) RETURN NUMBER IS
   v_ldisc NUMBER(10,2);
   v_mdisc NUMBER(10,2);
   v_lcost NUMBER(14,2);
   v_mcost NUMBER(14,2);
   v_tcost NUMBER(14,2);
   v_jodrno VARCHAR2(16);
   v_jdexists char(1);
BEGIN
   v_jdexists := 'N';
   BEGIN
      SELECT labor_discount, matrl_discount, jo_dr_no
      INTO   v_ldisc, v_mdisc, v_jodrno
      FROM   INV_JO_DR_HDR
      WHERE  johd_jo_no = p_jo_no
      AND    status = 'APPROVED';
      v_jdexists := 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_jdexists := 'N';
      WHEN TOO_MANY_ROWS THEN
         v_jdexists := 'Y';
   END;

   if v_jdexists = 'Y' then
       FOR a IN (
          SELECT jodt.cate_code, jodt.unit_price, jodt.qty, johd.labor_discount, johd.matrl_discount
          FROM   INV_JO_DR_DTL jodt, inv_jo_dr_hdr johd
          WHERE  jodt.jdhd_jo_dr_no = johd.jo_dr_no
          and    johd.johd_jo_no = p_jo_no
          AND    johd.status = 'APPROVED')
       LOOP
          v_lcost := 0;
          v_mcost := 0;
          IF a.cate_code = 'LBR' THEN
             v_lcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_ldisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_lcost,0);
          ELSE
             v_mcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_mdisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_mcost,0);
          END IF;
       END LOOP;
   else
       BEGIN
          SELECT labor_discount, matrl_discount
          INTO   v_ldisc, v_mdisc
          FROM   INV_JO_HDR
          WHERE  jo_no = p_jo_no
          AND    status = 'APPROVED';
          v_jdexists := 'Y';
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             v_jdexists := 'N';
          WHEN TOO_MANY_ROWS THEN
             v_jdexists := 'Y';
       END;

       FOR a IN (SELECT cate_code, unit_price, qty FROM INV_JO_DTL WHERE johd_jo_no = p_jo_no)
       LOOP
          v_lcost := 0;
          v_mcost := 0;
          IF a.cate_code = 'LBR' THEN
             v_lcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_ldisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_lcost,0);
          ELSE
             v_mcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_mdisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_mcost,0);
          END IF;
       END LOOP;
   end if;
   RETURN nvl(v_tcost,0);
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_REPAIR_COST_2" (
   p_jo_no IN VARCHAR2,
   p_dr_no IN VARCHAR2
   ) RETURN NUMBER IS
   v_ldisc NUMBER(10,2);
   v_mdisc NUMBER(10,2);
   v_lcost NUMBER(14,2);
   v_mcost NUMBER(14,2);
   v_tcost NUMBER(14,2);
   v_jodrno VARCHAR2(16);
   v_jdexists char(1);
BEGIN
   v_jdexists := 'N';
   BEGIN
      SELECT labor_discount, matrl_discount, jo_dr_no
      INTO   v_ldisc, v_mdisc, v_jodrno
      FROM   INV_JO_DR_HDR
      WHERE  johd_jo_no = p_jo_no
      AND    status = 'APPROVED';
      v_jdexists := 'Y';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         v_jdexists := 'N';
      WHEN TOO_MANY_ROWS THEN
         v_jdexists := 'Y';
   END;

   if v_jdexists = 'Y' then
       FOR a IN (
          SELECT jodt.cate_code, jodt.unit_price, jodt.qty, johd.labor_discount, johd.matrl_discount
          FROM   INV_JO_DR_DTL jodt, inv_jo_dr_hdr johd
          WHERE  jodt.jdhd_jo_dr_no = johd.jo_dr_no
          and    johd.johd_jo_no = p_jo_no
          and    johd.jo_dr_no = p_dr_no
          AND    johd.status = 'APPROVED')
       LOOP
          v_lcost := 0;
          v_mcost := 0;
          IF a.cate_code = 'LBR' THEN
             v_lcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_ldisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_lcost,0);
          ELSE
             v_mcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_mdisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_mcost,0);
          END IF;
       END LOOP;
   else
       BEGIN
          SELECT labor_discount, matrl_discount
          INTO   v_ldisc, v_mdisc
          FROM   INV_JO_HDR
          WHERE  jo_no = p_jo_no
          AND    status = 'APPROVED';
          v_jdexists := 'Y';
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             v_jdexists := 'N';
          WHEN TOO_MANY_ROWS THEN
             v_jdexists := 'Y';
       END;

       FOR a IN (SELECT cate_code, unit_price, qty FROM INV_JO_DTL WHERE johd_jo_no = p_jo_no)
       LOOP
          v_lcost := 0;
          v_mcost := 0;
          IF a.cate_code = 'LBR' THEN
             v_lcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_ldisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_lcost,0);
          ELSE
             v_mcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*((100-NVL(v_mdisc,0))/100);
             v_tcost := NVL(v_tcost,0) + NVL(v_mcost,0);
          END IF;
       END LOOP;
   end if;
   RETURN nvl(v_tcost,0);
END;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_REPORT_SERVER" return varchar2 is
begin
   return 'tpj_repserver';
   -- return 'ReportsServer_Dataserver_FormsReports';
end SF_GET_REPORT_SERVER;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_REPORT_URL" (
   p_rpt in varchar2,
   p_usr in varchar2,
   p_pwd in varchar2,
   p_con in varchar2
   ) return varchar2 is
begin
     return (sf_get_url || '/reports/rwservlet?server=' || sf_get_report_server || '&report=' || sf_get_app_dir || upper(p_rpt) || '.rdf&destype=cache&desformat=HTMLCSS&paramform=YES&userid=' || p_usr || '/' || p_pwd || '@' || p_con);
end sf_get_report_url;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_RETSLIP_AMT" (p_rr_no in varchar2) return number as
  nRetAmt Number (12,2);
begin
  select ret_amt
  into   nRetAmt
  from   acc_inv_retslip
  where  rr_no = p_rr_no;
  return nvl(nRetAmt,0);
exception
  when no_data_found then
     return 0;
end sf_get_retslip_amt;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_RS_CS_STATUS"
   (p_rshd_rs_no VARCHAR2) RETURN VARCHAR2
AS
   v_number NUMBER(3,2);
   v_status VARCHAR2(20);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN

   SELECT COUNT(nvl(rsdt.cshd_cs_no,decode(clr_rs_item,'N',NULL,1)))/COUNT(rshd_rs_no)
   INTO   v_number
   FROM   INV_REQSLIP_DTL rsdt
   WHERE  approved_qty > 0
   AND  rshd_rs_no = p_rshd_rs_no;

   IF v_number = 0 THEN
      RETURN 'FOR CANVASSING';
   ELSIF v_number > 0 AND v_number < 1 THEN
      RETURN 'PARTIALLY CANVASSED';
   ELSIF v_number = 1 THEN
      RETURN 'FULLY CANVASSED';
   END IF;
   RETURN NULL;
EXCEPTION
   WHEN v_zero_divisor THEN
      RETURN 'WAITING FOR RS';
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_RS_DR" (
   p_rs_no varchar2,
   p_item_code varchar2,
   p_cate_code varchar2,
   p_itty_code varchar2,
   p_itgr_code varchar2,
   p_uome_code varchar2
  ) return number as
  nQty Number(12,4);
begin
  select nvl(sum(qty),0)
  into   nQty
  from   inv_dr_dtl d, inv_dr_hdr h
  where  d.drhd_dr_no = h.dr_no
  and    h.status = 'POSTED'
  and    d.item_code = p_item_code
  and    d.cate_code = p_cate_code
  and    d.itty_code = p_itty_code
  and    d.itgr_code = p_itgr_code
  and    d.uome_code = p_uome_code
  and    d.rshd_rs_no = p_rs_no;
  return nQty;
end sf_get_rs_dr;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_RS_ISS" (
   p_rs_no varchar2,
   p_item_code varchar2,
   p_cate_code varchar2,
   p_itty_code varchar2,
   p_itgr_code varchar2,
   p_uome_code varchar2
  ) return number as
  nQty Number(12,4);
begin
  select nvl(sum(iss_qty),0)
  into   nQty
  from   inv_iss_dtl d, inv_iss_hdr h
  where  d.ishd_iss_no = h.iss_no
  and    h.status = 'APPROVED'
  and    d.item_code = p_item_code
  and    d.cate_code = p_cate_code
  and    d.itty_code = p_itty_code
  and    d.itgr_code = p_itgr_code
  and    d.uome_code = p_uome_code
  and    d.rshd_rs_no = p_rs_no;
  return nQty;
end sf_get_rs_iss;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_RS_ISS_STATUS"
   (p_rshd_rs_no VARCHAR2) RETURN VARCHAR2
AS
   v_number NUMBER(12,4);
   v_status VARCHAR2(20);
   v_zero_divisor EXCEPTION;
   PRAGMA EXCEPTION_INIT(v_zero_divisor,-1476);
BEGIN
   SELECT SUM(NVL(rsdt.iss_qty,0))/SUM(NVL(rsdt.approved_qty,0))
   INTO   v_number
   FROM   INV_REQSLIP_DTL rsdt
   WHERE  rshd_rs_no = p_rshd_rs_no;
   IF v_number = 0 THEN
      RETURN 'NO ISSUANCE';
   ELSIF v_number > 0 AND v_number < 1 THEN
      RETURN 'PARTIALLY ISSUED';
   ELSIF v_number >= 1 THEN
      RETURN 'FULLY ISSUED';
   END IF;
   RETURN NULL;
EXCEPTION
   WHEN v_zero_divisor THEN
      RETURN 'WAITING FOR RS';
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_RS_OFC" (p_rs_no VARCHAR2)
RETURN VARCHAR2 AS
   vOfc inv_reqslip_hdr.ofc_code%type;
BEGIN
   BEGIN
     SELECT ofc_code
     INTO   vOfc
     FROM   inv_reqslip_hdr
     WHERE  rs_no = p_rs_no;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN null;
   END;

   IF vOfc is null THEN
      vOfc := 'HO';
   END IF;
   RETURN vOfc;

END sf_get_rs_ofc;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_SCRATCHPAD_DIR" return varchar2 as
begin
   return 'C:\DevSuiteHome\forms\scratchpad\';
end sf_get_scratchpad_dir;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_SCRATCHPAD_URL" return varchar2 as
begin
   return '/forms/scratchpad/';
end sf_get_scratchpad_url;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_SSS_CONTRIBUTION"
   ( p_salary in number,
     p_effdate in date
   )
   return number is
   nAmt Number;
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_sss_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching SSS effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select sss_ee
   into   nAmt
   from   pys_sss_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;
   return nAmt;
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your SSS contribution table. No range for this salary - ' || to_char(p_salary));
   when too_many_rows then
      raise_application_error (-20001, 'Check your SSS contribution table. Too many range for this salary - ' || to_char(p_salary));
end sf_get_sss_contribution;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_SURVEYED_RATE"
(
   --p_fiso  in varchar2,
   --p_rank  in varchar2,
   p_catch in number
)  return number is
   nRate   pys_incentives.rate%type;
begin
   select rate
   into   nRate
   from   pys_incentives
   where  inty_code = 'SURVEYED'
   and    p_catch between range_fr and range_to
   and    rownum = 1;
   return nRate;
exception
   when no_data_found then
      return 0;
end sf_get_surveyed_rate;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_TAXABLE_13TH_MONTH"
   ( p_empl_id in  varchar2,
     p_effdate in  date
   )
   return number is
   nSalary  Number(8,2);
   nTaxable Number(8,2);
   nTax13th Number(8,2);
   dEffDate Date;
begin
   if p_empl_id is null then
      nTaxable := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_header
      where  eff_date <= p_effdate;

      nTax13th := 0;
      if dEffDate is not null then
         select non_tax_13th
         into   nTax13th
         from   pys_tax_header
         where eff_date = dEffDate;
      end if;

      if nSalary > nTax13th and nTax13th > 0 then
         select m_13_amt_a
         into   nSalary
         from   pys_13th_month_summary
         where  empl_id = p_empl_id
         and    p_effdate between PERIOD_FR and PERIOD_TO;

         nTaxable := nSalary-nTax13th;
      else
         nTaxable := 0;
      end if;

   end if;
   return nTaxable;

exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_taxable_13th_month;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_TAX_BASE"
   ( p_effdate in  date,
     p_salary  in  number
   )
   return number is
   nFix   Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
   dEffDate Date;
begin
   if p_salary is null then
      nBTax := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_rates
      where  p_salary between salary_fr and salary_to
      and    eff_date <= p_effdate;

      select fix_tax, base_tax, over_pct
      into   nFix, nBTax, nRate
      from   pys_tax_rates
      where  eff_date = dEffDate
      and    p_salary between salary_fr and salary_to;
   end if;
   return nBTax;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_tax_base;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_TAX_PCT"
   ( p_effdate in  date,
     p_salary  in  number
   )
   return number is
   nFix   Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
   dEffDate Date;
begin
   if p_salary is null then
      nBTax := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_rates
      where  p_salary between salary_fr and salary_to
      and    eff_date <= p_effdate;

      select fix_tax, base_tax, over_pct
      into   nFix, nBTax, nRate
      from   pys_tax_rates
      where  eff_date = dEffDate
      and    p_salary between salary_fr and salary_to;
   end if;
   return nRate;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_get_tax_pct;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_URL" return varchar2 is
begin
   return 'http://app.tpj.com:8889';
end sf_get_url;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_USER_OFC" (p_username VARCHAR2)
RETURN VARCHAR2 AS
   vOfc pms_employees.ofc_code%type;
   vEID pms_employees.empl_id%type;
BEGIN
   BEGIN
     SELECT ofc_code, empl_id
     INTO   vOfc, vEID
     FROM   PMS_EMPLOYEES
     WHERE  user_code = p_username;
   EXCEPTION
     WHEN NO_DATA_FOUND THEN null;
   END;

   IF vOfc is null THEN
      vOfc := 'HO';
   END IF;
   RETURN vOfc;

END sf_get_user_ofc;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_VESS_NAME" (p_vess_code VARCHAR2, p_source CHAR)
RETURN VARCHAR2
AS
  vname VARCHAR2(128);
BEGIN
  SELECT vess_name INTO vname
  FROM   (
    SELECT vess.NAME vess_name
    FROM   CMS_VESSELS vess
    WHERE  code = p_vess_code
    AND    p_source = 'C'
    UNION ALL
    SELECT vess.NAME
    FROM   INV_VESSELS vess
    WHERE  code = p_vess_code
    AND    p_source = 'I');
  RETURN vname;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN '';
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR(-20001,'Invalid Code for Vessel');
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_WHTAX"
   ( p_empl_id in varchar2,
     p_effdate in date,
     p_taxtype in varchar2,
     p_salary  in number
   )
   return number is
   nBSal  Number;
   nWTax  Number;
   nBTax  Number;
   nRate  Number;
   dEffDate Date;
begin
   if p_taxtype is null then
      raise_application_error (-20001, 'No assigned Tax Type for employee  - ' || p_empl_id);
   end if;

   select max(eff_date) into dEffDate
   from   pys_withholding_tax
   where  taty_code = p_taxtype
   and    eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching effectivity date for this Tax Type for employee  - ' || p_empl_id);
   end if;

   select salary_fr, base_tax, over_pct
   into   nBSal, nBTax, nRate
   from   pys_withholding_tax
   where  taty_code = p_taxtype
   and    eff_date = dEffDate
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
end sf_get_whtax;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_GET_WHTAX_A"
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


  CREATE OR REPLACE FUNCTION "TPJ"."SF_HIRE_APPLICANT"

 (P_APPL_ID IN VARCHAR2
 ,P_EMPL_ID IN VARCHAR2
 ,P_EMTY IN VARCHAR2
 ,P_POSI IN VARCHAR2
 ,P_DEPT IN VARCHAR2
 ,P_BASIC IN NUMBER
 ,P_DATE IN DATE
 )
 RETURN VARCHAR2
 IS
vERR Varchar2(128);
BEGIN
   -- CHECK FIRST
   if p_empl_id is null then
      return 'ERROR: Please assign Employee ID...';
   end if;

   if p_emty is null then
      return 'ERROR: Please assign Employee Type...';
   end if;

   if p_dept is null then
      return 'ERROR: Please assign Department...';
   end if;

   if p_posi is null then
      return 'ERROR: Please assign Position...';
   end if;

   if nvl(p_basic,0) = 0 then
      return 'ERROR: Please assign Basic Rate...';
   end if;

   if p_date is null then
      return 'ERROR: Please assign Effectivity Start Date...';
   end if;

   insert into pms_employees (
          empl_id, last_name, first_name, middle_name, dept_code, posi_code, emty_code, basic_rate,
          gender, civil_status, home_address, home_telno, cell_no, birthdate, birthplace,
          date_hired, eff_st_date, created_by, dt_created )
   select empl_id, last_name, first_name, middle_name, dept_code, posi_code, emty_code, basic_rate,
          gender, civil_status, home_address, home_telno, cell_no, birthdate, birthplace,
          eff_start_dt, eff_start_dt, user, sysdate
   from   pms_applicants
   where  appl_id = p_appl_id;

   BEGIN
      insert into pys_employee_allowances (
             empl_empl_id, allo_code, amt, created_by, dt_created )
      select p_empl_id, allo_code, amt, user, sysdate
      from   pms_appl_allowances
      where  appl_appl_id = p_appl_id;
   EXCEPTION
      when others then
         vErr := SQLCODE || '-' || SQLERRM;
         rollback;
         return vErr;
   END;
   commit;

   return 'OK';
EXCEPTION
   when others then
      vErr := SQLCODE || '-' || SQLERRM;
      rollback;
      return vErr;
END SF_HIRE_APPLICANT;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_INV_GET_WAREHOUSE" (p_ware_name in varchar2) return varchar2 as
   vCode Varchar2(16);
begin
   begin
      select code into vCode
      from   inv_warehouse
      where  wname like '%' || upper(p_ware_name) || '%'
      and rownum =1;
   exception
      when no_data_found then vCode := '00001';
   end;
   return vCode;
end sf_inv_get_warehouse;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_APOF"
(
  p_username varchar
)  return number is
  vcheck number;
begin
  select 1
  into   vcheck
  from   pms_employees empl, inv_approving_officer approve
  where  empl.empl_id = approve.code
  and    empl.user_code = p_username;
  return 1;
exception
  when others then
    return 0;
end sf_is_apof;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_FULLMOON"
(
   p_date in date
)  return number is

   nDummy Number;

begin

   select 1 into nDummy
   from   pys_fullmoon
   where  tx_date between (p_date-1) and (p_date+1);

   return 1;

exception
   when no_data_found then
      return 0;

end sf_is_fullmoon;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_HOLIDAY"
(
   p_date in date
 --  ,p_date_fr in date
 --  ,p_date_to in date
) return number is
   nDay Number :=0;


begin

   --get holidays

   select 1
   into   nDay
   from   pys_holidays
   where tx_date = trunc(p_date);
   --where tx_date between (p_date_fr ) and p_date_to
   --and trunc(to_char(tx_date, 'MMDD')) = trunc(to_char(p_date, 'MMDD'));

   return nDay;

exception
   when no_data_found then
      return 0;
end sf_is_holiday;


 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_ISS_RECEIVER"
(
  p_username varchar
)  return number is
  vcheck number;
begin
  select 1
  into   vcheck
  from   pms_employees empl
  where  empl.user_code = p_username
  and    empl.empl_id = 'M00047';
  return 1;
exception
  when others then
    return 0;
end sf_is_iss_receiver;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_ITEM_PRE_APPROVED" (
   p_item in varchar2,
   p_cate in varchar2,
   p_itty in varchar2,
   p_itgr in varchar2,
   p_uome in varchar2,
   p_ware in varchar2,
   p_qty  in varchar2 ) return varchar2 is
   nItemQty  number;
   vPreApproved Varchar2(1);
   vRSNo Varchar2(16);
begin
   nItemQty := p_qty;
   if p_ware is null then
      for i in (select dr_no, rs_no, qty_avail
                from   inv_item_ware
                where  item_code = p_item
                and    cate_code = p_cate
                and    itty_code = p_itty
                and    itgr_code = p_itgr
                and    uome_code = p_uome
                and    qty_avail > 0
                order by dt_created)
      loop
          if nItemQty > 0 then
             nItemQty := nItemQty - i.qty_avail;
             if i.rs_no is not null then
                vRSNo := i.rs_no;
                exit;
             end if;
          else
             exit;
          end if;
      end loop;
   else
      for i in (select dr_no, rs_no, qty_avail
                from   inv_item_ware
                where  item_code = p_item
                and    cate_code = p_cate
                and    itty_code = p_itty
                and    itgr_code = p_itgr
                and    uome_code = p_uome
                and    ware_code = p_ware
                and    qty_avail > 0
                order by dt_created)
      loop
          if nItemQty > 0 then
             nItemQty := nItemQty - i.qty_avail;
             if i.rs_no is not null then
                vRSNo := i.rs_no;
                exit;
             end if;
          else
             exit;
          end if;
      end loop;
   end if;
   if vRSNo is not null then
      begin
         select pre_approved
         into   vPreApproved
         from   inv_reqslip_dtl
         where  rshd_rs_no = vRSNo
         and    item_code = p_item
         and    cate_code = p_cate
         and    itgr_code = p_itgr
         and    itty_code = p_itty
         and    uome_code = p_uome;
      exception
         when others then vPreApproved:= 'N';
      end;
   end if;
   return nvl(vPreApproved,'N');
end sf_is_item_pre_approved;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_MANAGER"
(
   p_empl_id in VARCHAR,
   p_date IN  DATE
) RETURN VARCHAR IS
   v_ismanager char(1) := 'N';
BEGIN
   for a in (
      select nvl(is_manager,'N') ismanager
       from   pys_employee_salary
       where  empl_empl_id = p_empl_id
       and    eff_st_date < p_date
       order by eff_st_date desc)
   loop
      v_ismanager := a.ismanager;
      exit;
   end loop;
   return v_ismanager;
END sf_is_manager;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_PAST_PAYROLL" (p_date in date) return number is
   dPeriodTo date;
begin
   if p_date <= to_date('20120825', 'YYYYMMDD') then
      return 1;
   else
      return 0;
   end if;
   begin
      select period_to
      into   dPeriodTo
      from   pys_payroll_hdr
      where  p_date between (period_fr-5) and (period_to-5);
      if (dPeriodTo+1) < trunc(sysdate) then
         return 1;
      end if;
   exception
      when no_data_found then null;
   end;
   return 0;
end sf_is_past_payroll;



 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_SUNDAY"
(
   p_date in  date
) return number is
begin

   if to_char(p_date, 'fmDAY') = 'SUNDAY' then
      return 1;
   else
      return 0;
   end if;
end sf_is_sunday;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_VALID_CREW" (
   p_empl_id in varchar2,
   p_vessel  in varchar2,
   p_position in varchar2) return number is
   vRankCode Varchar2(20);
   vPosiCode Varchar2(20);
begin
   SELECT voyac.rank_code
   INTO   vRankCode
         FROM   cms_voyage_crew voyac, cms_voyages voya, cms_vessels vess
         WHERE  voyac.voya_voyage_date = voya.voyage_date
         AND    voyac.voya_vess_code = voya.vess_code
         and    voya.vess_code = vess.code
         and    voya.vess_code = p_vessel
         AND    voyac.empl_empl_id = p_empl_id
         and    (voyac.dt_disembarked is null
         or     voyac.dt_disembarked > sysdate)
         AND    (voyage_end_date IS NULL
         or     voyage_end_date > sysdate);

   if vRankcode = p_position then
      return 1;
   else
                  begin
                     select 'Y' into vPosiCode
                     from   pms_positions
                     where  code = p_position
                     and    rank_code = vRankCode;
         return 1;
                  exception
                         when no_data_found then return 0;
                  end;
   end if;
exception
   when no_data_found then return 0;
   when too_many_rows then return 2;
end sf_is_valid_crew;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_IS_VALID_PAX" (
   p_empl_id in varchar2,
   p_vessel  in varchar2,
   p_position in varchar2) return number is
   vRankCode Varchar2(20);
   vPosiCode Varchar2(20);
begin
   SELECT voyac.rank_code
   INTO   vRankCode
   FROM   cms_voyage_pax voyac, cms_voyages voya, cms_vessels vess
   WHERE  voyac.voya_voyage_date = voya.voyage_date
   AND    voyac.voya_vess_code = voya.vess_code
   and    voya.vess_code = vess.code
   and    voya.vess_code = p_vessel
   AND    voyac.empl_empl_id = p_empl_id
   and    (voyac.dt_disembarked is null
   or     voyac.dt_disembarked > sysdate)
   AND    (voyage_end_date IS NULL
   or     voyage_end_date > sysdate);

   if vRankcode = p_position then
      return 1;
   else
                  begin
                     select 'Y'
         into   vPosiCode
                     from   pms_positions
                     where  code = p_position
                     and    rank_code = vRankCode;
         return 1;
                  exception
                         when no_data_found then return 0;
                  end;
   end if;
exception
   when no_data_found then return 0;
   when too_many_rows then return 2;
end sf_is_valid_pax;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_LATEST_ALLOWANCE_DATE" (
   p_empl_id in varchar2,
   p_date_fr in date
  )  return date is

   dTmpDate Date;
   sal_date date;

begin

   select max(eff_st_date) into dTmpDate
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date >= p_date_fr;

  /*if dTmpDate is null then
      select max(eff_st_date) into dTmpDate
      from   pys_employee_allowances
      where  empl_empl_id = p_empl_id
      and    eff_st_date <= p_date_fr;
   end if;*/

   return dTmpDate;
exception
   when others then
      raise_application_error (-20001, 'ERROR - retrieval of latest allowance for employee ' || p_empl_id || ' dated ' || to_char(p_date_fr));
end sf_latest_allowance_date;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_NEXT_REMITTANCE_NO" return varchar2 as
   vMaxTranNo  Varchar2(20);
   nNextNumber Number;
   vTranNo     Varchar2(20);
BEGIN

   select max(to_number(substr(tran_no, 5, instr(tran_no, '-', 1, 2)-5 )))
   into   vMaxTranNo
   from   ACC_REMITTANCES
   where  tran_no like '%' || to_char(sysdate,'"-"RRRR');

   if vMaxTranNo is null then
      vTranNo := 'TPJ-0001' || to_char(sysdate,'"-"RRRR');
   else
      nNextNumber  := to_number(vMaxTranNo)+1;
      if nNextNumber > 9999 then
         vTranNo := 'TPJ-' || to_char(nNextNumber) || to_char(sysdate,'"-"RRRR');
      else
         vTranNo := 'TPJ-' || lpad(nNextNumber, 4, '0') || to_char(sysdate,'"-"RRRR');
      end if;
   end if;
   return vTranNo;

END;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_SPELL_NUMBER" ( p_number IN NUMBER )
RETURN VARCHAR2
AS
    TYPE myArray IS TABLE OF VARCHAR2(255);
    l_str      myArray := myArray( '',
                           ' thousand ', ' million ',
                           ' billion ', ' trillion ',
                           ' quadrillion ', ' quintillion ',
                           ' sextillion ', ' septillion ',
                           ' octillion ', ' nonillion ',
                           ' decillion ', ' undecillion ',
                           ' duodecillion ' );

    l_num   VARCHAR2(50) DEFAULT TRUNC( p_number );
    l_return VARCHAR2(4000);
 l_decimal NUMBER(5);
BEGIN
    l_decimal := (p_number - TRUNC(p_number))*100;
    dbms_output.put_line(p_number);
    dbms_output.put_line(trunc(p_number));
    dbms_output.put_line(l_decimal);
    FOR i IN 1 .. l_str.COUNT
    LOOP
        EXIT WHEN l_num IS NULL;

        IF ( TO_NUMBER(SUBSTR(l_num, LENGTH(l_num)-2, 3)) <> 0 )
        THEN
           l_return := TO_CHAR(
                           TO_DATE(
                            SUBSTR(l_num, LENGTH(l_num)-2, 3),
                              'J' ),
                       'Jsp' ) || l_str(i) || l_return;
        END IF;
        l_num := SUBSTR( l_num, 1, LENGTH(l_num)-3 );
    END LOOP;
    IF l_decimal > 0 THEN
      l_return := rtrim(l_return) ||' and '|| l_decimal ||'/100 ';
    END IF;

    RETURN l_return;
END;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SF_TAX_EXEMPTION"
   ( p_effdate  in  date,
     p_tax_type in  varchar2
   )
   return number is
   nTot_Exem Number(10,2);
   dEffDate Date;
begin
   if p_tax_type is null then
      nTot_Exem := 0;
   else
      select max(eff_date)
      into   dEffDate
      from   pys_tax_exemptions
      where  taty_code = p_tax_type
      and    eff_date <= p_effdate;

      select tot_exem
      into   nTot_Exem
      from   pys_tax_exemptions
      where  taty_code = p_tax_type
      and    eff_date = dEffDate;
   end if;
   return nTot_Exem;
exception
   when no_data_found then
      return 0;
   when others then
      return 0;
end sf_tax_exemption;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SPELL_NUMBER" ( p_number IN NUMBER )
   RETURN VARCHAR2
   -- original by Tom Kyte
   -- modified to include decimal places
   AS
       TYPE myArray IS TABLE OF VARCHAR2(255);
       l_str    myArray := myArray( '',
                              ' THOUSAND ', ' MILLION ',
                              ' BILLION ', ' TRILLION ',
                              ' QUADRILLION ', ' QUINTILLION ',
                              ' SEXTILLION ', ' SEPTILLION ',
                              ' OCTILLION ', ' NONILLION ',
                              ' DECILLION ', ' UNDECILLION ',
                              ' DUODECILLION ' );
       l_num VARCHAR2(50) DEFAULT TRUNC( p_number );
       l_return VARCHAR2(4000);
   BEGIN
       FOR i IN 1 .. l_str.COUNT
       LOOP
           EXIT WHEN l_num IS NULL;

           IF ( SUBSTR(l_num, LENGTH(l_num)-2, 3) <> 0 )
           THEN
               l_return := TO_CHAR(
                               TO_DATE(
                                SUBSTR(l_num, LENGTH(l_num)-2, 3),
                                  'J' ),
                           'JSP' ) || l_str(i) || l_return;
           END IF;
           l_num := SUBSTR( l_num, 1, LENGTH(l_num)-3 );
       END LOOP;

       -- beginning of section added to include decimal places:
       IF TO_CHAR( p_number ) LIKE '%.%'
       THEN
           l_num := SUBSTR( p_number, INSTR( p_number, '.' )+1 );
           l_return := l_return || ' AND '||TO_CHAR(TO_DATE(l_num,'J'),'JSPTH');




       END IF;
       -- end of section added to include decimal places

       RETURN l_return;
 END spell_number;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SP_ACC_GET_RR_DISCOUNT" (p_po_no in varchar2) return number as
   nDiscount Number;
begin
   select sum(discount)
   into  nDiscount
   from  inv_dr_dtl
   where pohd_po_no = p_po_no;
   return nvl(nDiscount,0);
end sp_acc_get_rr_discount;


 /


  CREATE OR REPLACE FUNCTION "TPJ"."SP_GET_LATEST_BASIC_A" (
   p_empl_id in varchar2,
   p_period_to in date
   ) return number
as
   dStart Date;
   dEnd   Date;
   vVess  Varchar2(16);
   nBasic Number(12,2);
   nCola  Number(12,2);
begin
   dStart := to_date(to_char(p_period_to, 'YYYYMM"01"'), 'YYYYMMDD');
   dEnd   := last_day(dStart);
   for i in (select latest_vess from pys_payroll_dtl
             where  period_to between dStart and dEnd
             and    empl_empl_id = p_empl_id
             order  by period_to desc, period_fr desc )
   loop
      vVess := i.latest_vess;
      exit;
   end loop;

   for i in ( select basic_rate
              from   pys_payroll_a
              where  period_to between dStart and dEnd
              and    empl_empl_id = p_empl_id
              and    basic_rate <> 0
              and    vess_code = vVess
              order  by period_to desc, period_fr desc )
   loop
      nBasic := i.basic_rate;
      exit;
   end loop;

   select max(cola_pay)
   into   nCola
   from   pys_payroll_dtl_log
   where  pay_date between dStart and dEnd
   and    empl_empl_id = p_empl_id
   and    vess_code = vVess;

   return nvl(nBasic,0)+nvl(nCola,0);
exception
   when others then return null;
end sp_get_latest_basic_a;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SP_GET_LATEST_PERIOD_B" (
   p_empl_id in varchar2,
   p_period_to in date,
   p_period_no in number
   ) return date
as
   dPeriodTo Date;
begin
   for i in (select period_to from pys_payroll_dtl
             where  period_to >= p_period_to
             and    empl_empl_id = p_empl_id
             and    pahd_payroll_no = p_period_no
             and    paty_code like 'REG%'
             order  by period_to asc )
   loop
      dPeriodTo := i.period_to;
      exit;
   end loop;
   return nvl(dPeriodTo, p_period_to);
end sp_get_latest_period_b;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SP_GET_LATEST_TITLE_A" (
   p_empl_id IN VARCHAR2,
   p_period_to IN DATE
   ) RETURN VARCHAR2
AS
   dStart  DATE;
   dEnd    DATE;
   vTitle  VARCHAR2(64);
BEGIN
   dStart := TO_DATE(TO_CHAR(p_period_to, 'YYYYMM"01"'), 'YYYYMMDD');
   dEnd   := LAST_DAY(dStart);
   FOR i IN (SELECT title FROM pys_payroll_dtl
             WHERE  period_to BETWEEN dStart AND dEnd
             AND    empl_empl_id = p_empl_id
             ORDER  BY period_to DESC )
   LOOP
      vTitle := i.title;
      EXIT;
   END LOOP;
   RETURN NVL(vTitle, ' ');
END sp_get_latest_title_a;
 /


  CREATE OR REPLACE FUNCTION "TPJ"."SP_GET_LATEST_VESSEL_A" (
   p_empl_id in varchar2,
   p_period_to in date
   ) return varchar2
as
   dStart Date;
   dEnd   Date;
   vVess  Varchar2(16);
begin
   dStart := to_date(to_char(p_period_to, 'YYYYMM"01"'), 'YYYYMMDD');
   dEnd   := last_day(dStart);
   for i in (select latest_vess from pys_payroll_dtl
             where  period_to between dStart and dEnd
             and    empl_empl_id = p_empl_id
             order  by period_to desc )
   loop
      vVess := i.latest_vess;
      exit;
   end loop;
   return nvl(vVess, ' ');
end sp_get_latest_vessel_a;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."SP_GET_LATEST_VESSEL_B" (
   p_empl_id in varchar2,
   p_pay_no in number
   ) return varchar2
as
   dStart Date;
   dEnd   Date;
   vVess  Varchar2(16);
begin
   for i in (select latest_vess from pys_payroll_dtl
             where  pahd_payroll_no = p_pay_no
             and    empl_empl_id = p_empl_id
             order  by period_to desc )
   loop
      vVess := i.latest_vess;
      exit;
   end loop;
   return nvl(vVess, ' ');
end sp_get_latest_vessel_b;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."VALIDATE_USER"
   (host_service VARCHAR2
   ,usernm       VARCHAR2
   ,old_password VARCHAR2) RETURN NUMBER
AS
   drop_db_link    BOOLEAN;
   bad_uname_pw    BOOLEAN;
   hold_username   VARCHAR2(100);
   v_host_service  VARCHAR2(100);
   bad_username_pw EXCEPTION;
   bad_db_link     EXCEPTION;
   bad_db_name     EXCEPTION;
   same_open_conn     EXCEPTION;
   PRAGMA EXCEPTION_INIT(bad_username_pw,-1017);
   PRAGMA EXCEPTION_INIT(bad_db_link,-2024);
   PRAGMA EXCEPTION_INIT(bad_db_name,-12154);
   PRAGMA EXCEPTION_INIT(same_open_conn,-2018);
BEGIN
   v_host_service := 'TPJNEW';
   drop_db_link    := FALSE;
   DECLARE
      dummy    CHAR(1);
   BEGIN
      SELECT 'x' INTO dummy
      FROM user_db_links
      WHERE db_link LIKE 'DBLINK'||usernm||'%';
      drop_db_link    := TRUE;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         drop_db_link := FALSE;
          WHEN TOO_MANY_ROWS THEN
             drop_db_link    := TRUE;
   END;
   DBMS_OUTPUT.PUT_LINE('Checking DB LINK');
   IF drop_db_link THEN
      FOR a IN (
             SELECT db_link FROM user_db_links
         WHERE db_link LIKE 'DBLINK'||usernm||'%')
          LOOP
         BEGIN
            EXECUTE IMMEDIATE 'drop database link '||a.db_link;
         EXCEPTION
            WHEN bad_db_link THEN NULL;
            WHEN same_open_conn THEN NULL;
         END;
          END LOOP;
   END IF;
   DBMS_OUTPUT.PUT_LINE('Create DB LINK');
   EXECUTE IMMEDIATE 'create database link dblink'||usernm||' connect to '||usernm||' identified by '||old_password||' using '''||v_host_service||'''';
   DBMS_OUTPUT.PUT_LINE('Finish DB LINK');
   EXECUTE IMMEDIATE 'select username from user_users@dblink'||usernm INTO hold_username;
   BEGIN
          FOR a IN (
             SELECT db_link FROM user_db_links
         WHERE db_link LIKE 'DBLINK'||usernm||'%')
          LOOP
         BEGIN
            EXECUTE IMMEDIATE 'drop database link '||a.db_link;
         EXCEPTION
            WHEN bad_db_link THEN NULL;
            WHEN same_open_conn THEN NULL;
         END;
          END LOOP;
   END LOOP;
   COMMIT;
   RETURN 0;
EXCEPTION
   WHEN bad_username_pw THEN
      bad_uname_pw    := TRUE;
      COMMIT;
      RETURN 1;
END;

 /


  CREATE OR REPLACE FUNCTION "TPJ"."sf_get_report_url" (
   p_rpt in varchar2,
   p_usr in varchar2,
   p_pwd in varchar2,
   p_con in varchar2
   ) return varchar2 is
   vReportServer Varchar2(60) := 'tpjrepserver';
begin
   return (sf_get_url || '/reports/rwservlet?server=' || vReportServer || '&report=C:\DevSuiteHome\forms\tpj\' || upper(p_rpt) || '.rdf&destype=cache&desformat=HTMLCSS&paramform=YES&userid=' || p_usr || '/' || p_pwd || '@' || p_con);
end sf_get_report_url;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."CURSOR_COMPARISON" AS
  l_loops  NUMBER := 1000000;
  l_dummy  dual.dummy%TYPE;
  l_start  NUMBER;

  CURSOR c_dual IS
    SELECT dummy
    FROM dual;
BEGIN
  -- Time implicit cursor.
  l_start := DBMS_UTILITY.get_time;

  FOR i IN 1 .. l_loops LOOP
    SELECT dummy
    INTO   l_dummy
    FROM   dual;
  END LOOP;

  DBMS_OUTPUT.put_line('Implicit: ' ||
                       (DBMS_UTILITY.get_time - l_start));

  -- Time explicit cursor.
  l_start := DBMS_UTILITY.get_time;

  FOR i IN 1 .. l_loops LOOP
    OPEN  c_dual;
    FETCH c_dual
    INTO  l_dummy;
    CLOSE c_dual;
  END LOOP;

  DBMS_OUTPUT.put_line('Explicit: ' ||
                       (DBMS_UTILITY.get_time - l_start));


END cursor_comparison;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_APV_DOWNLOAD_INV" (
   p_period_fr date,
   p_period_to date,
   p_ap_no     varchar2,
   p_inv_type  varchar2,
   p_supp_code varchar2
  ) as
  vStatus Varchar2(16);
   nItem   Number;
   nrr_conv ACC_AP_INV_DTL.rr_conv%type;
BEGIN
   if (p_period_fr is null) or (p_period_to is null)   then
      RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - Please enter period to download...');
   end if;

   -- clear PO and JO attachement to AP
   for i in (select rr_no, po_no from acc_ap_inv_dtl where ap_no = p_ap_no and is_selected = 'N') loop
       if substr(i.po_no,1,2) = 'JO' then
          -- clear JO
          update inv_jo_dr_hdr
          set    ap_no = null
          where  jo_dr_no = i.rr_no;
          --and    ap_no = p_ap_no;
      else
          -- clear PO
          update inv_dr_hdr
          set    ap_no = null
          where  dr_no = i.rr_no;
          --and    ap_no = p_ap_no;
      end if;
      if sql%found then
          -- delete
          delete from acc_ap_inv_dtl
          where  ap_no = p_ap_no
          and    rr_no = i.rr_no
          and    po_no = i.po_no
          and    is_selected = 'N';
      end if;
   end loop;

   if p_inv_type = 'PO' then
      for a in ( SELECT rr_no
                 FROM   acc_ap_inv_dtl
                 WHERE  ap_no = p_ap_no
                 AND    po_no like 'JO%')
      loop
         UPDATE inv_jo_dr_hdr
         SET    ap_no = null
         WHERE  jo_dr_no = a.rr_no
         AND    ap_no = p_ap_no;
      end loop;
      DELETE FROM acc_ap_inv_dtl
      WHERE  ap_no = p_ap_no
      AND    po_no LIKE 'JO%';
   end if;

   if p_inv_type = 'JO' then
      for a in ( SELECT rr_no
                 FROM   acc_ap_inv_dtl
                 WHERE  ap_no = p_ap_no
                 AND    po_no not LIKE 'JO%')
      loop
         update inv_dr_hdr
         set    ap_no = null
         where  dr_no = a.rr_no
         and    ap_no = p_ap_no;
      end loop;
      DELETE FROM acc_ap_inv_dtl
      WHERE  ap_no = p_ap_no
      AND    po_no not like 'JO%';
   end if;

   DELETE FROM acc_ap_advances acad
   WHERE ap_no = p_ap_no;

   SELECT nvl(max(item_no),0)
   INTO   nItem
   FROM   acc_ap_inv_dtl
   WHERE  ap_no = p_ap_no;

   nrr_conv := 0;

   if p_inv_type = 'PO' then
      for i in (SELECT drhd.dr_no rr_no,
                       drhd.po_no po_no,
                       drhd.rs_no rs_no,
                       nvl(drhd.dr_date, drhd.invoice_dt) rr_date,
                       nvl(drhd.invoice_no, drhd.supp_dr_no) invoice_no,
                       drhd.rr_amt-nvl(drhd.addtl_disc,0) rr_amt,
                       drhd.rr_paid rr_paid,
                       drhd.po_currency,
                       sf_get_inv_adv_payment('PO',drhd.po_no) cpa_amt,
                       sf_get_inv_adv_payment_php('PO',drhd.po_no) cpa_amt_php,
                       sf_get_retslip_amt(drhd.dr_no) ret_amt,
                       ap_no
                FROM   acc_inv_rr_dtl drhd
                WHERE  drhd.supp_code = p_supp_code
                AND    ap_no is null
                AND    drhd.dr_date BETWEEN p_period_fr AND p_period_to
                --AND    drhd.po_terms <> 'COD'
                AND    not exists (
                       SELECT 1
                       FROM   acc_ap_inv_dtl apin
                       WHERE  apin.rr_no = drhd.dr_no
                       AND    apin.ap_no = p_ap_no
                       )
                ORDER  BY DRHD.DR_DATE)
      loop
         nItem := nItem + 1;
         if i.po_currency = 'PHP' then
              nrr_conv := 1;
         else
              nrr_conv := 0;
         end if;
         INSERT INTO ACC_AP_INV_DTL
                ( item_no, ap_no, rr_no, rs_no, po_no, invoice_no, amount,
                  amount_net, rr_date, created_by, dt_created, rr_conv, cpa_amt, cpa_amt_php, ret_amt, ret_amt_php)
         VALUES ( nItem, p_ap_no, i.rr_no, i.rs_no, i.po_no, i.invoice_no, 0, --i.rr_amt,
                 i.rr_amt - (i.cpa_amt_php+i.ret_amt), i.rr_date, user, sysdate, nrr_conv, i.cpa_amt, i.cpa_amt_php, i.ret_amt, i.ret_amt);
         nrr_conv := 0;
         update inv_dr_hdr
               set    ap_no = p_ap_no
               where  dr_no = i.rr_no
               and    ap_no is null;
      end loop;
   end if;

   if p_inv_type = 'JO' then
      for i in (SELECT drhd.jo_dr_no dr_no,
                       drhd.supp_code supp_code,
                       drhd.johd_jo_no jo_no,
                       johd.jshd_js_no js_no,
                       drhd.supp_dr_no invoice_no,
                       nvl(drhd.invoice_dt,drhd.jo_dr_date) dr_date,
                       drhd.rr_amt rr_amt,
                       drhd.rr_paid rr_paid,
                       max(drdt.currency) po_currency,  --  'PHP',
                       sf_get_inv_adv_payment('JO',drhd.johd_jo_no) cpa_amt,
                       sf_get_inv_adv_payment_php('JO',drhd.johd_jo_no) cpa_amt_php
                FROM   inv_jo_dr_hdr drhd,
                       inv_jo_dr_dtl drdt,
                       inv_jo_hdr johd
                WHERE  drhd.johd_jo_no = johd.jo_no
                AND    drhd.jo_dr_no = drdt.jdhd_jo_dr_no
                AND    drdt.johd_jo_no = johd.jo_no
                AND    drhd.status='APPROVED'
                AND    drhd.supp_code = p_supp_code
                --AND   johd.terms <> 'COD'
                -- modified 20101208 as per ms sonia used invoice date
                --AND   drhd.jo_dr_date BETWEEN p_period_fr AND p_period_to
                AND    drhd.invoice_dt between p_period_fr and p_period_to
                AND    drhd.ap_no is null
                AND    not exists ( SELECT 1
                                    FROM   acc_ap_inv_dtl apin
                                    WHERE  apin.rr_no = drhd.jo_dr_no
                                    AND    apin.ap_no = p_ap_no
                                   )
                GROUP BY drhd.jo_dr_no,
                       drhd.supp_code,
                       drhd.johd_jo_no,
                       johd.jshd_js_no,
                       drhd.supp_dr_no,
                       nvl(drhd.invoice_dt,drhd.jo_dr_date),
                       drhd.rr_amt,
                       drhd.rr_paid,
                       sf_get_inv_adv_payment('JO',drhd.johd_jo_no)
                ORDER  BY 6 )
      loop
         nItem := nItem + 1;
         if i.po_currency = 'PHP' then
              nrr_conv := 1;
         else
              select fx_value
              into   nrr_conv
              from (select fx_date, fx_value from acc_forex where curr_code = i.po_currency and fx_date <= i.dr_date order by fx_date desc)
              where rownum = 1;
              if nrr_conv is null then
                 nrr_conv := 0;
              end if;
         end if;
         INSERT INTO acc_ap_inv_dtl
                ( item_no, ap_no, rr_no, rs_no, po_no, invoice_no, amount, amount_net, rr_date, created_by, dt_created, rr_conv, cpa_amt, cpa_amt_php)
         VALUES ( nItem, p_ap_no, i.dr_no, i.js_no, 'JO'||i.jo_no, i.invoice_no, i.rr_amt*nrr_conv, (i.rr_amt*nrr_conv)-i.cpa_amt, i.dr_date, user, sysdate, nrr_conv, i.cpa_amt, i.cpa_amt_php );
         nrr_conv := 0;
         UPDATE inv_jo_dr_hdr
         SET    ap_no = p_ap_no
         WHERE  jo_dr_no = i.dr_no
         AND    ap_no is null;
      end loop;
   end if;
   commit;
END sp_acc_apv_download_inv;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_APV_POST_INV" (
  p_ap_no in varchar2,
  p_drhd_curr in varchar2,
  p_Unused_Adv out number,
  p_Unused_Adv_Php out number
  ) as
   vPeriod_to           acc_ap_hdr.period_to%type;
   vAp_Date             acc_ap_hdr.ap_date%type;
   vInv_Type            acc_ap_hdr.inv_type%type;
   vRef_AP_No           acc_ap_hdr.ref_ap_no%type;
   vVat                 acc_ap_hdr.vat%type;
   vVat_Inc             acc_ap_hdr.vat_inc%type;
   vAp_Discount         acc_ap_hdr.ap_discount%type;
   vAp_Disc_Amt         acc_ap_hdr.ap_disc_amt%type;
   vAp_Oth_Disc_Amt     acc_ap_hdr.ap_oth_disc_amt%type;
   vUnused_Adv          acc_ap_hdr.unused_adv%type;
   vUnused_Adv_Php      acc_ap_hdr.unused_adv_php%type;
   vTotal_Amount        number(16,4);
   vTotal_Amount_Net    number(16,4);
   vTotal_Ret_Amt       number(16,4);
   vTotal_Ret_Amt_Php   number(16,4);
   vTotal_FX_Amount     number(16,4);
   vTotal_Amount_Net_FX number(16,4);
   vStatus      Varchar2(16);
   nDummy       Number;
   nVat         number(16,2);
   nVatphp      number(16,2);
   nAmtPhp      number(16,2);
   nDiscphp     number(16,2);
   nAmt         number(16,2);
   nDisc        number(16,2);
   nDisc_oth    number(16,2);
   nDisc_othphp number(16,2);
   nItem        Number := 1;
   vAP_Accnt    Varchar2(16):= '60001';
   vMaterial    Varchar2(16):= '903';
   vRepair      Varchar2(16):= '923';
   vDisc_Acct   Varchar2(16):= '944.1';
   vVAT_Acct    Varchar2(16):= '60005';
   vAdv_acct    Varchar2(16):= '40004';
   vSus_Acct    Varchar2(16):= '10010';
   vCurr_Code   varchar2(16);
   vInvType     varchar2(16);
   nSus         number(16,2);
   nSusPhp      number(16,2);
   nAdv         number(16,2);
   nAdvPhp      number(16,2);
   nSus1        number(16,2);
   nSusPhp1     number(16,2);
   nAdv1        number(16,2);
   nAdvPhp1     number(16,2);
   v_RefAp      char(1) := 'N';
   vCurr        varchar2(30);
   dCurrDate    date;
   nForex       Number;
BEGIN
   -- clear apv details
   delete from acc_ap_dtl where ap_no = p_ap_no;

   select period_to, ap_discount, ap_disc_amt, ap_oth_disc_amt, ap_date,
          vat, vat_inc, inv_type, ref_ap_no, unused_adv, unused_adv_php
   into   vPeriod_to, vAp_Discount, vAp_Disc_Amt, vAp_Oth_Disc_Amt, vAp_Date,
          vVat, vVat_Inc, vInv_Type, vRef_AP_No, vUnused_Adv, vUnused_Adv_Php
   from   acc_ap_hdr
   where  ap_no = p_ap_no;

   -- select sum(amount), sum(amount_net), sum(ret_amt), sum(ret_amt_php), sum(fx_amount), sum(fx_amount-(cpa_amt+ret_amt))
   select sum(amount), sum(amount-(cpa_amt_php+ret_amt_php)), sum(fx_amount-(cpa_amt+ret_amt)), sum(ret_amt), sum(ret_amt_php), sum(fx_amount)
   into   vTotal_Amount, vTotal_Amount_Net, vTotal_Amount_Net_FX, vTotal_Ret_Amt, vTotal_Ret_Amt_PHP, vTotal_FX_Amount
   from   acc_ap_inv_dtl
   where  ap_no = p_ap_no;

   insert into debug_log (source, ref_code, dt_created, ref_info )
   values ( 'SP_ACC_APV_POST_INV', p_ap_no, sysdate,
                               'vTotal_Amount=' || to_char(vTotal_Amount) ||
                               ' vTotal_Amount_Net = ' || to_char(vTotal_Amount_Net ) ||
                               ' vTotal_Amount_Net_FX = ' || to_char(vTotal_Amount_Net_FX) ||
                               ' vTotal_Ret_Amt = ' || to_char(vTotal_Ret_Amt) ||
                               ' vTotal_Ret_Amt_PHP = ' || to_char(vTotal_Ret_Amt_PHP) ||
                               ' vTotal_FX_Amount = ' || to_char(vTotal_FX_Amount) ||
                               ' vVat = ' || to_char(vVat) ||
                               ' vVat_Inc = ' || vVat_Inc ||
                               ' vInv_Type = ' || vInv_Type ||
                               ' vUnused_Adv = ' || to_char(vUnused_Adv) ||
                               ' vUnused_Adv_Php = ' || to_char(vUnused_Adv_Php) ||
                               ' vRef_AP_No = ' || to_char(vRef_AP_No) ||
                               ' p_drhd_curr = ' || p_drhd_curr );

   if vInv_Type = 'PO' then
      vInvType := 'PO';
   else
      vInvType := 'JO';
   end if;

   vCurr_Code := p_drhd_curr;

   --msg_alert ('check nAMT  -> ' || to_char(vTotal_Amount_Net), 'I', FALSE);
   nAmtPhp  := vTotal_Amount_Net;
   nDiscphp := (vTotal_Amount_Net*(vAp_Discount/100)) + (vAp_Disc_Amt*sf_get_fx_rate(vCurr_Code, vAp_Date));
   nAmt     := vTotal_Amount_Net_fx;
   nDisc    := (vTotal_Amount_Net_fx*(vAp_Discount/100)) + vAp_Disc_Amt;

   --namtphp  := :apin.total_amount_net;
   --ndiscphp := (:apin.total_amount_net*(:aphd.ap_discount/100)) + (:aphd.ap_disc_amt*sf_get_fx_rate(vcurr_code, :aphd.ap_date));
   --namt     := :apin.total_amount_net_fx;
   --ndisc    := (:apin.total_amount_net_fx*(:aphd.ap_discount/100)) + :aphd.ap_disc_amt;

   -- Other discount
   nDisc_oth    := nvl(vAp_Oth_Disc_Amt,0);
   nDisc_othphp := nvl(vAp_Oth_Disc_Amt,0)*sf_get_fx_rate(vCurr_Code, vAp_Date);

   --ndisc_oth    := nvl(:aphd.ap_oth_disc_amt,0);
   --ndisc_othphp := nvl(:aphd.ap_oth_disc_amt,0)*sf_get_fx_rate(vcurr_code, :aphd.ap_date);



   insert into acc_ap_dtl (
            item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
            debit, credit, debit_php, credit_php, created_by, dt_created)
   values ( nitem, p_ap_no, decode(vInv_Type,'PO',vMaterial,vRepair), vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
            vTotal_FX_Amount-nvl(vTotal_Ret_Amt,0), 0, vTotal_Amount-nvl(vTotal_Ret_Amt_PHP,0), 0, user, sysdate);

   if vAp_Discount > 0 or vAp_Disc_Amt > 0 then
      nitem := nitem + 1;
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created)
      values ( nitem, p_ap_no, vDisc_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
               0, nDisc, 0, nDiscphp, user, sysdate);
   end if;

   if nDisc_oth > 0 then
      nitem := nitem + 1;
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created)
      values ( nitem, p_ap_no, vDisc_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
               0, nDisc_oth, 0, nDisc_othphp, user, sysdate);
   end if;

   if vVat_Inc = 'Y' or vVat > 0 then

      if vVat_Inc = 'Y' then
          nVat    := nvl((nvl(vVat,0)/100) * (vTotal_FX_Amount / sf_get_acc_ewt),0);
          nVatphp := nvl((nvl(vVat,0)/100) * (vTotal_Amount    / sf_get_acc_ewt),0);
      else
          nVat    := nvl((vTotal_FX_Amount) * (nvl(vVat,0)/100),0);
          nVatphp := nvl((vTotal_Amount)    * (nvl(vVat,0)/100),0);
      end if;
      /* -- commented out by rollie 20100118
         -- as per ms sonia, vat should look into total amount not net total amount
      */
      nitem := nitem + 1;
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vVAT_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
               0, nVat, 0, nVatphp, user, sysdate  );

   end if;

   dbms_output.put_line('nAmt:' || to_char(nAmt) || 'nVat:' || to_char(nVat) || '^nDisc:' || to_char(nDisc) || '^nDisc_oth:' || to_char(nDisc_oth));
   nAmt    := nAmt    - round((nvl(nVat,0)    + nvl(nDisc,0) + nvl(nDisc_oth,0)),2);
   nAmtPhp := nAmtPhp - round((nvl(nVatphp,0) + nvl(nDiscphp,0) + nvl(nDisc_othphp,0)),2);

   delete from acc_ap_oth_dtl where ap_no = p_ap_no;

   for a in (select is_selected, po_no from acc_ap_inv_dtl where ap_no = p_ap_no)
   loop
       if nvl(a.is_selected,'N') = 'N' then
          delete from acc_ap_advances
          where  ap_no    = p_ap_no
          and    po_no    = replace(a.po_no,'JO','')
          and    inv_type = vInv_Type;
       else
          sp_pop_inv_adv_payment(p_ap_no, vInv_Type, replace(a.po_no,'JO','') );
       end if;
   end loop;

   delete from acc_ap_advances acad
   where  ap_no    = p_ap_no
   and    inv_type = vInv_Type
   and    not exists (select 1
                      from   acc_ap_inv_dtl apid, acc_ap_hdr aphd
                      where  apid.ap_no = acad.ap_no
                      and    aphd.ap_no = apid.ap_no
                      and    replace(apid.po_no,'JO','') = acad.po_no
                      and    acad.inv_type = aphd.inv_type);

   for a in (SELECT rr_no FROM acc_ap_inv_dtl
             WHERE  ap_no = p_ap_no
             AND    is_selected = 'N')
   loop
      if vInv_Type = 'PO' then
         update inv_dr_hdr
         set    ap_no = null
         where  dr_no = a.rr_no
         and    ap_no = p_ap_no;
      else
         update inv_jo_dr_hdr
         set    ap_no = null
         where  jo_dr_no = a.rr_no
         and    ap_no = p_ap_no;
      end if;
   end loop;

   -- clear PO and JO attachement to AP
   for i in (select rr_no, po_no from acc_ap_inv_dtl where ap_no = p_ap_no and is_selected = 'N') loop
       if substr(i.po_no,1,2) = 'JO' then
          -- clear JO
          update inv_jo_dr_hdr
          set    ap_no = null
          where  jo_dr_no = i.rr_no;
          --and    ap_no = p_ap_no;
      else
          -- clear PO
          update inv_dr_hdr
          set    ap_no = null
          where  dr_no = i.rr_no;
          --and    ap_no = p_ap_no;
      end if;
      if sql%found then
          -- delete
          delete from acc_ap_inv_dtl
          where  ap_no = p_ap_no
          and    rr_no = i.rr_no
          and    po_no = i.po_no
          and    is_selected = 'N';
      end if;
   end loop;

   dbms_output.put_line('nAmt:' || to_char(nAmt) || '^nAmtPhp:' || to_char(nAmtPhp));
   -- get balance from previous ap transaction
   if vRef_AP_No is not null then
        for a in ( select nvl(unused_adv_php,0) unused_adv_php, nvl(unused_adv,0) unused_adv
                   from   acc_ap_hdr
                   where  ap_no = vRef_AP_No )
        loop
           dbms_output.put_line('unused_adv:' || to_char(trunc(a.unused_adv,2)) || '^a.unused_adv_php:' || to_char(trunc(a.unused_adv_php,2)));
           insert into acc_ap_advances(
                   ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
           values (p_ap_no, 'AP', vRef_AP_No, vInvType, '0', a.unused_adv, user, sysdate, a.unused_adv_php);
           nitem := nitem + 1;
           insert into acc_ap_dtl (
                   item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
                   debit, credit, debit_php, credit_php, created_by, dt_created )
           values (nitem, p_ap_no, vAP_Accnt, vInvType, vInvType || '#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
                   0, (trunc(nAmt,2) - trunc(a.unused_adv,2)), 0, (trunc(nAmtPhp,2) - trunc(a.unused_adv_php,2)), user, sysdate);                   --0, greatest((trunc(nAmt,2) - trunc(a.unused_adv,2)),0), 0, greatest((trunc(nAmtPhp,2) - trunc(a.unused_adv_php,2)),0), user, sysdate);
           v_RefAp := 'Y';
        end loop;
   end if;

   if v_RefAp = 'N' then
      nitem := nitem + 1;
      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vAP_Accnt, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
               0, greatest(nvl(nAmt,0),0), 0, greatest(nvl(nAmtPhp,0),0), user, sysdate  );
   end if;

   nSus    := 0;
   nSusPhp := 0;
   nAdv    := 0;
   nAdvPhp := 0;

   for a in ( select ref_type, ref_code, adv_amount, adv_amount_php, inv_type, po_no
              from   acc_ap_advances
              where  ap_no = p_ap_no )
   loop
       -- get currency
       if a.ref_type = 'CV' then
          for a in ( SELECT NVL(pohd.currency, 'PHP') currency
                     FROM   acc_ap_inv_dtl apidt, inv_po_hdr pohd
                     WHERE  apidt.is_selected= 'y'
                     AND    pohd.po_no = apidt.po_no
                     AND   (apidt.rs_no LIKE 'M%' OR apidt.rs_no LIKE 'O%')
                     AND    apidt.ap_no = p_ap_no
                     UNION ALL
                     SELECT max(drdt.currency)  currency
                     FROM   acc_ap_inv_dtl apidt, inv_jo_hdr johd, inv_jo_dr_hdr drhd, inv_jo_dr_dtl drdt
                     WHERE  apidt.is_selected= 'Y'
                     AND    johd.jo_no = apidt.po_no
                     AND    drhd.johd_jo_no = johd.jo_no
                     AND    drhd.jo_dr_no = drdt.jdhd_jo_dr_no
                     AND    drdt.johd_jo_no = johd.jo_no
                     AND    (apidt.rs_no NOT LIKE 'M%' AND apidt.rs_no NOT LIKE 'O%')
                     AND    apidt.ap_no = p_ap_no
                     UNION ALL
                     SELECT NVL(apidt.invoice_curr, 'PHP') currency
                     FROM   acc_ap_oth_dtl apidt
                     WHERE  apidt.is_selected= 'Y'
                     AND    apidt.AP_NO = p_ap_no )
          loop
             vCurr := a.currency;
             exit;
          end loop;
       end if;

       if a.ref_type = 'CV' then
          for b1 in ( select cpdt.acco_code, cpdt.amount, cpdt.cpa_no
                      from   acc_cv_cpa_dtl cvcp, acc_cpa_dtl cpdt
                      where  cpdt.acco_code in (vSus_Acct, vAdv_acct)
                      and    cvcp.cv_no    = a.ref_code
                      and    cpdt.cpa_no   = cvcp.cpa_no
                      and    cpdt.ref_type = a.inv_type
                      and    cpdt.ref_code = a.po_no )
          loop
             if b1.acco_code = vSus_Acct then
                nSus    := nSus    + b1.amount;
                nSusPhp := nSusPhp + b1.amount;
             end if;
             if b1.acco_code = vAdv_acct then
                if vCurr <> 'PHP' then
                   begin
                      select h.cv_date
                      into   dCurrDate
                      from   acc_cv_cpa_dtl a, acc_cv_hdr h
                      where  h.cv_no = a.cv_no
                      and    a.cpa_no = b1.cpa_no
                      and   rownum = 1;
                   exception
                      when others then
                         RAISE_APPLICATION_ERROR(-20002, 'Error getting CV date...');
                   end;
                   nForex := sf_get_fx_rate (vCurr, dCurrDate);
                   nAdv   := nAdv    + (b1.amount/nForex);
                else
                   nAdv    := nAdv    + b1.amount;
                end if;
                nAdvPhp := nAdvPhp + b1.amount;
             end if;
          end loop;
       end if;

       if a.ref_type = 'JV' then
          for b1 in ( select acco_code, debit, debit_php from acc_jv_dtl
                      where  acco_code in (vSus_Acct, vAdv_acct)
                      and    jv_no = a.ref_code
                      and    ref_type = a.inv_type
                      and    ref_code = a.po_no )
          loop
             if b1.acco_code = vSus_Acct then
                nSus    := nSus    + b1.debit;
                nSusPhp := nSusPhp + b1.debit_php;
             end if;
             if b1.acco_code = vAdv_acct then
                nAdv    := nAdv    + b1.debit;
                nAdvPhp := nAdvPhp + b1.debit_php;
             end if;
          end loop;
       end if;

       if a.ref_type = 'AP' then
          nAdv    := nAdv    + a.adv_amount;
          nAdvPhp := nAdvPhp + a.adv_amount_php;
       end if;

       if a.ref_type = 'PCV' then
          for b1 in  ( select amt
                       from   acc_pcv_dtl pcdt
                       where  pcdt.acco_code = vAdv_acct
                       and    pcdt.pcv_no    = a.ref_code )
          loop
             nAdv    := nAdv    + a.adv_amount;
             nAdvPhp := nAdvPhp + a.adv_amount_php;
             exit;
          end loop;
       end if;
   end loop;
   --40004
   --10010

   nSus1    := nSus;
   nSusPhp1 := nSusPhp;
   nAdv1    := nAdv;
   nAdvPhp1 := nAdvPhp;

   if nSus <> 0 and nSusPhp <> 0 then
      nitem := nitem + 1;

      if vTotal_FX_Amount < nSus then
          nSus1 := vTotal_FX_Amount;
      end if;
      if vTotal_Amount < nSusPhp then
          nSusPhp1 := vTotal_Amount;
      end if;

      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vSus_Acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
               0, nSus1, 0, nSusPhp1, user, sysdate);
   end if;

   if nAdv <> 0 and nAdvPhp <> 0 then
      nitem := nitem + 1;
      if (vTotal_FX_Amount - nvl(nSus,0)) < nAdv then
          nAdv1 := (vTotal_FX_Amount - nvl(nSus,0));
      end if;
      if (vTotal_Amount - nvl(nSusPhp,0)) < nAdvPhp then
          nAdvPhp1 := (vTotal_Amount - nvl(nSusPhp,0));
      end if;

      insert into acc_ap_dtl (
               item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created )
      values ( nitem, p_ap_no, vAdv_acct, vInvType, vInvType ||'#' || to_char(vPeriod_To, 'MMYYYY'), vInvType,
               0, nAdv1, 0, nAdvPhp1, user, sysdate);
   end if;

   vUnused_Adv     := greatest(((nAdv + nSus)-(vTotal_FX_Amount)),0);
   vUnused_Adv_Php := greatest(((nAdvPhp + nSusPhp)-(vTotal_Amount)),0);

   -- get unused advance payments from APV
   for a in  ( select unused_adv, unused_adv_php
               from   acc_ap_hdr
               where  ap_status = 'APPROVED'
               and    ap_no > vRef_AP_No
               and    ap_no < p_ap_no
               and    unused_adv > 0
               and    unused_adv_php > 0
               order  by ap_no desc )
   loop
     vUnused_Adv     := vUnused_Adv + a.unused_adv;
     vUnused_Adv_Php := vUnused_Adv_Php + a.unused_adv_php;
     exit;
   end loop;
   commit;
   p_Unused_Adv := nvl(vUnused_Adv,0);
   p_Unused_Adv_Php := nvl(vUnused_Adv_Php,0);

END sp_acc_apv_post_inv;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_CONT_PAYROLL_ENTRIES" (
   p_payroll_no in number,
   p_period_fr in date,
   p_period_to in date
   ) is
   vPetty     Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
   vRepair    Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('REPAIR ACCOUNT CODE');
   vFinancial Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('FINANCIAL ACCOUNT CODE');
   nPCVNo acc_pcv_hdr.pcv_no%type;
   nOPCVNo acc_pcv_hdr.o_pcv_no%type;
BEGIN

   for i in (SELECT CODE, NAME, P_TYPE, SUM(AMT) AMT FROM (
             select a.contractor_code code, b.name, sum(a.TOTAL_PAY) amt, 'C' p_type
             from pys_contractual_payroll_dtl a, pms_contractors b
             where a.payroll_no = p_payroll_no
             and   a.pcv_no is null
             and   a.contractor_code is not null
             and   a.contractor_code = b.code
             group by a.contractor_code, b.name, 'C'
             union
             select a.contractor_code code, b.name, sum(VALE_AMT*-1) amtt, 'C' p_type
             from pys_contractor_payroll_dtl a, pms_contractors b
             where a.payroll_no = p_payroll_no
             and   a.pcv_no is null
             and   a.contractor_code is not null
             and   a.contractor_code = b.code
             group by a.contractor_code, b.name, 'C'
             union
             select a.vess_code code, b.name, sum(a.TOTAL_PAY) amtt, 'V' p_type
             from pys_contractual_payroll_dtl a, cms_vessels b
             where a.payroll_no = p_payroll_no
             and   a.vess_code = b.code
             and   a.pcv_no is null
             and   a.vess_code is not null
             group by a.vess_code, b.name, 'V'
             union
             select a.vess_code code, b.name, sum(VALE_AMT*-1) amt, 'V' p_type
             from pys_contractor_payroll_dtl a, cms_vessels b
             where a.payroll_no = p_payroll_no
             and   a.vess_code = b.code
             and   a.pcv_no is null
             and   a.vess_code is not null
             group by a.vess_code, b.name, 'V')
             GROUP BY CODE, NAME, P_TYPE )
   loop
      select nvl(max(pcv_no),0)+1 into nPCVNo
      from   acc_pcv_hdr
      where  ofc_code = 'HO';

      nOPCVNo := nPCVNo;

      begin
         if i.amt > 0 then
            insert into acc_pcv_hdr (pcv_no, o_pcv_no, pcv_date, pcv_type, pcv_payee, pcv_status, created_by, dt_created )
            values (nPCVNo, nOPCVNo, trunc(sysdate), 'NON-VALE', i.name, 'NEW', user, sysdate);

            begin
               IF i.P_TYPE = 'V' THEN
                  INSERT INTO acc_pcv_dtl
                         ( pcv_no, item_no, acco_code, particulars, amt, debit, credit, created_by, dt_created )
                  VALUES ( nPCVNo, 1, vFinancial, 'PAYROLL FOR CONTRACTUALS FOR THE PERIOD ' || to_char(p_period_fr, 'MM/DD/RR') || ' TO ' || to_char(p_period_to, 'MM/DD/RR'), i.amt, i.amt, 0, user, sysdate);
               ELSE
                  INSERT INTO acc_pcv_dtl
                         ( pcv_no, item_no, acco_code, particulars, amt, debit, credit, created_by, dt_created )
                  VALUES ( nPCVNo, 1, vRepair, 'PAYROLL FOR CONTRACTUALS FOR THE PERIOD ' || to_char(p_period_fr, 'MM/DD/RR') || ' TO ' || to_char(p_period_to, 'MM/DD/RR'), i.amt, i.amt, 0, user, sysdate);
               END IF;

               INSERT INTO acc_pcv_dtl
                      ( pcv_no, item_no, acco_code, particulars, amt, debit, credit, created_by, dt_created )
               VALUES ( nPCVNo, 2, vPetty, 'PAYROLL FOR CONTRACTUALS FOR THE PERIOD ' || to_char(p_period_fr, 'MM/DD/RR') || ' TO ' || to_char(p_period_to, 'MM/DD/RR'), i.amt*-1, 0, i.amt, user, sysdate);

            exception
               when others then
                  raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_cont_payroll_entries ' || i.name || ' pcv_no:' || to_char(nPCVNo));
            end;
         else
            nPCVNo := 0;
         end if;

         IF i.P_TYPE = 'V' THEN
            update pys_contractual_payroll_dtl set pcv_no=nPCVNo
            where  payroll_no = p_payroll_no
            and    pcv_no is null
            and    vess_code = i.code;
            update pys_contractor_payroll_dtl set pcv_no=nPCVNo
            where  payroll_no = p_payroll_no
            and    pcv_no is null
            and    vess_code = i.code;
         ELSE
            update pys_contractual_payroll_dtl set pcv_no=nPCVNo
            where  payroll_no = p_payroll_no
            and    pcv_no is null
            and    contractor_code = i.code;
            update pys_contractor_payroll_dtl set pcv_no=nPCVNo
            where  payroll_no = p_payroll_no
            and    pcv_no is null
            and    contractor_code = i.code;
         END IF;
      exception
         when dup_val_on_index then null;
      end;

   end loop;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment ');
END sp_acc_cont_payroll_entries;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_JV_POSTING" (
    p_jvno in  number,
    p_date in  date,
    p_acco in  varchar2,
    p_part in  varchar2,
    p_debt in  number,
    p_crdt in  number
   )
   as
begin
   if SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH') = p_acco then
      insert into acc_petty_cash
             ( tx_date, ref_type, ref_code, ref_desc, amt, debit, credit, created_by, dt_created )
      values ( p_date, 'JV', lpad(to_char(p_jvno),6,'0'), p_part, p_crdt, p_debt, p_crdt, user, sysdate );
   end if;
end sp_acc_jv_posting;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_PAYROLL_ENTRIES" (
   p_payroll_no in number,
   p_period_fr in date,
   p_period_to in date
   ) is
   vSalaries_n_Allowances      Varchar2(30) := sf_get_acc_sysparam_charval ('SALARIES AND ALLOWANCES');    -- 900
   vSSS_Premiums_Deductions    Varchar2(30) := sf_get_acc_sysparam_charval ('SSS PREMIUM DEDUCTIONS');     -- 60007
   vSSS_Salary_Loan_Deductions Varchar2(30) := sf_get_acc_sysparam_charval ('SSS SALARY LOAN DEDUCTIONS'); -- 60006
   vPag_Ibig_Loan_Deductions   Varchar2(30) := sf_get_acc_sysparam_charval ('PAG-IBIG LOAN DEDUCTIONS');   -- 60010
   vPag_Ibig_Fund_Deductions   Varchar2(30) := sf_get_acc_sysparam_charval ('PAG-IBIG FUND DEDUCTIONS');   -- 60009
   vWithholding_Tax            Varchar2(30) := sf_get_acc_sysparam_charval ('WITHHOLDING TAX');            -- 60004
   vVale                       Varchar2(30) := sf_get_acc_sysparam_charval ('VALE');                       -- 60013
   vCash_in_Bank_MBTC          Varchar2(30) := sf_get_acc_sysparam_charval ('CASH IN BANK-MBTC');          -- 10005
   vCash_in_Bank_BDO           Varchar2(30) := sf_get_acc_sysparam_charval ('CASH IN BANK-BDO');           -- 10004
   vPhilhealth_Deductions      Varchar2(30) := sf_get_acc_sysparam_charval ('PHILHEALTH DEDUCTIONS');      -- 60008
   vCash_in_Bank               Varchar2(30);
   nCash_in_Bank               Number(12,2);
   nJV_No   Number;
   nItemNo  Number := 0;
   vRemarks Varchar2(128);
BEGIN

   for i in ( select decode(dept_code, 'FL', 'FL', decode(dept_code, 'MA-CREW', 'FL', 'OFC')) dept_code,
                     sum(amount) nSalaries_n_Allowances,
                     sum(sss_amt) nSSS_Premiums_Deductions,
                     sum(sss_loan) nSSS_Salary_Loan_Deductions,
                     sum(pag_ibig_amt) nPag_Ibig_Loan_Deductions,
                     sum(pag_ibig_loan) nPag_Ibig_Fund_Deductions,
                     sum(whtax) nWithholding_Tax,
                     sum(vale) nVale,
                     sum(medicare) nPhilhealth_Deductions
              from   pys_payroll_summary
              where  payroll_no = p_payroll_no
              group  by decode(dept_code, 'FL', 'FL', decode(dept_code, 'MA-CREW', 'FL', 'OFC')) )
   loop

      select nvl(max(jv_no),0)+1
      into   nJV_No
      from   acc_jv_hdr;

      -- create JV Header
      if i.dept_code = 'FL' then
         vRemarks := 'ATM PAYROLL FOR CREWS FOR THE  PERIOD OF ' || to_char(p_period_fr, 'fmMonth DD') || ' - ' || to_char(p_period_to, 'fmMonth DD, YYYY');
      else
         vRemarks := 'ATM PAYROLL FOR OFFICE STAFFS FOR THE  PERIOD OF ' || to_char(p_period_fr, 'fmMonth DD') || ' - ' || to_char(p_period_to, 'fmMonth DD, YYYY');
      end if;
      insert into acc_jv_hdr
             ( jv_no, jv_date, jv_status, particular, curr_code, prepared_by, dt_prepared, created_by, dt_created, checked_by, approved_by )
      values ( nJV_No, trunc(sysdate), 'NEW', vRemarks, 'PHP', sf_get_empl(user), sysdate, user, sysdate, 'M00020','T00011');

      nItemNo := 0;

      -- create JV Details
      if i.nSalaries_n_Allowances > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vSalaries_n_Allowances, 'OTH', null, null, i.nSalaries_n_Allowances, 0, user, sysdate, i.nSalaries_n_Allowances, 0);
      end if;

      if i.nSSS_Premiums_Deductions > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vSSS_Premiums_Deductions, 'OTH', null, null, 0, i.nSSS_Premiums_Deductions, user, sysdate, 0, i.nSSS_Premiums_Deductions);
      end if;

      if i.nSSS_Salary_Loan_Deductions > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vSSS_Salary_Loan_Deductions, 'OTH', null, null, 0, i.nSSS_Salary_Loan_Deductions, user, sysdate, 0, i.nSSS_Salary_Loan_Deductions);
      end if;

      if i.nPag_Ibig_Loan_Deductions > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vPag_Ibig_Loan_Deductions, 'OTH', null, null, 0, i.nPag_Ibig_Loan_Deductions, user, sysdate, 0, i.nPag_Ibig_Loan_Deductions);
      end if;

      if i.nPag_Ibig_Fund_Deductions > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vPag_Ibig_Fund_Deductions, 'OTH', null, null, 0, i.nPag_Ibig_Fund_Deductions, user, sysdate, 0, i.nPag_Ibig_Fund_Deductions);
      end if;

      if i.nWithholding_Tax > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vWithholding_Tax, 'OTH', null, null, 0, i.nWithholding_Tax, user, sysdate, 0, i.nWithholding_Tax);
      end if;

      if i.nVale <> 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vVale, 'OTH', null, null, 0, i.nVale, user, sysdate, 0, i.nVale);
      end if;

      if i.nPhilhealth_Deductions > 0 then
         nItemNo := nItemNo + 1;
         insert into acc_jv_dtl
                ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
         values ( nJV_No, nItemNo, vPhilhealth_Deductions, 'OTH', null, null, 0, i.nPhilhealth_Deductions, user, sysdate, 0, i.nPhilhealth_Deductions);
      end if;

      nCash_in_Bank := i.nSalaries_n_Allowances - (
                       i.nSSS_Premiums_Deductions +
                       i.nSSS_Salary_Loan_Deductions +
                       i.nPag_Ibig_Loan_Deductions +
                       i.nPag_Ibig_Fund_Deductions +
                       i.nWithholding_Tax +
                       i.nVale +
                       i.nPhilhealth_Deductions);

      if i.dept_code = 'FL' then
         vCash_in_Bank := vCash_in_Bank_MBTC;
      else
         vCash_in_Bank := vCash_in_Bank_BDO;
      end if;

      nItemNo := nItemNo + 1;
      insert into acc_jv_dtl
             ( jv_no, item_no, acco_code, ref_type, ref_code, ref_desc, debit, credit, created_by, dt_created, debit_php, credit_php )
      values ( nJV_No, nItemNo, vCash_in_Bank, 'OTH', null, null, 0, nCash_in_Bank, user, sysdate, 0, nCash_in_Bank);

   end loop;
   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_payroll_entries ');
END sp_acc_payroll_entries;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_PCR_RECEIPTS" (
   p_ofc in varchar2,
   p_pcr in number,
   p_date_fr in date,
   p_date_to in date
   ) is
   vPettyCashCode Varchar2(30);
BEGIN
   if p_ofc = 'HO' then
      vPettyCashCode := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
   else
      vPettyCashCode := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH GENSAN');
   end if;

   for i in (select a.jv_no, a.acco_code, a.ref_desc particulars, a.debit jv_amt, b.jv_date
             from   acc_jv_dtl a, acc_jv_hdr b
             where  a.jv_no = b.jv_no
             and    b.jv_status = 'APPROVED'
             and    a.debit > 0
             and    a.acco_code = vPettyCashCode
             and    a.pcr_no is null
             and    b.jv_date between p_date_fr and p_date_to)
   loop
      begin
         insert into acc_pcr_receipts
                ( pcr_no, ref_type, ref_code, ref_desc, tx_amt, tx_date, created_by, dt_created )
         values ( p_pcr, 'JV', i.jv_no, i.particulars, i.jv_amt, i.jv_date, user, sysdate );
      exception
         when dup_val_on_index then null;
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_receipts - jv_no:' || to_char(i.jv_no));
      end;

   end loop;

   for i in (select a.cv_no, a.acco_code, a.ref_desc particulars, a.debit cv_amt, b.cv_date
             from   acc_cv_dtl a, acc_cv_hdr b
             where  a.cv_no = b.cv_no
             and    b.cv_status = 'APPROVED'
             and    a.debit > 0
             and    a.acco_code = vPettyCashCode
             and    a.pcr_no is null
             and    b.cv_date between p_date_fr and p_date_to)
   loop
      begin
         insert into acc_pcr_receipts
                ( pcr_no, ref_type, ref_code, ref_desc, tx_amt, tx_date, created_by, dt_created )
         values ( p_pcr, 'CV', i.cv_no, i.particulars, i.cv_amt, i.cv_date, user, sysdate );
      exception
         when dup_val_on_index then null;
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_receipts - cv_no:' || to_char(i.cv_no));
      end;

   end loop;

   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pcr_jv ');
END sp_acc_pcr_receipts;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_PCR_REPLENISHMENT" (
   p_ofc in varchar2,
   p_pcr in number,
   p_date_fr in date,
   p_date_to in date
   ) is
   vSundry        Varchar2(16) := NULL;
   nCash_amt      Number(12,2) := 0;
   nMeals_amt     Number(12,2) := 0;
   nTranspo_amt   Number(12,2) := 0;
   nFuels_amt     Number(12,2) := 0;
   nFinancial_amt Number(12,2) := 0;
   nSupplies_amt  Number(12,2) := 0;
   nTaxes_amt     Number(12,2) := 0;
   nRepair_amt    Number(12,2) := 0;
   nVale_amt      Number(12,2) := 0;
   nAdvances_amt  Number(12,2) := 0;
   nMisc_amt      Number(12,2) := 0;
   nSundry_amt    Number(12,2) := 0;
   nSalaries_amt  Number(12,2) := 0;
   nSuspense_amt  Number(12,2) := 0;
   vPettyCashCode Varchar2(30);
   nO_PCR_No      Number;
BEGIN

   if p_ofc = 'HO' then
      vPettyCashCode := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
   else
      vPettyCashCode := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH GENSAN');
   end if;

   for i in (select a.pcv_no, b.o_pcv_no, a.item_no, a.acco_code, a.particulars,
                    decode(b.pcv_status,'CANCELLED',0, a.amt) amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_status
             from   acc_pcv_dtl a, acc_pcv_hdr b
             where  a.pcv_no = b.pcv_no
             and    b.pcv_status in ('NEW','CANCELLED')
             --and    a.amt > 0
             and    vPettyCashCode <> a.acco_code
             and    b.ofc_code = p_ofc
             and    b.pcv_date between p_date_fr and p_date_to)
   loop
      if i.pcv_status = 'NEW' then
          if i.acco_code = sf_get_acc_sysparam_charval ('CASH ACCOUNT CODE') then
             nCash_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('MEALS ACCOUNT CODE') then
             nMeals_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('TRANSPO ACCOUNT CODE') then
             nTranspo_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('FUELS ACCOUNT CODE') then
             nFuels_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('FINANCIAL ACCOUNT CODE') then
             nFinancial_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('SUPPLIES ACCOUNT CODE') then
             nSupplies_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('TAXES ACCOUNT CODE') then
             nTaxes_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('REPAIR ACCOUNT CODE') then
             nRepair_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('VALE ACCOUNT CODE') then
             nVale_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('ADVANCES ACCOUNT CODE') then
             nAdvances_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('MISC ACCOUNT CODE') then
             nMisc_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('SALARIES ACCOUNT CODE') then
             nSalaries_amt := i.amt;
          elsif i.acco_code = sf_get_acc_sysparam_charval ('SUSPENSE ACCOUNT CODE') then
             nSuspense_amt := i.amt;
          else
             vSundry     := i.acco_code;
             nSundry_amt := i.amt;
          end if;
      end if;

      begin
         insert into acc_pcr_dtl
                ( pcr_no, pcv_no, o_pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, cash_amt, meals_amt, transpo_amt,
                  fuels_amt, financial_amt, supplies_amt, taxes_amt, repair_amt, vale_amt, advances_amt, misc_amt, sundry, sundry_amt,
                  pcv_date, created_by, dt_created, suspense_amt, salaries_amt
                )
         values ( p_pcr, i.pcv_no, i.o_pcv_no, i.item_no, i.acco_code, i.empl_empl_id, i.dept_code, i.particulars, i.amt, nCash_amt, nMeals_amt, nTranspo_amt,
                  nFuels_amt, nFinancial_amt, nSupplies_amt, nTaxes_amt, nRepair_amt, nVale_amt, nAdvances_amt, nMisc_amt, vSundry, nSundry_amt,
                  i.pcv_date, user, sysdate, nSuspense_amt, nSalaries_amt
                );
      exception
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment ' || i.empl_empl_id || ' pcv_no:' || to_char(i.pcv_no));
      end;
      nCash_amt      := 0;
      nMeals_amt     := 0;
      nTranspo_amt   := 0;
      nFuels_amt     := 0;
      nFinancial_amt := 0;
      nSupplies_amt  := 0;
      nTaxes_amt     := 0;
      nRepair_amt    := 0;
      nVale_amt      := 0;
      nAdvances_amt  := 0;
      nMisc_amt      := 0;
      nSalaries_amt  := 0;
      nSuspense_amt  := 0;
      vSundry        := NULL;
      nSundry_amt    := 0;
   end loop;
   for j in (select pcv_no from acc_pcr_dtl where pcr_no = p_pcr and amt <> 0 group by pcv_no)
   loop
      update acc_pcv_hdr
      set    pcr_no = p_pcr, pcv_status = 'REPLENISHED'
      where  pcv_no = j.pcv_no;
   end loop;
   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment ');
END sp_acc_pcr_replenishment;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_PC_REPLENISHMENT" (
   p_pcr in number,
   p_date_fr in date,
   p_date_to in date
   ) is
   vSundry        Varchar2(16) := NULL;
   nCash_amt      Number(12,2) := 0;
   nMeals_amt     Number(12,2) := 0;
   nTranspo_amt   Number(12,2) := 0;
   nFuels_amt     Number(12,2) := 0;
   nFinancial_amt Number(12,2) := 0;
   nSupplies_amt  Number(12,2) := 0;
   nTaxes_amt     Number(12,2) := 0;
   nRepair_amt    Number(12,2) := 0;
   nVale_amt      Number(12,2) := 0;
   nAdvances_amt  Number(12,2) := 0;
   nMisc_amt      Number(12,2) := 0;
   nSundry_amt    Number(12,2) := 0;
BEGIN

   for i in (select a.pcv_no, a.item_no, a.acco_code, a.particulars, a.amt, a.empl_empl_id, a.dept_code, b.pcv_date
             from   acc_pcv_dtl a, acc_pcv_hdr b
             where  a.pcv_no = b.pcv_no
             and    b.pcv_status = 'POSTED'
             and    a.amt > 0
             and    b.pcv_date between p_date_fr and p_date_to)
   loop
      if i.acco_code = sf_get_acc_sysparam_charval ('CASH ACCOUNT CODE') then
         nCash_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('MEALS ACCOUNT CODE') then
         nMeals_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('TRANSPO ACCOUNT CODE') then
         nTranspo_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('FUELS ACCOUNT CODE') then
         nFuels_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('FINANCIAL ACCOUNT CODE') then
         nFinancial_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('SUPPLIES ACCOUNT CODE') then
         nSupplies_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('TAXES ACCOUNT CODE') then
         nTaxes_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('REPAIR ACCOUNT CODE') then
         nRepair_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('VALE ACCOUNT CODE') then
         nVale_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('ADVANCES ACCOUNT CODE') then
         nAdvances_amt := i.amt;
      elsif i.acco_code = sf_get_acc_sysparam_charval ('MISC ACCOUNT CODE') then
         nMisc_amt := i.amt;
      else
         vSundry     := i.acco_code;
         nSundry_amt := i.amt;
      end if;

      begin
         insert into acc_pcr_dtl
                ( pcr_no, pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, cash_amt, meals_amt, transpo_amt,
                  fuels_amt, financial_amt, supplies_amt, taxes_amt, repair_amt, vale_amt, advances_amt, misc_amt, sundry, sundry_amt,
                  pcv_date, created_by, dt_created
                )
         values ( p_pcr, i.pcv_no, i.item_no, i.acco_code, i.empl_empl_id, i.dept_code, i.particulars, i.amt, nCash_amt, nMeals_amt, nTranspo_amt,
                  nFuels_amt, nFinancial_amt, nSupplies_amt, nTaxes_amt, nRepair_amt, nVale_amt, nAdvances_amt, nMisc_amt, vSundry, nSundry_amt,
                  i.pcv_date, user, sysdate
                );
      exception
         when others then
            raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment ' || i.empl_empl_id || ' pcv_no:' || to_char(i.pcv_no));
      end;

      nCash_amt      := 0;
      nMeals_amt     := 0;
      nTranspo_amt   := 0;
      nFuels_amt     := 0;
      nFinancial_amt := 0;
      nSupplies_amt  := 0;
      nTaxes_amt     := 0;
      nRepair_amt    := 0;
      nVale_amt      := 0;
      nAdvances_amt  := 0;
      nMisc_amt      := 0;
      vSundry        := NULL;
      nSundry_amt    := 0;

   end loop;

   for j in (select pcv_no from acc_pcr_dtl where pcr_no = p_pcr group by pcv_no)
   loop
      update acc_pcv_hdr
      set    pcv_status = 'REPLENISHED'
      where  pcv_no = j.pcv_no;
   end loop;

   commit;
exception
   when others then
      raise_application_error (-20001, SQLERRM || ' ERROR - sp_acc_pc_replenishment ');
END sp_acc_pc_replenishment;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_PETTY_CASH_ENTRIES" (
      p_pcv_type in varchar2,
      p_pcv_no   in number,
      p_crf_type in varchar2,
      p_crf_no   in number,
      p_vat_inc  in varchar2,
      p_vat      in number,
      p_empl     in varchar2,
      p_dept     in varchar2
   ) as
   nCheckEWT    Number;
   nCheckVALE   Number;
   nCheckPetty  Number;
   vEWT_Code    Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('EWT');
   vVALE_Code    Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('VALE');
   vPetty_Code   Varchar2(32);
   vPetty_CodeH  Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
   vPetty_CodeG  Varchar2(32) := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH GENSAN');
   nVAT         Number(14,6) := 0;
   nVALE        Number(14,6) := 0;
   nTotalDebit  Number(14,6) := 0;
   nTotalCredit Number(14,6) := 0;
   nTotalVale   Number(14,6) := 0;
   nTotalPCVVale Number(14,6) := 0;
   nItem        Number := 0;
   dValeDate    Date;
   -- for Vale on Deduction table
   nSeqNo       Number;
   vOfcCode     Varchar2(20);
   vItemNo      Number;
BEGIN
   select ofc_code
   into   vOfcCode
   from   acc_pcv_hdr
   where  pcv_no = p_pcv_no;

   if vOfcCode = 'HO' then
       vPetty_Code := vPetty_CodeH;
   else
       vPetty_Code := vPetty_CodeG;
   end if;
if p_pcv_type = 'VALE' then
      SELECT pcv_date
      INTO   dValeDate
      FROM   acc_pcv_hdr
      WHERE  pcv_no = p_pcv_no;
      if dValeDate >= to_date('20090601', 'YYYYMMDD') then
         SELECT count(1)
         INTO   nCheckVALE
         FROM   acc_pcv_dtl
         WHERE  pcv_no = p_pcv_no
         AND    acco_code = vVALE_Code;
         select sum(debit)
         into   nTotalPCVVale
         from   acc_pcv_dtl a, acc_pcv_hdr b
         where  a.pcv_no = b.pcv_no
         and    b.crf_no = to_char(p_crf_no)
         and    b.crf_type = p_crf_type
         and    b.pcv_no <> p_pcv_no;
         if p_crf_type = 'RV' then
            SELECT nvl(approved_amt,0)-nvl(nTotalPCVVale,0)
            INTO   nVale
            FROM   CMS_REQUEST_VALE
            WHERE  tran_no = p_crf_no                      ;
         elsif p_crf_type = 'OP' then
            SELECT SUM (nvl(d.approved_amt,0)) - nvl(nTotalPCVVale,0) approved_amt
            into   nVale
            FROM   cms_op_vale_hdr v, cms_op_vale_dtl d
            WHERE  v.tran_no = d.tran_no
            and    v.tran_no = to_char(p_crf_no)
            and    d.approved_flag = 'Y';
         else
            raise_application_error (-20001, 'ERROR invalid CRF TYPE entry');
         end if;
         begin
            if nCheckVALE = 0 then
                  nItem := nItem + 1;
                  INSERT INTO acc_pcv_dtl
                         ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
                  VALUES ( p_pcv_no, nItem, vVALE_Code, p_empl, p_dept, 'Vale', nVale, nVale, 0, user, sysdate);
            else
               UPDATE acc_pcv_dtl
               SET    amt    = nVale,
                      credit = 0,
                      debit  = nVale
               WHERE  pcv_no = p_pcv_no
               AND    acco_code = vVALE_Code;
            end if;

            -- start: FOR VALE on DEDUCTION TABLE
            IF p_crf_type = 'OP' THEN
               select max(seq_no)
               into   nSeqNo
               from   pys_deductions;
               for i in (select empl_empl_id, (approved_amt-release_amt) approved_amt from cms_op_vale_dtl where tran_no = p_crf_no and (approved_amt-release_amt) > 0 and approved_flag = 'Y')
               loop
                  update pys_deductions
                  set    amt = i.approved_amt,
                         total_amt = i.approved_amt,
                         start_date = trunc(sysdate),
                         end_date = last_day(trunc(sysdate))
                  where  empl_empl_id = i.empl_empl_id
                  and    ref_type = 'PCV'
                  and    ref_code = to_char(p_pcv_no);
                  if sql%notfound then
                     begin
                        nSeqNo := nvl(nSeqNo,0) + 1;
                        insert into pys_deductions
                               ( seq_no, empl_empl_id, no_payday, amt, total_amt, frequency, dety_code, start_date, end_date, ref_type, ref_code, created_by, dt_created )
                        values ( nSeqNo, i.empl_empl_id, 1, i.approved_amt, i.approved_amt, 'MO', 'VALE', trunc(sysdate), last_day(trunc(sysdate)), 'PCV', to_char(p_pcv_no), user, sysdate);
                     exception
                        when dup_val_on_index then null;
                     end;
                  end if;
               end loop;
 delete from ACC_PCV_EMP_DTL where pcv_no = p_pcv_no;
               vItemNo := 0;
               for a in (select empl_empl_id, (approved_amt-release_amt) approved_amt from cms_op_vale_dtl where tran_no = to_char(p_crf_no) and (approved_amt-release_amt) > 0 and approved_flag = 'Y')
               loop
                  vItemNo := vItemNo + 1;
                  insert into acc_pcv_emp_dtl(pcv_no, item_no, empl_id, amount, created_by, dt_created)
                  values (p_pcv_no, vItemNo, a.empl_empl_id, a.approved_amt, user, sysdate);
               end loop;
            ELSE
               update pys_deductions
               set    amt = nVale,
                      total_amt = nVale,
                      start_date = trunc(sysdate),
                      end_date = last_day(trunc(sysdate))
               where  empl_empl_id = p_empl
               and    ref_type = 'PCV'
               and    ref_code = to_char(p_pcv_no);
               if sql%notfound then
                  begin
                     select max(seq_no) into nSeqNo
                     from   pys_deductions;
                     insert into pys_deductions
                            ( seq_no, empl_empl_id, no_payday, amt, total_amt, frequency, dety_code, start_date, end_date, ref_type, ref_code, created_by, dt_created )
                     values ( nvl(nSeqNo,0)+1, p_empl, 1, nVale, nVale, 'MO', 'VALE', trunc(sysdate), last_day(trunc(sysdate)), 'PCV', to_char(p_pcv_no), user, sysdate);
                  exception
                     when dup_val_on_index then null;
                  end;
               end if;
            END IF;
            -- end: FOR VALE on DEDUCTION TABLE

         exception
            when OTHERS then
               raise_application_error (-20001, 'ERROR on generating EWT entry 3: ' || SQLERRM);
         end;
         select sum(debit)
         into   nTotalVale
         from   acc_pcv_dtl a, acc_pcv_hdr b
         where  a.pcv_no = b.pcv_no
         and    b.crf_no = to_char(p_crf_no)
         and    b.crf_type = p_crf_type;
         if p_crf_type = 'RV' then
            UPDATE CMS_REQUEST_VALE
            SET    pcv_no = p_pcv_no,
                   pcv_bal_amt = nTotalVale
            WHERE  tran_no = to_char(p_crf_no);
         elsif p_crf_type = 'OP' then
            UPDATE CMS_OP_VALE_HDR
            SET    pcv_no = p_pcv_no,
                   pcv_bal_amt = nTotalVale
            WHERE  tran_no = to_char(p_crf_no);

            UPDATE CMS_OP_VALE_DTL
            SET    release_amt = approved_amt
            WHERE  tran_no = to_char(p_crf_no);

         end if;
      end if;

   end if;
   select sum(nvl(debit,0)), sum(nvl(credit,0)), count(1)
   into   nTotalDebit, nTotalCredit, nItem
   from   acc_pcv_dtl
   where  pcv_no = p_pcv_no
   and    acco_code <> vPetty_Code;
   dbms_output.put_line('VALE Complete');
   if nTotalDebit > 0 then
      -- Generate EWT Entry
      if (p_vat_inc = 'Y') or (nvl(p_vat,0) > 0) then
         if p_vat_inc = 'Y' then
            nVAT := nvl((nvl(p_vat,0)/100) * (nTotalDebit/sf_get_acc_ewt),0);
         else
            nVAT := nvl((nTotalDebit)*(nvl(p_vat,0)/100),0);
         end if;
         SELECT count(1)
         INTO   nCheckEWT
         FROM   acc_pcv_dtl
         WHERE  pcv_no = p_pcv_no
         AND    acco_code = vEWT_Code;
         begin
            if nCheckEWT = 0 then
                  nItem := nItem + 1;
                  INSERT INTO acc_pcv_dtl
                         ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
                  VALUES ( p_pcv_no, nItem, vEWT_Code, p_empl, p_dept, 'Expanded Withholding Tax', nVAT*-1, 0, nVAT, user, sysdate);
            else
               UPDATE acc_pcv_dtl
               SET    amt    = nVAT*-1,
                      credit = nVAT,
                      debit  = 0
               WHERE  pcv_no = p_pcv_no
               AND    acco_code = vEWT_Code;
            end if;
         exception
            when OTHERS then
               raise_application_error (-20001, 'ERROR on generating EWT entry 4: ' || SQLERRM);
         end;
      end if;
      -- Generate PETTY CASH Entry
      SELECT count(1)
      INTO   nCheckPetty
      FROM   acc_pcv_dtl
      WHERE  pcv_no = p_pcv_no
      AND    acco_code = vPetty_Code;
      begin
         if nCheckPetty = 0 then
               nItem := nItem + 1;
               dbms_output.put_line(nTotalDebit||' - '||nTotalCredit);
               INSERT INTO acc_pcv_dtl
                      ( pcv_no, item_no, acco_code, empl_empl_id, dept_code, particulars, amt, debit, credit, created_by, dt_created )
               VALUES ( p_pcv_no, nItem, vPetty_Code, p_empl, p_dept, 'Petty Cash', ((nTotalDebit-nTotalCredit)-nVAT)*-1, 0, ((nTotalDebit-nTotalCredit)-nVAT), user, sysdate);
         else
UPDATE acc_pcv_dtl
            SET    amt    = ((nTotalDebit-nTotalCredit)-nVAT)*-1,
                   credit = ((nTotalDebit-nTotalCredit)-nVAT),
                   debit  = 0
            WHERE  pcv_no = p_pcv_no
            AND    acco_code = vPetty_Code;
         end if;
      exception
         when OTHERS then
            raise_application_error (-20001, 'ERROR on generating PETTY CASH entry: ' || SQLERRM);
      end;
      commit;
   end if;
   commit;
END sp_acc_petty_cash_entries;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_POP_AP_SUM" (p_date_fr date, p_date_to date) as
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
   bNotFound       boolean;
begin
   delete from acc_ap_summary
   where  userid = user;
   delete from acc_ap_summary_sundry
   where  userid = user;
   commit;
   for a in ( select h.supp_code, h.ap_no, h.ap_date, s.payee_name ap_payee
              from   acc_ap_hdr h, acc_payees s
              where  h.ap_status <> 'CANCELLED'
              and    s.payee_code = h.ap_payee_code
              and    s.payee_type = h.ap_payee_type
              and    h.ap_date >= p_date_fr
              and    h.ap_date <= p_date_to
             )
   loop
      bNotFound := TRUE;
      for b in ( select d.acco_code, d.debit_php, d.credit_php
                 from   acc_ap_dtl d
                 where  d.ap_no = a.ap_no
                )
      loop
         bNotFound       := FALSE;
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
         if b.acco_code = v_ewt_code then
            v_ewt_amt := b.credit_php - b.debit_php;
         elsif b.acco_code = v_ap_code then
            v_ap_amt := b.credit_php - b.debit_php;
         elsif b.acco_code = v_matrl_code then
            v_matrl_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_repair_code then
            v_repair_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_nets_code then
            v_nets_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_fuels_code then
            v_fuels_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_lubri_code then
            v_lubri_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_comm_code then
            v_comm_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_security_code then
            v_security_amt := b.debit_php - b.credit_php;
         elsif b.acco_code = v_ofc_code then
            v_ofc_amt := b.debit_php - b.credit_php;
         else
            insert into acc_ap_summary_sundry(ap_no, sundry, credit, debit, userid, acco_code)
            values (a.ap_no, sf_acc_get_account_name(b.acco_code), b.credit_php, b.debit_php, user, b.acco_code );
         end if;
         insert into acc_ap_summary (ap_no, ap_date, supp_code, expanded_amt, ap_amt, matrl_amt, sec_amt,
                                     repair_amt, nets_amt, fuel_amt, lub_amt, comm_amt, ofc_amt, userid, payee)
         values (a.ap_no, a.ap_date, a.supp_code, v_ewt_amt, v_ap_amt, v_matrl_amt, v_security_amt,
                                     v_repair_amt, v_nets_amt, v_fuels_amt, v_lubri_amt, v_comm_amt, v_ofc_amt, user, a.ap_payee);
      end loop;
      if bNotFound then
         insert into acc_ap_summary (ap_no, ap_date, supp_code, expanded_amt, ap_amt, matrl_amt, sec_amt,
                                     repair_amt, nets_amt, fuel_amt, lub_amt, comm_amt, ofc_amt, userid, payee)
         values (a.ap_no, a.ap_date, a.supp_code, 0, 0, 0, 0,
                                     0, 0, 0, 0, 0, 0, user, a.ap_payee);
      end if;
   end loop;
   commit;
end;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_POP_CV_SUM" (p_date_fr date, p_date_to date) as
  v_pc_code         varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH');
  v_sal_code        varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('SALARIES ACCOUNT CODE');
  --v_matrl_code      varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('SUPPLIES ACCOUNT CODE');
  v_repair_code     varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('REPAIR ACCOUNT CODE');
  v_meal_code       varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('MEALS ACCOUNT CODE');
  v_financial_code  varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('FINANCIAL ACCOUNT CODE');
  v_adv_code        varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('ADVANCES ACCOUNT CODE');
  v_adv_marina_code varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('ADVANCES MARINA CODE');
  v_adv_pcg_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('ADVANCES PCG CODE');
  --v_transpo_code    varchar2(16) := SF_GET_ACC_SYSPARAM_CHARVAL('TRANSPO ACCOUNT CODE');
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
  v_payee_name      varchar2(512);
  v_check_no        varchar2(512);
begin
  delete from acc_cv_summary
  where  userid = user;
  delete from acc_cv_summary_sundry
  where  userid = user;
  commit;
  for a in
    (
    select d.acco_code, decode(h.cv_status,'CANCELLED',0, d.debit) debit_php,
                        decode(h.cv_status,'CANCELLED',0, d.credit) credit_php, --h.particular,
           h.cv_no, h.cv_date, cpa_payee || decode(h.cv_status,'CANCELLED',' *CANCELLED*') cpa_payee
    from   acc_cv_hdr h, acc_cv_dtl d
    where  h.cv_no = d.cv_no(+)
    --and    h.cv_status <> 'CANCELLED'
    and    h.cv_date >= p_date_fr
    and    h.cv_date <= p_date_to
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
    --elsif a.acco_code = v_transpo_code then
    --   v_transpo_amt := a.debit_php - a.credit_php;
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
       if v_sun_cre_amt is not null and v_sun_deb_amt is not null and a.acco_code is not null then
          insert into acc_cv_summary_sundry(cv_no, sundry, debit, credit, userid, acco_code)
          values (a.cv_no, sf_acc_get_account_name(a.acco_code), v_sun_deb_amt, v_sun_cre_amt, user, a.acco_code);
       end if;
    end if;
    insert into acc_cv_summary
       (cv_no, cv_date, particular, cash_bpi_amt, pc_amt, salaries_amt,
        meals_amt, financial_amt, repairs_amt, rep_amt, rep_marina_amt, rep_pcg_amt,
        transpo_amt, userid, payee_name)
    values
       (a.cv_no, a.cv_date, NULL, v_cash_bpi_amt, v_pc_amt, v_sal_amt,
        v_meal_amt, v_financial_amt, v_repair_amt, v_adv_amt, v_adv_marina_amt, v_adv_pcg_amt,
        v_transpo_amt, user, a.cpa_payee);
  end loop;
  for a in
    (
    select distinct cv_no from acc_cv_summary where userid = user
    )
  loop
    for b in
      (
      select prnbank_name, prncheck_no from acc_cv_check_dtl
      where  a.cv_no = cv_no
      )
    loop
      if v_check_no is null then
         v_check_no := b.prnbank_name||'#'||b.prncheck_no;
      else
         v_check_no := v_check_no||' / '||b.prnbank_name||'#'||b.prncheck_no;
      end if;
    end loop;
    update acc_cv_summary
    set    check_no = v_check_no
    where  cv_no = a.cv_no
    and    userid = user;
    v_check_no := null;
  end loop;
  commit;
end sp_acc_pop_cv_sum;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_POP_JV_SUM" (p_date_fr date, p_date_to date) as
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
    select d.acco_code, decode(h.jv_status,'CANCELLED',0,d.debit_php) debit_php,
                        decode(h.jv_status,'CANCELLED',0,d.credit_php) credit_php,
                        h.particular|| decode(h.jv_status,'CANCELLED',' *CANCELLED*') particular, h.jv_no, h.jv_date
    from   acc_jv_hdr h, acc_jv_dtl d
    where  h.jv_no = d.jv_no
    --and    h.jv_status <> 'CANCELLED'
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
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ACC_POST_APV" (
   p_ap_no    in number,               --:aphd.ap_no
   p_ref_ap_no in number,              --:aphd.ref_ap_no
   p_inv_type in varchar,              --:aphd.inv_type
   p_ap_discount in number,            --:aphd.ap_discount
   p_ap_disc_amt in number,            --:aphd.ap_disc_amt
   p_ap_date in date,                  --:aphd.ap_date
   p_ap_oth_disc_amt in number,        --:aphd.ap_oth_disc_amt
   p_vat_inc in number,                --:aphd.vat_inc
   p_vat in number,                    --:aphd.vat
   p_drhd_rr_curr in number,           --:apin.drhd_rr_curr
   p_total_amount in number,           --:apin.total_amount
   p_total_amount_net in number,       --:apin.total_amount_net
   p_total_fx_amount in number,        --:apin.total_fx_amount
   p_total_ret_amt in number,          --:apin.total_ret_amt
   p_total_ret_amt_php in number,      --:apin.total_ret_amt_php
   p_period_to in date,                --:aphd.period_to
   p_unused_adv in out number,         --:aphd.unused_adv
   p_unused_adv_php in out number,     --:aphd.unused_adv_php
   p_total_amount_net_fx in out number --:apin.total_amount_net_fx
  ) as
   vStatus Varchar2(16);
   nDummy  Number;
   nvat       number(16,2);
   nvatphp    number(16,2);
   namtphp    number(16,2);
   ndiscphp   number(16,2);
   namt       number(16,2);
   ndisc      number(16,2);
   ndisc_oth    number(16,2);
   ndisc_othphp number(16,2);
   nItem   Number := 1;
   vAP_Accnt Varchar2(16):= '60001';
   vMaterial Varchar2(16):= '903';
   vRepair   Varchar2(16):= '923';
   vDisc_Acct Varchar2(16):= '944.1';
   vVAT_Acct Varchar2(16):= '60005';
   vAdv_acct Varchar2(16):= '40004';
   vSus_acct Varchar2(16):= '10010';
   vcurr_code varchar2(16);
   vinvtype   varchar2(16);
   nSus       number(16,2);
   nSusphp    number(16,2);
   nAdv       number(16,2);
   nAdvphp    number(16,2);
   nSus1       number(16,2);
   nSusphp1    number(16,2);
   nAdv1       number(16,2);
   nAdvphp1    number(16,2);
   v_refap     char(1) := 'N';
   vCurr      varchar2(30);
   dCurrDate  date;
   nForex     Number;
   FUNCTION get_ap_curr RETURN VARCHAR is
   begin
     for a in (
       select pohd.currency
       from    acc_ap_inv_dtl apidt, inv_po_hdr pohd
       where   apidt.is_selected = 'Y'
       And     pohd.po_no = apidt.po_no
       and    (apidt.rs_no like 'M%' or apidt.rs_no like 'O%')
       and    apidt.ap_no = p_ap_no
       union all
       select  'PHP'
       from    acc_ap_inv_dtl apidt, inv_jo_hdr johd
       where   apidt.is_selected= 'Y'
       and     johd.jo_no = apidt.po_no
       and    (apidt.rs_no not like 'M%' and apidt.rs_no not like 'O%')
       and    apidt.ap_no = p_ap_no
       Union all
       select apidt.invoice_curr
       from   acc_ap_oth_dtl apidt
       where  apidt.is_selected= 'Y'
       and    apidt.ap_no = p_ap_no)
     loop
          return a.currency;
          exit;
     end loop;
     return 'PHP';
   exception
     when others then raise_application_error (-20001, 'No FX');
   end;
BEGIN

   insert into debug_log (source, ref_code, dt_created, ref_info )
   values ( 'SP_ACC_POST_APV',  p_ref_ap_no, sysdate,
                               'p_ref_ap_no=' || to_char(p_ref_ap_no) ||
                               ' p_inv_type = ' || to_char(p_inv_type ) ||
                               ' p_ap_discount = ' || to_char(p_ap_discount) ||
                               ' p_ap_disc_amt = ' || to_char(p_ap_disc_amt) ||
                               ' p_ap_date = ' || to_char(p_ap_date) ||
                               ' p_ap_oth_disc_amt = ' || to_char(p_ap_oth_disc_amt) ||
                               ' p_vat_inc = ' || to_char(p_vat_inc) ||
                               ' p_vat = ' || to_char(p_vat) ||
                               ' p_unused_adv = ' || to_char(p_unused_adv ) ||
                               ' p_unused_adv_php = ' || to_char(p_unused_adv_php ) ||
                               ' p_drhd_rr_curr = ' || to_char(p_drhd_rr_curr ) ||
                               ' p_total_amount = ' || to_char(p_total_amount ) ||
                               ' p_total_amount_net = ' || to_char(p_total_amount_net ) ||
                               ' p_total_amount_net_fx = ' || to_char(p_total_amount_net_fx ) ||
                               ' p_total_fx_amount = ' || to_char(p_total_fx_amount) ||
                               ' p_total_ret_amt = ' || to_char(p_total_ret_amt) ||
                               ' p_total_ret_amt_php= ' || to_char(p_total_ret_amt_php) ||
                               ' p_period_to = ' || to_char(p_period_to));
   commit;

   delete from acc_ap_dtl where ap_no = p_ap_no;

   if p_inv_type = 'PO' then
      vinvtype := 'PO';
   else
      vinvtype := 'JO';
   end if;

   vcurr_code := p_drhd_rr_curr;

   namtphp  := p_total_amount_net;
   ndiscphp := (p_total_amount_net*(p_ap_discount/100)) + (p_ap_disc_amt*sf_get_fx_rate(vcurr_code, p_ap_date));
   namt     := p_total_amount_net_fx;
   ndisc    := (p_total_amount_net_fx*(p_ap_discount/100)) + p_ap_disc_amt;

   -- Other discount
   ndisc_oth    := nvl(p_ap_oth_disc_amt,0);
   ndisc_othphp := nvl(p_ap_oth_disc_amt,0)*sf_get_fx_rate(vcurr_code, p_ap_date);

   insert into acc_ap_dtl (
      item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
      debit, credit, debit_php, credit_php, created_by, dt_created)
   values  (
      nitem, p_ap_no, decode(p_inv_type,'PO',vmaterial,vRepair), vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
      p_total_fx_amount-nvl(p_total_ret_amt,0), 0, p_total_amount-nvl(p_total_ret_amt_php,0), 0, user, sysdate);

   if p_ap_discount > 0 or p_ap_disc_amt > 0 then
      nitem := nitem + 1;
      insert into acc_ap_dtl
        (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
         debit, credit, debit_php, credit_php, created_by, dt_created)
      values (nitem, p_ap_no, vdisc_acct, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
         0, ndisc, 0, ndiscphp, user, sysdate);
   end if;

   if ndisc_oth > 0 then
      nitem := nitem + 1;
      insert into acc_ap_dtl
        (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
         debit, credit, debit_php, credit_php, created_by, dt_created)
      values (nitem, p_ap_no, vdisc_acct, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
         0, ndisc_oth, 0, ndisc_othphp, user, sysdate);
   end if;

   if p_vat_inc = 'Y' or p_vat > 0 then

      if p_vat_inc = 'Y' then
          nvat    := nvl((nvl(p_vat,0)/100) * (p_total_fx_amount / sf_get_acc_ewt),0);
          nvatphp := nvl((nvl(p_vat,0)/100) * (p_total_amount    / sf_get_acc_ewt),0);
      else
          nvat    := nvl((p_total_fx_amount) * (nvl(p_vat,0)/100),0);
          nvatphp := nvl((p_total_amount)    * (nvl(p_vat,0)/100),0);
      end if;
      /* -- commented out by rollie 20100118
         -- as per ms sonia, vat should look into total amount not net total amount
      if p_vat_inc = 'Y' then
          nvat    := nvl((nvl(p_vat,0)/100) * (p_total_amount_net_fx / sf_get_acc_ewt),0);
          nvatphp := nvl((nvl(p_vat,0)/100) * (p_total_amount_net    / sf_get_acc_ewt),0);
      else
          nvat    := nvl((p_total_amount_net_fx) * (nvl(p_vat,0)/100),0);
          nvatphp := nvl((p_total_amount_net)    * (nvl(p_vat,0)/100),0);
      end if;
      */
      nitem := nitem + 1;
      insert into acc_ap_dtl
         (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
          debit, credit, debit_php, credit_php, created_by, dt_created )
      values (nitem, p_ap_no, vvat_acct, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
          0, nvat, 0, nvatphp, user, sysdate  );

   end if;

   namt    := namt    - round((nvl(nvat,0)    + nvl(ndisc,0) + nvl(ndisc_oth,0)),2);
   namtphp := namtphp - round((nvl(nvatphp,0) + nvl(ndiscphp,0) + nvl(ndisc_othphp,0)),2);

   delete from acc_ap_oth_dtl where ap_no = p_ap_no;

   for a in
     (select is_selected, po_no from acc_ap_inv_dtl where ap_no = p_ap_no)
   loop
       if nvl(a.is_selected,'N') = 'N' then
          delete from acc_ap_advances
          where  ap_no    = p_ap_no
          and    po_no    = replace(a.po_no,'JO','')
          and    inv_type = p_inv_type;
       else
          sp_pop_inv_adv_payment(p_ap_no, p_inv_type, replace(a.po_no,'JO','') );
       end if;
   end loop;

   delete from acc_ap_advances acad
   where  ap_no    = p_ap_no
   and    inv_type = p_inv_type
   and    not exists (select 1 from acc_ap_inv_dtl apid, acc_ap_hdr aphd
                      where  apid.ap_no = acad.ap_no
                      and    aphd.ap_no = apid.ap_no
                      and    replace(apid.po_no,'JO','')    = acad.po_no
                      and    acad.inv_type = aphd.inv_type);

   for a in (
      SELECT rr_no from ACC_AP_INV_DTL
      where  ap_no = p_ap_no
      and    is_selected = 'N')
   loop
      if p_inv_type = 'PO' then
         update inv_dr_hdr
         set    ap_no = null
         where  dr_no = a.rr_no
         and    ap_no = p_ap_no;
      else
         update inv_jo_dr_hdr
         set    ap_no = null
         where  jo_dr_no = a.rr_no
         and    ap_no = p_ap_no;
      end if;
   end loop;

   -- clear PO and JO attachement to AP
   for i in (select rr_no, po_no from acc_ap_inv_dtl where ap_no = p_ap_no and is_selected = 'N') loop
       if substr(i.po_no,1,2) = 'JO' then
          -- clear JO
          update inv_jo_dr_hdr
          set    ap_no = null
          where  jo_dr_no = i.rr_no;
          --and    ap_no = p_ap_no;
      else
          -- clear PO
          update inv_dr_hdr
          set    ap_no = null
          where  dr_no = i.rr_no;
          --and    ap_no = p_ap_no;
      end if;
      if sql%found then
          -- delete
          delete from acc_ap_inv_dtl
          where  ap_no = p_ap_no
          and    rr_no = i.rr_no
          and    po_no = i.po_no
          and    is_selected = 'N';
      end if;
   end loop;

   -- get balance from previous ap transaction
   if p_ref_ap_no is not null then
        for a in ( select unused_adv_php, unused_adv
                   from   acc_ap_hdr
                   where  ap_no = p_ref_ap_no )
        loop
           --msg_alert('refap=Y namt=' || namt || ' namtphp=' || namtphp, 'I', FALSE);
              insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
           values (p_ap_no, 'AP', p_ref_ap_no, vinvtype, '0', a.unused_adv, user, sysdate, a.unused_adv_php);

           nitem := nitem + 1;
           insert into acc_ap_dtl
             (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
              debit, credit, debit_php, credit_php, created_by, dt_created )
           values
             (nitem, p_ap_no, vap_accnt, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
              0, greatest((trunc(namt,2) - trunc(a.unused_adv,2)),0), 0, greatest((trunc(namtphp,2) - trunc(a.unused_adv_php,2)),0), user, sysdate);
           v_refap := 'Y';
        end loop;
   end if;

   if v_refap = 'N' then
       nitem := nitem + 1;
      --msg_alert('refap=N namt=' || namt || ' namtphp=' || namtphp, 'I', FALSE);
      insert into acc_ap_dtl
       (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
        debit, credit, debit_php, credit_php, created_by, dt_created )
      values (nitem, p_ap_no, vap_accnt, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
        0, greatest(namt,0), 0, greatest(namtphp,0), user, sysdate  );
   end if;

   nSus    := 0;
   nSusphp := 0;
   nAdv    := 0;
   nAdvphp := 0;

   -- acc_ap_advances loop
   for a in ( select ref_type, ref_code, adv_amount, adv_amount_php, inv_type, po_no
              from   acc_ap_advances
              where  ap_no = p_ap_no )
   loop
       if a.ref_type = 'CV' then
           vCurr := get_ap_curr;
           for b1 in ( select cpdt.acco_code, cpdt.amount, cpdt.cpa_no
                       from   acc_cv_cpa_dtl cvcp, acc_cpa_dtl cpdt
                       where  cpdt.acco_code in (vSus_Acct, vAdv_Acct)
                       and    cvcp.cv_no    = a.ref_code
                       and    cpdt.cpa_no   = cvcp.cpa_no
                       and    cpdt.ref_type = a.inv_type
                       and    cpdt.ref_code = a.po_no )
           loop
              if b1.acco_code = vSus_acct then
                 nSus    := nSus    + b1.amount;
                 nSusphp := nSusphp + b1.amount;
              end if;
              if b1.acco_code = vAdv_acct then
                 if vCurr <> 'PHP' then
                    begin
                       select h.cv_date
                       into   dCurrDate
                       from   acc_cv_cpa_dtl a, acc_cv_hdr h
                       where  h.cv_no = a.cv_no
                       and    a.cpa_no = b1.cpa_no
                       and   rownum = 1;
                    exception
                       when others then
                          RAISE_APPLICATION_ERROR (-20001, 'Error getting CV date...');
                    end;
                    nForex := sf_get_fx_rate (vCurr, dCurrDate);
                    --msg_alert('vCurr=' || vCurr || ' nForex=' || nForex, 'I', FALSE);
                    nAdv    := nAdv    + (b1.amount/nForex);
                    --nAdv    := nAdv    + b1.amount;
                 else
                    nAdv    := nAdv    + b1.amount;
                 end if;
                 nAdvphp := nAdvphp + b1.amount;
              end if;
              --exit;
           end loop;
       end if;

       if a.ref_type = 'JV' then
            for b1 in
              (
              select acco_code, debit, debit_php from acc_jv_dtl
              where  acco_code in (vSus_Acct, vAdv_Acct)
              and    jv_no = a.ref_code
              and    ref_type = a.inv_type
              and    ref_code = a.po_no
              )
            loop
               if b1.acco_code = vSus_acct then
                  nSus    := nSus    + b1.debit;
                  nSusphp := nSusphp + b1.debit_php;
               end if;
               if b1.acco_code = vAdv_acct then
                  nAdv    := nAdv    + b1.debit;
                  nAdvphp := nAdvphp + b1.debit_php;
               end if;
               --exit;
            end loop;
       end if;

       if a.ref_type = 'AP' then
          nAdv    := nAdv    + a.adv_amount;
          nAdvphp := nAdvphp + a.adv_amount_php;
       end if;

       if a.ref_type = 'PCV' then
            for b1 in ( select amt
                        from   acc_pcv_dtl pcdt
                        where  pcdt.acco_code = vAdv_Acct
                        and    pcdt.pcv_no    = a.ref_code )
            loop
               nAdv    := nAdv    + a.adv_amount;
               nAdvphp := nAdvphp + a.adv_amount_php;
               exit;
            end loop;
       end if;

       if nAdv > 0 then
          update acc_ap_dtl
          set    credit = greatest(credit - nAdv,0),
                 credit_php= greatest(credit_php - nAdvPhp,0)
          where ap_no = p_ap_no
          and   acco_code = vap_accnt;
       end if;

   end loop;
   -- end acc_ap_advances loop

   --40004
   --10010
   nSus1    := nSus;
   nSusphp1 := nSusphp;
   nAdv1    := nAdv;
   nAdvphp1 := nAdvphp;
   if nSus <> 0 and nSusphp <> 0 then
      nitem := nitem + 1;
      if p_total_fx_amount < nSus then
          nSus1 := p_total_fx_amount;
      end if;
      if p_total_amount < nSusphp then
          nSusphp1 := p_total_amount;
      end if;

      insert into acc_ap_dtl
             (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
              debit, credit, debit_php, credit_php, created_by, dt_created )
      values (nitem, p_ap_no, vSus_acct, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
              0, nSus1, 0, nSusphp1, user, sysdate);
   end if;

   if nAdv <> 0 and nAdvphp <> 0 then
      nitem := nitem + 1;
      if (p_total_fx_amount - nvl(nSus,0)) < nAdv then
          nAdv1 := (p_total_fx_amount - nvl(nSus,0));
      end if;
      if (p_total_amount - nvl(nSusphp,0)) < nAdvphp then
          nAdvphp1 := (p_total_amount - nvl(nSusphp,0));
      end if;

      insert into acc_ap_dtl
             (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
              debit, credit, debit_php, credit_php, created_by, dt_created )
      values (nitem, p_ap_no, vAdv_acct, vinvtype, vinvtype ||'#' || to_char(p_period_to, 'MMYYYY'), vinvtype,
              0, nAdv1, 0, nAdvphp1, user, sysdate);
   end if;

   p_unused_adv     := greatest(((nAdv + nSus)-(p_total_fx_amount)),0);
   p_unused_adv_php := greatest(((nAdvphp + nSusphp)-(p_total_amount)),0);
   --msg_alert('p_unused_adv '||p_unused_adv|| ' '||nAdv ||' '|| nSus ||' '||p_total_fx_amount,'E',FALSE);
   --msg_alert('p_unused_adv_php '|| p_unused_adv_php||' '||nAdvphp ||' '|| nSusphp||' '||p_total_amount, 'E', FALSE);
   -- get unused advance payments from APV
   for a in (select unused_adv, unused_adv_php
             from   acc_ap_hdr
             where  ap_status = 'APPROVED'
             and    ap_no > p_ref_ap_no
             and    ap_no < p_ap_no
             and    unused_adv > 0
             and    unused_adv_php > 0
             order  by ap_no desc )
   loop
      p_unused_adv     := p_unused_adv + a.unused_adv;
      p_unused_adv_php := p_unused_adv_php + a.unused_adv_php;
      exit;
   end loop;
   --msg_alert('p_unused_adv '||p_unused_adv,'E',FALSE);
   --msg_alert('p_unused_adv_php '|| p_unused_adv_php, 'E', FALSE);
   commit;

END sp_acc_post_apv;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_ANNUAL_TAX" (
   p_pay_no in number,
   p_date_to in date ) is

   dStart         Date;
   dEnd           Date;
   dEnd2          Date;
   nAmtCola       Number(14,6) := 0;
   nDedAmt        Number(14,6) := 0;
   nWhtax         Number(14,6) := 0;
   nTaxExemption  Number(14,6) := 0;
   nTaxable13Mo   Number(14,6) := 0;
   nTaxableIncome Number(14,6) := 0;
   dEffDate       Date;
   nFixTax        Number(14,6) := 0;
   nBaseTax       Number(14,6) := 0;
   nTaxPct        Number(14,6) := 0;
   nSubjectTax    Number(14,6) := 0;
   nTax           Number(14,6) := 0;

begin
   dStart := to_date(to_char(p_date_to,'YYYY') || '0101', 'YYYYMMDD');
   dEnd   := to_date(to_char(p_date_to,'YYYY') || '1231', 'YYYYMMDD');
   dEnd2  := to_date(to_char(p_date_to,'YYYY') || '1130', 'YYYYMMDD');

   for i in (select emp.empl_id, emp.taty_code tax_type
             from   pms_employees emp, pys_payroll_summary pay, pys_payroll_hdr pad
             where  pay.empl_id = emp.empl_id
             and    pay.payroll_no = pad.payroll_no
             and    pad.period_to between dStart and dEnd
             group by emp.empl_id, emp.taty_code
             )
   loop
      for j in (select to_char(pad.period_to, 'YYYYMM') cur_mon_sort,
                       to_char(pad.period_to, 'fmMonth-YYYY') cur_mon,
                       pay.l_vess_code_a vessel_nm,
                       pay.dept_code dept_code,
                       pay.l_title_a title,
                       pay.l_oport oport,
                       pay.l_basic_rate_a basic_rate,
                       (decode(pay.dept_code,'FL', sum(pay.no_days)*(pay.l_basic_rate_a-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(pay.l_basic_rate_a-max(pay.cola_rate)), pay.l_basic_rate_a) +
                       decode(pay.dept_code,'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) ) amt_cola
                from   pys_payroll_summary pay, pys_payroll_hdr pad
                where  pay.payroll_no = pad.payroll_no
                and    pad.period_to between dStart and dEnd
                and    pay.empl_id = i.empl_id
                group by to_char(pad.period_to, 'YYYYMM'),
                       to_char(pad.period_to, 'fmMonth-YYYY'), pay.l_oport, pay.l_basic_rate_a, pay.l_vess_code_a,
                       pay.dept_code, pay.l_title_a
                order by to_char(pad.period_to, 'YYYYMM')
               )
      loop
         --if i.empl_id = 'C00013' then
         --  dbms_output.put_line('nAmtCola='|| to_char(nAmtCola));
         --end if;
         nAmtCola := nvl(nAmtCola,0) + nvl(j.amt_cola,0);
      end loop;

      for j in (select sum(pay.pag_ibig_amt) d_pagibig,
                       sum(pay.sss_amt) d_sss,
                       sum(pay.medicare) d_medicare,
                       sum(pay.whtax) d_whtax
                from   pys_payroll_summary pay, pys_payroll_hdr pahd
                where  pay.payroll_no = pahd.payroll_no
                and    pahd.period_to between dStart and dEnd
                and    pay.empl_id = i.empl_id
                )
      loop
         nDedAmt := nvl(nDedAmt,0) + (j.d_pagibig + j.d_sss + j.d_medicare);
      end loop;

      select sum(pay.whtax)
      into   nWhtax
      from   pys_payroll_summary pay
      where  pay.period_to between dStart and dEnd2
      and    pay.empl_id = i.empl_id;

      nTaxExemption  := sf_tax_exemption(dEnd, i.tax_type);
      nTaxable13Mo   := sf_get_taxable_13th_month(i.empl_id, dEnd);
      nTaxableIncome := (nAmtCola-nDedAmt) + nTaxable13Mo - nTaxExemption;

      if nTaxableIncome > 0 then
         begin
            select max(eff_date)
            into   dEffDate
            from   pys_tax_rates
            where  nTaxableIncome between salary_fr and salary_to
            and    eff_date <= dEnd;
         exception
            when no_data_found then
               raise_application_error(-20001, 'ERROR - Taxable income not in range. Actual income of ' || to_char(nTaxableIncome));
         end;

         begin
            select fix_tax, base_tax, over_pct
            into   nFixTax, nBaseTax, nTaxPct
            from   pys_tax_rates
            where  eff_date = dEffDate
            and    nTaxableIncome between salary_fr and salary_to;
         exception
            when no_data_found then
               raise_application_error(-20001, 'ERROR - Taxable income not in range. Actual income of ' || to_char(nTaxableIncome) || ', effective date:' || to_char(dEffDate));
         end;

         nSubjectTax    := nTaxableIncome - nBaseTax;
         nTax           := nSubjectTax * (nTaxPct/100);
         nTax           := nTax + nFixTax;

         if nTax > nWhtax then
            update pys_payroll_dtl
            set    amt = nTax - nWhtax, basic_rate=nTaxableIncome
            where  empl_empl_id = i.empl_id
            and    pahd_payroll_no = p_pay_no
            and    paty_code = 'WHTAX';

            for k in (select period_to, no_days
                      from   pys_payroll_summary
                      where  empl_id = i.empl_id
                      and    payroll_no = p_pay_no
                      order by whtax desc, no_days desc)
            loop
               update pys_payroll_summary
               set    net_amount = net_amount - (nTax - nWhtax),
                      whtax = (nTax - nWhtax)
               where  empl_id = i.empl_id
               and    payroll_no = p_pay_no
               and    period_to = k.period_to
               and    no_days = k.no_days
               and    rownum = 1;
               exit;
            end loop;
         --else
         --   delete pys_payroll_dtl
         --   where  empl_empl_id = i.empl_id
         --   and    pahd_payroll_no = p_pay_no
         --   and    paty_code = 'WHTAX';
         end if;
      --else
         --if i.empl_id = 'C00013' then
         --dbms_output.put_line ('check i.empl_id:' || to_char(i.empl_id) || ', nTaxableIncome:' || to_char(nvl(nTaxableIncome,0)) ||
         --                                                ', nAmtCola:' || to_char(nAmtCola) ||
         --                                                ', nDedAmt:' || to_char(nDedAmt) ||
         --                                                ', nTaxExemption:' || to_char(nTaxExemption)
         --                     );
         --end if;
      end if;

      -- reset variables
      nAmtCola       := 0;
      nDedAmt        := 0;
      nWhtax         := 0;
      nTaxExemption  := 0;
      nTaxable13Mo   := 0;
      nTaxableIncome := 0;
      dEffDate       := null;
      nFixTax        := 0;
      nBaseTax       := 0;
      nTaxPct        := 0;
      nSubjectTax    := 0;
      nTax           := 0;
   end loop;

   if p_pay_no = 20091231 then
        dbms_output.put_line('Update dup whtax');
        update PYS_PAYROLL_SUMMARY
        set    whtax = 0
        where  payroll_no = 20091231
        and    medicare = 0
        and    empl_id in (
                           select empl_id from PYS_PAYROLL_SUMMARY
                           where payroll_no = 20091231 having (count(1) > 1 and avg(whtax) > 0 )
                           group by empl_id );
        dbms_output.put_line('Update dup whtax record : '||sql%rowcount);
        dbms_output.put_line('Update dup net total');
        update PYS_PAYROLL_SUMMARY
        set    net_amount = ((amount + Ot_Amt + Cola_Amt) -
                          (pag_ibig_amt + pag_ibig_loan + sss_amt + sss_loan + medicare + whtax + vale))
        where  payroll_no = 20091231
        and    medicare = 0
        and    empl_id in (
                          select empl_id from PYS_PAYROLL_SUMMARY
                          where  payroll_no = 20091231 having (count(1) > 1 and avg(whtax) > 0 )
                          group by empl_id );
        dbms_output.put_line('Update dup net total : '||sql%rowcount);

   end if;
   commit;

end sp_annual_tax;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_APPROVED_CS" (
   p_cs_no in varchar2,
   p_prepared_by in varchar2,
   p_created_by in varchar2,
   p_dt_prepared in date,
   p_remarks in varchar2
) as
   vpo_no Varchar2(20);
   vtotalcosttmp Number(14,4):= 0;
   vtotalcost    Number(14,4):= 0;
   vsuppcode     Varchar2(30);
   vctr          Number := 0;
   vdesc         Varchar2(300);
begin

   begin
      -- insert into PO
      for i in (
                 select a.supp_code, a.rshd_rs_no, p_prepared_by prepared_by, max(a.currency) currency, max(a.terms) terms,
                        p_dt_prepared dt_prepared, 'FOR APPROVAL' status, p_created_by created_by
                 from   INV_CANVASS_DTL a, inv_reqslip_hdr c
                 where  a.cshd_cs_no = p_cs_no
                 and    a.rshd_rs_no = c.rs_no
                 group  by a.supp_code, a.rshd_rs_no
                 order  by a.supp_code asc
               )
      loop
         if i.supp_code is null then
            rollback;
            raise_application_error (-20001, 'Error in Approving Canvass.');
            exit;
         end if;

         -- create PO hdr
         select po_seq.nextval into vpo_no from dual;
         insert into inv_po_hdr
                (po_no, supp_code, rshd_rs_no, po_date, prepared_by, dt_prepared, status, currency, created_by, dt_created, terms, remarks)
         values (lpad(vpo_no,6,0), i.supp_code, i.rshd_rs_no, trunc(sysdate), i.prepared_by, sysdate, i.status, i.currency, i.created_by, sysdate, i.terms, p_remarks);

         for j in (
                    select a.currency, a.cate_code, a.itty_code, a.itgr_code, a.item_code, c.vess_code,
                           a.qty_approved, a.unit_cost, a.discount, a.uome_code, a.terms
                    from   INV_CANVASS_DTL a, inv_reqslip_hdr c
                    where  a.cshd_cs_no = p_cs_no
                    and    a.rshd_rs_no = c.rs_no
                    and    a.supp_code = i.supp_code
                  )
         loop
            --CGFK$QRY_CSDT_CSDT_ITEMS_FK(vdesc, a.item_code, a.cate_code, a.itty_code, a.itgr_code);
            vtotalcosttmp := nvl(j.unit_cost,0)*nvl(j.qty_approved,0);
            vtotalcost    := nvl(vtotalcosttmp,0) - (nvl(vtotalcosttmp,0)*nvl(j.discount,0)/100);

            -- populate PO dtl
            insert into inv_po_dtl
                   (pohd_po_no, rshd_rs_no, cate_code, itty_code, itgr_code, item_code, intended_for,
                    approved_qty, rs_qty, unit_cost, total_cost, discount, uome_code, supp_code,
                    created_by, dt_created, po_date, description)
            values
                   (lpad(vpo_no,6,0), i.rshd_rs_no, j.cate_code, j.itty_code, j.itgr_code, j.item_code, j.vess_code,
                    j.qty_approved, j.qty_approved, j.unit_cost, vtotalcost, j.discount, j.uome_code, i.supp_code,
                    user, sysdate, sysdate, vdesc);

            update inv_po_hdr
            set    po_amt = nvl(po_amt,0) + (NVL(j.unit_cost,0)*(j.qty_approved))*((100-NVL(j.discount,0))/100)
            where  po_no = lpad(vpo_no,6,0);

            update inv_reqslip_dtl
            set    pohd_po_no = lpad(vpo_no,6,0)
            where  item_code = j.item_code
            and    cate_code = j.cate_code
            and    itty_code = j.itty_code
            and    itgr_code = j.itgr_code
            and    uome_code = j.uome_code
            and    rshd_rs_no = i.rshd_rs_no;

            update inv_canvass_dtl
            set    pohd_po_no = lpad(vpo_no,6,0)
            where  cshd_cs_no = p_cs_no
            and    item_code  = j.item_code
            and    cate_code  = j.cate_code
            and    itty_code  = j.itty_code
            and    itgr_code  = j.itgr_code
            and    uome_code  = j.uome_code
            and    rshd_rs_no = i.rshd_rs_no;

            vtotalcosttmp := 0;
            vtotalcost    := 0;
            vsuppcode     := i.supp_code;
            vctr          := vctr + 1;
            vdesc         := null;
         end loop;
      end loop;
   exception
      when others then
         rollback;
         raise_application_error(-20001,'Error in Approving Canvass. Ora - '||SQLCODE||' '||SQLERRM);
   end;

end;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_CHECK_POST_MOVEMENT" (
  p_tranno   in varchar2,
  p_emplid   in varchar2,
  p_eff_dt   in date,
  p_eff_en   in date,
  p_fr_vess  in varchar2,
  p_fr_posi  in varchar2,
  p_fr_basic in number,
  p_to_vess  in varchar2,
  p_to_posi  in varchar2,
  p_to_basic in number,
  p_to_dept  in varchar2
  ) as
   vStatus Varchar2(16);
   vemmoStatus Varchar2(16);
   vsalfreq varchar2(16);
   vismanager varchar2(1);
BEGIN
    begin
      select status into vemmoStatus from PMS_EMPLOYEE_MOVEMENTS where tran_no = p_tranno;
   exception
      when no_data_found then
         dbms_output.put_line ('Please save Employee Movement first.');
         RETURN;
   end;

   if vemmoStatus <> 'APPROVED' then
      raise_application_error(-20001, 'Cannot post not yet Approved Employee Movement.');
   end if;

   begin
      select py_status into vStatus from PMS_EMPLOYEE_MOVEMENTS where tran_no = p_tranno;
   exception
      when no_data_found then
         dbms_output.put_line ('Please save Employee Movement first.');
         RETURN;
   end;
   if vStatus in ('POSTED', 'CANCELLED') then
      raise_application_error(-20001, 'Transaction already been ' || vStatus || ', changes are not allowed.');
   end if;

   -- get salary info
   begin
      for a in (
            select sal_freq, is_manager
            from   pys_employee_salary
            where  empl_empl_id = p_emplid
            order by eff_st_date desc)
      loop
            vsalfreq := a.sal_freq;
            vismanager := a.is_manager;
            exit;
      end loop;
      vsalfreq := nvl(vsalfreq,'SEMI-MO');
      vismanager := nvl(vismanager,'N');
   end;

   -- preliminary test
   -- crew
   if p_fr_vess is not null or p_to_vess is not null then
      if p_fr_vess is null then
         declare
            vembarked char(1);
            vrankcode varchar2(16);
            vbasicrate    number;
            vranktitle varchar2(64);
            vvessname varchar2(64);
            vdtembarked date;
            vvesscodec varchar2(64);
         begin
            vembarked := 'N';
            SELECT vess.name, voya.vess_code into vVessName, vVessCodeC
            FROM   cms_voyage_crew voyac, cms_voyages voya, cms_vessels vess
            WHERE  voyac.voya_voyage_date = voya.voyage_date
            AND    voyac.voya_vess_code = voya.vess_code
            and    voya.vess_code = vess.code
            AND    voyac.empl_empl_id = p_emplid
            and    voyac.dt_disembarked is null
            AND    voyage_end_date IS NULL;
            if vVessCodeC <> nvl(p_fr_vess, 'x') then
               raise_application_error(-20001, 'Employee ' || p_emplid || ' is currently in vessel '||vvessname || '.');
            end if;
         exception
            when no_data_found then null;
            when too_many_rows then
               raise_application_error(-20001, 'Employee ' || p_emplid || ' is currently in 2 or more vessels');
         end;
      else
         declare
            vBasicRate  number;
            vDtEmbarked date;
            nRetr       number;
         begin
            sp_is_valid_crew(p_emplid, p_fr_vess, p_fr_posi, vBasicRate, vDtEmbarked, nRetr);
            if nRetr = 0 then
               raise_application_error(-20001, 'Employee ' || p_emplid || ' is not the '||p_fr_posi||' in vessel '||p_fr_vess);
            end if;
            if nRetr = 2 then
               raise_application_error(-20001, 'Employee ' || p_emplid || ' is currently in 2 or more vessels');
            end if;
            if vBasicRate <> p_fr_basic then
                raise_application_error(-20001, 'Employee''s rate is not the same with position '||p_fr_posi||' in vessel '||p_fr_vess);
            end if;
            if vDtEmbarked > p_eff_dt then
                raise_application_error(-20001, 'Crew Date disembarked should be later than date embarked');
            end if;
         end;
      end if;
   end if;
   -- end prelimanary test

   -- posting
   -- crew
   if p_fr_vess is not null or p_to_vess is not null then
      if p_fr_vess is not null then
         --dbms_output.put_line ('Crew From');
         declare
            vdisembark char(1);
            vembark    char(1);
            vfrrankcode  varchar2(16);
            vfrranktitle  varchar2(64);
            vtorankcode  varchar2(16);
            vtoranktitle  varchar2(64);
         begin
            begin
               select rank.code, rank.title into vfrrankcode, vfrranktitle
               from   pms_ranks rank, pms_positions posi
               where  posi.rank_code = rank.code
               and    posi.code = p_fr_posi
               and    rownum = 1;
            exception
               when no_data_found then
                  raise_application_error(-20001, ' From Position Name does not exist.');
            end;

            -- insert into audit log
            insert into pms_empl_move_log (MODULE, TRAN_NO, EMPL_ID, VESS_CODE, POSI_CODE, BASIC_RATE, DT_DISEMBARKED, DT_EMBARKED, STATUS, PY_STATUS, CREATED, DT_CREATED)
            select 'PYST120', p_tranno, cvc.empl_empl_id, cvc.voya_vess_code, p_fr_posi, cvc.basic_rate, (p_eff_dt-DECODE(p_to_vess,NULL,0,1)), cvc.dt_embarked, 'APPROVED', 'POSTED', user, sysdate
            from   cms_voyage_crew cvc
            where  cvc.voya_vess_code = p_fr_vess
            and    cvc.empl_empl_id   = p_emplid
            and    cvc.voya_voyage_date <= p_eff_dt
            and    cvc.rank_code      = vfrrankcode
            and    cvc.basic_rate     = p_fr_basic
            and    cvc.dt_disembarked is null
            and    exists (select    1 from cms_voyages voya
                           where   voya.vess_code = p_fr_vess
                           and     voya.voyage_date = cvc.voya_voyage_date
                           and     voya.vess_code = cvc.voya_vess_code
                           and     voya.voyage_end_date is null);

            update cms_voyage_crew cvc
            set    cvc.dt_disembarked = (p_eff_dt-DECODE(p_to_vess,NULL,0,1)),
                   cvc.tran_no_disembarked = (p_tranno)
            where  cvc.voya_vess_code = p_fr_vess
            and    cvc.empl_empl_id   = p_emplid
            and    cvc.voya_voyage_date <= p_eff_dt
            and    cvc.rank_code      = vfrrankcode
            and    cvc.basic_rate     = p_fr_basic
            and    cvc.dt_disembarked is null
            and    exists (select    1 from cms_voyages voya
                           where   voya.vess_code = p_fr_vess
                           and     voya.voyage_date = cvc.voya_voyage_date
                           and     voya.vess_code = cvc.voya_vess_code
                           and     voya.voyage_end_date is null);
         end;
      end if;

      if p_to_vess is not null then
         --dbms_output.put_line ('Crew To');
         declare
            vdisembark char(1);
            vembark    char(1);
            vfrrankcode  varchar2(16);
            vfrranktitle  varchar2(64);
            vtorankcode  varchar2(16);
            vtoranktitle  varchar2(64);
            vvoyage_dt date;
            vvoyage_end_date date;
            vseq       number;
         begin
            begin
               select rank.code, rank.title into vtorankcode, vtoranktitle
               from   pms_ranks rank, pms_positions posi
               where  posi.rank_code = rank.code
               and    posi.code = p_to_posi
               and    rownum = 1;
            exception
               when no_data_found then
                  raise_application_error(-20001, ' To Position Name does not exist.');
            end;

            begin
               select voyage_date, voyage_end_date
               into   vvoyage_dt, vvoyage_end_date
               from   cms_voyages
               where  vess_code = p_to_vess
               and    trunc(p_eff_dt) between voyage_date and nvl(voyage_end_date,to_date('20990101','YYYYMMDD'))
               and    voyage_status = 'OP';
            exception
               when no_data_found then
                  rollback;
                  raise_application_error(-20001, 'No Open schedule voyage for vessel '||initcap(p_to_vess));
                  return;
            end;

            if vvoyage_dt is null then
               rollback;
               raise_application_error(-20001, 'No Open schedule voyage for vessel '||initcap(p_to_vess));
               return;
            end if;

            begin
               select max(cvc.seq_no)+1 into vseq
               from   cms_voyage_crew cvc--, cms_voyages voya
               where  cvc.voya_vess_code = p_to_vess
               and    cvc.voya_voyage_date = vvoyage_dt;
               --and    cvc.voya_voyage_date <= p_eff_dt
               --and    cvc.voya_vess_code = voya.vess_code
               --and    cvc.voya_voyage_date = voya.voyage_date
               --and    voya.voyage_end_date is null
               --and    exists (select    1 from cms_voyages voya
               --               where   voya.vess_code = p_to_vess
               --               and     voya.voyage_date = cvc.voya_voyage_date
               --               and     voya.vess_code = cvc.voya_vess_code
               --               and     voya.voyage_end_date is null);
            exception
               when no_data_found then
                  rollback;
                  raise_application_error(-20001, 'No Open schedule voyage for vessel '||initcap(p_to_vess));
                  return;
            end;

            if vseq is null then
               vseq := 1;
            end if;

            begin
               insert into pms_empl_move_log (MODULE, TRAN_NO, EMPL_ID, VESS_CODE, POSI_CODE, BASIC_RATE, DT_DISEMBARKED, DT_EMBARKED, STATUS, PY_STATUS, CREATED, DT_CREATED)
               values ('PYST120',p_tranno, p_emplid, p_to_vess, p_to_posi, p_to_basic, p_eff_en, p_eff_dt, 'APPROVED', 'POSTED', user, sysdate);
               --pause;
               insert into pys_employee_salary
                      (EMPL_EMPL_ID, EFF_ST_DATE, POSI_CODE, DEPT_CODE, BASIC_RATE, CREATED_BY, DT_CREATED,
                       BASIC_RATE_G, SAL_FREQ, IS_MANAGER)
               values (p_emplid, p_eff_dt, p_to_posi, p_to_dept, p_to_basic, SF_GET_EMPL(user), sysdate,
                       p_to_basic*decode(vsalfreq,'MONTHLY',30,1), vsalfreq, vismanager);
               --pause;
               if vvoyage_end_date is not null then
                  dbms_output.put_line ('Voyage for Vessel '||p_to_vess||' had already been ended on '||to_char(vvoyage_end_date,'Month DD, YYYY'));
                  insert into cms_voyage_crew(voya_vess_code, voya_voyage_date, empl_empl_id,
                          created_by, dt_created, rank_code, title,
                          seq_no, dt_embarked, dt_disembarked, passenger,
                          basic_rate, basic_rate_g,  tran_no_embarked, tran_no_disembarked)
                  values (p_to_vess,vvoyage_dt, p_emplid,
                          user, sysdate, vtorankcode, vtoranktitle,
                          vseq, p_eff_dt, vvoyage_end_date, 'N',
                          p_to_basic, p_to_basic, p_tranno, p_tranno);
               else
                  insert into cms_voyage_crew(voya_vess_code, voya_voyage_date, empl_empl_id,
                          created_by, dt_created, rank_code, title,
                          seq_no, dt_embarked, dt_disembarked, passenger,
                          basic_rate, basic_rate_g,  tran_no_embarked)
                  values (p_to_vess,vvoyage_dt, p_emplid,
                          user, sysdate, vtorankcode, vtoranktitle,
                            vseq, p_eff_dt, p_eff_en, 'N',
                            p_to_basic, p_to_basic, p_tranno);
               end if;
            end;
         end;
      end if;
   end if;


END;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_CHK_BEGBAL_NEGATIVE_STOCKS" as
  nCnt Number;
begin
  for i in (select *
            from  inv_stocks a
            where tran_type='ISS' and dr_ref_no is not null and dr_ref_type='DR'
            and   not exists (select 1 from inv_stocks b
            where b.tran_type='DR' and b.ref_no = a.dr_ref_no and b.item_code = a.item_code and b.uome_code=a.uome_code)
           )
  loop
     select count(1) into nCnt from inv_stocks_history
     where  item_code = i.item_code
     and    uome_code = i.uome_code
     and    tran_type = 'DR'
     and    ref_no = i.dr_ref_no;

     if nCnt = 0 then
        insert into inv_stocks_history
        select * from inv_stocks
        where  item_code = i.item_code
        and    uome_code = i.uome_code
        and    tran_type = i.tran_type
        and    ref_no = i.ref_no;

        delete from inv_stocks
        where item_code = i.item_code
        and    uome_code = i.uome_code
        and    tran_type = i.tran_type
        and    ref_no = i.ref_no;
        commit;
     else
        insert into inv_stocks
        select * from inv_stocks_history
        where  item_code = i.item_code
        and    uome_code = i.uome_code
        and    tran_type = 'DR'
        and    ref_no = i.dr_ref_no;

        delete from inv_stocks_history
        where item_code = i.item_code
        and    uome_code = i.uome_code
        and    tran_type = 'DR'
        and    ref_no = i.dr_ref_no;
        commit;
     end if;
  end loop;
end sp_chk_begbal_negative_stocks;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_CMS_POP_SHOOTHOME_DTL"
  (  p_sh_no varchar2 ) is
begin
   delete from cms_shoothome_dtl where shhd_sh_no = p_sh_no;

   insert into cms_shoothome_dtl
          (shhd_sh_no, tyfi_fish, fize_code, tot_catch, created_by, dt_created)
   select shhd_sh_no, tyfi_fish, fize_code, sum(tot_catch), user, sysdate
   from   cms_shoothome_catch_dtl cscd, cms_catches_dr_dtls cadt
   where  shhd_sh_no = p_sh_no
   and    delivered_qty > 0
   and    cscd.tx_no = cadt.cadr_tx_id
   group by shhd_sh_no, tyfi_fish, fize_code;

   commit;
end sp_cms_pop_shoothome_dtl;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_ATTENDANCE"
(
   p_type    in  varchar2,
   p_empl_id in  varchar2,
   p_date_fr in  date,
   p_date_to in  date,
   p_numday  out number,
   p_overtm  out number,
   p_regsun  out number,
   p_reghol  out number,
   p_holsun  out number,
   p_cola    out number

) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_period_fr in date, p_period_to in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date between p_period_fr and p_period_to
   order  by att_date;


   nNumHrs  Number := 0;
   nOvertm  Number := 0;
   nRegHol  Number := 0;
   nHolSun  Number := 0;
   nRegSun  Number := 0;
   nCOLA    Number := 0;
   nUpTO    Number := 0;
   bHolSun  Boolean;
   nDay     Number :=0;
   dDate    Date := p_date_fr;
   dTxDate  Date;
   dStart   Date;
   dEnd     Date;
   nTmpHrs  Number := 0;
   nDeduct  Number := 0;
   nAssume  Number := 0;
begin

   if p_type = 'FLT' then

      nUpTo := (p_date_to-p_date_fr)+1;

      dDate := p_date_fr;
      for i in 1..nUpTo loop
         nDay    := nDay + 1;
         dDate := dDate + (nDay-1);
         nNumHrs := nNumHrs + 8;
         nCOLA := nCOLA + 1;
         if sf_is_holiday (dDate) = 1 then
            if sf_is_sunday(dDate) = 1 then
              -- nHolSun := nRegSun + 8;
                nHolSun := nHolSun + 8;
            else
               nRegHol := nRegHol + 8;
            end if;
         else
            if sf_is_sunday(dDate) = 1 then
               nRegSun := nRegSun + 8;
            --else
            --   nNumHrs := nNumHrs + 8;
            end if;
         end if;
      end loop;

   else

      -- set up cutoff date
      if to_char(p_date_fr, 'DD') = '01' then
         dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      else
         dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '11', 'YYYYMMDD');
      end if;

      if to_char(p_date_to, 'DD') = '15' then
         dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      else
         dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      end if;

      for j in atre ( p_empl_id, dStart, dEnd ) loop

         nDay  := nDay + 1;
         dDate := j.tx_date;
         if sf_is_holiday (dDate) = 1 then
            if sf_is_sunday (dDate) = 1 then
               nHolSun := nRegSun + j.num_hours + j.ot_hours;
               if j.num_hours >= 6  then
                  nCOLA := nCOLA + 1;
               end if;
            else
               nRegHol := nRegHol + j.num_hours + j.ot_hours;
               if j.num_hours >= 4  then
                  nCOLA := nCOLA + 1;
               end if;
            end if;

         else

            if sf_is_sunday (dDate) = 1 then
               nRegSun := nRegSun + j.num_hours + j.ot_hours;
               if j.num_hours >= 4  then
                  nCOLA := nCOLA + 1;
               end if;
            else
               if to_char(dDate, 'fmMonth') = to_char(p_date_to, 'fmMonth') then
                  nNumHrs  := nNumHrs + j.num_hours;
                  nCOLA := nCOLA + 1;
               end if;
               -- Overtime
               nOvertm := nOvertm + j.ot_hours;
            end if;

         end if;

      end loop;

      -- ADD from Cutoff date to End of Month
      nUpTo   := (p_date_to-dEnd);
      nAssume := 0;
      for i in 1..nUpTo loop
         dDate := dEnd + i;
         if sf_is_sunday (dDate) = 0 then
            nAssume := nAssume + 8;
            nCOLA := nCOLA + 1;
         end if;
         dbms_output.put_line ('check date: ' || to_char(dDate) || ', ' || to_char(nAssume));
      end loop;
      -- end Cutoff date

      -- LESS from previous Cutoff date to End of previous Month
      nUpTo   := (p_date_fr-dStart);
      nTmpHrs := 0;
      nDeduct := 0;
      for i in 1..nUpTo loop
         dDate := dStart + (i-1);
         -- check if not SUNDAY
         if (sf_is_sunday (dDate) = 0) and (sf_is_holiday (dDate) = 0) then
             begin
               select num_hours
               into   nTmpHrs
               from   pms_attendance_records
               where  empl_empl_id = p_empl_id
               and    att_date = dDate;
            exception
               when no_data_found then
                  nTmpHrs := 0;
                  nCOLA := nCOLA - 1;
            end;
            if nTmpHrs < 8 then
               nDeduct := nDeduct + (8-nTmpHrs);
            end if;
         end if;
      end loop;
      -- end Cutoff date

   end if; -- end of OFC/FLT

   p_numday  := ((nNumHrs+nAssume)-nDeduct)/8;
   p_cola    := nCOLA;
   if p_type = 'FLT' then
      p_overtm  := nOvertm/8;
      p_regsun  := nRegSun/8;
      p_reghol  := nRegHol/8;
      p_holsun  := nHolSun/8;
   else
      p_overtm  := nOvertm;
      p_regsun  := nRegSun;
      p_reghol  := nRegHol;
      p_holsun  := nHolSun;
   end if;

end sp_count_attendance;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_FLT_ATTENDANCE"
(
   p_empl_id    IN  VARCHAR2,
   p_payno      IN  NUMBER,
   p_year       IN  VARCHAR2,
   p_mon        IN  VARCHAR2,
   p_date_fr    IN  DATE,
   p_date_to    IN  DATE,
   p_Sunday_RF  IN  NUMBER,
   p_Holiday_RF IN  NUMBER,
   p_HolSun_RF  IN  NUMBER,
   p_sal_freq   IN  VARCHAR2,
   p_seq_no     IN  NUMBER,
   p_dEmplID    IN  VARCHAR2,
   p_latestvess  OUT VARCHAR2,
   p_latesttitle OUT VARCHAR2,
   p_o_seq_no   OUT NUMBER

) IS

   dEmplID      VARCHAR2(16) := p_dEmplID;
   nSalaryR     NUMBER(8,2)  := 0;
   nASalaryR     NUMBER(8,2)  := 0;
   nSeqNo       NUMBER;
   dPeriodMo    DATE;
   dPeriodFr    DATE;
   dPeriodTo    DATE;
   vLatestVess  VARCHAR2(32);
   vLatestTitle VARCHAR2(60);
   vLatestRate  NUMBER(10,3) := 0;
   nDays        NUMBER(10,5) := 0;
   nADays        NUMBER(10,5) := 0;
   bIsEndOfMonth BOOLEAN;

BEGIN

   nSeqNo := p_seq_no;

   -- set cutoff date
   IF TO_CHAR(p_date_fr, 'DD') = '01' THEN
      dPeriodFr := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dPeriodTo := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   ELSE
      dPeriodMo := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '01', 'YYYYMMDD'); -- for overtimes
      dPeriodFr := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dPeriodTo := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   END IF;

   -- get latest vessel
   FOR i IN ( SELECT vess_code, title, basic_rate
              FROM   pys_payroll_dtl_log
              WHERE  empl_empl_id = p_empl_id
              AND    pay_date BETWEEN p_date_fr AND p_date_to
              ORDER  BY pay_date DESC
            )
   LOOP
      vLatestVess  := i.vess_code;
      vLatestTitle := i.title;
      vLatestRate  := i.basic_rate;
      EXIT;
   END LOOP;
   IF vLatestVess IS NULL THEN
      -- get latest vessel
      FOR i IN ( SELECT vess_code, title, basic_rate
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 ORDER  BY pay_date DESC
               )
      LOOP
         vLatestVess  := i.vess_code;
         vLatestTitle := i.title;
         vLatestRate  := i.basic_rate;
         EXIT;
      END LOOP;
   END IF;

   -- set latest vess
   UPDATE pys_payroll_dtl_log
   SET    latest_vess = vLatestVess
   WHERE  empl_empl_id = p_empl_id
   AND    pay_date BETWEEN p_date_fr AND p_date_to;


   -- regular days
   FOR j IN ( SELECT posi_code,
                     title,
                     basic_rate,
                     vess_code,
                     sal_freq,
                     MIN(pay_date)               dStart,
                     MAX(pay_date)               dEnd,
                     SUM(nDays)                  nNumday,
                     SUM(AMT)                    nSalaryR,
                     SUM(COLA_PAY)               nCola
              FROM   pys_payroll_dtl_log
              WHERE  empl_empl_id = p_empl_id
              AND    pay_date BETWEEN p_date_fr AND p_date_to
              GROUP  BY  posi_code, title, basic_rate, vess_code, sal_freq
             )
   LOOP

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: j.nNumDay=' || TO_CHAR(j.nNumDay) || ',j.vess_code=' || j.vess_code ||
                               ',j.dStart=' || TO_CHAR(j.dStart) || ',j.dEnd=' || TO_CHAR(j.dEnd) );
      END IF;

      IF j.sal_freq = 'MONTHLY' AND bIsEndOfMonth AND TO_CHAR(j.dEnd,'DD') >= '28' THEN
         IF TO_CHAR(j.dEnd,'DD') = '31' THEN
            nDays    := j.nNumday  - 1;
            nSalaryR := j.nSalaryR - j.basic_rate;
         ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
            nDays    := j.nNumday  + (30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')));
            nSalaryR := j.nSalaryR + (j.basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
         ELSE
            nDays    := j.nNumday;
            nSalaryR := j.nSalaryR;
         END IF;
      ELSE
         nDays    := j.nNumday;
         nSalaryR := j.nSalaryR;
      END IF;

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      INSERT INTO pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
      VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nSalaryR, nDays, j.basic_rate, nSalaryR, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

      IF j.nCola > 0 THEN
         nSeqNo := nSeqNo + 1;
         INSERT INTO pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
         VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', (j.nCola/j.nNumday)*nDays, nDays, (j.nCola/j.nNumday), j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
      END IF;

   END LOOP;

   IF dEmplID = p_empl_id THEN
      DBMS_OUTPUT.PUT_LINE ('check: before ''if bIsEndOfMonth then'' ');
   END IF;

   IF bIsEndOfMonth THEN

      -- sundays and holidays
      FOR j IN ( SELECT posi_code,
                        NVL(a_title,title) title,
                        DECODE(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE) basic_rate,
                        vess_code,
                        MIN(pay_date)               dStart,
                        MAX(pay_date)               dEnd,
                        SUM(DECODE(SU_PAY,0,A_SU_PAY,SU_PAY))   nSuDays,
                        SUM(DECODE(SU_PAY,0,A_SU_PAY,SU_PAY)*DECODE(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nSuPay,
                        SUM(DECODE(HO_PAY,0,A_HO_PAY,HO_PAY))   nHoDays,
                        SUM(DECODE(HO_PAY,0,A_HO_PAY,HO_PAY)*DECODE(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nHoPay,
                        SUM(DECODE(HS_PAY,0,A_HS_PAY,HS_PAY))   nHSDays,
                        SUM(DECODE(HS_PAY,0,A_HS_PAY,HS_PAY)*DECODE(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nHSPay
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 AND    pay_date BETWEEN dPeriodMo AND p_date_to          -- 16 to eod
                 GROUP  BY  posi_code, NVL(a_title,title), DECODE(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE), vess_code
                )
      LOOP

         IF ( j.nSuPay+j.nHoPay+j.nHSPay ) > 0 THEN
            -- check if there is header...
            FOR k IN (SELECT pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, posi_code, title, basic_rate, vess_code, dept_code, sal_freq, latest_vess
                      FROM   pys_payroll_dtl
                      WHERE  empl_empl_id = p_empl_id
                      AND    j.dEnd BETWEEN period_fr AND period_to
                      AND    paty_code LIKE 'REG%'
                      AND    pahd_payroll_no <= p_payno
                      ORDER  BY period_to DESC)
            LOOP
               IF j.dStart BETWEEN k.period_fr AND k.period_to THEN
                  IF k.pahd_payroll_no <> p_payno THEN
                     nSeqNo := nSeqNo + 1;
                     INSERT INTO pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                     VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', 0, 0, j.basic_rate, 0, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
                  END IF;
                  EXIT;
               END IF;
            END LOOP;
         END IF;

         IF j.nSuPay > 0 THEN
            nSeqNo := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_Vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-SUN-FLT', j.nSuPay, j.nSuDays, j.basic_rate*p_Sunday_RF, j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
         END IF;

         IF j.nHoPay > 0 THEN
            nSeqNo := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-FLT', j.nHoPay, j.nHoDays, j.basic_rate*p_Holiday_RF, j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
         END IF;

         IF j.nHSPay > 0 THEN
            nSeqNo := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HS-FLT', j.nHSPay, j.nHSDays, j.basic_rate*p_HolSun_RF, j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
         END IF;

      END LOOP;

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: before ''bIsEndOfMonth adjustments'' ');
      END IF;

      -- adjustments
      FOR j IN ( SELECT posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        a_basic_rate,
                        MIN(pay_date)                 dStart,
                        MAX(pay_date)                 dEnd,
                        SUM(nDays)                    nNumday,
                        SUM(AMT)                      nSalaryR,
                        SUM(DECODE(COLA_PAY,0,0,1))   nColaD,
                        SUM(COLA_PAY)                 nCola,
                        SUM(A_nDays)                  nANumday,
                        SUM(A_AMT)                    nASalaryR,
                        SUM(DECODE(A_COLA_PAY,0,0,1)) nAColaD,
                        SUM(A_COLA_PAY)               nACola
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 AND    pay_date BETWEEN dPeriodFr AND (p_date_fr-1)
                 GROUP  BY posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        a_basic_rate)
      LOOP
         IF dEmplID = p_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check: j.nNumday=' || TO_CHAR(j.nNumday) || ',j.nANumday=' || TO_CHAR(j.nANumday) ||
                                  ',j.basic_rate=' || TO_CHAR(j.basic_rate) || ',j.a_basic_rate=' || TO_CHAR(j.a_basic_rate) ||
                                  ',j.nCola=' || TO_CHAR(j.nCola) || ',j.nACola=' || TO_CHAR(j.nACola) || ',j.vess_code=' || j.vess_code ||
                                  ',j.nColaD=' || TO_CHAR(j.nColaD) || ',j.nAColaD=' || TO_CHAR(j.nAColaD) ||
                                  ',j.dStart=' || TO_CHAR(j.dStart) || ',j.dEnd=' || TO_CHAR(j.dEnd) );
         END IF;

         -- insert attendance summary
         IF j.basic_rate = 0 AND j.a_basic_rate > 0 THEN

            nSeqNo  := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nANumday, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

            IF j.nACola > 0 THEN
               nSeqNo := nSeqNo + 1;
               INSERT INTO pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nACola, nDays, j.nACola/j.nANumday, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
            END IF;
         ELSE
            IF (j.basic_rate-j.a_basic_rate) <> 0 THEN
               IF j.basic_rate > 0 AND j.a_basic_rate = 0 THEN
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, j.nSalaryR*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               ELSE
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, j.nSalaryR*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               END IF;
            END IF;

            IF (j.nACola-j.nCola) <> 0 THEN
               if (j.nAColaD-j.nColaD) > 0 then
               nSeqNo := nSeqNo + 1;
               INSERT INTO pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola-j.nCola), (j.nAColaD-j.nColaD), (j.nACola-j.nCola)/(j.nAColaD-j.nColaD), j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
               end if;
            END IF;
         END IF;

      END LOOP;

   ELSE
      -- adjustments
      FOR j IN ( SELECT posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        sal_freq,
                        a_basic_rate,
                        MIN(pay_date)                 dStart,
                        MAX(pay_date)                 dEnd,
                        SUM(nDays)                    nNumday,
                        SUM(AMT)                      nSalaryR,
                        SUM(DECODE(SU_PAY,0,0,SU_PAY))     nSuDays,
                        SUM(SU_PAY*BASIC_RATE)        nSuPay,
                        SUM(DECODE(HO_PAY,0,0,HO_PAY))     nHoDays,
                        SUM(HO_PAY*BASIC_RATE)        nHoPay,
                        SUM(DECODE(HS_PAY,0,0,HS_PAY))     nHSDays,
                        SUM(HS_PAY*BASIC_RATE)        nHSPay,
                        SUM(DECODE(COLA_PAY,0,0,1))   nColaD,
                        SUM(COLA_PAY)                 nCola,
                        SUM(a_nDays)                  nANumday,
                        SUM(A_AMT)                    nASalaryR,
                        SUM(DECODE(A_SU_PAY,0,0,A_SU_PAY))   nASuDays,
                        SUM(A_SU_PAY*A_BASIC_RATE)    nASuPay,
                        SUM(DECODE(A_HO_PAY,0,0,A_HO_PAY))   nAHoDays,
                        SUM(A_HO_PAY*A_BASIC_RATE)    nAHoPay,
                        SUM(DECODE(A_HS_PAY,0,0,A_HS_PAY))   nAHSDays,
                        SUM(A_HS_PAY*A_BASIC_RATE)    nAHSPay,
                        SUM(DECODE(A_COLA_PAY,0,0,1)) nAColaD,
                        SUM(A_COLA_PAY)               nACola
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 AND    pay_date BETWEEN dPeriodFr AND (p_date_fr-1)
                 GROUP  BY posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        sal_freq,
                        a_basic_rate)
      LOOP
         -- insert attendance summary
         IF j.basic_rate = 0 AND j.a_basic_rate > 0 THEN

            --IF j.sal_freq = 'MONTHLY' AND  TO_CHAR(j.dEnd,'DD') >= '28' THEN
            IF (j.sal_freq = 'MONTHLY') AND (TO_CHAR(j.dEnd,'DD') >= '28') AND (TO_CHAR(j.dEnd,'DD') >= TO_CHAR(last_day(j.dEnd),'DD')) THEN
               IF TO_CHAR(j.dEnd,'DD') = '31' THEN
                  nDays    := j.nANumday  - 1;
                  nSalaryR := j.nASalaryR - j.a_basic_rate;
               ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
                  nDays    := j.nANumday  + (30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')));
                  nSalaryR := j.nASalaryR + (j.a_basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
               ELSE
                  nDays    := j.nANumday;
                  nSalaryR := j.nASalaryR;
               END IF;
            ELSE
               nDays    := j.nANumday;
               nSalaryR := j.nASalaryR;
            END IF;

            nSeqNo  := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nSalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nDays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, nSalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

            IF j.nACola > 0 THEN
               nSeqNo := nSeqNo + 1;
               INSERT INTO pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola/j.nANumday)*nDays, nDays, j.nACola/j.nANumday, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
            END IF;
         ELSE
            IF (j.basic_rate-j.a_basic_rate) <> 0 THEN

               --IF (j.sal_freq = 'MONTHLY') AND (TO_CHAR(j.dEnd,'DD') >= '28') AND (j.nANumday > 0) THEN
               IF (j.sal_freq = 'MONTHLY') AND (TO_CHAR(j.dEnd,'DD') >= '28') AND (TO_CHAR(j.dEnd,'DD') >= TO_CHAR(last_day(j.dEnd),'DD')) AND (j.nANumday > 0) THEN
                  IF TO_CHAR(j.dEnd,'DD') = '31' THEN
                     nDays     := j.nANumday  - 1;
                     nADays    := nDays;
                     nSalaryR  := j.nSalaryR - j.basic_rate;
                     nASalaryR := j.nASalaryR - j.a_basic_rate;
                  ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
                     nDays     := j.nANumday  + (30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')));
                     nADays    := nDays;
                     nSalaryR  := j.nSalaryR + (j.basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
                     nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
                  ELSE
                     nDays     := j.nANumday;
                     nADays    := nDays;
                     nSalaryR  := j.nSalaryR;
                     nASalaryR := j.nASalaryR;
                  END IF;
               ELSE
                  nDays     := j.nNumday;
                  nADays    := j.nANumday;
                  nSalaryR  := j.nSalaryR;
                  nASalaryR := j.nASalaryR;
               END IF;


               IF j.basic_rate > 0 AND j.a_basic_rate = 0 THEN
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               ELSE
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nADays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               END IF;
            END IF;

            IF (j.nACola-j.nCola) <> 0 THEN
               nSeqNo := nSeqNo + 1;
               --IF (j.sal_freq = 'MONTHLY') AND (TO_CHAR(j.dEnd,'DD') >= '28') THEN
               IF (j.sal_freq = 'MONTHLY') AND (TO_CHAR(j.dEnd,'DD') >= '28') AND (TO_CHAR(j.dEnd,'DD') >= TO_CHAR(last_day(j.dEnd),'DD')) THEN
                  IF TO_CHAR(j.dEnd,'DD') = '31' THEN
                     nDays    := (GREATEST(j.nAColaD-1,0)-(j.nColaD-1));
                     if (j.nAColaD-j.nColaD) <> 0 then
                        nSalaryR := nDays*((j.nACola-j.nCola)/(j.nAColaD-j.nColaD));
                     else
                        nSalaryR := 0;
                     end if;
                  ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
                     nDays    := (GREATEST(j.nAColaD-(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))),0)-(j.nColaD-(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')))));
                     if (j.nAColaD-j.nColaD) <> 0 then
                        nSalaryR :=  nDays*((j.nACola-j.nCola)/(j.nAColaD-j.nColaD));
                     else
                        nSalaryR := 0;
                     end if;
                  ELSE
                     nDays    := (j.nAColaD-j.nColaD);
                     nSalaryR := (j.nACola-j.nCola);
                  END IF;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess, modified_by )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', nSalaryR, nDays, (j.nACola-j.nCola)/(j.nAColaD-j.nColaD), j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess, TO_CHAR(j.nAColaD) || ',' || TO_CHAR(j.nColaD) );
               ELSE
                  if (j.nAColaD-j.nColaD) <> 0 then
                     INSERT INTO pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
                     VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola-j.nCola), (j.nAColaD-j.nColaD), (j.nACola-j.nCola)/(j.nAColaD-j.nColaD), j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
                  end if;
               END IF;
            END IF;
         END IF;

      END LOOP;

   END IF;  --<if bIsEndOfMonth then>

   p_o_seq_no    := nSeqNo;
   p_latestvess  := vLatestVess;
   p_latesttitle := vLatestTitle;


EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);
END sp_count_flt_attendance;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_FLT_ATTENDANCE_LOG"
(
   p_empl_id    IN  VARCHAR2,
   p_payno      IN  NUMBER,
   p_year       IN  VARCHAR2,
   p_mon        IN  VARCHAR2,
   p_date_fr    IN  DATE,
   p_date_to    IN  DATE,
   p_Sunday_RF  IN  NUMBER,
   p_Holiday_RF IN  NUMBER,
   p_HolSun_RF  IN  NUMBER,
   p_dEmplID    IN  VARCHAR2,
   p_sal_freq   IN  VARCHAR2

) IS

   dEmplID           VARCHAR2(16) := p_dEmplID;
   dLatestEmbarked   DATE;
   dLatestDismbarked DATE;
   vLatestVessel     VARCHAR2(16);
   vLatestPosition   VARCHAR2(60);
   vLatestTitle      VARCHAR2(60);
   nLatestBasic      NUMBER(8,2);
   nLatestBasicG     NUMBER(8,2);
   vPLatestVessel    VARCHAR2(16);
   vPLatestPosition  VARCHAR2(60);
   vPLatestTitle     VARCHAR2(60);
   nPLatestBasic     NUMBER(8,2);
   nPLatestBasicG    NUMBER(8,2);

   nCola      NUMBER(10,5) := 0;
   nRegHol    NUMBER(10,5) := 0;
   nHolSun    NUMBER(10,5) := 0;
   nRegSun    NUMBER(10,5) := 0;
   nEnd       NUMBER(10,5) := 0;
   dChkDate   DATE;
   dTmpDate   DATE;
   dStart     DATE;
   dEnd       DATE;
   vOnBoard   VARCHAR2(1);
   dColaEff     DATE;
   nCntonCutOff Number;
BEGIN

   -- set cutoff date
   IF TO_CHAR(p_date_fr, 'DD') = '01' THEN
      dStart := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   ELSE
      dStart := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   END IF;

   --- reset first, this is for re-compute
   UPDATE PYS_PAYROLL_DTL_LOG
   SET    a_vess_code    = NULL,
          a_posi_code    = NULL,
          a_title        = NULL,
          a_basic_rate   = 0,
          a_basic_rate_g = 0,
          a_ndays        = 0,
          a_amt          = 0,
          a_amt_g        = 0,
          a_ot_pay       = 0,
          a_ht_pay       = 0,
          a_oport        = 'N',
          a_su_pay       = 0,
          a_ho_pay       = 0,
          a_hs_pay       = 0,
          a_cola_pay     = 0
   WHERE empl_empl_id = p_empl_id
   AND   pay_date BETWEEN dStart AND (p_date_fr-1);

   -- check every day
   nEnd := (p_date_to - dStart) + 1;
   FOR j IN 1..nEnd LOOP
      dChkDate := (dStart-1) + j;
      IF dLatestEmbarked IS NULL AND dChkDate <= dEnd THEN
         dTmpDate := Sf_Get_Latest_Embark(p_empl_id, dChkDate);
         IF dTmpDate IS NOT NULL THEN
            BEGIN
               SELECT TRUNC(vocr.dt_embarked), trunc(vocr.dt_disembarked), vocr.voya_vess_code,
                      empl.posi_code, vocr.title, vocr.basic_rate, vocr.basic_rate_g
               INTO   dLatestEmbarked, dLatestDismbarked, vLatestVessel,
                      vLatestPosition, vLatestTitle, nLatestBasic, nLatestBasicG
               FROM   CMS_VOYAGE_CREW vocr,
                      CMS_VESSELS vess,
                      PMS_EMPLOYEES empl
               WHERE  vocr.voya_voyage_date <= dTmpDate
               AND    vocr.dt_embarked = dTmpDate
               AND    vocr.voya_vess_code = vess.code
               AND    vocr.empl_empl_id = empl.empl_id
               AND    vocr.empl_empl_id = p_empl_id
               AND    vocr.passenger = 'N';
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  -- set latest embark and disembark to backdate, so as not to allow to compute
                  dLatestEmbarked   := TO_DATE('19000101', 'YYYYMMDD');
                  dLatestDismbarked := TO_DATE('19000101', 'YYYYMMDD');
               WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log-get service for employee ' || p_empl_id || ' ' || SQLERRM);
            END;
         ELSE
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         END IF;
      ELSE

         IF (dChkDate = (dEnd + 1)) and (dLatestEmbarked IS NULL ) THEN
            -- check if on-board during cut-off
            select count(1) into nCntonCutOff
            from PYS_PAYROLL_DTL_LOG
            where  empl_empl_id = p_empl_id
            and    pay_date = (dEnd);
            dTmpDate := Sf_Get_Latest_Embark(p_empl_id, dChkDate);
            IF (dTmpDate IS NOT NULL) and (nCntonCutOff > 1) THEN
               BEGIN
                  SELECT TRUNC(vocr.dt_embarked), trunc(vocr.dt_disembarked)
                  INTO   dLatestEmbarked, dLatestDismbarked
                  FROM   CMS_VOYAGE_CREW vocr
                  WHERE  vocr.voya_voyage_date <= dTmpDate
                  AND    vocr.dt_embarked = dTmpDate
                  AND    vocr.empl_empl_id = p_empl_id
                  AND    vocr.passenger = 'N';

                  vLatestVessel    := vPLatestVessel;
                  vLatestPosition  := vPLatestPosition;
                  vLatestTitle     := vPLatestTitle;
                  nLatestBasic     := nPLatestBasic;
                  nLatestBasicG    := nPLatestBasicG;

               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     -- set latest embark and disembark to backdate, so as not to allow to compute
                     dLatestEmbarked   := TO_DATE('19000101', 'YYYYMMDD');
                     dLatestDismbarked := TO_DATE('19000101', 'YYYYMMDD');
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log-get service for employee ' || p_empl_id || ' ' || SQLERRM);
               END;

            END IF;
         END IF;

         IF dLatestEmbarked IS NULL THEN
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         END IF;

      END IF; -- <if dLatestEmbarked is null then>

      -- check if on duty
      IF dChkDate BETWEEN dLatestEmbarked AND NVL(dLatestDismbarked, dChkDate+2) THEN
         vOnBoard := 'Y';
      ELSE
         IF (dChkDate > dEnd) AND NVL(dLatestDismbarked, dChkDate+2) >= dEnd THEN  -- check if still on actual payroll period (10 and 25)
            vOnBoard := 'Y';
         ELSE
            vOnBoard := 'N';
         END IF;
      END IF;

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: dChkDate=' || TO_CHAR(dChkDate) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked) || ',vLatestVessel=' || vLatestVessel || ',vOnBoard=' || vOnBoard );
      END IF;

      IF vOnBoard = 'Y' THEN
         -- check if pay date is sunday or holiday
         IF Sf_Is_Holiday (dChkDate) = 1 THEN
            IF Sf_Is_Sunday(dChkDate) = 1 THEN
               nHolSun := p_HolSun_RF;
            ELSE
               nRegHol := p_Holiday_RF;
            END IF;
         ELSE
            IF Sf_Is_Sunday(dChkDate) = 1 THEN
               nRegSun := p_Sunday_RF;
            END IF;
         END IF;

         -- check if with cola
         Sp_Get_Latest_Cola (p_empl_id, dChkDate, nCola, dColaEff);
         IF nCola > 0 AND dColaEff <= dEnd THEN
            nCola := nCola;
         ELSE
            nCola := 0;
         END IF;

         IF dEmplID = p_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check: nRegSun=' || TO_CHAR(nRegSun) || ',nRegHol =' || TO_CHAR(nRegHol ) ||
                                  ',nHolSun=' || TO_CHAR(nHolSun) || ',nCola=' || TO_CHAR(nCola) );
         END IF;

         -- create payroll log
         IF dChkDate < p_date_fr THEN    -- check assumed dates from previous payroll
            UPDATE PYS_PAYROLL_DTL_LOG
            SET    a_vess_code    = vLatestVessel,
                   a_posi_code    = vLatestPosition,
                   a_title        = vLatestTitle,
                   a_basic_rate   = nLatestBasic,
                   a_basic_rate_g = nLatestBasic,
                   a_ndays        = 1,
                   a_amt          = nLatestBasic,
                   a_amt_g        = nLatestBasic,
                   a_ot_pay       = 0,
                   a_ht_pay       = 0,
                   a_oport        = 'N',
                   a_su_pay       = nRegSun,
                   a_ho_pay       = nRegHol,
                   a_hs_pay       = nHolSun,
                   su_pay         = decode(su_pay, 0, 0, decode(nHolSun, 0, su_pay, 0)),
                   a_cola_pay     = nCola,
                   modified_by    = USER,
                   dt_modified    = SYSDATE
            WHERE empl_empl_id = p_empl_id
            AND   pay_date = dChkDate;
            IF SQL%NOTFOUND THEN
               INSERT INTO PYS_PAYROLL_DTL_LOG
                      ( payroll_no, empl_empl_id, pay_date, dept_code, a_vess_code, a_posi_code, a_title, sal_freq,
                        latest_vess, a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, a_ot_pay, a_ht_pay, a_oport,
                        a_su_pay, a_ho_pay, a_hs_pay, a_cola_pay, a_ndays, created_by, dt_created
                      )
               VALUES ( p_payno, p_empl_id, dChkDate, 'FL', vLatestVessel, vLatestPosition, vLatestTitle, p_sal_freq,
                        vLatestVessel, nLatestBasic, nLatestBasic, nLatestBasic, nLatestBasic, 0, 0, 'N',
                        nRegSun, nRegHol, nHolSun, nCola, 1, USER, SYSDATE
                      );
            END IF;
         ELSE
            BEGIN
               INSERT INTO PYS_PAYROLL_DTL_LOG
                      ( payroll_no, empl_empl_id, pay_date, dept_code, vess_code, posi_code, title, sal_freq,
                        latest_vess, basic_rate, basic_rate_g, amt, amt_g, ot_pay, ht_pay, oport,
                        su_pay, ho_pay, hs_pay, cola_pay, ndays, created_by, dt_created
                      )
               VALUES ( p_payno, p_empl_id, dChkDate, 'FL', vLatestVessel, vLatestPosition, vLatestTitle, p_sal_freq,
                        vLatestVessel, nLatestBasic, nLatestBasic, nLatestBasic, nLatestBasic, 0, 0, 'N',
                        nRegSun, nRegHol, nHolSun, nCola, 1, USER, SYSDATE
                      );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX THEN
                  UPDATE PYS_PAYROLL_DTL_LOG
                  SET    vess_code    = vLatestVessel,
                         posi_code    = vLatestPosition,
                         title        = vLatestTitle,
                         basic_rate   = nLatestBasic,
                         basic_rate_g = nLatestBasic,
                         ndays        = 1,
                         amt          = nLatestBasic,
                         amt_g        = nLatestBasic,
                         ot_pay       = 0,
                         ht_pay       = 0,
                         oport        = 'N',
                         su_pay       = nRegSun,
                         ho_pay       = nRegHol,
                         hs_pay       = nHolSun,
                         cola_pay     = nCola,
                         modified_by  = USER,
                         dt_modified  = SYSDATE
                  WHERE empl_empl_id = p_empl_id
                  AND   pay_date = dChkDate;
            END;
         END IF; -- <if dChkDate < p_date_fr then>
      ELSE
         IF dChkDate < p_date_fr AND TO_CHAR(p_date_fr, 'DD') = '16' THEN    -- check assumed dates from previous payroll
            UPDATE PYS_PAYROLL_DTL_LOG
            SET    ot_pay       = 0,
                   ht_pay       = 0,
                   su_pay       = 0,
                   ho_pay       = 0,
                   hs_pay       = 0,
                   modified_by  = USER,
                   dt_modified  = SYSDATE
            WHERE empl_empl_id = p_empl_id
            AND   pay_date = dChkDate;
         END IF;
      END IF; -- <if vOnDuty = 'Y' then>

      -- check if next pay date crew is still on board
      IF (dChkDate+1) BETWEEN dLatestEmbarked AND NVL(dLatestDismbarked, dChkDate+2) THEN
         NULL; -- still on duty
      ELSE
         IF (dChkDate+1) > dEnd AND NVL(dLatestDismbarked, dChkDate+2) > dEnd THEN    -- check if still on actual payroll period (10 and 25)
            NULL; -- assume crew still on duty
         ELSE
            vPLatestVessel    := vLatestVessel;
            vPLatestPosition  := vLatestPosition;
            vPLatestTitle     := vLatestTitle;
            nPLatestBasic     := nLatestBasic;
            nPLatestBasicG    := nLatestBasicG;
            dLatestEmbarked   := NULL;
            dLatestDismbarked := NULL;
            vLatestVessel     := NULL;
            vLatestPosition   := NULL;
            vLatestTitle      := NULL;
            nLatestBasic      := NULL;
            nLatestBasicG     := NULL;
         END IF;
      END IF;
      nHolSun := 0;
      nRegHol := 0;
      nRegSun := 0;
      nCola   := 0;

   END LOOP; -- <for j in 1..nEnd loop>


EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log employee ' || p_empl_id || ' ' || SQLERRM);
END Sp_Count_Flt_Attendance_Log;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_FLT_ATT_LOG_TEST"
(
   p_empl_id    IN  VARCHAR2,
   p_payno      IN  NUMBER,
   p_year       IN  VARCHAR2,
   p_mon        IN  VARCHAR2,
   p_date_fr    IN  DATE,
   p_date_to    IN  DATE,
   p_Sunday_RF  IN  NUMBER,
   p_Holiday_RF IN  NUMBER,
   p_HolSun_RF  IN  NUMBER,
   p_dEmplID    IN  VARCHAR2,
   p_sal_freq   IN  VARCHAR2

) IS

   dEmplID           VARCHAR2(16) := p_empl_id;
   dLatestEmbarked   DATE;
   dLatestDismbarked DATE;
   vLatestVessel     VARCHAR2(16);
   vLatestPosition   VARCHAR2(60);
   vLatestTitle      VARCHAR2(60);
   nLatestBasic      NUMBER(8,2);
   nLatestBasicG     NUMBER(8,2);

   nCola      NUMBER(10,5) := 0;
   nRegHol    NUMBER(10,5) := 0;
   nHolSun    NUMBER(10,5) := 0;
   nRegSun    NUMBER(10,5) := 0;
   nEnd       NUMBER(10,5) := 0;
   dChkDate   DATE;
   dTmpDate   DATE;
   dStart     DATE;
   dEnd       DATE;
   vOnBoard   VARCHAR2(1);
   dColaEff     DATE;

BEGIN

   -- set cutoff date
   IF TO_CHAR(p_date_fr, 'DD') = '01' THEN
      dStart := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   ELSE
      dStart := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   END IF;

   -- check every day
   nEnd := (p_date_to - dStart) + 1;
   FOR j IN 1..nEnd LOOP
      dChkDate := (dStart-1) + j;
      IF dLatestEmbarked IS NULL AND dChkDate <= dEnd THEN
         dTmpDate := Sf_Get_Latest_Embark(p_empl_id, dChkDate);
         IF dTmpDate IS NOT NULL THEN
            BEGIN
               SELECT TRUNC(vocr.dt_embarked), trunc(vocr.dt_disembarked), vocr.voya_vess_code,
                      empl.posi_code, vocr.title, vocr.basic_rate, vocr.basic_rate_g
               INTO   dLatestEmbarked, dLatestDismbarked, vLatestVessel,
                      vLatestPosition, vLatestTitle, nLatestBasic, nLatestBasicG
               FROM   CMS_VOYAGE_CREW vocr,
                      CMS_VESSELS vess,
                      PMS_EMPLOYEES empl
               WHERE  vocr.voya_voyage_date <= dTmpDate
               AND    vocr.dt_embarked = dTmpDate
               AND    vocr.voya_vess_code = vess.code
               AND    vocr.empl_empl_id = empl.empl_id
               AND    vocr.empl_empl_id = p_empl_id
               AND    vocr.passenger = 'N';
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  -- set latest embark and disembark to backdate, so as not to allow to compute
                  dLatestEmbarked   := TO_DATE('19000101', 'YYYYMMDD');
                  dLatestDismbarked := TO_DATE('19000101', 'YYYYMMDD');
               WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log-get service for employee ' || p_empl_id || ' ' || SQLERRM);
            END;
         ELSE
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         END IF;
      ELSE
         IF (dChkDate = (dEnd + 1)) and (dLatestEmbarked IS NULL ) THEN
            dTmpDate := Sf_Get_Latest_Embark(p_empl_id, dChkDate);
            IF dTmpDate IS NOT NULL THEN
               BEGIN
                  SELECT TRUNC(vocr.dt_embarked), trunc(vocr.dt_disembarked), vocr.voya_vess_code,
                         empl.posi_code, vocr.title, vocr.basic_rate, vocr.basic_rate_g
                  INTO   dLatestEmbarked, dLatestDismbarked, vLatestVessel,
                         vLatestPosition, vLatestTitle, nLatestBasic, nLatestBasicG
                  FROM   CMS_VOYAGE_CREW vocr,
                         CMS_VESSELS vess,
                         PMS_EMPLOYEES empl
                  WHERE  vocr.voya_voyage_date <= dTmpDate
                  AND    vocr.dt_embarked = dTmpDate
                  AND    vocr.voya_vess_code = vess.code
                  AND    vocr.empl_empl_id = empl.empl_id
                  AND    vocr.empl_empl_id = p_empl_id
                  AND    vocr.passenger = 'N';
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     -- set latest embark and disembark to backdate, so as not to allow to compute
                     dLatestEmbarked   := TO_DATE('19000101', 'YYYYMMDD');
                     dLatestDismbarked := TO_DATE('19000101', 'YYYYMMDD');
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log-get service for employee ' || p_empl_id || ' ' || SQLERRM);
               END;

            END IF;
         END IF;

         IF dLatestEmbarked IS NULL THEN
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         END IF;
      END IF; -- <if dLatestEmbarked is null then>

      -- check if on duty
      IF dChkDate BETWEEN dLatestEmbarked AND NVL(dLatestDismbarked, dChkDate+2) THEN
         vOnBoard := 'Y';
      ELSE
         IF (dChkDate > dEnd) AND NVL(dLatestDismbarked, dChkDate+2) >= dEnd THEN  -- check if still on actual payroll period (10 and 25)
            vOnBoard := 'Y';
         ELSE
            vOnBoard := 'N';
         END IF;
      END IF;

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: dChkDate=' || TO_CHAR(dChkDate) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked) || ',vLatestVessel=' || vLatestVessel || ',vOnBoard=' || vOnBoard );
      END IF;

/*
      IF vOnBoard = 'Y' THEN
         -- check if pay date is sunday or holiday
         IF Sf_Is_Holiday (dChkDate) = 1 THEN
            IF Sf_Is_Sunday(dChkDate) = 1 THEN
               nHolSun := p_HolSun_RF;
            ELSE
               nRegHol := p_Holiday_RF;
            END IF;
         ELSE
            IF Sf_Is_Sunday(dChkDate) = 1 THEN
               nRegSun := p_Sunday_RF;
            END IF;
         END IF;

         -- check if with cola
         Sp_Get_Latest_Cola (p_empl_id, dChkDate, nCola, dColaEff);
         IF nCola > 0 AND dColaEff <= dEnd THEN
            nCola := nCola;
         ELSE
            nCola := 0;
         END IF;

         IF dEmplID = p_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check: nRegSun=' || TO_CHAR(nRegSun) || ',nRegHol =' || TO_CHAR(nRegHol ) ||
                                  ',nHolSun=' || TO_CHAR(nHolSun) || ',nCola=' || TO_CHAR(nCola) );
         END IF;

         -- create payroll log
         IF dChkDate < p_date_fr THEN    -- check assumed dates from previous payroll

            DBMS_OUTPUT.PUT_LINE ('check assume: dChkDate=' || TO_CHAR(dChkDate) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked) || ',vLatestVessel=' || vLatestVessel || ',vOnBoard=' || vOnBoard );

         ELSE
            DBMS_OUTPUT.PUT_LINE ('check current: dChkDate=' || TO_CHAR(dChkDate) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked) || ',vLatestVessel=' || vLatestVessel || ',vOnBoard=' || vOnBoard );
         END IF; -- <if dChkDate < p_date_fr then>
      ELSE
         IF dChkDate < p_date_fr AND TO_CHAR(p_date_fr, 'DD') = '16' THEN    -- check assumed dates from previous payroll
            DBMS_OUTPUT.PUT_LINE ('check assume 2: dChkDate=' || TO_CHAR(dChkDate) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked) || ',vLatestVessel=' || vLatestVessel || ',vOnBoard=' || vOnBoard );

         END IF;
      END IF; -- <if vOnDuty = 'Y' then>
*/
      -- check if next pay date crew is still on board
      IF (dChkDate+1) BETWEEN dLatestEmbarked AND NVL(dLatestDismbarked, dChkDate+2) THEN
         NULL; -- still on duty
      ELSE
         DBMS_OUTPUT.PUT_LINE ('check 1: dChkDate=' || TO_CHAR(dChkDate+1) || ',dEnd=' || TO_CHAR(dEnd) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) || ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked));
         IF (dChkDate+1) > dEnd AND NVL(dLatestDismbarked, dChkDate+2) > dEnd THEN    -- check if still on actual payroll period (10 and 25)
            NULL; -- assume crew still on duty
         ELSE
            dLatestEmbarked   := NULL;
            dLatestDismbarked := NULL;
            vLatestVessel     := NULL;
            vLatestPosition   := NULL;
            vLatestTitle      := NULL;
            nLatestBasic      := NULL;
            nLatestBasicG     := NULL;
         END IF;
         DBMS_OUTPUT.PUT_LINE ('check 2: dChkDate=' || TO_CHAR(dChkDate+1) || ',dEnd=' || TO_CHAR(dEnd) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) || ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked));
      END IF;
      nHolSun := 0;
      nRegHol := 0;
      nRegSun := 0;
      nCola   := 0;

   END LOOP; -- <for j in 1..nEnd loop>


EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log employee ' || p_empl_id || ' ' || SQLERRM);
END Sp_Count_Flt_Att_Log_test;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_HOLIDAYS"
(
   p_type    in  varchar2,
   p_empl_id in  varchar2,
   p_date_fr in  date,
   p_date_to in  date,
   p_overtm  out number,
   p_regsun  out number,
   p_reghol  out number,
   p_holsun  out number,
   p_cola    out number

) is

   --get holidays
   cursor x ( p_date in date ) is
   select tx_date
   from   pys_holidays
   where  tx_date = p_date;

   --get attendance
   cursor atre (p_empl_id in varchar2, p_period_fr in date, p_period_to in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date between p_period_fr and p_period_to
   order  by att_date;


   nOvertm  Number := 0;
   nRegHol  Number := 0;
   nHolSun  Number := 0;
   nRegSun  Number := 0;
   nCOLA    Number := 0;
   nUpTO    Number := 0;
   bHolSun  Boolean;
   nDay     Number :=0;
begin

   if p_type = 'FLT' then

      nUpTo := (p_date_to-p_date_fr);

      for i in 1..nUpTo loop
         nDay := nDay + 1;
         bHolSun := FALSE;
         for i in x ( p_date_fr+(nDay-1) ) loop
            if to_char(i.tx_date, 'fmDAY') = 'SUNDAY' then
               nHolSun := nRegSun + 1;
            else
               nRegHol := nRegHol + 1;
            end if;
            bHolSun := TRUE;
         end loop;
         if not bHolSun then
            if to_char(p_date_fr + (nDay-1), 'fmDAY') = 'SUNDAY' then
               nRegSun := nRegSun + 1;
            end if;
         end if;
      end loop;

   else

      for j in atre ( p_empl_id, p_date_fr, p_date_to ) loop

         bHolSun := FALSE;
         for i in x ( j.tx_date ) loop
            if to_char(i.tx_date, 'fmDAY') = 'SUNDAY' then
               nHolSun := nRegSun + j.num_hours;
               if j.num_hours >= 8  then
                  nCOLA := nCOLA + 1;
               end if;
            else
               nRegHol := nRegHol + j.num_hours;
            end if;
            bHolSun := TRUE;
         end loop;

         -- if not holiday but fall on Sunday
         if not bHolSun then
            if to_char(j.tx_date, 'fmDAY') = 'SUNDAY' then
               nRegSun := nRegSun + j.num_hours;
               if j.num_hours >= 8  then
                  nCOLA := nCOLA + 1;
               end if;
               bHolSun := TRUE;
            end if;
         end if;

         -- if not holiday and not Sunday, regular OT
         if not bHolSun then
             nOvertm := nOvertm + j.num_hours;
         end if;

      end loop;

   end if;

   p_overtm  := nOvertm;
   p_regsun  := nRegSun;
   p_reghol  := nRegHol;
   p_holsun  := nHolSun;
   p_cola    := nCOLA;

end sp_count_holidays;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_MGR_ATTENDANCE"
(
   p_empl_id    in  varchar2,
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_dept_code  in  varchar2,
   p_posi_code  in  varchar2,
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Sunday_RF  in  number,
   p_Holiday_RF in  number,
   p_HolSun_RF  in  number,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2,
   p_numday     out number,
   p_tsalaryg   out number,
   p_supay      out number,
   p_hopay      out number,
   p_hspay      out number,
   p_Allowance  out number,
   p_o_seq_no   out number

) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_date in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date = p_date;

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, amt, eff_st_date --max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date)
                         from pys_employee_salary
                         where empl_empl_id = p_empl_id
                         and eff_st_date <= p_effectivity) -- added by thess 1/7/08-- p_effectivity
   group  by empl_empl_id, allo_code, amt, eff_st_date;

   nNumHrs   Number (7,3) := 0;
   nNumDay    Number := 0;
   nRegHol    Number := 0;
   nHolSun    Number := 0;
   nRegSun    Number := 0;
   nUpTO      Number := 0;
   nTmpHrs    Number (7,3) := 0;
   dDate      Date;
   dStart     Date;
   dend       Date;
   dPrevStart Date;
   dPrevend   Date;
   dFirstDay  Date;
   nRecCtr    Number := 0;
   bIsEndOfMonth Boolean;

   nSeqNo       Number;
   nSalaryR     Number(8,2) := 0;
   nSalaryG     Number(8,2) := 0;
   nSunday_R    Number(8,3) := 0;
   nHoliday_R   Number(8,3) := 0;
   nHolSun_R    Number(8,3) := 0;
   nSuPay       Number(8,2) := 0;
   nHoPay       Number(8,2) := 0;
   nHSPay       Number(8,2) := 0;
   nAllowances  Number(8,2);
   nTSalaryG    Number(8,2) := 0;
   nTSuPay      Number(8,2) := 0;
   nTHoPay      Number(8,2) := 0;
   nTHSPay      Number(8,2) := 0;
   nTNumDay     Number := 0;
   nTRegSun     Number := 0;
   nTRegHol     Number := 0;
   nTHolSun     Number := 0;
   dTmpDate     Date;

   nHolOT    Number (7,3) := 0;
   nHolOT_R     Number(8,3) := 0;
   nSunday_T    Varchar2(16) := 'OT-SUN-OFC';
   nHoliday_T   Varchar2(16) := 'OT-HOL-OFC';
   nHolOT_T     Varchar2(16) := 'OT-HOL-EXC';
   dEmplID      varchar2(16) := p_dEmplID;
   nCola        number(10,5) := 0;
begin

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   --if to_char(p_date_to,'DD') = '15' then
   --   nUpTo := (p_date_to - dStart) + 1;
   --else
   --   nUpTo := (p_date_to - dStart) ;
   --end if;

   nUpto := (dEnd - dStart)+1;
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 1: p_empl_id=' || p_empl_id || ',dStart=' || to_char(dStart) || ',dEnd=' || to_char(dEnd) || ' nUpto=' || to_char(nUpto));
   end if;
   for k in 1..nUpto loop
      dDate := (dStart-1) + k;
      nTmpHrs := 0;
      if sf_is_sunday (dDate) = 1 then
         if sf_is_holiday (dDate) = 1 then
            for j in atre (p_empl_id, dDate) loop
               --if j.num_hours >= 4  then
               if j.num_hours > 0  then  -- if present
                  nRegHol := nRegHol + 8;
               end if;
            end loop;
         else
            for j in atre (p_empl_id, dDate) loop
               --if j.num_hours >= 4  then
               if j.num_hours > 0  then    -- if present
                  nTmpHrs := nTmpHrs + 8;
               end if;
            end loop;
         end if;
      elsif sf_is_holiday (dDate) = 1 then
         for j in atre (p_empl_id, dDate) loop
            --if j.num_hours >= 6  then
            if j.num_hours > 0  then    -- if present
               nRegHol := nRegHol + 8;
            end if;
         end loop;
      end if;
      nNumHrs  := nNumHrs + nTmpHrs;
      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 2: dDate=' || to_char(dDate) || ' nNumHrs=' || to_char(nNumHrs) || ' nRegHol=' || to_char(nRegHol) ||
                               ' nTmpHrs=' || to_char(nTmpHrs) || ' Sun:Hol=' || to_char(sf_is_sunday (dDate)) || ':' || to_char(sf_is_holiday (dDate)));
      end if;

   end loop;

   -- compute attendance
   begin
      nSeqNo     := nSeqNo + 1;
      nNumDay    := 15 + (nNumHrs/8);
      nSalaryR   := nNumDay * (p_basic_r/30);
      nSalaryG   := p_basic_g/2;
      nSunday_R  := ( p_Sunday_RF * (p_basic_r/30) );
      nHoliday_R := ( p_Holiday_RF * (p_basic_r/30) );
      nHolSun_R  := ( p_HolSun_RF * (p_basic_r/30) );

      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 3: nNumDay=' || to_char(nNumDay) || ', nSalaryR=' || to_char(nSalaryR) || ', nSalaryG=' || to_char(nSalaryG) ||
                               ',p_Holiday_RF=' || to_char(p_Holiday_RF) || ',p_HolSun_RF=' || to_char(p_HolSun_RF) ||
                               ',nHoliday_R=' || to_char(nHoliday_R) || ',nRegHol=' || to_char(nRegHol));
      end if;

      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, 'REG', nSalaryR, nNumDay, p_basic_r, nSalaryG, p_basic_g, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end;

   if nRegSun > 0 then
      nSeqNo := nSeqNo + 1;
      nSuPay := nSunday_R * (nRegSun/8);
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nSunday_T, nSuPay, (nRegSun/8), nSunday_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   if nRegHol > 0 then
      nSeqNo := nSeqNo + 1;
      nHoPay := nHoliday_R * (nRegHol/8);
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHoliday_T, nHoPay, (nRegHol/8), nHoliday_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   if nHolOT > 0 then
      nSeqNo := nSeqNo + 1;
      nHSPay := nHolOT_R * (nHolOT/8);
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHolOT_T, nHSPay, (nHolOT/8), nHolOT_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   -- get allowances (OFC)
   dTmpDate := p_date_fr; --sf_latest_allowance_date (p_empl_id, p_date_fr);
   if dTmpDate is not null then
      for x in allo (p_empl_id, dTmpDate) loop
         nSeqNo := nSeqNo + 1;
         if nNumDay > 15 then
            nCola := 15;
         else
            nCola := nNumDay;
         end if;
         nAllowances := nAllowances + (x.amt*nNumDay);
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, x.allo_code, (x.amt*nCola), nCola, x.amt, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
      end loop;
   end if;

   p_numday    := nNumDay;
   p_tsalaryg  := nSalaryG;
   p_SuPay     := nSuPay;
   p_HoPay     := nHoPay;
   p_HSPay     := nHSPay;
   p_Allowance := nAllowances;
   p_o_seq_no  := nSeqNo;

end sp_count_mgr_attendance;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_MGR_ATTENDANCE_0815"
(
   p_empl_id    in  varchar2,
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_dept_code  in  varchar2,
   p_posi_code  in  varchar2,
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Sunday_RF  in  number,
   p_Holiday_RF in  number,
   p_HolSun_RF  in  number,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2,
   p_numday     out number,
   p_tsalaryg   out number,
   p_supay      out number,
   p_hopay      out number,
   p_hspay      out number,
   p_Allowance  out number,
   p_o_seq_no   out number

) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_date in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date = p_date;

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, amt, eff_st_date --max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date)
                         from pys_employee_salary
                         where empl_empl_id = p_empl_id
                         and eff_st_date <= p_effectivity) -- added by thess 1/7/08-- p_effectivity
   group  by empl_empl_id, allo_code, amt, eff_st_date;

   nNumHrs   Number (7,3) := 0;
   nNumDay    Number := 0;
   nRegHol    Number := 0;
   nHolSun    Number := 0;
   nRegSun    Number := 0;
   nUpTO      Number := 0;
   nTmpHrs    Number (7,3) := 0;
   dDate      Date;
   dStart     Date;
   dend       Date;
   dPrevStart Date;
   dPrevend   Date;
   dFirstDay  Date;
   nRecCtr    Number := 0;
   bIsEndOfMonth Boolean;

   nSeqNo       Number;
   nSalaryR     Number(8,2) := 0;
   nSalaryG     Number(8,2) := 0;
   nSunday_R    Number(8,3) := 0;
   nHoliday_R   Number(8,3) := 0;
   nHolSun_R    Number(8,3) := 0;
   nSuPay       Number(8,2) := 0;
   nHoPay       Number(8,2) := 0;
   nHSPay       Number(8,2) := 0;
   nAllowances  Number(8,2);
   nTSalaryG    Number(8,2) := 0;
   nTSuPay      Number(8,2) := 0;
   nTHoPay      Number(8,2) := 0;
   nTHSPay      Number(8,2) := 0;
   nTNumDay     Number := 0;
   nTRegSun     Number := 0;
   nTRegHol     Number := 0;
   nTHolSun     Number := 0;
   dTmpDate     Date;

   nHolOT    Number (7,3) := 0;
   nHolOT_R     Number(8,3) := 0;
   nSunday_T    Varchar2(16) := 'OT-SUN-OFC';
   nHoliday_T   Varchar2(16) := 'OT-HOL-OFC';
   nHolOT_T     Varchar2(16) := 'OT-HOL-EXC';
   dEmplID      varchar2(16) := p_dEmplID;
   nCola        number(10,5) := 0;
begin

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if to_char(p_date_to, 'DD') = '15' then
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   --if to_char(p_date_to,'DD') = '15' then
   --   nUpTo := (p_date_to - dStart) + 1;
   --else
   --   nUpTo := (p_date_to - dStart) ;
   --end if;

   nUpto := (dEnd - dStart)+1;
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 1: p_empl_id=' || p_empl_id || ',dStart=' || to_char(dStart) || ',dEnd=' || to_char(dEnd) || ' nUpto=' || to_char(nUpto));
   end if;
   for k in 1..nUpto loop
      dDate := (dStart-1) + k;
      nTmpHrs := 0;
      if sf_is_sunday (dDate) = 1 then
         if sf_is_holiday (dDate) = 1 then
            for j in atre (p_empl_id, dDate) loop
               --if j.num_hours >= 4  then
               if j.num_hours > 0  then  -- if present
                  nRegHol := nRegHol + 8;
               end if;
            end loop;
         else
            for j in atre (p_empl_id, dDate) loop
               --if j.num_hours >= 4  then
               if j.num_hours > 0  then    -- if present
                  nTmpHrs := nTmpHrs + 8;
               end if;
            end loop;
         end if;
      elsif sf_is_holiday (dDate) = 1 then
         for j in atre (p_empl_id, dDate) loop
            --if j.num_hours >= 6  then
            if j.num_hours > 0  then    -- if present
               nRegHol := nRegHol + 8;
            end if;
         end loop;
      end if;
      nNumHrs  := nNumHrs + nTmpHrs;
      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 2: dDate=' || to_char(dDate) || ' nNumHrs=' || to_char(nNumHrs) || ' nRegHol=' || to_char(nRegHol) ||
                               ' nTmpHrs=' || to_char(nTmpHrs) || ' Sun:Hol=' || to_char(sf_is_sunday (dDate)) || ':' || to_char(sf_is_holiday (dDate)));
      end if;

   end loop;

   -- compute attendance
   begin
      nSeqNo     := nSeqNo + 1;
      nNumDay    := 15 + (nNumHrs/8);
      nSalaryR   := nNumDay * (p_basic_r/30);
      nSalaryG   := p_basic_g/2;
      nSunday_R  := ( p_Sunday_RF * (p_basic_r/30) );
      nHoliday_R := ( p_Holiday_RF * (p_basic_r/30) );
      nHolSun_R  := ( p_HolSun_RF * (p_basic_r/30) );

      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 3: nNumDay=' || to_char(nNumDay) || ', nSalaryR=' || to_char(nSalaryR) || ', nSalaryG=' || to_char(nSalaryG) ||
                               ',p_Holiday_RF=' || to_char(p_Holiday_RF) || ',p_HolSun_RF=' || to_char(p_HolSun_RF) ||
                               ',nHoliday_R=' || to_char(nHoliday_R) || ',nRegHol=' || to_char(nRegHol));
      end if;

      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, 'REG', nSalaryR, nNumDay, p_basic_r, nSalaryG, p_basic_g, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end;

   if nRegSun > 0 then
      nSeqNo := nSeqNo + 1;
      nSuPay := nSunday_R * (nRegSun/8);
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nSunday_T, nSuPay, (nRegSun/8), nSunday_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   if nRegHol > 0 then
      nSeqNo := nSeqNo + 1;
      nHoPay := nHoliday_R * (nRegHol/8);
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHoliday_T, nHoPay, (nRegHol/8), nHoliday_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   if nHolOT > 0 then
      nSeqNo := nSeqNo + 1;
      nHSPay := nHolOT_R * (nHolOT/8);
      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq )
      values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, nHolOT_T, nHSPay, (nHolOT/8), nHolOT_R, null, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
   end if;

   -- get allowances (OFC)
   dTmpDate := p_date_fr; --sf_latest_allowance_date (p_empl_id, p_date_fr);
   if dTmpDate is not null then
      for x in allo (p_empl_id, dTmpDate) loop
         nSeqNo := nSeqNo + 1;
         if nNumDay > 15 then
            nCola := 15;
         else
            nCola := nNumDay;
         end if;
         nAllowances := nAllowances + (x.amt*nNumDay);
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, p_date_fr, p_date_to, nSeqNo, p_empl_id, p_posi_code, x.allo_code, (x.amt*nCola), nCola, x.amt, p_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
      end loop;
   end if;

   p_numday    := nNumDay;
   p_tsalaryg  := nSalaryG;
   p_SuPay     := nSuPay;
   p_HoPay     := nHoPay;
   p_HSPay     := nHSPay;
   p_Allowance := nAllowances;
   p_o_seq_no  := nSeqNo;

end sp_count_mgr_attendance_0815;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_MGR_ATTENDANCE_NEW"
(
   p_empl_id    in  varchar2,
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_dept_code  in  varchar2,
   p_posi_code  in  varchar2,
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Sunday_RF  in  number,
   p_Holiday_RF in  number,
   p_HolSun_RF  in  number,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2,
   p_numday     out number,
   p_tsalaryg   out number,
   p_supay      out number,
   p_hopay      out number,
   p_hspay      out number,
   p_Allowance  out number,
   p_o_seq_no   out number

) is

   --get attendance
   cursor atre (p_empl_id in varchar2, p_date in date ) is
   select att_date tx_date, am_time_in, am_time_out, pm_time_in, pm_time_out, num_hours, ot_hours, outer_port
   from   pms_attendance_records
   where  empl_empl_id = p_empl_id
   and    att_date = p_date;

   --get allowances
   cursor allo (p_empl_id in varchar2, p_effectivity in date) is
   select empl_empl_id, allo_code, amt, eff_st_date --max(amt) amt
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date)
                         from pys_employee_salary
                         where empl_empl_id = p_empl_id
                         and eff_st_date <= p_effectivity) -- added by thess 1/7/08-- p_effectivity
   group  by empl_empl_id, allo_code, amt, eff_st_date;

   nNumHrs    Number (7,3) := 0;
   nDays      Number(10,5) := 0;
   nADays     Number(10,5) := 0;
   nSalaryR   Number(12,4) := 0;
   nASalaryR  Number(12,4) := 0;
   nNumDay    Number := 0;
   nRegHol    Number := 0;
   nHolSun    Number := 0;
   nRegSun    Number := 0;
   nUpTO      Number := 0;
   nTmpHrs    Number (7,3) := 0;
   dDate      Date;
   dStart     Date;
   dend       Date;
   dPrevStart Date;
   dPrevend   Date;
   dFirstDay  Date;
   nRecCtr    Number := 0;
   bIsEndOfMonth Boolean;
   nBasicR    Number(12,5);

   nSeqNo       Number;
   nSalaryG     Number(8,2) := 0;
   nSunday_R    Number(8,3) := 0;
   nHoliday_R   Number(8,3) := 0;
   nHolSun_R    Number(8,3) := 0;
   nSuPay       Number(8,2) := 0;
   nHoPay       Number(8,2) := 0;
   nHSPay       Number(8,2) := 0;
   nAllowances  Number(8,2);
   nTSalaryG    Number(8,2) := 0;
   nTSuPay      Number(8,2) := 0;
   nTHoPay      Number(8,2) := 0;
   nTHSPay      Number(8,2) := 0;
   nTNumDay     Number := 0;
   nTRegSun     Number := 0;
   nTRegHol     Number := 0;
   nTHolSun     Number := 0;
   dTmpDate     Date;
   o_basic_r    Number(10,5) := 0;
   o_basic_g    Number(10,5) := 0;
   o_salfreq    Varchar2(12);
   o_ismanager  Varchar2(12);
   nColaPay     Number(10,5) := 0;
   nColaDay     Number(10,5) := 0;
   dColaEff     Date;
   vOuter_Port  Varchar2(1) := 'N';

   nHolOT    Number (7,3) := 0;
   nHolOT_R     Number(8,3) := 0;
   nSunday_T    Varchar2(16) := 'OT-SUN-OFC';
   nHoliday_T   Varchar2(16) := 'OT-HOL-OFC';
   nHolOT_T     Varchar2(16) := 'OT-HOL-EXC';
   dEmplID      varchar2(16) := p_dEmplID;
   nCola        number(10,5) := 0;
   bFirst       Boolean := TRUE;
begin

   nSeqNo := p_seq_no;

   -- set up cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   nUpto := (p_date_to - dStart)+1;
   if p_empl_id = dEmplID then
      dbms_output.put_line ('check 1: p_empl_id=' || p_empl_id || ',dStart=' || to_char(dStart) || ',dEnd=' || to_char(dEnd) || ' nUpto=' || to_char(nUpto));
   end if;
   for k in 1..nUpto loop
      dDate := (dStart-1) + k;
      nTmpHrs := 0;
      if sf_is_sunday (dDate) = 1 then
         if sf_is_holiday (dDate) = 1 then
            for j in atre (p_empl_id, dDate) loop
               if j.num_hours > 0  then  -- if present
                  nRegHol := nRegHol + 8;
               end if;
            end loop;
         else
            for j in atre (p_empl_id, dDate) loop
               if j.num_hours > 0  then    -- if present
                  nTmpHrs := nTmpHrs + 8;
               end if;
            end loop;
         end if;
      elsif sf_is_holiday (dDate) = 1 then
         for j in atre (p_empl_id, dDate) loop
            if j.num_hours > 0  then    -- if present
               nRegHol := nRegHol + 8;
            end if;
         end loop;
      end if;
      nNumHrs  := nNumHrs + nTmpHrs;
      if p_empl_id = dEmplID then
         dbms_output.put_line ('check 2: dDate=' || to_char(dDate) || ' nNumHrs=' || to_char(nNumHrs) || ' nRegHol=' || to_char(nRegHol) ||
                               ' nTmpHrs=' || to_char(nTmpHrs) || ' Sun:Hol=' || to_char(sf_is_sunday (dDate)) || ':' || to_char(sf_is_holiday (dDate)));
      end if;

      if dDate < dEnd then
         sp_latest_get_basic_rate (p_empl_id, dDate, o_basic_r, o_basic_g, o_salfreq, o_ismanager);
      else
         sp_latest_get_basic_rate (p_empl_id, dEnd, o_basic_r, o_basic_g, o_salfreq, o_ismanager);
      end if;

      nNumDay    := (nNumHrs/8);
      nSuPay     := p_Sunday_RF * (nRegSun/8);
      nHoPay     := p_Holiday_RF * (nRegHol/8);
      nHSPay     := p_HolSun_RF * (nHolOT/8);
      nBasicR    := o_basic_r/30;

      -- check if with cola
      sp_get_latest_cola (p_empl_id, dDate, nColaPay, dColaEff);
      if nColaPay > 0 and dColaEff <= dEnd then
         nColaDay := 1;
         nColaPay := nColaPay;
      else
         nColaPay := 0;
         nColaDay := 0;
      end if;

      -- create payroll log
      if dDate < p_date_fr then    -- check assumed dates from previous payroll
         update pys_payroll_dtl_log
         set    a_dept_code    = p_dept_code,
                a_posi_code    = p_posi_code,
                a_basic_rate   = nBasicR,
                a_basic_rate_g = o_basic_g,
                a_ndays        = 1,
                a_amt          = nBasicR,
                a_amt_g        = o_basic_g/2,
                su_pay         = nSuPay,
                ho_pay         = nHoPay,
                hs_pay         = nHSPay,
                a_oport        = vOuter_Port,
                a_cola_pay     = nColaPay,
                a_cola_day     = nColaDay,
                modified_by    = user,
                dt_modified    = sysdate
         where empl_empl_id = p_empl_id
         and   pay_date = dDate;
         if sql%NOTFOUND then
            insert into pys_payroll_dtl_log
                   ( payroll_no, empl_empl_id, pay_date, a_dept_code, a_posi_code, sal_freq,
                     a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, ot_pay, hs_pay, oport,
                     su_pay, ho_pay, ht_pay, a_cola_pay, a_cola_day, a_ndays, created_by, dt_created
                   )
            values ( p_payno, p_empl_id, dDate, p_dept_code, p_posi_code, o_salfreq,
                     nBasicR, o_basic_g, nBasicR, o_basic_g/2, 0, nHSPay, vOuter_Port,
                     nSuPay, nHoPay, 0, nColaPay, nColaDay, 1, user, sysdate
                   );
         end if;
      else

         begin
            insert into pys_payroll_dtl_log
                   ( payroll_no, empl_empl_id, pay_date, dept_code, posi_code, sal_freq,
                     basic_rate, basic_rate_g, amt, amt_g, ot_pay, ht_pay, oport,
                     su_pay, ho_pay, hs_pay, cola_pay, cola_day, ndays, created_by, dt_created
                   )
            values ( p_payno, p_empl_id, dDate, p_dept_code, p_posi_code, o_salfreq,
                     nBasicR, o_basic_g, nBasicR, o_basic_g/2, 0, nHSPay, vOuter_Port,
                     nSuPay, nHoPay, 0, nColaPay, nColaDay, 1, user, sysdate
                   );
         exception
            when dup_val_on_index then
               update pys_payroll_dtl_log
               set    dept_code    = p_dept_code,
                      posi_code    = p_posi_code,
                      basic_rate   = nBasicR,
                      basic_rate_g = o_basic_g,
                      ndays        = 1,
                      amt          = nBasicR,
                      amt_g        = o_basic_g/2,
                      oport        = vOuter_Port,
                      su_pay       = nSuPay,
                      ho_pay       = nHoPay,
                      hs_pay       = nHSPay,
                      cola_pay     = nColaPay,
                      cola_day     = nColaDay,
                      modified_by  = user,
                      dt_modified  = sysdate
               where empl_empl_id = p_empl_id
               and   pay_date = dDate;
         end;
      end if; -- <if dChkDate < p_date_fr then>

      nNumDay    := 0;
      nSuPay     := 0;
      nHoPay     := 0;
      nHSPay     := 0;
      nRegSun    := 0;
      nRegHol    := 0;
      nHolOT     := 0;

   end loop;


   -- regular days
   for j in ( select posi_code,
                     title,
                     max(basic_rate) basic_rate,
                     max(basic_rate_g) basic_rate_g,
                     dept_code,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(cola_day)               nColaDay,
                     sum(cola_pay)               nColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.dept_code=' || j.dept_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if;

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      if  j.nNumday > 15 then
         nDays := 15;
      else
         if TO_CHAR(j.dEnd,'DD') <= '30' then
            nDays := 15;
         else
            nDays := j.nNumday;
         end if;
      end if;
      if bFirst then
         if j.dEnd > dEnd then
            nDays := nDays + sf_count_sundays(p_empl_id, dStart, dEnd);
         else
            nDays := nDays + sf_count_sundays(p_empl_id, dStart, j.dEnd);
         end if;
      else
         if j.dEnd > dEnd then
            nDays := nDays + sf_count_sundays(p_empl_id, j.dStart, dEnd);
         else
            nDays := nDays + sf_count_sundays(p_empl_id, j.dStart, j.dEnd);
         end if;
      end if;

      insert into pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
      values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nDays*j.basic_rate, nDays, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', 'MONTHLY' );

      bFirst := FALSE;

   end loop;

   -- regular days (cola)
   for j in ( select posi_code,
                     title,
                     dept_code,
                     min(pay_date) dStart,
                     max(pay_date) dEnd,
                     max(cola_pay) nColaRate,
                     sum(cola_day) nColaDay,
                     sum(cola_pay) nColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    cola_pay > 0
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code
             )
   loop

      if j.nColaPay > 0 and j.nColaDay > 0 then
         nSeqNo := nSeqNo + 1;
         if  j.nColaDay > 15 then
            nColaDay := 15;
            nColaPay := 15*j.nColaRate;
         else
            nColaDay := j.nColaDay;
            nColaPay := j.nColaPay;
         end if;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', nColaPay, nColaDay, j.nColaRate, j.dept_code, user, sysdate, 'ADD', 'MONTHLY'  );
      end if;

   end loop;

   -- regular days (overtime)
   for j in ( select posi_code,
                     title,
                     max(decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE)) basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                     sum(HO_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHoPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dStart and dEnd
              group  by  posi_code, title, dept_code, oport
             )
   loop

      if j.nHoPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-OFC', j.nHoPay, j.nHoDays, j.basic_rate, j.dept_code, user, sysdate, 'ADD', 'MONTHLY'   );
      end if;

   end loop;



   -- adjustments
   for j in ( select posi_code,
                     title,
                     dept_code,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_basic_rate,
                     min(pay_date)                 dStart,
                     max(pay_date)                 dEnd,
                     sum(nDays)                    nNumday,
                     sum(AMT)                      nSalaryR,
                     sum(A_nDays)                  nANumday,
                     sum(A_AMT)                    nASalaryR
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dStart and (p_date_fr-1)
              and    (basic_rate-a_basic_rate) <> 0
              group  by posi_code,
                     title,
                     dept_code,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_basic_rate)
   loop
      if (j.basic_rate - j.a_basic_rate) <> 0 or (j.nNumDay-j.nANumday) <> 0 then
         if TO_CHAR(j.dEnd,'DD') >= '28' then
            if TO_CHAR(j.dEnd,'DD') = '31' then
               nDays     := j.nANumday - 1;
               nADays    := nDays;
               nSalaryR  := j.nSalaryR - j.basic_rate;
               nASalaryR := j.nASalaryR - j.a_basic_rate;
            elsif TO_CHAR(j.dEnd,'DD') < '30' then
               nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
               nADays    := 15;
               nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
               nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
            else
               nDays     := j.nANumday;
               nADays    := nDays;
               nSalaryR  := j.nSalaryR;
               nASalaryR := j.nASalaryR;
            end if;
         else
            nDays     := j.nNumday;
            nADays    := j.nANumday;
            nSalaryR  := j.nSalaryR;
            nASalaryR := j.nASalaryR;
         end if;

         nSeqNo  := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nASalaryR, nADays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', 'MONTHLY' );
         nSeqNo  := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR)*-1, nDays*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', 'MONTHLY' );
      end if;
   end loop;

   -- adjustment (cola)
   for j in ( select posi_code,
                     title,
                     dept_code,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     min(pay_date)   dStart,
                     max(pay_date)   dEnd,
                     sum(cola_day)   nColaDay,
                     sum(cola_pay)   nColaPay,
                     sum(a_cola_day) nAColaDay,
                     sum(a_cola_pay) nAColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    a_cola_day <> 0
              and    pay_date between dStart and (p_date_fr-1)
              group  by posi_code,
                     title,
                     dept_code,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate )
   loop
      if (j.nAColaPay-j.nColaPay) <> 0 and (j.nAColaDay-j.nColaDay) <> 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
      end if;

   end loop;

   p_numday    := 0;
   p_tsalaryg  := 0;
   p_SuPay     := 0;
   p_HoPay     := 0;
   p_HSPay     := 0;
   p_Allowance := 0;
   p_o_seq_no  := nSeqNo;

end sp_count_mgr_attendance_new;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_OFC_ATTENDANCE"
(
   p_empl_id    in  varchar2,
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_dept_code  in  varchar2,
   p_posi_code  in  varchar2,
   p_isMonthly  in  varchar2,    -- monthly but non-manager
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Overtm_RO  in  number,
   p_Sunday_RO  in  number,
   p_Holiday_RO in  number,
   p_HolSun_RO  in  number,
   p_Outer_RO   in  number,
   p_OutAd_RO   in  number,
   p_seq_no     in  number,
   p_dEmplID    in  varchar2,
   p_numday     out number,
   p_tsalaryg   out number,
   p_otpay      out number,
   p_supay      out number,
   p_hopay      out number,
   p_hspay      out number,
   p_OPPay      out number,
   p_OAPay      out number,
   p_Allowance  out number,
   p_o_seq_no   out number

) is

   dEmplID      varchar2(16) := p_dEmplID;
   nDays        Number(10,5) := 0;
   nADays       Number(10,5) := 0;
   nSalaryR     Number(12,4) := 0;
   nASalaryR    Number(12,4) := 0;
   nSeqNo       Number;
   vSalFreq     Varchar2(12);
   dPeriodFr    Date;
   dPeriodTo    Date;
   dTempFr      Date;
   dTempTo      Date;
   bIsEndOfMonth Boolean;
   nSundayOPDays Number(10,5) := 0;
   nSundayOPDate Date;
   nSundayOPRate Number(12,4) := 0;
   nTotalCola    Number(12,4) := 0;
   nMoTotalRec  Number(12,4)  := 0;
   nMoTotalDay  Number(12,4)  := 0;
   nAlloCtr   Number;
   dAlloMaxDt Date;
   vAlloAmt   NUmber(12,4);
   nColaPay   Number(12,4);
   nColaDay   Number(12,4);

begin

   nSeqNo := p_seq_no;

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dPeriodFr := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dPeriodFr := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if p_isMonthly = 'Y' then
      vSalFreq := 'MONTHLY';
   else
      vSalFreq := 'SEMI-MO';
   end if;

   -- regular days
   for j in ( select posi_code,
                     title,
                     --max(basic_rate) basic_rate,
                     basic_rate basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(decode(OT_PAY,0,0,OT_PAY))   nOtDays,
                     sum(OT_PAY*BASIC_RATE)      nOtPay,
                     sum(decode(SU_PAY,0,0,SU_PAY))   nSuDays,
                     sum(SU_PAY*BASIC_RATE)      nSuPay,
                     sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                     sum(HO_PAY*BASIC_RATE)      nHoPay,
                     sum(decode(HT_PAY,0,0,HT_PAY))   nHSDays,
                     sum(HT_PAY*BASIC_RATE)      nHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code, oport, basic_rate
             )
   loop

      if dEmplID = p_empl_id then
         dbms_output.put_line ('check: j.nNumDay=' || to_char(j.nNumDay) || ',j.dept_code=' || j.dept_code ||
                               ',j.dStart=' || to_char(j.dStart) || ',j.dEnd=' || to_char(j.dEnd) );
      end if;

      -- insert attendance summary
      if j.oport = 'Y' then
         --issue: for outer port (numdays should always be 15 if, with complete attendance) malabo to
         if j.nNumday >= ((p_date_to-p_date_fr)+1) and
            j.nActDay = ((p_date_to-p_date_fr)+1)
         then
            if p_isMonthly = 'Y' then      -- 15 plus sundays and holidays
               nDays := 15 + sf_count_sundays_op(p_empl_id, dPeriodFr, dPeriodTo, 'Y');
               sp_count_sundays_op(p_empl_id, dPeriodFr, dPeriodTo, 'N', nSundayOPDays, nSundayOPDate, nSundayOPRate );
               if nSundayOPDays > 0 then
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, nSundayOPDate, nSundayOPDate, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nSundayOPDays*nSundayOPRate, nSundayOPDays, nSundayOPRate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               end if;
            else
               nDays := j.nActDay;  -- outer port are based on actual days
            end if;
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP', nDays*j.basic_rate, nDays, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP', j.nSalaryR, j.nNumDay, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      else
         -- issue: monthly but non-managers re increases (numdays should always be 15 if, with complete attendance)
         if j.nNumday >= ((p_date_to-p_date_fr)+1) and
            j.nActDay = ((p_date_to-p_date_fr)+1) and
            p_isMonthly = 'Y'
         then
            nDays := 15 + sf_count_sundays_op(p_empl_id, dPeriodFr, dPeriodTo, 'N'); --(j.nNumday-j.nActDay);
            sp_count_sundays_op(p_empl_id, dPeriodFr, dPeriodTo, 'Y', nSundayOPDays, nSundayOPDate, nSundayOPRate );
            if nSundayOPDays > 0 then
               nSeqNo  := nSeqNo + 1;
               insert into pys_payroll_dtl
                  ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
               values ( p_payno, p_year, p_mon, nSundayOPDate, nSundayOPDate, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP', nSundayOPDays*nSundayOPRate, nSundayOPDays, nSundayOPRate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
            end if;
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nDays*j.basic_rate, nDays, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', j.nSalaryR, j.nNumDay, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      end if;
      if p_isMonthly = 'Y' then
         nMoTotalRec := nMoTotalRec + 1;
         nMoTotalDay := nMoTotalDay + j.nNumday;
      end if;
   end loop;

   -- check monthly employees with change in rate or title or dept.
   --IF ((TO_CHAR(p_date_to,'DD') = '31' and nMoTotalDay >= 15) or
   --    (TO_CHAR(p_date_to,'DD') = '30' and nMoTotalDay >= 15) or
   --    (TO_CHAR(p_date_to,'DD') = '29' and nMoTotalDay >= 14) or
   --    (TO_CHAR(p_date_to,'DD') = '28' and nMoTotalDay >= 13)) and
   --    nMoTotalRec > 1
   if p_dEmplID = p_empl_id then
      dbms_output.put_line('check MOnthly... nMoTotalRec=' || to_char(nMoTotalRec) || ',nMoTotalDay=' || to_char(nMoTotalDay));
   end if;
   IF nMoTotalRec > 1 and p_isMonthly = 'Y' THEN
      nMoTotalRec := 0;
      nMoTotalDay := 0;
      FOR i IN (SELECT period_fr, period_to, seq_no, empl_empl_id, no_days, basic_rate, basic_rate_g, paty_code
                FROM   pys_payroll_dtl
                WHERE  pahd_payroll_no = p_payno
                AND    empl_empl_id = p_empl_id
                ORDER  BY period_fr)
      LOOP
         if i.period_fr = p_date_fr then
            if to_char(i.period_fr, 'DD') = '01' then
               dTempFr := to_date(to_char(add_months(i.period_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
            else
               dTempFr := to_date(to_char(i.period_fr, 'YYYYMM') || '11', 'YYYYMMDD');
            end if;
         else
            dTempFr := i.period_fr;
         end if;

         if i.period_to = p_date_to then
            if to_char(i.period_to, 'DD') = '15' then
               dTempTo := to_date(to_char(i.period_to, 'YYYYMM') || '10', 'YYYYMMDD');
            else
               dTempTo := to_date(to_char(i.period_to, 'YYYYMM') || '25', 'YYYYMMDD');
            end if;
         else
            dTempTo := i.period_to;
         end if;

         if i.paty_code like 'REG-OP' then
            nDays := sf_count_sundays_op(p_empl_id, dTempFr, dTempTo, 'Y');
         else
            nDays := sf_count_sundays_op(p_empl_id, dTempFr, dTempTo, 'N');
         end if;
         if (nMoTotalDay + i.no_days) > 15 THEN
            nMoTotalRec := 15 - nMoTotalDay;
            nMoTotalDay := 15;
         else
            nMoTotalRec := i.no_days;
            nMoTotalDay := nMoTotalDay + i.no_days;
         end if;
         UPDATE pys_payroll_dtl
         SET    amt     = (nMoTotalRec+nDays) * i.basic_rate,
                no_days = nMoTotalRec+nDays
         WHERE  pahd_payroll_no = p_payno
         AND    empl_empl_id = p_empl_id
         AND    seq_no = i.seq_no;

         if p_dEmplID = p_empl_id then
            dbms_output.put_line('check MOnthly... nDays=' || to_char(nDays) || ',nMoTotalRec=' || to_char(nMoTotalRec) || ',i.no_days=' || to_char(i.no_days) || ',i.period_fr=' || to_char(i.period_fr) || ',i.period_to=' || to_char(i.period_to));
         end if;

      END LOOP;
   END IF;

   -- regular days (cola)
   nAlloCtr := 0;
   for j in ( select posi_code,
                     title,
                     dept_code,
                     min(pay_date) dStart,
                     max(pay_date) dEnd,
                     sum(cola_day) nColaDay,
                     sum(cola_pay) nColaPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    cola_pay > 0
              and    pay_date between p_date_fr and p_date_to
              group  by  posi_code, title, dept_code
             )
   loop

      if j.nColaPay > 0 and j.nColaDay > 0 then
         if p_isMonthly = 'Y' and j.nColaDay > 15 then
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', 15*(j.nColaPay/j.nColaDay), 15, j.nColaPay/j.nColaDay, j.dept_code, user, sysdate, 'ADD', vSalFreq );
            nTotalCola := 15;
         else
            if p_isMonthly = 'Y' and nAlloCtr = 0 then
               begin
                  select max(eff_st_date) into dAlloMaxDt
                  from   pys_employee_allowances
                  where  empl_empl_id = p_empl_id;
                  select amt
                  into   vAlloAmt
                  from   pys_employee_allowances
                  where  empl_empl_id = p_empl_id
                  and    eff_st_date=dAlloMaxDt
                  and    allo_code = 'ALLOW-OFC';
                  nColaPay := vAlloAmt*15;
                  nColaDay := 15;
                  nAlloCtr := nAlloCtr + 1;
               exception
                  when others then
                     nColaPay := j.nColaPay;
                     nColaDay := j.nColaDay;
               end;
            else
                  nColaPay := j.nColaPay;
                  nColaDay := j.nColaDay;
            end if;
            nSeqNo := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', nColaPay, nColaDay, nColaPay/nColaDay, j.dept_code, user, sysdate, 'ADD', vSalFreq );
            nTotalCola := nTotalCola + nColaDay;
         end if;
      end if;

   end loop;

   -- regular days (overtime)
   for j in ( select posi_code,
                     title,
                     decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE) basic_rate,
                     dept_code,
                     oport,
                     min(pay_date)               dStart,
                     max(pay_date)               dEnd,
                     sum(decode(nDays,0,0,1))    nActDay,
                     sum(nDays)                  nNumday,
                     sum(AMT)                    nSalaryR,
                     sum(decode(OT_PAY,0,0,OT_PAY))   nOtDays,
                     sum(OT_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nOtPay,
                     sum(decode(SU_PAY,0,0,SU_PAY))   nSuDays,
                     sum(SU_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nSuPay,
                     sum(decode(HO_PAY,0,0,HO_PAY))   nHoDays,
                     sum(HO_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHoPay,
                     sum(decode(HT_PAY,0,0,HT_PAY))   nHSDays,
                     sum(HT_PAY*decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE))      nHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dPeriodFr and dPeriodTo
              group  by  posi_code, title, dept_code, oport, decode(A_BASIC_RATE, 0, BASIC_RATE, A_BASIC_RATE)
             )
   loop

      if j.nOtPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-OFC', j.nOtPay, j.nOtDays, j.basic_rate*p_Overtm_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

      if j.nSuPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-SUN-OFC', j.nSuPay, j.nSuDays, j.basic_rate*p_Sunday_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

      if j.nHoPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-OFC', j.nHoPay, j.nHoDays, j.basic_rate*p_Holiday_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq  );
      end if;

      if j.nHSPay > 0 then
         nSeqNo := nSeqNo + 1;
         insert into pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
         values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-EXC', j.nHSPay, j.nHSDays, j.basic_rate*p_HolSun_RO, j.dept_code, user, sysdate, 'ADD', vSalFreq );
      end if;

   end loop;

   -- adjustments
   for j in ( select posi_code,
                     title,
                     dept_code,
                     oport,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate,
                     min(pay_date)                 dStart,
                     max(pay_date)                 dEnd,
                     sum(nDays)                    nNumday,
                     sum(AMT)                      nSalaryR,
                     0   nSuDays,
                     0   nSuPay,
                     0   nHoDays,
                     0   nHoPay,
                     0   nHSDays,
                     0   nHSPay,
                     sum(A_nDays)                  nANumday,
                     sum(A_AMT)                    nASalaryR,
                     0   nASuDays,
                     0   nASuPay,
                     0   nAHoDays,
                     0   nAHoPay,
                     0   nAHSDays,
                     0   nAHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dPeriodFr and (p_date_fr-1)
              and    a_ndays > 0
              and    a_amt <> 0
              group  by posi_code,
                     title,
                     dept_code,
                     oport,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate)
   loop
      -- insert attendance summary
      if j.basic_rate = 0 and j.a_basic_rate > 0 then

         if j.a_oport = 'Y' then
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            nSeqNo  := nSeqNo + 1;
            insert into pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      else
         if (j.basic_rate - j.a_basic_rate) <> 0 or (j.nNumDay-j.nANumday) <> 0 then
            if j.a_oport = 'Y' then
               if j.a_oport <> j.oport then
                  if (p_isMonthly = 'Y') and  TO_CHAR(j.dEnd,'DD') >= '28' then
                     if TO_CHAR(j.dEnd,'DD') = '31' then
                        nDays     := j.nANumday - 1;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR - j.basic_rate;
                        nASalaryR := j.nASalaryR - j.a_basic_rate;
                     elsif TO_CHAR(j.dEnd,'DD') < '30' then
                        nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                     else
                        nDays     := j.nANumday;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;
                  else
                     nDays     := j.nNumday;
                     nADays    := j.nANumday;
                     nSalaryR  := j.nSalaryR;
                     nASalaryR := j.nASalaryR;
                  end if;
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nADays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, 0, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               else
                  if j.basic_rate > 0 and j.a_basic_rate = 0 then
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, 0, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  else
                     if (p_isMonthly = 'Y') and  TO_CHAR(j.dEnd,'DD') >= '28' then
                        if TO_CHAR(j.dEnd,'DD') = '31' then
                           nDays     := j.nANumday - 1;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR - j.basic_rate;
                           nASalaryR := j.nASalaryR - j.a_basic_rate;
                        elsif TO_CHAR(j.dEnd,'DD') < '30' then
                           nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                           nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        else
                           nDays     := j.nANumday;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR;
                           nASalaryR := j.nASalaryR;
                        end if;
                     else
                        nDays     := j.nNumday;
                        nADays    := j.nANumday;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;

                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nADays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  end if;
               end if;
            else
              if j.a_oport <> j.oport then
                  if (p_isMonthly = 'Y') and  TO_CHAR(j.dEnd,'DD') >= '28' then
                     if TO_CHAR(j.dEnd,'DD') = '31' then
                        nDays     := j.nANumday - 1;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR - j.basic_rate;
                        nASalaryR := j.nASalaryR - j.a_basic_rate;
                     elsif TO_CHAR(j.dEnd,'DD') < '30' then
                        nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                     else
                        nDays     := j.nANumday;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;
                  else
                     nDays     := j.nNumday;
                     nADays    := j.nANumday;
                     nSalaryR  := j.nSalaryR;
                     nASalaryR := j.nASalaryR;
                  end if;

                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, decode(nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay,0,0,nADays+j.nASuDays+j.nAHoDays+j.nAHSDays), j.a_basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  nSeqNo  := nSeqNo + 1;
                  insert into pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', nSalaryR*-1, nDays*-1, j.basic_rate, 0, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               else
                  if j.basic_rate > 0 and j.a_basic_rate = 0 then
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, 0, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  else
                     if (p_isMonthly = 'Y') and  TO_CHAR(j.dEnd,'DD') >= '28' then
                        if TO_CHAR(j.dEnd,'DD') = '31' then
                           nDays     := j.nANumday - 1;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR - j.basic_rate;
                           nASalaryR := j.nASalaryR - j.a_basic_rate;
                        elsif TO_CHAR(j.dEnd,'DD') < '30' then
                           nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                           nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        else
                           nDays     := j.nANumday;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR;
                           nASalaryR := j.nASalaryR;
                        end if;
                     else
                        nDays     := j.nNumday;
                        nADays    := j.nANumday;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;

                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', (nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay), (nADays+j.nASuDays+j.nAHoDays+j.nAHSDays), j.a_basic_rate, 0, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                     nSeqNo  := nSeqNo + 1;
                     insert into pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, 0, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  end if;
               end if;
            end if;
         end if;
      end if;
   end loop;

   if p_isMonthly = 'Y' and nTotalCola > 15 then
      -- adjustment (cola)
      for j in ( select a_posi_code,
                        a_title,
                        a_dept_code,
                        a_basic_rate,
                        min(pay_date)   dStart,
                        max(pay_date)   dEnd,
                        sum(cola_day)   nColaDay,
                        sum(cola_pay)   nColaPay,
                        sum(a_cola_day) nAColaDay,
                        sum(a_cola_pay) nAColaPay
                 from   pys_payroll_dtl_log
                 where  empl_empl_id = p_empl_id
                 --and    (cola_day-a_cola_day) <> 0
                 and    pay_date between dPeriodFr and (p_date_fr-1)
                 group  by a_posi_code,
                        a_title,
                        a_dept_code,
                        a_basic_rate )
      loop
         if ((j.nAColaPay-j.nColaPay) <> 0) or ((j.nAColaDay-j.nColaDay) <> 0) then
            nSeqNo := nSeqNo + 1;
            if (p_isMonthly = 'Y') and TO_CHAR(j.dEnd,'DD') >= '28' then

               if p_dEmplID = p_empl_id then
                  dbms_output.put_line('Ano ba nagyari dito sa taas... dPeriodFr=' || to_char(dPeriodFr) || ',j.nAColaPay=' || to_char(j.nAColaPay) || ',j.nColaPay=' || to_char(j.nColaPay) ||
                                                                      ',j.nAColaDay=' || to_char(j.nAColaDay) || ',j.nColaDay=' || to_char(j.nColaDay));
               end if;

               if TO_CHAR(j.dEnd,'DD') = '31' then
                  nDays    := (greatest(j.nAColaDay-1,0)-(j.nColaDay-1));
                  if nDays = 0 then
                     nDays := greatest(j.nAColaDay-1,0);
                     nSalaryR := (j.nAColaPay-j.nColaPay)-((j.nAColaPay-j.nColaPay)/j.nAColaDay);
                  else
                     nSalaryR := nDays*((j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay));
                  end if;
               elsif TO_CHAR(j.dEnd,'DD') < '30' then
                  nDays    := (greatest(j.nAColaDay-(30-to_number(TO_CHAR(j.dEnd,'DD'))),0)-(j.nColaDay-(30-to_number(TO_CHAR(j.dEnd,'DD')))));
                  if nDays = 0 then
                     nDays := greatest(j.nAColaDay-(30-to_number(TO_CHAR(j.dEnd,'DD'))),0);
                     nSalaryR :=  (j.nAColaPay-j.nColaPay)-((j.nAColaPay-j.nColaPay)/j.nAColaDay);
                  else
                     nSalaryR :=  nDays*((j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay));
                  end if;
               else
                  nDays    := (j.nAColaDay-j.nColaDay);
                  nSalaryR := (j.nAColaPay-j.nColaPay);
               end if;

               if p_dEmplID = p_empl_id then
                  dbms_output.put_line('Ano ba nagyari dito sa baba... nDays=' || to_char(nDays) || ',nSalaryR=' || to_char(nSalaryR));
               end if;

               if nDays <> 0 then
                  insert into pys_payroll_dtl
                        ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', nSalaryR, nDays, nSalaryR/nDays, j.a_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
               end if;
            else
               if (j.nAColaDay-j.nColaDay) <> 0 then
                  insert into pys_payroll_dtl
                        ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', 'MONTHLY' );
               end if;
            end if;
            --insert into pys_payroll_dtl
            --      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
            --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
         end if;

      end loop;
   else
      -- compute cola adjustment for regular employees
      for j in ( select a_posi_code,
                        a_title,
                        a_dept_code,
                        a_basic_rate,
                        min(pay_date)   dStart,
                        max(pay_date)   dEnd,
                        sum(cola_day)   nColaDay,
                        sum(cola_pay)   nColaPay,
                        sum(a_cola_day) nAColaDay,
                        sum(a_cola_pay) nAColaPay
                 from   pys_payroll_dtl_log
                 where  empl_empl_id = p_empl_id
                 --and    (cola_day-a_cola_day) <> 0
                 and    pay_date between dPeriodFr and (p_date_fr-1)
                 group  by a_posi_code,
                        a_title,
                        a_dept_code,
                        a_basic_rate )
      loop
         if ((j.nAColaPay-j.nColaPay) <> 0) or ((j.nAColaDay-j.nColaDay) <> 0) then
            nSeqNo := nSeqNo + 1;
            if (j.nAColaDay-j.nColaDay) <> 0 then
               update pys_payroll_dtl
               set    amt = amt + (j.nAColaPay-j.nColaPay),
                      no_days = no_days + (j.nAColaDay-j.nColaDay)
               where  pahd_payroll_no = p_payno
               and    empl_empl_id = p_empl_id
               and    paty_code = 'COLA'
               and    basic_rate = (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay);
               if sql%notfound then
                  insert into pys_payroll_dtl
                        ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq )
                  values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nAColaPay-j.nColaPay, j.nAColaDay-j.nColaDay, (j.nAColaPay-j.nColaPay)/(j.nAColaDay-j.nColaDay), j.a_dept_code, user, sysdate, 'ADD', vSalFreq );
               end if;
            end if;
         end if;
      end loop;
   end if;

   p_o_seq_no    := nSeqNo;

exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);

end sp_count_ofc_attendance;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_OFC_ATTENDANCE_LOG"
(
   p_empl_id    in  varchar2,
   p_payno      in  number,
   p_year       in  varchar2,
   p_mon        in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_dept_code  in  varchar2,
   p_posi_code  in  varchar2,
   p_isMonthly  in  varchar2,    -- monthly but non-manager
   p_basic_r    in  number,
   p_basic_g    in  number,
   p_Overtm_RO  in  number,
   p_Sunday_RO  in  number,
   p_Holiday_RO in  number,
   p_HolSun_RO  in  number,
   p_Outer_RO   in  number,
   p_OutAd_RO   in  number,
   p_dEmplID    in  varchar2

) is

   dEmplID      varchar2(16) := p_dEmplID;
   vSalFreq     Varchar2(12);
   dAm_time_in  date;
   nNum_Hours   Number(12,5) := 0;
   nOT_Hours    Number(12,5) := 0;
   vOuter_Port  Varchar2(12);
   vIsOuterPort Varchar2(12);
   o_basic_r    Number(12,5) := 0;
   o_basic_g    Number(12,5) := 0;
   o_salfreq    Varchar2(12);
   o_ismanager  Varchar2(12);

   nBasicR      Number(12,5) := 0;
   nColaPay     Number(12,5) := 0;
   nColaDay     Number(12,5) := 0;
   nOvertm      Number(12,5) := 0;
   nRegHol      Number(12,5) := 0;
   nRegSun      Number(12,5) := 0;
   nRegDay      Number(12,5) := 0;
   nHolSun      Number(12,5) := 0;
   nHolOT       Number(12,5) := 0;
   nEnd         Number(12,5) := 0;
   dChkDate     Date;
   dTmpDate     Date;
   dStart       Date;
   dEnd         Date;
   dColaEff     Date;
   bWithCola    Boolean := FALSE;

begin

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dStart := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   else
      dStart := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   end if;

   if p_empl_id = dEmplID then
      dbms_output.put_line ('ofc 1: dEmplID=' || dEmplID || ', dStart: ' || to_char(dStart) || ', dEnd: ' || to_char(dEnd) || ',p_basic_r:' || to_char(p_basic_r) || ',p_basic_g:' || to_char(p_basic_g));
   end if;

   if p_isMonthly = 'Y' then
      vSalFreq := 'MONTHLY';
   else
      vSalFreq := 'SEMI-MO';
   end if;

   -- check every day
   nEnd := (p_date_to - dStart) + 1;
   for j in 1..nEnd loop
      dChkDate := (dStart-1) + j;
      if dChkDate <= dEnd then
         begin
            select am_time_in, num_hours, ot_hours, outer_port
            into   dAm_time_in, nNum_Hours, nOT_Hours, vOuter_Port
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dChkDate;

            if dEmplID = p_empl_id then
               dbms_output.put_line ('ofc 2: dChkDate= ' || to_char(dChkDate) || ',dAm_time_in=' || to_char(dAm_time_in) ||
                                     ',nNum_Hours=' || to_char(nNum_Hours) ||
                                     ',vOuter_Port=' || vOuter_Port || ',vIsOuterPort=' || vIsOuterPort );
            end if;
         exception
            when no_data_found then
               nNum_Hours  := 0;
               nOT_Hours   := 0;
               vOuter_Port := 'N';
               -- check if assumed days... 11-15 and 26-31
               if dChkDate < p_date_fr and p_isMonthly = 'N'  then
                  begin
                     select oport
                     into   vOuter_Port
                     from   pys_payroll_dtl_log
                     where  empl_empl_id = p_empl_id
                     and    pay_date = dChkDate;
                     if vOuter_Port = 'Y' then
                        vOuter_Port := 'N';
                        nColaPay := sf_get_latest_cola (p_empl_id, dChkDate);
                        if nColaPay > 0 then
                           nColaDay := 1;
                           update pys_payroll_dtl_log
                           set    a_dept_code    = dept_code,
                                  a_posi_code    = posi_code,
                                  a_ndays        = 1,
                                  a_amt          = 0,
                                  a_amt_g        = 0,
                                  cola_day       = 0,
                                  cola_pay       = 0,
                                  a_cola_day     = nColaDay*-1,
                                  a_cola_pay     = nColaPay*-1,
                                  modified_by  = user,
                                  dt_modified  = sysdate
                           where empl_empl_id = p_empl_id
                           and   pay_date = dChkDate;
                        else
                           update pys_payroll_dtl_log
                           set    a_dept_code    = dept_code,
                                  a_posi_code    = posi_code,
                                  a_ndays        = 1,
                                  a_amt          = 0,
                                  a_amt_g        = 0,
                                  modified_by  = user,
                                  dt_modified  = sysdate
                           where empl_empl_id = p_empl_id
                           and   pay_date = dChkDate;
                        end if;
                     elsif (sf_is_sunday (dChkDate) = 0 or sf_is_holiday (dChkDate) = 0 ) then
                        vOuter_Port := 'N';
                        nColaPay := sf_get_latest_cola (p_empl_id, dChkDate);
                        if nColaPay > 0 then
                           nColaDay := 1;
                           update pys_payroll_dtl_log
                           set    a_dept_code    = dept_code,
                                  a_posi_code    = posi_code,
                                  a_ndays        = 1,
                                  a_amt          = amt*-1,
                                  a_amt_g        = amt_g*-1,
                                  cola_day       = 0,
                                  cola_pay       = 0,
                                  a_cola_day     = nColaDay*-1,
                                  a_cola_pay     = nColaPay*-1,
                                  modified_by  = user,
                                  dt_modified  = sysdate
                           where empl_empl_id = p_empl_id
                           and   pay_date = dChkDate;
                        else
                           update pys_payroll_dtl_log
                           set    a_dept_code    = dept_code,
                                  a_posi_code    = posi_code,
                                  a_ndays        = 1,
                                  a_amt          = 0,
                                  a_amt_g        = 0,
                                  modified_by  = user,
                                  dt_modified  = sysdate
                           where empl_empl_id = p_empl_id
                           and   pay_date = dChkDate;
                        end if;
                     end if;
                  exception
                     when no_data_found then null;
                  end;
               end if;
            when others then
               raise_application_error (-20001, 'Error on sp_count_ofc_attendance_log-get employee attendance' || p_empl_id || ' ' || SQLERRM);
         end;
      else
         vOuter_Port := nvl(vIsOuterPort, 'N');
         if nvl(vIsOuterPort,'N') = 'Y' then
            nNum_Hours  := 8;
            nOT_Hours   := 0;
         elsif sf_is_sunday (dChkDate) = 0 then
            nNum_Hours  := 8;
            nOT_Hours   := 0;
         else
            nNum_Hours  := 0;
            nOT_Hours   := 0;
         end if;
      end if;

      if dEmplID = p_empl_id then
         dbms_output.put_line ('ofc 3: dChkDate= ' || to_char(dChkDate) || ',dAm_time_in=' || to_char(dAm_time_in) ||
                               ',nNum_Hours=' || to_char(nNum_Hours) || ',nOT_Hours=' || to_char(nOT_Hours) ||
                               ',vOuter_Port=' || vOuter_Port || ',vIsOuterPort=' || vIsOuterPort );
      end if;

      if nNum_Hours > 0 then
         if sf_is_sunday (dChkDate) = 1 then
            if sf_is_holiday (dChkDate) = 1 then
               if dAm_time_in is not null then
                  if nNum_Hours >= 4  then
                     nRegDay := 1;
                     nRegHol := 1;
                     nHolOT  := (nOT_Hours/8);
                  else
                     nRegDay := 1;
                     nRegHol := (nNum_Hours/4);
                  end if;
               else
                  nRegDay := 1;
               end if;
            else
               if nNum_Hours >= 4  then
                  nRegDay := 1;
                  if p_IsMonthly='N' and vOuter_Port='N' then
                     nRegSun := (nOT_Hours/8);
                  end if;
               else
                  nRegDay := nRegDay + (nNum_Hours/4);
               end if;
            end if;
         elsif sf_is_holiday (dChkDate) = 1 then
            if dAm_time_in is not null then
               nRegDay := 1;
               if nNum_Hours >= 6  then
                  nRegHol := 1;
                  nHolOT := (nOT_Hours/8);
               else
                  nRegHol := (nNum_Hours/6);
               end if;
            else
               nRegDay := 1;
            end if;
         else
            -- Overtime
            if nNum_Hours >= 8  then
               nRegDay := 1;
            else
               nRegDay := (nNum_Hours/8);
            end if;
            nOvertm := (nOT_Hours/8);
         end if;
         bWithCola := TRUE;
      else
         if sf_is_holiday (dChkDate) = 1 then
            nRegDay := 1;
            bWithCola := FALSE;
         end if;

         -- Monthly but non-managers (sundays are counted)
         if p_isMonthly = 'Y' and (sf_is_sunday (dChkDate) = 1) then
            nRegDay := 1;
            bWithCola := FALSE;
         end if;
      end if;

      nOvertm  := ( p_Overtm_RO  * nOvertm );
      nRegSun  := ( p_Sunday_RO  * nRegSun );
      nRegHol  := ( p_Holiday_RO * nRegHol );
      nHolOT   := ( p_HolSun_RO  * nHolOT );

      if dChkDate < dEnd then
         sp_latest_get_basic_rate (p_empl_id, dChkDate, o_basic_r, o_basic_g, o_salfreq, o_ismanager);
      else
         sp_latest_get_basic_rate (p_empl_id, dEnd, o_basic_r, o_basic_g, o_salfreq, o_ismanager);
      end if;
      if vOuter_Port = 'Y' then
         nBasicR  := p_Outer_RO * o_basic_r;
      else
         nBasicR  := o_basic_r;
      end if;

      if (nRegDay+nOvertm+nRegSun+nRegHol+nHolOT) > 0 then

         -- check if with cola
         if bWithCola then
            sp_get_latest_cola (p_empl_id, dChkDate, nColaPay, dColaEff);
            if nColaPay > 0 and dColaEff <= dEnd then
               nColaDay := 1;
               if nRegDay < 1 then
                  nColaDay := nRegDay;
                  nColaPay := nColaPay*nColaDay;
               end if;
            else
               nColaPay := 0;
               nColaDay := 0;
            end if;
         else
            nColaPay := 0;
            nColaDay := 0;
         end if;

         if dEmplID = p_empl_id then
            dbms_output.put_line ('check: nRegDay=' || to_char(nRegDay) || ',nRegSun=' || to_char(nRegSun) || ',nRegHol =' || to_char(nRegHol ) ||
                                  ',nOvertm=' || to_char(nOvertm) || ',nHolOT=' || to_char(nHolOT) || ',nCola=' || to_char(nColaPay) ||
                                  ',nBasicR =' || to_char(nBasicR ) || ',o_basic_r =' || to_char(o_basic_r ));
         end if;

         -- create payroll log
         if dChkDate < p_date_fr then    -- check assumed dates from previous payroll
            update pys_payroll_dtl_log
            set    dept_code      = nvl(dept_code,p_dept_code),
                   a_dept_code    = p_dept_code,
                   a_posi_code    = p_posi_code,
                   a_basic_rate   = nBasicR,
                   a_basic_rate_g = o_basic_g,
                   a_ndays        = nRegDay,
                   a_amt          = nBasicR*nRegDay,
                   a_amt_g        = o_basic_g/2,
                   ot_pay         = nOvertm,
                   ht_pay         = nHolOT,
                   su_pay         = nRegSun,
                   ho_pay         = nRegHol,
                   hs_pay         = 0,
                   a_oport        = vOuter_Port,
                   a_cola_pay     = nColaPay,
                   a_cola_day     = nColaDay,
                   modified_by    = user,
                   dt_modified    = sysdate
            where empl_empl_id = p_empl_id
            and   pay_date = dChkDate;
            if sql%NOTFOUND then
               insert into pys_payroll_dtl_log
                      ( payroll_no, empl_empl_id, pay_date, dept_code, a_dept_code, a_posi_code, sal_freq,
                        a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, ot_pay, hs_pay, oport,
                        su_pay, ho_pay, ht_pay, a_cola_pay, a_cola_day, a_ndays, created_by, dt_created
                      )
               values ( p_payno, p_empl_id, dChkDate, p_dept_code, p_dept_code, p_posi_code, vSalFreq,
                        nBasicR, o_basic_g, nBasicR*nRegDay, o_basic_g/2, nOvertm, 0, vOuter_Port,
                        nRegSun, nRegHol, nHolOT, nColaPay, nColaDay, nRegDay, user, sysdate
                      );
            end if;
         else

            begin
               insert into pys_payroll_dtl_log
                      ( payroll_no, empl_empl_id, pay_date, dept_code, posi_code, sal_freq,
                        basic_rate, basic_rate_g, amt, amt_g, ot_pay, hs_pay, oport,
                        su_pay, ho_pay, ht_pay, cola_pay, cola_day, ndays, created_by, dt_created
                      )
               values ( p_payno, p_empl_id, dChkDate, p_dept_code, p_posi_code, vSalFreq,
                        nBasicR, o_basic_g, nBasicR*nRegDay, o_basic_g/2, nOvertm, 0, vOuter_Port,
                        nRegSun, nRegHol, nHolOT, nColaPay, nColaDay, nRegDay, user, sysdate
                      );
            exception
               when dup_val_on_index then
                  update pys_payroll_dtl_log
                  set    dept_code    = p_dept_code,
                         posi_code    = p_posi_code,
                         basic_rate   = nBasicR,
                         basic_rate_g = o_basic_g,
                         ndays        = nRegDay,
                         amt          = nBasicR*nRegDay,
                         amt_g        = o_basic_g/2,
                         ot_pay       = nOvertm,
                         ht_pay       = nHolOT,
                         oport        = vOuter_Port,
                         su_pay       = nRegSun,
                         ho_pay       = nRegHol,
                         hs_pay       = 0,
                         cola_pay     = nColaPay,
                         cola_day     = nColaDay,
                         modified_by  = user,
                         dt_modified  = sysdate
                  where empl_empl_id = p_empl_id
                  and   pay_date = dChkDate;
            end;
         end if; -- <if dChkDate < p_date_fr then>
      end if; -- <(nRegDay+nOvertm+nRegSun+nRegHol+nHolOT) > 0>

      if dChkDate = dEnd then
         vIsOuterPort := vOuter_Port;
      end if;

      -- reset variables
      dAm_time_in := null;
      nNum_Hours  := 0;
      nOT_Hours   := 0;
      vOuter_Port := 'N';
      nOvertm     := 0;
      nRegDay     := 0;
      nRegSun     := 0;
      nRegHol     := 0;
      nHolOT      := 0;
      nBasicR     := 0;
      nColaPay    := 0;
      nColaDay    := 0;
      o_basic_r   := 0;
      o_basic_g   := 0;

   end loop; -- <for j in 1..nEnd loop>

end sp_count_ofc_attendance_log;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_OFC_ATT_TEST"
(
   p_empl_id    in  varchar2,
   p_date_fr    in  date,
   p_date_to    in  date,
   p_isMonthly  in  varchar2    -- monthly but non-manager

) is

   dEmplID      varchar2(16) := p_empl_id;
   nDays        Number(10,5) := 0;
   nADays       Number(10,5) := 0;
   nSalaryR     Number(12,4) := 0;
   nASalaryR    Number(12,4) := 0;
   nSeqNo       Number;
   vSalFreq     Varchar2(12);
   dPeriodFr    Date;
   dPeriodTo    Date;
   dTempFr      Date;
   dTempTo      Date;
   bIsEndOfMonth Boolean;
   nSundayOPDays Number(10,5) := 0;
   nSundayOPDate Date;
   nSundayOPRate Number(12,4) := 0;
   nTotalCola    Number(12,4) := 0;
   nMoTotalRec  Number(12,4)  := 0;
   nMoTotalDay  Number(12,4)  := 0;
   nAlloCtr   Number;
   dAlloMaxDt Date;
   vAlloAmt   NUmber(12,4);
   nColaPay   Number(12,4);
   nColaDay   Number(12,4);

begin

   nSeqNo := 1;

   -- set cutoff date
   if to_char(p_date_fr, 'DD') = '01' then
      dPeriodFr := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   else
      dPeriodFr := to_date(to_char(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dPeriodTo := to_date(to_char(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   end if;

   if p_isMonthly = 'Y' then
      vSalFreq := 'MONTHLY';
   else
      vSalFreq := 'SEMI-MO';
   end if;

   -- adjustments
   for j in ( select posi_code,
                     title,
                     dept_code,
                     oport,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate,
                     min(pay_date)                 dStart,
                     max(pay_date)                 dEnd,
                     sum(nDays)                    nNumday,
                     sum(AMT)                      nSalaryR,
                     0   nSuDays,
                     0   nSuPay,
                     0   nHoDays,
                     0   nHoPay,
                     0   nHSDays,
                     0   nHSPay,
                     sum(A_nDays)                  nANumday,
                     sum(A_AMT)                    nASalaryR,
                     0   nASuDays,
                     0   nASuPay,
                     0   nAHoDays,
                     0   nAHoPay,
                     0   nAHSDays,
                     0   nAHSPay
              from   pys_payroll_dtl_log
              where  empl_empl_id = p_empl_id
              and    pay_date between dPeriodFr and (p_date_fr-1)
              and    a_ndays > 0
              group  by posi_code,
                     title,
                     dept_code,
                     oport,
                     basic_rate,
                     a_posi_code,
                     a_title,
                     a_dept_code,
                     a_oport,
                     a_basic_rate)
   loop
      -- insert attendance summary
      if j.basic_rate = 0 and j.a_basic_rate > 0 then

         if j.a_oport = 'Y' then
            dbms_output.put_line('insert on adjustment if (j.basic_rate = 0 and j.a_basic_rate > 0):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
            --nSeqNo  := nSeqNo + 1;
            --insert into pys_payroll_dtl
            --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         else
            dbms_output.put_line('insert on adjustment else (j.basic_rate = 0 and j.a_basic_rate > 0):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
            --nSeqNo  := nSeqNo + 1;
            --insert into pys_payroll_dtl
            --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
            --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.nANumDay+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
         end if;
      else
         if (j.basic_rate - j.a_basic_rate) <> 0 or (j.nNumDay-j.nANumday) <> 0 then
            if j.a_oport = 'Y' then
               if j.a_oport <> j.oport then
                  if (p_isMonthly = 'Y') and  (TO_CHAR(j.dEnd,'DD') >= '28') and (TO_CHAR(j.dEnd,'DD') = TO_CHAR(last_day(j.dEnd),'DD')) then
                     if TO_CHAR(j.dEnd,'DD') = '31' then
                        nDays     := j.nANumday - 1;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR - j.basic_rate;
                        nASalaryR := j.nASalaryR - j.a_basic_rate;
                     elsif TO_CHAR(j.dEnd,'DD') < '30' then
                        nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                     else
                        nDays     := j.nANumday;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;
                  else
                     nDays     := j.nNumday;
                     nADays    := j.nANumday;
                     nSalaryR  := j.nSalaryR;
                     nASalaryR := j.nASalaryR;
                  end if;
                  dbms_output.put_line('insert on adjustment if (j.a_oport <> j.oport):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
                  --nSeqNo  := nSeqNo + 1;
                  --insert into pys_payroll_dtl
                  --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nADays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  --nSeqNo  := nSeqNo + 1;
                  --insert into pys_payroll_dtl
                  --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               else
                  if j.basic_rate > 0 and j.a_basic_rate = 0 then
                     dbms_output.put_line('insert on adjustment if (j.basic_rate > 0 and j.a_basic_rate = 0):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
                     --nSeqNo  := nSeqNo + 1;
                     --insert into pys_payroll_dtl
                     --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  else
                     if (p_isMonthly = 'Y') and  TO_CHAR(j.dEnd,'DD') >= '28' then
                        if TO_CHAR(j.dEnd,'DD') = '31' then
                           nDays     := j.nANumday - 1;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR - j.basic_rate;
                           nASalaryR := j.nASalaryR - j.a_basic_rate;
                        elsif TO_CHAR(j.dEnd,'DD') < '30' then
                           nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                           nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        else
                           nDays     := j.nANumday;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR;
                           nASalaryR := j.nASalaryR;
                        end if;
                     else
                        nDays     := j.nNumday;
                        nADays    := j.nANumday;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;

                     dbms_output.put_line('insert on adjustment else (j.basic_rate > 0 and j.a_basic_rate = 0):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
                     --nSeqNo  := nSeqNo + 1;
                     --insert into pys_payroll_dtl
                     --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nADays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                     --nSeqNo  := nSeqNo + 1;
                     --insert into pys_payroll_dtl
                     --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  end if;
               end if;
            else
              if j.a_oport <> j.oport then
                  if (p_isMonthly = 'Y') and  (TO_CHAR(j.dEnd,'DD') >= '28') and (TO_CHAR(j.dEnd,'DD') = TO_CHAR(last_day(j.dEnd),'DD')) then
                     if TO_CHAR(j.dEnd,'DD') = '31' then
                        nDays     := j.nANumday - 1;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR - j.basic_rate;
                        nASalaryR := j.nASalaryR - j.a_basic_rate;
                     elsif TO_CHAR(j.dEnd,'DD') < '30' then
                        nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                     else
                        nDays     := j.nANumday;
                        nADays    := nDays;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;
                  else
                     nDays     := j.nNumday;
                     nADays    := j.nANumday;
                     nSalaryR  := j.nSalaryR;
                     nASalaryR := j.nASalaryR;
                  end if;

                  dbms_output.put_line('insert on adjustment (j.a_oport <> j.oport):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
                  --nSeqNo  := nSeqNo + 1;
                  --insert into pys_payroll_dtl
                  --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-OP-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, decode(nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay,0,0,nADays+j.nASuDays+j.nAHoDays+j.nAHSDays), j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  --nSeqNo  := nSeqNo + 1;
                  --insert into pys_payroll_dtl
                  --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                  --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-OP-ADJ', nSalaryR*-1, nDays*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
               else
                  if j.basic_rate > 0 and j.a_basic_rate = 0 then
                     dbms_output.put_line('insert on adjustment if (j.basic_rate > 0 and j.a_basic_rate = 0):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
                     --nSeqNo  := nSeqNo + 1;
                     --insert into pys_payroll_dtl
                     --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (j.nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (j.nNumDay+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2*-1, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  else
                     if (p_isMonthly = 'Y') and  (TO_CHAR(j.dEnd,'DD') >= '28') and (TO_CHAR(j.dEnd,'DD') = TO_CHAR(last_day(j.dEnd),'DD')) then
                        if TO_CHAR(j.dEnd,'DD') = '31' then
                           nDays     := j.nANumday - 1;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR - j.basic_rate;
                           nASalaryR := j.nASalaryR - j.a_basic_rate;
                        elsif TO_CHAR(j.dEnd,'DD') < '30' then
                           nDays     := j.nANumday  + (30-to_number(TO_CHAR(j.dEnd,'DD')));
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR + (j.basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                           nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-to_number(TO_CHAR(j.dEnd,'DD'))));
                        else
                           nDays     := j.nANumday;
                           nADays    := nDays;
                           nSalaryR  := j.nSalaryR;
                           nASalaryR := j.nASalaryR;
                        end if;
                     else
                        nDays     := j.nNumday;
                        nADays    := j.nANumday;
                        nSalaryR  := j.nSalaryR;
                        nASalaryR := j.nASalaryR;
                     end if;

                     dbms_output.put_line('insert on adjustment else (j.basic_rate > 0 and j.a_basic_rate = 0):' || to_char(nDays) || ',' || to_char(nADays) || ',' || to_char(nSalaryR) || ',' || to_char(nASalaryR) );
                     --nSeqNo  := nSeqNo + 1;
                     --insert into pys_payroll_dtl
                     --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', (nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay), (nADays+j.nASuDays+j.nAHoDays+j.nAHSDays), j.a_basic_rate, p_basic_g/2, p_basic_g, j.a_dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                     --nSeqNo  := nSeqNo + 1;
                     --insert into pys_payroll_dtl
                     --       ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq )
                     --values ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, p_basic_g/2, p_basic_g, j.dept_code, user, sysdate, 'ADD', 'N', vSalFreq );
                  end if;
               end if;
            end if;
         end if;
      end if;
   end loop;


exception
   when others then
      raise_application_error (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);

end sp_count_ofc_att_test;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_COUNT_SUNDAYS_OP"
(
   p_empl_id in  varchar2,
   p_date_fr in  date,
   p_date_to in  date,
   p_outer   in  varchar2,
   p_days    out number,
   p_date    out date,
   p_rate    out number
) is
   dChkDate     Date;
   dLastSunday  Date;
   nCtr  Number := 0;
   nUpTO Number := 0;
   nDummy Number;
   nBasic  Number(12,4);
begin
   nUpTo := (p_date_to-p_date_fr)+1;
   dChkDate := p_date_fr -1;
   for i in 1..nUpTo loop
      dChkDate := dChkDate + 1;
      if sf_is_sunday (dChkDate) = 1 then
         begin
            select num_hours
            into   nDummy
            from   pms_attendance_records
            where  empl_empl_id = p_empl_id
            and    att_date = dChkDate
            and    outer_port = p_outer;
            nCtr := nCtr + 1;
            dLastSunday := dChkDate;
         exception
            when no_data_found then null;
         end;
      end if;
   end loop;

   if nCtr > 0 then
      begin
         select nvl(a_basic_rate,basic_rate)
         into   nBasic
         from   pys_payroll_dtl_log
         where  empl_empl_id = p_empl_id
         and    pay_date = dLastSunday;
      exception
         when no_data_found then nBasic := 0;
      end;
   end if;

   p_days := nCtr;
   p_date := dLastSunday;
   p_rate := nBasic;

end sp_count_sundays_op;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_CREW_ON_LAOT" (
   p_asof   Date )
   as
   dP_Start Date;
   dStart   Date;
   dEnd     Date;
   nMos     Number := 0;
   vMinVess Varchar2(16);
   vMintitl Varchar2(60);
   vMinDate Date;
   vMaxVess Varchar2(16);
   vMaxtitl Varchar2(60);
   vMaxDate Date;
   bOneYear Boolean;
   bRegenerate Boolean;
   nCnt     Number;
   dCreated Date;
begin
   select count(1), trunc(max(dt_created))
   into   nCnt, dCreated
   from   pms_crew_on_laot
   where  dt_asof = p_asof;

   bRegenerate := TRUE;
   if nCnt > 0 then
      if dCreated = trunc(sysdate) then
         bRegenerate := FALSE;
      else
         delete from pms_crew_on_laot
         where dt_asof = p_asof;
      end if;
   end if;

   if bRegenerate then
      dP_Start := add_months(p_asof, -12);
      for i in (select empl_empl_id, min(dt_embarked) dt_embarked from (
                select empl_empl_id, max(dt_embarked) dt_embarked
                from   cms_voyage_crew
                where  dt_embarked <= dP_Start
                group  by empl_empl_id
                union
                select empl_empl_id, min(dt_embarked) dt_embarked
                from   cms_voyage_crew
                where  dt_embarked >= dP_Start
                group  by empl_empl_id )
                group  by empl_empl_id)
      loop
         for j in (select voya_vess_code, title, dt_embarked, dt_disembarked
                   from   cms_voyage_crew
                   where  empl_empl_id = i.empl_empl_id
                   and    dt_embarked >= i.dt_embarked
                   order  by dt_embarked )
         loop
            if dStart is null then
               dStart   := j.dt_embarked;
               dEnd     := j.dt_disembarked;
               vMinVess := j.voya_vess_code;
               vMintitl := j.title;
               vMinDate := j.dt_embarked;
            else
               if (dEnd+1) <> j.dt_embarked then
                  bOneYear := FALSE;
                  exit;
               else
                  bOneYear := TRUE;
                  dStart := j.dt_embarked;
                  dEnd   := j.dt_disembarked;
               end if;
            end if;
            nMos := nMos + months_between(nvl(j.dt_disembarked,p_asof), j.dt_embarked);
            vMaxVess := j.voya_vess_code;
            vMaxtitl := j.title;
            vMaxDate := j.dt_embarked;
            if p_asof < j.dt_embarked then
               exit;
            end if;
            if (j.dt_disembarked is not null) and (p_asof < j.dt_disembarked) then
               exit;
            end if;
         end loop;
         if bOneYear and nMos >= 12 then
            insert into pms_crew_on_laot (dt_asof, empl_empl_id, earliest_vess_code, earliest_title, earliest_dt_embarked,
                                                                 latest_vess_code, latest_title, latest_dt_embarked, dt_created )
            values (p_asof, i.empl_empl_id, vMinVess, vMintitl, vMinDate, vMaxVess, vMaxtitl, vMaxDate, sysdate );
         end if;
         -- reset values
         dStart   := null;
         dEnd     := null;
         nMos     := 0;
         vMinVess := null;
         vMintitl := null;
         vMinDate := null;
         vMaxVess := null;
         vMaxtitl := null;
         vMaxDate := null;
         bOneYear := FALSE;
      end loop;
   end if;
   commit;
end sp_crew_on_laot;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GENERATE_PACKING_LIST" (p_tran_no in varchar2) as
begin
   insert into inv_packing_list_dtl (TRAN_NO, WTS_TRAN_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE, QTY, APPROVED_QTY, VESS_CODE, REMARKS, CREATED_BY, DT_CREATED)
   select p_tran_no, d.TRAN_NO, d.ITEM_CODE, d.ITTY_CODE, d.CATE_CODE, d.ITGR_CODE, d.UOME_CODE, d.QTY, d.APPROVED_QTY, d.VESS_CODE, d.REMARKS, user, sysdate
   from   inv_ware_transfer_dtl d, inv_ware_transfer_hdr h
   where  d.tran_no = h.tran_no
   and    h.status = 'APPROVED'
   and    d.pl_tran_no is null;

   update inv_ware_transfer_dtl
   set    pl_tran_no = p_tran_no
   where  pl_tran_no is null
   and    exists (select 1 from inv_ware_transfer_hdr h where h.status = 'APPROVED' and inv_ware_transfer_dtl.tran_no = h.tran_no);

   commit;
end sp_generate_packing_list;


 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_BASIC_RATE" (
   p_empl_id in varchar2,
   p_date_fr in date,
   p_date_to in date,
   p_basic_r out number,
   p_basic_g out number,
   p_salfreq out varchar,
   p_ismanager out varchar
  )  is

   cursor x is
   select eff_st_date, eff_en_date, basic_rate, basic_rate_g, sal_freq
   from   pys_employee_salary
   --where  eff_st_date >= p_date_fr
   where eff_st_date <= p_date_fr --modified by thess 1/7/2008
   and     empl_empl_id = p_empl_id
   order  by eff_st_date;

   cursor y is
   select eff_st_date, eff_en_date, basic_rate, basic_rate_g, sal_freq
   from   pys_employee_salary
   where  empl_empl_id = p_empl_id
   and eff_en_date is null -- added by thess 1/7/2008
   order  by eff_st_date desc;

   nBasicR    Number(8,2);
   nBasicG    Number(8,2);
   vSalFreq   Varchar2(16);
   vIsManager Varchar2(1);
begin

   for i in (select eff_st_date, basic_rate, basic_rate_g, sal_freq, is_manager
             from   pys_employee_salary
             where  empl_empl_id = p_empl_id
             order  by eff_st_date desc
             )
   loop
      if p_date_to >= i.eff_st_date then
         nBasicR    := i.basic_rate;
         nBasicG    := i.basic_rate_g;
         vSalFreq   := i.sal_freq;
         vIsManager := i.is_manager;
         exit;
      end if;
   end loop;

   p_basic_r   := nvl(nBasicR,0);
   p_basic_g   := nvl(nBasicG,0);
   p_salfreq   := nvl(vSalFreq,'SEMI-MO');
   p_ismanager := nvl(vIsManager,'N');
end sp_get_basic_rate;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_FLT_OT_RATES" (
   p_sun out number,
   p_hol out number,
   p_hs  out number
  ) is

   nSundayR     Number(6,3);
   nHolidayR    Number(6,3);
   nHolSunR     Number(6,3);

begin
   begin
      select rate into nSundayR from pys_payroll_types where code = 'OT-SUN-FLT';
   exception
      when no_data_found then nSundayR := 0;
   end;

   begin
      select rate into nHolidayR from pys_payroll_types where code = 'OT-HOL-FLT';
   exception
      when no_data_found then nHolidayR := 0;
   end;

   begin
      select rate into nHolSunR from pys_payroll_types where code = 'OT-HS-FLT';
   exception
      when no_data_found then nHolSunR := 0;
   end;

   p_sun := nSundayR;
   p_hol := nHolidayR;
   p_hs  := nHolSunR;

end sp_get_flt_ot_rates;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_LATEST_COLA" (
   p_empl_id in  varchar2,
   p_date_fr in  date,
   p_cola    out number,
   p_eff     out date
  )  as
  nAmt  Number(12,2);
  dEff  Date;
begin
   -- get latest record
   select sum(amt), max(eff_st_date)
   into   nAmt, dEff
   from   pys_employee_allowances
   where  empl_empl_id = p_empl_id
   and    eff_st_date = (select max(eff_st_date)
                      from pys_employee_salary
                      where empl_empl_id = p_empl_id
                      and eff_st_date < p_date_fr+1);

   p_cola := nvl(nAmt,0);
   p_eff  := trunc(dEff);
exception
   when no_data_found then
      p_cola := nvl(nAmt,0);
      p_eff  := trunc(dEff);
   when others then
      raise_application_error (-20001, 'Error on sf_get_latest_colafor employee ' || p_empl_id || ' ' || SQLERRM);
end SP_GET_LATEST_COLA;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_OFC_OT_RATES" (
   p_ot  out number,
   p_sun out number,
   p_hol out number,
   p_hs  out number,
   p_outer out number,
   p_outad out number
  ) is

   nOtR         Number(6,3);
   nSundayR     Number(6,3);
   nHolidayR    Number(6,3);
   nHolSunR     Number(6,3);
   nOuterR      Number(6,3);
   nOutAdR      Number(6,3);

begin
   begin
      select rate into nOtR from pys_payroll_types where code = 'OT-OFC';
   exception
      when no_data_found then nOtR:= 0;
   end;

   begin
      select rate into nSundayR from pys_payroll_types where code = 'OT-SUN-OFC';
   exception
      when no_data_found then nSundayR := 0;
   end;

   begin
      select rate into nHolidayR from pys_payroll_types where code = 'OT-HOL-OFC';
   exception
      when no_data_found then nHolidayR := 0;
   end;

   begin
      select rate into nHolSunR from pys_payroll_types where code = 'OT-HOL-EXC';
   exception
      when no_data_found then nHolSunR := 0;
   end;

   begin
      select rate into nOuterR from pys_payroll_types where code = 'REG-OP';
   exception
      when no_data_found then nOuterR := 0;
   end;

   begin
      select rate into nOutAdR from pys_payroll_types where code = 'REG-OP-ADJ';
   exception
      when no_data_found then nOutAdR := 0;
   end;

   p_ot  := nOtR;
   p_sun := nSundayR;
   p_hol := nHolidayR;
   p_hs  := nHolSunR;
   p_outer := nOuterR;
   p_outad := nOutAdR;

end sp_get_ofc_ot_rates;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_OT_RATES" (
   p_reg out number,
   p_sun out number,
   p_hol out number,
   p_hs  out number
  ) is

   nOtR         Number(6,3);
   nSundayR     Number(6,3);
   nHolidayR    Number(6,3);
   nHolSunR     Number(6,3);

begin
   begin
      select rate into nOtR from pys_payroll_types where code = 'OT';
   exception
      when no_data_found then nOtR:= 0;
   end;

   begin
      select rate into nSundayR from pys_payroll_types where code = 'OT-SUN';
   exception
      when no_data_found then nSundayR := 0;
   end;

   begin
      select rate into nHolidayR from pys_payroll_types where code = 'OT-HOL';
   exception
      when no_data_found then nHolidayR := 0;
   end;

   begin
      select rate into nHolSunR from pys_payroll_types where code = 'OT-HS';
   exception
      when no_data_found then nHolSunR := 0;
   end;

   p_reg := nOtR;
   p_sun := nSundayR;
   p_hol := nHolidayR;
   p_hs  := nHolSunR;

end sp_get_ot_rates;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_PAGIBIG_CONTRIBUTION"
   ( p_salary in number,
     p_ee out number,
     p_er out number
   ) is
   nEE Number;
   nER Number;
begin
   if p_salary > 5000 then
      nEE := 100;
      nER := 100;
   elsif p_salary >= 2500 and p_salary <= 5000 then
      nEE := p_salary * .01;
      nER := p_salary * .02;
   else
      nEE := 25;
      nER := 50;
   end if;
   p_ee := nEE;
   p_er := nER;
end sp_get_pagibig_contribution;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_PAGIBIG_EE_ER"
   ( p_salary in  number,
     p_ee     out number,
     p_er     out number
   )
   is
   nEE Number;
   nER Number;
begin

   if p_salary >= 5000 then
      nEE := 100;
      nER := 100;
   --elsif p_salary > 2500 and p_salary < 5000 then
   elsif p_salary >= 1501 and p_salary < 5000 then
      --nEE := p_salary * .01;
      nEE := p_salary * .02;
      nER := p_salary * .02;
   else
      --nEE := 25;
      --nER := 50;
      nEE := p_salary * .01;
      nER := p_salary * .02;
   end if;

   p_ee := nEE;
   p_er := nER;

end sp_get_pagibig_ee_er;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_PHILHEALTH_CONTRIBUTION"
   ( p_salary  in number,
     p_effdate in date,
     p_ee out number,
     p_er out number
   ) is
   nEE Number;
   nER Number;
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_philhealth_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching Philhealth effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select ee_share, er_share
   into   nEE, nER
   from   pys_philhealth_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;
   p_ee := nEE;
   p_er := nER;
exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Philhealth contribution table. No range for this salary - ' || to_char(p_salary));
   when too_many_rows then
      raise_application_error (-20001, 'Check your Philhealth contribution table. Too many range for this salary - ' || to_char(p_salary));
end sp_get_philhealth_contribution;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_PHILHEALTH_EE_ER"
   ( p_salary  in  number,
     p_effdate in date,
     p_ee     out number,
     p_er     out number
   )
   is
   nEE Number;
   nER Number;
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_philhealth_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching Philhealth effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select ee_share, er_share
   into   nEE, nER
   from   pys_philhealth_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;

   p_ee := nEE;
   p_er := nER;

exception
   when no_data_found then
      raise_application_error (-20001, 'Check your Philhealth contribution table. No range for this salary - ' || to_char(p_salary));

   when too_many_rows then
      raise_application_error (-20001, 'Check your Philhealth contribution table. Too many range for this salary - ' || to_char(p_salary));

end sp_get_philhealth_ee_er;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_REPAIR_COST" (p_jo_no IN VARCHAR2, p_tcost OUT NUMBER) AS
   v_ldisc NUMBER(10,2);
   v_mdisc NUMBER(10,2);
   v_lcost NUMBER(14,2);
   v_mcost NUMBER(14,2);
   v_tcost NUMBER(14,2);
   v_jodrno VARCHAR2(16);
BEGIN
   BEGIN
      SELECT labor_discount, matrl_discount, jo_dr_no
      INTO   v_ldisc, v_mdisc, v_jodrno
      FROM   INV_JO_DR_HDR
      WHERE  johd_jo_no = p_jo_no;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         p_tcost := 0;
   END;


   FOR a IN (SELECT cate_code, unit_price, qty FROM INV_JO_DR_DTL WHERE jdhd_jo_dr_no = v_jodrno)
   LOOP
      v_lcost := 0;
      v_mcost := 0;
      IF a.cate_code = 'LBR' THEN
         v_lcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*(v_ldisc/100);
         v_tcost := NVL(v_tcost,0) + NVL(v_lcost,0);
      ELSE
         v_mcost := (NVL(a.unit_price,0)*NVL(a.qty,0))*(v_mdisc/100);
         v_tcost := NVL(v_tcost,0) + NVL(v_mcost,0);
      END IF;
   END LOOP;
   p_tcost := v_tcost;
END;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GET_SSS_CONTRIBUTION_ER_EE"
   ( p_salary  in  number,
     p_effdate in  date,
     p_ee      out number,
     p_er      out number,
     p_ecer    out number,
     p_mocr    out number
   )
   is
   nER Number(8,2);
   nEC Number(8,2);
   nECER Number(8,2);
   nMO_Credit Number(8,2);
   dEffDate  Date;
begin

   select max(eff_date) into dEffDate
   from   pys_sss_table
   where  eff_date <= p_effdate
   and    p_salary between salary_fr and salary_to;

   if dEffDate is null then
      raise_application_error (-20001, 'No matching SSS effectivity for this salary - ' || nvl(to_char(p_salary),'BLANK'));
   end if;

   select sss_er, sss_ee, ec_er, mo_sal_credit
   into   nER, nEC, nECER, nMO_Credit
   from   pys_sss_table
   where  eff_date = dEffDate
   and    p_salary between salary_fr and salary_to;

   p_ee   := nEC;
   p_er   := nER;
   p_ecer := nECER;
   p_mocr := nMO_Credit;

exception
   when no_data_found then
      if p_salary <= 0 then
         p_ee := 0;
         p_er := 0;
         p_er := 0;
         p_mocr := 0;
      else
         raise_application_error (-20001, 'Check your SSS contribution table. No range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
      end if;
   when too_many_rows then
      select sss_er, sss_ee, tc_er, mo_sal_credit
      into   nER, nEC, nECER, nMO_Credit
      from   pys_sss_table
      where  eff_date = dEffDate
      and    p_salary between salary_fr and salary_to
      and    rownum = 1;
      p_ee   := nEC;
      p_er   := nER;
      p_ecer := nECER;
      p_mocr := nMO_Credit;
      --raise_application_error (-20001, 'Check your SSS contribution table. Too many range for this salary - ' || nvl(to_char(p_salary),'BLANK'));
end sp_get_sss_contribution_er_ee;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GRANT_ACCESS" (p_role in varchar2, p_object in varchar2) as
   vStr Varchar2(256);
begin
   -- grant select to tpj roles
   for i in (select granted_role role from user_role_privs where granted_role like p_role) loop
      for j in (select object_name, object_type from user_objects
               where object_name like p_object and object_type in ('TABLE', 'FUNCTION', 'PROCEDURE', 'VIEW', 'SEQUENCE')
               )
      loop
         if j.object_type IN ('FUNCTION', 'PROCEDURE') then
            vStr := 'grant execute on ' || j.object_name || ' to ' || i.role;
         else
            if instr(i.role, 'READ', 1, 1) > 0 then
               vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role;
            else
               vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role;
            end if;
         end if;
         execute immediate(vStr);
      end loop;
   end loop;
end sp_grant_access;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_GRANT_READ_ACCESS" (p_role in varchar2, p_object in varchar2) as
   vStr Varchar2(256);
begin
   -- grant select to tpj roles
   for i in (select granted_role role from user_role_privs where granted_role like p_role) loop
      for j in (select object_name, object_type from user_objects
               where object_name like p_object and object_type in ('TABLE', 'FUNCTION', 'PROCEDURE', 'VIEW', 'SEQUENCE')
               )
      loop
         if j.object_type IN ('FUNCTION', 'PROCEDURE') then
            vStr := 'grant execute on ' || j.object_name || ' to ' || i.role;
         else
            vStr := 'grant select,insert,update,delete on ' || j.object_name || ' to ' || i.role;
         end if;
         execute immediate(vStr);
      end loop;
   end loop;
end sp_grant_read_access;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INCENTIVE_COMPUTATION"
(
   p_tranno  IN NUMBER,
   p_year    IN VARCHAR2,
   p_mon     IN VARCHAR2,
   p_date_fr IN DATE,
   p_date_to IN DATE
)
   AS
   --get voyage crew
   CURSOR vocr IS
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, NVL(dt_disembarked,p_date_to) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess, CMS_VOYAGES voya
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NULL
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id IS NOT NULL
   AND    vocr.voya_vess_code = voya.vess_code
   AND    vocr.voya_voyage_date = voya.voyage_date
   AND    voya.voyage_status <> 'CN'
   UNION
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked+1 dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess, CMS_VOYAGES voya
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NOT NULL
   AND    vocr.dt_disembarked >= p_date_fr
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id IS NOT NULL
   AND    vocr.voya_vess_code = voya.vess_code
   AND    vocr.voya_voyage_date = voya.voyage_date
   AND    voya.voyage_status <> 'CN'
   ORDER  BY dt_embarked;
   CURSOR vocr_e (p_empl_id IN VARCHAR2) IS
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, NVL(dt_disembarked+1,p_date_to) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess, CMS_VOYAGES voya
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NULL
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.voya_vess_code = voya.vess_code
   AND    vocr.voya_voyage_date = voya.voyage_date
   AND    voya.voyage_status <> 'CN'
   AND    vocr.empl_empl_id = p_empl_id
   UNION
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked+1 dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess, CMS_VOYAGES voya
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NOT NULL
   AND    vocr.dt_disembarked >= p_date_fr
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.voya_vess_code = voya.vess_code
   AND    vocr.voya_voyage_date = voya.voyage_date
   AND    voya.voyage_status <> 'CN'
   AND    vocr.empl_empl_id = p_empl_id
   ORDER  BY dt_embarked;
   --get vessel total catch
   CURSOR mcsu_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_catcher
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end;
   --get vessel catch per source
   CURSOR dcsu_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_catcher
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY fiso_code, tx_date;
   CURSOR drdt_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT SUM(tot_catch) total_catch
   FROM   CMS_CATCHES_DR_DTLS
   WHERE  to_vess_code = p_catcher
   AND    tx_date BETWEEN p_start AND p_end;
   --GROUP  BY tx_date;
   --get vessel lightboat
   CURSOR dcsu_l ( p_lighted IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_lighted = p_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY  vess_lighted, vess_surveyed, fiso_code
   UNION
   SELECT vess_lighted, vess_surveyed, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_surveyed = p_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY vess_lighted, vess_surveyed, fiso_code;
   --get vessel surveyed
   CURSOR dcsu_s ( p_surveyed_by IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, surveyed_by, vess_catcher, surveyed_by_vess, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  surveyed_by = p_surveyed_by
   AND    tx_date BETWEEN p_start AND p_end
   AND    fiso_code in ('KAWAN', 'TROSO')
   AND    time_setted < p_end
   GROUP  BY  tx_date, surveyed_by, vess_catcher, surveyed_by_vess;
   --get vessel catch per day 300 600
   CURSOR dcsu_d ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_surveyed
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;
   CURSOR dcsu_d2 ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_lighted = p_surveyed
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;
   CURSOR dcsu_d3 ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_surveyed = p_surveyed
   AND    vess_surveyed <> vess_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;
   --get vessel delivered per day
   -- cursor drsu_d ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   -- select tx_date, sum(total_catch) total_catch
   -- from   cms_catches_dr_dtls
   -- where  vess_surveyed = p_surveyed
   -- and    tx_date between p_start and p_end
   -- group  by tx_date;
   CURSOR dedu (p_empl_id IN VARCHAR2 ) IS
   SELECT empl_empl_id, dety_code, seq_no, amt
   FROM   PYS_DEDUCTIONS
   WHERE  empl_empl_id = p_empl_id
   AND    end_date  <= p_date_to
   AND    start_date >= p_date_fr
   --and    no_payday > 0
   AND    dety_code = ('VALE'); -- VALE should be deducted from Incentives
   CURSOR cash_b (p_voya_vess IN VARCHAR2,
                  p_sta IN DATE,
                  p_end IN DATE ) IS
   SELECT greatest(voro.start_date, p_sta) start_date, least(nvl(voro.end_date,p_end), p_end) end_date,
          decode(loca.loca_type, 'INTL', least(nvl(voro.end_date,p_end), p_end) - greatest(voro.start_date, p_sta), 0) n_days,
          voro.destination, loca.loca_type loca_type
   FROM   cms_voyage_route voro, cms_voyages voya, cms_catch_locations loca
   where  voro.voya_vess_code = voya.vess_code
   and    voro.voya_voyage_date = voya.voyage_date
   and    voro.destination = loca.code
   and    voya.voyage_status <> 'CN'
   and    p_sta >= voya.voyage_date
   and    voro.voya_vess_code = p_voya_vess
   and    p_sta >= voro.start_date
   and    ((voya.voyage_end_date is not null
   and      p_sta < voya.voyage_end_date)
   or      voya.voyage_end_date is null )
   and    ((voro.end_date is not null
   and      p_sta < voro.end_date)
   or      voro.end_date is null );
   dStart       DATE;
   dEnd         DATE;
   nTotalCatch  NUMBER(12,2);
   nDummy       NUMBER;
   n300_600_cnt NUMBER;
   nCashBonus_cnt NUMBER;
   nRate        PYS_EMPLOYEE_INCENTIVES.rate%TYPE;
   nExtra       PYS_INCENTIVES.rate_2%TYPE;
   nBasis       PYS_EMPLOYEE_INCENTIVES.basis%TYPE;
   nAmt         PYS_EMPLOYEE_INCENTIVES.amt%TYPE;
   vErrMsg      VARCHAR2(2000);
   nCheck       NUMBER;
   nCATCHER     NUMBER;
   nLIGHTBOAT   NUMBER;
   nLighted     NUMBER:= 0;
   nSurveyed    NUMBER:= 0;
   d_empl_id    VARCHAR2(16) := 'B00006';
BEGIN
   -- CATCHER
   SELECT COUNT(1) INTO nDummy
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  tx_date BETWEEN  p_date_fr AND p_date_to;
   IF nDummy > 0 THEN
      DELETE FROM CMS_DAILY_CATCH_SUMMARY WHERE  tx_date BETWEEN  p_date_fr AND p_date_to;
   END IF;
   -- clear first
   BEGIN
      delete from PYS_EMPLOYEE_INCENTIVES where inhd_tran_no = p_tranno;
      delete from PYS_KAWAN_TROSO_INCENTIVES where inhd_tran_no = p_tranno;
      delete from PYS_CONTRACTUAL_INCENTIVES where inhd_tran_no = p_tranno;
      delete from PYS_KAWAN_TROSO_INCENTIVES_F where inhd_tran_no = p_tranno;
   END;
   BEGIN
      INSERT INTO CMS_DAILY_CATCH_SUMMARY
             (
             tx_date, time_setted, vess_catcher, vess_surveyed, vess_lighted, fiso_code, surveyed_by, surveyed_by_vess, total_catch, created_by, dt_created
             )
      SELECT chdr.tx_date, TO_DATE(TO_CHAR(chdr.tx_date, 'YYYYMMDD') || TO_CHAR(chdr.time_setted, 'HH24MI'), 'YYYYMMDDHH24MI') time_setted,
             chdr.vess_code vess_catcher, chdr.vess_surveyed, chdr.vess_lighted, clog.fiso_code, chdr.surveyed_by, chdr.surveyed_by_vess,
             --SUM(NVL(clog.tot_jmb_catch,0) + NVL(clog.tot_lrg_catch,0) + NVL(clog.tot_reg_catch,0)  + NVL(clog.tot_med_catch,0) + NVL(clog.tot_sml_catch,0)) total_catch,
                               SUM(NVL(tot_catch,0)) total_catch, USER, SYSDATE
      FROM   CMS_CATCHES_LOG clog, CMS_CATCHES_HDR chdr
      WHERE  clog.cahd_tx_no = chdr.tx_no
      AND    chdr.tx_date BETWEEN p_date_fr AND p_date_to
      GROUP  BY chdr.tx_date, TO_DATE(TO_CHAR(chdr.tx_date, 'YYYYMMDD') || TO_CHAR(chdr.time_setted, 'HH24MI'), 'YYYYMMDDHH24MI'),
            chdr.vess_code, chdr.vess_surveyed, chdr.vess_lighted, clog.fiso_code, chdr.surveyed_by, chdr.surveyed_by_vess;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         vErrMsg := SQLERRM;
         RAISE_APPLICATION_ERROR (-20001, vErrMsg);
   END;
   -- CARRIER
   -- select count(1) into nDummy
   -- from   cms_daily_delivery_summary
   -- where  tx_date between  p_date_fr and p_date_to;
   -- if nDummy > 0 then
   --    delete from cms_daily_catch_summary where  tx_date between  p_date_fr and p_date_to;
   -- end if;
   -- begin
   --    insert into cms_daily_catch_summary
   --           (
   --           tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code, total_catch, created_by, dt_created
   --           )
   --    select tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code,
   --           sum(nvl(tot_jmb_catch,0) + nvl(tot_lrg_catch,0) + nvl(tot_reg_catch,0)  + nvl(tot_med_catch,0) + nvl(tot_sml_catch,0)) total_catch, user, sysdate
   --    from   cms_catches_log
   --    where  tx_date between p_date_fr and p_date_to
   --    group  by tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code;
   --    commit;
   -- exception
   --    when others then
   --       vErrMsg := SQLERRM;
   --       raise_application_error (-20001, vErrMsg);
   -- end;
   FOR i IN vocr LOOP
      nCATCHER    := 0 ;
      nLIGHTBOAT  := 0 ;
      nTotalCatch := 0;
      if i.empl_empl_id = d_empl_id then
         DBMS_OUTPUT.PUT_LINE('empl empl id '||i.empl_empl_id||', i.passenger '||i.passenger || ',i.vessel:' || i.vessel);
      end if;
      IF i.passenger <> 'Y' THEN
         IF i.dt_embarked < p_date_fr THEN
            dStart := p_date_fr;
         ELSE
            dStart := i.dt_embarked ;
         END IF;
         IF i.dt_disembarked >= p_date_to THEN
            dEnd := p_date_to+1;
         ELSE
            dEnd := i.dt_disembarked ;
         END IF;
         -- total catch
         -- scenarios: rate should be based on total catch provided vessels
         nTotalCatch := 0;
         FOR k IN vocr_e ( i.empl_empl_id ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check carrier i.vess_type:' || i.vess_type || ',k.vess_type:' || k.vess_type);
            END IF;
            IF i.vess_type = k.vess_type THEN
               FOR j IN dcsu_c ( i.vessel, dStart, dEnd ) LOOP
                  nTotalCatch := nTotalCatch + j.total_catch;
                  IF i.empl_empl_id = d_empl_id THEN
                     DBMS_OUTPUT.PUT_LINE ('check carrier j.total_catch:' || to_char(j.total_catch) || ' nTotalCatch:' || to_char(nTotalCatch));
                  END IF;
               END LOOP;
            END IF;
         END LOOP;
         -- kawan/troso report detail
         -- catcher per source
         FOR j IN dcsu_c ( i.vessel, dStart, dEnd ) LOOP
            nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, j.total_catch );
            --nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, nTotalCatch );
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check carrier rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
            END IF;
            IF j.total_catch > 0 AND nRate > 0 THEN
               Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL );
               -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL, NULL, NULL );
            END IF;
            nCATCHER := nCATCHER + (nRate);
         END LOOP;

         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check nCATCHER:' || TO_CHAR(nCATCHER) );
         END IF;
         IF nCATCHER > 0 THEN
            FOR j IN (SELECT code FROM CMS_FISHING_SOURCES WHERE status = 'ACTIVE') LOOP
               SELECT nvl(sum(basis),0), nvl(max(rate),0) INTO nTotalCatch, nRate
               FROM   PYS_KAWAN_TROSO_INCENTIVES
               WHERE  YEAR          = p_year
               AND    MO            = p_mon
               AND    INTY_CODE     = 'CATCHER'
               AND    EMPL_EMPL_ID  = i.empl_empl_id
               AND    VESS_CODE     = i.vessel
               AND    FISO_CODE     = j.code
               AND    RANK_CODE     = i.rank_code;
               Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'CATCHER', i.vessel, i.rank_code, j.code, nTotalCatch, nRate, nTotalCatch*nRate, p_tranno, NULL, NULL, NULL );
            END LOOP;
         END IF;
         -- lighted
         -- scenarios for catcher with lighted and/or surveyed, applicable only for PAYAO
         -- if catcher is entitled for lighted and surveyed 15% of lighted + surveyed
         -- if catcher is entitled for lighted 5% of lighted + surveyed
         -- if catcher is entitled for surveyed 10% of lighted + surveyed
         nLighted  := 0;
         nSurveyed := 0;
         FOR j IN dcsu_l ( i.vessel, dStart, dEnd ) LOOP
            -- total catch is divided to lighted and surveyed
            nLighted  := j.total_catch/2;
            nSurveyed := j.total_catch/2;
            IF i.vess_type = 'CATCHER' THEN
               IF j.fiso_code = 'PAYAO' THEN
                  IF i.empl_empl_id = d_empl_id THEN
                     DBMS_OUTPUT.PUT_LINE ('check lighted rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',i.vess_type:' || i.vess_type || ',j.fiso_code :' || j.fiso_code );
                  END IF;
                  IF j.vess_lighted = j.vess_surveyed THEN
                     nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch);
                     --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch);
                     IF j.total_catch > 0 AND nRate > 0 THEN
                        Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, ((nLighted*.15)+nSurveyed), nRate, ((nLighted*.15)+nSurveyed)*nRate, p_tranno, NULL );
                        -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, ((nLighted*.15)+nSurveyed), nRate, ((nLighted*.15)+nSurveyed)*nRate, p_tranno, NULL, NULL, NULL );
                     END IF;
                     nLIGHTBOAT := nLIGHTBOAT + (((nLighted*.15)+nSurveyed)*nRate);
                  ELSIF j.vess_lighted = i.vessel THEN
                     nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch/2);
                     --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                     IF j.total_catch > 0 AND nRate > 0 THEN
                        Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nLighted*.05), nRate, (nLighted*.05)*nRate, p_tranno, NULL );
                        -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nLighted*.05), nRate, (nLighted*.05)*nRate, p_tranno, NULL, NULL, NULL );
                     END IF;
                     nLIGHTBOAT := nLIGHTBOAT + ((nLighted*.05)*nRate);
                  ELSIF j.vess_surveyed = i.vessel THEN
                     nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch/2);
                     --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                     IF j.total_catch > 0 AND nRate > 0 THEN
                        Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nSurveyed*.10), nRate, (nSurveyed*.10)*nRate, p_tranno, NULL );
                        -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nSurveyed*.10), nRate, (nSurveyed*.10)*nRate, p_tranno, NULL, NULL, NULL );
                     END IF;
                     nLIGHTBOAT := nLIGHTBOAT + ((nSurveyed*.10)*nRate);
                  END IF;
               END IF;
               IF i.empl_empl_id = d_empl_id THEN
                  DBMS_OUTPUT.PUT_LINE ('check lighted rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',i.vess_type:' || i.vess_type);
               END IF;
            ELSE
               IF j.vess_lighted = j.vess_surveyed THEN
                  nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch);
                  --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch);
                  IF j.total_catch > 0 AND nRate > 0 THEN
                     Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL );
                     -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL, NULL, NULL );
                  END IF;
                  nLIGHTBOAT := nLIGHTBOAT + (j.total_catch*nRate);
               ELSE
                  nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch/2);
                  --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                  IF j.total_catch > 0 AND nRate > 0 THEN
                     Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, nLighted*nRate, p_tranno, NULL );
                     --Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, nLighted*nRate, p_tranno, NULL, NULL, NULL );
                  END IF;
                  nLIGHTBOAT := nLIGHTBOAT + (nLighted*nRate);
               END IF;
               IF i.empl_empl_id = d_empl_id THEN
                  DBMS_OUTPUT.PUT_LINE ('check lighted rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
               END IF;
            END IF;
         END LOOP;
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check LIGHTBOAT:' || TO_CHAR(nRate) || ',i.vess_type:' || i.vess_type || ',i.rank_code:' ||  i.rank_code || ',nLIGHTBOAT:' || TO_CHAR(nLIGHTBOAT) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
         END IF;
         IF nLIGHTBOAT > 0 THEN
            IF i.vess_type <> 'CATCHER' THEN
               FOR j IN (SELECT code FROM CMS_FISHING_SOURCES WHERE status = 'ACTIVE') LOOP
                  BEGIN
                     SELECT count(1) INTO nCheck
                     FROM   PYS_KAWAN_TROSO_INCENTIVES
                     WHERE  YEAR          = p_year
                     AND    MO            = p_mon
                     AND    INTY_CODE     = 'LIGHTBOAT'
                     AND    EMPL_EMPL_ID  = i.empl_empl_id
                     AND    VESS_CODE     = i.vessel
                     AND    FISO_CODE     = j.code
                     AND    RANK_CODE     = i.rank_code;
                  IF nCheck = 0 then
                     Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL, NULL, NULL );
                  END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        --Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL );
                        Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL, NULL, NULL );
                  END;
               END LOOP;
            END IF;
         END IF;
         -- Surveyed By
         FOR j IN dcsu_s ( i.empl_empl_id, dStart, dEnd ) LOOP
            nRate := Sf_Get_Surveyed_Rate ( j.total_catch );
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check surveyed rate:' || TO_CHAR(nRate) || ',i.rank_code:' ||  i.rank_code || ',n300_600_cnt:' || TO_CHAR(n300_600_cnt));
            END IF;
            IF nRate > 0 THEN
               Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, j.tx_date, j.tx_date, 'SURVEYED', j.vess_catcher, i.rank_code, NULL, j.total_catch, nRate, j.total_catch * nRate, p_tranno, j.surveyed_by_vess );
               --Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, j.tx_date, j.tx_date, 'SURVEYED', j.vess_catcher, i.rank_code, NULL, j.total_catch, nRate, j.total_catch * nRate, p_tranno, j.surveyed_by_vess, NULL, NULL );
            END IF;
         END LOOP;
         -- kawan/troso report summary
         for j in (select INTY_CODE, FISO_CODE, RANK_CODE, sum(basis) basis
                   from   pys_kawan_troso_incentives
                   where  year = p_year
                   and    mo   = p_mon
                   and    empl_empl_id = i.empl_empl_id
                   group  by INTY_CODE, FISO_CODE, RANK_CODE)
         loop
             if j.INTY_CODE = 'CATCHER' then
                nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, j.basis );
             elsif j.INTY_CODE = 'LIGHTHOUSE' then
                nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.basis);
             elsif j.INTY_CODE = 'SURVEYED' then
                nRate := Sf_Get_Surveyed_Rate ( j.basis );
             end if;
             Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.basis, nRate, j.basis*nRate, p_tranno, NULL, NULL, NULL );
         end loop;
         -- 300/600
         n300_600_cnt := 0;
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check 300_600 i.vessel:' || i.vessel || ', dStart:' || TO_CHAR(dStart) || ', dEnd:' || TO_CHAR(dEnd, 'YYYYMMDD HH24MISS'));
         END IF;
         FOR j IN dcsu_d ( i.vessel, dStart, dEnd ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check 300_600 j.total_catch:' || TO_CHAR(j.total_catch) || ', j.tx_date:' || TO_CHAR(j.tx_date));
            END IF;
            IF Sf_Is_Fullmoon ( j.tx_date ) = 1 THEN
               IF j.total_catch >= 300 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            ELSE
               IF j.total_catch >= 600 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            END IF;
         END LOOP;
         -- for lighted
         FOR j IN dcsu_d2 ( i.vessel, dStart, dEnd ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check 300_600 j.total_catch:' || TO_CHAR(j.total_catch) || ', j.tx_date:' || TO_CHAR(j.tx_date));
            END IF;
            IF Sf_Is_Fullmoon ( j.tx_date ) = 1 THEN
               IF j.total_catch >= 300 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            ELSE
               IF j.total_catch >= 600 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            END IF;
         END LOOP;
         -- for surveyed
         FOR j IN dcsu_d3 ( i.vessel, dStart, dEnd ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check 300_600 j.total_catch:' || TO_CHAR(j.total_catch) || ', j.tx_date:' || TO_CHAR(j.tx_date));
            END IF;
            IF Sf_Is_Fullmoon ( j.tx_date ) = 1 THEN
               IF j.total_catch >= 300 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            ELSE
               IF j.total_catch >= 600 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            END IF;
         END LOOP;
         nRate := Sf_300_600_Rate ( i.rank_code, n300_600_cnt );
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check 300_600 rate:' || TO_CHAR(nRate) || ', i.rank_code:' ||  i.rank_code || ', n300_600_cnt:' || TO_CHAR(n300_600_cnt));
         END IF;
         IF n300_600_cnt > 0  AND nRate > 0 THEN
            Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, '300_600', i.vessel, i.rank_code, NULL, n300_600_cnt, nRate, n300_600_cnt*nRate, p_tranno, NULL, NULL, NULL );
         END IF;
         -- carrier/delivery
         for j in drdt_c ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_delivery_rate ( i.rank_code, j.total_catch );
            if j.total_catch > 0 and nRate > 0 then
               begin
                  Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'DELIVERIES', i.vessel, i.rank_code, NULL, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL, NULL, NULL );
               EXCEPTION
                  WHEN OTHERS THEN
                     vErrMsg := SQLERRM;
                     RAISE_APPLICATION_ERROR (-20001, 'CARRIER ERROR:' || vErrMsg);
               END;
            end if;
         end loop;
         -- Cash Bonus
         nCashBonus_cnt := 0;
         nRate  := 0;
         nExtra := 0;
         nRate := sf_get_cashbonus_rate ( i.rank_code, 1, nExtra  );
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check CashBonus nRate:' || to_char(nRate) || ', nExtra' || TO_CHAR(nExtra) || ' dStart:' || to_char(dStart) ||' dEnd:' || to_char(dEnd));
         END IF;
         IF nRate > 0 THEN
            FOR j IN cash_b ( i.vessel, dStart, dEnd-1 ) LOOP
               IF i.empl_empl_id = d_empl_id THEN
                  DBMS_OUTPUT.PUT_LINE ('check CashBonus j.n_days: ' || to_char(j.n_days) || ':' || to_char(j.start_date) || ':' || to_char(j.end_date));
               END IF;
               if j.n_days > 0 then
                  nCashBonus_cnt := nCashBonus_cnt + 1;
                  Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, j.start_date, j.end_date, 'CASH BONUS', i.vessel, i.rank_code, NULL, j.n_days, nRate, (j.n_days*nRate), p_tranno, NULL, NULL, NULL );
               end if;
            END LOOP;
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check CashBonus count: ' || to_char(nCashBonus_cnt));
            END IF;
            IF (nCashBonus_cnt > 0) and (nExtra > 0) THEN
               Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'CASH BONUS', i.vessel, i.rank_code, NULL, 1, nExtra, nExtra, p_tranno, NULL, NULL, NULL );
            ELSIF (nCashBonus_cnt = 0) THEN
               Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'CASH BONUS', i.vessel, i.rank_code, NULL, 0, 0, 0, p_tranno, NULL, NULL, NULL );
            END IF;
         ELSE
            Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd-1, 'CASH BONUS', i.vessel, i.rank_code, NULL, 0, 0, 0, p_tranno, NULL, NULL, NULL );
         END IF;
      END IF;
   END LOOP;
   FOR x IN (SELECT empl_empl_id, SUM(DECODE(inty_code,'CATCHER',amt,'LIGHTBOAT', amt, 0)) amt
             FROM   PYS_EMPLOYEE_INCENTIVES
             WHERE  inhd_tran_no = p_tranno
             GROUP  BY empl_empl_id
            )
   LOOP
      FOR i IN (SELECT empl_empl_id, period_to, period_fr, vess_code vessel, rank_code
                FROM   PYS_EMPLOYEE_INCENTIVES
                WHERE  inhd_tran_no = p_tranno
                AND    empl_empl_id = x.empl_empl_id
                ORDER  BY period_to DESC, period_fr DESC
               )
      LOOP
         IF (x.amt > 0) THEN
            FOR z IN dedu (i.empl_empl_id) LOOP
               Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, p_date_fr, p_date_to, NULL, i.vessel, i.rank_code, NULL, z.amt, 1, z.amt, p_tranno, NULL, z.dety_code, z.seq_no );
            END LOOP;
         END IF;
         UPDATE PYS_EMPLOYEE_INCENTIVES
         SET    l_vess_code = i.vessel,
                l_rank_code = i.rank_code
         WHERE  empl_empl_id = x.empl_empl_id
         AND    inhd_tran_no = p_tranno;
         EXIT;
      END LOOP;
   END LOOP;
   Sp_Incentive_Computation_F ( p_tranno, p_year, p_mon, p_date_fr, p_date_to);
   COMMIT;
EXCEPTION
   WHEN OTHERS THEN
      vErrMsg := SQLERRM;
      RAISE_APPLICATION_ERROR (-20001, vErrMsg);
END Sp_Incentive_Computation;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INCENTIVE_COMPUTATION_F"
(
   p_tranno  IN NUMBER,
   p_year    IN VARCHAR2,
   p_mon     IN VARCHAR2,
   p_date_fr IN DATE,
   p_date_to IN DATE
)
   AS

   --get voyage crew
   CURSOR vocr IS
   SELECT vocrf.vess_code vessel, vess.vety_code, vocrf.cont_id cont_id, vocrf.rank_code,
          vocrf.dt_embarked, NVL(vocrf.dt_disembarked+1,p_date_to) dt_disembarked, vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW_FOREIGN vocrf, CMS_VESSELS vess
   WHERE  vocrf.dt_embarked <= p_date_to
   AND    vocrf.dt_disembarked IS NULL
   AND    vocrf.vess_code = vess.code
   AND    vocrf.cont_id IS NOT NULL
   UNION
   SELECT vocrf.vess_code vessel, vess.vety_code, vocrf.cont_id cont_id, vocrf.rank_code,
          vocrf.dt_embarked, vocrf.dt_disembarked+1 dt_disembarked, vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW_FOREIGN vocrf, CMS_VESSELS vess
   WHERE  vocrf.dt_embarked <= p_date_to
   AND    vocrf.dt_disembarked IS NOT NULL
   AND    vocrf.dt_disembarked >= p_date_fr
   AND    vocrf.vess_code = vess.code
   AND    vocrf.cont_id IS NOT NULL
   ORDER  BY dt_embarked;

   CURSOR vocr_e (p_cont_id IN VARCHAR2) IS
   SELECT vocrf.vess_code vessel, vess.vety_code, vocrf.cont_id cont_id, vocrf.rank_code,
          vocrf.dt_embarked, NVL(vocrf.dt_disembarked+1,p_date_to) dt_disembarked, vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW_FOREIGN vocrf, CMS_VESSELS vess
   WHERE  vocrf.dt_embarked <= p_date_to
   AND    vocrf.dt_disembarked IS NULL
   AND    vocrf.vess_code = vess.code
   AND    vocrf.cont_id = p_cont_id
   UNION
   SELECT vocrf.vess_code vessel, vess.vety_code, vocrf.cont_id cont_id, vocrf.rank_code,
          vocrf.dt_embarked, vocrf.dt_disembarked+1 dt_disembarked, vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW_FOREIGN vocrf, CMS_VESSELS vess
   WHERE  vocrf.dt_embarked <= p_date_to
   AND    vocrf.dt_disembarked IS NOT NULL
   AND    vocrf.dt_disembarked >= p_date_fr
   AND    vocrf.vess_code = vess.code
   AND    vocrf.cont_id = p_cont_id
   ORDER  BY dt_embarked;

   --get vessel total catch
   CURSOR mcsu_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_catcher
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end;

   --get vessel catch per source
   CURSOR dcsu_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_catcher
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY fiso_code, tx_date;

   CURSOR drdt_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT SUM(tot_catch) total_catch
   FROM   CMS_CATCHES_DR_DTLS
   WHERE  to_vess_code = p_catcher
   AND    tx_date BETWEEN p_start AND p_end;
   --GROUP  BY tx_date;

   --get vessel lightboat
   CURSOR dcsu_l ( p_lighted IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_lighted = p_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY  vess_lighted, vess_surveyed, fiso_code
   UNION
   SELECT vess_lighted, vess_surveyed, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_surveyed = p_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY vess_lighted, vess_surveyed, fiso_code;

   --get vessel surveyed
   CURSOR dcsu_s ( p_surveyed_by IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, surveyed_by, vess_catcher, surveyed_by_vess, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  surveyed_by = p_surveyed_by
   AND    tx_date BETWEEN p_start AND p_end
   AND    fiso_code in ('KAWAN', 'TROSO')
   AND    time_setted < p_end
   GROUP  BY  tx_date, surveyed_by, vess_catcher, surveyed_by_vess;

   --get vessel catch per day 300 600
   CURSOR dcsu_d ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_surveyed
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;

   CURSOR dcsu_d2 ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_lighted = p_surveyed
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;

   CURSOR dcsu_d3 ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_surveyed = p_surveyed
   AND    vess_surveyed <> vess_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;

   CURSOR cash_b (p_voya_vess IN VARCHAR2,
                  p_sta IN DATE,
                  p_end IN DATE ) IS
   SELECT greatest(voro.start_date, p_sta) start_date, least(nvl(voro.end_date,p_end), p_end) end_date,
          decode(loca.loca_type, 'INTL', least(nvl(voro.end_date,p_end), p_end) - greatest(voro.start_date, p_sta), 0) n_days,
          voro.destination, loca.loca_type loca_type
   FROM   cms_voyage_route voro, cms_voyages voya, cms_catch_locations loca
   where  voro.voya_vess_code = voya.vess_code
   and    voro.voya_voyage_date = voya.voyage_date
   and    voro.destination = loca.code
   and    voya.voyage_status <> 'CN'
   and    p_sta >= voya.voyage_date
   and    voro.voya_vess_code = p_voya_vess
   and    p_sta >= voro.start_date
   and    ((voya.voyage_end_date is not null
   and      p_sta < voya.voyage_end_date)
   or      voya.voyage_end_date is null )
   and    ((voro.end_date is not null
   and      p_sta < voro.end_date)
   or      voro.end_date is null );

   dStart       DATE;
   dEnd         DATE;
   nTotalCatch  NUMBER(12,2);
   nDummy       NUMBER;
   n300_600_cnt NUMBER;
   nCashBonus_cnt NUMBER;
   nRate        PYS_CONTRACTUAL_INCENTIVES.rate%TYPE;
   nExtra       PYS_INCENTIVES.rate_2%TYPE;
   nBasis       PYS_CONTRACTUAL_INCENTIVES.basis%TYPE;
   nAmt         PYS_CONTRACTUAL_INCENTIVES.amt%TYPE;
   vErrMsg      VARCHAR2(2000);
   nCheck       NUMBER;
   nCATCHER     NUMBER;
   nLIGHTBOAT   NUMBER;
   nLighted     NUMBER:= 0;
   nSurveyed    NUMBER:= 0;

   d_cont_id    VARCHAR2(16) := 'C00004';

BEGIN

   FOR i IN vocr LOOP

      nCATCHER    := 0 ;
      nLIGHTBOAT  := 0 ;
      nTotalCatch := 0;

      if i.cont_id = d_cont_id then
         DBMS_OUTPUT.PUT_LINE('empl empl id '||i.cont_id||', i.passenger '|| ',i.vessel:' || i.vessel);
      end if;

         IF i.dt_embarked < p_date_fr THEN
            dStart := p_date_fr;
         ELSE
            dStart := i.dt_embarked ;
         END IF;

         IF i.dt_disembarked >= p_date_to THEN
            dEnd := p_date_to+1;
         ELSE
            dEnd := i.dt_disembarked ;
         END IF;

         -- total catch
         -- scenarios: rate should be based on total catch provided vessels
         nTotalCatch := 0;
         FOR k IN vocr_e ( i.cont_id ) LOOP
            IF i.cont_id = d_cont_id THEN
               DBMS_OUTPUT.PUT_LINE ('check carrier i.vess_type:' || i.vess_type || ',k.vess_type:' || k.vess_type);
            END IF;
            IF i.vess_type = k.vess_type THEN
               FOR j IN dcsu_c ( i.vessel, dStart, dEnd ) LOOP
                  IF i.cont_id = d_cont_id THEN
                     DBMS_OUTPUT.PUT_LINE ('check carrier j.total_catch:' || to_char(j.total_catch));
                  END IF;
                  nTotalCatch := nTotalCatch + j.total_catch;
               END LOOP;
            END IF;
         END LOOP;

         -- kawan/troso report detail
         -- catcher per source
         FOR j IN dcsu_c ( i.vessel, dStart, dEnd ) LOOP
            nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, j.total_catch );
            IF i.cont_id = d_cont_id THEN
               DBMS_OUTPUT.PUT_LINE ('check carrier rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
            END IF;
            IF j.total_catch > 0 AND nRate > 0 THEN
               Sp_ins_kawan_troso_incentive_f ( i.cont_id, p_year, p_mon, dStart, dEnd-1, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno );
            END IF;
            nCATCHER := nCATCHER + (nRate);
         END LOOP;
         IF nCATCHER > 0 THEN
            FOR j IN (SELECT code FROM CMS_FISHING_SOURCES WHERE status = 'ACTIVE') LOOP
               BEGIN
                  SELECT count(1) INTO nCheck
                  FROM   PYS_KAWAN_TROSO_INCENTIVES_F
                  WHERE  YEAR          = p_year
                  AND    MO            = p_mon
                  AND    INTY_CODE     = 'CATCHER'
                  AND    cont_id  = i.cont_id
                  AND    VESS_CODE     = i.vessel
                  AND    FISO_CODE     = j.code
                  AND    RANK_CODE     = i.rank_code;
                  IF nCheck = 0 then
                     Sp_Insert_Cont_Incentive ( i.cont_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno );
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     Sp_Insert_Cont_Incentive ( i.cont_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno );
                  WHEN TOO_MANY_ROWS THEN null;
               END;
            END LOOP;
         END IF;

         -- carrier/delivery
         for j in drdt_c ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_delivery_rate ( i.rank_code, j.total_catch );
            if j.total_catch > 0 and nRate > 0 then
               begin
                  Sp_Insert_Cont_Incentive ( i.cont_id, p_year, p_mon, dStart, dEnd-1, 'DELIVERIES', i.vessel, i.rank_code, NULL, j.total_catch, nRate, j.total_catch*nRate, p_tranno );
               EXCEPTION
                  WHEN OTHERS THEN
                     vErrMsg := SQLERRM;
                     RAISE_APPLICATION_ERROR (-20001, 'CARRIER ERROR:' || vErrMsg);
               END;
            end if;
         end loop;

   END LOOP;

EXCEPTION
   WHEN OTHERS THEN
      vErrMsg := SQLERRM;
      RAISE_APPLICATION_ERROR (-20001, vErrMsg);

END Sp_Incentive_Computation_F;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INSERT_CONT_INCENTIVE"
(
   p_cont_id      varchar2,
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
   d_cont_id    varchar2(20) := 'C00004';
begin
   insert into pys_contractual_incentives
          (
            cont_id, year, mo, period_fr, period_to, inty_code, fiso_code, vess_code, rank_code,
            basis, rate, amt, inhd_tran_no, dt_created, created_by
          )
   values (
            p_cont_id, p_year, p_mo, p_start, p_end, p_inty_code, p_fiso_code, p_vess_code, p_rank_code,
            p_basis, p_rate, p_amt, p_inhd_tran_no, trunc(sysdate), user
          );
   commit;
exception
   when dup_val_on_index then
      IF p_cont_id = d_cont_id THEN
         DBMS_OUTPUT.PUT_LINE ('check insert p_inty_code:' || p_inty_code || ',p_vess_code:' || p_vess_code || ',p_fiso_code:' ||  p_fiso_code || ',p_basis:' || TO_CHAR(p_basis));
      END IF;
   when others then
      vErrMsg := SQLERRM;
      raise_application_error (-20001, vErrMsg);
end sp_insert_cont_incentive;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INSERT_CREW_LIST" (
  p_payroll_no VARCHAR2,
  p_fr_date DATE,
  p_TO_DATE DATE,
  p_vess_code VARCHAR2,
  p_empl_id VARCHAR2,
  p_title VARCHAR2,
  p_on_board DATE,
  p_wentdown DATE,
  p_fr_posi_code VARCHAR2,
  p_fr_vess_code VARCHAR2,
  p_fr_eff_date DATE,
  p_to_posi_code VARCHAR2,
  p_to_vess_code VARCHAR2,
  p_to_eff_date DATE,
  p_tran_no VARCHAR2,
  p_voyage_date DATE,
  p_voyage_end_date DATE
  ) AS
BEGIN
if p_empl_id  = 'F00005' then
   dbms_output.put_line(p_empl_id||' 1;'||p_wentdown);
end if;
  INSERT INTO PMS_CREW_LIST(PAYROLL_NO, FR_DATE, TO_DATE, vess_code, empl_id, title, on_board, wentdown,
                            fr_posi_code, fr_vess_code, fr_eff_date, to_posi_code, to_vess_code, to_eff_date, tran_no,
                            userid, dt_created, voyage_st_date, voyage_end_date)
              VALUES (p_PAYROLL_NO, p_FR_DATE, p_TO_DATE, p_vess_code, p_empl_id, p_title, p_on_board, p_wentdown,
                            p_fr_posi_code, p_fr_vess_code, p_fr_eff_date, p_to_posi_code, p_to_vess_code, p_to_eff_date, p_tran_no,
                            USER, SYSDATE, p_voyage_date, p_voyage_end_date);
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    BEGIN
        --dbms_output.put_line('Sp_Insert_Crew_List : Empl Id '||p_empl_id||' : on_board '|| p_on_board||' : wentdown '|| p_wentdown);
        if p_empl_id  = 'F00005' then
           dbms_output.put_line(p_empl_id||' 2;'||p_wentdown);
        end if;
        UPDATE  PMS_CREW_LIST
        SET     on_board = p_on_board,
                wentdown = p_wentdown,
                fr_posi_code = p_fr_posi_code,
                fr_vess_code = p_fr_vess_code,
                fr_eff_date  = p_fr_eff_date,
                to_posi_code = p_to_posi_code,
                to_vess_code = p_to_vess_code,
                to_eff_date  = p_to_eff_date
        WHERE   payroll_no = p_payroll_no
        AND     empl_id    = p_empl_id
        AND     on_board   = p_on_board
        AND     ((tran_no    = p_tran_no) OR (p_tran_no IS NULL AND tran_no IS NULL));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        /*
        UPDATE  PMS_CREW_LIST
        SET     on_board = p_on_board,
                wentdown = p_wentdown,
                fr_posi_code = p_fr_posi_code,
                fr_vess_code = p_fr_vess_code,
                fr_eff_date  = p_fr_eff_date,
                to_posi_code = p_to_posi_code,
                to_vess_code = p_to_vess_code,
                to_eff_date  = p_to_eff_date
        WHERE   payroll_no = p_payroll_no
        AND     empl_id    = p_empl_id
        AND     ((tran_no    = p_tran_no) OR (p_tran_no IS NULL AND tran_no IS NULL));
        */
        if p_empl_id  = 'F00005' then
           dbms_output.put_line(p_empl_id||' 3;'||p_wentdown);
        end if;
        null;

       --raise_application_error(-20001,'PCL UK '||p_payroll_no||' - '||p_empl_id||'- '||p_tran_no||' - '||p_fr_posi_code||' - '||p_to_posi_code);
    END;
END Sp_Insert_Crew_List;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INSERT_CREW_LIST_MOV" (
  p_payroll_no VARCHAR2,
  p_fr_date DATE,
  p_TO_DATE DATE,
  p_vess_code VARCHAR2,
  p_empl_id VARCHAR2,
  p_title VARCHAR2,
  p_on_board DATE,
  p_wentdown DATE,
  p_fr_posi_code VARCHAR2,
  p_fr_vess_code VARCHAR2,
  p_fr_eff_date DATE,
  p_to_posi_code VARCHAR2,
  p_to_vess_code VARCHAR2,
  p_to_eff_date DATE,
  p_tran_no VARCHAR2,
  p_move_type varchar2,
  p_voyage_date DATE,
  p_voyage_end_date DATE
  ) AS
  v_wentdown DATE;
  vCnt Number;
BEGIN
  select decode(p_wentdown,to_date('20990101','YYYYMMDD'),null,p_wentdown) into v_wentdown from dual;

  BEGIN
    SELECT 1 into vCnt
    FROM   PMS_CREW_LIST_mov
    WHERE  payroll_no = p_payroll_no
    AND    empl_id = p_empl_id
    AND    tran_no = p_tran_no;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
       vCnt := 0;
  END;

  IF vCnt = 0 THEN
    INSERT INTO PMS_CREW_LIST_mov
         (PAYROLL_NO, FR_DATE, TO_DATE, vess_code, empl_id, title, on_board, wentdown,
         fr_posi_code, fr_vess_code, fr_eff_date, to_posi_code, to_vess_code, to_eff_date, tran_no,
         userid, dt_created, mov_type, voyage_st_date, voyage_end_date)
    VALUES (p_PAYROLL_NO, p_FR_DATE, p_TO_DATE, p_vess_code, p_empl_id, p_title, p_on_board, v_wentdown,
         p_fr_posi_code, p_fr_vess_code, p_fr_eff_date, p_to_posi_code, p_to_vess_code, p_to_eff_date, p_tran_no,
         USER, SYSDATE, p_move_type, p_voyage_date, p_voyage_end_date);
  END IF;
EXCEPTION
  WHEN DUP_VAL_ON_INDEX THEN
    BEGIN
        --dbms_output.put_line('Sp_Insert_Crew_List : Empl Id '||p_empl_id||' : on_board '|| p_on_board||' : wentdown '|| p_wentdown);
        UPDATE  PMS_CREW_LIST_mov
        SET     on_board = p_on_board,
                wentdown = v_wentdown,
                fr_posi_code = p_fr_posi_code,
                fr_vess_code = p_fr_vess_code,
                fr_eff_date  = p_fr_eff_date,
                to_posi_code = p_to_posi_code,
                to_vess_code = p_to_vess_code,
                to_eff_date  = p_to_eff_date
        WHERE   payroll_no = p_payroll_no
        AND     empl_id    = p_empl_id
        AND     on_board   = p_on_board
        AND     ((tran_no    = p_tran_no) OR (p_tran_no IS NULL AND tran_no IS NULL));
    EXCEPTION
      WHEN DUP_VAL_ON_INDEX THEN
        /*
        UPDATE  PMS_CREW_LIST
        SET     on_board = p_on_board,
                wentdown = p_wentdown,
                fr_posi_code = p_fr_posi_code,
                fr_vess_code = p_fr_vess_code,
                fr_eff_date  = p_fr_eff_date,
                to_posi_code = p_to_posi_code,
                to_vess_code = p_to_vess_code,
                to_eff_date  = p_to_eff_date
        WHERE   payroll_no = p_payroll_no
        AND     empl_id    = p_empl_id
        AND     ((tran_no    = p_tran_no) OR (p_tran_no IS NULL AND tran_no IS NULL));
        */
        null;
       --raise_application_error(-20001,'PCL UK '||p_payroll_no||' - '||p_empl_id||'- '||p_tran_no||' - '||p_fr_posi_code||' - '||p_to_posi_code);
    END;
END Sp_Insert_Crew_List_mov;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INSERT_EMPLOYEE_INCENTIVE"
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
   p_vess_code_2  varchar2,
   p_dety_code    varchar2,
   p_dety_no      number
) as

   vErrMsg      varchar2(2000);
   d_empl_id    varchar2(20) := 'G00017';
begin
   insert into pys_employee_incentives
          (
            empl_empl_id, year, mo, period_fr, period_to, inty_code, fiso_code, vess_code, rank_code,
            basis, rate, amt, inhd_tran_no, vess_code_2, dety_code, dedu_seq_no, dt_created, created_by
          )
   values (
            p_empl_id, p_year, p_mo, p_start, p_end, p_inty_code, p_fiso_code, p_vess_code, p_rank_code,
            p_basis, p_rate, p_amt, p_inhd_tran_no, p_vess_code_2, p_dety_code, p_dety_no, trunc(sysdate), user
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
end sp_insert_employee_incentive;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INS_KAWAN_TROSO_INCENTIVE"
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

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INS_KAWAN_TROSO_INCENTIVE_F"
(
   p_cont_id      varchar2,
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
   d_cont_id    varchar2(20) := 'C00004';
begin
   IF p_cont_id = d_cont_id THEN
      DBMS_OUTPUT.PUT_LINE ('check ins kawan troso:' || p_inty_code || ',p_vess_code:' || p_vess_code || ',p_fiso_code:' ||  p_fiso_code || ',p_basis:' || TO_CHAR(p_basis));
   END IF;
   insert into pys_kawan_troso_incentives_f
          (
            cont_id, year, mo, period_fr, period_to, inty_code, fiso_code, vess_code, rank_code,
            basis, rate, amt, inhd_tran_no, dt_created, created_by
          )
   values (
            p_cont_id, p_year, p_mo, p_start, p_end, p_inty_code, p_fiso_code, p_vess_code, p_rank_code,
            p_basis, p_rate, p_amt, p_inhd_tran_no, trunc(sysdate), user
          );
   commit;
   IF p_cont_id = d_cont_id THEN
      DBMS_OUTPUT.PUT_LINE ('check ins kawan troso: commit');
   END IF;
exception
   when dup_val_on_index then
      IF p_cont_id = d_cont_id THEN
         DBMS_OUTPUT.PUT_LINE ('check insert p_inty_code:' || p_inty_code || ',p_vess_code:' || p_vess_code || ',p_fiso_code:' ||  p_fiso_code || ',p_basis:' || TO_CHAR(p_basis));
      END IF;
   when others then
      vErrMsg := SQLERRM;
      raise_application_error (-20001, vErrMsg);
end sp_ins_kawan_troso_incentive_f;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_APPROVE_BORROWING" (
   p_tran_no in varchar2 ) as
   vTranType inv_borrowing_hdr.tran_type%type;
   vSource   inv_borrowing_hdr.vess_code%type;
   vRSNO     inv_borrowing_hdr.rshd_rs_no%type;
   nReleasedQty Number(12,3);
   nTotReleased Number(12,3);
begin
   begin
      select tran_type, vess_code, rshd_rs_no
      into   vTranType, vSource, vRSNO
      from   inv_borrowing_hdr
      where  tran_no = p_tran_no
      and    status = 'FOR APPROVAL';
   exception
      when no_data_found then null;
   end;
   if vTranType = 'BORROW' then
      for i in (select d.rshd_rs_no, d.vess_code lender, d.item_code, d.cate_code, d.itty_code, d.itgr_code, d.uome_code, d.qty, d.repl_rs_no, h.vess_code borrower
                from   inv_borrowing_dtl d, inv_borrowing_hdr h
                where  h.tran_no = d.tran_no
                and    h.tran_no = p_tran_no)
      loop
         -- UPDATE REQUISITION SLIP
         update inv_reqslip_dtl
         set    borrowed_qty = least(nvl(borrowed_qty,0) + i.qty, approved_qty)
         where  rshd_rs_no = i.rshd_rs_no
         and    item_code = i.item_code
         and    cate_code = i.cate_code
         and    itty_code = i.itty_code
         and    itgr_code = i.itgr_code
         and    uome_code = i.uome_code;
         -- UPDATE DELIVERIES
         nReleasedQty := 0;
         nTotReleased := 0;
         for k in (select d.drhd_dr_no, d.pohd_po_no, d.rshd_rs_no, d.item_code, d.cate_code, d.itty_code, d.itgr_code, d.uome_code, d.qty, nvl(d.borrowed_qty,0) borrowed_qty
                   from   inv_dr_dtl d, inv_dr_hdr h
                   where  d.drhd_dr_no = h.dr_no
                   and    h.status = 'POSTED'
                   and    d.rshd_rs_no = i.rshd_rs_no
                   and    d.item_code = i.item_code
                   and    d.cate_code = i.cate_code
                   and    d.itty_code = i.itty_code
                   and    d.itgr_code = i.itgr_code
                   and    d.uome_code = i.uome_code
                   order by d.drhd_dr_no
                  )
         loop
            if (i.qty-nTotReleased) > (k.qty-k.borrowed_qty) then
               nReleasedQty := (k.qty-k.borrowed_qty);
            else
               nReleasedQty := (i.qty-nTotReleased);
            end if;
            if nReleasedQty > 0 then
               update inv_dr_dtl
               set    qty_to_release = nReleasedQty,
                      borrowed_qty = k.borrowed_qty + nReleasedQty,
                      borrowed_by = i.borrower,
                      borrowed_rs = i.repl_rs_no
               where  rshd_rs_no = i.rshd_rs_no
               and    item_code = i.item_code
               and    cate_code = i.cate_code
               and    itty_code = i.itty_code
               and    itgr_code = i.itgr_code
               and    uome_code = i.uome_code
               and    drhd_dr_no = k.drhd_dr_no
               and    pohd_po_no = k.pohd_po_no;
               update inv_wsm_rr set downloaded='U' where rr_no = k.drhd_dr_no;
            end if;
            nTotReleased := nTotReleased + nReleasedQty;
            if nTotReleased >= i.qty then
               exit;
            end if;
         end loop;
      end loop;
   end if;
   commit;
end sp_inv_approve_borrowing;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_APPROVE_CS" (
   p_cs_no  in varchar2,
   p_rs_no  in varchar2
  ) as
   vPO_No     Varchar2(16);
   vDesc      Varchar2(1024);
   vSuppCode  Varchar2(16);
   vCtr       Number;
   vTotalCost Number;
   vTotalCostTmp Number;
BEGIN
   begin
      -- insert into PO
      for i in (
                 select a.supp_code, a.rshd_rs_no, h.prepared_by prepared_by, max(a.currency) currency, max(a.terms) terms,
                        h.dt_prepared dt_prepared, 'FOR APPROVAL' status, h.created_by created_by, h.remarks
                 from   INV_CANVASS_DTL a, inv_reqslip_hdr c, inv_canvass_hdr h
                 where  a.cshd_cs_no = h.cs_no
                 and    a.rshd_rs_no = c.rs_no
                 and    a.cshd_cs_no = p_cs_no
                 group  by a.supp_code, a.rshd_rs_no, h.prepared_by, h.dt_prepared, h.created_by, h.remarks
                 order  by a.supp_code asc
               )
      loop
         if i.supp_code is null then
            -- msg_alert ('Error in Approving Canvass.', 'E', TRUE);
            raise_application_error(-20001, 'Error in Approving Canvass - No selected Supplier.');
            exit;
         end if;

         -- create PO hdr
         select po_seq.nextval into vPO_No from dual;

         insert into inv_po_hdr
                (po_no, supp_code, rshd_rs_no, po_date, prepared_by, dt_prepared, status, currency, created_by, dt_created, terms, remarks)
         values (lpad(vPO_No,6,0), i.supp_code, i.rshd_rs_no, trunc(sysdate), i.prepared_by, sysdate, i.status, i.currency, i.created_by, sysdate, i.terms, i.remarks);

         for j in (
                    select a.currency, a.cate_code, a.itty_code, a.itgr_code, a.item_code, c.vess_code,
                           a.qty_approved, a.unit_cost, a.discount, a.uome_code, a.terms
                    from   INV_CANVASS_DTL a, inv_reqslip_hdr c
                    where  a.cshd_cs_no = p_cs_no
                    and    a.rshd_rs_no = c.rs_no
                    and    a.supp_code = i.supp_code
                  )
         loop
            vTotalCostTmp := nvl(j.unit_cost,0)*nvl(j.qty_approved,0);
            vTotalCost    := nvl(vTotalCostTmp,0) - (nvl(vTotalCostTmp,0)*nvl(j.discount,0)/100);

            -- populate PO dtl
            insert into inv_po_dtl
                   (pohd_po_no, rshd_rs_no, cate_code, itty_code, itgr_code, item_code, intended_for,
                    approved_qty, rs_qty, unit_cost, total_cost, discount, uome_code, supp_code,
                    created_by, dt_created, po_date, description)
            values
                   (lpad(vPO_No,6,0), i.rshd_rs_no, j.cate_code, j.itty_code, j.itgr_code, j.item_code, j.vess_code,
                    j.qty_approved, j.qty_approved, j.unit_cost, vTotalCost, j.discount, j.uome_code, i.supp_code,
                    user, sysdate, sysdate, vDesc);

            update inv_po_hdr
            set    po_amt = nvl(po_amt,0) + (NVL(j.unit_cost,0)*(j.qty_approved))*((100-NVL(j.discount,0))/100)
            where  po_no = lpad(vPO_No,6,0);

            update inv_reqslip_dtl
            set    pohd_po_no = lpad(vPO_No,6,0)
            where  item_code = j.item_code
            and    cate_code = j.cate_code
            and    itty_code = j.itty_code
            and    itgr_code = j.itgr_code
            and    uome_code = j.uome_code
            and    rshd_rs_no = i.rshd_rs_no;

            update inv_canvass_dtl
            set    pohd_po_no = lpad(vPO_No,6,0)
            where  cshd_cs_no = p_cs_no
            and    item_code  = j.item_code
            and    cate_code  = j.cate_code
            and    itty_code  = j.itty_code
            and    itgr_code  = j.itgr_code
            and    uome_code  = j.uome_code
            and    rshd_rs_no = i.rshd_rs_no;

            vTotalCostTmp := 0;
            vTotalCost    := 0;
            vSuppCode     := i.supp_code;
            vCtr          := vCtr + 1;
            vDesc         := null;
         end loop;
      end loop;
   exception
      when others then
         rollback;
         -- msg_alert('Error in Approving Canvass. Ora - '||SQLCODE||' '||SQLERRM,'E',TRUE);
         raise_application_error(-20001, 'Error in Approving Canvass. Ora - ' || SQLCODE || ' ' || SQLERRM);
   end;

   /*
   -- update inv_canvass_dtl
   -- set    status  = 'APPROVED'
   -- where  cshd_cs_no = p_cs_no;
   */

   update inv_reqslip_hdr
   set    rs_cs_status = NVL(sf_get_rs_cs_status(rs_no),rs_cs_status)
   where  rs_no = p_rs_no;

   update inv_canvass_hdr
   set  status = 'APPROVED',
        approved_by = sf_get_empl(user),
        dt_approved = sysdate
   where cs_no = p_cs_no;

   commit;

end sp_inv_approve_cs;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_APPROVE_ISS" (
   p_iss_no in varchar2,
   p_rs_no  in varchar2
  ) as
   vStatus       Varchar2(16);
   vVessCode     Varchar2(16);
   vDtlCnt       Number := 0;
   vBorrowedBy   Varchar2(16);
   vBorrowedRs   Varchar2(16);
   vRSno         Varchar2(16);
   nQtyToRelease Number;
   nBorrowedQty  Number;
   nActualQty    Number;
   nAllocQty     Number;
   nQty          Number;
   vCheck        Char(1);
BEGIN
   begin
      for a in ( select item_code,cate_code,itty_code,itgr_code,uome_code, iss_qty, ref_type, ref_no, rshd_rs_no, dr_no
                 from   inv_iss_dtl
                 where  ishd_iss_no = p_iss_no)
      loop
         if a.item_code is null or a.cate_code is null or a.itgr_code is null or a.itty_code is null or a.uome_code is null then
            raise_application_error(-20001, 'Error in Approving Issuance');
         end if;

         if a.ref_type = 'WR' then
            begin
               select 'Y'
               into   vcheck
               from   inv_item_ware
               where  item_code = a.item_code
               and    cate_code = a.cate_code
               and    itgr_code = a.itgr_code
               and    uome_code = a.uome_code
               and    itty_code = a.itty_code
               and    ware_code = a.ref_no
               and    nvl(dr_no,'STOCK') = nvl(a.dr_no,'STOCK')
               and    qty_avail >= a.iss_qty;
            exception
               when no_data_found then
                  raise_application_error(-20001, 'Warehouse '||a.ref_no||' has no available item for '||get_item_desc(a.item_code,a.cate_code,a.itty_code,a.itgr_code)||' or less than issuing quantity.');
            end;

            update inv_item_ware
            set    qty_avail = qty_avail-nvl(a.iss_qty,0),
                   qty_alloc = qty_alloc+nvl(a.iss_qty,0)
            where  item_code = a.item_code
            and    cate_code = a.cate_code
            and    itgr_code = a.itgr_code
            and    uome_code = a.uome_code
            and    itty_code = a.itty_code
            and    ware_code = a.ref_no
            and    nvl(dr_no,'STOCK') = nvl(a.dr_no,'STOCK');
         end if;

         if a.ref_type = 'DR' then
            select d.rshd_rs_no, d.Qty, d.qty_to_release, d.borrowed_by, nvl(d.borrowed_rs,d.rshd_rs_no), d.borrowed_qty, d.qty_actual, d.qty_alloc, r.vess_code
            into   vRSno, nQty, nQtyToRelease, vBorrowedBy, vBorrowedRs, nBorrowedQty, nActualQty, nAllocQty, vVessCode
            from   inv_dr_dtl d, inv_reqslip_hdr r
            where  d.item_code = a.item_code
            and    d.cate_code = a.cate_code
            and    d.itgr_code = a.itgr_code
            and    d.uome_code = a.uome_code
            and    d.itty_code = a.itty_code
            and    d.drhd_dr_no = a.ref_no
            and    d.rshd_rs_no = r.rs_no;
            --and    d.rshd_rs_no = a.rshd_rs_no
            --and    (qty_actual-qty_alloc) >= a.iss_qty;

            if (vBorrowedRs <> a.rshd_rs_no) then
               raise_application_error(-20001, 'Error in Approving Issuance');
            end if;

            if (nQtyToRelease > 0) and (vBorrowedBy <> vVessCode) and ((nQty-nBorrowedQty) > 0) then
               update inv_dr_dtl
               set    qty_to_release = nQty-nBorrowedQty,
                      borrowed_by = vVessCode,
                      borrowed_rs = vRSno
               where  rshd_rs_no = vRSno
               and    item_code = a.item_code
               and    cate_code = a.cate_code
               and    itgr_code = a.itgr_code
               and    uome_code = a.uome_code
               and    itty_code = a.itty_code;
               -- update
               update inv_wsm_rr
               set    downloaded='U'
               where  rr_no = a.ref_no;
            end if;

            if vBorrowedRs is null then
               if (nActualQty-nAllocQty) >= a.iss_qty then
                  raise_application_error(-20001, 'DR No. ' || a.ref_no || ' has no available item for ' || get_item_desc(a.item_code,a.cate_code,a.itty_code,a.itgr_code) || ' or less than issuing quantity.');
               end if;
            end if;

            update inv_dr_dtl
            set    qty_alloc = qty_alloc + nvl(a.iss_qty,0)
            where  item_code = a.item_code
            and    cate_code = a.cate_code
            and    itgr_code = a.itgr_code
            and    uome_code = a.uome_code
            and    itty_code = a.itty_code
            and    drhd_dr_no = a.ref_no;
         end if;

         if a.dr_no <> 'STOCK' then
            update inv_items_log
            set    bal_qty = nvl(bal_qty,0) - nvl(a.iss_qty,0)
            where  code      = a.item_code
            and    cate_code = a.cate_code
            and    itgr_code = a.itgr_code
            and    uome_code = a.uome_code
            and    itty_code = a.itty_code;
         end if;

         insert into inv_item_audit_log( action, itty_code, itgr_code, cate_code, item_code, uome_code, qty, created_by, dt_created, info, ref_type, ref_no, dr_no)
         values ('ISSUANCE',a.itty_code, a.itgr_code, a.cate_code, a.item_code, a.uome_code, a.iss_qty, user, sysdate, 'Iss No. '|| p_iss_no || ' - RS No. ' || p_rs_no, a.ref_type, a.ref_no, a.dr_no);
      end loop;
   exception
      when others then
         rollback;
   end;

   update inv_reqslip_hdr
   set    rs_iss_status = sf_get_rs_iss_status(p_rs_no)
   where  rs_no = p_rs_no;

   sp_inv_create_iss_monitoring(p_iss_no);
   commit;

END sp_inv_approve_iss;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_APPROVE_TRANSFER" (
   p_tran_no in varchar2
  ) as
begin
   for i in ( select ishd_iss_no, item_code, cate_code, itty_code, itgr_code, uome_code, qty,
                     rshd_rs_no, ref_type, ref_no, dr_no
              from   inv_transfer_dtl
              where  tran_no = p_tran_no)
   loop
      update inv_iss_dtl
      set    tr_qty = tr_qty + i.qty
      where  item_code = i.item_code
      and    uome_code = i.uome_code
      and    cate_code = i.cate_code
      and    itty_code = i.itty_code
      and    itgr_code = i.itgr_code
      and    ref_type = i.ref_type
      and    ref_no = i.ref_no
      and    dr_no = i.dr_no
      and    ishd_iss_no = i.ishd_iss_no;
   end loop;
   commit;
end sp_inv_approve_transfer;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_APPROVE_WARE_TRANSFER" (
   p_tran_no in varchar2
  ) as
begin
   null;
   for a in ( select tran_no, item_code, cate_code, itty_code, itgr_code, uome_code, qty
              from   inv_ware_transfer_dtl
              where  tran_no = p_tran_no)
   loop
      exit;
   end loop;
end sp_inv_approve_ware_transfer;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_CANCEL_DELIVERY" (p_dr_no VARCHAR2) AS
  v_pohd_po_no INV_PO_HDR.po_no%TYPE;
  v_dr_status  INV_DR_HDR.status%TYPE;
  v_fstock     INV_REQSLIP_HDR.for_stock%TYPE;
  v_rshd_rs_no INV_REQSLIP_HDR.rs_no%TYPE;
  v_wcode      INV_WAREHOUSE.code%TYPE;
BEGIN
  FOR a IN (
     SELECT ishd_iss_no FROM INV_ISS_DTL isdt, INV_ISS_HDR ishd
  WHERE  isdt.ishd_iss_no = ishd.iss_no
  AND    status IN ('APPROVED','FOR APPROVAL')
  AND    ref_no = p_dr_no)
  LOOP
     DBMS_OUTPUT.PUT_LINE('Cannot Cancel Delivery with active Issuance No. '||a.ishd_iss_no||'.');
     RETURN;
  END LOOP;
  BEGIN
    SELECT pohd_po_no, status
    INTO   v_pohd_po_no, v_dr_status
    FROM   INV_DR_HDR
    WHERE  dr_no = p_dr_no;
  EXCEPTION
    WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20001,'DR not exists. '||SQLERRM);
  END;
  IF v_dr_status <> 'POSTED' THEN
     DBMS_OUTPUT.PUT_LINE('Cannot cancel not approved Delivery');
     RETURN;
  END IF;

  BEGIN
    SELECT rshd.for_stock INTO v_fstock
    FROM   INV_REQSLIP_HDR rshd, INV_PO_HDR pohd
    WHERE  pohd.rshd_rs_no = rshd.rs_no
    AND    pohd.po_no = v_pohd_po_no;
  EXCEPTION
    WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20001,'RS Not exists. '||SQLERRM);
  END;

  FOR a IN (
    SELECT code FROM INV_WAREHOUSE ORDER BY code)
  LOOP
     v_wcode := a.code;
     EXIT;
  END LOOP;

  IF NVL(v_fstock,'N') = 'N' AND v_wcode IS NULL THEN
     DBMS_OUTPUT.PUT_LINE('Error in Approving. No warehouse declared.');
     RETURN;
  END IF;

  FOR a IN (
    SELECT cate_code, itty_code, itgr_code, item_code, uome_code, qty
    FROM   INV_DR_DTL
    WHERE  drhd_dr_no = p_dr_no)
  LOOP
    UPDATE INV_PO_DTL
    SET    dr_qty = GREATEST(dr_qty - ABS(NVL(a.qty,0)),0)
    WHERE  item_code  = a.item_code
    AND    cate_code  = a.cate_code
    AND    itty_code  = a.itty_code
    AND    itgr_code  = a.itgr_code
    AND    uome_code  = a.uome_code
    AND    pohd_po_no = v_pohd_po_no;
    IF NVL(v_fstock,'N') = 'N' THEN
       UPDATE INV_REQSLIP_DTL rsdt
       SET    rsdt.rr_qty = NVL(rsdt.rr_qty,0) - a.qty
       WHERE  rsdt.rshd_rs_no = v_rshd_rs_no
       AND    rsdt.item_code  = a.item_code
       AND    rsdt.cate_code  = a.cate_code
       AND    rsdt.itgr_code  = a.itgr_code
       AND    rsdt.uome_code  = a.uome_code
       AND    rsdt.itty_code  = a.itty_code;

       UPDATE INV_ITEMS_LOG
       SET    tot_qty = NVL(tot_qty,0) - NVL(a.qty,0),
              bal_qty = NVL(bal_qty,0) - NVL(a.qty,0)
       WHERE  code      = a.item_code
       AND    cate_code = a.cate_code
       AND    itgr_code = a.itgr_code
       AND    uome_code = a.uome_code
       AND    itty_code = a.itty_code;

       INSERT INTO INV_ITEM_AUDIT_LOG( action, itty_code, itgr_code, cate_code, item_code, uome_code, qty, created_by, dt_created, info)
       VALUES ('PO_DELIVERY-C',a.itty_code, a.itgr_code, a.cate_code, a.item_code, a.uome_code, a.qty, USER, SYSDATE,'DR No. '||p_dr_no||' - PO No. '||v_pohd_po_no);
    ELSE
       UPDATE INV_ITEM_WARE iw
       SET    iw.qty = NVL(iw.qty,0) - NVL(a.qty,0),
              iw.qty_avail = NVL(iw.qty_avail,0) - NVL(a.qty,0)
       WHERE  iw.dr_no     = p_dr_no
       AND    iw.ware_code = v_wcode
       AND    iw.item_code = a.item_code
       AND    iw.cate_code = a.cate_code
       AND    iw.itty_code = a.itty_code
       AND    iw.itgr_code = a.itgr_code
       AND    iw.uome_code = a.uome_code;

       INSERT INTO INV_ITEM_AUDIT_LOG( action, itty_code, itgr_code, cate_code, item_code, uome_code, qty, created_by, dt_created, info)
       VALUES ('PO_DELIVERY-C',a.itty_code, a.itgr_code, a.cate_code, a.item_code, a.uome_code, a.qty, USER, SYSDATE,'DR No. '||p_dr_no||' - PO No. '||v_pohd_po_no||' For Stock');
    END IF;
  END LOOP;

  UPDATE INV_PO_HDR
  SET    po_dr_status = NVL(Sf_Get_Po_Dr_Status(po_no),po_dr_status)
  WHERE  po_no = v_pohd_po_no;

  UPDATE INV_DR_HDR
  SET    status = 'CANCELLED',
         posted_by = Sf_Get_Empl(USER)
  WHERE  dr_no = p_dr_no;

END;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_CANCEL_ISSUANCE" (p_iss_no VARCHAR2) AS
  v_rshd_rs_no INV_REQSLIP_HDR.rs_no%TYPE;
  v_iss_status INV_ISS_HDR.status%TYPE;
BEGIN
  BEGIN
    SELECT rshd_rs_no, status
    INTO   v_rshd_rs_no, v_iss_status
    FROM   INV_ISS_HDR
    WHERE  iss_no = p_iss_no;
  EXCEPTION
    WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR(-20001,SQLERRM);
  END;
  IF v_iss_status <> 'APPROVED' THEN
     DBMS_OUTPUT.PUT_LINE('Cannot cancel not approved Issuance');
     RETURN;
  END IF;

  FOR a IN (
    SELECT item_code, cate_code, itty_code, itgr_code, uome_code, iss_qty, ref_type, ref_no, rshd_rs_no, dr_no
    FROM   INV_ISS_DTL
    WHERE  ishd_iss_no = p_iss_no)
  LOOP

    IF a.ref_type = 'WR' THEN
       UPDATE INV_ITEM_WARE
       SET    qty_avail = qty_avail + NVL(a.iss_qty,0),
              qty_alloc = qty_alloc - NVL(a.iss_qty,0)
       WHERE  item_code = a.item_code
       AND    cate_code = a.cate_code
       AND    itgr_code = a.itgr_code
       AND    uome_code = a.uome_code
       AND    itty_code = a.itty_code
       AND    ware_code = a.ref_no
       AND    NVL(dr_no,'STOCK') = NVL(a.dr_no,'STOCK');
    END IF;

    IF a.ref_type = 'DR' THEN
       UPDATE INV_DR_DTL
       SET    qty_alloc = qty_alloc - NVL(a.iss_qty,0)
       WHERE  item_code = a.item_code
       AND    cate_code = a.cate_code
       AND    itgr_code = a.itgr_code
       AND    uome_code = a.uome_code
       AND    itty_code = a.itty_code
       AND    drhd_dr_no = a.ref_no;
    END IF;

    IF a.dr_no <> 'STOCK' THEN
       UPDATE INV_ITEMS_LOG
       SET    bal_qty = NVL(bal_qty,0) + NVL(a.iss_qty,0)
       WHERE  code      = a.item_code
       AND    cate_code = a.cate_code
       AND    itgr_code = a.itgr_code
       AND    uome_code = a.uome_code
       AND    itty_code = a.itty_code;
    END IF;

 UPDATE INV_REQSLIP_DTL
    SET    iss_qty = GREATEST(iss_qty - ABS(NVL(a.iss_qty,0)),0)
    WHERE  item_code  = a.item_code
    AND    cate_code  = a.cate_code
    AND    itty_code  = a.itty_code
    AND    itgr_code  = a.itgr_code
    AND    uome_code  = a.uome_code
    AND    rshd_rs_no = v_rshd_rs_no;

    INSERT INTO INV_ITEM_AUDIT_LOG( action, itty_code, itgr_code, cate_code, item_code, uome_code, qty, created_by, dt_created, info, ref_type, ref_no, dr_no)
    VALUES ('ISSUANCE-C',a.itty_code, a.itgr_code, a.cate_code, a.item_code, a.uome_code, a.iss_qty, USER, SYSDATE, 'Iss No. '||p_iss_no||' - RS No. '||v_rshd_rs_no, a.ref_type, a.ref_no, a.dr_no);
  END LOOP;

  UPDATE INV_REQSLIP_HDR
  SET    rs_iss_status = Sf_Get_Rs_Iss_Status(rs_no)
  WHERE  rs_no = v_rshd_rs_no;

  UPDATE INV_ISS_HDR
  SET    status = 'CANCELLED',
         approved_by = Sf_Get_Empl(USER)
  WHERE  iss_no = p_iss_no;

END;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_CREATE_ISS_MONITORING" (p_iss_no in varchar2) as
   nItem NUmber := 0;
begin
   for i in (select d.item_code, d.itty_code, d.cate_code, d.itgr_code, d.uome_code, d.iss_qty, d.ref_no, d.ref_type, d.dr_no,
             h.prepared_by received_by, h.dt_prepared dt_received
             from   inv_iss_dtl d, inv_iss_hdr h
             where  d.ishd_iss_no = p_iss_no
             and    d.ishd_iss_no = h.iss_no )
   loop
      nItem := nItem + 1;
      insert into inv_iss_transfer_log (
              ishd_iss_no, item_no, item_code, itty_code, cate_code, itgr_code, uome_code, iss_qty, ref_type, ref_no, dr_no,
              transfer_code, received_by, received_by_name, dt_received, remarks, created_by, dt_created)
      values (p_iss_no, nItem, i.item_code, i.itty_code, i.cate_code, i.itgr_code, i.uome_code, i.iss_qty, i.ref_type, i.ref_no, i.dr_no,
              'In-Transit to GenSan', i.received_by, Sf_Get_Empl_Name(i.received_by), i.dt_received, null, user, sysdate);

   end loop;
   commit;
end;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_CREATE_RR" (
   p_po_no in varchar2
   ) as
   vRR_No Varchar2(16);
   vRS_No Varchar2(16);
   vPO_Date Date;
   vSupp_Code Varchar2(16);
   vCurrency  Varchar2(16);
   nCurr_Cnv Number;
   dRR_Date Date;
   vRemarks Varchar2(255);
   vOfc_Code Varchar2(16);
begin
   dRR_Date := trunc(sysdate);
   select pohd.rshd_rs_no,
          pohd.po_date,
          pohd.supp_code,
          pohd.currency,
          rshd.remarks,
          rshd.ofc_code
   into   vRS_No,
          vPO_Date,
          vSupp_Code,
          vCurrency,
          vRemarks,
          vOfc_Code
   from   inv_po_hdr pohd, inv_reqslip_hdr rshd
   where  pohd.status = 'APPROVED'
   and    pohd.po_dr_status <> 'FULLY DELIVERED'
   and    pohd.rshd_rs_no = rshd.rs_no
   and    pohd.po_no = p_po_no;

   if vCurrency = 'PHP' then
      nCurr_Cnv := 1;
   else
      begin
         select fx_value into nCurr_Cnv from acc_forex where fx_date = dRR_Date and curr_code = vCurrency;
      exception
         when no_data_found then
            raise_application_error(-20001, 'Cannot Post RR with Foreign Currency. Converstion not available.');
      end;
   end if;

   select lpad(drhd_seq.nextval,6,'0') into vRR_No from dual;
   insert into inv_dr_hdr
          ( dr_no, pohd_po_no, supp_code, dr_date, status,
            curr_cnv, currency, ofc_code, remarks,
            created_by, dt_created,  prepared_by, dt_prepared
          )
   values (vRR_No, p_po_no, vSupp_Code, dRR_Date, 'FOR APPROVAL',
           nCurr_Cnv, vCurrency, vOfc_Code, vRemarks,
           user, sysdate, sf_get_empl(USER), sysdate
          );

   insert into inv_dr_dtl
          (drhd_dr_no, pohd_po_no, rshd_rs_no, item_code, cate_code, itty_code, itgr_code, uome_code, qty,
           unit_cost, supp_code, dr_date, total_cost, discount, created_by, dt_created, currency,
           qty_alloc, qty_actual, prepared_by, dt_prepared
          )
   select vRR_No, p_po_no, vRS_No, item_code, cate_code, itty_code, itgr_code, uome_code, 0,
          unit_cost, vSupp_Code, dRR_Date, total_cost, discount, user, sysdate, vCurrency,
          0, 0, sf_get_empl(USER), sysdate
   from   inv_po_dtl
   where  pohd_po_no = p_po_no;

   commit;
end sp_inv_create_rr;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_GET_PROD_DATE" (
   p_rs_no      in  varchar2,
   p_rs_date    in  date,
   p_prod_basis in  varchar2,
   p_prod_time  in  number,
   p_prod_start out date,
   p_prod_end   out date
) as
   dProdStaDt Date;
   dProdEndDt Date;
BEGIN
   IF (p_prod_time is not null) AND (p_prod_time > 0) THEN
      IF p_prod_basis = 'RS' THEN
         dProdStaDt := p_rs_date;
      ELSIF p_prod_basis = 'PO' THEN
         select min(po_date)
         into   dProdStaDt
         from   inv_po_hdr
         where  rshd_rs_no = p_rs_no;
      ELSIF p_prod_basis = 'AP' THEN
         -- select min(h.ap_date)
         -- into   dProdStaDt
         -- from   acc_ap_inv_dtl d, acc_ap_hdr h
         -- where  d.ap_no = h.ap_no
         -- and    d.rs_no = p_rs_no;
         select min(h.ref_date)
         into   dProdStaDt
         from   inv_rs_acc_dtl h
         where  h.rs_no = p_rs_no;
      ELSE
         dProdStaDt := NULL;
         dProdEndDt := NULL;
      END IF;
      IF dProdStaDt is not null THEN
         dProdEndDt := dProdStaDt + p_prod_time;
      ELSE
         dProdEndDt := NULL;
      END IF;
   ELSE
      dProdStaDt := NULL;
      dProdEndDt := NULL;
   END IF;
   p_prod_start := dProdStaDt;
   p_prod_end   := dProdEndDt;
END sp_inv_get_prod_date;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_POST_RR" (p_dr_no in varchar2) as
   vStatus Varchar2(16);
   vFStock Char(1);
   vWCode  Varchar2(16);
   vPONo   Varchar2(16);
   vRSNo   Varchar2(16);
   vRcvd   Varchar2(30);
   dRcvd   Date;
BEGIN
   select rshd.for_stock, pohd.po_no, pohd.rshd_rs_no, drhd.received_by, drhd.dt_received
   into   vFStock, vPONo, vRSNo, vRcvd, dRcvd
   from   inv_reqslip_hdr rshd, inv_po_hdr pohd, inv_dr_hdr drhd
   where  pohd.rshd_rs_no = rshd.rs_no
   and    pohd.po_no = drhd.pohd_po_no
   and    drhd.dr_no = p_dr_no;

   for a in ( select code from inv_warehouse order by code) loop
     vWCode := a.code;
     exit;
   end loop;

   if nvl(vFStock,'N') = 'N' and vWCode is null then
      raise_application_error (-20001, 'Error in Posting. No warehouse declared.');
   end if;

   begin
      for i in ( select d.item_code, d.cate_code, d.itty_code, d.itgr_code, d.uome_code,
                        d.qty, d.unit_cost, d.currency, d.discount,
                        d.pohd_po_no po_no, d.rshd_rs_no rs_no
                 from   inv_dr_dtl d
                 where  d.drhd_dr_no = p_dr_no)
      loop
         if i.item_code is null or i.cate_code is null or i.itgr_code is null or i.itty_code is null or i.uome_code is null then
            rollback;
            raise_application_error(-20001, 'Error in Posting DR - no items entered.');
         end if;

         update inv_reqslip_dtl rsdt
         set    rsdt.rr_qty = nvl(rsdt.rr_qty,0)+i.qty,
                rsdt.prodn_rcvd_by = decode(rsdt.production_time, null, null, decode(rsdt.prodn_rcvd_by, null, vRcvd, rsdt.prodn_rcvd_by)),
                rsdt.prodn_rcvd_dt = decode(rsdt.production_time, null, null, decode(rsdt.prodn_rcvd_dt, null, dRcvd, rsdt.prodn_rcvd_dt)),
                rsdt.prodn_rcvd_flag = decode(rsdt.production_time, null, null, 'Y')
         where  rsdt.rshd_rs_no = i.rs_no
         and    rsdt.item_code  = i.item_code
         and    rsdt.cate_code  = i.cate_code
         and    rsdt.itgr_code  = i.itgr_code
         and    rsdt.uome_code  = i.uome_code
         and    rsdt.itty_code  = i.itty_code;

         if nvl(vFStock,'N') = 'N' then
            update inv_items_log
            set    tot_qty = nvl(tot_qty,0) + nvl(i.qty,0),
                   bal_qty = nvl(bal_qty,0) + nvl(i.qty,0)
            where  code      = i.item_code
            and    cate_code = i.cate_code
            and    itgr_code = i.itgr_code
            and    uome_code = i.uome_code
            and    itty_code = i.itty_code;

            insert into inv_item_audit_log( action, itty_code, itgr_code, cate_code, item_code, uome_code, qty, created_by, dt_created, info)
            values ('PO_DELIVERY',i.itty_code, i.itgr_code, i.cate_code, i.item_code, i.uome_code, i.qty, user, sysdate, 'DR No. ' || p_dr_no || ' - PO No. ' || vPONo);
         else
            begin
               insert into inv_item_ware
                      (ware_code, dr_no, itty_code, itgr_code, cate_code, item_code, uome_code, qty, qty_avail,
                       qty_alloc, created_by, dt_created, modified_by, dt_modified, unit_cost, currency, discount,
                       po_no, rs_no)
               values (vWCode, p_dr_no, i.itty_code, i.itgr_code, i.cate_code, i.item_code, i.uome_code, i.qty, i.qty,

                       0, user, sysdate, null, null, i.unit_cost, i.currency, i.discount,
                       i.po_no, i.rs_no);
            exception
               when dup_val_on_index then
                  update inv_item_ware iw
                  set    iw.qty = nvl(iw.qty,0) + nvl(i.qty,0),
                         iw.qty_avail = nvl(iw.qty_avail,0) + nvl(i.qty,0)
                  where  iw.dr_no     = p_dr_no
                  and    iw.ware_code = vWCode
                  and    iw.item_code = i.item_code
                  and    iw.cate_code = i.cate_code
                  and    iw.itty_code = i.itty_code
                  and    iw.itgr_code = i.itgr_code
                  and    iw.uome_code = i.uome_code;
            end;
            insert into inv_item_audit_log
                   (action, itty_code, itgr_code, cate_code, item_code, uome_code, qty, created_by, dt_created, info)
            values ('PO_DELIVERY', i.itty_code, i.itgr_code, i.cate_code, i.item_code, i.uome_code, i.qty, user, sysdate,'DR No. ' || p_dr_no || ' - PO No. ' || vPONo ||' For Stock');
         end if;
      end loop;
   exception
      when others then
         rollback;
         raise_application_error(-20001, 'Error in Posting DR - ' || SQLERRM);
   end;

   update inv_po_hdr
   set    po_dr_status = nvl(sf_get_po_dr_status(vPONo), po_dr_status)
   where  po_no = vPONo;
   commit;
END sp_inv_post_rr;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_PRINT_RR" (p_rr_no in varchar2) as
begin
  update inv_wsm_rr set downloaded='P' where rr_no = p_rr_no;
  commit;
end sp_inv_print_rr;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_INV_RR_WITH_BORROWING" (
   p_rs_no in varchar2,
   p_po_no in varchar2,
   p_dr_no in varchar2 ) as
   nReleasedQty Number(12,3);
   nTotReleased Number(12,3);
begin
   for i in (select bodt.rshd_rs_no, bohd.vess_code, bodt.item_code, bodt.cate_code, bodt.itty_code, bodt.itgr_code, bodt.uome_code, bodt.qty, bodt.repl_rs_no
             from   inv_borrowing_dtl bodt, inv_borrowing_hdr bohd
             where  bodt.tran_no = bohd.tran_no
             and    exists (select 1
                            from   inv_dr_dtl drdt, inv_reqslip_dtl rsdt
                            where  drdt.drhd_dr_no = p_dr_no
                            and    drdt.rshd_rs_no = p_rs_no
                            and    drdt.pohd_po_no = p_po_no
                            and    drdt.rshd_rs_no = rsdt.rshd_rs_no
                            and    drdt.item_code = rsdt.item_code
                            and    drdt.cate_code = rsdt.cate_code
                            and    drdt.itty_code = rsdt.itty_code
                            and    drdt.itgr_code = rsdt.itgr_code
                            and    drdt.uome_code = rsdt.uome_code
                            and    drdt.rshd_rs_no = bodt.rshd_rs_no
                            and    drdt.item_code = bodt.item_code
                            and    drdt.cate_code = bodt.cate_code
                            and    drdt.itty_code = bodt.itty_code
                            and    drdt.itgr_code = bodt.itgr_code
                            and    drdt.uome_code = bodt.uome_code)
            )
   loop
      -- UPDATE DELIVERIES
      nReleasedQty := 0;
      nTotReleased := 0;
      for k in (select d.drhd_dr_no, d.pohd_po_no, d.rshd_rs_no, d.item_code, d.cate_code, d.itty_code, d.itgr_code, d.uome_code, d.qty, nvl(d.borrowed_qty,0) borrowed_qty
                from   inv_dr_dtl d, inv_dr_hdr h
                where  d.drhd_dr_no = p_dr_no
                and    d.rshd_rs_no = p_rs_no
                and    d.pohd_po_no = p_po_no
                and    d.drhd_dr_no = h.dr_no
                and    h.status = 'POSTED'
                and    d.rshd_rs_no = i.rshd_rs_no
                and    d.item_code = i.item_code
                and    d.cate_code = i.cate_code
                and    d.itty_code = i.itty_code
                and    d.itgr_code = i.itgr_code
                and    d.uome_code = i.uome_code
                order by d.drhd_dr_no
               )
      loop
         if (i.qty-nTotReleased) > (k.qty-k.borrowed_qty) then
            nReleasedQty := (k.qty-k.borrowed_qty);
         else
            nReleasedQty := (i.qty-nTotReleased);
         end if;
         if nReleasedQty > 0 then
            update inv_dr_dtl
            set    qty_to_release = nReleasedQty,
                   borrowed_qty = k.borrowed_qty + nReleasedQty,
                   borrowed_by = i.vess_code,
                   borrowed_rs = i.repl_rs_no
            where  rshd_rs_no = i.rshd_rs_no
            and    item_code = i.item_code
            and    cate_code = i.cate_code
            and    itty_code = i.itty_code
            and    itgr_code = i.itgr_code
            and    uome_code = i.uome_code
            and    drhd_dr_no = k.drhd_dr_no
            and    pohd_po_no = k.pohd_po_no
            and    rshd_rs_no = k.rshd_rs_no;
         end if;
         nTotReleased := nTotReleased + nReleasedQty;
         if nTotReleased >= i.qty then
            exit;
         end if;
      end loop;
   end loop;
   commit;
end sp_inv_rr_with_borrowing;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_IS_VALID_CREW" (
   p_empl_id in varchar2,
   p_vessel  in varchar2,
   p_position in varchar2,
   p_basic_rate out number,
   p_embarked out date,
   p_retr out number) is
   vRankCode  Varchar2(20);
   vPosiCode  Varchar2(20);
   nBasicRate Number;
   dEmbarked  Date;
   nRetr      Number;
begin
   begin
      SELECT voyac.rank_code, voyac.basic_rate, voyac.dt_embarked
      INTO   vRankCode, nBasicRate, dEmbarked
          FROM   cms_voyage_crew voyac, cms_voyages voya, cms_vessels vess
          WHERE  voyac.voya_voyage_date = voya.voyage_date
          AND    voyac.voya_vess_code = voya.vess_code
          and    voya.vess_code = vess.code
          and    voya.vess_code = p_vessel
          AND    voyac.empl_empl_id = p_empl_id
          and    (voyac.dt_disembarked is null
          or     voyac.dt_disembarked > sysdate)
          AND    (voyage_end_date IS NULL
          or     voyage_end_date > sysdate);

      if vRankcode = p_position then
         nRetr := 1;
      else
         begin
            select 'Y' into vPosiCode
            from   pms_positions
            where  code = p_position
            and    rank_code = vRankCode;
            nRetr := 1;
         exception
            when no_data_found then nRetr := 0;
         end;
      end if;
   exception
      when no_data_found then nRetr := 0;
      when too_many_rows then nRetr := 2;
   end;
   p_basic_rate := nBasicRate;
   p_embarked   := dEmbarked;
   p_retr       := nRetr;
end sp_is_valid_crew;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_IS_VALID_PAX" (
   p_empl_id in varchar2,
   p_vessel  in varchar2,
   p_position in varchar2,
   p_basic_rate out number,
   p_embarked out date,
   p_retr out number) is
   vRankCode Varchar2(20);
   vPosiCode Varchar2(20);
   nBasicRate Number;
   dEmbarked  Date;
   nRetr      Number;
begin
   begin
      SELECT voyac.rank_code, voyac.basic_rate, voyac.dt_embarked
      INTO   vRankCode, nBasicRate, dEmbarked
      FROM   cms_voyage_pax voyac, cms_voyages voya, cms_vessels vess
      WHERE  voyac.voya_voyage_date = voya.voyage_date
      AND    voyac.voya_vess_code = voya.vess_code
      and    voya.vess_code = vess.code
      and    voya.vess_code = p_vessel
      AND    voyac.empl_empl_id = p_empl_id
      and    (voyac.dt_disembarked is null
      or     voyac.dt_disembarked > sysdate)
      AND    (voyage_end_date IS NULL
      or     voyage_end_date > sysdate);

      if vRankcode = p_position then
         nRetr := 1;
      else
         begin
            select 'Y'
            into   vPosiCode
            from   pms_positions
            where  code = p_position
            and    rank_code = vRankCode;
            nRetr := 1;
         exception
            when no_data_found then nRetr := 0;
         end;
      end if;
   exception
      when no_data_found then nRetr := 0;
      when too_many_rows then nRetr := 2;
   end;
   p_basic_rate := nBasicRate;
   p_embarked   := dEmbarked;
   p_retr       := nRetr;
end sp_is_valid_pax;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_LATEST_GET_BASIC_RATE" (
   p_empl_id in varchar2,
   p_date_fr in date,
   p_basic_r out number,
   p_basic_g out number,
   p_salfreq out varchar,
   p_ismanager out varchar
  )  is

   nBasicR    Number(8,2);
   nBasicG    Number(8,2);
   vSalFreq   Varchar2(16);
   vIsManager Varchar2(1);
begin

   for i in (select eff_st_date, basic_rate, basic_rate_g, sal_freq, is_manager
             from   pys_employee_salary
             where  empl_empl_id = p_empl_id
             and    eff_st_date <= p_date_fr
             order  by eff_st_date desc
             )
   loop
      nBasicR    := i.basic_rate;
      nBasicG    := i.basic_rate_g;
      vSalFreq   := i.sal_freq;
      vIsManager := i.is_manager;
      exit;
   end loop;

   p_basic_r   := nvl(nBasicR,0);
   p_basic_g   := nvl(nBasicG,0);
   p_salfreq   := nvl(vSalFreq,'SEMI-MO');
   p_ismanager := nvl(vIsManager,'N');
end sp_latest_get_basic_rate;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_LOG_TIME_IO" (p_line in varchar2, p_batch_no in number, p_retr out number) as
   nRetr number;
   vDate varchar2(10);
   vTime varchar2(10);
   vCard varchar2(8);
begin
   nRetr := 0;
   vCard := substr(p_line, 1, 5);
   vDate := substr(p_line, 19, 8);
   vTime := substr(p_line, 28, 5);
   insert into time_in_time_out_log (batch_no, tx_date, tx_time, card_no, time_log, dt_created, created_by)
   values (p_batch_no, to_date(vDate,'MMDDYYYY'), to_date(vDate || vTime,'MMDDYYYYHH24:MI'), vCard, p_line, sysdate, user);
   commit;
   nRetr := 1;
   p_retr := nRetr;
exception
   when others then
      --raise_application_error(-20001, vDate || ':' || vTime || ' ==== ' || SQLERRM);
      p_retr := -1;
end;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_LOG_TIME_IO_OLD" (p_line in varchar2, p_batch_no in number, p_retr out number) as
nRetr number;
    vDate varchar2(8);
    vTime varchar2(8);
    vCard varchar2(8);
begin
   nRetr := 0;
   vDate := substr(p_line, 1, 8);
   vTime := substr(p_line, 10, 6);
   vCard := substr(p_line, instr(p_line,'|', 1, 5)+1, 4);
   insert into time_in_time_out_log (batch_no, tx_date, tx_time, card_no, time_log, dt_created, created_by)
   values (p_batch_no, to_date(vDate,'YYYYMMDD'), to_date(vDate || vTime,'YYYYMMDDHH24MISS'), vCard, p_line, sysdate, user);
   commit;
   nRetr := 1;
   p_retr := nRetr;
exception
   when others then p_retr := -1;
end sp_log_time_io_old;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_OPEN_BEGBAL" as
   vNewTableName Varchar2(30);
   vOpMsg        Varchar2(4000);
   vStr          Varchar2(4000);
   nCnt          Number;
begin

   insert into inv_item_ware_begbal_log (username, dt_created, begbal_action)
   values (user, sysdate, 'OPEN');

   insert into inv_item_ware_begbal_history
   select * from inv_item_ware_begbal;

   delete inv_item_ware_begbal;

   commit;
end sp_open_begbal;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PAYROLL_COMPUTATION_A"
(
   p_payno   IN NUMBER,
   p_year    IN VARCHAR2,
   p_mon     IN VARCHAR2,
   p_date_fr IN DATE,
   p_date_to IN DATE
)
   AS
   --get attendance record
   CURSOR attr (p_period_fr IN DATE, p_period_to IN DATE ) IS
   SELECT b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          'OFC' empl_type,  b.dept_code dept_code, 'SEMI-MO' sal_freq
   FROM   PMS_EMPLOYEES b
   WHERE  EXISTS (SELECT 1
   FROM   PMS_ATTENDANCE_RECORDS a
   WHERE  a.empl_empl_id = b.empl_id
   AND    a.att_date BETWEEN p_period_fr AND p_period_to )
   AND    EXISTS (
      SELECT 1
      FROM   PYS_EMPLOYEE_SALARY c
      WHERE  eff_st_date  IN ( SELECT MAX(eff_st_date)
      FROM   PYS_EMPLOYEE_SALARY d
      WHERE  d.eff_st_date <= p_period_to
      AND    d.empl_empl_id = b.empl_id )
      AND    c.empl_empl_id = b.empl_id
      AND    c.sal_freq = 'SEMI-MO'
   )
   UNION
   SELECT vocr.empl_empl_id empl_empl_id, empl.taty_code, empl.posi_code posi_code,
          'FLT' empl_type, 'FL' dept_code, 'SEMI-MO' sal_freq
   FROM   CMS_VOYAGES voya, CMS_VOYAGE_CREW vocr, CMS_VESSELS vess, PMS_EMPLOYEES empl
   WHERE  voya.vess_code = vocr.voya_vess_code
   AND    voya.voyage_date = vocr.voya_voyage_date
   AND    voya.voyage_status <> 'CN'
   AND    vocr.voya_voyage_date <= p_period_to
   AND    vocr.dt_embarked <= p_period_to
   AND   (vocr.dt_disembarked IS NULL
   OR    (vocr.dt_disembarked IS NOT NULL AND vocr.dt_disembarked >= p_period_fr) )
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id = empl.empl_id
   AND    NOT EXISTS (
      SELECT 1
      FROM   PYS_EMPLOYEE_SALARY c
      WHERE  eff_st_date  IN ( SELECT MAX(eff_st_date)
      FROM   PYS_EMPLOYEE_SALARY d
      WHERE  d.eff_st_date <= p_period_to
      AND    d.empl_empl_id = vocr.empl_empl_id )
      AND    c.empl_empl_id = vocr.empl_empl_id
      AND    c.sal_freq = 'MONTHLY'
   )
   GROUP  BY vocr.empl_empl_id, empl.taty_code, empl.posi_code,
          'FLT', NULL
   UNION
   SELECT b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          DECODE(b.dept_code,'FL', 'FLT', 'OFC') empl_type, b.dept_code dept_code,  'MONTHLY' sal_freq
   FROM   PMS_EMPLOYEES b
   WHERE  EXISTS (
      SELECT 1
      FROM   PYS_EMPLOYEE_SALARY c
      WHERE  eff_st_date  IN ( SELECT MAX(eff_st_date)
      FROM   PYS_EMPLOYEE_SALARY d
      WHERE  d.eff_st_date <= p_period_to
      AND    d.empl_empl_id = b.empl_id )
      AND    c.empl_empl_id = b.empl_id
      AND    c.sal_freq = 'MONTHLY'
   );
   --get voyage crew
   CURSOR vocr IS
   SELECT vocr.empl_empl_id, vocr.dt_embarked, vocr.dt_disembarked
   FROM   CMS_VOYAGES voya, CMS_VOYAGE_CREW vocr
   WHERE  voya.vess_code = vocr.voya_vess_code
   AND    voya.voyage_date = vocr.voya_voyage_date
   AND    voya.voyage_status <> 'CN'
   AND    vocr.dt_embarked < p_date_fr
   AND    vocr.dt_disembarked <= p_date_to
   UNION
   SELECT vocr.empl_empl_id, vocr.dt_embarked, vocr.dt_disembarked
   FROM   CMS_VOYAGES voya, CMS_VOYAGE_CREW vocr
   WHERE  voya.vess_code = vocr.voya_vess_code
   AND    voya.voyage_date = vocr.voya_voyage_date
   AND    voya.voyage_status <> 'CN'
   AND    vocr.dt_embarked BETWEEN p_date_fr AND p_date_to;
   --get employee incentive
   CURSOR emin (p_empl_id IN VARCHAR2) IS
   SELECT empl_empl_id, inty_code, fiso_code, vess_code, basis, rate, YEAR, mo, amt
   FROM   PYS_EMPLOYEE_INCENTIVES
   WHERE  empl_empl_id = p_empl_id
   AND    YEAR = TO_CHAR(p_date_to, 'YYYY')
   AND    mo = TO_CHAR(p_date_to, 'MM');
   --get employee deductions
   CURSOR dedu (p_empl_id IN VARCHAR2) IS
   SELECT empl_empl_id, dety_code, seq_no, amt
   FROM   PYS_DEDUCTIONS
   WHERE  empl_empl_id = p_empl_id
   AND    end_date  >= p_date_to
   AND    start_date <= p_date_to
   --and    no_payday > 0
   AND    dety_code <> ('VALE'); -- not to include VALE in Payroll deductions for fleet; should be deducted from Incentives
   --get ofc employee deductions
   CURSOR ofc_dedu (p_empl_id IN VARCHAR2) IS
   SELECT empl_empl_id, dety_code, seq_no, amt
   FROM   PYS_DEDUCTIONS
   WHERE  empl_empl_id = p_empl_id
   AND    end_date  >= p_date_to
   AND    start_date <= p_date_to; -- include VALE in Payroll deductions for ofc;
   nSeqNo         NUMBER;
   bWithDeduction BOOLEAN;
   nPayNo         NUMBER(8);
   -- Overtime Rates for OFC and FLT
   nOvertm_RO   NUMBER(8,3);
   nSunday_RO   NUMBER(8,3);
   nHoliday_RO  NUMBER(8,3);
   nHolSun_RO   NUMBER(8,3);
   nOuter_RO    NUMBER(8,3);
   nOutAd_RO    NUMBER(8,3);
   nOvertm_RF   NUMBER(8,3);
   nSunday_RF   NUMBER(8,3);
   nHoliday_RF  NUMBER(8,3);
   nHolSun_RF   NUMBER(8,3);
   nCola        NUMBER(8,3);
   -- Actual OT pay
   nOtPay       NUMBER(8,2);
   nSuPay       NUMBER(8,2);
   nHoPay       NUMBER(8,2);
   nHSPay       NUMBER(8,2);
   nOPPay       NUMBER(8,2);
   nOPAdj       NUMBER(8,2);
   -- Employee Basic Rates and Computed Salary
   vIsManager   VARCHAR2(2);
   vSalFreq     VARCHAR2(16);
   nBasicR      NUMBER(8,2);
   nBasicG      NUMBER(8,2);
   nSalaryG     NUMBER(8,2);
   -- Deductions
   nSSS         NUMBER(8,2);
   nSSS_ER      NUMBER(8,2);
   nSSS_EC      NUMBER(8,2);
   nSSS_MO      NUMBER(8,2);
   nPagibig     NUMBER(8,2);
   nPagibig_ER  NUMBER(8,2);
   nPhHealth    NUMBER(8,2);
   nPhHealth_ER NUMBER(8,2);
   nTaxable     NUMBER(8,2);
   nWhTax       NUMBER(8,2);
   -- From Previous Pay Sched
   dPrevStart   DATE;
   nPrevSal     NUMBER(8,2);
   nPrevAllo    NUMBER(8,2);
   nPrevDays    NUMBER(8,2);
   nNumHrs      NUMBER(5,2);
   nAllowances  NUMBER(8,2);
   nDeduction   NUMBER(8,2) := 0;
   nVale        NUMBER(8,2) := 0;
   vLatestVess  VARCHAR2(32);
   vLatestTitle VARCHAR2(60);
   nSalaryG_D   NUMBER(8,2);
   nSalaryG_B   NUMBER(8,2);
   nSalaryG_R   NUMBER(8,2);
   dPeriodTOG   DATE;
   bFixMonthly  BOOLEAN;
   bDuplicate   BOOLEAN;
   nAdjCount    NUMBER;
   nMaxPayNo    NUMBER;
   dEmplID      VARCHAR2(16) := 'O00021';
BEGIN
   -- cleanup before recompute
   DELETE FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno AND adj_approval ='N';
   DELETE FROM PYS_PAYROLL_DTL_ADJ_LOG WHERE pahd_payroll_no = p_payno AND adj_approval ='N';
   DELETE FROM PYS_SSS_CONTRIBUTION WHERE period_to = p_date_to
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   DELETE FROM PYS_PAGIBIG_CONTRIBUTION WHERE period_to = p_date_to
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   DELETE FROM PYS_PHILHEALTH_CONTRIBUTION WHERE period_to = p_date_to
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   --DELETE FROM PYS_SSS_CONTRI_DTL WHERE psch_payroll_no = p_payno
   --   AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   --DELETE FROM PYS_PAGIBIG_CONTRI_DTL WHERE ppch_payroll_no = p_payno
   --   AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   --DELETE FROM PYS_HEALTH_CONTRI_DTL WHERE phch_payroll_no = p_payno
   --   AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   DELETE FROM PYS_PAYROLL_DTL_LOG WHERE payroll_no = p_payno
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   -- end of cleanup
   -- get Max SeqNo
   SELECT NVL(MAX(seq_no),0)
   INTO   nSeqNo
   FROM   PYS_PAYROLL_DTL
   WHERE  pahd_payroll_no = p_payno;
   -- get OFC and FLT Overtime Rate
   sp_get_ofc_ot_rates ( nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO);
   sp_get_flt_ot_rates ( nSunday_RF, nHoliday_RF, nHolSun_RF );
   -- check pay period
   IF p_date_to <= TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '15', 'YYYYMMDD') THEN
      bWithDeduction := FALSE;
      dPrevStart     := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      --dPrevStart     := p_date_fr;
   ELSE
      bWithDeduction := TRUE;
      -- get Max Previous Start
      SELECT payroll_no, period_fr
      INTO   nPayNo, dPrevStart
      FROM   PYS_PAYROLL_HDR
      WHERE  period_fr = TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '01', 'YYYYMMDD');
   END IF;
   DBMS_OUTPUT.PUT_LINE ('check M0: dPrevStart:' || TO_CHAR(dPrevStart)  || ',p_date_to:' || TO_CHAR(p_date_to) );
   FOR i IN attr ( dPrevStart, p_date_to ) LOOP
      nSalaryG   := 0;
      nOPPay     := 0;
      nOPAdj     := 0;
      nOtPay     := 0;
      nSuPay     := 0;
      nHoPay     := 0;
      nHsPay     := 0;
      nAllowances := 0;
      nPrevSal   := 0;
      nPrevAllo  := 0;
      vLatestVess := NULL;
      vLatestTitle := NULL;
      nSalaryG_D  := 0;
      nSalaryG_B  := 0;
      bFixMonthly := FALSE;
      bDuplicate  := FALSE;
      -- get basic rate and salary mode/frequency
      -- check attendance
      -- check if with approved adjustment
      nAdjCount := 0;
      SELECT COUNT(1)
      INTO   nAdjCount
      FROM   PYS_PAYROLL_DTL
      WHERE  empl_empl_id = i.empl_empl_id
      AND    pahd_payroll_no = p_payno
      AND    adj_approval = 'Y';
      vSalFreq := i.sal_freq;
      IF i.empl_type = 'OFC' THEN
         sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq, vIsManager );
      END IF;
      IF i.empl_empl_id = dEmplID THEN
         DBMS_OUTPUT.PUT_LINE ('check M00:' || i.empl_empl_id || ',nBasicG:' || TO_CHAR(nBasicG) ||
                                ',nBasicR:' || TO_CHAR(nBasicR) || ',i.empl_type:' || i.empl_type||
                                ',vSalFreq:' || vSalFreq || ',vIsManager:' || vIsManager || ',i.taty_code:' || i.taty_code);
      END IF;
       -- check if Employee has assigned Tax Type
      IF i.taty_code IS NOT NULL AND NVL(nAdjCount,0)=0 THEN         -- START: Tax Type checking (no Deduction loop)
         IF i.empl_type = 'OFC' THEN
            IF vSalFreq = 'MONTHLY' THEN
               IF vIsManager = 'Y' THEN
                  sp_count_mgr_attendance_new ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, nBasicR, nBasicG,
                                            nSunday_RO, nHoliday_RO, nHolSun_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nSuPay, nHoPay, nHSPay, nAllowances, nSeqNo);
               ELSE
                  sp_count_ofc_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                                i.dept_code, i.posi_code, 'Y', nBasicR, nBasicG,
                                                nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO, dEmplID );
                  sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, 'Y', nBasicR, nBasicG,
                                            nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
               END IF;
            ELSE
               sp_count_ofc_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                             i.dept_code, i.posi_code, 'N', nBasicR, nBasicG,
                                             nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO, dEmplID );
               sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                         i.dept_code, i.posi_code, 'N', nBasicR, nBasicG,
                                         nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                         nSeqNo, dEmplID, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
            END IF;
         ELSE
            sp_count_flt_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                          nSunday_RF, nHoliday_RF, nHolSun_RF, dEmplID, vSalFreq );
            sp_count_flt_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                      nSunday_RF, nHoliday_RF, nHolSun_RF,
                                      vSalFreq, nSeqNo, dEmplID, vLatestVess, vLatestTitle, nSeqNo);
         END IF;
         -- Start Compution for deductions
         -- No Deduction for Employees with no Government rate
         IF i.empl_empl_id = dEmplID THEN
            DBMS_OUTPUT.PUT_LINE ('check M1:' || i.empl_empl_id || ',nSalaryG:' || TO_CHAR(nSalaryG) ||
                                  ',vIsManager:' || vIsManager || ',nPayNo:' || TO_CHAR(nPayNo) || ',p_payno:' || TO_CHAR(p_payno));
         END IF;
         IF (bWithDeduction) THEN
            nCola := 0;
            FOR k IN (SELECT pahd_payroll_no, BASIC_RATE_G, basic_rate, dept_code, SAL_FREQ, no_days, period_to
                      FROM   PYS_PAYROLL_DTL
                      WHERE  empl_empl_id = i.empl_empl_id
                      AND    pahd_payroll_no = p_payno
                      AND    paty_code LIKE 'REG%'
                      UNION
                      SELECT pahd_payroll_no, BASIC_RATE_G, basic_rate, dept_code, SAL_FREQ, no_days, period_to
                      FROM   PYS_PAYROLL_DTL
                      WHERE  empl_empl_id = i.empl_empl_id
                      AND    pahd_payroll_no = nPayNo
                      AND    paty_code LIKE 'REG%'
                      ORDER  BY period_to DESC)
            LOOP
               IF i.empl_empl_id = dEmplID THEN
                  DBMS_OUTPUT.PUT_LINE ('check M2a: k.sal_freq:' || k.sal_freq || ',k.dept_code:' || k.dept_code ||
                                        ', k.BASIC_RATE_G:' || TO_CHAR(k.BASIC_RATE_G));
               END IF;
               IF k.sal_freq = 'MONTHLY' THEN
                  IF k.dept_code='FL' THEN
                     nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                     --nSalaryG_B := k.BASIC_RATE_G/30;  -- check crew
                     nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);  -- check crew
                  ELSE
                     IF k.dept_code='MA-CREW' THEN
                        nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                        nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);  -- check crew
                     ELSE
                        nSalaryG_B := k.BASIC_RATE_G;
                        bFixMonthly := TRUE;
                     END IF;
                  END IF;
               ELSE
                  IF k.dept_code='FL' THEN
                     nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                     nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);
                  ELSE
                     IF k.dept_code='MA-CREW' THEN
                        nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                        nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);  -- check crew
                     ELSE
                        nSalaryG_B := k.BASIC_RATE_G;
                        bFixMonthly := TRUE;
                     END IF;
                  END IF;
               END IF;
               dPeriodTOG := k.period_to;
               nMaxPayNo := k.pahd_payroll_no;
               EXIT;
            END LOOP;
            IF i.dept_code='MA-CREW' THEN
               FOR k IN (SELECT paty_code, nvl(SUM(no_days),0) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = p_payno
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code LIKE 'REG%'
                         GROUP  BY paty_code
                         UNION ALL
                         SELECT paty_code, nvl(SUM(no_days),0) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = nPayNo
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code LIKE 'REG%'
                         GROUP  BY paty_code
                         )
               LOOP
                  IF i.empl_empl_id = dEmplID THEN
                     DBMS_OUTPUT.PUT_LINE ('check M2b: k.paty_code:' || k.paty_code || ', k.no_days:' || TO_CHAR(k.no_days));
                  END IF;
                  nSalaryG_D := nSalaryG_D + k.no_days;
               END LOOP;
            ELSE
               FOR k IN (SELECT paty_code, nvl(SUM(no_days),0) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = p_payno
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code <> 'COLA'
                         GROUP  BY paty_code
                         UNION ALL
                         SELECT paty_code, nvl(SUM(no_days),0) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = nPayNo
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code <> 'COLA'
                         GROUP  BY paty_code
                         )
               LOOP
                  IF i.empl_empl_id = dEmplID THEN
                     DBMS_OUTPUT.PUT_LINE ('check M2b: k.paty_code:' || k.paty_code || ', k.no_days:' || TO_CHAR(k.no_days));
                  END IF;
                  nSalaryG_D := nSalaryG_D + k.no_days;
               END LOOP;
            END IF;
            IF i.empl_empl_id = dEmplID THEN
               DBMS_OUTPUT.PUT_LINE ('check M2: nSalaryG_D:' || TO_CHAR(nSalaryG_D) || ',' || 'nSalaryG_B:' || TO_CHAR(nSalaryG_B) ||
                                     ', dPrevStart:' || TO_CHAR( dPrevStart) || ', p_date_to:' || TO_CHAR( p_date_to));
            END IF;
            BEGIN
               IF dPeriodTOG IS NULL THEN
                  dPeriodTOG := p_date_to;
               END IF;
               IF bFixMonthly THEN
                  nSalaryG   := NVL(nSalaryG_B,0);
               ELSE
                  nSalaryG   := (NVL(nSalaryG_D,0)* NVL(nSalaryG_B,0));
               END IF;
            END;
            IF i.empl_empl_id = dEmplID THEN
               DBMS_OUTPUT.PUT_LINE ('check M3: nSalaryG:   ' || TO_CHAR(nSalaryG) ||  ', nMaxPayNo:' || TO_CHAR(NVL(nMaxPayNo,0)) || ', p_payno:' || TO_CHAR(NVL(p_payno,0)) || ', nOtPay:' || TO_CHAR(NVL(nOtPay,0)) || ', ' ||
                                     'nSuPay:' || TO_CHAR(NVL(nSuPay,0)) || ', nHoPay:' || TO_CHAR(NVL(nHoPay,0)) || ', nHsPay:' || TO_CHAR(NVL(nHsPay,0)) || ', nAllowances:' || TO_CHAR(NVL(nAllowances,0)) || ', ' ||
                                     'nPrevSal:' || TO_CHAR(NVL(nPrevSal,0)) || ', nPrevAllo:' || TO_CHAR(NVL(nPrevAllo,0)) );
            END IF;
            IF (NVL(nSalaryG,0) > 0) THEN
               -- check there are records
               IF nMaxPayNo < p_payno THEN
                  IF dPeriodTOG IS NULL OR dPeriodTOG < p_date_fr THEN
                     dPeriodTOG := p_date_to;
                  END IF;
                  -- check if there is header...
                  FOR k IN (SELECT pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, posi_code, title, basic_rate, vess_code, dept_code, sal_freq, latest_vess
                            FROM   PYS_PAYROLL_DTL
                            WHERE  empl_empl_id = i.empl_empl_id
                            AND    paty_code LIKE 'REG%'
                            AND    pahd_payroll_no <= p_payno
                            ORDER  BY period_to DESC)
                  LOOP
                     nSeqNo := nSeqNo + 1;
                     INSERT INTO PYS_PAYROLL_DTL
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                     VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, k.posi_code, k.title, 'REG-ADJ', 0, 0, k.basic_rate, 0, k.basic_rate, k.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', k.sal_freq, k.latest_vess );
                     EXIT;
                  END LOOP;
               END IF;
               -- compute SSS
               BEGIN
                  --if nSalaryG >= 1000 then   -- added by thess 04042008 to filter salaries less than 1000
                     nSeqNo := nSeqNo + 1;
                     sp_get_sss_contribution_er_ee (nSalaryG, p_date_to, nSSS, nSSS_ER, nSSS_EC, nSSS_MO);
                     -- populate sss ER and EE contribution
                     INSERT INTO PYS_SSS_CONTRIBUTION
                            ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, mo_sal_credit, created_by, dt_created )
                     VALUES ( dPrevStart, p_date_to, i.empl_empl_id, nSSS, nSSS_ER, NVL(nSSS_EC,0), nSSS_MO, USER, SYSDATE );

                     INSERT INTO PYS_PAYROLL_DTL
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'SSS', nSSS, nSalaryG, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                  --end if;
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN
                     nSSS := 0;
                     nSSS_ER := 0;
                     nSSS_EC := 0;
                     nSSS_MO := 0;
                     bDuplicate := TRUE;
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - sss contribution for ' || i.empl_empl_id || ' period: ' || TO_CHAR(dPrevStart) || '-' || TO_CHAR(p_date_to) || TO_CHAR(nSSS) || '/' || TO_CHAR(nSSS_ER) || '/' || TO_CHAR(nSSS_EC) || '/' || TO_CHAR(nSalaryG));
               END;
               -- compute Pag-ibig
               BEGIN
                  nSeqNo := nSeqNo + 1;
                  -- nPagibig := sf_get_pagibig_contribution(nBasic);
                  sp_get_pagibig_ee_er (nSalaryG, nPagibig, nPagibig_ER);
                  -- populate pag-ibig ER and EE contribution
                  INSERT INTO PYS_PAGIBIG_CONTRIBUTION
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
                  VALUES ( dPrevStart, p_date_to, i.empl_empl_id, nPagibig, nPagibig_ER, USER, SYSDATE );

                  INSERT INTO PYS_PAYROLL_DTL
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                  VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'PAGIBIG', nPagibig, nSalaryG, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN
                     nPagibig := 0;
                     nPagibig_ER := 0;
                     bDuplicate := TRUE;
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - pagibig contribution for ' || i.empl_empl_id || ' period: ' || TO_CHAR(dPrevStart) || '-' || TO_CHAR(p_date_to) || '/' || TO_CHAR(nPagibig) || '/' || TO_CHAR(nPagibig_ER) || '/' || TO_CHAR(nSalaryG));
               END;
               -- compute Philhealth
               BEGIN
                  nSeqNo := nSeqNo + 1;
                  --nPhHealth := sf_get_philhealth_contribution(nBasic);
                  sp_get_philhealth_ee_er (nSalaryG, p_date_to, nPhHealth, nPhHealth_ER);
                  -- populate pag-ibig ER and EE contribution
                  INSERT INTO PYS_PHILHEALTH_CONTRIBUTION
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
                  VALUES ( dPrevStart, p_date_to, i.empl_empl_id, nPhHealth, nPhHealth_ER, USER, SYSDATE );
                  INSERT INTO PYS_PAYROLL_DTL
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_Freq, latest_vess, title )
                  VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'PHILHEALTH', nPhHealth, nSalaryG, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN
                     nPhHealth    := 0;
                     nPhHealth_ER := 0;
                     bDuplicate := TRUE;
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - philhealth contribution for ' || i.empl_empl_id || ' period: ' || TO_CHAR(dPrevStart) || '-' || TO_CHAR(p_date_to) || '/' || TO_CHAR(nPhHealth) || '/' || TO_CHAR(nPhHealth_ER) || '/' || TO_CHAR(nSalaryG));
               END;

               IF not bDuplicate THEN
                  -- compute WH TAX
                  BEGIN
                     nTaxable := NVL(nSalaryG,0) - (nSSS + nPagibig + nPhHealth);
                     IF nTaxable >= 0 THEN  -- added by thess 04042008 to validate net taxable salary
                        nSeqNo   := nSeqNo + 1;
                        IF to_char(p_date_to, 'MMDD') = '1231' THEN
                           nWhTax   := 0;
                        ELSE
                           nWhTax   := sf_get_whtax(i.empl_empl_id, p_date_to, i.taty_code, nTaxable);
                        END IF;
                        INSERT INTO PYS_PAYROLL_DTL
                               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                        VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'WHTAX', nWhTax, nTaxable, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                     END IF;
                  END;
               END IF;
            END IF;                     -- END : No salary
            IF i.empl_empl_id = dEmplID THEN
               DBMS_OUTPUT.PUT_LINE ('check deduction: nSalaryG:   ' || TO_CHAR(nSalaryG) ||  ', i.empl_type :' || i.empl_type );
            END IF;

            -- Deductions
            IF not bDuplicate THEN
               IF i.empl_type = 'FLT' THEN
                  IF (NVL(nSalaryG,0) <> 0) THEN
                     FOR z IN dedu (i.empl_empl_id) LOOP
                        nSeqNo := nSeqNo + 1;
                        INSERT INTO PYS_PAYROLL_DTL
                               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                        VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                        nDeduction := NVL(nDeduction,0) + z.amt;
                     END LOOP;
                  END IF;
               ELSE
                  FOR z IN ofc_dedu (i.empl_empl_id) LOOP
                     BEGIN
                        nSeqNo := nSeqNo + 1;
                        INSERT INTO PYS_PAYROLL_DTL
                               ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                        VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                        nDeduction := NVL(nDeduction,0) + z.amt;
                     EXCEPTION
                        WHEN OTHERS THEN
                           RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - deductions ' || i.empl_empl_id || ' z.amt: ' || TO_CHAR(z.amt) || ',z.dety_code:' || TO_CHAR(z.dety_code) );
                     END;
                  END LOOP;
                  --nVale := nSalaryG-(nWhTax+nPhHealth+nPagibig+nSSS+nDeduction);
                  --if nVale < 0 then
                  --   nVale := nVale * -1;
                  --   begin
                  --      update pys_deductions
                  --      set    total_amt = total_amt + (nVale-amt)
                  --      where  empl_empl_id = i.empl_empl_id
                  --      and    dety_code = 'VALE'
                  --      and    amt <> nVale;
                  --      if sql%NOTFOUND then
                  --         insert into pys_deductions (seq_no, empl_empl_id, dety_code, start_date, end_date, no_payday, amt, frequency, total_amt, dt_created, created_by )
                  --         values (DEDU_SEQ.NEXTVAL, i.empl_empl_id, 'VALE', p_date_to, p_date_to+1, 1, 0, 'MO', nVale, sysdate, user);
                  --      end if;
                  --      insert into pys_deductions_log (empl_empl_id, pahd_payroll_no, amt, dt_created, created_by )
                  --      values (i.empl_empl_id, p_payno, nVale, sysdate, user);
                  --   end;
                  --end if;
               END IF; -- <if i.empl_type = 'FL' then>
            END IF;

         END IF;                        -- END : Deduction Computation -- No Deduction for Employees with no Government rate
      END IF;                           -- END: Tax Type checking  (no Deduction loop)
   END LOOP;
   -- summarizes computation
   SP_PAYROLL_SUMMARY(p_payno);
   -- compute annual tax
   IF to_char(p_date_to, 'MMDD') = '1231' THEN
      sp_annual_tax (p_payno, p_date_to);
   END IF;
END sp_payroll_computation_a;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PAYROLL_COMPUTATION_B"
(
   p_payno   in number,
   p_year    in varchar2,
   p_mon     in varchar2,
   p_date_fr in date,
   p_date_to in date
)
   as

   --get attendance record
   cursor attr (p_period_fr in date, p_period_to in date ) is
   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          'OFC' empl_type,  b.dept_code dept_code, 'SEMI-MO' sal_freq
   from   pms_employees b
   where  exists (select 1
   from   pms_attendance_records a
   where  a.empl_empl_id = b.empl_id
   and    a.att_date between p_period_fr and p_period_to )
   and    exists (
      select 1
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= p_period_to
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'SEMI-MO'
   )
   union
   select vocr.empl_empl_id empl_empl_id, empl.taty_code, empl.posi_code posi_code,
          'FLT' empl_type, 'FL' dept_code, 'SEMI-MO' sal_freq
   from   cms_voyage_crew vocr, cms_vessels vess, pms_employees empl
   where  vocr.voya_voyage_date <= p_period_to
   and    vocr.dt_embarked <= p_period_to
   and   (vocr.dt_disembarked is null
   or    (vocr.dt_disembarked is not null and vocr.dt_disembarked >= p_period_fr) )
   and    vocr.voya_vess_code = vess.code
   and    vocr.empl_empl_id = empl.empl_id
   and    not exists (
      select 1
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= p_period_to
      and    d.empl_empl_id = vocr.empl_empl_id )
      and    c.empl_empl_id = vocr.empl_empl_id
      and    c.sal_freq = 'MONTHLY'
   )
   group  by vocr.empl_empl_id, empl.taty_code, empl.posi_code,
          'FLT', NULL
   union
   select b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          decode(b.dept_code,'FL', 'FLT', 'OFC') empl_type, b.dept_code dept_code,  'MONTHLY' sal_freq
   from   pms_employees b
   where  exists (
      select 1
      from   pys_employee_salary c
      where  eff_st_date  in ( select max(eff_st_date)
      from   pys_employee_salary d
      where  d.eff_st_date <= p_period_to
      and    d.empl_empl_id = b.empl_id )
      and    c.empl_empl_id = b.empl_id
      and    c.sal_freq = 'MONTHLY'
   );

   --get voyage crew
   cursor vocr is
   select empl_empl_id, dt_embarked, dt_disembarked
   from   cms_voyage_crew
   where  dt_embarked < p_date_fr
   and    dt_disembarked <= p_date_to
   union
   select empl_empl_id, dt_embarked, dt_disembarked
   from   cms_voyage_crew
   where  dt_embarked between p_date_fr and p_date_to;

   --get employee incentive
   cursor emin (p_empl_id in varchar2) is
   select empl_empl_id, inty_code, fiso_code, vess_code, basis, rate, year, mo, amt
   from   pys_employee_incentives
   where  empl_empl_id = p_empl_id
   and    year = to_char(p_date_to, 'YYYY')
   and    mo = to_char(p_date_to, 'MM');

   --get employee deductions
   cursor dedu (p_empl_id in varchar2) is
   select empl_empl_id, dety_code, seq_no, amt
   from   pys_deductions
   where  empl_empl_id = p_empl_id
   and    end_date  >= p_date_to
   and    start_date <= p_date_to
   --and    no_payday > 0
   and    dety_code <> ('VALE'); -- not to include VALE in Payroll deductions for fleet; should be deducted from Incentives

   --get ofc employee deductions
   cursor ofc_dedu (p_empl_id in varchar2) is
   select empl_empl_id, dety_code, seq_no, amt
   from   pys_deductions
   where  empl_empl_id = p_empl_id
   and    end_date  >= p_date_to
   and    start_date <= p_date_to; -- include VALE in Payroll deductions for ofc;

   nSeqNo         Number;
   bWithDeduction Boolean;
   nPayNo         Number(8);

   -- Overtime Rates for OFC and FLT
   nOvertm_RO   Number(8,3);
   nSunday_RO   Number(8,3);
   nHoliday_RO  Number(8,3);
   nHolSun_RO   Number(8,3);
   nOuter_RO    Number(8,3);
   nOutAd_RO    Number(8,3);
   nOvertm_RF   Number(8,3);
   nSunday_RF   Number(8,3);
   nHoliday_RF  Number(8,3);
   nHolSun_RF   Number(8,3);
   nCola        Number(8,3);

   -- Actual OT pay
   nOtPay       Number(8,2);
   nSuPay       Number(8,2);
   nHoPay       Number(8,2);
   nHSPay       Number(8,2);
   nOPPay       Number(8,2);
   nOPAdj       Number(8,2);

   -- Employee Basic Rates and Computed Salary
   vIsManager   varchar2(2);
   vSalFreq     varchar2(16);
   nBasicR      Number(8,2);
   nBasicG      Number(8,2);
   nSalaryG     Number(8,2);

   -- Deductions
   nSSS         Number(8,2);
   nSSS_ER      Number(8,2);
   nSSS_EC      Number(8,2);
   nPagibig     Number(8,2);
   nPagibig_ER  Number(8,2);
   nPhHealth    Number(8,2);
   nPhHealth_ER Number(8,2);
   nTaxable     Number(8,2);
   nWhTax       Number(8,2);

   -- From Previous Pay Sched
   dPrevStart   Date;
   nPrevSal     Number(8,2);
   nPrevAllo    Number(8,2);
   nPrevDays    Number(8,2);

   nNumHrs      Number(5,2);
   nAllowances  Number(8,2);
   nDeduction   Number(8,2) := 0;
   nVale        Number(8,2) := 0;
   vLatestVess  Varchar2(32);
   vLatestTitle Varchar2(60);
   nSalaryG_D   Number(8,2);
   nSalaryG_B   Number(8,2);
   nSalaryG_R   Number(8,2);
   dPeriodTOG   Date;
   bFixMonthly  Boolean;
   nAdjCount    Number;

   dEmplID      varchar2(16) := 'A00001';

begin

   -- get Max SeqNo
   select nvl(max(seq_no),0)
   into   nSeqNo
   from   pys_payroll_dtl
   where  pahd_payroll_no = p_payno;

   -- get OFC and FLT Overtime Rate
   sp_get_ofc_ot_rates ( nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO);
   sp_get_flt_ot_rates ( nSunday_RF, nHoliday_RF, nHolSun_RF );

   -- check pay period
   if p_date_to <= to_date(to_char(p_date_to, 'YYYYMM') || '15', 'YYYYMMDD') then

      bWithDeduction := FALSE;
      dPrevStart     := to_date(to_char(add_months(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      --dPrevStart     := p_date_fr;

   else

      bWithDeduction := TRUE;

      -- get Max Previous Start
      select payroll_no, period_fr
      into   nPayNo, dPrevStart
      from   pys_payroll_hdr
      where  period_fr = to_date(to_char(p_date_to, 'YYYYMM') || '01', 'YYYYMMDD');

   end if;

   dbms_output.put_line ('check M0: dPrevStart:' || to_char(dPrevStart)  || ',p_date_to:' || to_char(p_date_to) );
   for i in attr ( dPrevStart, p_date_to ) loop

      nSalaryG   := 0;
      nOPPay     := 0;
      nOPAdj     := 0;
      nOtPay     := 0;
      nSuPay     := 0;
      nHoPay     := 0;
      nHsPay     := 0;
      nAllowances := 0;
      nPrevSal   := 0;
      nPrevAllo  := 0;
      vLatestVess := null;
      vLatestTitle := null;
      nSalaryG_D  := 0;
      nSalaryG_B  := 0;
      bFixMonthly := FALSE;

      -- get basic rate and salary mode/frequency
      -- check attendance

      -- check if with approved adjustment
      nAdjCount := 0;
      select count(1)
      into   nAdjCount
      from   pys_payroll_dtl
      where  empl_empl_id = i.empl_empl_id
      and    pahd_payroll_no = p_payno
      and    adj_approval = 'Y';

      vSalFreq := i.sal_freq;
      if i.empl_type = 'OFC' then
         sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq, vIsManager );
      end if;


      if i.empl_empl_id = dEmplID then
         dbms_output.put_line ('check M00:' || i.empl_empl_id || ',nBasicG:' || to_char(nBasicG) ||
                                ',nBasicR:' || to_char(nBasicR) || ',i.empl_type:' || i.empl_type||
                                ',vSalFreq:' || vSalFreq || ',vIsManager:' || vIsManager);
      end if;

       -- check if Employee has assigned Tax Type
      if i.taty_code is not null and nvl(nAdjCount,0)=0 then         -- START: Tax Type checking (no Deduction loop)

         if i.empl_type = 'OFC' then
            if vSalFreq = 'MONTHLY' then
               if vIsManager = 'Y' then
                  sp_count_mgr_attendance_new ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, nBasicR, nBasicG,
                                            nSunday_RO, nHoliday_RO, nHolSun_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nSuPay, nHoPay, nHSPay, nAllowances, nSeqNo);
               end if;
            end if;
         end if;
      end if;                           -- END: Tax Type checking  (no Deduction loop)

   end loop;

end sp_payroll_computation_b;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PAYROLL_SUMMARY" (
   p_payroll_no IN NUMBER
   ) AS
   nRegDay      pys_payroll_dtl.no_days%type := 0;
   nSalary      pys_payroll_dtl.amt%type := 0;
   nOtAmt       pys_payroll_dtl.amt%type := 0;
   nOtDay       pys_payroll_dtl.no_days%type := 0;
   nColaAmt     pys_payroll_dtl.amt%type := 0;
   nColaDay     pys_payroll_dtl.no_days%type := 0;
   nNetAmt      pys_payroll_dtl.amt%type := 0;
   nPAGIBIG     pys_payroll_dtl.amt%type := 0;
   nPHILHEALTH  pys_payroll_dtl.amt%type := 0;
   nSSS         pys_payroll_dtl.amt%type := 0;
   nWHTAX       pys_payroll_dtl.amt%type := 0;
   nPAGIBIGLOAN pys_payroll_dtl.amt%type := 0;
   nSSSLOAN     pys_payroll_dtl.amt%type := 0;
   nVALE        pys_payroll_dtl.amt%type := 0;
   nBasic       pys_payroll_dtl.basic_rate%type := 0;
   nLBasic      pys_payroll_dtl.basic_rate%type := 0;
   vLVess       VARCHAR2(16);
   vDept        VARCHAR2(16);
   vLTitle      VARCHAR2(60);
   bFirst       BOOLEAN;
   nRecAmt      NUMBER(10,2);
   vPrevEmplID  VARCHAR2(16) := 'x x x';
   dStart       DATE;
   dStart2      DATE;
   dEnd         DATE;
   nPrevPayrollNo NUMBER;
   nColaRate    pys_payroll_dtl.basic_rate%type;
   nAmt_a       pys_payroll_dtl.amt%type;
   n13th_n_mon  NUMBER(9,2);
   n13th_n_mon_b NUMBER(9,2);
   n13th_a      NUMBER(9,2);
   n13th_b      NUMBER(9,2);
   nSILP_a      NUMBER(9,2);
   nSILP_b      NUMBER(9,2);
   n13th_amt_a  NUMBER(12,2);
   n13th_amt_b  NUMBER(12,2);
   dPeriodFr    DATE;
   dPeriodTo    DATE;
   vOPort       VARCHAR2(1);
   vLOPort      VARCHAR2(1);
   nOuterR      NUMBER(8,4);
   bIsFinal     BOOLEAN;
BEGIN
   -- clear summary
   DELETE FROM pys_payroll_summary
   WHERE  payroll_no = p_payroll_no;
   COMMIT;
   -- clear summary
   DELETE FROM pys_13th_month
   WHERE  payroll_no = p_payroll_no;
   COMMIT;

   -- get Outer Port Rate
   BEGIN
      SELECT rate
      INTO   nOuterR
      FROM   pys_payroll_types
      WHERE  code = 'REG-OP';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN nOuterR := 1;
      WHEN OTHERS THEN nOuterR := 1;
   END;

   FOR i IN (SELECT empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq,
                    MIN(period_fr) period_fr, SUM(no_days) no_days, SUM(amt) amt,
                    MAX(basic_rate_g) basic_rate_g, MAX(amt_g) amt_g, MAX(paty_code) paty_code
             FROM   pys_payroll_dtl
             WHERE  pahd_payroll_no = p_payroll_no
             AND    paty_code LIKE 'REG%'
             GROUP  BY empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq
             ORDER  BY empl_empl_id, period_to DESC
            )
   LOOP
       -- get OT total
       IF i.dept_code = 'FL' THEN
          SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
          INTO   nOtDay, nOtAmt
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    title = i.title
          AND    paty_code LIKE 'OT%'
          AND    period_to BETWEEN i.period_fr AND i.period_to
          AND    NOT EXISTS (SELECT 1 FROM pys_payroll_summary
                             WHERE pys_payroll_dtl.empl_empl_id = pys_payroll_summary.empl_id
                             AND   title = i.title
                             AND   pys_payroll_dtl.pahd_payroll_no = pys_payroll_summary.payroll_no
                             AND   pys_payroll_dtl.period_fr = pys_payroll_summary.period_fr
                             AND   pys_payroll_dtl.period_to = pys_payroll_summary.period_to
                            );

       ELSE
          if vPrevEmplID <> i.empl_empl_id then
             SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
             INTO   nOtDay, nOtAmt
             FROM   pys_payroll_dtl
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = i.empl_empl_id
             AND    paty_code LIKE 'OT%';
             --AND    period_to BETWEEN i.period_fr AND i.period_to;
          end if;
       END IF;

       IF vPrevEmplID <> i.empl_empl_id THEN
          -- get COLA total
          SELECT NVL(SUM(no_days),0) cola_days, NVL(SUM(amt),0) cola_amt
          INTO   nColaDay, nColaAmt
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'COLA';
          --and    period_to between i.period_fr and i.period_to;
          nColaRate := 0;
          IF i.dept_code = 'FL' THEN
             nColaRate := sf_get_payroll_cola(i.empl_empl_id, p_payroll_no, p_payroll_no);
          ELSE
             IF (nColaAmt > 0) and (nColaDay > 0) THEN
                nColaRate := (nColaAmt/nColaDay);
             END IF;
          END IF;
       END IF;

       -- get PAGIBIG total
       BEGIN
          SELECT amt
          INTO   nPAGIBIG
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'PAGIBIG'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPAGIBIG := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PAGIBIG amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get PHILHEALTH total
       BEGIN
          SELECT amt
          INTO   nPHILHEALTH
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'PHILHEALTH'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPHILHEALTH := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PHILHEALTH amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get SSS total
       BEGIN
          SELECT amt
          INTO   nSSS
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'SSS'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nSSS := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for SSS amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get WHTAX total
       BEGIN
          SELECT amt
          INTO   nWHTAX
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'WHTAX'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nWHTAX := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for WHTAX amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get HDMF LOAN/PAGIBIGLOAN total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nPAGIBIGLOAN
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'HDMF LOAN'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPAGIBIGLOAN := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PAGIBIGLOAN amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get SSSLOAN total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nSSSLOAN
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'SSSLOAN'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nSSSLOAN := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for SSSLOAN amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get VALE total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nVALE
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'VALE'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nVALE := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for VALE amt of ' || TO_CHAR(i.empl_empl_id));
       END;

       IF i.dept_code IS NULL THEN
          SELECT dept_code INTO vDept
          FROM   pms_employees
          WHERE  empl_id = i.empl_empl_id;
       ELSE
          vDept := i.dept_code;
       END IF;

       nBasic  := i.basic_rate;
       vLOPort := 'N';
       FOR k IN (SELECT basic_rate, title, vess_code, paty_code
                 FROM   pys_payroll_dtl
                 WHERE  empl_empl_id = i.empl_empl_id
                 AND    pahd_payroll_no = p_payroll_no
                 AND    paty_code LIKE 'REG%'
                 ORDER  BY period_to DESC)
       LOOP
          nLBasic := k.basic_rate;
          vLVess  := k.vess_code;
          vLTitle := k.title;
          IF i.paty_code LIKE 'REG-OP%' THEN
             vLOPort := 'Y';
          END IF;
          EXIT;
       END LOOP;
       vOPort := 'N';
       IF vDept = 'FL' THEN
          nSalary := i.amt + nOtAmt;
          nOtAmt  := 0;
          nRegDay := i.no_days + nOtDay;
          nOtDay  := 0;
       ELSIF vDept = 'MA-CREW' THEN
          nRegDay  := i.no_days;
          nSalary  := i.amt;
       ELSE
          nSalary := i.amt;
          nRegDay := i.no_days;
          IF nBasic > 10000 THEN
             nBasic := nBasic/30;
          END IF;
          IF i.paty_code LIKE 'REG-OP%' THEN
             vOPort := 'Y';
          END IF;
       END IF;

       nNetAmt := (nSalary + nOtAmt + nColaAmt) -
                  (nPAGIBIG + nPAGIBIGLOAN + nSSS + nSSSLOAN + nPHILHEALTH + nWHTAX + nVALE);

       BEGIN
          INSERT INTO pys_payroll_summary
                 ( payroll_no, period_fr, period_to, empl_id, dept_code, vess_code,
                  title, sal_freq, basic_rate, no_days, amount, cola_amt, cola_day, cola_rate,
                  ot_amt, ot_day, pag_ibig_amt, pag_ibig_loan, sss_amt, sss_loan,
                  medicare, whtax, vale, net_amount, l_basic_rate, l_vess_code, l_title,
                  basic_rate_g, amount_g, oport, l_oport
                 )
          VALUES ( p_payroll_no, i.period_fr, i.period_to, i.empl_empl_id, vDept, i.vess_code,
                  i.title, i.sal_freq, nBasic, nRegDay, nSalary, nColaAmt, nColaDay, nColaRate,
                  nOtAmt, nOtDay, nPAGIBIG, nPAGIBIGLOAN, nSSS, nSSSLOAN,
                  nPHILHEALTH, nWHTAX, nVALE, nNetAmt, nLBasic, vLVess, vLTitle,
                  i.basic_rate_g, i.amt_g, vOPort, vLOPort
                 );
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN --NULL;
            DBMS_OUTPUT.PUT_LINE ('DUP VAL on Employee: ' || i.empl_empl_id || ', vess_code :' || i.vess_code || ', nSalary:' || to_char(nSalary)
                                       || ', nNetAmt:' || to_char(nNetAmt) || ', nBasic:' || to_char(nBasic) || ', nRegDay:' || to_char(nRegDay));
      END;
      nOtAmt       := 0;
      nRegDay      := 0;
      nSalary      := 0;
      nOtDay       := 0;
      nColaAmt     := 0;
      nColaDay     := 0;
      nNetAmt      := 0;
      nPAGIBIG     := 0;
      nPHILHEALTH  := 0;
      nSSS         := 0;
      nWHTAX       := 0;
      nPAGIBIGLOAN := 0;
      nSSSLOAN     := 0;
      nVALE        := 0;
      nLBasic      := 0;
      vLVess       := NULL;
      vLTitle      := NULL;
      vPrevEmplID  := i.empl_empl_id;
   END LOOP;

   -- check employees with negative net amount
   FOR i IN (SELECT empl_id empl_empl_id, SUM(net_amount) net_amt, SUM(no_days) no_days, COUNT(1) nRec
             FROM   pys_payroll_summary
             WHERE  payroll_no = p_payroll_no
             GROUP  BY empl_id
             HAVING SUM(net_amount) < 0 )
   LOOP
      bFirst := TRUE;
      nRecAmt := 0;
      FOR j IN (SELECT ROWID, vale, net_amount
                FROM   pys_payroll_summary
                WHERE  empl_id = i.empl_empl_id
                AND    payroll_no = p_payroll_no
                FOR    UPDATE
                ORDER  BY net_amount DESC)
      LOOP
         IF i.nRec = 1 THEN
            UPDATE pys_payroll_summary
            SET    vale = (vale + net_amount),
                   net_amount = 0
            WHERE  ROWID = j.ROWID;
         ELSE
            IF bFirst THEN
               UPDATE pys_payroll_summary
               SET    net_amount =0
               WHERE  ROWID = j.ROWID;
               nRecAmt := j.net_amount;
            ELSE
               UPDATE pys_payroll_summary
               SET    net_amount =0,
                      vale = net_amount + nRecAmt
               WHERE  ROWID = j.ROWID;
            END IF;
         END IF;
         bFirst := FALSE;
      END LOOP;
   END LOOP;
   COMMIT;

   -- if end of month generate Payroll A Summary
   SELECT period_fr, period_to
   INTO   dStart, dEnd
   FROM   pys_payroll_hdr
   WHERE  payroll_no = p_payroll_no;

   -- check if 13thmonth is computed
   bIsFinal := TRUE;
   --IF TO_CHAR(dStart, 'MON') = 'NOV' THEN
   --   IF trunc(sysdate) > to_date(TO_CHAR(dStart, 'YYYYMM') || '21', 'YYYYMMDD') then
   --      bIsFinal := FALSE;
   --   END IF;
   --END IF;

   IF TO_CHAR(dStart, 'DD') = '16' THEN

      SELECT MAX(payroll_no)
      INTO   nPrevPayrollNo
      FROM   pys_payroll_hdr
      WHERE  period_fr = (SELECT MAX(period_fr)
                          FROM   pys_payroll_hdr
                          WHERE  period_fr < dStart);

      SELECT period_fr
      INTO   dStart2
      FROM   pys_payroll_hdr
      WHERE  payroll_no = nPrevPayrollNo;

      FOR i IN (SELECT empl_id, MAX(period_to) period_to, MAX(sal_freq) sal_freq, MAX(dept_code) dept_code,
                       SUM(cola_amt) cola_amt, SUM(cola_day) cola_day, MAX(cola_rate) cola_rate
                FROM   pys_payroll_summary
                WHERE  payroll_no IN (nPrevPayrollNo, p_payroll_no)
                GROUP  BY empl_id
                HAVING MAX(period_to) > dStart2)
      LOOP
         FOR k IN (SELECT empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g, oport
                   FROM   pys_payroll_summary
                   WHERE  empl_id = i.empl_id
                   AND    payroll_no IN (nPrevPayrollNo, p_payroll_no)
                   ORDER  BY payroll_no DESC, period_to DESC)
         LOOP
            IF i.sal_freq = 'MONTHLY' THEN
               nColaRate := 0;
               IF i.dept_code = 'FL' THEN
                  IF i.cola_amt > 0 THEN
                     nColaRate := i.cola_rate;
                  END IF;
               END IF;
               UPDATE pys_payroll_summary
               SET    l_vess_code_a  = k.l_vess_code,
                      l_title_a      = NVL(k.l_title, k.title),
                      l_basic_rate_a = k.basic_rate_g+nColaRate
               WHERE  empl_id = i.empl_id
               AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
            ELSE
               IF i.dept_code = 'FL' THEN
                  nColaRate := 0;
                  IF i.cola_amt > 0 THEN
                     nColaRate := i.cola_rate;
                  END IF;
                  UPDATE pys_payroll_summary
                  SET    l_vess_code_a  = k.l_vess_code,
                         l_title_a      = NVL(k.l_title, k.title),
                         l_basic_rate_a = NVL(k.l_basic_rate, k.basic_rate) +  nColaRate
                  WHERE  empl_id = i.empl_id
                  AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
               ELSE
                  nColaRate := 0;
                  IF i.dept_code = 'MA-CREW' THEN
                     IF i.cola_amt > 0 THEN
                        nColaRate := i.cola_rate;
                     END IF;
                     UPDATE pys_payroll_summary
                     SET    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = NVL(k.l_title, k.title),
                            l_basic_rate_a = k.basic_rate_g+nColaRate
                     WHERE  empl_id = i.empl_id
                     AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
                  ELSE
                     UPDATE pys_payroll_summary
                     SET    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = NVL(k.l_title, k.title),
                            l_basic_rate   = k.basic_rate,
                            l_basic_rate_a = k.basic_rate_g,
                            l_oport        = k.oport
                     WHERE  empl_id = i.empl_id
                     AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
                  END IF;
               END IF;
            END IF;

            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            IF bIsFinal THEN
               nSILP_a := 0;    n13th_amt_a := 0;   n13th_n_mon   := 0;
               nSILP_b := 0;    n13th_amt_b := 0;   n13th_n_mon_b := 0;
               IF TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY') > dEnd THEN
                  dPeriodFr := ADD_MONTHS(TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY'),-12);
                  dPeriodTo := TO_DATE('3011' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY');
               ELSE
                  dPeriodFr := TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY');
                  dPeriodTo := ADD_MONTHS(TO_DATE('3011' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY'),12);
               END IF;
               FOR n IN (SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                SUM(pay.amount) amount,
                                SUM(pay.no_days) no_days,
                                SUM(pay.cola_amt) cola_amt,
                                NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)) basic_rate_a,
                                MAX(pay.dept_code) dept_code,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon,
                                (DECODE(MAX(pay.dept_code),'FL', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)),'MA-CREW', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)), NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))) )  amount_g

                                --+
                                -- decode(max(pay.dept_code),'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         AND    pay.payroll_no = pahd.payroll_no
                         AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM')
                         having (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) ) > 0)

               LOOP
                  n13th_n_mon := n13th_n_mon + n.nMon;
                  n13th_amt_a := n13th_amt_a + NVL(n.amount_g,0);
               END LOOP;

               if n13th_n_mon > 0 then
                  n13th_a := (n13th_amt_a/n13th_n_mon) * (n13th_n_mon/12);
               end if;

               FOR n IN (SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                SUM(pay.amount) amount,
                                SUM(pay.no_days) no_days,
                                SUM(pay.cola_amt) cola_amt,
                                NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)) basic_rate_a,
                                MAX(pay.dept_code) dept_code,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon,
                                (DECODE(MAX(pay.dept_code),'FL', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)),'MA-CREW', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)), NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))) )  amount_g
                                --+
                                -- decode(max(pay.dept_code),'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         --AND    pay.payroll_no = pahd.payroll_no
                         --AND    not (oport = 'Y' and pay.no_days < 0)
                         --AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         --GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM'))
                   and    pay.payroll_no = pahd.payroll_no
                   --and    pay.period_fr >= pahd.period_fr
                   and    pahd.period_to between dPeriodFr and dPeriodTo
                   group  by to_char(pahd.period_to,'YYYYMM'))

               LOOP
                  n13th_n_mon_b := n13th_n_mon_b + n.nMon;
                  n13th_amt_b := n13th_amt_b + NVL(n.amount,0);
               END LOOP;

               if n13th_n_mon_b > 0 then
                  n13th_b := (n13th_amt_b/n13th_n_mon_b) * (n13th_n_mon_b/12);
               end if;

               for n in (select basic_rate, sum(nMon) nMon from (
                         select to_char(pahd.period_to,'YYYYMM') cur_mon,
                                 decode(oport,'Y',round(pay.basic_rate/1.3,2),pay.basic_rate)  basic_rate,
                                decode(greatest(sum(least(pay.no_days,15)),15),15,.5,1) nMon
                         from   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         where  pay.empl_id = i.empl_id
                         and    pay.payroll_no = pahd.payroll_no
                         and    pahd.period_to between dPeriodFr and dPeriodTo
                         and    pay.period_fr >= pahd.period_fr
                         group  by to_char(pahd.period_to,'YYYYMM'),  decode(oport,'Y',round(pay.basic_rate/1.3,2),pay.basic_rate)   )
                         group  by basic_rate
                        )
               loop
                  nSILP_b := nSILP_b + (n.basic_rate * 5 * (n.nMon/12));
               end loop;

               --FOR n IN (SELECT basic_rate, SUM(nMon) nMon FROM (
               --          SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
               --                 DECODE(pay.oport,'Y',round(pay.basic_rate/nOuterR,2),pay.basic_rate)  basic_rate,
               --                 DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon
               --          FROM   pys_payroll_summary pay,
               --                 pys_payroll_hdr pahd
               --          WHERE  pay.empl_id = i.empl_id
               --          AND    pay.payroll_no = pahd.payroll_no
               --          and    not (oport = 'Y' and pay.no_days < 0)
               --          AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
               --          GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM'), DECODE(pay.oport,'Y',round(pay.basic_rate/nOuterR,2),pay.basic_rate) )
               --          GROUP  BY basic_rate
               --         )
               --LOOP
               --   nSILP_b := nSILP_b + (n.basic_rate * 5 * (n.nMon/12));
               --END LOOP;

               FOR n IN (SELECT basic_rate, SUM(nMon) nMon FROM (
                         SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                DECODE(MAX(pay.dept_code), 'FL', NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)),
                                                           'MA-CREW', NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)),
                                                            NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))/30)  basic_rate,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         AND    pay.payroll_no = pahd.payroll_no
                         AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM')
                         having (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) ) > 0 )

                         GROUP  BY basic_rate
                        )
               LOOP
                  nSILP_a := nSILP_a + (n.basic_rate * 5 * (n.nMon/12));
               END LOOP;

               BEGIN
                  INSERT INTO pys_13th_month_summary
                         (empl_id, dept_code, vess_code, title, period_fr, period_to, m_13_amt, m_13_amt_a, silp_amt, silp_amt_a )
                  VALUES (i.empl_id, i.dept_code, k.l_vess_code, NVL(k.l_title, k.title), dPeriodFr, dPeriodTo, n13th_b, n13th_a, nSILP_b, nSILP_a );
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN
                     UPDATE pys_13th_month_summary
                     SET    m_13_amt   = n13th_b,
                            m_13_amt_a = n13th_a,
                            silp_amt   = nSILP_b,
                            silp_amt_a = nSILP_a
                     WHERE  empl_id = i.empl_id
                     AND    period_fr = dPeriodFr
                     AND    period_to = dPeriodTo;
               END;
            END IF;
            EXIT;
         END LOOP;
      END LOOP;
   END IF;

   COMMIT;
END sp_payroll_summary;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PAYROLL_SUMMARY_EMPL" (
   p_payroll_no IN NUMBER,
   p_empl_id IN VARCHAR2
   ) AS
   nRegDay      pys_payroll_dtl.no_days%type := 0;
   nSalary      pys_payroll_dtl.amt%type := 0;
   nOtAmt       pys_payroll_dtl.amt%type := 0;
   nOtDay       pys_payroll_dtl.no_days%type := 0;
   nColaAmt     pys_payroll_dtl.amt%type := 0;
   nColaDay     pys_payroll_dtl.no_days%type := 0;
   nNetAmt      pys_payroll_dtl.amt%type := 0;
   nPAGIBIG     pys_payroll_dtl.amt%type := 0;
   nPHILHEALTH  pys_payroll_dtl.amt%type := 0;
   nSSS         pys_payroll_dtl.amt%type := 0;
   nWHTAX       pys_payroll_dtl.amt%type := 0;
   nPAGIBIGLOAN pys_payroll_dtl.amt%type := 0;
   nSSSLOAN     pys_payroll_dtl.amt%type := 0;
   nVALE        pys_payroll_dtl.amt%type := 0;
   nBasic       pys_payroll_dtl.basic_rate%type := 0;
   nLBasic      pys_payroll_dtl.basic_rate%type := 0;
   vLVess       VARCHAR2(16);
   vDept        VARCHAR2(16);
   vLTitle      VARCHAR2(60);
   bFirst       BOOLEAN;
   nRecAmt      NUMBER(10,2);
   vPrevEmplID  VARCHAR2(16) := 'x x x';
   dStart       DATE;
   dStart2      DATE;
   dEnd         DATE;
   nPrevPayrollNo NUMBER;
   nColaRate    pys_payroll_dtl.basic_rate%type;
   nAmt_a       pys_payroll_dtl.amt%type;
   n13th_n_mon  NUMBER(9,2);
   n13th_n_mon_b NUMBER(9,2);
   n13th_a      NUMBER(9,2);
   n13th_b      NUMBER(9,2);
   nSILP_a      NUMBER(9,2);
   nSILP_b      NUMBER(9,2);
   n13th_amt_a  NUMBER(12,2);
   n13th_amt_b  NUMBER(12,2);
   dPeriodFr    DATE;
   dPeriodTo    DATE;
   vOPort       VARCHAR2(1);
   vLOPort      VARCHAR2(1);
   nOuterR      NUMBER(8,4);
   nCheck       NUMBER;
   nSeqNo       NUMBER;
   bIsFinal     BOOLEAN;
BEGIN
   -- clear summary
   DELETE FROM pys_payroll_summary
   WHERE  payroll_no = p_payroll_no
   AND    empl_id = p_empl_id;
   COMMIT;
   -- clear summary
   DELETE FROM pys_13th_month
   WHERE  payroll_no = p_payroll_no
   AND    empl_id = p_empl_id;
   COMMIT;

   -- get Outer Port Rate
   BEGIN
      SELECT rate
      INTO   nOuterR
      FROM   pys_payroll_types
      WHERE  code = 'REG-OP';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN nOuterR := 1;
      WHEN OTHERS THEN nOuterR := 1;
   END;

   FOR i IN (SELECT period_to, (basic_rate/sf_get_ot_rates(paty_code)) basic_rate, posi_code, dept_code, title, vess_code, sal_freq,
                    period_fr period_fr, (basic_rate_g/sf_get_ot_rates(paty_code)) basic_rate_g, paty_code, pahd_year, pahd_mo
             FROM   PYS_PAYROLL_DTL
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = p_empl_id
             AND    paty_code LIKE 'OT%'
             ORDER  BY empl_empl_id, period_to DESC
            )
   LOOP
       BEGIN
          SELECT 1 INTO nCheck FROM PYS_PAYROLL_DTL
          WHERE  empl_empl_id = p_empl_id
          AND    paty_code LIKE 'REG%'
          AND    i.period_to BETWEEN period_fr AND period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             SELECT MAX(seq_no)+1 INTO nSeqNo FROM PYS_PAYROLL_DTL;
             INSERT INTO PYS_PAYROLL_DTL
                    ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
             VALUES ( p_payroll_no, i.pahd_year, i.pahd_mo, i.period_fr, i.period_to, nSeqNo, p_empl_id, i.posi_code, i.title, 'REG-ADJ', 0, 0, i.basic_rate, 0, i.basic_rate, i.vess_code, i.dept_code, USER, SYSDATE, 'ADD', 'N', i.sal_freq, i.vess_code );
              WHEN TOO_MANY_ROWS THEN
                     NULL;
       END;
   END LOOP;

   FOR i IN (SELECT empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq,
                    MIN(period_fr) period_fr, SUM(no_days) no_days, SUM(amt) amt,
                    MAX(basic_rate_g) basic_rate_g, MAX(amt_g) amt_g, MAX(paty_code) paty_code
             FROM   pys_payroll_dtl
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = p_empl_id
             AND    paty_code LIKE 'REG%'
             GROUP  BY empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq
             ORDER  BY empl_empl_id, period_to
            )
   LOOP
       -- get OT total
       IF i.dept_code = 'FL' THEN
          SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
          INTO   nOtDay, nOtAmt
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    title = i.title
          AND    paty_code LIKE 'OT%'
          AND    period_to BETWEEN i.period_fr AND i.period_to
          AND    NOT EXISTS (SELECT 1 FROM pys_payroll_summary
                             WHERE pys_payroll_dtl.empl_empl_id = pys_payroll_summary.empl_id
                             AND   title = i.title
                             AND   pys_payroll_dtl.pahd_payroll_no = pys_payroll_summary.payroll_no
                             AND   pys_payroll_dtl.period_fr = pys_payroll_summary.period_fr
                             AND   pys_payroll_dtl.period_to = pys_payroll_summary.period_to
                            );

       ELSE
          if vPrevEmplID <> i.empl_empl_id then
             SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
             INTO   nOtDay, nOtAmt
             FROM   pys_payroll_dtl
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = i.empl_empl_id
             AND    paty_code LIKE 'OT%';
             --AND    period_to BETWEEN i.period_fr AND i.period_to;
          end if;
       END IF;

       IF vPrevEmplID <> i.empl_empl_id THEN
          -- get COLA total
          SELECT NVL(SUM(no_days),0) cola_days, NVL(SUM(amt),0) cola_amt
          INTO   nColaDay, nColaAmt
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'COLA';
          --and    period_to between i.period_fr and i.period_to;
          nColaRate := 0;
          IF i.dept_code = 'FL' THEN
             nColaRate := sf_get_payroll_cola(i.empl_empl_id, p_payroll_no, p_payroll_no);
          ELSE
             IF nColaAmt > 0 THEN
                nColaRate := (nColaAmt/nColaDay);
             END IF;
          END IF;
       END IF;

       -- get PAGIBIG total
       BEGIN
          SELECT amt
          INTO   nPAGIBIG
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'PAGIBIG'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPAGIBIG := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PAGIBIG amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get PHILHEALTH total
       BEGIN
          SELECT amt
          INTO   nPHILHEALTH
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'PHILHEALTH'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPHILHEALTH := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PHILHEALTH amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get SSS total
       BEGIN
          SELECT amt
          INTO   nSSS
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'SSS'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nSSS := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for SSS amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get WHTAX total
       BEGIN
          SELECT amt
          INTO   nWHTAX
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'WHTAX'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nWHTAX := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for WHTAX amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get HDMF LOAN/PAGIBIGLOAN total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nPAGIBIGLOAN
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'HDMF LOAN'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPAGIBIGLOAN := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PAGIBIGLOAN amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get SSSLOAN total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nSSSLOAN
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'SSSLOAN'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nSSSLOAN := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for SSSLOAN amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get VALE total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nVALE
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'VALE'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nVALE := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for VALE amt of ' || TO_CHAR(i.empl_empl_id));
       END;

       IF i.dept_code IS NULL THEN
          SELECT dept_code INTO vDept
          FROM   pms_employees
          WHERE  empl_id = i.empl_empl_id;
       ELSE
          vDept := i.dept_code;
       END IF;

       nBasic  := i.basic_rate;
       vLOPort := 'N';
       FOR k IN (SELECT basic_rate, title, vess_code, paty_code
                 FROM   pys_payroll_dtl
                 WHERE  empl_empl_id = i.empl_empl_id
                 AND    pahd_payroll_no = p_payroll_no
                 AND    paty_code LIKE 'REG%'
                 ORDER  BY period_to DESC)
       LOOP
          nLBasic := k.basic_rate;
          vLVess  := k.vess_code;
          vLTitle := k.title;
          IF i.paty_code LIKE 'REG-OP%' THEN
             vLOPort := 'Y';
          END IF;
          EXIT;
       END LOOP;
       vOPort := 'N';
       IF vDept = 'FL' THEN
          nSalary := i.amt + nOtAmt;
          nOtAmt  := 0;
          nRegDay := i.no_days + nOtDay;
          nOtDay  := 0;
       ELSIF vDept = 'MA-CREW' THEN
          nRegDay  := i.no_days;
          nSalary  := i.amt;
       ELSE
          nSalary := i.amt;
          nRegDay := i.no_days;
          IF nBasic > 10000 THEN
             nBasic := nBasic/30;
          END IF;
          IF i.paty_code LIKE 'REG-OP%' THEN
             vOPort := 'Y';
          END IF;
       END IF;

       nNetAmt := (nSalary + nOtAmt + nColaAmt) -
                  (nPAGIBIG + nPAGIBIGLOAN + nSSS + nSSSLOAN + nPHILHEALTH + nWHTAX + nVALE);

       INSERT INTO pys_payroll_summary
              ( payroll_no, period_fr, period_to, empl_id, dept_code, vess_code,
               title, sal_freq, basic_rate, no_days, amount, cola_amt, cola_day, cola_rate,
               ot_amt, ot_day, pag_ibig_amt, pag_ibig_loan, sss_amt, sss_loan,
               medicare, whtax, vale, net_amount, l_basic_rate, l_vess_code, l_title,
               basic_rate_g, amount_g, oport, l_oport
              )
       VALUES ( p_payroll_no, i.period_fr, i.period_to, i.empl_empl_id, vDept, i.vess_code,
               i.title, i.sal_freq, nBasic, nRegDay, nSalary, nColaAmt, nColaDay, nColaRate,
               nOtAmt, nOtDay, nPAGIBIG, nPAGIBIGLOAN, nSSS, nSSSLOAN,
               nPHILHEALTH, nWHTAX, nVALE, nNetAmt, nLBasic, vLVess, vLTitle,
               i.basic_rate_g, i.amt_g, vOPort, vLOPort
              );

      nOtAmt       := 0;
      nRegDay      := 0;
      nSalary      := 0;
      nOtDay       := 0;
      nColaAmt     := 0;
      nColaDay     := 0;
      nNetAmt      := 0;
      nPAGIBIG     := 0;
      nPHILHEALTH  := 0;
      nSSS         := 0;
      nWHTAX       := 0;
      nPAGIBIGLOAN := 0;
      nSSSLOAN     := 0;
      nVALE        := 0;
      nLBasic      := 0;
      vLVess       := NULL;
      vLTitle      := NULL;
      vPrevEmplID  := i.empl_empl_id;
   END LOOP;

   -- check employees with negative net amount
   FOR i IN (SELECT empl_id empl_empl_id, SUM(net_amount) net_amt, SUM(no_days) no_days, COUNT(1) nRec
             FROM   pys_payroll_summary
             WHERE  payroll_no = p_payroll_no
             GROUP  BY empl_id
             HAVING SUM(net_amount) < 0 )
   LOOP
      bFirst := TRUE;
      nRecAmt := 0;
      FOR j IN (SELECT ROWID, vale, net_amount
                FROM   pys_payroll_summary
                WHERE  empl_id = i.empl_empl_id
                AND    payroll_no = p_payroll_no
                FOR    UPDATE
                ORDER  BY net_amount DESC)
      LOOP
         IF i.nRec = 1 THEN
            UPDATE pys_payroll_summary
            SET    vale = (vale + net_amount),
                   net_amount = 0
            WHERE  ROWID = j.ROWID;
         ELSE
            IF bFirst THEN
               UPDATE pys_payroll_summary
               SET    net_amount =0
               WHERE  ROWID = j.ROWID;
               nRecAmt := j.net_amount;
            ELSE
               UPDATE pys_payroll_summary
               SET    net_amount =0,
                      vale = net_amount + nRecAmt
               WHERE  ROWID = j.ROWID;
            END IF;
         END IF;
         bFirst := FALSE;
      END LOOP;
   END LOOP;
   COMMIT;

   -- if end of month generate Payroll A Summary
   SELECT period_fr, period_to
   INTO   dStart, dEnd
   FROM   pys_payroll_hdr
   WHERE  payroll_no = p_payroll_no;

   -- check if 13thmonth is computed
   bIsFinal := TRUE;
   IF TO_CHAR(dStart, 'MON') = 'NOV' THEN
      IF trunc(sysdate) > to_date(TO_CHAR(dStart, 'YYYYMM') || '21', 'YYYYMMDD') then
         bIsFinal := FALSE;
      END IF;
   END IF;

   IF TO_CHAR(dStart, 'DD') = '16' THEN
      SELECT MAX(payroll_no)
      INTO   nPrevPayrollNo
      FROM   pys_payroll_hdr
      WHERE  payroll_no < p_payroll_no;

      SELECT period_fr
      INTO   dStart2
      FROM   pys_payroll_hdr
      WHERE  payroll_no = nPrevPayrollNo;

      FOR i IN (SELECT empl_id, MAX(period_to) period_to, MAX(sal_freq) sal_freq, MAX(dept_code) dept_code,
                       SUM(cola_amt) cola_amt, SUM(cola_day) cola_day, MAX(cola_rate) cola_rate
                FROM   pys_payroll_summary
                WHERE  payroll_no IN (nPrevPayrollNo, p_payroll_no)
                AND    empl_id = p_empl_id
                GROUP  BY empl_id
                HAVING MAX(period_to) > dStart2)
      LOOP
         FOR k IN (SELECT empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g, oport
                   FROM   pys_payroll_summary
                   WHERE  empl_id = i.empl_id
                   AND    payroll_no IN (nPrevPayrollNo, p_payroll_no)
                   ORDER  BY payroll_no DESC, period_to DESC)
         LOOP
            IF i.sal_freq = 'MONTHLY' THEN
               nColaRate := 0;
               IF i.dept_code = 'FL' THEN
                  IF i.cola_amt > 0 THEN
                     nColaRate := i.cola_rate;
                  END IF;
               END IF;
               UPDATE pys_payroll_summary
               SET    l_vess_code_a  = k.l_vess_code,
                      l_title_a      = NVL(k.l_title, k.title),
                      l_basic_rate_a = k.basic_rate_g+nColaRate
               WHERE  empl_id = i.empl_id
               AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
            ELSE
               IF i.dept_code = 'FL' THEN
                  nColaRate := 0;
                  IF i.cola_amt > 0 THEN
                     nColaRate := i.cola_rate;
                  END IF;
                  UPDATE pys_payroll_summary
                  SET    l_vess_code_a  = k.l_vess_code,
                         l_title_a      = NVL(k.l_title, k.title),
                         l_basic_rate_a = NVL(k.l_basic_rate, k.basic_rate) +  nColaRate
                  WHERE  empl_id = i.empl_id
                  AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
               ELSE
                  nColaRate := 0;
                  IF i.dept_code = 'MA-CREW' THEN
                     IF i.cola_amt > 0 THEN
                        nColaRate := i.cola_rate;
                     END IF;
                     UPDATE pys_payroll_summary
                     SET    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = NVL(k.l_title, k.title),
                            l_basic_rate_a = k.basic_rate_g+nColaRate
                     WHERE  empl_id = i.empl_id
                     AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
                  ELSE
                     UPDATE pys_payroll_summary
                     SET    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = NVL(k.l_title, k.title),
                            l_basic_rate   = k.basic_rate,
                            l_basic_rate_a = k.basic_rate_g,
                            l_oport        = k.oport
                     WHERE  empl_id = i.empl_id
                     AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
                  END IF;
               END IF;
            END IF;

            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            IF bIsFinal THEN
               nSILP_a := 0;    n13th_amt_a := 0;   n13th_n_mon   := 0;
               nSILP_b := 0;    n13th_amt_b := 0;   n13th_n_mon_b := 0;
               IF TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY') > dEnd THEN
                  dPeriodFr := ADD_MONTHS(TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY'),-12);
                  dPeriodTo := TO_DATE('3011' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY');
               ELSE
                  dPeriodFr := TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY');
                  dPeriodTo := ADD_MONTHS(TO_DATE('3011' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY'),12);
               END IF;
               FOR n IN (SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                SUM(pay.amount) amount,
                                SUM(pay.no_days) no_days,
                                SUM(pay.cola_amt) cola_amt,
                                NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)) basic_rate_a,
                                MAX(pay.dept_code) dept_code,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon,
                                (DECODE(MAX(pay.dept_code),'FL', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)),'MA-CREW', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)), NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))) )  amount_g
                                --+
                                -- decode(max(pay.dept_code),'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         AND    pay.payroll_no = pahd.payroll_no
                         AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM')
                         having (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) ) > 0)
               LOOP
                  n13th_n_mon := n13th_n_mon + n.nMon;
                  n13th_amt_a := n13th_amt_a + NVL(n.amount_g,0);
               END LOOP;

               if n13th_n_mon > 0 then
                  n13th_a := (n13th_amt_a/n13th_n_mon) * (n13th_n_mon/12);
               end if;

               FOR n IN (SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                SUM(pay.amount) amount,
                                SUM(pay.no_days) no_days,
                                SUM(pay.cola_amt) cola_amt,
                                NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)) basic_rate_a,
                                MAX(pay.dept_code) dept_code,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon,
                                (DECODE(MAX(pay.dept_code),'FL', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)),'MA-CREW', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)), NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))) )  amount_g
                                --+
                                -- decode(max(pay.dept_code),'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         AND    pay.payroll_no = pahd.payroll_no
                         AND    not (oport = 'Y' and pay.no_days < 0)
                         AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM'))
               LOOP
                  n13th_n_mon_b := n13th_n_mon_b + n.nMon;
                  n13th_amt_b := n13th_amt_b + NVL(n.amount,0);
               END LOOP;

               if n13th_n_mon_b > 0 then
                  n13th_b := (n13th_amt_b/n13th_n_mon_b) * (n13th_n_mon_b/12);
               end if;

               FOR n IN (SELECT basic_rate, SUM(nMon) nMon FROM (
                         SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                DECODE(pay.oport,'Y',round(pay.basic_rate/nOuterR,2),pay.basic_rate)  basic_rate,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         AND    pay.payroll_no = pahd.payroll_no
                         and    not (oport = 'Y' and pay.no_days < 0)
                         AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM'), DECODE(pay.oport,'Y',round(pay.basic_rate/nOuterR,2),pay.basic_rate) )
                         GROUP  BY basic_rate
                        )
               LOOP
                  nSILP_b := nSILP_b + (n.basic_rate * 5 * (n.nMon/12));
               END LOOP;

               FOR n IN (SELECT basic_rate, SUM(nMon) nMon FROM (
                         SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                                DECODE(MAX(pay.dept_code), 'FL', NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)),
                                                           'MA-CREW', NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)),
                                                            NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))/30)  basic_rate,
                                DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon
                         FROM   pys_payroll_summary pay,
                                pys_payroll_hdr pahd
                         WHERE  pay.empl_id = i.empl_id
                         AND    pay.payroll_no = pahd.payroll_no
                         AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                         GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM')
                         having (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) ) > 0 )
                         GROUP  BY basic_rate
                        )
               LOOP
                  nSILP_a := nSILP_a + (n.basic_rate * 5 * (n.nMon/12));
               END LOOP;

               BEGIN
                  INSERT INTO pys_13th_month_summary
                         (empl_id, dept_code, vess_code, title, period_fr, period_to, m_13_amt, m_13_amt_a, silp_amt, silp_amt_a )
                  VALUES (i.empl_id, i.dept_code, k.l_vess_code, NVL(k.l_title, k.title), dPeriodFr, dPeriodTo, n13th_b, n13th_a, nSILP_b, nSILP_a );
               EXCEPTION
                  WHEN DUP_VAL_ON_INDEX THEN
                     UPDATE pys_13th_month_summary
                     SET    m_13_amt   = n13th_b,
                            m_13_amt_a = n13th_a,
                            silp_amt   = nSILP_b,
                            silp_amt_a = nSILP_a
                     WHERE  empl_id = i.empl_id
                     AND    period_fr = dPeriodFr
                     AND    period_to = dPeriodTo;
               END;
            END IF;
            EXIT;
         END LOOP;
      END LOOP;
   END IF;

   COMMIT;

   if p_payroll_no = 20091231 then
        dbms_output.put_line('Update dup whtax');
        update PYS_PAYROLL_SUMMARY
        set    whtax = 0
        where  payroll_no = 20091231
        and    medicare = 0
        and    empl_id = p_empl_id
        and    empl_id in (
                           select empl_id from PYS_PAYROLL_SUMMARY
                           where payroll_no = 20091231 having (count(1) > 1 and avg(whtax) > 0 )
                           group by empl_id );
        dbms_output.put_line('Update dup whtax record : '||sql%rowcount);
        dbms_output.put_line('Update dup net total');
        update PYS_PAYROLL_SUMMARY
        set    net_amount = ((amount + Ot_Amt + Cola_Amt) -
                          (pag_ibig_amt + pag_ibig_loan + sss_amt + sss_loan + medicare + whtax + vale))
        where  payroll_no = 20091231
        and    medicare = 0
        and    empl_id = p_empl_id
        and    empl_id in (
                          select empl_id from PYS_PAYROLL_SUMMARY
                          where  payroll_no = 20091231 having (count(1) > 1 and avg(whtax) > 0 )
                          group by empl_id );
        dbms_output.put_line('Update dup net total : '||sql%rowcount);

        commit;
   end if;

END sp_payroll_summary_empl;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PAYROLL_SUMMARY_EMPL_OLD" (
   p_payroll_no IN NUMBER,
   p_empl_id IN VARCHAR2
   ) AS
   nRegDay      NUMBER(8,4) := 0;
   nSalary      NUMBER(8,2) := 0;
   nOtAmt       NUMBER(8,2) := 0;
   nOtDay       NUMBER(8,4) := 0;
   nColaAmt     NUMBER(8,2) := 0;
   nColaDay     NUMBER(8,4) := 0;
   nNetAmt      NUMBER(8,2) := 0;
   nPAGIBIG     NUMBER(8,2) := 0;
   nPHILHEALTH  NUMBER(8,2) := 0;
   nSSS         NUMBER(8,2) := 0;
   nWHTAX       NUMBER(8,2) := 0;
   nPAGIBIGLOAN NUMBER(8,2) := 0;
   nSSSLOAN     NUMBER(8,2) := 0;
   nVALE        NUMBER(8,2) := 0;
   nBasic       NUMBER(8,2) := 0;
   nLBasic      NUMBER(8,2) := 0;
   vLVess       VARCHAR2(16);
   vDept        VARCHAR2(16);
   vLTitle      VARCHAR2(60);
   bFirst       BOOLEAN;
   nRecAmt      NUMBER(10,2);
   vPrevEmplID  VARCHAR2(16) := 'x x x';
   dStart       DATE;
   dStart2      DATE;
   dEnd         DATE;
   nPrevPayrollNo NUMBER;
   nColaRate    NUMBER(8,2);
   nAmt_a       NUMBER(8,2);
   n13th_n_mon  NUMBER(9,2);
   n13th_a      NUMBER(9,2);
   n13th_b      NUMBER(9,2);
   nSILP_a      NUMBER(9,2);
   nSILP_b      NUMBER(9,2);
   n13th_amt_a  NUMBER(12,2);
   n13th_amt_b  NUMBER(12,2);
   dPeriodFr    DATE;
   dPeriodTo    DATE;
   vOPort       VARCHAR2(1);
   vLOPort      VARCHAR2(1);
   nOuterR      NUMBER(8,4);
   nCheck       NUMBER;
   nSeqNo       NUMBER;
BEGIN
   -- clear summary
   DELETE FROM PYS_PAYROLL_SUMMARY
   WHERE  payroll_no = p_payroll_no
   AND    empl_id = p_empl_id;
   COMMIT;
   -- clear summary
   DELETE FROM PYS_13TH_MONTH
   WHERE  payroll_no = p_payroll_no
   AND    empl_id = p_empl_id;
   COMMIT;
   -- get Outer Port Rate
   BEGIN
      SELECT rate
      INTO   nOuterR
      FROM   PYS_PAYROLL_TYPES
      WHERE  code = 'REG-OP';
   EXCEPTION
      WHEN NO_DATA_FOUND THEN nOuterR := 1;
      WHEN OTHERS THEN nOuterR := 1;
   END;
   FOR i IN (SELECT period_to, (basic_rate/sf_get_ot_rates(paty_code)) basic_rate, posi_code, dept_code, title, vess_code, sal_freq,
                    period_fr period_fr, (basic_rate_g/sf_get_ot_rates(paty_code)) basic_rate_g, paty_code, pahd_year, pahd_mo
             FROM   PYS_PAYROLL_DTL
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = p_empl_id
             AND    paty_code LIKE 'OT%'
             ORDER  BY empl_empl_id, period_to DESC
            )
   LOOP
       BEGIN
          SELECT 1 INTO nCheck FROM PYS_PAYROLL_DTL
          WHERE  empl_empl_id = p_empl_id
          AND    paty_code LIKE 'REG%'
          AND    i.period_to BETWEEN period_fr AND period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN
             SELECT MAX(seq_no)+1 INTO nSeqNo FROM PYS_PAYROLL_DTL;
             INSERT INTO PYS_PAYROLL_DTL
                    ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
             VALUES ( p_payroll_no, i.pahd_year, i.pahd_mo, i.period_fr, i.period_to, nSeqNo, p_empl_id, i.posi_code, i.title, 'REG-ADJ', 0, 0, i.basic_rate, 0, i.basic_rate, i.vess_code, i.dept_code, USER, SYSDATE, 'ADD', 'N', i.sal_freq, i.vess_code );
              WHEN TOO_MANY_ROWS THEN
                     NULL;
       END;
   END LOOP;
   FOR i IN (SELECT empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq,
                    MIN(period_fr) period_fr, SUM(no_days) no_days, SUM(amt) amt,
                    MAX(basic_rate_g) basic_rate_g, MAX(amt_g) amt_g, MAX(paty_code) paty_code
             FROM   PYS_PAYROLL_DTL
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = p_empl_id
             AND    paty_code LIKE 'REG%'
             GROUP  BY empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq
             ORDER  BY empl_empl_id, period_to DESC
            )
   LOOP
       -- get OT total
       IF i.dept_code = 'FL' THEN
          SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
          INTO   nOtDay, nOtAmt
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    title = i.title
          AND    paty_code LIKE 'OT%'
          AND    period_to BETWEEN i.period_fr AND i.period_to
          AND    NOT EXISTS (SELECT 1 FROM PYS_PAYROLL_SUMMARY
                             WHERE PYS_PAYROLL_DTL.empl_empl_id = PYS_PAYROLL_SUMMARY.empl_id
                             AND   title = i.title
                             AND   PYS_PAYROLL_DTL.pahd_payroll_no = PYS_PAYROLL_SUMMARY.payroll_no
                             AND   PYS_PAYROLL_DTL.period_fr = PYS_PAYROLL_SUMMARY.period_fr
                             AND   PYS_PAYROLL_DTL.period_to = PYS_PAYROLL_SUMMARY.period_to
                            );
       ELSE
          IF vPrevEmplID <> i.empl_empl_id THEN
             SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
             INTO   nOtDay, nOtAmt
             FROM   PYS_PAYROLL_DTL
             WHERE  pahd_payroll_no = p_payroll_no
             AND    empl_empl_id = i.empl_empl_id
             AND    paty_code LIKE 'OT%';
             --AND    period_to BETWEEN i.period_fr AND i.period_to;
          END IF;
       END IF;
       IF vPrevEmplID <> i.empl_empl_id THEN
          -- get COLA total
          SELECT NVL(SUM(no_days),0) cola_days, NVL(SUM(amt),0) cola_amt
          INTO   nColaDay, nColaAmt
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'COLA';
          --and    period_to between i.period_fr and i.period_to;
          nColaRate := 0;
          IF i.dept_code = 'FL' THEN
             nColaRate := sf_get_payroll_cola(i.empl_empl_id, p_payroll_no, p_payroll_no);
          ELSE
             IF nColaAmt > 0 THEN
                nColaRate := (nColaAmt/nColaDay);
             END IF;
          END IF;
       END IF;
       -- get PAGIBIG total
       BEGIN
          SELECT amt
          INTO   nPAGIBIG
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'PAGIBIG'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPAGIBIG := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PAGIBIG amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get PHILHEALTH total
       BEGIN
          SELECT amt
          INTO   nPHILHEALTH
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'PHILHEALTH'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPHILHEALTH := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PHILHEALTH amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get SSS total
       BEGIN
          SELECT amt
          INTO   nSSS
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'SSS'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nSSS := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for SSS amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get WHTAX total
       BEGIN
          SELECT amt
          INTO   nWHTAX
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'WHTAX'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nWHTAX := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for WHTAX amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get HDMF LOAN/PAGIBIGLOAN total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nPAGIBIGLOAN
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'HDMF LOAN'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nPAGIBIGLOAN := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for PAGIBIGLOAN amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get SSSLOAN total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nSSSLOAN
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'SSSLOAN'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nSSSLOAN := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for SSSLOAN amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       -- get VALE total
       BEGIN
          SELECT NVL(SUM(amt),0)
          INTO   nVALE
          FROM   PYS_PAYROLL_DTL
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    dety_code LIKE 'VALE'
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       EXCEPTION
          WHEN NO_DATA_FOUND THEN nVALE := 0;
          WHEN TOO_MANY_ROWS THEN
             RAISE_APPLICATION_ERROR (-20001, 'ERROR on payroll summary for VALE amt of ' || TO_CHAR(i.empl_empl_id));
       END;
       IF i.dept_code IS NULL THEN
          SELECT dept_code INTO vDept
          FROM   PMS_EMPLOYEES
          WHERE  empl_id = i.empl_empl_id;
       ELSE
          vDept := i.dept_code;
       END IF;
       nBasic  := i.basic_rate;
       vLOPort := 'N';
       FOR k IN (SELECT basic_rate, title, vess_code, paty_code
                 FROM   PYS_PAYROLL_DTL
                 WHERE  empl_empl_id = i.empl_empl_id
                 AND    pahd_payroll_no = p_payroll_no
                 AND    paty_code LIKE 'REG%'
                 ORDER  BY period_to DESC)
       LOOP
          nLBasic := k.basic_rate;
          vLVess  := k.vess_code;
          vLTitle := k.title;
          IF i.paty_code LIKE 'REG-OP%' THEN
             vLOPort := 'Y';
          END IF;
          EXIT;
       END LOOP;
       vOPort := 'N';
       IF vDept = 'FL' THEN
          nSalary := i.amt + nOtAmt;
          nOtAmt  := 0;
          nRegDay := i.no_days + nOtDay;
          nOtDay  := 0;
       ELSIF vDept = 'MA-CREW' THEN
          nRegDay  := i.no_days;
          nSalary  := i.amt;
       ELSE
          nSalary := i.amt;
          nRegDay := i.no_days;
          IF nBasic > 10000 THEN
             nBasic := nBasic/30;
          END IF;
          IF i.paty_code LIKE 'REG-OP%' THEN
             vOPort := 'Y';
          END IF;
       END IF;
       nNetAmt := (nSalary + nOtAmt + nColaAmt) -
                  (nPAGIBIG + nPAGIBIGLOAN + nSSS + nSSSLOAN + nPHILHEALTH + nWHTAX + nVALE);
       INSERT INTO PYS_PAYROLL_SUMMARY
              ( payroll_no, period_fr, period_to, empl_id, dept_code, vess_code,
               title, sal_freq, basic_rate, no_days, amount, cola_amt, cola_day, cola_rate,
               ot_amt, ot_day, pag_ibig_amt, pag_ibig_loan, sss_amt, sss_loan,
               medicare, whtax, vale, net_amount, l_basic_rate, l_vess_code, l_title,
               basic_rate_g, amount_g, oport, l_oport
              )
       VALUES ( p_payroll_no, i.period_fr, i.period_to, i.empl_empl_id, vDept, i.vess_code,
               i.title, i.sal_freq, nBasic, nRegDay, nSalary, nColaAmt, nColaDay, nColaRate,
               nOtAmt, nOtDay, nPAGIBIG, nPAGIBIGLOAN, nSSS, nSSSLOAN,
               nPHILHEALTH, nWHTAX, nVALE, nNetAmt, nLBasic, vLVess, vLTitle,
               i.basic_rate_g, i.amt_g, vOPort, vLOPort
              );
      nOtAmt       := 0;
      nRegDay      := 0;
      nSalary      := 0;
      nOtDay       := 0;
      nColaAmt     := 0;
      nColaDay     := 0;
      nNetAmt      := 0;
      nPAGIBIG     := 0;
      nPHILHEALTH  := 0;
      nSSS         := 0;
      nWHTAX       := 0;
      nPAGIBIGLOAN := 0;
      nSSSLOAN     := 0;
      nVALE        := 0;
      nLBasic      := 0;
      vLVess       := NULL;
      vLTitle      := NULL;
      vPrevEmplID  := i.empl_empl_id;
   END LOOP;
   -- check employees with negative net amount
   FOR i IN (SELECT empl_id empl_empl_id, SUM(net_amount) net_amt, SUM(no_days) no_days, COUNT(1) nRec
             FROM   PYS_PAYROLL_SUMMARY
             WHERE  payroll_no = p_payroll_no
             GROUP  BY empl_id
             HAVING SUM(net_amount) < 0 )
   LOOP
      bFirst := TRUE;
      nRecAmt := 0;
      FOR j IN (SELECT ROWID, vale, net_amount
                FROM   PYS_PAYROLL_SUMMARY
                WHERE  empl_id = i.empl_empl_id
                AND    payroll_no = p_payroll_no
                FOR    UPDATE
                ORDER  BY net_amount DESC)
      LOOP
         IF i.nRec = 1 THEN
            UPDATE PYS_PAYROLL_SUMMARY
            SET    vale = (vale + net_amount),
                   net_amount = 0
            WHERE  ROWID = j.ROWID;
         ELSE
            IF bFirst THEN
               UPDATE PYS_PAYROLL_SUMMARY
               SET    net_amount =0
               WHERE  ROWID = j.ROWID;
               nRecAmt := j.net_amount;
            ELSE
               UPDATE PYS_PAYROLL_SUMMARY
               SET    net_amount =0,
                      vale = net_amount + nRecAmt
               WHERE  ROWID = j.ROWID;
            END IF;
         END IF;
         bFirst := FALSE;
      END LOOP;
   END LOOP;
   COMMIT;

   -- if end of month generate Payroll A Summary
   SELECT period_fr, period_to
   INTO   dStart, dEnd
   FROM   PYS_PAYROLL_HDR
   WHERE  payroll_no = p_payroll_no;

   IF TO_CHAR(dStart, 'DD') = '16' THEN
      SELECT MAX(payroll_no)
      INTO   nPrevPayrollNo
      FROM   PYS_PAYROLL_HDR
      WHERE  payroll_no < p_payroll_no;
      SELECT period_fr
      INTO   dStart2
      FROM   PYS_PAYROLL_HDR
      WHERE  payroll_no = nPrevPayrollNo;
      FOR i IN (SELECT empl_id, MAX(period_to) period_to, MAX(sal_freq) sal_freq, MAX(dept_code) dept_code,
                       SUM(cola_amt) cola_amt, SUM(cola_day) cola_day, MAX(cola_rate) cola_rate
                FROM   PYS_PAYROLL_SUMMARY
                WHERE  payroll_no IN (nPrevPayrollNo, p_payroll_no)
                GROUP  BY empl_id
                HAVING MAX(period_to) > dStart2)
      LOOP
         FOR k IN (SELECT empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g, oport
                   FROM   PYS_PAYROLL_SUMMARY
                   WHERE  empl_id = i.empl_id
                   AND    payroll_no IN (nPrevPayrollNo, p_payroll_no)
                   ORDER  BY payroll_no DESC, period_to DESC)
         LOOP
            IF i.sal_freq = 'MONTHLY' THEN
               nColaRate := 0;
               IF i.dept_code = 'FL' THEN
                  IF i.cola_amt > 0 THEN
                     nColaRate := i.cola_rate;
                  END IF;
               END IF;
               UPDATE PYS_PAYROLL_SUMMARY
               SET    l_vess_code_a  = k.l_vess_code,
                      l_title_a      = NVL(k.l_title, k.title),
                      l_basic_rate_a = k.basic_rate_g+nColaRate
               WHERE  empl_id = i.empl_id
               AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
            ELSE
               IF i.dept_code = 'FL' THEN
                  nColaRate := 0;
                  IF i.cola_amt > 0 THEN
                     nColaRate := i.cola_rate;
                  END IF;
                  UPDATE PYS_PAYROLL_SUMMARY
                  SET    l_vess_code_a  = k.l_vess_code,
                         l_title_a      = NVL(k.l_title, k.title),
                         l_basic_rate_a = NVL(k.l_basic_rate, k.basic_rate) +  nColaRate
                  WHERE  empl_id = i.empl_id
                  AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
               ELSE
                  nColaRate := 0;
                  IF i.dept_code = 'MA-CREW' THEN
                     IF i.cola_amt > 0 THEN
                        nColaRate := i.cola_rate;
                     END IF;
                     UPDATE PYS_PAYROLL_SUMMARY
                     SET    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = NVL(k.l_title, k.title),
                            l_basic_rate_a = k.basic_rate_g+nColaRate
                     WHERE  empl_id = i.empl_id
                     AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
                  ELSE
                     UPDATE PYS_PAYROLL_SUMMARY
                     SET    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = NVL(k.l_title, k.title),
                            l_basic_rate   = k.basic_rate,
                            l_basic_rate_a = k.basic_rate_g,
                            l_oport        = k.oport
                     WHERE  empl_id = i.empl_id
                     AND    payroll_no IN (nPrevPayrollNo, p_payroll_no);
                  END IF;
               END IF;
            END IF;
            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            nSILP_a := 0;    n13th_amt_a := 0;   n13th_n_mon := 0;
            nSILP_b := 0;    n13th_amt_b := 0;
            IF TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY') > dEnd THEN
               dPeriodFr := ADD_MONTHS(TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY'),-12);
               dPeriodTo := TO_DATE('3011' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY');
            ELSE
               dPeriodFr := TO_DATE('0112' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY');
               dPeriodTo := ADD_MONTHS(TO_DATE('3011' || TO_CHAR(dEnd, 'YYYY'), 'DDMMYYYY'),12);
            END IF;
            FOR n IN (SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                             SUM(pay.amount) amount,
                             SUM(pay.no_days) no_days,
                             SUM(pay.cola_amt) cola_amt,
                             NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)) basic_rate_a,
                             MAX(pay.dept_code) dept_code,
                             DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon,
                             (DECODE(MAX(pay.dept_code),'FL', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)),'MA-CREW', SUM(pay.no_days)*(NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))-MAX(pay.cola_rate)), NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))) )  amount_g
                             --+
                             -- decode(max(pay.dept_code),'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                      FROM   PYS_PAYROLL_SUMMARY pay,
                             PYS_PAYROLL_HDR pahd
                      WHERE  pay.empl_id = i.empl_id
                      AND    pay.payroll_no = pahd.payroll_no
                      AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                      GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM'))
            LOOP
               n13th_n_mon := n13th_n_mon + n.nMon;
               n13th_amt_b := n13th_amt_b + NVL(n.amount,0);
               n13th_amt_a := n13th_amt_a + NVL(n.amount_g,0);
            END LOOP;
            n13th_b := (n13th_amt_b/n13th_n_mon) * (n13th_n_mon/12);
            n13th_a := (n13th_amt_a/n13th_n_mon) * (n13th_n_mon/12);
            FOR n IN (SELECT basic_rate, SUM(nMon) nMon FROM (
                      SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                             DECODE(MAX(l_oport),'Y',MAX(pay.l_basic_rate)/nOuterR,MAX(pay.l_basic_rate))  basic_rate,
                             DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon
                      FROM   PYS_PAYROLL_SUMMARY pay,
                             PYS_PAYROLL_HDR pahd
                      WHERE  pay.empl_id = i.empl_id
                      AND    pay.payroll_no = pahd.payroll_no
                      AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                      GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM') )
                      GROUP  BY basic_rate
                     )
            LOOP
               nSILP_b := nSILP_b + (n.basic_rate * 5 * (n.nMon/12));
            END LOOP;
            FOR n IN (SELECT basic_rate, SUM(nMon) nMon FROM (
                      SELECT TO_CHAR(pahd.period_to,'YYYYMM') cur_mon,
                             DECODE(MAX(pay.dept_code), 'FL', NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)),
                                                        'MA-CREW', NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate)),
                                                         NVL(MAX(pay.l_basic_rate_a),MAX(pay.l_basic_rate))/30)  basic_rate,
                             DECODE(GREATEST(SUM(pay.no_days),15),15,.5,1) nMon
                      FROM   PYS_PAYROLL_SUMMARY pay,
                             PYS_PAYROLL_HDR pahd
                      WHERE  pay.empl_id = i.empl_id
                      AND    pay.payroll_no = pahd.payroll_no
                      AND    pahd.period_to BETWEEN dPeriodFr AND dPeriodTo
                      GROUP  BY TO_CHAR(pahd.period_to,'YYYYMM') )
                      GROUP  BY basic_rate
                     )
            LOOP
               nSILP_a := nSILP_a + (n.basic_rate * 5 * (n.nMon/12));
            END LOOP;
            BEGIN
               INSERT INTO PYS_13TH_MONTH_SUMMARY
                      (empl_id, dept_code, vess_code, title, period_fr, period_to, m_13_amt, m_13_amt_a, silp_amt, silp_amt_a )
               VALUES (i.empl_id, i.dept_code, k.l_vess_code, NVL(k.l_title, k.title), dPeriodFr, dPeriodTo, n13th_b, n13th_a, nSILP_b, nSILP_a );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX THEN
                  UPDATE PYS_13TH_MONTH_SUMMARY
                  SET    m_13_amt   = n13th_b,
                         m_13_amt_a = n13th_a,
                         silp_amt   = nSILP_b,
                         silp_amt_a = nSILP_a
                  WHERE  empl_id = i.empl_id
                  AND    period_fr = dPeriodFr
                  AND    period_to = dPeriodTo;
            END;
            EXIT;
         END LOOP;
      END LOOP;
   END IF;
   COMMIT;
END sp_payroll_summary_empl_old;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POPULATE_CREW_LIST" (p_payroll_no VARCHAR2) AS
  v_mid_s_date VARCHAR2(3) := '26';
  v_mid_e_date VARCHAR2(3) := '10';
  v_end_s_date VARCHAR2(3) := '11';
  v_end_e_date VARCHAR2(3) := '25';
  v_period_fr DATE;
  v_period_to DATE;
  v_pay_fr DATE;
  v_pay_to DATE;
  v_dis_fr DATE;
  v_dis_to DATE;
  v_range_fr DATE;
  v_range_to DATE;
  v_tran_fr DATE;
  v_tran_to DATE;
  v_empl_cnt NUMBER;
  v_distinct_empl_cnt NUMBER;
  v_distinct_empl VARCHAR2(16);
  v_dt_onboard DATE;
  v_dt_wentdown DATE;
  v_dt_fr DATE;
  v_dt_to DATE;
  v_close_tag CHAR(1);
  v_decode_cnt number;
BEGIN
  v_close_tag := 'N';
  v_distinct_empl_cnt := 0;

  BEGIN
   SELECT period_fr, period_to, closed_tag
   INTO   v_period_fr, v_period_to, v_close_tag
   FROM   PYS_PAYROLL_HDR
   WHERE  payroll_no = p_payroll_no;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-20001,'Invalid Payroll No : '||p_payroll_no);
  END;
  IF NVL(v_close_tag,'N') = 'Y' THEN
     DBMS_OUTPUT.PUT_LINE('Payroll Already Closed');
     RETURN;
     -- must not print closed tag
  END IF;
  DELETE FROM PMS_CREW_LIST WHERE payroll_no = p_payroll_no;
  IF LAST_DAY(TRUNC(v_period_to)) = TRUNC(v_period_to) THEN
    v_pay_fr := TO_DATE(TO_CHAR(v_period_fr,'MM')||v_end_s_date||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_pay_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||v_end_e_date||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_dis_fr := TO_DATE(TO_CHAR(v_period_fr,'MM')||'01'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_dis_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||'26'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_range_fr := add_months(TO_DATE(TO_CHAR(v_period_fr,'MM')||'26'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR'),-1);
    v_range_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||'25'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
  ELSE
    v_pay_fr := TO_DATE(TO_CHAR(ADD_MONTHS(v_period_fr,-1),'MM')||v_mid_s_date||TO_CHAR(ADD_MONTHS(v_period_fr,-1),'RRRR'),'MMDDRRRR');
    v_pay_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||v_mid_e_date||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_dis_fr := TO_DATE(TO_CHAR(ADD_MONTHS(v_period_fr,-1),'MM')||'26'||TO_CHAR(ADD_MONTHS(v_period_fr,-1),'RRRR'),'MMDDRRRR');
    v_dis_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||'11'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_range_fr := add_months(TO_DATE(TO_CHAR(v_period_fr,'MM')||'26'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR'),-1);
    v_range_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||'10'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
  END IF;


  v_tran_fr := v_dis_fr;
  v_tran_to := v_dis_to;
  /*
  IF v_period_to=LAST_DAY(v_period_to) THEN
     v_tran_fr := ADD_MONTHS(TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD'),-1);
     v_tran_to := TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD');
  ELSE
     v_tran_fr := TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD');
     v_tran_to := ADD_MONTHS(TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD'),1);
  END IF;
  */
  DBMS_OUTPUT.PUT_LINE('v_period_fr : '||v_period_fr);
  DBMS_OUTPUT.PUT_LINE('v_period_to : '||v_period_to);
  DBMS_OUTPUT.PUT_LINE('v_pay_fr    : '||v_pay_fr   );
  DBMS_OUTPUT.PUT_LINE('v_pay_to    : '||v_pay_to   );
  DBMS_OUTPUT.PUT_LINE('v_tran_fr   : '||v_tran_fr  );
  DBMS_OUTPUT.PUT_LINE('v_tran_to   : '||v_tran_to  );
  DBMS_OUTPUT.PUT_LINE('v_dis_fr   : '||v_dis_fr  );
  DBMS_OUTPUT.PUT_LINE('v_dis_to   : '||v_dis_to  );
  DBMS_OUTPUT.PUT_LINE('v_range_fr   : '||v_range_fr  );
  DBMS_OUTPUT.PUT_LINE('v_range_to   : '||v_range_to  );
  -- voyage

  if v_period_to = last_day(v_period_to) then
     v_decode_cnt := 1;
  else
     v_decode_cnt := 0;
  end if;

  FOR voya IN
    (
    SELECT vess_code, voyage_date, case
                                   when voyage_end_date > v_pay_to then null
                                   when voyage_end_date <= v_pay_to then voyage_end_date
                                   end voyage_end_date
    FROM   CMS_VOYAGES
    WHERE  1 = 1
    AND    ((voyage_end_date IS NULL AND voyage_date <= v_pay_fr)
           OR (voyage_end_date BETWEEN v_range_fr AND v_range_to)
           OR (v_pay_fr between voyage_date and voyage_end_date)
           OR (voyage_end_date IS NULL AND voyage_date BETWEEN v_range_fr AND v_range_to))
    ORDER BY voyage_date
    )
  LOOP
    -- crew
    if voya.vess_code = 'SK' then
    DBMS_OUTPUT.PUT_LINE('vess voya.vess_code: '||voya.vess_code||';voya.voyage_date: '||voya.voyage_date||'; voya.voyage_end_date: '|| voya.voyage_end_date );
    end if;
    FOR vcrew IN (
      SELECT empl_empl_id, title, dt_embarked,  case
                                        when trunc(dt_disembarked) > v_pay_to then null
                                        when trunc(dt_disembarked) <= v_pay_to then dt_disembarked
                                        end dt_disembarked, tran_no_embarked, tran_no_disembarked, rank_code, voya_vess_code
      FROM   CMS_VOYAGE_CREW
      WHERE  voya.vess_code = voya_vess_code
      AND    empl_empl_id is not null
      AND    voya.voyage_date = voya_voyage_date
      AND    ((dt_embarked <= v_pay_fr AND (dt_disembarked IS NULL OR dt_disembarked > v_pay_fr))
              OR (trunc(dt_embarked) BETWEEN v_range_fr AND v_range_to)
              OR ((dt_disembarked BETWEEN v_range_fr AND v_range_to))-- AND voya.voyage_end_date IS NOT NULL)
              OR ((dt_disembarked = voya.voyage_end_date) AND (voya.voyage_end_date IS NOT NULL OR dt_disembarked > v_pay_fr))
              OR ((dt_disembarked >= v_dis_fr AND dt_disembarked < v_dis_to) AND voya.voyage_end_date IS NULL
                   AND EXISTS(SELECT 1 FROM PMS_EMPLOYEE_MOVEMENTS WHERE tran_no_disembarked = tran_no AND to_vess_code IS NULL))
              )
      ORDER  BY empl_empl_id, dt_embarked)
    LOOP
      v_empl_cnt := 0;
      if v_distinct_empl is null then
         v_distinct_empl_cnt := 1;
         v_distinct_empl := vcrew.empl_empl_id;
      elsif v_distinct_empl = vcrew.empl_empl_id then
         v_distinct_empl_cnt := v_distinct_empl_cnt + 1;
      elsif v_distinct_empl <> vcrew.empl_empl_id then
         v_distinct_empl_cnt := 1;
         v_distinct_empl := vcrew.empl_empl_id;
      else
         raise_application_error(-20005, 'Error Populating Crew List');
         --dbms_output.put_line(v_distinct_empl_cnt ||' - '||vcrew.empl_empl_id||' - '|| v_distinct_empl);
      end if;

      --if vcrew.empl_empl_id = 'S00036' then
      --  dbms_output.put_line('v_distinct_empl_cnt - '||v_distinct_empl_cnt);
      --   dbms_output.put_line('v_distinct_empl - '||v_distinct_empl);
      --end if;
      v_dt_onboard := NULL;
      v_dt_wentdown := NULL;
      v_dt_fr := NULL;
      v_dt_to := NULL;
      IF v_period_fr <= trunc(vcrew.dt_embarked) THEN
         v_dt_onboard := vcrew.dt_embarked;
         v_dt_fr := vcrew.dt_embarked;
      ELSIF vcrew.dt_disembarked = voya.voyage_end_date THEN
         IF vcrew.dt_disembarked between v_dis_fr and v_dis_to then
            v_dt_onboard := ADD_MONTHS(LAST_DAY(v_pay_to)+1,-1);
            v_dt_fr := v_pay_fr;
         else
            if vcrew.dt_disembarked >= v_dis_to then
               v_dt_onboard := ADD_MONTHS(LAST_DAY(v_pay_to)+1,-1);
               v_dt_fr := v_pay_fr;
            else
               v_dt_onboard := NULL;
               v_dt_fr := null;
            end if;
         end if;
      ELSIF (trunc(vcrew.dt_embarked) between v_range_fr and v_range_to) THEN
         v_dt_onboard := vcrew.dt_embarked;
         v_dt_fr := vcrew.dt_embarked;
      ELSE
         v_dt_onboard := ADD_MONTHS(LAST_DAY(v_pay_to)+1,-1);
         v_dt_fr := v_pay_fr;
      END IF;
      if vcrew.empl_empl_id = 'V00004' then
         dbms_output.put_line(vcrew.dt_disembarked ||' - '|| voya.voyage_end_date||' - '||vcrew.tran_no_disembarked);
      end if;
      IF vcrew.dt_disembarked = voya.voyage_end_date THEN
         if vcrew.dt_disembarked between v_dis_fr and v_dis_to then
            v_dt_wentdown := vcrew.dt_disembarked;
            v_dt_to := vcrew.dt_disembarked;
         else
            null;
         end if;
      ELSIF vcrew.dt_disembarked IS NOT NULL THEN
         BEGIN
            FOR wet IN (SELECT 1 FROM PMS_EMPLOYEE_MOVEMENTS WHERE vcrew.tran_no_disembarked = tran_no AND to_vess_code IS NULL)
            LOOP
                v_dt_wentdown := vcrew.dt_disembarked;
                v_dt_to := vcrew.dt_disembarked;
              EXIT;
            END LOOP;
         END;
      END IF;

      --IF voya.vess_code = 'ME.02' THEN
      --   DBMS_OUTPUT.PUT_LINE('vess_code '||voya.vess_code||'; empl_id : '||vcrew.empl_empl_id||'; onboard : '||v_dt_onboard);
      --END IF;
      IF v_empl_cnt = 0 THEN
         if voya.vess_code = 'SK' then
            dbms_output.put_line('Vess :'||voya.vess_code||', voyage_date : '||voya.voyage_date||', voyage_end_date : '||voya.voyage_end_date||'; empl_id : '||vcrew.empl_empl_id||', v_dt_onboard : '|| v_dt_onboard||',  v_dt_wentdown : '||v_dt_wentdown);
         end if;
         Sp_Insert_Crew_List(p_payroll_no, v_period_fr, v_period_to, voya.vess_code, vcrew.empl_empl_id,
                             vcrew.rank_code, v_dt_onboard, v_dt_wentdown, NULL, NULL, TO_DATE(NULL),
                             NULL, NULL, TO_DATE(NULL), NULL, trunc(v_dt_fr), nvl(trunc(v_dt_to),v_tran_to));
      END IF;
    END LOOP;
  END LOOP;
  /* fix more than 2 vess code of an empl_id*/
  begin
     for dup in (
        select empl_id
        from  ( select  distinct empl_id, vess_code from pms_Crew_list where payroll_no = p_payroll_no)
        having count(empl_id) > 1
        group by empl_id)
     loop
        --IF dup.empl_id='S00039' THEN
           DBMS_OUTPUT.PUT_LINE('Empl ID : '||dup.empl_id||' 2 vessels of an empl id');
        --END IF;
        declare
          v_dup_vess varchar2(16);
          v_dup_cnt  number;
        begin
          v_dup_cnt  := 0;
            for upd in (select voya_vess_code, dt_embarked from cms_voyage_crew where empl_empl_id = dup.empl_id order by dt_embarked desc)
            loop
               --delete from pms_crew_list where payroll_no = p_payroll_no and empl_id = dup.empl_id and vess_code <> upd.voya_vess_code;
               begin
                   update pms_Crew_list
                   set    vess_code    = upd.voya_vess_code,
                          fr_vess_code = vess_code,
                          fr_posi_code = title,
                          fr_eff_date  = (upd.dt_embarked - 1),
                          voyage_end_date  = trunc((upd.dt_embarked - 1)),
                          vess_mov = 'Y'
                   where  payroll_no = p_payroll_no
                   and    empl_id = dup.empl_id
                   and    fr_vess_code is null
                   and    fr_posi_code is null
                   and    fr_eff_date  is null
                   and    vess_code <> upd.voya_vess_code;
               end;
               exit;
            end loop;
        end;
     end loop;
  end;
  --SP_POP_CREW_LIST_MOVEMENTS(p_payroll_no);
END Sp_Populate_Crew_List;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POP_AP_DTL" (p_ap_no number) as
   vstatus    varchar2(16);
   ndummy     number;
   nvat       number(16,4);
   nvatphp    number(16,4);
   namtphp    number(16,4);
   ndiscphp   number(16,4);
   namt       number(16,4);
   ndisc      number(16,4);
   nitem      number := 1;
   vap_accnt  varchar2(16):= '60001';
   vmaterial  varchar2(16):= '903';
   vrepair    varchar2(16):= '923';
   vdisc_acct varchar2(16):= '944.1';
   vvat_acct  varchar2(16):= '60005';
   vcurr_code varchar2(16);
   vinvtype   varchar2(16);
begin
  for a in
     (
     select aphd.inv_type, aphd.ap_no, aphd.ap_discount, aphd.ap_disc_amt, aphd.ap_date, aphd.period_to, aphd.vat, aphd.vat_inc,
            sum(greatest((nvl(apin.fx_amount,0) - nvl(apin.cpa_amt,0))*apin.rr_conv,0)) total_amount_net,
            sum(greatest((nvl(apin.fx_amount,0) - nvl(apin.cpa_amt,0)),0)) total_amount_net_fx
     from   acc_ap_hdr aphd, acc_ap_inv_dtl apin
     where  aphd.ap_no = apin.ap_no
     and    aphd.ap_status <> 'CANCELLED'
     and    aphd.ap_no = p_ap_no
     group  by aphd.inv_type, aphd.ap_no, aphd.ap_discount, aphd.ap_disc_amt, aphd.ap_date, aphd.period_to, aphd.vat, aphd.vat_inc
     )
  loop
     for curr in (
        select pohd.currency
        from    acc_ap_inv_dtl apidt, inv_po_hdr pohd
        where   apidt.is_selected= 'Y'
        and     pohd.po_no = apidt.po_no
        and    (apidt.rs_no like 'M%' or apidt.rs_no like 'O%')
        and    apidt.ap_no = a.ap_no
        union all
        select  'PHP'
        from    acc_ap_inv_dtl apidt, inv_jo_hdr johd
        where   apidt.is_selected= 'Y'
        and     johd.jo_no = apidt.po_no
        and    (apidt.rs_no not like 'M%' and apidt.rs_no not like 'O%')
        and    apidt.ap_no = a.ap_no
        union all
        select apidt.invoice_curr
        from   acc_ap_oth_dtl apidt
        where  apidt.is_selected= 'Y'
        and    apidt.ap_no = a.ap_no)
      loop
          vcurr_code := curr.currency;
          exit;
      end loop;
      vcurr_code := nvl(vcurr_code,'PHP');
      if vcurr_code = 'PHP' then
         update acc_ap_dtl
         set    debit_php = debit,
                credit_php = credit
         where  ap_no = p_ap_no;
         commit;
         return;
      end if;
      if a.inv_type = 'PO' then
         vinvtype := 'RR';
      else
         vinvtype := 'JO';
      end if;
      delete from acc_ap_dtl where  ap_no = p_ap_no;
      namtphp  := a.total_amount_net;
      ndiscphp := (a.total_amount_net*(a.ap_discount/100)) + (a.ap_disc_amt*sf_get_fx_rate(vcurr_code, a.ap_date));
      namt     := a.total_amount_net_fx;
      ndisc    := (a.total_amount_net_fx*(a.ap_discount/100)) + a.ap_disc_amt;
      insert into acc_ap_dtl (
         item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
         debit, credit, debit_php, credit_php, created_by, dt_created)
      values  (
         nitem, a.ap_no, decode(a.inv_type,'PO',vmaterial,vrepair), vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
         a.total_amount_net_fx, 0, a.total_amount_net, 0, user, sysdate);
       if a.ap_discount > 0 or a.ap_disc_amt > 0 then
          nitem := nitem + 1;
          insert into acc_ap_dtl
                  (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
                   debit, credit, debit_php, credit_php, created_by, dt_created)
          values (nitem, a.ap_no, vdisc_acct, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
                  0, ndisc, 0, ndiscphp, user, sysdate);
       end if;
       if a.vat_inc = 'Y' or a.vat > 0 then
          if a.vat_inc = 'Y' then
             nvat    := nvl((nvl(a.vat,0)/100) * (a.total_amount_net_fx / sf_get_acc_ewt),0);
             nvatphp := nvl((nvl(a.vat,0)/100) * (a.total_amount_net    / sf_get_acc_ewt),0);
          else
             nvat    := nvl((a.total_amount_net_fx) * (nvl(a.vat,0)/100),0);
             nvatphp := nvl((a.total_amount_net)    * (nvl(a.vat,0)/100),0);
          end if;
          nitem := nitem + 1;
          insert into acc_ap_dtl
                 (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
                  debit, credit, debit_php, credit_php, created_by, dt_created )
          values (nitem, a.ap_no, vvat_acct, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
                  0, nvat, 0, nvatphp, user, sysdate  );
       end if;
       namt    := namt    - (nvl(nvat,0)    + nvl(ndisc,0));
       namtphp := namtphp - (nvl(nvatphp,0) + nvl(ndiscphp,0));
       nitem := nitem + 1;
       insert into acc_ap_dtl
              (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created )
       values (nitem, a.ap_no, vap_accnt, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
               0, namt, 0, namtphp, user, sysdate  );
  end loop;
  commit;
exception
  when others then
    raise_application_error(-20005,'AP#'||p_ap_no||' - '||SQLERRM);
end sp_pop_ap_dtl;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POP_AP_OTH_DTL" (p_ap_no number) as
   vstatus    varchar2(16);
   ndummy     number;
   nvat       number(16,4);
   nvatphp    number(16,4);
   namtphp    number(16,4);
   ndiscphp   number(16,4);
   namt       number(16,4);
   ndisc      number(16,4);
   nitem      number := 1;
   vap_accnt  varchar2(16):= '60001';
   vmaterial  varchar2(16):= '903';
   vrepair    varchar2(16):= '923';
   vdisc_acct varchar2(16):= '944.1';
   vvat_acct  varchar2(16):= '60005';
   vcurr_code varchar2(16);
   vinvtype   varchar2(16);
begin
  for a in
     (
     select aphd.inv_type, aphd.ap_no, aphd.ap_discount, aphd.ap_disc_amt, aphd.ap_date, aphd.period_to, aphd.vat, aphd.vat_inc,
            sum(greatest((nvl(apin.amount,0)),0)) total_amount_net,
            sum(greatest((nvl(apin.invoice_amount,0)),0)) total_amount_net_fx
     from   acc_ap_hdr aphd, acc_ap_oth_dtl apin
     where  aphd.ap_no = apin.ap_no
     and    aphd.ap_status <> 'CANCELLED'
     and    aphd.ap_no = p_ap_no
     group  by aphd.inv_type, aphd.ap_no, aphd.ap_discount, aphd.ap_disc_amt, aphd.ap_date, aphd.period_to, aphd.vat, aphd.vat_inc
     )
  loop
     for curr in (
        select apidt.invoice_curr
        from   acc_ap_oth_dtl apidt
        where  apidt.is_selected= 'Y'
        and    apidt.ap_no = a.ap_no)
      loop
          vcurr_code := curr.invoice_curr;
          exit;
      end loop;
      vcurr_code := nvl(vcurr_code,'PHP');
      if vcurr_code = 'PHP' then
         update acc_ap_dtl
         set    debit_php = debit,
                credit_php = credit
         where  ap_no = p_ap_no;
         commit;
         return;
      end if;
      vinvtype := 'OTHERS';
      delete from acc_ap_dtl where  ap_no = p_ap_no;
      namtphp  := a.total_amount_net;
      ndiscphp := (a.total_amount_net*(a.ap_discount/100)) + (a.ap_disc_amt*sf_get_fx_rate(vcurr_code, a.ap_date));
      namt     := a.total_amount_net_fx;
      ndisc    := (a.total_amount_net_fx*(a.ap_discount/100)) + a.ap_disc_amt;
      insert into acc_ap_dtl (
         item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
         debit, credit, debit_php, credit_php, created_by, dt_created)
      values  (
         nitem, a.ap_no, vmaterial, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
         a.total_amount_net_fx, 0, a.total_amount_net, 0, user, sysdate);
       if a.ap_discount > 0 or a.ap_disc_amt > 0 then
          nitem := nitem + 1;
          insert into acc_ap_dtl
                  (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
                   debit, credit, debit_php, credit_php, created_by, dt_created)
          values (nitem, a.ap_no, vdisc_acct, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
                  0, ndisc, 0, ndiscphp, user, sysdate);
       end if;
       if a.vat_inc = 'Y' or a.vat > 0 then
          if a.vat_inc = 'Y' then
             nvat    := nvl((nvl(a.vat,0)/100) * (a.total_amount_net_fx / sf_get_acc_ewt),0);
             nvatphp := nvl((nvl(a.vat,0)/100) * (a.total_amount_net    / sf_get_acc_ewt),0);
          else
             nvat    := nvl((a.total_amount_net_fx) * (nvl(a.vat,0)/100),0);
             nvatphp := nvl((a.total_amount_net)    * (nvl(a.vat,0)/100),0);
          end if;
          nitem := nitem + 1;
          insert into acc_ap_dtl
                 (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
                  debit, credit, debit_php, credit_php, created_by, dt_created )
          values (nitem, a.ap_no, vvat_acct, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
                  0, nvat, 0, nvatphp, user, sysdate  );
       end if;
       namt    := namt    - (nvl(nvat,0)    + nvl(ndisc,0));
       namtphp := namtphp - (nvl(nvatphp,0) + nvl(ndiscphp,0));
       nitem := nitem + 1;
       insert into acc_ap_dtl
              (item_no, ap_no, acco_code, ref_type, ref_code, ref_desc,
               debit, credit, debit_php, credit_php, created_by, dt_created )
       values (nitem, a.ap_no, vap_accnt, vinvtype, vinvtype ||'#' || to_char(a.period_to, 'MMYYYY'), vinvtype,
               0, namt, 0, namtphp, user, sysdate  );
  end loop;
  commit;
exception
  when others then
    raise_application_error(-20005,'AP#'||p_ap_no||' - '||SQLERRM);
end sp_pop_ap_oth_dtl;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POP_CREW_LIST_MOVEMENTS" (p_payroll_no VARCHAR2) AS
  v_mid_s_date VARCHAR2(3) := '26';
  v_mid_e_date VARCHAR2(3) := '10';
  v_end_s_date VARCHAR2(3) := '11';
  v_end_e_date VARCHAR2(3) := '25';
  v_period_fr DATE;
  v_period_to DATE;
  v_pay_fr DATE;
  v_pay_to DATE;
  v_dis_fr DATE;
  v_dis_to DATE;
  v_tran_fr DATE;
  v_tran_to DATE;
  v_tran_fr_temp DATE;
  v_tran_to_temp DATE;
  v_empl_cnt NUMBER;
  v_distinct_empl_cnt NUMBER;
  v_distinct_empl VARCHAR2(16);
  v_dt_onboard DATE;
  v_dt_wentdown DATE;
  v_close_tag CHAR(1);
BEGIN
  v_close_tag := 'N';
  v_distinct_empl_cnt := 0;
  BEGIN
   SELECT period_fr, period_to, closed_tag
   INTO   v_period_fr, v_period_to, v_close_tag
   FROM   PYS_PAYROLL_HDR
   WHERE  payroll_no = p_payroll_no;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
    RAISE_APPLICATION_ERROR(-2001,'Invalid Payroll No : '||p_payroll_no);
  END;
  IF NVL(v_close_tag,'N') = 'Y' THEN
     DBMS_OUTPUT.PUT_LINE('Payroll Already Closed');
     RETURN;
     -- must not print closed tag
  END IF;
  DELETE FROM PMS_CREW_LIST_MOV WHERE payroll_no = p_payroll_no;
  IF LAST_DAY(TRUNC(v_period_to)) = TRUNC(v_period_to) THEN
    v_pay_fr := TO_DATE(TO_CHAR(v_period_fr,'MM')||v_end_s_date||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_pay_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||v_end_e_date||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_dis_fr := TO_DATE(TO_CHAR(v_period_fr,'MM')||'01'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_dis_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||'26'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
  ELSE
    v_pay_fr := TO_DATE(TO_CHAR(ADD_MONTHS(v_period_fr,-1),'MM')||v_mid_s_date||TO_CHAR(ADD_MONTHS(v_period_fr,-1),'RRRR'),'MMDDRRRR');
    v_pay_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||v_mid_e_date||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
    v_dis_fr := TO_DATE(TO_CHAR(ADD_MONTHS(v_period_fr,-1),'MM')||'26'||TO_CHAR(ADD_MONTHS(v_period_fr,-1),'RRRR'),'MMDDRRRR');
    v_dis_to := TO_DATE(TO_CHAR(v_period_fr,'MM')||'11'||TO_CHAR(v_period_fr,'RRRR'),'MMDDRRRR');
  END IF;
  v_tran_fr := v_dis_fr;
  v_tran_to := v_dis_to;
  /*
  IF v_period_to=LAST_DAY(v_period_to) THEN
     v_tran_fr := ADD_MONTHS(TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD'),-1);
     v_tran_to := TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD');
  ELSE
     v_tran_fr := TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD');
     v_tran_to := ADD_MONTHS(TO_DATE(TO_CHAR(v_pay_fr,'MMYYYY')||'26','MMYYYYDD'),1);
  END IF;
  */
  DBMS_OUTPUT.PUT_LINE('v_period_fr : '||v_period_fr);
  DBMS_OUTPUT.PUT_LINE('v_period_to : '||v_period_to);
  DBMS_OUTPUT.PUT_LINE('v_pay_fr    : '||v_pay_fr   );
  DBMS_OUTPUT.PUT_LINE('v_pay_to    : '||v_pay_to   );
  DBMS_OUTPUT.PUT_LINE('v_tran_fr   : '||v_tran_fr  );
  DBMS_OUTPUT.PUT_LINE('v_tran_to   : '||v_tran_to  );
  DBMS_OUTPUT.PUT_LINE('v_dis_fr   : '||v_dis_fr  );
  DBMS_OUTPUT.PUT_LINE('v_dis_to   : '||v_dis_to  );
  -- voyage
  FOR voya IN
    (
    SELECT vess_code, empl_id, on_board, nvl(wentdown,sf_get_next_onboard(pcl.payroll_no, pcl.empl_id, pcl.on_board)) wentdown, title, voyage_st_date, voyage_end_date
    FROM   pms_crew_list pcl
    WHERE  1 = 1
    AND    payroll_no = p_payroll_no
    ORDER BY 1,2,3,4
    )
  LOOP
    FOR ce IN (
            --pass embarked
            SELECT DECODE(emmx.to_vess_code,NULL,NULL,'Pass') to_posi_code, emmx.to_vess_code, (DECODE(emmx.to_vess_code,NULL,TO_DATE(NULL),emmo.eff_st_date)) TO_eff_DATE,
                   DECODE(emmx.fr_vess_code,NULL,NULL,'Pass') fr_posi_code, emmx.fr_vess_code, (DECODE(emmx.fr_vess_code,NULL,TO_DATE(NULL),TRUNC(emmo.eff_st_date-1))) fr_eff_date,
                   emmo.tran_no, TO_DATE(NULL) wentdown, 'PE' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS_PAX emmx, PMS_EMPLOYEE_MOVEMENTS emmo, CMS_VOYAGE_PAX cpax
            WHERE emmx.tran_no = emmo.tran_no
            AND   voya.empl_id = cpax.empl_empl_id
            AND   emmo.empl_empl_id = cpax.empl_empl_id
            and   cpax.tran_no_embarked = emmo.tran_no
            and   emmo.py_status = 'POSTED'
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --pass embarked not yet disembarked
            SELECT DECODE(emmx.to_vess_code,NULL,NULL,'Pass') to_posi_code, emmx.to_vess_code, (DECODE(emmx.to_vess_code,NULL,TO_DATE(NULL),emmo.eff_st_date)) TO_eff_DATE,
                   DECODE(emmx.fr_vess_code,NULL,NULL,'Pass') fr_posi_code, emmx.fr_vess_code, (DECODE(emmx.fr_vess_code,NULL,TO_DATE(NULL),TRUNC(emmo.eff_st_date-1))) fr_eff_date,
                   emmo.tran_no, TO_DATE(NULL) wentdown, 'PE' stat, 'Y' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS_PAX emmx, PMS_EMPLOYEE_MOVEMENTS emmo, CMS_VOYAGE_PAX cpax
            WHERE emmx.tran_no = emmo.tran_no
            AND   voya.empl_id = cpax.empl_empl_id
            AND   emmo.empl_empl_id = cpax.empl_empl_id
            and   cpax.tran_no_embarked = emmo.tran_no
            and   emmo.py_status = 'POSTED'
            AND   cpax.dt_disembarked is null
            and   trunc(emmo.eff_st_date) < voya.voyage_st_date
            --and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --pass disembarked
            SELECT voya.title, voya.vess_code, emmo.eff_st_date,
                   'Pass', emmx.fr_vess_code, (emmo.eff_st_date-1),
                   emmo.tran_no, TO_DATE(NULL), 'PD' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS_PAX emmx, PMS_EMPLOYEE_MOVEMENTS emmo, CMS_VOYAGE_PAX cpax
            WHERE emmx.tran_no = emmo.tran_no
            AND   voya.empl_id = cpax.empl_empl_id
            AND   emmo.empl_empl_id = cpax.empl_empl_id
            AND   emmx.to_vess_code IS NULL
            and   emmo.py_status = 'POSTED'
            AND   cpax.tran_no_disembarked = emmo.tran_no
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --crew embarked
            SELECT to_posi_code, to_vess_code, eff_st_date to_eff_date,
                   fr_posi_code, fr_vess_code, (DECODE(fr_vess_code,NULL,TO_DATE(NULL),(eff_st_date)-1)) fr_eff_date,
                   tran_no, TO_DATE(NULL) wentdown,'CE' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS emmo
            WHERE py_status = 'POSTED'
            and   empl_empl_id = voya.empl_id
            AND   to_vess_code is not null
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --crew disembarked
            SELECT NULL, NULL, NULL,
                   fr_posi_code, fr_vess_code, eff_st_date,
                   tran_no, eff_st_date, 'CD' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS emmo
            WHERE to_vess_code IS NULL
            and   fr_vess_code IS NOT NULL
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            and   empl_empl_id = voya.empl_id
            and   py_status = 'POSTED'
            AND   fr_vess_code is not null)
          LOOP
            v_empl_cnt := v_empl_cnt + 1;
            IF voya.empl_id='P00018' THEN
               DBMS_OUTPUT.PUT_LINE('Empl ID : '||voya.empl_id||' wentdown '||voya.wentdown||';  Stat : '||ce.stat||'; tran no : '||ce.tran_no||'; pass details : '||ce.get_pass_detail||' - '||ce.fr_posi_code||' - '||ce.to_posi_code||' - '||ce.wentdown);
            END IF;
            IF ce.get_pass_detail = 'Y' then
               for ceb in (
                  select DECODE(emmx.to_vess_code,NULL,NULL,'Pass') to_posi_code, emmx.to_vess_code, (DECODE(emmx.to_vess_code,NULL,TO_DATE(NULL),emmo.eff_st_date)) TO_eff_DATE,
                         DECODE(emmx.fr_vess_code,NULL,NULL,'Pass') fr_posi_code, emmx.fr_vess_code, (DECODE(emmx.fr_vess_code,NULL,TO_DATE(NULL),TRUNC(emmo.eff_st_date-1))) fr_eff_date,
                         emmo.tran_no, TO_DATE(NULL) wentdown, 'PE' stat, 'Y' get_pass_detail
                  from   PMS_EMPLOYEE_MOVEMENTS emmo, PMS_EMPLOYEE_MOVEMENTS_PAX emmx
                  where  emmo.tran_no = emmx.tran_no
                  and    emmo.py_status = 'POSTED'
                  and    emmo.empl_empl_id = voya.empl_id
                  and    ce.tran_no > emmo.tran_no
                  order by emmo.eff_st_date desc)
                loop
                   if ceb.to_vess_code is null then
                      exit;
                   end if;
                   Sp_Insert_Crew_List_mov(p_payroll_no, v_period_fr, v_period_to, voya.vess_code, voya.empl_id,
                                       voya.title, v_dt_onboard, ceb.wentdown, ceb.fr_posi_code, ceb.fr_vess_code, ceb.fr_eff_date,
                                       ceb.to_posi_code, ceb.to_vess_code, ceb.to_eff_date, ceb.tran_no, ceb.stat, voya.voyage_st_date, voya.voyage_end_date);
                end loop;
            end if;
            if (ce.to_vess_code = voya.vess_code) and (voya.wentdown is not null) then
                Sp_Insert_Crew_List_mov(p_payroll_no, v_period_fr, v_period_to, voya.vess_code, voya.empl_id,
                                    voya.title, voya.on_board, voya.wentdown, ce.fr_posi_code, ce.fr_vess_code, ce.fr_eff_date,
                                    ce.to_posi_code, ce.to_vess_code, ce.to_eff_date, ce.tran_no, ce.stat, voya.voyage_st_date, voya.voyage_end_date);
            else
                Sp_Insert_Crew_List_mov(p_payroll_no, v_period_fr, v_period_to, voya.vess_code, voya.empl_id,
                                    voya.title, voya.on_board, ce.wentdown, ce.fr_posi_code, ce.fr_vess_code, ce.fr_eff_date,
                                    ce.to_posi_code, ce.to_vess_code, ce.to_eff_date, ce.tran_no, ce.stat, voya.voyage_st_date, voya.voyage_end_date);
            end if;
          END LOOP;
    END LOOP;
END Sp_Pop_crew_list_movements;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POP_INV_ADV_PAYMENT" (p_ap_no varchar2, p_inv_type varchar2, p_po_no varchar2) IS
  v_adv      acc_ap_inv_dtl.cpa_amt%type;
  v_used_adv acc_ap_inv_dtl.cpa_amt%type;
  v_used_adv_php acc_ap_inv_dtl.cpa_amt%type;
begin
  v_adv := 0;
  v_used_adv_php := 0;
  v_used_adv := 0;
  -- delete old advances
  delete from acc_ap_advances
  where  ap_no    = p_ap_no
  and    po_no    = p_po_no
  and    inv_type = p_inv_type;
  if p_inv_type = 'PO' then
      -- JV
      FOR a IN (
        SELECT sum(debit) as "DEBIT", sum(debit_php) as "DEBIT_PHP", JVHD.JV_NO
        FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
        WHERE  JVHD.JV_NO = JVDT.JV_NO
        AND    JVHD.JV_STATUS = 'APPROVED'
        AND    JVDT.REF_TYPE = 'PO'
        AND    JVDT.REF_CODE = P_PO_NO
        GROUP  BY JVHD.JV_NO)
      LOOP
        -- get used JV advances on other AP
        FOR b IN (
          SELECT nvl(ADV_AMOUNT,0) adv_amount, nvl(ADV_AMOUNT_php,0) adv_amount_php FROM acc_ap_advances
          WHERE  ap_no <> p_ap_no
          and    ref_type = 'JV'
          and    ref_code = a.jv_no
          and    po_no    = p_po_no
          and    inv_type = 'PO')
        LOOP
          v_used_adv     := b.adv_amount     + nvl(v_used_adv,0);
          v_used_adv_php := b.adv_amount_php + nvl(v_used_adv_php,0);
        END LOOP;
        dbms_output.put_line('(a.debit_php - v_used_adv_php)'||(a.debit_php - v_used_adv_php));
        BEGIN
          insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
          values (p_ap_no, 'JV', a.jv_no, 'PO', p_po_no, a.debit - v_used_adv, user, sysdate, (a.debit_php - nvl(v_used_adv_php,0)));
        exception
          when others then
            raise_application_error(-20001, 'Error updating Advances from JV to PO '||p_po_no||' - '||SQLCODE||' - '||SQLERRM);
        END;
        v_used_adv := 0;
        v_used_adv_php := 0;
      END LOOP;
      -- PCV
      v_used_adv := 0;
      v_used_adv_php := 0;
      FOR a IN (
        SELECT nvl(SUM(nvl(AMOUNT,0)),0) DEBIT, PCHD.PCV_NO
        FROM   ACC_PCV_INV_DTL PCDT, ACC_PCV_HDR PCHD, ACC_PCV_DTL PCDTT
        WHERE  PCHD.PCV_NO = PCDT.PCV_NO
        AND    PCHD.PCV_NO = PCDTT.PCV_NO
        AND    PCHD.PCV_STATUS = 'REPLENISHED'
        AND    PCDT.PO_NO = 'PO'||P_PO_NO
        AND    PCDTT.ACCO_CODE = '40004'
        GROUP BY PCHD.PCV_NO)
      LOOP
        -- get used PCV advances on other AP
        FOR b IN (
          SELECT nvl(ADV_AMOUNT,0) adv_amount FROM acc_ap_advances
          WHERE  ap_no <> p_ap_no
          and    ref_type = 'PCV'
          and    ref_code = a.pcv_no
          and    po_no    = p_po_no
          and    inv_type = 'PO')
        LOOP
          v_used_adv := b.adv_amount + nvl(v_used_adv,0);
        END LOOP;
        BEGIN
          insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
          values (p_ap_no, 'PCV', a.pcv_no, 'PO', p_po_no, a.debit - v_used_adv, user, sysdate, (a.debit - v_used_adv));
        exception
          when others then
            raise_application_error(-20001, 'Error updating Advances from PCV to PO '||p_po_no||' - '||SQLCODE||' - '||SQLERRM);
        END;
        v_used_adv := 0;
        v_used_adv_php := 0;
      END LOOP;
      --CPA
      v_used_adv := 0;
      v_used_adv_php := 0;
      FOR a IN (
        SELECT nvl(SUM(nvl(CPDT.AMOUNT,0)),0) as "DEBIT", JVHD.CV_NO
        FROM   ACC_CV_CPA_DTL JVDT, ACC_CV_HDR JVHD, ACC_CPA_DTL CPDT
        WHERE  JVHD.CV_NO = JVDT.CV_NO
        AND    JVHD.CV_STATUS = 'APPROVED'
        AND    CPDT.REF_TYPE = 'PO'
        AND    CPDT.CPA_NO = JVDT.CPA_NO
        AND    CPDT.REF_CODE = P_PO_NO
        GROUP BY JVHD.CV_NO)
      LOOP
        -- get used CPA advances on other AP
        FOR b IN (
          SELECT nvl(ADV_AMOUNT,0) adv_amount FROM acc_ap_advances
          WHERE  ap_no <> p_ap_no
          and    ref_type = 'CV'
          and    ref_code = a.cv_no
          and    po_no    = p_po_no
          and    inv_type = 'PO')
        LOOP
          v_used_adv := b.adv_amount + nvl(v_used_adv,0);
        END LOOP;
        BEGIN
          insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
          values (p_ap_no, 'CV', a.cv_no, 'PO', p_po_no, a.debit - v_used_adv, user, sysdate, a.debit - v_used_adv);
        exception
          when others then
            raise_application_error(-20001, 'Error updating Advances from CV to PO '||p_po_no||' - '||SQLCODE||' - '||SQLERRM);
        END;
        v_used_adv := 0;
        v_used_adv_php := 0;
      END LOOP;
  end if;
  if p_inv_type = 'JO' then
      -- JV
      FOR a IN (
        SELECT sum(jvdt.debit) as "DEBIT", sum(jvdt.debit_php) as "DEBIT_PHP", JVHD.JV_NO
        FROM   ACC_JV_DTL JVDT, ACC_JV_HDR JVHD
        WHERE  JVHD.JV_NO = JVDT.JV_NO
        AND    JVHD.JV_STATUS = 'APPROVED'
        AND    JVDT.REF_TYPE = 'JO'
        AND    JVDT.REF_CODE = P_PO_NO
        GROUP  BY JVHD.JV_NO)
      LOOP
        -- get used JV advances on other AP
        FOR b IN (
          SELECT nvl(ADV_AMOUNT,0) adv_amount, nvl(adv_amount_php,0) adv_amount_php
          FROM    acc_ap_advances
          WHERE  ap_no <> p_ap_no
          and    ref_type = 'JV'
          and    ref_code = a.jv_no
          and    po_no    = p_po_no
          and    inv_type = 'JO')
        LOOP
          v_used_adv     := b.adv_amount     + nvl(v_used_adv,0);
          v_used_adv_php := b.adv_amount_php + nvl(v_used_adv_php,0);
        END LOOP;
        BEGIN
          insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
          values (p_ap_no, 'JV', a.jv_no, 'JO', p_po_no, (a.debit - v_used_adv), user, sysdate, (a.debit_php - v_used_adv_php));
        exception
          when others then
            raise_application_error(-20001, 'Error updating Advances from JV to JO '||p_po_no||' - '||SQLCODE||' - '||SQLERRM);
        END;
        v_used_adv := 0;
        v_used_adv_php := 0;

      END LOOP;
      -- PCV
      v_used_adv := 0;
      v_used_adv_php := 0;
      FOR a IN (
        SELECT nvl(SUM(nvl(AMOUNT,0)),0) DEBIT, PCHD.PCV_NO
        FROM   ACC_PCV_INV_DTL PCDT, ACC_PCV_HDR PCHD, ACC_PCV_DTL PCDTT
        WHERE  PCHD.PCV_NO = PCDT.PCV_NO
        AND    PCHD.PCV_NO = PCDTT.PCV_NO
        AND    PCDTT.ACCO_CODE = '40004'
        AND    PCHD.PCV_STATUS = 'REPLENISHED'
        AND    PCDT.PO_NO = 'JO'||P_PO_NO
        GROUP BY PCHD.PCV_NO)
      LOOP
        -- get used PCV advances on other AP
        FOR b IN (
          SELECT nvl(ADV_AMOUNT,0) adv_amount FROM acc_ap_advances
          WHERE  ap_no <> p_ap_no
          and    ref_type = 'PCV'
          and    ref_code = a.pcv_no
          and    po_no    = p_po_no
          and    inv_type = 'JO')
        LOOP
          v_used_adv := b.adv_amount + nvl(v_used_adv,0);
        END LOOP;
        BEGIN
          insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
          values (p_ap_no, 'PCV', a.pcv_no, 'JO', p_po_no, a.debit - v_used_adv, user, sysdate, a.debit - v_used_adv);
        exception
          when others then
            raise_application_error(-20001, 'Error updating Advances from PCV to JO '||p_po_no||' - '||SQLCODE||' - '||SQLERRM);
        END;
        v_used_adv := 0;
        v_used_adv_php := 0;
      END LOOP;
      --CPA
      v_used_adv := 0;
      v_used_adv_php := 0;
      FOR a IN (
        SELECT nvl(SUM(nvl(CPDT.AMOUNT,0)),0) DEBIT, JVHD.CV_NO
        FROM   ACC_CV_CPA_DTL JVDT, ACC_CV_HDR JVHD, ACC_CPA_DTL CPDT
        WHERE  JVHD.CV_NO = JVDT.CV_NO
        AND    JVHD.CV_STATUS = 'APPROVED'
        AND    CPDT.REF_TYPE = 'JO'
        AND    CPDT.CPA_NO = JVDT.CPA_NO
        AND    CPDT.REF_CODE = P_PO_NO
        GROUP BY JVHD.CV_NO)
      LOOP
        -- get used CPA advances on other AP
        FOR b IN (
          SELECT nvl(ADV_AMOUNT,0) adv_amount FROM acc_ap_advances
          WHERE  ap_no <> p_ap_no
          and    ref_type = 'CV'
          and    ref_code = a.cv_no
          and    po_no    = p_po_no
          and    inv_type = 'JO')
        LOOP
          v_used_adv := b.adv_amount + nvl(v_used_adv,0);
        END LOOP;
        BEGIN
          insert into acc_ap_advances(ap_no, ref_type, ref_code, inv_type, po_no,  adv_amount, created_by, dt_created, adv_amount_php)
          values (p_ap_no, 'CV', a.cv_no, 'JO', p_po_no, a.debit - v_used_adv, user, sysdate, a.debit - v_used_adv);
        exception
          when others then
            raise_application_error(-20001, 'Error updating Advances from CV to JO '||p_po_no||' - '||SQLCODE||' - '||SQLERRM);
        END;
        v_used_adv := 0;
        v_used_adv_php := 0;
      END LOOP;
  end if;
end;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POST_BEGBAL" as
   vNewTableName Varchar2(30);
   vOpMsg        Varchar2(4000);
   vStr          Varchar2(4000);
   nCnt          Number;
begin
   insert into inv_item_ware_begbal_log (username, dt_created, begbal_action)
   values (user, sysdate, 'POST');

   for h in (select WARE_CODE, DR_NO, ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE,
                    QTY, QTY_AVAIL, QTY_ALLOC, UNIT_COST, CURRENCY, DISCOUNT, BIN_NO,
                    CREATED_BY, DT_CREATED, MODIFIED_BY, DT_MODIFIED
             from   inv_item_ware_begbal
             where  posted_dt is null)
   loop
      begin
         insert into inv_item_ware
               (WARE_CODE, DR_NO, ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE,
                QTY, QTY_AVAIL, QTY_ALLOC, UNIT_COST, CURRENCY, DISCOUNT, BIN_NO,
                CREATED_BY, DT_CREATED, MODIFIED_BY, DT_MODIFIED )
         values(h.WARE_CODE, h.DR_NO, h.ITTY_CODE, h.ITGR_CODE, h.CATE_CODE, h.ITEM_CODE, h.UOME_CODE,
                h.QTY, h.QTY, h.QTY_AVAIL, h.QTY_ALLOC, h.CURRENCY, 0, h.BIN_NO,
                h.CREATED_BY, h.DT_CREATED, h.MODIFIED_BY, h.DT_MODIFIED );
      exception
         when dup_val_on_index then
            update inv_item_ware
            set    qty       = h.qty,
                   qty_alloc = h.qty_alloc,
                   qty_avail = h.qty_avail,
                   bin_no    = h.bin_no,
                   unit_cost = 0,
                   currency  = null,
                   discount  = 0
            where  ware_code = h.ware_code
            and    itty_code = h.itty_code
            and    itgr_code = h.itgr_code
            and    cate_code = h.cate_code
            and    item_code = h.item_code
            and    uome_code = h.uome_code;
      end;
   end loop;

   -- Inventory Items
   for i in (select ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, sum(qty) qty
             from   inv_item_ware_begbal
             where  posted_dt is null
             group  by ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE)
   loop
      update inv_items
      set    beg_bal_qty = i.qty,
             tot_qty     = i.qty,
             bal_qty     = i.qty,
             beg_bal_uc  = 0
      where  itty_code = i.itty_code
      and    itgr_code = i.itgr_code
      and    cate_code = i.cate_code
      and    code      = i.item_code;
   end loop;

   -- Inventory Items per UOME
   for k in (select ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE, sum(qty) qty
             from   inv_item_ware_begbal
             where  posted_dt is null
             group  by ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE)
   loop
      update inv_items_log
      set    beg_bal_qty = k.qty,
             tot_qty     = k.qty,
             bal_qty     = k.qty,
             beg_bal_uc  = 0,
             tmp_tot_qty = 0,
             tmp_bal_qty = 0,
             tmp_beg_qty = 0
      where  itty_code = k.itty_code
      and    itgr_code = k.itgr_code
      and    cate_code = k.cate_code
      and    code      = k.item_code
      and    uome_code = k.uome_code;
   end loop;

   update inv_item_ware_begbal
   set    posted_dt = sysdate
   where  posted_dt is null;

   commit;
end sp_post_begbal;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_POST_BEGBAL_BKUP" as
   vNewTableName Varchar2(30);
   vOpMsg        Varchar2(4000);
   vStr          Varchar2(4000);
   nCnt          Number;
begin
   insert into inv_item_ware_begbal_log (username, dt_created, begbal_action)
   values (user, sysdate, 'POST');

   for h in (select WARE_CODE, DR_NO, ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE,
                    QTY, QTY_AVAIL, QTY_ALLOC, UNIT_COST, CURRENCY, DISCOUNT, BIN_NO,
                    CREATED_BY, DT_CREATED, MODIFIED_BY, DT_MODIFIED
             from   inv_item_ware_begbal
             where  posted_dt is null)
   loop
      begin
         insert into inv_item_ware
               (WARE_CODE, DR_NO, ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE,
                QTY, QTY_AVAIL, QTY_ALLOC, UNIT_COST, CURRENCY, DISCOUNT, BIN_NO,
                CREATED_BY, DT_CREATED, MODIFIED_BY, DT_MODIFIED )
         values(h.WARE_CODE, h.DR_NO, h.ITTY_CODE, h.ITGR_CODE, h.CATE_CODE, h.ITEM_CODE, h.UOME_CODE,
                h.QTY, h.QTY, 0, 0, h.CURRENCY, 0, h.BIN_NO,
                h.CREATED_BY, h.DT_CREATED, h.MODIFIED_BY, h.DT_MODIFIED );
      exception
         when dup_val_on_index then
            update inv_item_ware
            set    qty       = h.qty,
                   qty_avail = h.qty,
                   bin_no    = h.bin_no,
                   unit_cost = 0,
                   currency  = null,
                   discount  = 0
            where  ware_code = h.ware_code
            and    itty_code = h.itty_code
            and    itgr_code = h.itgr_code
            and    cate_code = h.cate_code
            and    item_code = h.item_code
            and    uome_code = h.uome_code;
      end;
   end loop;

   -- Inventory Items
   for i in (select ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, sum(qty) qty
             from   inv_item_ware_begbal
             where  posted_dt is null
             group  by ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE)
   loop
      update inv_items
      set    beg_bal_qty = i.qty,
             tot_qty     = i.qty,
             bal_qty     = i.qty,
             beg_bal_uc  = 0
      where  itty_code = i.itty_code
      and    itgr_code = i.itgr_code
      and    cate_code = i.cate_code
      and    code      = i.item_code;
   end loop;

   -- Inventory Items per UOME
   for k in (select ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE, sum(qty) qty
             from   inv_item_ware_begbal
             where  posted_dt is null
             group  by ITTY_CODE, ITGR_CODE, CATE_CODE, ITEM_CODE, UOME_CODE)
   loop
      update inv_items_log
      set    beg_bal_qty = k.qty,
             tot_qty     = k.qty,
             bal_qty     = k.qty,
             beg_bal_uc  = 0,
             tmp_tot_qty = 0,
             tmp_bal_qty = 0,
             tmp_beg_qty = 0
      where  itty_code = k.itty_code
      and    itgr_code = k.itgr_code
      and    cate_code = k.cate_code
      and    code      = k.item_code
      and    uome_code = k.uome_code;
   end loop;

   update inv_item_ware_begbal
   set    posted_dt = sysdate
   where  posted_dt is null;

   commit;
end sp_post_begbal_bkup;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_TIME_IO" (p_batch in number) as
   nTime Number(12,4);
   dStaTm  Date;
   dEndTm  Date;
   dActIn  Date;
   dActOut Date;
   vRemarks Varchar2(255);
begin
   for i in ( select b.empl_id, a.tx_date, min(a.tx_time) time_in, max(a.tx_time) time_out
              from   time_in_time_out_log a, pms_employees b
              where  a.card_no = b.biometrics_card_no
              and    a.batch_no = p_batch
              group  by b.empl_id, a.tx_date )
   loop
      vRemarks := NULL;
      nTime   := NULL;
      dStaTm  := NULL;
      dEndTm  := NULL;
      dActIn  := NULL;
      dActOut := NULL;
      begin
         dStaTm := to_date(to_char(i.time_in,'YYYYMMDD') || '0800', 'YYYYMMDDHH24MI');
         dEndTm := to_date(to_char(i.time_in,'YYYYMMDD') || '1700', 'YYYYMMDDHH24MI');
         if dStaTm > i.time_in then
            dActIn := dStaTm;
         else
            dActIn := i.time_in;
         end if;
         if i.time_in > dEndTm then
            dActOut := dEndTm;
         else
            dActOut := i.time_out;
         end if;

         nTime := ((dActOut-dActIn) * 24)-1;

         --  for late
         if i.time_in > (dStaTm - (5/60/24)) then
            nTime := nTime - 1;
            vRemarks := 'LATE';
         end if;

         if nTime > 8 then
            nTime := 8;
         else
            nTime := greatest(nTime,0);
         end if;
         insert into pms_attendance_records
                ( empl_empl_id, att_date, am_time_in, pm_time_out, num_hours, ot_hours, dt_created, created_by, nd_hours, outer_port, batch_no, remarks )
         values ( i.empl_id, i.tx_date, i.time_in, i.time_out, nTime, 0, sysdate, user, 0, 'N', p_batch, vRemarks );
      exception
         when others then raise_application_error (-20001, 'Employee ID - ' || i.empl_id || ' : ' || SQLERRM);
      end;
   end loop;
   commit;
end;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_ISS" as
   bInserted Boolean;
   err_msg   varchar2(200);
begin
   -- Create Issuance Header
   for a in (select a.iss_no, to_date(a.iss_date,'YYYY/MM/DD') iss_date, nvl(d.borrowed_by, e.vess_code) vess_code,
                    decode(a.item_type, 'PO', 'MAINTENANCE', a.item_type) iss_type,
                    nvl(d.borrowed_rs, b.rshd_rs_no) rshd_rs_no, sf_get_empl_code(e.requested_by) received_by, sysdate dt_received,
                    sf_get_empl_code(a.issued_by) issued_by, sf_get_empl_code(a.issued_to) issued_to, sf_get_empl_code(a.prepared_by) prepared_by,
                    sysdate dt_prepared, user created_by, sysdate dt_created, 'HO' ofc_code
             from   wms_po_iss a, inv_po_hdr b, inv_dr_hdr c, inv_dr_dtl d, inv_reqslip_hdr e
             where  a.po_no = b.po_no
             and    b.po_no = c.pohd_po_no
             and    e.rs_no = a.rs_no
             and    c.dr_no = d.drhd_dr_no
             and    d.item_code = a.item_code
             and    a.process_flag = 'N'
             and    a.po_no is not null
             and    a.po_no <> '""'
             group by a.iss_no, to_date(a.iss_date,'YYYY/MM/DD'), nvl(d.borrowed_by, e.vess_code), a.item_type, nvl(d.borrowed_rs, b.rshd_rs_no), sf_get_empl_code(e.requested_by),
                      sf_get_empl_code(a.issued_by), sf_get_empl_code(a.issued_to), sf_get_empl_code(a.prepared_by)
            )
   loop
      err_msg := NULL;
      begin
         insert into inv_iss_hdr
                (iss_no, iss_date, status, vess_code, iss_type, rshd_rs_no, received_by, dt_received,
                 issued_by, issued_to, prepared_by, dt_prepared, created_by, dt_created, ofc_code, apof_code, approving_officer )
         values (a.iss_no, a.iss_date, 'APPROVED', a.vess_code, a.iss_type, a.rshd_rs_no, a.received_by, a.dt_received,
                 a.issued_by, a.issued_to, a.prepared_by, a.dt_prepared, a.created_by, a.dt_created, a.ofc_code, 'L00011', 'L00011');
      exception
         when dup_val_on_index then null;
         when others then
            err_msg := SUBSTR(SQLERRM, 1, 200);
            update wms_po_iss
            set    err_desc = 'H:' || err_msg
            where  iss_no = a.iss_no;
      end;
   end loop;

   for b in (select a.iss_no, to_date(a.iss_date,'YYYY/MM/DD') iss_date, e.vess_code,
                    decode(a.item_type, 'PO', 'MAINTENANCE', a.item_type) iss_type,
                    a.rs_no rshd_rs_no, sf_get_empl_code(e.requested_by) received_by, sysdate dt_received,
                    sf_get_empl_code(a.issued_by) issued_by, sf_get_empl_code(a.issued_to) issued_to, sf_get_empl_code(a.prepared_by) prepared_by,
                    sysdate dt_prepared, user created_by, sysdate dt_created, 'HO' ofc_code
             from   wms_po_iss a, inv_reqslip_hdr e
             where  e.rs_no = a.rs_no
             and    a.process_flag = 'N'
             and    (a.po_no is null
              or     a.po_no <> '""')
             group by a.iss_no, to_date(a.iss_date,'YYYY/MM/DD'), e.vess_code, a.item_type, a.rs_no, sf_get_empl_code(e.requested_by),
                      sf_get_empl_code(a.issued_by), sf_get_empl_code(a.issued_to), sf_get_empl_code(a.prepared_by)
            )
   loop
      err_msg := NULL;
      begin
         insert into inv_iss_hdr
                (iss_no, iss_date, status, vess_code, iss_type, rshd_rs_no, received_by, dt_received,
                 issued_by, issued_to, prepared_by, dt_prepared, created_by, dt_created, ofc_code, apof_code, approving_officer )
         values (b.iss_no, b.iss_date, 'APPROVED', b.vess_code, b.iss_type, b.rshd_rs_no, b.received_by, b.dt_received,
                 b.issued_by, b.issued_to, b.prepared_by, b.dt_prepared, b.created_by, b.dt_created, b.ofc_code, 'L00011', 'L00011');
      exception
         when dup_val_on_index then null;
         when others then
            err_msg := SUBSTR(SQLERRM, 1, 200);
            update wms_po_iss
            set    err_desc = 'H:' || err_msg
            where  iss_no = b.iss_no;
      end;
   end loop;

   -- Create Issuance Detail
   -- iss_no, iss_date, status, rs_no, po_no, item_type , issued_to, issued_by, received_by, via, approving_officer, prepared_by, approved_by,
   -- remarks, amount, series_no, item_code, qty, approved_qty, uom, serial_no, lot_no, batch_no, ware_code, loca_code, bin_no, barcode
   for i in (select a.iss_no, nvl(d.borrowed_rs, b.rshd_rs_no) rshd_rs_no, a.item_code, d.itty_code, d.cate_code, d.itgr_code, a.uom uome_code,
                    a.item_type iss_type, to_date(a.iss_date,'YYYY/MM/DD') iss_date, a.issued_by, 'WR' ref_type, c.dr_no ref_no, c.dr_no,
                    user created_by, sysdate dt_created, decode(d.borrowed_rs, null, d.qty, d.qty_to_release) iss_qty,
                    decode(d.borrowed_rs, null, d.qty, d.qty_to_release) iss_actual_qty
             from   wms_po_iss a, inv_po_hdr b, inv_dr_hdr c, inv_dr_dtl d
             where  a.po_no = b.po_no
             and    b.po_no = c.pohd_po_no
             and    c.dr_no = d.drhd_dr_no
             and    a.process_flag = 'N'
             and    (a.po_no is null
              or     a.po_no <> '""')
             and    a.err_desc is null
             and    a.item_code = d.item_code
             and    a.rs_no = d.rshd_rs_no)
   loop
      bInserted := TRUE;
      err_msg := NULL;
      begin
         insert into inv_iss_dtl
                (ishd_iss_no, rshd_rs_no, item_code, itty_code, cate_code, itgr_code, uome_code,
                 iss_type, iss_date, issued_by, ref_type, ref_no, dr_no, iss_qty, iss_actual_qty,
                 created_by, dt_created )
         values (i.iss_no, i.rshd_rs_no, i.item_code, i.itty_code, i.cate_code, i.itgr_code, i.uome_code,
                 i.iss_type, i.iss_date, i.issued_by, i.ref_type, i.ref_no, i.dr_no, i.iss_qty, i.iss_actual_qty,
                 i.created_by, i.dt_created);
      exception
         when dup_val_on_index then
            update inv_iss_dtl
            set    iss_qty = i.iss_qty,
                   iss_actual_qty = i.iss_actual_qty
            where  ishd_iss_no = i.iss_no
            and    rshd_rs_no = i.rshd_rs_no
            and    item_code = i.item_code
            and    cate_code = i.cate_code
            and    itty_code = i.itty_code
            and    itgr_code = i.itgr_code
            and    uome_code = i.uome_code;
         when others then
            bInserted := FALSE;
            err_msg := SUBSTR(SQLERRM, 1, 200);
            update wms_po_iss
            set    err_desc = 'D:' || err_msg
            where  iss_no = i.iss_no;
      end;

      if bInserted then
         update inv_reqslip_dtl rsdt
         set    rsdt.iss_qty      = greatest(rsdt.iss_qty + nvl(i.iss_qty,0),0)
         where  rsdt.item_code    = i.item_code
         and    rsdt.cate_code    = i.cate_code
         and    rsdt.itty_code    = i.itty_code
         and    rsdt.itgr_code    = i.itgr_code
         and    rsdt.uome_code    = i.uome_code
         and    rsdt.rshd_rs_no   = i.rshd_rs_no;

         update inv_reqslip_hdr
         set    rs_iss_status = sf_get_rs_iss_status(i.rshd_rs_no)
         where  rs_no = i.rshd_rs_no;
      end if;
   end loop;

   --for i in (select nvl(d.borrowed_rs, b.rshd_rs_no) rshd_rs_no, a.item_code, d.itty_code, d.cate_code, d.itgr_code, a.uom uome_code,
   --                 decode(d.borrowed_rs, null, d.qty, d.qty_to_release) iss_qty
   --          from   wms_po_iss_picked a, inv_po_hdr b, inv_dr_hdr c, inv_dr_dtl d
   --          where  a.po_no = b.po_no
   --          and    b.po_no = c.pohd_po_no
   --          and    c.dr_no = d.drhd_dr_no
   --          and    a.process_flag = 'N'
   --          and    a.item_code = d.item_code)
   --loop
   --   update inv_reqslip_dtl rsdt
   --   set    rsdt.iss_qty      = greatest(rsdt.iss_qty + nvl(i.iss_qty,0),0)
   --   where  rsdt.item_code    = i.item_code
   --   and    rsdt.cate_code    = i.cate_code
   --   and    rsdt.itty_code    = i.itty_code
   --   and    rsdt.itgr_code    = i.itgr_code
   --   and    rsdt.uome_code    = i.uome_code
   --   and    rsdt.rshd_rs_no   = i.rshd_rs_no;
   --   update inv_reqslip_hdr
   --   set    rs_iss_status = sf_get_rs_iss_status(i.rshd_rs_no)
   --   where  rs_no = i.rshd_rs_no;
   --end loop;

   update wms_po_iss
   set    process_flag = 'Y'
   where  process_flag = 'N'
   and    err_desc is null;

   commit;
end sp_process_wms_iss;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_ISS_CANCEL" as
begin
   null;
end sp_process_wms_iss_cancel;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_ISS_PICKED" as
   bInserted Boolean;
   err_msg varchar2(200);
begin
   for i in (select a.iss_no, to_date(a.iss_date,'YYYY/MM/DD') iss_date, 'FOR APPROVAL' status, a.intended_for vess_code,
                    decode(a.rs_type, 'PO', 'MAINTENANCE', decode(a.rs_type, 'OPERATION', 'MAINTENANCE', a.rs_type)) iss_type,
                    nvl(d.borrowed_rs, b.rshd_rs_no) rshd_rs_no, sf_get_empl_code(a.requested_by) received_by, sysdate dt_received,
                    sf_get_empl_code(a.requested_by) issued_by, sf_get_empl_code(a.requested_by) issued_to,
                    user prepared_by, sysdate dt_prepared, user created_by, sysdate dt_created, 'HO' ofc_code
             from   wms_po_iss_picked a, inv_po_hdr b, inv_dr_dtl d
             where  a.po_no = b.po_no
             and    a.rr_no = d.drhd_dr_no
             and    a.item_code = d.item_code
             and    a.process_flag = 'N'
             and    a.po_no is not null
             and    a.po_no <> '""'
             group by a.iss_no, to_date(a.iss_date,'YYYY/MM/DD'), 'FOR APPROVAL', a.intended_for,
                    decode(a.rs_type, 'PO', 'MAINTENANCE', decode(a.rs_type, 'OPERATION', 'MAINTENANCE', a.rs_type)),
                    nvl(d.borrowed_rs, b.rshd_rs_no), sf_get_empl_code(a.requested_by)
             )
   loop
      err_msg := null;
      begin
         insert into inv_iss_hdr
                ( iss_no, iss_date, status, vess_code, iss_type, rshd_rs_no, received_by, dt_received,
                  issued_by, issued_to, prepared_by, dt_prepared, created_by, dt_created, ofc_code )
         values ( i.iss_no, i.iss_date, i.status, i.vess_code, i.iss_type, i.rshd_rs_no, i.received_by, i.dt_received,
                  i.issued_by, i.issued_to, i.prepared_by, i.dt_prepared, i.created_by, i.dt_created, i.ofc_code );
      exception
         when dup_val_on_index then
            update inv_iss_hdr
            set    vess_code = i.vess_code,
                   rshd_rs_no = i.rshd_rs_no,
                   received_by = i.received_by,
                   dt_received = i.dt_received,
                   issued_by = i.issued_by,
                   issued_to = i.issued_to,
                   prepared_by = i.prepared_by,
                   dt_prepared = i.dt_prepared,
                   created_by = i.created_by,
                   dt_created = i.dt_created,
                   ofc_code = i.ofc_code
            where  iss_no = i.iss_no;
         when others then
            err_msg := SUBSTR(SQLERRM, 1, 200);
            update wms_po_iss_picked
            set    err_desc = 'H: ' || err_msg
            where  iss_no = i.iss_no;
      end;
   end loop;

   for j in (select a.iss_no, nvl(d.borrowed_rs, b.rshd_rs_no) rshd_rs_no, a.item_code, d.itty_code, d.cate_code, d.itgr_code, a.uom uome_code,
                    a.rs_type iss_type, to_date(a.iss_date,'YYYY/MM/DD') iss_date, a.requested_by issued_by, 'DR' ref_type, c.dr_no ref_no, c.dr_no,
                    user created_by, sysdate dt_created, decode(d.borrowed_rs, null, d.qty, d.qty_to_release) iss_qty,
                    decode(d.borrowed_rs, null, d.qty, d.qty_to_release) iss_actual_qty
             from wms_po_iss_picked a, inv_po_hdr b, inv_dr_hdr c, inv_dr_dtl d
             where  a.po_no = b.po_no
             and    b.po_no = c.pohd_po_no
             and    c.dr_no = d.drhd_dr_no
             and    a.process_flag = 'N'
             and    a.po_no is not null
             and    a.po_no <> '""'
             and    a.err_desc is null
             and    a.item_code = d.item_code
             and    a.rr_no = d.drhd_dr_no)
   loop
      bInserted := TRUE;
      err_msg   := null;
      begin
         insert into inv_iss_dtl
                (ishd_iss_no, iss_date, rshd_rs_no, item_code, itty_code, cate_code, itgr_code, uome_code,
                 ref_type, ref_no, dr_no, iss_qty, iss_actual_qty, iss_type, issued_by, created_by, dt_created)
         values (j.iss_no, j.iss_date, j.rshd_rs_no, j.item_code, j.itty_code, j.cate_code, j.itgr_code, j.uome_code,
                 j.ref_type, j.ref_no, j.dr_no, j.iss_qty, j.iss_actual_qty, j.iss_type, j.issued_by, j.created_by, j.dt_created );
      exception
         when dup_val_on_index then
            update inv_iss_dtl
            set    ref_type = j.ref_type,
                   ref_no = j.ref_no,
                   dr_no = j.dr_no,
                   issued_by = j.issued_by,
                   created_by = j.created_by,
                   dt_created = j.dt_created,
                   iss_qty = j.iss_qty,
                   iss_actual_qty = j.iss_actual_qty
            where  ishd_iss_no = j.iss_no
            and    rshd_rs_no = j.rshd_rs_no
            and    item_code = j.item_code
            and    cate_code = j.cate_code
            and    itty_code = j.itty_code
            and    itgr_code = j.itgr_code
            and    uome_code = j.uome_code;
         when others then
            bInserted := FALSE;
            err_msg := SUBSTR(SQLERRM, 1, 200);
            update wms_po_iss_picked
            set    err_desc = 'D:' || err_msg
            where  iss_no = j.iss_no;
      end;

      if bInserted then
         update inv_reqslip_dtl rsdt
         set    rsdt.iss_qty      = greatest(rsdt.iss_qty + nvl(j.iss_qty,0),0)
         where  rsdt.item_code    = j.item_code
         and    rsdt.cate_code    = j.cate_code
         and    rsdt.itty_code    = j.itty_code
         and    rsdt.itgr_code    = j.itgr_code
         and    rsdt.uome_code    = j.uome_code
         and    rsdt.rshd_rs_no   = j.rshd_rs_no;
         update inv_reqslip_hdr
         set    rs_iss_status = sf_get_rs_iss_status(j.rshd_rs_no)
         where  rs_no = j.rshd_rs_no;
      end if;
   end loop;

   update wms_po_iss_picked
   set    process_flag = 'Y'
   where  process_flag = 'N'
   and    err_desc is null;
   commit;
end sp_process_wms_iss_picked;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_JO_ISS" as
begin
   null;
end sp_process_wms_jo_iss;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_JO_RR" as
begin
   null;
end sp_process_wms_jo_rr;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_PO_RR" as
begin
   null;
end sp_process_wms_po_rr;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_RETURN" as
begin
   null;
end sp_process_wms_return;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_RETURN_SUP" as
begin
   null;
end sp_process_wms_return_sup;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_WTS" as
BEGIN
   insert into inv_ware_transfer_hdr
         (tran_no, tran_date, ware_code_o, ware_code_d, status, requested_by, prepared_by, dt_prepared,
          approved_by, dt_approved, vess_code, ofc_code, remarks, created_by, dt_created)
   select wts_no, to_date(wts_date,'YYYY/MM/DD'), sf_inv_get_warehouse(ware_code_fr), sf_inv_get_warehouse(ware_code_to), 'Pending', sf_get_empl_code(received_by),
          sf_get_empl_code(prepared_by), nvl(to_date(dt_approved,'YYYY/MM/DD'),sysdate),
         'L00011', to_date(dt_approved,'YYYY/MM/DD'), intended_for, 'HO', remarks, user, sysdate
   from   wms_wts
   where process_flag = 'N'
   group by wts_no, to_date(wts_date,'YYYY/MM/DD'), sf_inv_get_warehouse(ware_code_fr), sf_inv_get_warehouse(ware_code_to), 'Pending', sf_get_empl_code(received_by),
            sf_get_empl_code(prepared_by), nvl(to_date(dt_approved,'YYYY/MM/DD'),sysdate), 'L00011',
            to_date(dt_approved,'YYYY/MM/DD'), intended_for, 'HO', remarks;

   insert into inv_ware_transfer_dtl
    (tran_no, ware_code_o, ware_code_d, item_code, itty_code, cate_code, itgr_code, qty, uome_code,
     tracking_no, remarks, created_by, dt_created, vess_code, approved_qty, pl_tran_no)
   select a.wts_no, sf_inv_get_warehouse(a.ware_code_fr), sf_inv_get_warehouse(a.ware_code_to), a.item_code, b.itty_code, b.cate_code, b.itgr_code, a.qty, a.uom,
     a.batch_no, a.remarks, user, sysdate, intended_for, a.qty, a.lot_no
   from wms_wts a, inv_items b
   where a.process_flag = 'N'
   and   a.item_code = b.code;

   update wms_wts set process_flag='Y' where process_flag='N';
   commit;
END sp_process_wms_wts;



 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_WTS_CANCEL" as
begin
   null;
end sp_process_wms_wts_cancel;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PROCESS_WMS_WTS_PICKED" as
begin
   -- Create Header
   insert into inv_ware_transfer_hdr
         (TRAN_NO, TRAN_DATE, WARE_CODE_O, WARE_CODE_D,
          VESS_CODE, STATUS, CREATED_BY, DT_CREATED, OFC_CODE)
   select st_no, to_date(st_date,'YYYY/MM/DD'), warehouse_fr, warehouse_to,
          intended_for, 'FOR APPROVAL', user, sysdate, 'HO'
   from   wms_wts_picked
   where   process_flag = 'N'
   group by st_no, to_date(st_date,'YYYY/MM/DD'), warehouse_fr, warehouse_to, intended_for;

   insert into inv_ware_transfer_dtl
         (tran_no, item_code, itty_code, cate_code, itgr_code, uome_code,
          ware_code_o, ware_code_d, created_by, dt_created, qty, approved_qty)
   select a.st_no, a.item_code, b.itty_code, b.cate_code, b.itgr_code, a.uom,
          warehouse_fr, warehouse_to, user, sysdate, qty, approved_qty
   from wms_wts_picked a, inv_items b
   where  a.item_code = b.code
   and    a.process_flag = 'N';

   update wms_wts
   set    process_flag = 'Y'
   where  process_flag = 'N';

end sp_process_wms_wts_picked;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PYS_BACKUP_PAYROLL_NO" (p_payroll_no in number) as
   vOpMsg       Varchar2(1024);
   vCheckHist   Number;
   vCheckTran   Number;
begin

   delete from PYS_PAYROLL_DTL_LOG_RE WHERE payroll_no = p_payroll_no;
   delete from PYS_PAYROLL_DTL_RE WHERE pahd_payroll_no = p_payroll_no;
   delete from PYS_PAYROLL_DTL_ADJ_LOG_RE WHERE pahd_payroll_no = p_payroll_no;
   delete from PYS_PAYROLL_SUMMARY_RE WHERE payroll_no = p_payroll_no;
   delete from PYS_13TH_MONTH_SUMMARY_RE WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
   delete from PYS_SSS_CONTRIBUTION_RE WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
   delete from PYS_PAGIBIG_CONTRIBUTION_RE WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
   delete from PYS_PHILHEALTH_CONTRIBUTION_RE WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');

   begin
      insert into PYS_PAYROLL_DTL_LOG_RE select * from PYS_PAYROLL_DTL_LOG WHERE payroll_no = p_payroll_no;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_PAYROLL_DTL_LOG backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_PAYROLL_DTL_RE select * from PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payroll_no;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_PAYROLL_DTL backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_PAYROLL_DTL_ADJ_LOG_RE select * from PYS_PAYROLL_DTL_ADJ_LOG WHERE pahd_payroll_no = p_payroll_no;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_PAYROLL_DTL_ADJ_LOG backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_PAYROLL_SUMMARY_RE select * from PYS_PAYROLL_SUMMARY WHERE payroll_no = p_payroll_no;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_PAYROLL_SUMMARY backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_13TH_MONTH_SUMMARY_RE select * from PYS_13TH_MONTH_SUMMARY WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
      vCheckHist := sql%rowcount;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_13TH_MONTH_SUMMARY backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_SSS_CONTRIBUTION_RE select * from PYS_SSS_CONTRIBUTION WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
      vCheckHist := sql%rowcount;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_SSS_CONTRIBUTION backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_PAGIBIG_CONTRIBUTION_RE select * from PYS_PAGIBIG_CONTRIBUTION WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
      vCheckHist := sql%rowcount;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_PAGIBIG_CONTRIBUTION backup. ORA' || to_char(SQLCODE) || '.';
   end;

   begin
      insert into PYS_PHILHEALTH_CONTRIBUTION_RE select * from PYS_PHILHEALTH_CONTRIBUTION WHERE period_to = to_date(to_char(p_payroll_no), 'YYYYMMDD');
      vCheckHist := sql%rowcount;
   exception
      when others then
         vOpMsg   := nvl(vOpMsg,'') || chr(10) || 'ERROR on PYS_PHILHEALTH_CONTRIBUTION backup. ORA' || to_char(SQLCODE) || '.';
   end;
   commit;
end sp_pys_backup_payroll_no;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PYS_CREATE_PAY_ADJ" (p_empl_id in varchar2, p_payroll_no in number)  as
   nItemNo Number;
begin
   select nvl(max(item_no),0)
   into   nItemNo
   from   pys_payroll_dtl_adj_log
   where  pahd_payroll_no = p_payroll_no;

   for i in (select PAHD_PAYROLL_NO, SEQ_NO, EMPL_EMPL_ID, PATY_CODE, DEDU_SEQ_NO, DETY_CODE,
                    PERIOD_FR, PERIOD_TO, NO_DAYS, BASIC_RATE, BASIC_RATE_G, AMT, AMT_G, SAL_FREQ, LATEST_VESS,
                    POSI_CODE, VESS_CODE, TITLE, DEPT_CODE, PAY_FLAG
             from   pys_payroll_dtl a
             where  empl_empl_id = p_empl_id
             and    pahd_payroll_no = p_payroll_no
             and    not exists ( select 1
                                 from   pys_payroll_dtl_adj_log b
                                 where  a.empl_empl_id = b.empl_empl_id
                                 and    a.pahd_payroll_no = b.pahd_payroll_no
                               ) )
   loop
      begin
         nItemNo := nItemNo + 1;
         insert into pys_payroll_dtl_adj_log
            ( PAHD_PAYROLL_NO, ITEM_NO, SEQ_NO, EMPL_EMPL_ID, PATY_CODE, DEDU_SEQ_NO, DETY_CODE,
              PERIOD_FR, PERIOD_TO, NO_DAYS, BASIC_RATE, BASIC_RATE_G, AMT, AMT_G, SAL_FREQ, LATEST_VESS,
              POSI_CODE, VESS_CODE, TITLE, DEPT_CODE, PAY_FLAG, ADJ_ACTION, CREATED_BY, DT_CREATED
            )
         values
            ( i.PAHD_PAYROLL_NO, nItemNo, i.SEQ_NO, i.EMPL_EMPL_ID, i.PATY_CODE, i.DEDU_SEQ_NO, i.DETY_CODE,
              i.PERIOD_FR, i.PERIOD_TO, i.NO_DAYS, i.BASIC_RATE, i.BASIC_RATE_G, i.AMT, i.AMT_G, i.SAL_FREQ, i.LATEST_VESS,
              i.POSI_CODE, i.VESS_CODE, i.TITLE, i.DEPT_CODE, i.PAY_FLAG, 'UPDATE', user, sysdate
            );
      end;
   end loop;
   commit;
end sp_pys_create_pay_adj;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_PYS_REVERSE_ADJUSTMENT" (
   p_payroll_no   VARCHAR2,
   p_empl_empl_id VARCHAR2) AS
BEGIN
   FOR i IN (SELECT empl_empl_id, seq_no, paty_code, basic_rate, amt, basic_rate_g, amt_g, no_days, adj_action
             FROM pys_payroll_dtl_adj_log
             WHERE empl_empl_id =p_empl_empl_id
             AND pahd_payroll_no = p_payroll_no)
   LOOP
      if i.adj_action = 'INSERT' then
        delete from pys_payroll_dtl
        WHERE  pahd_payroll_no = p_payroll_no
        AND    empl_empl_id = i.empl_empl_id
        AND    seq_no = i.seq_no;
      end if;
      if i.adj_action = 'UPDATE' then
        UPDATE pys_payroll_dtl
        SET    basic_rate    = i.basic_rate,
               amt           = i.amt,
               basic_rate_g  = i.basic_rate_g,
               amt_g         = i.amt_g,
               no_days       = i.no_days,
               adj_approval    = 'N',
               adj_approved_by = NULL,
               adj_approved_dt = NULL
        WHERE  pahd_payroll_no = p_payroll_no
        AND    seq_no = i.seq_no;
      end if;
   END LOOP;

   -- delete from payroll dtl which not exists in adjustment
   delete from pys_payroll_dtl padt
   WHERE  padt.pahd_payroll_no = p_payroll_no
   AND    padt.empl_empl_id = p_empl_empl_id
   and    not exists(select 1
                     from   pys_payroll_dtl_adj_log adj
                     where  adj.pahd_payroll_no = padt.pahd_payroll_no
                     and    padt.empl_empl_id = adj.empl_empl_id
                     and    adj.seq_no = padt.seq_no);


   UPDATE pys_payroll_dtl_adj_log
   SET    adj_approval    = 'N',
          adj_approved_by = NULL,
          adj_approved_dt = NULL
   WHERE empl_empl_id = p_empl_empl_id
   AND   pahd_payroll_no = p_payroll_no;

   COMMIT;

END sp_pys_reverse_adjustment;
 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_RECOMPUTE_13MONTH" (
   p_payno_1 in number,
   p_payno_2 in number
   ) as
   dStart       Date;
   dEnd         Date;
   nColaRate    Number(8,2);
   n13th_n_mon  Number(9,2);
   n13th_a      Number(9,2);
   n13th_b      Number(9,2);
   nSILP_a      Number(9,2);
   nSILP_b      Number(9,2);
   n13th_amt_a  Number(12,2);
   n13th_amt_b  Number(12,2);
   dPeriodFr    Date;
   dPeriodTo    Date;
   nOuterR      Number(8,4);
   n13th_n_mon_b Number(9,2);
begin
   -- clear summary
   delete from pys_13th_month
   where  payroll_no = p_payno_2;
   commit;
   -- get Outer Port Rate
   begin
      select rate
      into   nOuterR
      from   pys_payroll_types
      where  code = 'REG-OP';
   exception
      when no_data_found then nOuterR := 1;
      when others then nOuterR := 1;
   end;

   select period_fr, period_to
   into   dStart, dEnd
   from   pys_payroll_hdr
   where  payroll_no = p_payno_2;

   for i in (select empl_id, max(period_to) period_to, max(sal_freq) sal_freq, max(dept_code) dept_code,
                    sum(cola_amt) cola_amt, sum(cola_day) cola_day, max(cola_rate) cola_rate
             from   pys_payroll_summary
             where  payroll_no in (p_payno_1, p_payno_2)
             group  by empl_id)
   loop
      for k in (select empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g, oport
                from   pys_payroll_summary
                where  empl_id = i.empl_id
                and    payroll_no in (p_payno_1, p_payno_2)
                order  by payroll_no desc, period_to desc)
      loop
         -- compute for 13th MONTH and SILP
         -- compute for 13th MONTH and SILP
         -- compute for 13th MONTH and SILP
         nSILP_a := 0;    n13th_amt_a := 0;   n13th_n_mon := 0;
         nSILP_b := 0;    n13th_amt_b := 0;   n13th_n_mon_b := 0;
         if to_date('0112' || to_char(dEnd, 'YYYY'), 'DDMMYYYY') > dEnd then
            dPeriodFr := add_months(to_date('0112' || to_char(dEnd, 'YYYY'), 'DDMMYYYY'),-12);
            dPeriodTo := to_date('3011' || to_char(dEnd, 'YYYY'), 'DDMMYYYY');
         else
            dPeriodFr := to_date('0112' || to_char(dEnd, 'YYYY'), 'DDMMYYYY');
            dPeriodTo := add_months(to_date('3011' || to_char(dEnd, 'YYYY'), 'DDMMYYYY'),12);
         end if;
         for n in (select to_char(pahd.period_to,'YYYYMM') cur_mon,
                          sum(pay.amount) amount,
                          sum(pay.no_days) no_days,
                          sum(pay.cola_amt) cola_amt,
                          nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate)) basic_rate_a,
                          max(pay.dept_code) dept_code,
                          decode(greatest(sum(pay.no_days),15),15,.5,1) nMon,
                         (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) )  amount_g
                          --+
                          -- decode(pay.dept_code,'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                   from   pys_payroll_summary pay,
                          pys_payroll_hdr pahd
                   where  pay.empl_id = i.empl_id
                   and    pay.payroll_no = pahd.payroll_no
                   --AND    pay.no_days > 0
                   and    pahd.period_to between dPeriodFr and dPeriodTo
                   group  by to_char(pahd.period_to,'YYYYMM')
                   having (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) ) > 0)
         loop
            n13th_n_mon := n13th_n_mon + n.nMon;
            n13th_amt_a := n13th_amt_a + nvl(n.amount_g,0);
         end loop;
         if n13th_n_mon > 0 then
            n13th_a := (n13th_amt_a/n13th_n_mon) * (n13th_n_mon/12);
         end if;

         for n in (select to_char(pahd.period_to,'YYYYMM') cur_mon,
                          sum(pay.amount) amount,
                          sum(pay.no_days) no_days,
                          sum(pay.cola_amt) cola_amt,
                          nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate)) basic_rate_a,
                          max(pay.dept_code) dept_code,
                          decode(greatest(sum(pay.no_days),15),15,.5,1) nMon,
                         (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) )  amount_g
                          --+
                          -- decode(pay.dept_code,'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                   from   pys_payroll_summary pay,
                          pys_payroll_hdr pahd
                   where  pay.empl_id = i.empl_id
                   and    pay.payroll_no = pahd.payroll_no
                   and    pay.period_fr >= pahd.period_fr
                   and    pahd.period_to between dPeriodFr and dPeriodTo
                   group  by to_char(pahd.period_to,'YYYYMM'))
         loop
             n13th_n_mon_b := n13th_n_mon_b + n.nMon;
             n13th_amt_b := n13th_amt_b + nvl(n.amount,0);
         end loop;
         if n13th_n_mon_b > 0 then
            n13th_b := (n13th_amt_b/n13th_n_mon_b) * (n13th_n_mon_b/12);
         end if;

         for n in (select basic_rate, sum(nMon) nMon from (
                   select to_char(pahd.period_to,'YYYYMM') cur_mon,
                           decode(oport,'Y',round(pay.basic_rate/1.3,2),pay.basic_rate)  basic_rate,
                          decode(greatest(sum(pay.no_days),15),15,.5,1) nMon
                   from   pys_payroll_summary pay,
                          pys_payroll_hdr pahd
                   where  pay.empl_id = i.empl_id
                   and    pay.payroll_no = pahd.payroll_no
                   and    pahd.period_to between dPeriodFr and dPeriodTo
                   and    pay.period_fr >= pahd.period_fr
                   group  by to_char(pahd.period_to,'YYYYMM'),  decode(oport,'Y',round(pay.basic_rate/1.3,2),pay.basic_rate)   )
                   group  by basic_rate
                  )
         loop
            nSILP_b := nSILP_b + (n.basic_rate * 5 * (n.nMon/12));
         end loop;

         for n in (select basic_rate, sum(nMon) nMon from (
                   select to_char(pahd.period_to,'YYYYMM') cur_mon,
                          decode(max(pay.dept_code), 'FL', nvl(max(pay.l_basic_rate_a)-max(pay.cola_rate),max(pay.l_basic_rate)-max(pay.cola_rate)),
                                                     'MA-CREW', nvl(max(pay.l_basic_rate_a)-max(pay.cola_rate),max(pay.l_basic_rate)-max(pay.cola_rate)),
                                                      nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))/30)  basic_rate,
                          decode(greatest(sum(pay.no_days),15),15,.5,1) nMon
                   from   pys_payroll_summary pay,
                          pys_payroll_hdr pahd
                   where  pay.empl_id = i.empl_id
                   and    pay.payroll_no = pahd.payroll_no
                   --AND    pay.no_days > 0
                   and    pahd.period_to between dPeriodFr and dPeriodTo
                   group  by to_char(pahd.period_to,'YYYYMM')
                   having (decode(max(pay.dept_code),'FL', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)),'MA-CREW', sum(pay.no_days)*(nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))-max(pay.cola_rate)), nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))) ) > 0)
                   group  by basic_rate
                  )
         loop
            nSILP_a := nSILP_a + (n.basic_rate * 5 * (n.nMon/12));
         end loop;

         begin
            insert into pys_13th_month_summary
                   (empl_id, dept_code, vess_code, title, period_fr, period_to, m_13_amt, m_13_amt_a, silp_amt, silp_amt_a )
            values (i.empl_id, i.dept_code, k.l_vess_code, nvl(k.l_title, k.title), dPeriodFr, dPeriodTo, n13th_b, n13th_a, nSILP_b, nSILP_a );
         exception
            when dup_val_on_index then
               update pys_13th_month_summary
               set    m_13_amt   = n13th_b,
                      m_13_amt_a = n13th_a,
                      silp_amt   = nSILP_b,
                      silp_amt_a = nSILP_a
               where  empl_id = i.empl_id
               and    period_fr = dPeriodFr
               and    period_to = dPeriodTo;
         end;
         exit;
      end loop;
   end loop;
end sp_recompute_13month;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_RESET_RR_APV" (p_rr_no in varchar2, p_type in varchar2) as
   nChk Number;
   vAPNO Varchar2(20);
begin
   if p_type = 'PO' then
      select max(ap_no), count(1)
      into   vAPNO, nChk
      from   acc_ap_inv_dtl
      where  rr_no = p_rr_no
      and    po_no not like 'JO%'
      and    is_selected = 'Y';
   else
      select max(ap_no), count(1)
      into   vAPNO, nChk
      from   acc_ap_inv_dtl
      where  rr_no = p_rr_no
      and    po_no like 'JO%'
      and    is_selected = 'Y';
   end if;
   if nChk = 0 then
      if p_type = 'PO' then
         update inv_dr_hdr set ap_no = null where dr_no = p_rr_no;
      elsif p_type = 'JO' then
         update inv_jo_dr_hdr set ap_no = null where jo_dr_no = p_rr_no;
      end if;
      commit;
   end if;
   dbms_output.put_line ('.');
   dbms_output.put_line ('.');
   dbms_output.put_line ('Already exists on AP NO. ' || vAPNO);
   dbms_output.put_line ('.');
   dbms_output.put_line ('.');
end sp_reset_rr_apv;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_UPDATE_LATEST_VESSEL" as
begin
   for i in (select empl_id from pms_employees where dept_code = 'FL') loop
      for j in (select voya_vess_code, title, dt_embarked from cms_voyage_crew where empl_empl_id = i.empl_id order by dt_embarked desc) loop
         update pms_employees
         set    vess_code = j.voya_vess_code,
                latest_title = j.title,
                latest_embarked = j.dt_embarked
         where  empl_id = i.empl_id;
         exit;
      end loop;
   end loop;
end sp_update_latest_vessel;

 /


  CREATE OR REPLACE PROCEDURE "TPJ"."SP_UPDATE_VOYAGE_CONTRACT_CREW" (
   p_vess_code       VARCHAR2,
   p_voyage_date     DATE,
   p_voro_seq_no   NUMBER,
   p_contract_type   VARCHAR2,
   p_contract_no     VARCHAR2
)
AS
   p_ref_date   DATE;
BEGIN
   BEGIN
      SELECT TRUNC (ref_date)
      INTO   p_ref_date
      FROM   CMS_VOYAGES_CONTRACT
      WHERE  vess_code = p_vess_code
      AND    voyage_date = p_voyage_date
      AND    voro_seq_no = p_voro_seq_no
      AND    contract_type = p_contract_type
      AND    contract_no = p_contract_no;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         DBMS_OUTPUT.PUT_LINE('Invalid Contract');
         RETURN;
   END;
   DBMS_OUTPUT.PUT_LINE('p_vess_code '||p_vess_code);
   DBMS_OUTPUT.PUT_LINE('p_voyage_date '||p_voyage_date);
   DBMS_OUTPUT.PUT_LINE('p_voro_seq_no '||p_voro_seq_no);
   DBMS_OUTPUT.PUT_LINE('p_contract_type '||p_contract_type);
   DBMS_OUTPUT.PUT_LINE('p_contract_no  '|| p_contract_no );

   IF p_contract_type = 'VOYAGE CONTRACT' THEN
      BEGIN
         DELETE FROM CMS_VOYAGES_CONTRACT_CREW
         WHERE vess_code = p_vess_code
         AND voyage_date = p_voyage_date
         AND voro_seq_no = p_voro_seq_no
         AND contract_type = p_contract_type
         AND contract_no = p_contract_no;
         DBMS_OUTPUT.PUT_LINE(p_contract_type);

         FOR a IN ( SELECT p_vess_code, p_voyage_date, p_contract_type, p_contract_no,
                           voyacrew.empl_empl_id, voyacrew.rank_code, USER, SYSDATE
                    FROM   CMS_VOYAGE_CREW voyacrew,
                           PMS_EMPLOYEES empl,
                           CMS_VESSEL_CREW vesscrew
                    WHERE voyacrew.empl_empl_id = empl.empl_id
                    AND voyacrew.voya_vess_code = p_vess_code
                    AND voyacrew.voya_voyage_date = p_voyage_date
                    --AND voyacrew.voya_vess_code = empl.vess_code
                    --AND voyacrew.dt_embarked = empl.latest_embarked
                    --AND voyacrew.rank_code = empl.latest_rank_code
                    AND vesscrew.vess_code(+) = voyacrew.voya_vess_code
                    AND vesscrew.rank_code(+) = voyacrew.rank_code
                    AND EXISTS ( SELECT 1
                                 FROM CMS_VOYAGE_CREW voyacrew1
                                 WHERE voyacrew.empl_empl_id = voyacrew1.empl_empl_id
                                 AND voyacrew.voya_vess_code = voyacrew1.voya_vess_code
                                 AND voyacrew.voya_voyage_date = voyacrew1.voya_voyage_date
                                 AND voyacrew.rank_code = voyacrew1.rank_code
                                 AND voyacrew1.orig_list = 'Y')
                                )
         LOOP
            BEGIN
               INSERT INTO CMS_VOYAGES_CONTRACT_CREW
                      ( vess_code, voyage_date, contract_type, contract_no, voro_seq_no,
                        empl_empl_id, rank_code, created_by, dt_created)
               VALUES ( p_vess_code, p_voyage_date, p_contract_type, p_contract_no, p_voro_seq_no,
                        a.empl_empl_id, a.rank_code, USER, SYSDATE );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX THEN NULL;
            END;
         END LOOP;
      END;
   ELSIF p_contract_type = 'ADDENDUM' THEN
      BEGIN
         DELETE FROM CMS_VOYAGES_CONTRACT_CREW
         WHERE vess_code = p_vess_code
         AND voyage_date = p_voyage_date
         AND voro_seq_no = p_voro_seq_no
         AND contract_type = p_contract_type
         AND contract_no = p_contract_no;
         DBMS_OUTPUT.PUT_LINE(p_contract_type);

         INSERT INTO CMS_VOYAGES_CONTRACT_CREW
                     ( vess_code, voyage_date, contract_type, contract_no, voro_seq_no,
                       empl_empl_id, rank_code, created_by, dt_created )
         SELECT DISTINCT p_vess_code, p_voyage_date, p_contract_type, p_voro_seq_no,
                         p_contract_no, voyacrew.empl_empl_id,
                         voyacrew.rank_code, USER, SYSDATE
         FROM CMS_VOYAGE_CREW voyacrew,
              PMS_EMPLOYEES empl,
              CMS_VESSEL_CREW vesscrew
         WHERE voyacrew.empl_empl_id = empl.empl_id
         AND voyacrew.voya_vess_code = p_vess_code
         AND voyacrew.voya_voyage_date = p_voyage_date
         --AND voyacrew.voya_vess_code = empl.vess_code
         --AND voyacrew.dt_embarked = empl.latest_embarked
         --AND voyacrew.rank_code = empl.latest_rank_code
         AND vesscrew.vess_code(+) = voyacrew.voya_vess_code
         AND vesscrew.rank_code(+) = voyacrew.rank_code
         AND TRUNC (voyacrew.dt_embarked) = p_ref_date
         AND NOT EXISTS ( SELECT 1
                          FROM CMS_VOYAGE_CREW voyacrew1
                          WHERE voyacrew.empl_empl_id = voyacrew1.empl_empl_id
                          AND voyacrew.voya_vess_code = voyacrew1.voya_vess_code
                          AND voyacrew.voya_voyage_date = voyacrew1.voya_voyage_date
                          AND voyacrew.rank_code = voyacrew1.rank_code
                          AND voyacrew1.orig_list = 'Y');
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('Addendum Duplicate '||SQLERRM);
            NULL;
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Addendum Others '||SQLERRM);
            RAISE_APPLICATION_ERROR(-20001, SQLERRM);
      END;
   ELSIF p_contract_type = 'CREW END CONTRACT' THEN
      BEGIN
         DELETE FROM CMS_VOYAGES_CONTRACT_CREW
         WHERE vess_code = p_vess_code
         AND voyage_date = p_voyage_date
         AND voro_seq_no = p_voro_seq_no
         AND contract_type = p_contract_type
         AND contract_no = p_contract_no;
         DBMS_OUTPUT.PUT_LINE(p_contract_type);
         -- end of contract
         INSERT INTO CMS_VOYAGES_CONTRACT_CREW
                ( vess_code, voyage_date, contract_type, contract_no, voro_seq_no,
                  empl_empl_id, rank_code, created_by, dt_created )
         SELECT DISTINCT p_vess_code, p_voyage_date, p_contract_type, p_voro_seq_no,
                         p_contract_no, voyacrew.empl_empl_id,
                         voyacrew.rank_code, USER, SYSDATE
         FROM CMS_VOYAGE_CREW voyacrew,
              PMS_EMPLOYEES empl,
              CMS_VESSEL_CREW vesscrew
         WHERE voyacrew.empl_empl_id = empl.empl_id
         AND voyacrew.voya_vess_code = p_vess_code
         AND voyacrew.voya_voyage_date = p_voyage_date
         AND voyacrew.voya_vess_code = empl.vess_code
         AND voyacrew.dt_embarked = empl.latest_embarked
         AND voyacrew.rank_code = empl.latest_rank_code
         AND vesscrew.vess_code(+) = voyacrew.voya_vess_code
         AND vesscrew.rank_code(+) = voyacrew.rank_code
         AND TRUNC (voyacrew.dt_disembarked) = p_ref_date;
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN NULL;
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Addendum Others '||SQLERRM);
            RAISE_APPLICATION_ERROR(-20001, SQLERRM);
      END;

      BEGIN
         -- change vessel
         INSERT INTO CMS_VOYAGES_CONTRACT_CREW
                       ( vess_code, voyage_date, contract_type, contract_no, voro_seq_no,
                         empl_empl_id, rank_code, created_by, dt_created)
         SELECT DISTINCT p_vess_code, p_voyage_date, p_contract_type, p_voro_seq_no,
                         p_contract_no, voyacrew.empl_empl_id,
                         voyacrew.rank_code, USER, SYSDATE
         FROM CMS_VOYAGE_CREW voyacrew
         WHERE EXISTS ( SELECT 1
                        FROM PMS_EMPLOYEE_MOVEMENTS emove
                        WHERE voyacrew.tran_no_disembarked = emove.tran_no
                        AND emove.fr_vess_code <> emove.to_vess_code )
         AND TRUNC (voyacrew.dt_disembarked) = p_ref_date;
      EXCEPTION
         WHEN DUP_VAL_ON_INDEX THEN NULL;
         WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Addendum Others '||SQLERRM);
            RAISE_APPLICATION_ERROR(-20001, SQLERRM);
      END;
   ELSIF p_contract_type = 'VOYAGE END CONTRACT' THEN
      BEGIN
         DELETE FROM CMS_VOYAGES_CONTRACT_CREW
         WHERE vess_code = p_vess_code
         AND voyage_date = p_voyage_date
         AND voro_seq_no = p_voro_seq_no
         AND contract_type = p_contract_type
         AND contract_no = p_contract_no;

         FOR a IN (SELECT   empl_empl_id, rank_code
                   FROM CMS_VOYAGE_CREW voyacrew
                   WHERE voyacrew.voya_vess_code = p_vess_code
                   AND voyacrew.voya_voyage_date = p_voyage_date
                   ORDER BY dt_embarked DESC)
         LOOP
            BEGIN
               INSERT INTO CMS_VOYAGES_CONTRACT_CREW
                      ( vess_code, voyage_date, contract_type, voro_seq_no,
                        contract_no, empl_empl_id, rank_code,
                        created_by, dt_created )
               VALUES ( p_vess_code, p_voyage_date, p_contract_type, p_voro_seq_no,
                        p_contract_no, a.empl_empl_id, a.rank_code,
                        USER, SYSDATE );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX THEN NULL;
               WHEN OTHERS THEN
                  DBMS_OUTPUT.PUT_LINE('Addendum Others '||SQLERRM);
                  RAISE_APPLICATION_ERROR(-20001, SQLERRM);
            END;
         END LOOP;
      END;
   END IF;
END;

 /


  CREATE OR REPLACE TRIGGER "TPJ"."ACC_ACCOUNTS_TRG"
BEFORE INSERT
ON ACC_ACCOUNTS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   nPos Number;
BEGIN
   IF replace(upper(:new.name),' ','') like 'CASHINBANK%' then
      nPos := instr(upper(:new.name), 'BANK', 1, 1);
      insert into acc_banks
             (code, name, account_type, acco_code, created_by, dt_created)
      values (:new.code, ltrim(replace(substr(:new.name, nPos+5), '-',' ')), 'CURRENT', :new.code, user, sysdate);
   END IF;
EXCEPTION
   when dup_val_on_index then null;
END acc_accounts_trg;
ALTER TRIGGER "TPJ"."ACC_ACCOUNTS_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."ACC_ACCOUNTS_UPD_TRG"
BEFORE UPDATE
ON ACC_ACCOUNTS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   nPos Number;
BEGIN
   IF replace(upper(:new.name),' ','') like 'CASHINBANK%' then
      nPos := instr(upper(:new.name), 'BANK', 1, 1);
      insert into acc_banks
             (code, name, account_type, acco_code, created_by, dt_created)
      values (:new.code, ltrim(replace(substr(:new.name, nPos+5), '-',' ')), 'CURRENT', :new.code, user, sysdate);
   END IF;
EXCEPTION
   when dup_val_on_index then null;
END acc_accounts_upd_trg;
ALTER TRIGGER "TPJ"."ACC_ACCOUNTS_UPD_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."ACC_APDT_AUDIT_LOG_TRG"
before delete on acc_ap_dtl
for each row
begin
   insert into acc_ap_dtl_log
          (item_no, ap_no, acco_code, ref_type, ref_code, debit, credit, debit_php, credit_php, created_by, dt_created, modified_by, dt_modified, posted_by, dt_posted )
   values (:old.item_no, :old.ap_no, :old.acco_code, :old.ref_type, :old.ref_code, :old.debit, :old.credit, :old.debit_php, :old.credit_php, :old.created_by, :old.dt_created, :old.modified_by, :old.dt_modified, user, sysdate);
exception
   when others then
   insert into debug_log (source, ref_code, dt_created, ref_info )
   values ( 'ACC_APDT_AUDIT_LOG_TRG', :old.ap_no, sysdate,
                               ' :old.acco_code=' || :old.acco_code ||
                               ' :old.debit = ' || to_char(:old.debit ) ||
                               ' :old.credit = ' || to_char(:old.credit));

end;

ALTER TRIGGER "TPJ"."ACC_APDT_AUDIT_LOG_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."ACC_AP_INV_DTL_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON TPJ.ACC_AP_INV_DTL REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF INSERTING THEN
      IF (:NEW.IS_SELECTED = 'Y') THEN
         IF ((:NEW.RS_NO LIKE 'O%') OR (:NEW.RS_NO LIKE 'M%')) THEN
            UPDATE INV_DR_HDR SET RR_PAID = RR_PAID + :NEW.AMOUNT, RR_PAID_FX = RR_PAID_FX + :NEW.FX_AMOUNT
            WHERE  DR_NO = :NEW.RR_NO;
         ELSE
            UPDATE INV_JO_DR_HDR SET RR_PAID = RR_PAID + :NEW.AMOUNT
            WHERE  JO_DR_NO = :NEW.RR_NO;
         END IF;
      END IF;
   END IF;
   IF UPDATING THEN
      IF (:NEW.RS_NO LIKE 'O%') OR (:NEW.RS_NO LIKE 'M%') THEN
         UPDATE INV_DR_HDR SET RR_PAID = RR_PAID + (:NEW.AMOUNT - :OLD.AMOUNT), RR_PAID_FX = RR_PAID_FX + (:NEW.FX_AMOUNT - :OLD.FX_AMOUNT)
         WHERE  DR_NO = :NEW.RR_NO;
      ELSE
         UPDATE INV_JO_DR_HDR SET RR_PAID = RR_PAID + (:NEW.AMOUNT - :OLD.AMOUNT)
         WHERE  JO_DR_NO = :NEW.RR_NO;
      END IF;
   END IF;
   IF DELETING THEN
      IF (:OLD.RS_NO LIKE 'O%') OR (:OLD.RS_NO LIKE 'M%') THEN
         UPDATE INV_DR_HDR SET RR_PAID = GREATEST((RR_PAID - :OLD.AMOUNT), 0), RR_PAID_FX = GREATEST((RR_PAID_FX - :OLD.FX_AMOUNT),0)
         WHERE  DR_NO = :OLD.RR_NO;
      ELSE
         UPDATE INV_JO_DR_HDR SET RR_PAID = GREATEST((RR_PAID - :OLD.AMOUNT), 0)
         WHERE  JO_DR_NO = :OLD.RR_NO;
      END IF;
   END IF;
END;

ALTER TRIGGER "TPJ"."ACC_AP_INV_DTL_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."CMS_VESS_CREW_ALLO_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON TPJ.CMS_VESS_CREW_ALLO
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

BEGIN
IF INSERTING THEN
INSERT INTO CMS_VESS_CREW_ALLO_AUDIT
      ( USER_ID          ,
        ACTION           ,
        NEW_VESS_CODE    ,
        NEW_VECR_SEQ_NO  ,
        NEW_ALLO_CODE    ,
        NEW_AMOUNT       ,
        NEW_CREATED_BY   ,
        NEW_DT_CREATED   ,
        NEW_MODIFIED_BY  ,
        NEW_DT_MODIFIED  )
VALUES (USER, 'I',
        :NEW.VESS_CODE  ,
        :NEW.VECR_SEQ_NO,
        :NEW.ALLO_CODE  ,
        :NEW.AMOUNT     ,
        :NEW.CREATED_BY ,
        :NEW.DT_CREATED ,
        :NEW.MODIFIED_BY,
        :NEW.DT_MODIFIED
        );
END IF;
IF UPDATING THEN
INSERT INTO CMS_VESS_CREW_ALLO_AUDIT
      ( USER_ID,ACTION,
        NEW_VESS_CODE    ,
        NEW_VECR_SEQ_NO  ,
        NEW_ALLO_CODE    ,
        NEW_AMOUNT       ,
        NEW_CREATED_BY   ,
        NEW_DT_CREATED   ,
        NEW_MODIFIED_BY  ,
        NEW_DT_MODIFIED  ,
        OLD_VESS_CODE    ,
        OLD_VECR_SEQ_NO  ,
        OLD_ALLO_CODE    ,
        OLD_AMOUNT       ,
        OLD_CREATED_BY   ,
        OLD_DT_CREATED   ,
        OLD_MODIFIED_BY  ,
        OLD_DT_MODIFIED)
VALUES (USER, 'U',
        :NEW.VESS_CODE    ,
        :NEW.VECR_SEQ_NO  ,
        :NEW.ALLO_CODE    ,
        :NEW.AMOUNT       ,
        :NEW.CREATED_BY   ,
        :NEW.DT_CREATED   ,
        :NEW.MODIFIED_BY  ,
        :NEW.DT_MODIFIED  ,
        :OLD.VESS_CODE    ,
        :OLD.VECR_SEQ_NO  ,
        :OLD.ALLO_CODE    ,
        :OLD.AMOUNT       ,
        :OLD.CREATED_BY   ,
        :OLD.DT_CREATED   ,
        :OLD.MODIFIED_BY  ,
        :OLD.DT_MODIFIED  );
END IF;
IF DELETING THEN
INSERT INTO CMS_VESS_CREW_ALLO_AUDIT
      ( USER_ID          ,
        ACTION           ,
        NEW_VESS_CODE    ,
        NEW_VECR_SEQ_NO  ,
        NEW_ALLO_CODE    ,
        NEW_AMOUNT       ,
        NEW_CREATED_BY   ,
        NEW_DT_CREATED   ,
        NEW_MODIFIED_BY  ,
        NEW_DT_MODIFIED  )
VALUES (USER, 'D',
        :OLD.VESS_CODE  ,
        :OLD.VECR_SEQ_NO,
        :OLD.ALLO_CODE  ,
        :OLD.AMOUNT     ,
        :OLD.CREATED_BY ,
        :OLD.DT_CREATED ,
        :OLD.MODIFIED_BY,
        :OLD.DT_MODIFIED
        );
END IF;
END;
ALTER TRIGGER "TPJ"."CMS_VESS_CREW_ALLO_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."CMS_VOYAGES_CONTRACT_TRG"
BEFORE DELETE OR INSERT OR UPDATE OF contract_text
ON TPJ.CMS_VOYAGES
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

BEGIN
   IF INSERTING THEN
      INSERT INTO CMS_VOYAGES_contract_audit
            (USER_ID, ACTION, ACTION_DT, VESS_CODE, VOYAGE_DATE, NEW_CONTRACT_TEXT)
      VALUES (USER, 'I', SYSDATE, :NEW.VESS_CODE, :NEW.VOYAGE_DATE, :NEW.CONTRACT_TEXT);
   END IF;
   IF UPDATING THEN
      INSERT INTO CMS_VOYAGES_contract_audit
            (USER_ID, ACTION, ACTION_DT, VESS_CODE, VOYAGE_DATE, NEW_CONTRACT_TEXT, OLD_CONTRACT_TEXT)
      VALUES (USER, 'U', SYSDATE, :OLD.VESS_CODE, :OLD.VOYAGE_DATE, :NEW.CONTRACT_TEXT, :OLD.CONTRACT_TEXT);
   END IF;
   IF DELETING THEN
      INSERT INTO CMS_VOYAGES_contract_audit
            (USER_ID, ACTION, ACTION_DT, VESS_CODE, VOYAGE_DATE, NEW_CONTRACT_TEXT)
      VALUES (USER, 'D', SYSDATE, :OLD.VESS_CODE, :OLD.VOYAGE_DATE, :OLD.CONTRACT_TEXT);
   END IF;
END;
ALTER TRIGGER "TPJ"."CMS_VOYAGES_CONTRACT_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."CMS_VOYAGE_CREW_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON TPJ.CMS_VOYAGE_CREW
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

BEGIN
   IF INSERTING THEN
      UPDATE PMS_EMPLOYEES
      SET    vess_code = :NEW.VOYA_VESS_CODE,
             latest_embarked = :NEW.DT_EMBARKED,
                         latest_rank_code = :NEW.rank_code
      WHERE  empl_id   = :NEW.EMPL_EMPL_ID
      AND    (latest_embarked IS NULL
      OR      latest_embarked < :NEW.DT_EMBARKED);
      INSERT INTO CMS_VOYAGE_CREW_AUDIT
            ( ACTION, USER_ID, NEW_VOYA_VESS_CODE, NEW_VOYA_VOYAGE_DATE, NEW_EMPL_EMPL_ID,
              NEW_CREATED_BY, NEW_DT_CREATED, NEW_MODIFIED_BY, NEW_DT_MODIFIED,
              NEW_RANK_CODE, NEW_TITLE, NEW_SEQ_NO, NEW_DT_EMBARKED, NEW_DT_DISEMBARKED,
              NEW_PASSENGER, NEW_BASIC_RATE, NEW_APPROVED, NEW_BASIC_RATE_G, NEW_TRAN_NO_EMBARKED,
              NEW_TRAN_NO_DISEMBARKED, NEW_ORIG_LIST, DT_CREATED, CREATED_BY )
      VALUES ('I', USER, :NEW.VOYA_VESS_CODE, :NEW.VOYA_VOYAGE_DATE, :NEW.EMPL_EMPL_ID,
              :NEW.CREATED_BY, :NEW.DT_CREATED, :NEW.MODIFIED_BY, :NEW.DT_MODIFIED,
              :NEW.RANK_CODE, :NEW.TITLE, :NEW.SEQ_NO, :NEW.DT_EMBARKED, :NEW.DT_DISEMBARKED,
              :NEW.PASSENGER, :NEW.BASIC_RATE, :NEW.APPROVED, :NEW.BASIC_RATE_G, :NEW.TRAN_NO_EMBARKED,
              :NEW.TRAN_NO_DISEMBARKED, :NEW.ORIG_LIST, sysdate, user);
   END IF;
   IF UPDATING THEN
      UPDATE PMS_EMPLOYEES
      SET    vess_code = :NEW.VOYA_VESS_CODE,
             latest_embarked = :NEW.DT_EMBARKED,
                         latest_rank_code = :NEW.rank_code
      WHERE  empl_id   = :NEW.EMPL_EMPL_ID
      AND    (latest_embarked IS NULL
      OR      latest_embarked < :NEW.DT_EMBARKED);
      INSERT INTO CMS_VOYAGE_CREW_AUDIT
            ( ACTION, USER_ID, NEW_VOYA_VESS_CODE, NEW_VOYA_VOYAGE_DATE, NEW_EMPL_EMPL_ID,
              NEW_CREATED_BY, NEW_DT_CREATED, NEW_MODIFIED_BY, NEW_DT_MODIFIED,
              NEW_RANK_CODE, NEW_TITLE, NEW_SEQ_NO, NEW_DT_EMBARKED, NEW_DT_DISEMBARKED,
              NEW_PASSENGER, NEW_BASIC_RATE, NEW_APPROVED, NEW_BASIC_RATE_G, NEW_TRAN_NO_EMBARKED,
              NEW_TRAN_NO_DISEMBARKED, OLD_VOYA_VESS_CODE, OLD_VOYA_VOYAGE_DATE, OLD_EMPL_EMPL_ID,
              OLD_CREATED_BY, OLD_DT_CREATED, OLD_MODIFIED_BY, OLD_DT_MODIFIED, OLD_RANK_CODE,
              OLD_TITLE, OLD_SEQ_NO, OLD_DT_EMBARKED, OLD_DT_DISEMBARKED, OLD_PASSENGER, OLD_BASIC_RATE,
              OLD_APPROVED, OLD_BASIC_RATE_G, OLD_TRAN_NO_EMBARKED, OLD_TRAN_NO_DISEMBARKED,
                          NEW_ORIG_LIST, OLD_ORIG_LIST, DT_CREATED, CREATED_BY )
      VALUES ('U', USER, :NEW.VOYA_VESS_CODE, :NEW.VOYA_VOYAGE_DATE, :NEW.EMPL_EMPL_ID,
              :NEW.CREATED_BY, :NEW.DT_CREATED, :NEW.MODIFIED_BY, :NEW.DT_MODIFIED,
              :NEW.RANK_CODE, :NEW.TITLE, :NEW.SEQ_NO, :NEW.DT_EMBARKED, :NEW.DT_DISEMBARKED,
              :NEW.PASSENGER, :NEW.BASIC_RATE, :NEW.APPROVED, :NEW.BASIC_RATE_G, :NEW.TRAN_NO_EMBARKED,
              :NEW.TRAN_NO_DISEMBARKED, :OLD.VOYA_VESS_CODE, :OLD.VOYA_VOYAGE_DATE,
              :OLD.EMPL_EMPL_ID, :OLD.CREATED_BY, :OLD.DT_CREATED, :OLD.MODIFIED_BY, :OLD.DT_MODIFIED,
              :OLD.RANK_CODE, :OLD.TITLE, :OLD.SEQ_NO, :OLD.DT_EMBARKED, :OLD.DT_DISEMBARKED,
              :OLD.PASSENGER, :OLD.BASIC_RATE, :OLD.APPROVED, :OLD.BASIC_RATE_G, :OLD.TRAN_NO_EMBARKED,
              :OLD.TRAN_NO_DISEMBARKED, :NEW.ORIG_LIST, :OLD.ORIG_LIST, sysdate, user);
   END IF;
   IF DELETING THEN
      INSERT INTO CMS_VOYAGE_CREW_AUDIT
            ( ACTION, USER_ID, NEW_VOYA_VESS_CODE, NEW_VOYA_VOYAGE_DATE, NEW_EMPL_EMPL_ID,
              NEW_CREATED_BY, NEW_DT_CREATED, NEW_MODIFIED_BY, NEW_DT_MODIFIED, NEW_RANK_CODE,
              NEW_TITLE, NEW_SEQ_NO, NEW_DT_EMBARKED, NEW_DT_DISEMBARKED, NEW_PASSENGER,
              NEW_BASIC_RATE, NEW_APPROVED, NEW_BASIC_RATE_G, NEW_TRAN_NO_EMBARKED,
              NEW_TRAN_NO_DISEMBARKED, NEW_ORIG_LIST, CREATED_BY, DT_CREATED)
      VALUES ('D', USER, :OLD.VOYA_VESS_CODE, :OLD.VOYA_VOYAGE_DATE, :OLD.EMPL_EMPL_ID,
              :OLD.CREATED_BY, :OLD.DT_CREATED, :OLD.MODIFIED_BY, :OLD.DT_MODIFIED, :OLD.RANK_CODE,
              :OLD.TITLE, :OLD.SEQ_NO, :OLD.DT_EMBARKED, :OLD.DT_DISEMBARKED, :OLD.PASSENGER,
              :OLD.BASIC_RATE, :OLD.APPROVED, :OLD.BASIC_RATE_G, :OLD.TRAN_NO_EMBARKED,
              :OLD.TRAN_NO_DISEMBARKED, :OLD.ORIG_LIST, sysdate, user);
   END IF;
END;

ALTER TRIGGER "TPJ"."CMS_VOYAGE_CREW_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_CATEGORIES_TRG"
BEFORE INSERT or UPDATE
ON INV_CATEGORIES
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   if nvl(:old.approver, 'x')  <> nvl(:new.approver, 'y') then
      insert into inv_categories_log
             (code, approver, new_approver, created_by, dt_created)
      values (:new.code, :old.approver, :new.approver, user, sysdate);
   end if;
EXCEPTION
   when dup_val_on_index then null;
END inv_categories_trg;

ALTER TRIGGER "TPJ"."INV_CATEGORIES_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_DR_AP"
BEFORE UPDATE
OF AP_NO
ON TPJ.INV_DR_HDR
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
BEGIN
   insert into acc_ap_inv_dtl_log( userid ,ref_dt , ap_no , old_ap_no, dr_no, inv_type)
   values (user, sysdate, :new.ap_no, :old.ap_no, :new.dr_no, 'DR');
END ;

ALTER TRIGGER "TPJ"."INV_DR_AP" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_DR_HDR_INS_TRG"
BEFORE INSERT
ON INV_DR_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   declare
      vRSNO Varchar2(30);
   begin
      select rshd_rs_no
      into   vRSNO
      from   inv_po_hdr
      where  po_no = :NEW.pohd_po_no;
      :NEW.ofc_code := sf_get_rs_ofc(vRSNO);
   exception
      when no_data_found then :NEW.ofc_code := 'HO';
   end;
END;

ALTER TRIGGER "TPJ"."INV_DR_HDR_INS_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_DR_HDR_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON INV_DR_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  vErrMsg Varchar2(2000);
  dBegBal Date;
  bOK     Boolean;
BEGIN
   IF :NEW.STATUS = 'POSTED' AND :OLD.STATUS <> 'POSTED' THEN
      DECLARE
         nPOcpa INV_PO_HDR.cpa_bal%TYPE;
      BEGIN
         SELECT cpa_bal
         INTO   nPOcpa
         FROM   INV_PO_HDR
         WHERE  po_no = :NEW.pohd_po_no;
         IF nPOcpa >= :NEW.RR_amt THEN
            :NEW.cpa_amt := :NEW.RR_amt;
         ELSE
            :NEW.cpa_amt := nPOcpa;
         END IF;
         UPDATE INV_PO_HDR
         SET    cpa_bal = cpa_bal - :NEW.cpa_amt
         WHERE  po_no = :NEW.pohd_po_no;
      END;
      BEGIN
         INSERT INTO INV_WSM_RR (RR_NO, DOWNLOADED, DT_CREATED) VALUES (:NEW.DR_NO, 'N', sysdate);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

      BEGIN
         INSERT INTO INV_WSM_RR_RS (RR_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.DR_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_DR_DTL
         WHERE  DRHD_DR_NO = :NEW.DR_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

      IF :NEW.ofc_code = 'HO' then
            for i in (SELECT drdt.item_code, drdt.cate_code
                             , drdt.itty_code, drdt.itgr_code, drdt.uome_code
                             , decode (rehd.for_stock, 'Y', drdt.qty, 0) qty
                             , decode (rehd.for_stock, 'N', drdt.qty, 0) qty_alloc
                             , drdt.currency, drdt.unit_cost
                             , drdt.unit_cost * :NEW.curr_cnv unit_cost_php
                             , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                      FROM   inv_dr_dtl drdt, inv_reqslip_hdr rehd
                      WHERE  drdt.drhd_dr_no = :NEW.dr_no
                      AND    drdt.rshd_rs_no = rehd.rs_no)
            loop
               BEGIN
                  bOK := FALSE;
                  if i.qty > 0 and i.qty_alloc = 0 then
                     dBegBal := sf_get_begbal_dt(:NEW.ofc_code, 'BEG_BAL', i.item_code, i.uome_code, sysdate);
                     if dBegBal is not null and dBegBal <= sysdate then
                        bOK := TRUE;
                     end if;
                  end if;
                  if i.qty = 0 and i.qty_alloc > 0 then
                     bOK := TRUE;
                  end if;
                  if bOK then
                     INSERT INTO inv_stocks
                            (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                             qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
                     VALUES ('DR', :NEW.dr_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                              i.qty, i.qty_alloc, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.supp_code, :NEW.ofc_code );
                  else
                     INSERT INTO inv_stocks_history
                            (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                             qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
                     VALUES ('DR', :NEW.dr_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                              i.qty, i.qty_alloc, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.supp_code, :NEW.ofc_code );
                  end if;
               EXCEPTION
                  WHEN OTHERS THEN
                     vErrMsg := SQLERRM;
                     insert into debug_log values ('INV_DR_HDR_TRG', :NEW.dr_no, vErrMsg, sysdate);
               END;
            end loop;
       ELSE
         BEGIN
            INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
            SELECT 'DR', :NEW.dr_no ref_no, drdt.item_code, drdt.cate_code
                   , drdt.itty_code, drdt.itgr_code, drdt.uome_code
                   , decode (rehd.for_stock, 'Y', drdt.qty, 0) qty
                   , decode (rehd.for_stock, 'N', drdt.qty, 0) qty_alloc
                   , drdt.currency, drdt.unit_cost
                   , drdt.unit_cost * :NEW.curr_cnv unit_cost_php
                   , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                   , :NEW.supp_code "REFERENCE"
                   , :NEW.ofc_code
            FROM   inv_dr_dtl drdt, inv_reqslip_hdr rehd
            WHERE  drdt.drhd_dr_no = :NEW.dr_no
            AND    drdt.rshd_rs_no = rehd.rs_no;
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_DR_HDR_TRG', :NEW.dr_no, vErrMsg, sysdate);
         END;
       END IF;

   END IF;

   IF :NEW.STATUS = 'CANCELLED' AND :OLD.STATUS = 'POSTED' THEN
      UPDATE INV_PO_HDR
      SET   cpa_bal = cpa_bal + :NEW.cpa_amt
      WHERE  po_no = :NEW.pohd_po_no;

      -- add removal from bincard
      IF :NEW.ofc_code = 'HO' then
            for i in (SELECT drdt.item_code, drdt.cate_code
                             , drdt.itty_code, drdt.itgr_code, drdt.uome_code
                             , decode (rehd.for_stock, 'Y', drdt.qty, 0) qty
                             , decode (rehd.for_stock, 'N', drdt.qty, 0) qty_alloc
                             , drdt.currency, drdt.unit_cost
                             , drdt.unit_cost * :NEW.curr_cnv unit_cost_php
                             , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                      FROM   inv_dr_dtl drdt, inv_reqslip_hdr rehd
                      WHERE  drdt.drhd_dr_no = :NEW.dr_no
                      AND    drdt.rshd_rs_no = rehd.rs_no)
            loop
               BEGIN
                  if i.qty > 0 and i.qty_alloc = 0 then
                     UPDATE inv_stocks
                     SET    qty = 0
                     WHERE  tran_type = 'DR'
                     AND    ref_no = :NEW.dr_no
                     AND    item_code = i.item_code
                     AND    uome_code = i.item_code
                     AND    qty = i.qty
                     AND    reference = :NEW.supp_code
                     AND    ofc_code = :NEW.ofc_code;
                     UPDATE inv_stocks_history
                     SET    qty = 0
                     WHERE  tran_type = 'DR'
                     AND    ref_no = :NEW.dr_no
                     AND    item_code = i.item_code
                     AND    uome_code = i.item_code
                     AND    qty = i.qty
                     AND    reference = :NEW.supp_code
                     AND    ofc_code = :NEW.ofc_code;
                  end if;
                  if i.qty = 0 and i.qty_alloc > 0 then
                     UPDATE inv_stocks
                     SET    qty_alloc = 0
                     WHERE  tran_type = 'DR'
                     AND    ref_no = :NEW.dr_no
                     AND    item_code = i.item_code
                     AND    uome_code = i.item_code
                     AND    qty = i.qty
                     AND    reference = :NEW.supp_code
                     AND    ofc_code = :NEW.ofc_code;

                     UPDATE inv_stocks_history
                     SET    qty_alloc = 0
                     WHERE  tran_type = 'DR'
                     AND    ref_no = :NEW.dr_no
                     AND    item_code = i.item_code
                     AND    uome_code = i.item_code
                     AND    qty = i.qty
                     AND    reference = :NEW.supp_code
                     AND    ofc_code = :NEW.ofc_code;
                  end if;
               EXCEPTION
                  WHEN OTHERS THEN
                     vErrMsg := SQLERRM;
                     insert into debug_log values ('INV_DR_HDR_TRG -> Cancelled', :NEW.dr_no, vErrMsg, sysdate);
               END;
            end loop;
       ELSE
         BEGIN
            INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
            SELECT 'DR', :NEW.dr_no ref_no, drdt.item_code, drdt.cate_code
                   , drdt.itty_code, drdt.itgr_code, drdt.uome_code
                   , decode (rehd.for_stock, 'Y', drdt.qty, 0) qty
                   , decode (rehd.for_stock, 'N', drdt.qty, 0) qty_alloc
                   , drdt.currency, drdt.unit_cost
                   , drdt.unit_cost * :NEW.curr_cnv unit_cost_php
                   , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                   , :NEW.supp_code "REFERENCE"
                   , :NEW.ofc_code
            FROM   inv_dr_dtl drdt, inv_reqslip_hdr rehd
            WHERE  drdt.drhd_dr_no = :NEW.dr_no
            AND    drdt.rshd_rs_no = rehd.rs_no;
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_DR_HDR_TRG', :NEW.dr_no, vErrMsg, sysdate);
         END;
       END IF;
   END IF;

   IF :NEW.STATUS = 'FOR APPROVAL' AND :OLD.STATUS = 'POSTED' THEN
      UPDATE INV_PO_HDR
      SET   cpa_bal = cpa_bal + :NEW.cpa_amt
      WHERE  po_no = :NEW.pohd_po_no;
      :NEW.cpa_amt := 0;
   END IF;

   IF :NEW.STATUS = 'POSTED' AND :OLD.STATUS <> 'POSTED' THEN
      DECLARE
         nPOcpa INV_PO_HDR.cpa_bal%TYPE;
      BEGIN
         SELECT cpa_bal
         INTO   nPOcpa
         FROM   INV_PO_HDR
         WHERE  po_no = :NEW.pohd_po_no;
         IF nPOcpa >= :NEW.RR_amt THEN
            :NEW.cpa_amt := :NEW.RR_amt;
         ELSE
            :NEW.cpa_amt := nPOcpa;
         END IF;
         UPDATE INV_PO_HDR
         SET    cpa_bal = cpa_bal - :NEW.cpa_amt
         WHERE  po_no = :NEW.pohd_po_no;
      END;
      BEGIN
         INSERT INTO INV_WSM_RR (RR_NO, DOWNLOADED, DT_CREATED) VALUES (:NEW.DR_NO, 'N', sysdate);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

      BEGIN
         INSERT INTO INV_WSM_RR_RS (RR_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.DR_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_DR_DTL
         WHERE  DRHD_DR_NO = :NEW.DR_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;

   IF (:NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED') OR
      (:NEW.STATUS = 'DISAPPROVED' AND :OLD.STATUS <> 'DISAPPROVED')
   THEN
      BEGIN
         INSERT INTO INV_WSM_RR_RS_CANCELLED (RR_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.DR_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_DR_DTL
         WHERE  DRHD_DR_NO = :NEW.DR_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
END;

ALTER TRIGGER "TPJ"."INV_DR_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_ISS_HDR_INS_TRG"
BEFORE INSERT
ON INV_ISS_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   :NEW.ofc_code := sf_get_rs_ofc(:NEW.rshd_rs_no);
END;

ALTER TRIGGER "TPJ"."INV_ISS_HDR_INS_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_ISS_HDR_TRG"
BEFORE UPDATE ON INV_ISS_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  vErrMsg Varchar2(2000);
  dBegBal Date;
  bOK     Boolean;
BEGIN

   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
      BEGIN
         INSERT INTO INV_WSM_ISS (ISS_NO, DOWNLOADED, DT_CREATED) VALUES (:NEW.ISS_NO, 'N', sysdate);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

      BEGIN
         INSERT INTO INV_WSM_IS_RS (ISS_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.ISS_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_ISS_DTL
         WHERE  ISHD_ISS_NO = :NEW.ISS_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

      IF :NEW.ofc_code = 'HO' then
            for i in (SELECT isdt.item_code, isdt.cate_code, isdt.itty_code
                            , isdt.itgr_code, isdt.uome_code
                            , decode (rehd.for_stock, 'Y', isdt.iss_qty, 0) qty
                            , decode (rehd.for_stock, 'N', isdt.iss_qty, 0) qty_alloc
                            , drdt.currency
                            , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
                            , isdt.ref_no
                            , isdt.ref_type
                      FROM   inv_iss_dtl isdt, inv_dr_dtl drdt, inv_dr_hdr drhd, inv_reqslip_hdr rehd
                      WHERE  isdt.ishd_iss_no = :NEW.iss_no
                      AND    isdt.ref_type = 'DR'
                      AND    isdt.ref_no = drdt.drhd_dr_no
                      AND    drhd.dr_no = drdt.drhd_dr_no
                      AND    drdt.item_code = isdt.item_code
                      AND    drdt.cate_code = isdt.cate_code
                      AND    drdt.itty_code = isdt.itty_code
                      AND    drdt.itgr_code = isdt.itgr_code
                      AND    drdt.uome_code = isdt.uome_code
                      AND    drdt.rshd_rs_no = rehd.rs_no)
            loop
               BEGIN
                  bOK := FALSE;
                  if i.qty > 0 and i.qty_alloc = 0 then
                     dBegBal := sf_get_begbal_dt(:NEW.ofc_code, 'BEG_BAL', i.item_code, i.uome_code, sysdate);
                     if dBegBal is not null and dBegBal <= sysdate then
                        bOK := TRUE;
                     end if;
                  end if;
                  if i.qty = 0 and i.qty_alloc > 0 then
                     dBegBal := sf_get_begbal_dt(:NEW.ofc_code, 'DR', i.item_code, i.uome_code, sysdate);
                     if dBegBal is not null and dBegBal <= sysdate then
                        bOK := TRUE;
                     end if;
                  end if;
                  if bOK then
                     INSERT INTO inv_stocks
                            (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                             qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                             ofc_code, dr_ref_no, dr_ref_type)
                     VALUES ('ISS', :NEW.iss_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                             i.qty, i.qty_alloc, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.vess_code,
                             :NEW.ofc_code, i.ref_no, i.ref_type);
                  else
                     INSERT INTO inv_stocks_history
                            (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                             qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                             ofc_code, dr_ref_no, dr_ref_type)
                     VALUES ('ISS', :NEW.iss_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                             i.qty, i.qty_alloc, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.vess_code,
                             :NEW.ofc_code, i.ref_no, i.ref_type);
                  end if;
               EXCEPTION
                  WHEN OTHERS THEN
                     vErrMsg := SQLERRM;
                     insert into debug_log values ('INV_ISS_HDR_TRG', :NEW.iss_no || ' : ref_type = ''DR''', vErrMsg, sysdate);
               END;
         end loop;

         for i in (SELECT isdt.item_code, isdt.cate_code, isdt.itty_code, isdt.itgr_code, isdt.uome_code
                        , isdt.iss_qty qty, iware.currency, iware.unit_cost, iware.unit_cost unit_cost_php
                        , isdt.ref_no, isdt.ref_type
                   FROM   inv_iss_dtl isdt, inv_item_ware iware
                   WHERE  isdt.ishd_iss_no = :NEW.iss_no
                   AND    isdt.item_code = iware.item_code
                   AND    isdt.cate_code = iware.cate_code
                   AND    isdt.itty_code = iware.itty_code
                   AND    isdt.itgr_code = iware.itgr_code
                   AND    isdt.uome_code = iware.uome_code
                   AND    isdt.rshd_rs_no <> 'M000000'
                   AND    isdt.ref_type = 'WR'
                   AND    isdt.ref_no = iware.ware_code
                   AND    isdt.dr_no = iware.dr_no
                   AND    isdt.dr_no = 'STOCK')
         loop
            BEGIN
               bOK := FALSE;
               if i.qty > 0 then
                  dBegBal := sf_get_begbal_dt(:NEW.ofc_code, 'BEG_BAL', i.item_code, i.uome_code, sysdate);
                  if dBegBal is not null and dBegBal <= sysdate then
                     bOK := TRUE;
                  end if;
               end if;
               if bOK then
                    INSERT INTO inv_stocks
                            (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                             qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                             ofc_code, dr_ref_no, dr_ref_type)
                     VALUES ('ISS', :NEW.iss_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                             i.qty, 0, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.vess_code,
                             :NEW.ofc_code, i.ref_no, i.ref_type);
               else
                    INSERT INTO inv_stocks_history
                            (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                             qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                             ofc_code, dr_ref_no, dr_ref_type)
                     VALUES ('ISS', :NEW.iss_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                             i.qty, 0, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.vess_code,
                             :NEW.ofc_code, i.ref_no, i.ref_type);

               end if;
            EXCEPTION
               WHEN OTHERS THEN
                  vErrMsg := SQLERRM;
                  insert into debug_log values ('INV_ISS_HDR_TRG', :NEW.iss_no || ' : isdt.rshd_rs_no <> ''M000000''', vErrMsg, sysdate);
            END;
         end loop;

         for i in (SELECT isdt.item_code, isdt.cate_code, isdt.itty_code, isdt.itgr_code, isdt.uome_code
                        , isdt.iss_qty qty, iware.currency, nvl(drdt.unit_cost,0) unit_cost
                        , nvl(drdt.unit_cost,0) * nvl(drdt.curr_cnv,0) unit_cost_php
                        , isdt.ref_no, isdt.ref_type
                   FROM   inv_iss_dtl isdt
                        , inv_item_ware iware
                        , inv_dr_vw drdt
                   WHERE  isdt.ishd_iss_no = :NEW.iss_no
                   AND    isdt.item_code = iware.item_code
                   AND    isdt.cate_code = iware.cate_code
                   AND    isdt.itty_code = iware.itty_code
                   AND    isdt.itgr_code = iware.itgr_code
                   AND    isdt.uome_code = iware.uome_code
                   AND    isdt.ref_type = 'WR'
                   AND    isdt.ref_no = iware.ware_code
                   AND    isdt.dr_no = iware.dr_no
                   AND    isdt.dr_no <> 'STOCK'
                   AND    iware.item_code = drdt.item_code (+)
                   AND    iware.cate_code = drdt.cate_code (+)
                   AND    iware.itty_code = drdt.itty_code (+)
                   AND    iware.itgr_code = drdt.itgr_code (+)
                   AND    iware.uome_code = drdt.uome_code (+)
                   AND    iware.dr_no = drdt.dr_no (+))
         loop
            BEGIN
               bOK := FALSE;
               if i.qty > 0 then
                  dBegBal := sf_get_begbal_dt(:NEW.ofc_code, 'BEG_BAL', i.item_code, i.uome_code, sysdate);
                  if dBegBal is not null and dBegBal <= sysdate then
                     bOK := TRUE;
                  end if;
               end if;
               if bOK then
                  INSERT INTO inv_stocks
                         (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                          qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                          ofc_code, dr_ref_no, dr_ref_type)
                  VALUES ('ISS', :NEW.iss_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                          i.qty, 0, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.vess_code,
                          :NEW.ofc_code, i.ref_no, i.ref_type);
               else
                  INSERT INTO inv_stocks_history
                         (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                          qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                          ofc_code, dr_ref_no, dr_ref_type)
                  VALUES ('ISS', :NEW.iss_no, i.item_code, i.cate_code, i.itty_code, i.itgr_code, i.uome_code,
                          i.qty, 0, i.currency, i.unit_cost, i.unit_cost_php, sysdate, :NEW.vess_code,
                          :NEW.ofc_code, i.ref_no, i.ref_type);
               end if;
            EXCEPTION
               WHEN OTHERS THEN
                  vErrMsg := SQLERRM;
                  insert into debug_log values ('INV_ISS_HDR_TRG', :NEW.iss_no || ' : isdt.ref_type = ''WR''', vErrMsg, sysdate);
            END;
         end loop;


       ELSE
         BEGIN
            INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                                           ofc_code, dr_ref_no, dr_ref_type)
            SELECT 'ISS', :NEW.iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
                  , isdt.itgr_code, isdt.uome_code
                  , decode (rehd.for_stock, 'Y', isdt.iss_qty, 0) qty
                  , decode (rehd.for_stock, 'N', isdt.iss_qty, 0) qty_alloc
                  , drdt.currency
                  , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
                  , sysdate -- :NEW.dt_modified dt_created
                  , :NEW.vess_code
                  , :NEW.ofc_code
                  , isdt.ref_no
                 , isdt.ref_type
            FROM   inv_iss_dtl isdt, inv_dr_dtl drdt, inv_dr_hdr drhd, inv_reqslip_hdr rehd
            WHERE  isdt.ishd_iss_no = :NEW.iss_no
            AND    isdt.ref_type = 'DR'
            AND    isdt.ref_no = drdt.drhd_dr_no
            AND    drhd.dr_no = drdt.drhd_dr_no
            AND    drdt.item_code = isdt.item_code
            AND    drdt.cate_code = isdt.cate_code
            AND    drdt.itty_code = isdt.itty_code
            AND    drdt.itgr_code = isdt.itgr_code
            AND    drdt.uome_code = isdt.uome_code
            AND    drdt.rshd_rs_no = rehd.rs_no;
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_ISS_HDR_TRG', :NEW.iss_no || ' : isdt.ref_type = ''DR''', vErrMsg, sysdate);
         END;

         BEGIN
            INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                                           ofc_code, dr_ref_no, dr_ref_type)
            SELECT 'ISS', :NEW.iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
                 , isdt.itgr_code, isdt.uome_code
                 , isdt.iss_qty qty
                 , 0 qty_alloc
                 , iware.currency
                 , iware.unit_cost, iware.unit_cost unit_cost_php
                 , sysdate -- nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                 , :NEW.vess_code
                 , :NEW.ofc_code
                 , isdt.ref_no
                 , isdt.ref_type
            FROM   inv_iss_dtl isdt, inv_item_ware iware
            WHERE  isdt.ishd_iss_no = :NEW.iss_no
            AND    isdt.item_code = iware.item_code
            AND    isdt.cate_code = iware.cate_code
            AND    isdt.itty_code = iware.itty_code
            AND    isdt.itgr_code = iware.itgr_code
            AND    isdt.uome_code = iware.uome_code
            AND    isdt.rshd_rs_no <> 'M000000'
            AND    isdt.ref_type = 'WR'
            AND    isdt.ref_no = iware.ware_code
            AND    isdt.dr_no = iware.dr_no
            AND    isdt.dr_no = 'STOCK';
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_ISS_HDR_TRG', :NEW.iss_no || ' : isdt.rshd_rs_no <> ''M000000''', vErrMsg, sysdate);
         END;

         BEGIN
            INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference,
                                           ofc_code, dr_ref_no, dr_ref_type)
            SELECT 'ISS', :NEW.iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
                 , isdt.itgr_code, isdt.uome_code
                 , isdt.iss_qty qty
                 , 0 qty_alloc
                 , iware.currency
                 , nvl(drdt.unit_cost,0) unit_cost
                 , nvl(drdt.unit_cost,0) * nvl(drdt.curr_cnv,0) unit_cost_php
                 , sysdate -- nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                 , :NEW.vess_code
                 , :NEW.ofc_code
                 , isdt.ref_no
                 , isdt.ref_type
            FROM   inv_iss_dtl isdt
                 , inv_item_ware iware
                 , inv_dr_vw drdt
            WHERE  isdt.ishd_iss_no = :NEW.iss_no
            AND    isdt.item_code = iware.item_code
            AND    isdt.cate_code = iware.cate_code
            AND    isdt.itty_code = iware.itty_code
            AND    isdt.itgr_code = iware.itgr_code
            AND    isdt.uome_code = iware.uome_code
            AND    isdt.ref_type = 'WR'
            AND    isdt.ref_no = iware.ware_code
            AND    isdt.dr_no = iware.dr_no
            AND    isdt.dr_no <> 'STOCK'
            AND    iware.item_code = drdt.item_code (+)
            AND    iware.cate_code = drdt.cate_code (+)
            AND    iware.itty_code = drdt.itty_code (+)
            AND    iware.itgr_code = drdt.itgr_code (+)
            AND    iware.uome_code = drdt.uome_code (+)
            AND    iware.dr_no = drdt.dr_no (+) ;
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_ISS_HDR_TRG', :NEW.iss_no || ' : isdt.ref_type = ''WR''', vErrMsg, sysdate);
         END;

       END IF;

       -- correct allocated issuance with no receiving...
       sp_chk_begbal_negative_stocks();

   END IF;

   IF :NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED' THEN
      BEGIN
         INSERT INTO INV_WSM_ISS_CANCEL (ISS_NO, DOWNLOADED, DT_CREATED) VALUES (:NEW.ISS_NO, 'N', sysdate);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;

   IF (:NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED') OR
      (:NEW.STATUS = 'DISAPPROVED' AND :OLD.STATUS <> 'DISAPPROVED')
   THEN
      BEGIN
         INSERT INTO INV_WSM_IS_RS_CANCELLED (ISS_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.ISS_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_ISS_DTL
         WHERE  ISHD_ISS_NO = :NEW.ISS_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
END;

ALTER TRIGGER "TPJ"."INV_ISS_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_ITEMS_TRG"
BEFORE INSERT
ON INV_ITEMS
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   BEGIN
      INSERT INTO INV_WSM_ITEMS VALUES (:NEW.CODE, :NEW.CATE_CODE, :NEW.ITTY_CODE, :NEW.ITGR_CODE, 'N', sysdate, null);
   EXCEPTION
      WHEN OTHERS THEN NULL;
   END;
END;

ALTER TRIGGER "TPJ"."INV_ITEMS_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_ITEM_WARE_BEGBAL_TRG"
BEFORE UPDATE ON inv_item_ware_begbal
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  vErrMsg Varchar2(2000);
  vChk    Number;
BEGIN
   IF :NEW.posted_dt is not null AND :OLD.posted_dt is null THEN
      BEGIN
         IF :NEW.ware_code <> '00004' THEN
            select count(1) into vChk
            from   inv_stocks
            where  tran_type = 'BEG_BAL'
            and    item_code = :NEW.item_code
            and    uome_code = :NEW.uome_code
            and    cate_code = :NEW.cate_code
            and    itty_code = :NEW.itty_code
            and    itgr_code = :NEW.itgr_code
            and    reference = :NEW.ware_code;
         ELSE
            select count(1) into vChk
            from   inv_stocks_gensan
            where  tran_type = 'BEG_BAL'
            and    item_code = :NEW.item_code
            and    uome_code = :NEW.uome_code
            and    cate_code = :NEW.cate_code
            and    itty_code = :NEW.itty_code
            and    itgr_code = :NEW.itgr_code
            and    reference = :NEW.ware_code;
         END IF;
         IF vChk = 0 THEN
            IF :NEW.ware_code <> '00004' THEN
               INSERT INTO inv_stocks (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                       qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created,
                                       reference, ofc_code)
               VALUES ('BEG_BAL', '000000', :NEW.item_code, :NEW.cate_code, :NEW.itty_code, :NEW.itgr_code, :NEW.uome_code,
                                       :NEW.qty, :NEW.qty_alloc, 'PHP', 0, 0, :NEW.posted_dt,
                                       :NEW.ware_code, 'HO' );
            ELSE
               INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                       qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created,
                                       reference, ofc_code)
               VALUES ('BEG_BAL', '000000', :NEW.item_code, :NEW.cate_code, :NEW.itty_code, :NEW.itgr_code, :NEW.uome_code,
                                       :NEW.qty, :NEW.qty_alloc, 'PHP', 0, 0, :NEW.posted_dt,
                                       :NEW.ware_code, 'GENSAN' );
            END IF;
         ELSE
            IF :NEW.ware_code <> '00004' THEN
               UPDATE inv_stocks
               SET    qty       = :NEW.qty,
                      qty_alloc = :NEW.qty_alloc
               where  tran_type = 'BEG_BAL'
               and    item_code = :NEW.item_code
               and    uome_code = :NEW.uome_code
               and    cate_code = :NEW.cate_code
               and    itty_code = :NEW.itty_code
               and    itgr_code = :NEW.itgr_code
               and    reference = :NEW.ware_code;
            ELSE
               UPDATE inv_stocks_gensan
               SET    qty       = :NEW.qty,
                      qty_alloc = :NEW.qty_alloc
               where  tran_type = 'BEG_BAL'
               and    item_code = :NEW.item_code
               and    uome_code = :NEW.uome_code
               and    cate_code = :NEW.cate_code
               and    itty_code = :NEW.itty_code
               and    itgr_code = :NEW.itgr_code
               and    reference = :NEW.ware_code;
            END IF;
         END IF;
      EXCEPTION
         WHEN OTHERS THEN
            vErrMsg := SQLERRM;
            insert into debug_log values ('INV_ITEM_WARE_BEGBAL_TRG', :NEW.item_code, vErrMsg, sysdate);
      END;
   END IF;
END;



ALTER TRIGGER "TPJ"."INV_ITEM_WARE_BEGBAL_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_JODR_AP"
BEFORE UPDATE
OF AP_NO
ON TPJ.INV_JO_DR_HDR
REFERENCING NEW AS New OLD AS Old
FOR EACH ROW
DECLARE
BEGIN
   insert into acc_ap_inv_dtl_log( userid ,ref_dt , ap_no , old_ap_no, dr_no, inv_type)
   values (user, sysdate, :new.ap_no, :old.ap_no, :new.jo_dr_no, 'JODR');
END ;
ALTER TRIGGER "TPJ"."INV_JODR_AP" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_JOISS_HDR_TRG"
BEFORE INSERT
ON inv_joiss_hdr
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
      BEGIN
         INSERT INTO INV_WSM_JO_ISS VALUES (:NEW.JOISS_NO, 'N', sysdate, null);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
   IF :NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED' THEN
      BEGIN
         INSERT INTO INV_WSM_JO_ISS_CANCEL VALUES (:NEW.JOISS_NO, 'N', sysdate, null);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
END;
ALTER TRIGGER "TPJ"."INV_JOISS_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_JO_DR_HDR_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON INV_JO_DR_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
      DECLARE
        nPOcpa INV_JO_HDR.cpa_bal%TYPE;
      BEGIN
        SELECT cpa_bal
        INTO   nPOcpa
        FROM   INV_JO_HDR
        WHERE  jo_no = :NEW.johd_jo_no;
        IF nPOcpa >= :NEW.RR_amt THEN
           :NEW.cpa_amt := :NEW.RR_amt;
        ELSE
           :NEW.cpa_amt := nPOcpa;
        END IF;
        UPDATE INV_JO_HDR
        SET    cpa_bal = cpa_bal - :NEW.cpa_amt
        WHERE  jo_no = :NEW.johd_jo_no;
      END;

      BEGIN
         INSERT INTO INV_WSM_JO_RR VALUES (:NEW.JO_DR_NO, 'N', sysdate, null);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

   END IF;
   IF :NEW.STATUS = 'CANCELLED' THEN
     UPDATE INV_JO_HDR
     SET   cpa_bal = cpa_bal + :NEW.cpa_amt
     WHERE  jo_no = :NEW.johd_jo_no;
   END IF;
END;



ALTER TRIGGER "TPJ"."INV_JO_DR_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_PO_HDR_TRG"
BEFORE UPDATE ON INV_PO_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
      BEGIN
         INSERT INTO INV_WSM_PO (PO_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.PO_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_PO_DTL
         WHERE  POHD_PO_NO = :NEW.PO_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
   IF (:NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED') OR
      (:NEW.STATUS = 'DISAPPROVED' AND :OLD.STATUS <> 'DISAPPROVED')
   THEN
      BEGIN
         INSERT INTO INV_WSM_PO_CANCELLED (PO_NO, RS_NO, EMAIL_SENT, DT_CREATED)
         SELECT :NEW.PO_NO, RSHD_RS_NO, 'N', sysdate
         FROM   INV_PO_DTL
         WHERE  POHD_PO_NO = :NEW.PO_NO
         GROUP BY RSHD_RS_NO;
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
END;
ALTER TRIGGER "TPJ"."INV_PO_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_REQSLIP_DTL_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON INV_REQSLIP_DTL REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF INSERTING THEN
      INSERT INTO   INV_REQSLIP_DTL_LOG(
      ACTION_TAG         ,
      CREATED_BY         ,
      DT_CREATED         ,
      RSHD_RS_NO         ,
      ITTY_CODE          ,
      CATE_CODE          ,
      ITGR_CODE          ,
      ITEM_CODE          ,
      STATUS             ,
      QTY                ,
      APPROVED_QTY       ,
      UNIT_COST          ,
      TOTAL_COST         ,
      UOME_CODE          ,
      REMARKS            ,
      MODIFIED_BY        ,
      DT_MODIFIED        ,
      LPO_COST           ,
      LPO_CURRENCY       ,
      STOCK              ,
      CSHD_CS_NO         ,
      POHD_PO_NO         ,
      ISS_QTY            ,
      OLD_RS             ,
      NEW_RS             ,
      RR_QTY             ,
      WARE_CODE          ,
      CLR_RS_ITEM        ,
      STOCK_QTY          ,
      STOCK_ISS_QTY      ,
      WITH_STOCK         )
      VALUES (
      'INSERT',
      USER         ,
      SYSDATE         ,
      :NEW.RSHD_RS_NO         ,
      :NEW.ITTY_CODE          ,
      :NEW.CATE_CODE          ,
      :NEW.ITGR_CODE          ,
      :NEW.ITEM_CODE          ,
      :NEW.STATUS             ,
      :NEW.QTY                ,
      :NEW.APPROVED_QTY       ,
      :NEW.UNIT_COST          ,
      :NEW.TOTAL_COST         ,
      :NEW.UOME_CODE          ,
      :NEW.REMARKS            ,
      :NEW.MODIFIED_BY        ,
      :NEW.DT_MODIFIED        ,
      :NEW.LPO_COST           ,
      :NEW.LPO_CURRENCY       ,
      :NEW.STOCK              ,
      :NEW.CSHD_CS_NO         ,
      :NEW.POHD_PO_NO         ,
      :NEW.ISS_QTY            ,
      :NEW.OLD_RS             ,
      :NEW.NEW_RS             ,
      :NEW.RR_QTY             ,
      :NEW.WARE_CODE          ,
      :NEW.CLR_RS_ITEM        ,
      :NEW.STOCK_QTY          ,
      :NEW.STOCK_ISS_QTY      ,
      :NEW.WITH_STOCK         );



   END IF;
   IF UPDATING THEN
      INSERT INTO   INV_REQSLIP_DTL_LOG(
      ACTION_TAG         ,
      CREATED_BY         ,
      DT_CREATED         ,
      RSHD_RS_NO         ,
      ITTY_CODE          ,
      CATE_CODE          ,
      ITGR_CODE          ,
      ITEM_CODE          ,
      STATUS             ,
      QTY                ,
      APPROVED_QTY       ,
      UNIT_COST          ,
      TOTAL_COST         ,
      UOME_CODE          ,
      REMARKS            ,
      MODIFIED_BY        ,
      DT_MODIFIED        ,
      LPO_COST           ,
      LPO_CURRENCY       ,
      STOCK              ,
      CSHD_CS_NO         ,
      POHD_PO_NO         ,
      ISS_QTY            ,
      OLD_RS             ,
      NEW_RS             ,
      RR_QTY             ,
      WARE_CODE          ,
      CLR_RS_ITEM        ,
      STOCK_QTY          ,
      STOCK_ISS_QTY      ,
      WITH_STOCK         ,
      OLD_RSHD_RS_NO         ,
      OLD_ITTY_CODE          ,
      OLD_CATE_CODE          ,
      OLD_ITGR_CODE          ,
      OLD_ITEM_CODE          ,
      OLD_STATUS             ,
      OLD_QTY                ,
      OLD_APPROVED_QTY       ,
      OLD_UNIT_COST          ,
      OLD_TOTAL_COST         ,
      OLD_UOME_CODE          ,
      OLD_REMARKS            ,
      OLD_MODIFIED_BY        ,
      OLD_DT_MODIFIED        ,
      OLD_LPO_COST           ,
      OLD_LPO_CURRENCY       ,
      OLD_STOCK              ,
      OLD_CSHD_CS_NO         ,
      OLD_POHD_PO_NO         ,
      OLD_ISS_QTY            ,
      OLD_OLD_RS             ,
      OLD_NEW_RS             ,
      OLD_RR_QTY             ,
      OLD_WARE_CODE          ,
      OLD_CLR_RS_ITEM        ,
      OLD_STOCK_QTY          ,
      OLD_STOCK_ISS_QTY      ,
      OLD_WITH_STOCK         )
      VALUES (
      'UPDATE',
      USER         ,
      SYSDATE         ,
      :NEW.RSHD_RS_NO         ,
      :NEW.ITTY_CODE          ,
      :NEW.CATE_CODE          ,
      :NEW.ITGR_CODE          ,
      :NEW.ITEM_CODE          ,
      :NEW.STATUS             ,
      :NEW.QTY                ,
      :NEW.APPROVED_QTY       ,
      :NEW.UNIT_COST          ,
      :NEW.TOTAL_COST         ,
      :NEW.UOME_CODE          ,
      :NEW.REMARKS            ,
      :NEW.MODIFIED_BY        ,
      :NEW.DT_MODIFIED        ,
      :NEW.LPO_COST           ,
      :NEW.LPO_CURRENCY       ,
      :NEW.STOCK              ,
      :NEW.CSHD_CS_NO         ,
      :NEW.POHD_PO_NO         ,
      :NEW.ISS_QTY            ,
      :NEW.OLD_RS             ,
      :NEW.NEW_RS             ,
      :NEW.RR_QTY             ,
      :NEW.WARE_CODE          ,
      :NEW.CLR_RS_ITEM        ,
      :NEW.STOCK_QTY          ,
      :NEW.STOCK_ISS_QTY      ,
      :NEW.WITH_STOCK         ,
      :OLD.RSHD_RS_NO         ,
      :OLD.ITTY_CODE          ,
      :OLD.CATE_CODE          ,
      :OLD.ITGR_CODE          ,
      :OLD.ITEM_CODE          ,
      :OLD.STATUS             ,
      :OLD.QTY                ,
      :OLD.APPROVED_QTY       ,
      :OLD.UNIT_COST          ,
      :OLD.TOTAL_COST         ,
      :OLD.UOME_CODE          ,
      :OLD.REMARKS            ,
      :OLD.MODIFIED_BY        ,
      :OLD.DT_MODIFIED        ,
      :OLD.LPO_COST           ,
      :OLD.LPO_CURRENCY       ,
      :OLD.STOCK              ,
      :OLD.CSHD_CS_NO         ,
      :OLD.POHD_PO_NO         ,
      :OLD.ISS_QTY            ,
      :OLD.OLD_RS             ,
      :OLD.NEW_RS             ,
      :OLD.RR_QTY             ,
      :OLD.WARE_CODE          ,
      :OLD.CLR_RS_ITEM        ,
      :OLD.STOCK_QTY          ,
      :OLD.STOCK_ISS_QTY      ,
      :OLD.WITH_STOCK         );
   END IF;
   IF DELETING THEN
      INSERT INTO   INV_REQSLIP_DTL_LOG(
      ACTION_TAG         ,
      CREATED_BY         ,
      DT_CREATED         ,
      RSHD_RS_NO         ,
      ITTY_CODE          ,
      CATE_CODE          ,
      ITGR_CODE          ,
      ITEM_CODE          ,
      STATUS             ,
      QTY                ,
      APPROVED_QTY       ,
      UNIT_COST          ,
      TOTAL_COST         ,
      UOME_CODE          ,
      REMARKS            ,
      MODIFIED_BY        ,
      DT_MODIFIED        ,
      LPO_COST           ,
      LPO_CURRENCY       ,
      STOCK              ,
      CSHD_CS_NO         ,
      POHD_PO_NO         ,
      ISS_QTY            ,
      OLD_RS             ,
      NEW_RS             ,
      RR_QTY             ,
      WARE_CODE          ,
      CLR_RS_ITEM        ,
      STOCK_QTY          ,
      STOCK_ISS_QTY      ,
      WITH_STOCK         )
      VALUES (
      'DELETE',
      USER         ,
      SYSDATE         ,
      :OLD.RSHD_RS_NO         ,
      :OLD.ITTY_CODE          ,
      :OLD.CATE_CODE          ,
      :OLD.ITGR_CODE          ,
      :OLD.ITEM_CODE          ,
      :OLD.STATUS             ,
      :OLD.QTY                ,
      :OLD.APPROVED_QTY       ,
      :OLD.UNIT_COST          ,
      :OLD.TOTAL_COST         ,
      :OLD.UOME_CODE          ,
      :OLD.REMARKS            ,
      :OLD.MODIFIED_BY        ,
      :OLD.DT_MODIFIED        ,
      :OLD.LPO_COST           ,
      :OLD.LPO_CURRENCY       ,
      :OLD.STOCK              ,
      :OLD.CSHD_CS_NO         ,
      :OLD.POHD_PO_NO         ,
      :OLD.ISS_QTY            ,
      :OLD.OLD_RS             ,
      :OLD.NEW_RS             ,
      :OLD.RR_QTY             ,
      :OLD.WARE_CODE          ,
      :OLD.CLR_RS_ITEM        ,
      :OLD.STOCK_QTY          ,
      :OLD.STOCK_ISS_QTY      ,
      :OLD.WITH_STOCK         );
   END IF;
END;

ALTER TRIGGER "TPJ"."INV_REQSLIP_DTL_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_REQSLIP_HDR_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON INV_REQSLIP_HDR
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   vOFC varchar2(16);
BEGIN
   IF INSERTING THEN
     vOfc := sf_get_user_ofc(user);
     IF (NVL(:NEW.ofc_code,'HO') <> vOfc) THEN
        :NEW.ofc_code := vOfc;
     END IF;
     insert into inv_reqslip_hdr_log
     values (:new.rs_no, null, :new.status, null, :new.dept_code, null, :new.for_stock, sysdate, user, 'I');

   END IF;

   IF UPDATING THEN
     insert into inv_reqslip_hdr_log
     values (:new.rs_no, :old.status, :new.status, :old.dept_code, :new.dept_code, :old.for_stock, :new.for_stock, sysdate, user, 'U');

     IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
        BEGIN
           INSERT INTO inv_wsm_rs (rs_no, downloaded, dt_created, email_sent ) VALUES (:NEW.RS_NO, 'N', sysdate, 'N');
        EXCEPTION
           WHEN OTHERS THEN NULL;
        END;
     END IF;

     IF (:NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED') OR
        (:NEW.STATUS = 'DISAPPROVED' AND :OLD.STATUS <> 'DISAPPROVED')
     THEN
        BEGIN
           INSERT INTO inv_wsm_rs_cancelled (rs_no, downloaded, dt_created, email_sent ) VALUES (:NEW.RS_NO, 'N', sysdate, 'N');
        EXCEPTION
           WHEN OTHERS THEN NULL;
        END;
     END IF;

   END IF;


END;
ALTER TRIGGER "TPJ"."INV_REQSLIP_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_RETSLIP_HDR_TRG"
BEFORE UPDATE ON inv_retslip_hdr
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
  vErrMsg Varchar2(2000);
BEGIN

   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
         BEGIN
            INSERT INTO inv_stocks (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
            SELECT 'RET', :NEW.ret_no, rtdt.item_code, rtdt.cate_code, rtdt.itty_code
                 , rtdt.itgr_code, rtdt.uome_code
                 , rtdt.returned_qty
                 , 0
                 , drdt.currency
                 , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
                 , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                 , :NEW.supp_code
                 , drhd.ofc_code
            FROM   inv_retslip_dtl rtdt
                 , inv_dr_dtl drdt
                 , inv_dr_hdr drhd
            WHERE  rtdt.rthd_ret_no = :NEW.ret_no
            AND    rtdt.drhd_dr_no = drdt.drhd_dr_no
            AND    drhd.dr_no = drdt.drhd_dr_no
            AND    drdt.item_code = rtdt.item_code
            AND    drdt.cate_code = rtdt.cate_code
            AND    drdt.itty_code = rtdt.itty_code
            AND    drdt.itgr_code = rtdt.itgr_code
            AND    drdt.uome_code = rtdt.uome_code
            AND    drhd.ofc_code = 'HO';
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_RETSLIP_HDR_TRG', :NEW.ret_no || ' : drhd.ofc_code = ''HO''', vErrMsg, sysdate);
         END;

         BEGIN
            INSERT INTO inv_stocks_gensan (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                           qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
            SELECT 'RET', :NEW.ret_no, rtdt.item_code, rtdt.cate_code, rtdt.itty_code
                 , rtdt.itgr_code, rtdt.uome_code
                 , rtdt.returned_qty
                 , 0
                 , drdt.currency
                 , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
                 , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                 , :NEW.supp_code
                 , drhd.ofc_code
            FROM   inv_retslip_dtl rtdt
                 , inv_dr_dtl drdt
                 , inv_dr_hdr drhd
            WHERE  rtdt.rthd_ret_no = :NEW.ret_no
            AND    rtdt.drhd_dr_no = drdt.drhd_dr_no
            AND    drhd.dr_no = drdt.drhd_dr_no
            AND    drdt.item_code = rtdt.item_code
            AND    drdt.cate_code = rtdt.cate_code
            AND    drdt.itty_code = rtdt.itty_code
            AND    drdt.itgr_code = rtdt.itgr_code
            AND    drdt.uome_code = rtdt.uome_code
            AND    drhd.ofc_code = 'GENSAN';
         EXCEPTION
            WHEN OTHERS THEN
               vErrMsg := SQLERRM;
               insert into debug_log values ('INV_RETSLIP_HDR_TRG', :NEW.ret_no || ' : drhd.ofc_code = ''GENSAN''', vErrMsg, sysdate);
         END;
   END IF;
END;

ALTER TRIGGER "TPJ"."INV_RETSLIP_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_RE_HDR_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON inv_re_hdr
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
      BEGIN
         INSERT INTO inv_wsm_memo_re VALUES (:NEW.RE_NO, 'N', sysdate, null);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
END;
ALTER TRIGGER "TPJ"."INV_RE_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_ST_HDR_TRG"
BEFORE DELETE OR INSERT OR UPDATE
ON inv_st_hdr
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
DECLARE
   vErrMsg Varchar2(2000);
   vReType Varchar2(16);
BEGIN
   IF :NEW.STATUS = 'APPROVED' AND :OLD.STATUS <> 'APPROVED' THEN
      BEGIN
         INSERT INTO inv_wsm_st VALUES (:NEW.ST_NO, 'N', sysdate, null);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;

      -- IF :NEW.rehd_re_no = '000000' THEN
      BEGIN
         select re_type
         into   vReType
         from   inv_re_hdr
         where  re_no = :new.rehd_re_no;
         if vReType = 'TRS' then
            INSERT INTO inv_stocks (tran_type, ref_no, item_code, cate_code, itty_code, itgr_code, uome_code,
                                    qty, qty_alloc, currency, unit_cost, unit_cost_php, dt_created, reference, ofc_code)
            SELECT 'TRANSFER', :NEW.st_no, stdt.item_code, stdt.cate_code
                 , stdt.itty_code, stdt.itgr_code, stdt.uome_code
                 , stdt.qty
                 , 0
                 , 'PHP', 0
                 , 0 unit_cost_php
                 , nvl(:NEW.dt_modified,:NEW.dt_created) dt_created
                 , :NEW.ware_code
                 , 'HO' ofc_code
            FROM   inv_st_dtl stdt
            WHERE  stdt.sthd_st_no = :NEW.st_no;
         end if;
      EXCEPTION
         WHEN OTHERS THEN
            vErrMsg := SQLERRM;
            insert into debug_log values ('INV_ST_HDR_TRG', :NEW.st_no, vErrMsg, sysdate);
      END;
      -- END IF;

   END IF;

   IF :NEW.STATUS = 'CANCELLED' AND :OLD.STATUS <> 'CANCELLED' THEN
      BEGIN
         INSERT INTO inv_wsm_st_cancel VALUES (:NEW.ST_NO, 'N', sysdate, null);
      EXCEPTION
         WHEN OTHERS THEN NULL;
      END;
   END IF;
END;

ALTER TRIGGER "TPJ"."INV_ST_HDR_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_SUPPLIERS_TRG"
BEFORE INSERT
ON inv_suppliers
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   BEGIN
      INSERT INTO INV_WSM_SUPPLIERS VALUES (:NEW.CODE, 'N', sysdate, null);
   EXCEPTION
      WHEN OTHERS THEN NULL;
   END;
END;

ALTER TRIGGER "TPJ"."INV_SUPPLIERS_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."INV_UNIT_OF_MEASURE_TRG"
BEFORE INSERT
ON inv_unit_of_measure
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW
BEGIN
   BEGIN
      INSERT INTO INV_WSM_UOMS VALUES (:NEW.CODE, 'N', sysdate, null);
   EXCEPTION
      WHEN OTHERS THEN NULL;
   END;
END;

ALTER TRIGGER "TPJ"."INV_UNIT_OF_MEASURE_TRG" ENABLE
 /


  CREATE OR REPLACE TRIGGER "TPJ"."ITTY_ITEM_TRG"
AFTER UPDATE
OF DESCRIPTION
ON TPJ.INV_ITEM_TYPES
REFERENCING NEW AS NEW OLD AS OLD
FOR EACH ROW

BEGIN
  -- your code here
  -- (Trigger template "Default" could not be loaded.)
  UPDATE INV_ITEMS
  SET    NAME = INITCAP(:NEW.description)
  WHERE  itty_code = :OLD.code;
END;
ALTER TRIGGER "TPJ"."ITTY_ITEM_TRG" ENABLE
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_BANK_BAL_V" ("REF_TYPE", "REF_NO", "REF_DATE", "PRNCHECK_NO", "PAYEE_CODE", "PAYEE_TYPE", "DEBIT", "CREDIT", "ACCO_CODE", "ACCO_NAME") AS
  select ref_type, ref_no, ref_date, prncheck_no, payee_code, payee_type, debit, credit, acco_code, acco_name
from acc_bank_balance_stg union
SELECT 'CV' ref_type, h.cv_no cv_no, h.cv_date, cvc.prncheck_no
       , h.cpa_payee_code, h.cpa_payee_type
       , DECODE (
           h.cv_status
         , 'CANCELLED', 0
         , CASE
             WHEN d.debit <> 0 THEN NVL ( cvc.prncheck_amt, 0 )
             ELSE 0
           END
         ) debit_php
       , DECODE (
           h.cv_status
         , 'CANCELLED', 0
         , CASE
             WHEN d.credit <> 0 THEN NVL ( cvc.prncheck_amt, 0 )
             ELSE 0
           END
         ) credit_php
       , d.acco_code pcv_acco_code
       , sf_acc_get_account_name ( d.acco_code ) pcv_acco_name
  FROM   acc_cv_dtl d, acc_cv_hdr h, acc_cv_check_dtl cvc
  WHERE  d.cv_no = h.cv_no AND cvc.cv_no = h.cv_no
  AND    d.acco_code = cvc.bank_code
  UNION ALL
  SELECT 'PCV' ref_type, d.pcv_no ref_no, h.pcv_date ref_date, NULL
       , h.pcv_payee, NULL, DECODE (
                             h.pcv_status
                           , 'CANCELLED', 0
                           , d.debit
                           )
       , DECODE (
           h.pcv_status
         , 'CANCELLED', 0
         , d.credit
         ), d.acco_code acco_code
       , sf_acc_get_account_name ( d.acco_code ) acco_name
  FROM   acc_pcv_dtl d, acc_pcv_hdr h
  WHERE  d.pcv_no = h.pcv_no
  UNION ALL
  SELECT 'JV' ref_type, h.jv_no jv_no, h.jv_date, NULL, NULL, NULL
       , DECODE (
           h.jv_status
         , 'CANCELLED', 0
         , d.debit_php
         ) debit_php
       , DECODE (
           h.jv_status
         , 'CANCELLED', 0
         , d.credit_php
         ) credit_php, d.acco_code pcv_acco_code
       , sf_acc_get_account_name ( d.acco_code ) pcv_acco_name
  FROM   acc_jv_dtl d, acc_jv_hdr h
  WHERE  d.jv_no = h.jv_no
  UNION ALL
  SELECT 'AP' ref_type, h.ap_no ap_no, h.ap_date, NULL, h.ap_payee_code
       , h.ap_payee_type
       , DECODE (
           h.ap_status
         , 'CANCELLED', 0
         , d.debit_php
         ) debit_php
       , DECODE (
           h.ap_status
         , 'CANCELLED', 0
         , d.credit_php
         ) credit_php, d.acco_code pcv_acco_code
       , sf_acc_get_account_name ( d.acco_code ) acco_name
  FROM   acc_ap_dtl d, acc_ap_hdr h
  WHERE  d.ap_no = h.ap_no

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_CHECK_ADVANCES_VW" ("REF_TYPE", "REF_DATE", "REF_CODE", "ACCO_CODE", "REF_DESC", "AMT") AS
  SELECT 'PCV' REF_TYPE,
       HDR.PCV_DATE REF_DATE,
       DTL.PCV_NO REF_CODE,
       DTL.ACCO_CODE ACCO_CODE,
       DTL.PARTICULARS REF_DESC,
       abs(DTL.AMT) AMT
FROM ACC_PCV_DTL DTL, ACC_PCV_HDR HDR
WHERE DTL.ACCO_CODE = '10009'
AND   DTL.PCV_NO = HDR.PCV_NO
AND   EXISTS (SELECT 1 FROM ACC_PCV_DTL DTL1, ACC_PCV_HDR HDR1
              WHERE DTL1.PCV_NO = HDR1.PCV_NO
              AND   DTL1.PCV_NO = DTL.PCV_NO
              AND   DTL1.ACCO_CODE = '40003')
AND   NOT EXISTS (SELECT APPJ.REF_CODE FROM ACC_AP_PCV_JV_ADVANCES APPJ
                  WHERE APPJ.REF_TYPE = 'PCV'
                  AND   APPJ.REF_CODE = DTL.PCV_NO
                  AND   APPJ.IS_SELECTED = 'Y' )
UNION
SELECT 'CV' REF_TYPE,
       HDR.CV_DATE REF_DATE,
       DTL.CV_NO REF_CODE,
       DTL.ACCO_CODE ACCO_CODE,
       DTL.REF_DESC REF_DESC,
       ABS(DTL.CREDIT) AMT
FROM  ACC_CV_DTL DTL, ACC_CV_HDR HDR
WHERE DTL.ACCO_CODE = '10002'
AND   DTL.CV_NO = HDR.CV_NO
AND   EXISTS (SELECT 1 FROM ACC_CV_DTL DTL1, ACC_CV_HDR HDR1
              WHERE DTL1.CV_NO = HDR1.CV_NO
              AND   DTL1.CV_NO = DTL.CV_NO
              AND   DTL1.ACCO_CODE = '40003'
              )
AND   EXISTS (SELECT 1 FROM ACC_CV_CPA_DTL CDT
              WHERE CDT.CV_NO = DTL.CV_NO
              AND   CDT.CPA_REF_TYPE = 'SOA'
             )
AND   NOT EXISTS (SELECT APPJ.REF_CODE FROM ACC_AP_PCV_JV_ADVANCES APPJ
                  WHERE APPJ.REF_TYPE = 'CV'
                  AND   APPJ.REF_CODE = DTL.CV_NO
                  AND   APPJ.IS_SELECTED = 'Y'
             )
ORDER BY 1, 2

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_CV_CPA_V" ("CV_DATE", "CPA_NO", "CV_NO", "CPA_PAYEE", "PRNBANK_NAME", "PRNCHECK_AMT", "CV_STATUS") AS
  select cvhd.cv_date, cvcp.cpa_no, cvhd.cv_no, cvhd.cpa_payee, cvck.prnbank_name, cvck.prncheck_amt, cvhd.cv_status
from   acc_cv_hdr cvhd, acc_cv_cpa_dtl cvcp, acc_cv_check_dtl cvck
where  cvhd.cv_no = cvck.cv_no(+)
and    cvhd.cv_no = cvcp.cv_no(+)
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_GEN_LEDGER_V" ("REF_TYPE", "REF_NO", "REF_DATE", "PARTICULARS", "DEBIT", "CREDIT", "ACCO_CODE", "ACCO_NAME", "VESS_CODE") AS
  SELECT 'BB' ref_type, 0 cv_no, nvl(beg_bal_dt,to_date('20000101','YYYYMMDD')) cv_date, 'Beginning Balance', beg_bal debit_php
       , 0 credit_php, code pcv_acco_code
       , name pcv_acco_name, NULL
  FROM   acc_accounts
  UNION ALL
SELECT 'CV' ref_type, h.cv_no cv_no, h.cv_date, NULL, d.debit debit_php
       , d.credit credit_php, d.acco_code pcv_acco_code
       , sf_acc_get_account_name ( d.acco_code ) pcv_acco_name, NULL
  FROM   acc_cv_dtl d, acc_cv_hdr h
  WHERE  d.cv_no = h.cv_no AND h.cv_status <> 'CANCELLED'
  UNION ALL
  SELECT 'JV' ref_type, h.jv_no jv_no, h.jv_date, h.particular particulars
       , d.debit_php debit_php, d.credit_php credit_php
       , d.acco_code pcv_acco_code
       , sf_acc_get_account_name ( d.acco_code ) pcv_acco_name, NULL
  FROM   acc_jv_dtl d, acc_jv_hdr h
  WHERE  d.jv_no = h.jv_no AND h.jv_status <> 'CANCELLED'
  UNION ALL
  SELECT 'AP' ref_type, h.ap_no ap_no, h.ap_date, h.particulars particulars
       , d.debit_php debit_php, d.credit_php credit_php
       , d.acco_code pcv_acco_code
       , sf_acc_get_account_name ( d.acco_code ) acco_name, NULL
  FROM   acc_ap_dtl d, acc_ap_hdr h
  WHERE  d.ap_no = h.ap_no AND h.ap_status <> 'CANCELLED'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_INV_PCV_DTL" ("PO_NO", "RSHD_RS_NO", "PO_DATE", "PO_AMT", "PCV_AMT", "MAX_REF_SRC", "MIN_REF_SRC") AS
  SELECT po_no,
       rs_no rshd_rs_no,
       po_date,
       max(po_amt) po_amt,
       sum(pcv_amt) pcv_amt, max(ref_src) max_ref_src, min(ref_src) min_ref_src
from (
-- PO
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       SUM(approved_qty*unit_cost*((100-discount)/100)) po_amt,
       pohd.pcv_amt pcv_amt,
       'PO# ' || pohd.po_no ref_src
FROM   INV_PO_HDR pohd, INV_PO_DTL podt
WHERE  pohd.po_no = podt.pohd_po_no
AND    pohd.status = 'APPROVED'
AND    pohd.po_date > add_months(sysdate, -24)
GROUP BY pohd.rshd_rs_no, pohd.po_no, pohd.po_date, pohd.pcv_amt
HAVING SUM(approved_qty*unit_cost*((100-discount)/100)) > pohd.pcv_amt
UNION ALL
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       0 po_amt,
       cpdt.amount pcv_amt,
       'CPA ' || to_char(cpdt.cpa_no) ref_src
FROM   acc_cpa_dtl cpdt, acc_cpa_hdr cphd, inv_po_hdr pohd
WHERE  cpdt.ref_code = pohd.po_no
AND    pohd.po_date > add_months(sysdate, -24)
AND    cpdt.cpa_no = cphd.cpa_no
AND    cpdt.ref_type = 'PO'
AND    cphd.cpa_status <> 'CANCELLED'
UNION ALL
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       0 po_amt,
       apin.amount pcv_amt,
       'AP# ' || to_char(aphd.ap_no) ref_src
FROM   acc_ap_hdr aphd, inv_po_hdr pohd, acc_ap_inv_dtl apin
WHERE  apin.po_no = pohd.po_no
and    pohd.po_date > add_months(sysdate, -24)
AND    aphd.ap_no = apin.ap_no
and    apin.is_selected = 'Y'
and    apin.amount > 0
AND    aphd.ap_status <> 'CANCELLED'
UNION ALL
SELECT 'PO' || pohd.po_no po_no,
       pohd.rshd_rs_no rs_no,
       pohd.po_date po_date,
       0 po_amt,
       jvdt.debit_php pcv_amt,
       'JV# ' || to_char(jvhd.jv_no) ref_src
FROM   acc_jv_dtl jvdt, acc_jv_hdr jvhd, inv_po_hdr pohd
WHERE  jvdt.jv_no = jvhd.jv_no
AND    pohd.po_date > add_months(sysdate, -24)
AND    jvdt.ref_type = 'PO'
AND    jvdt.ref_code = pohd.po_no
AND    jvdt.debit_php > 0
AND    jvdt.acco_code = '40004'
AND    jvhd.jv_status <> 'CANCELLED'
UNION ALL
SELECT  a.po_no,
        a.rs_no,
        a.po_date,
        a.po_amount po_amt, -- a.po_amount
        a.amount pcv_amt,
        'PCV#' || to_char(a.pcv_no)
FROM   acc_pcv_inv_dtl a, acc_pcv_hdr b
WHERE  a.pcv_no = b.pcv_no
AND    b.pcv_status <> 'CANCELLED'
-- JO
UNION ALL
SELECT 'JO' || johd.jo_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       SUM(jodt.qty*jodt.unit_price*DECODE(jodt.cate_code,'LBR',((100-labor_discount)/100),((100-matrl_discount)/100))) po_amt,
       johd.pcv_amt pcv_amt,
       'JO' || johd.jo_no ref_src
FROM   inv_jo_hdr johd, inv_jo_dtl jodt
WHERE  johd.jo_no = jodt.johd_jo_no
AND    johd.jo_date > add_months(sysdate, -24)
AND    johd.status = 'APPROVED'
AND    not exists (select 1 from acc_pcv_inv_dtl pcid where pcid.po_no = 'JO' || johd.jo_no)
GROUP BY johd.jshd_js_no, johd.jo_no, johd.jo_date, johd.pcv_amt
HAVING SUM(jodt.qty*jodt.unit_price*DECODE(jodt.cate_code,'LBR',((100-labor_discount)/100),((100-matrl_discount)/100))) > johd.pcv_amt
UNION ALL
SELECT 'JO' || johd.jo_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       0 po_amt,
       cpdt.amount pcv_amt,
       'CPA ' || to_char(cpdt.cpa_no) ref_src
FROM   acc_cpa_dtl cpdt, acc_cpa_hdr cphd, inv_jo_hdr johd
WHERE  cpdt.cpa_no = cphd.cpa_no
AND    johd.jo_date > add_months(sysdate, -24)
AND    cpdt.ref_type = 'JO'
AND    cpdt.ref_code = johd.jo_no
AND    cphd.cpa_status <> 'CANCELLED'
UNION ALL
SELECT apin.po_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       0 po_amt,
       apin.amount pcv_amt,
       'AP# ' || to_char(aphd.ap_no) ref_src
FROM   acc_ap_hdr aphd, acc_ap_inv_dtl apin, inv_jo_hdr johd
WHERE  aphd.ap_no = apin.ap_no
and    johd.jo_date > add_months(sysdate, -24)
AND    ('JO' || johd.jo_no) = apin.po_no
and    apin.amount > 0
and    apin.is_selected = 'Y'
and    apin.po_no like 'JO%'
AND    aphd.ap_status <> 'CANCELLED'
UNION ALL
SELECT 'JO' || johd.jo_no po_no,
       johd.jshd_js_no rs_no,
       johd.jo_date po_date,
       0 po_amt,
       jvdt.debit_php pcv_amt,
       'JV# ' || to_char(jvhd.jv_no) ref_src
FROM   acc_jv_dtl jvdt, acc_jv_hdr jvhd, inv_jo_hdr johd
WHERE  jvdt.jv_no = jvhd.jv_no
AND    johd.jo_date > add_months(sysdate, -24)
AND    jvdt.ref_type = 'JO'
AND    jvdt.ref_code = johd.jo_no
AND    jvdt.debit_php > 0
AND    jvdt.acco_code = '40004'
AND    jvhd.jv_status <> 'CANCELLED'
) GROUP BY po_no,
        rs_no,
        po_date
--Having (sum(po_amt) -
--       sum(pcv_amt)) > 0

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_INV_RETSLIP" ("RET_NO", "RET_TYPE", "RET_DATE", "RR_NO", "PO_NO", "RS_NO", "SUPP_CODE", "RET_QTY", "RET_AMT") AS
  select  h.ret_no, h.ret_type, h.dt_returned ret_date, h.drhd_dr_no rr_no, d.pohd_po_no po_no, d.rshd_rs_no rs_no, h.supp_code,
        sum(d.returned_qty) ret_qty,  sum(d.returned_qty*r.unit_cost) ret_amt
from    inv_retslip_hdr h, inv_retslip_dtl d, inv_dr_dtl r
where   h.ret_no = d.rthd_ret_no
and     h.status = 'APPROVED'
and     d.drhd_dr_no = r.drhd_dr_no
and     d.pohd_po_no = r.pohd_po_no
and     d.rshd_rs_no = r.rshd_rs_no
and     d.item_code = r.item_code
and     d.cate_code = r.cate_code
and     d.itty_code = r.itty_code
and     d.itgr_code = r.itgr_code
and     d.returned_qty > 0
group   by h.ret_no, h.ret_type, h.dt_returned, h.drhd_dr_no, d.pohd_po_no, d.rshd_rs_no, h.supp_code

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_INV_RR_DTL" ("DR_NO", "SUPP_CODE", "PO_NO", "RS_NO", "INVOICE_NO", "DR_DATE", "RR_AMT", "RR_PAID", "PO_CURRENCY", "PO_TERMS", "CPA_AMT", "SUPP_DR_NO", "INVOICE_DT", "AP_NO", "ADDTL_DISC") AS
  SELECT drhd.dr_no dr_no, drhd.supp_code supp_code, drhd.pohd_po_no po_no
       , pohd.rshd_rs_no rs_no, drhd.invoice_no invoice_no
       , drhd.dr_date dr_date, drhd.rr_amt rr_amt, drhd.rr_paid rr_paid
       , pohd.currency po_currency, pohd.terms po_terms, drhd.cpa_amt
       , drhd.supp_dr_no, drhd.invoice_dt, drhd.ap_no
       , 0 addtl_disc --drhd.addtl_disc
  FROM   inv_dr_hdr drhd, inv_po_hdr pohd
  WHERE  drhd.pohd_po_no = pohd.po_no AND drhd.status = 'POSTED'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_PAYEES" ("PAYEE_CODE", "PAYEE_TYPE", "PAYEE_NAME") AS
  SELECT EMPL_ID PAYEE_CODE, 'EMPL' PAYEE_TYPE, FIRST_NAME||' '||LAST_NAME PAYEE_NAME FROM PMS_EMPLOYEES
UNION ALL
SELECT CODE, 'SUPP' PAYEE_TYPE, NAME FROM INV_SUPPLIERS
UNION ALL
SELECT CODE, 'MISC' PAYEE_TYPE, NAME FROM ACC_MISC_PAYEES
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_PCR_JVCV_LOV" ("OFC_CODE", "REF_TYPE", "JV_NO", "JV_DATE", "ACCO_CODE", "ACCO_NAME", "PARTICULARS", "AMT", "AMT_CHAR", "PRNBANK_NAME", "PRNCHECK_NO") AS
  SELECT 'HO' OFC_CODE,
       'JV' REF_TYPE,
       JVDT.JV_NO JV_NO,
       JVHD.JV_DATE JV_DATE,
       JVDT.ACCO_CODE ACCO_CODE,
       ACCO.NAME ACCO_NAME,
       sf_acc_get_receipt_dtl('JV', JVDT.JV_NO) PARTICULARS,
       sum(JVDT.debit_php) AMT,
       to_char(sum(JVDT.debit_php),'999,999,990.00') AMT_CHAR,
       NULL PRNBANK_NAME,
       NULL PRNCHECK_NO
FROM ACC_JV_DTL JVDT,
     ACC_ACCOUNTS ACCO,
     ACC_JV_HDR JVHD
WHERE JVDT.ACCO_CODE = ACCO.CODE AND
      JVDT.JV_NO = JVHD.JV_NO AND
      JVHD.JV_STATUS <> 'CANCELLED' AND
      JVDT.ACCO_CODE = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH')
AND   JVHD.JV_DATE >= TO_DATE('20130101','YYYYMMDD') AND
      JVDT.DEBIT > 0 AND
      JVHD.PCR_NO is null
GROUP  BY JVDT.JV_NO,
       JVHD.JV_DATE,
       JVDT.ACCO_CODE,
       ACCO.NAME
UNION ALL
SELECT 'HO' OFC_CODE,
       'CV' REF_TYPE,
       CVDT.CV_NO JV_NO,
       CVHD.CV_DATE JV_DATE,
       CVDT.ACCO_CODE ACCO_CODE,
       ACCO.NAME ACCO_NAME,
       CVDT.REF_TYPE || '-' || CVDT.REF_CODE PARTICULARS,
       CVCDT.PRNCHECK_AMT,
       TO_CHAR(CVCDT.PRNCHECK_AMT,'999,999,990.00') AMT_CHAR,
       CVCDT.PRNBANK_NAME,
       CVCDT.PRNCHECK_NO
FROM ACC_CV_DTL CVDT,
     ACC_ACCOUNTS ACCO,
     ACC_CV_HDR CVHD,
     ACC_CV_CHECK_DTL CVCDT
WHERE CVDT.ACCO_CODE = ACCO.CODE AND
      CVDT.CV_NO = CVHD.CV_NO AND
      CVHD.CV_STATUS <> 'CANCELLED' AND
      CVHD.CV_DATE >= TO_DATE('20130101','YYYYMMDD') AND
      CVDT.CV_NO = CVCDT.CV_NO AND
      CVDT.ACCO_CODE = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH') AND
      CVDT.DEBIT > 0  AND
      CVCDT.PCR_NO is null
UNION ALL
SELECT 'GENSAN' OFC_CODE,
       'JV' REF_TYPE,
       JVDT.JV_NO JV_NO,
       JVHD.JV_DATE JV_DATE,
       JVDT.ACCO_CODE ACCO_CODE,
       ACCO.NAME ACCO_NAME,
       sf_acc_get_receipt_dtl('JV', JVDT.JV_NO) PARTICULARS,
       sum(JVDT.debit_php) AMT,
       to_char(sum(JVDT.debit_php),'999,999,990.00') AMT_CHAR,
       NULL PRNBANK_NAME,
       NULL PRNCHECK_NO
FROM ACC_JV_DTL JVDT,
     ACC_ACCOUNTS ACCO,
     ACC_JV_HDR JVHD
WHERE JVDT.ACCO_CODE = ACCO.CODE AND
      JVDT.JV_NO = JVHD.JV_NO AND
      JVHD.JV_STATUS <> 'CANCELLED' AND
      JVDT.ACCO_CODE = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH GENSAN')
AND   JVHD.JV_DATE >= TO_DATE('20130101','YYYYMMDD') AND
      JVDT.DEBIT > 0 AND
      JVHD.PCR_NO is null
GROUP  BY JVDT.JV_NO,
       JVHD.JV_DATE,
       JVDT.ACCO_CODE,
       ACCO.NAME
UNION ALL
SELECT 'GENSAN' OFC_CODE,
       'CV' REF_TYPE,
       CVDT.CV_NO JV_NO,
       CVHD.CV_DATE JV_DATE,
       CVDT.ACCO_CODE ACCO_CODE,
       ACCO.NAME ACCO_NAME,
       CVDT.REF_TYPE || '-' || CVDT.REF_CODE PARTICULARS,
       CVCDT.PRNCHECK_AMT,
       TO_CHAR(CVCDT.PRNCHECK_AMT,'999,999,990.00') AMT_CHAR,
       CVCDT.PRNBANK_NAME,
       CVCDT.PRNCHECK_NO
FROM ACC_CV_DTL CVDT,
     ACC_ACCOUNTS ACCO,
     ACC_CV_HDR CVHD,
     ACC_CV_CHECK_DTL CVCDT
WHERE CVDT.ACCO_CODE = ACCO.CODE AND
      CVDT.CV_NO = CVHD.CV_NO AND
      CVHD.CV_STATUS <> 'CANCELLED' AND
      CVHD.CV_DATE >= TO_DATE('20130101','YYYYMMDD') AND
      CVDT.CV_NO = CVCDT.CV_NO AND
      CVDT.ACCO_CODE = SF_GET_ACC_SYSPARAM_CHARVAL('PETTY CASH GENSAN') AND
      CVDT.DEBIT > 0  AND
      CVCDT.PCR_NO is null

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_PCV_UNREPLENISHED" ("OFC_CODE", "O_PCV_NO", "PCV_NO", "PCR_NO", "ITEM_NO", "ACCO_CODE", "PARTICULARS", "AMT", "EMPL_EMPL_ID", "DEPT_CODE", "PCV_DATE", "PCV_PAYEE", "PCV_STATUS") AS
  SELECT 'HO' ofc_code, b.o_pcv_no, a.pcv_no, b.pcr_no, a.item_no, a.acco_code, a.particulars
       , a.credit amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_payee
       , b.pcv_status
  FROM   acc_pcv_dtl a, acc_pcv_hdr b
  WHERE  a.pcv_no = b.pcv_no AND a.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH' )
  AND    b.pcv_status = 'NEW'
  AND    b.ofc_code = 'HO'
  UNION
  SELECT 'HO' ofc_code, b.o_pcv_no, a.pcv_no, b.pcr_no, a.item_no, a.acco_code, a.particulars
       , 0 amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_payee||' - CANCELLED'
       , b.pcv_status
  FROM   acc_pcv_dtl a, acc_pcv_hdr b
  WHERE  a.pcv_no = b.pcv_no AND a.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH' )
  AND    b.pcv_status = 'CANCELLED'
  AND    b.ofc_code = 'HO'
  UNION
  SELECT 'HO' ofc_code, b.o_pcv_no, a.pcv_no, b.pcr_no, a.item_no, a.acco_code, a.particulars
       , a.credit amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_payee
       , b.pcv_status
  FROM   acc_pcv_dtl a, acc_pcv_hdr b
  WHERE  a.pcv_no = b.pcv_no
  AND    b.pcv_status = 'REPLENISHED'
  AND    a.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH' )
  AND    b.ofc_code = 'HO'
  UNION
SELECT 'GENSAN' ofc_code, b.o_pcv_no, a.pcv_no, b.pcr_no, a.item_no, a.acco_code, a.particulars
       , a.credit amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_payee
       , b.pcv_status
  FROM   acc_pcv_dtl a, acc_pcv_hdr b
  WHERE  a.pcv_no = b.pcv_no AND a.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH GENSAN' )
  AND    b.pcv_status = 'NEW'
  AND    b.ofc_code = 'GENSAN'
  UNION
  SELECT 'GENSAN' ofc_code, b.o_pcv_no, a.pcv_no, b.pcr_no, a.item_no, a.acco_code, a.particulars
       , 0 amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_payee||' - CANCELLED'
       , b.pcv_status
  FROM   acc_pcv_dtl a, acc_pcv_hdr b
  WHERE  a.pcv_no = b.pcv_no AND a.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH GENSAN' )
  AND    b.pcv_status = 'CANCELLED'
  AND    b.ofc_code = 'GENSAN'
  UNION
  SELECT 'GENSAN' ofc_code, b.o_pcv_no, a.pcv_no, b.pcr_no, a.item_no, a.acco_code, a.particulars
       , a.credit amt, a.empl_empl_id, a.dept_code, b.pcv_date, b.pcv_payee
       , b.pcv_status
  FROM   acc_pcv_dtl a, acc_pcv_hdr b
  WHERE  a.pcv_no = b.pcv_no
  AND    b.pcv_status = 'REPLENISHED'
  AND    b.ofc_code = 'GENSAN'
  AND    a.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH GENSAN' )

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_PDC_SUM_V" ("ACCOUNT_CODE", "REF_TYPE", "CV_NO", "PRNCHECK_DATE", "PRNCHECK_NO", "PAYEE_CODE", "PAYEE_TYPE", "PRNCHECK_AMT") AS
  SELECT d.acco_code account_code, 'CV' ref_type, h.cv_no cv_no, cvc.PRNCHECK_DATE, cvc.prncheck_no
       , h.cpa_payee_code payee_code, h.cpa_payee_type payee_type
       , DECODE (
           h.cv_status
         , 'CANCELLED', 0
         , NVL ( cvc.prncheck_amt, 0 )
         ) prncheck_amt
  FROM   acc_cv_hdr h, acc_cv_check_dtl cvc, acc_cv_dtl d
  WHERE  cvc.cv_no = h.cv_no
  AND    d.cv_no = h.cv_no
  order by cvc.PRNCHECK_DATE, cvc.prncheck_no
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SOURCE_CASH_ADVANCES_V" ("SRC_REF_TYPE", "SRC_DATE", "SRC_REF_CODE", "SRC_ACCO_CODE", "SRC_REF_DESC", "SRC_AP_NO", "SRC_AMT") AS
  SELECT 'PCV' SRC_REF_TYPE,
       HDR.PCV_DATE SRC_DATE,
       DTL.PCV_NO SRC_REF_CODE,
       DTL.ACCO_CODE SRC_ACCO_CODE,
       DTL.PARTICULARS SRC_REF_DESC,
       sf_get_pcv_ap_no('PCV', DTL.PCV_NO, '10009') SRC_AP_NO,
       abs(DTL.AMT) SRC_AMT
       --DTL.AMT SRC_AMT
FROM ACC_PCV_DTL DTL, ACC_PCV_HDR HDR
WHERE DTL.ACCO_CODE = '10009'
AND   DTL.PCV_NO = HDR.PCV_NO
AND   EXISTS ( SELECT 1 FROM ACC_PCV_DTL DTL1, ACC_PCV_HDR HDR1
WHERE DTL1.PCV_NO = HDR1.PCV_NO
AND   DTL1.PCV_NO = DTL.PCV_NO
AND   DTL1.ACCO_CODE = '40003' )
UNION
SELECT 'CV' SRC_REF_TYPE,
       HDR.CV_DATE SRC_DATE,
       DTL.CV_NO SRC_REF_CODE,
       DTL.ACCO_CODE SRC_ACCO_CODE,
       DTL.REF_DESC SRC_REF_DESC,
       sf_get_pcv_ap_no('CV', DTL.CV_NO,  '10002') SRC_AP_NO,
       abs(DTL.CREDIT) SRC_AMT
FROM ACC_CV_DTL DTL, ACC_CV_HDR HDR
WHERE DTL.ACCO_CODE = '10002'
AND   DTL.CV_NO = HDR.CV_NO
AND   EXISTS ( SELECT 1 FROM ACC_CV_DTL DTL1, ACC_CV_HDR HDR1
WHERE DTL1.CV_NO = HDR1.CV_NO
AND   DTL1.CV_NO = DTL.CV_NO
AND   DTL1.ACCO_CODE = '40003' )
ORDER BY SRC_REF_TYPE, SRC_REF_CODE

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SOURCE_CASH_V" ("OFC_CODE", "SRC_DATE", "SRC_REF_TYPE", "SRC_REF_CODE", "PRNBANK_NAME", "PRNCHECK_NO", "SRC_AMT", "PCR_NO", "PCR_DATE", "REMARKS") AS
  SELECT 'HO' ofc_code, cvhd.cv_date src_date, 'CV' src_ref_type, cvdt.cv_no src_ref_code
       , cvcdt.prnbank_name, cvcdt.prncheck_no, cvcdt.prncheck_amt src_amt
       , cvcdt.pcr_no, pcrhd.pcr_date, cvcdt.src_note remarks
  FROM   acc_cv_dtl cvdt
       , acc_cv_hdr cvhd
       , acc_cv_check_dtl cvcdt
       , acc_pcr_hdr pcrhd
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cvhd.cv_date >= TO_DATE ( '20090601', 'yyyymmdd' )
  AND    cvdt.cv_no = cvcdt.cv_no
  AND    cvdt.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH' )
  AND    pcrhd.pcr_no(+) = cvcdt.pcr_no
  AND    cvhd.cv_status <> 'CANCELLED'
  UNION ALL
  SELECT 'HO' ofc_code, jvhd.jv_date, 'JV', jvdt.jv_no, NULL, NULL, jvdt.debit_php amt
       , jvhd.pcr_no, pcrhd.pcr_date, jvdt.src_note
  FROM   acc_jv_dtl jvdt, acc_jv_hdr jvhd, acc_pcr_hdr pcrhd
  WHERE  jvdt.jv_no = jvhd.jv_no
  AND    jvdt.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH' )
  AND    jvhd.jv_date >= TO_DATE ( '20090601', 'yyyymmdd' )
  AND    jvhd.jv_status <> 'CANCELLED'
  AND    pcrhd.pcr_no(+) = jvhd.pcr_no
  AND    jvdt.debit > 0
UNION ALL
SELECT 'GENSAN' ofc_code, cvhd.cv_date src_date, 'CV' src_ref_type, cvdt.cv_no src_ref_code
       , cvcdt.prnbank_name, cvcdt.prncheck_no, cvcdt.prncheck_amt src_amt
       , cvcdt.pcr_no, pcrhd.pcr_date, cvcdt.src_note remarks
  FROM   acc_cv_dtl cvdt
       , acc_cv_hdr cvhd
       , acc_cv_check_dtl cvcdt
       , acc_pcr_hdr pcrhd
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cvhd.cv_date >= TO_DATE ( '20090601', 'yyyymmdd' )
  AND    cvdt.cv_no = cvcdt.cv_no
  AND    cvdt.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH GENSAN' )
  AND    pcrhd.pcr_no(+) = cvcdt.pcr_no
  AND    cvhd.cv_status <> 'CANCELLED'
  UNION ALL
  SELECT 'GENSAN' ofc_code, jvhd.jv_date, 'JV', jvdt.jv_no, NULL, NULL, jvdt.debit_php amt
       , jvhd.pcr_no, pcrhd.pcr_date, jvdt.src_note
  FROM   acc_jv_dtl jvdt, acc_jv_hdr jvhd, acc_pcr_hdr pcrhd
  WHERE  jvdt.jv_no = jvhd.jv_no
  AND    jvdt.acco_code = sf_get_acc_sysparam_charval ( 'PETTY CASH GENSAN' )
  AND    jvhd.jv_date >= TO_DATE ( '20090601', 'yyyymmdd' )
  AND    jvhd.jv_status <> 'CANCELLED'
  AND    pcrhd.pcr_no(+) = jvhd.pcr_no
  AND    jvdt.debit > 0

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SUBSIDIARY_CODES" ("SL_TYPE", "SL_CODE", "SL_NAME", "CREATED_BY", "DT_CREATED", "MODIFIED_BY", "DT_MODIFIED") AS
  select 'BANK' sl_type, code sl_code, name sl_name, created_by, dt_created, modified_by, dt_modified
from   acc_banks
union
select 'SUPPLIER' sl_type, code sl_code, name sl_name, created_by, dt_created, modified_by, dt_modified
from   inv_suppliers
union
select 'CUSTOMER' sl_type, code sl_code, name sl_name, created_by, dt_created, modified_by, dt_modified
from   cms_customers
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SUPPLIER_LEDGER" ("I_RR_DATE", "I_PAYEE_TYPE", "I_SUPP_CODE", "I_PO_NO", "I_AMOUNT", "I_AP_NO", "I_RR_NO", "I_RS_NO", "I_INV_NO", "I_RR_AMT", "I_IS_SELECTED", "I_INV_TYPE", "REF_CODE", "REF_TYPE", "PRNBANK_NAME", "PRNCHECK_NO", "PRNCHECK_DATE", "PRNCHECK_AMT", "EWT", "A_PO_NO", "STMT") AS
  SELECT   nvl(ap_beg_bal_dt,to_date('20000101','YYYYMMDD')) i_rr_date, 'SUPP' i_payee_type
       , code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, 0 ref_code
       , 'BB' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, ap_beg_bal prncheck_amt, 0 ewt, 'BEG. BAL.' a_po_no
       , 1 stmt
  FROM   inv_suppliers
union all
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
       , 2 stmt
  FROM   acc_cv_hdr cvhd
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  -- AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_type = 'SOA'
union all
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
       , 3 stmt
  FROM   acc_cv_hdr cvhd
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  -- AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvhd.cv_no not in (select cv_no from acc_cv_dtl cvdt where cvdt.cv_no = cvhd.cv_no and cvdt.acco_code not in ('60005', '40004'))
  UNION ALL
  -- Utilities 20110610
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount prncheck_amt
       , 0 ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
       , 4 stmt
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type = 'APV'
  AND    cvdt.acco_code = '60001'
  AND    not exists (SELECT 1
                     FROM     acc_ap_hdr aphd
                            , acc_ap_dtl apdt
                            , acc_jv_dtl jvdt
                            , acc_jv_dtl jvdt2
                     WHERE    aphd.ap_no = apdt.ap_no(+)
                     AND      cpdt.ref_type = 'APV'
                     AND      cpdt.ref_code = aphd.ap_no
                     AND      aphd.ap_status = 'APPROVED'
                     AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
                     AND      exists (select 1 from acc_cv_dtl cvdt2 where cvhd.cv_no = cvdt2.cv_no)
                     AND      apdt.ap_no = jvdt.ref_code (+)
                     AND      jvdt.ref_type (+) = 'APV'
                     AND      jvdt.acco_code (+) = '60001'
                     AND      jvdt.jv_no = jvdt2.jv_no (+)
                     AND      jvdt2.acco_code (+) = '60005'
                    )
  UNION ALL
  -- Expanded or EWT
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
       , 5 stmt
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '60005'
  UNION ALL
  -- Advances to Supplier
  -- Expanded or EWT (Advances)
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
       , 6 stmt
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'NEW'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '40004'
  AND    not exists (select 1 from acc_cv_dtl cvdt2 where cvdt2.cv_no = cvhd.cv_no and cvdt2.acco_code in ('60005','60001'))
  UNION ALL
  -- Petty Cash
--  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
--       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
--       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
--       , NULL i_is_selected, NULL i_inv_type, pchd.pcv_no, 'PCV', NULL, NULL
--       , pchd.pcv_date
--       , pcid.amount
--       , decode (pchd.vat_inc, 'Y', nvl((nvl(vat,0)/100) * (pcid.amount/sf_get_acc_ewt),0),
--                                    pcid.amount*(nvl(vat,0)/100)
--                )
--       , null
--  FROM   acc_pcv_inv_dtl pcid, acc_pcv_hdr pchd, inv_po_hdr pohd
--  WHERE  pchd.pcv_no = pcid.pcv_no
--  AND    pchd.pcv_status = 'REPLENISHED'
--  AND    pcid.amount > 0
--  AND    pcid.po_no like 'PO%'
--  AND    pohd.po_no = substr(pcid.po_no,3)
--  UNION ALL
  -- Accounts Payable (discounts)
  SELECT aphd.ap_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, aphd.ap_no ref_code
       , 'APV' ref_type, NULL, NULL
       , null prncheck_date, apdt.credit_php debit, 0 credit , null
       , 7 stmt
  FROM   acc_ap_hdr aphd, acc_ap_dtl apdt
  WHERE  aphd.ap_no = apdt.ap_no
  AND    apdt.acco_code = '944.1'
  AND    apdt.credit_php > 0
  UNION ALL
  -- Disbursment (CV discounts)
  SELECT cvhd.cv_date i_rr_date, 'SUPP' i_payee_type
       , cphd.cpa_payee_code i_supp_code, cpdt.ref_code i_po_no, cvdt.credit i_amount, null i_ap_no
       , lpad(to_char(cvhd.cv_no),6,'0') i_rr_no, NULL i_rs_no, NULL i_inv_no, cvdt.credit i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, null ref_code
       , null ref_type, NULL , NULL
       , NULL , 0 debit, 0 credit, null
       , 8 stmt
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cvdt.acco_code = '944.1'
  AND    cvdt.credit > 0
  UNION ALL
  -- Accounts Payable (advances)
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit_php debit
       , nvl(jvdt2.debit_php,0) ewt
       , 'APV# ' || lpad(to_char(aphd.ap_no),6,'0')
       , 9 stmt
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd, acc_jv_dtl jvdt2
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvhd.jv_no = jvdt2.jv_no
  AND    jvdt2.acco_code = '60005'
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  UNION ALL
  -- Accounts Payable (advances)
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , nvl(aphd.supp_code, aphd.ap_payee_code) i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit_php debit
       , 0 credit
       , 'APV# ' || lpad(to_char(aphd.ap_no),6,'0')
       , 10 stmt
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  AND    not exists (select 1 from acc_jv_dtl jvdt2 where jvdt2.jv_no = jvhd.jv_no and jvdt2.acco_code = '60005')
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , johd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, null
       , 11 stmt
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_jo_hdr johd
  WHERE  jvdt.ref_type = 'JO'
  AND    jvdt.ref_code = johd.jo_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, jvdt.ref_type || '# ' || jvdt.ref_code
       , 12 stmt
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_po_hdr pohd
  WHERE  jvdt.ref_type = 'PO'
  AND    jvdt.ref_code = pohd.po_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    debit_php > 0
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, null
       , 13 stmt
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code <> '60001'
  UNION ALL
  SELECT   cvhd.cv_date i_rr_date, aphd.ap_payee_type
         , aphd.ap_payee_code i_supp_code, NULL i_po_no, 0 i_amount
         , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no
         , 0 i_rr_amt, NULL i_is_selected, NULL i_inv_type, cvhd.cv_no
         , 'CV', NULL, NULL, NULL
         , SUM ( DECODE ( apdt.acco_code, '60001', apdt.credit - nvl(jvdt.debit_php,0), 0) ) ap_amt
         , SUM ( DECODE ( apdt.acco_code, '60005', apdt.credit, nvl(jvdt.debit_php,0)) ) ap_ewt
         , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
         , 14 stmt
  FROM     acc_ap_hdr aphd
         , acc_ap_dtl apdt
         , acc_cv_hdr cvhd
         , acc_cpa_dtl cpdt
         , acc_cpa_hdr cphd
         , acc_cv_cpa_dtl cvcp
         , acc_jv_dtl jvdt
         , acc_jv_dtl jvdt2
  WHERE    cvcp.cv_no = cvhd.cv_no
  AND      cphd.cpa_no = cpdt.cpa_no
  AND      cphd.cpa_no = cvcp.cpa_no
  AND      aphd.ap_no = apdt.ap_no(+)
  AND      cpdt.ref_type = 'APV'
  AND      cpdt.ref_code = aphd.ap_no
  AND      aphd.ap_status = 'APPROVED'
  AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
  AND      exists (select 1 from acc_cv_dtl cvdt where cvhd.cv_no = cvdt.cv_no)
  AND      apdt.ap_no = jvdt.ref_code (+)
  AND      jvdt.ref_type (+) = 'APV'
  AND      jvdt.acco_code (+) = '60001'
  AND      jvdt.jv_no = jvdt2.jv_no (+)
  AND      jvdt2.acco_code (+) = '60005'
  GROUP BY cvhd.cv_no, cvhd.cv_date, aphd.ap_payee_type, aphd.ap_payee_code, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  -- PCV
  UNION ALL
  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code,  null i_po_no, null i_amount, null i_ap_no
       , null i_rr_no, null i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , pcdt.is_selected i_is_selected, NULL i_inv_type, pchd.pcv_no ref_code
       , 'PCV' ref_type, NULL, NULL, NULL
       , pcdt.amount-(decode(pchd.vat_inc, 'Y', round(nvl((nvl(pchd.vat,0)/100)*(pcdt.amount/sf_get_acc_ewt),0),2), round(pcdt.amount*(nvl(pchd.vat,0)/100),2) )) debit
       , decode(pchd.vat_inc, 'Y', round(nvl((nvl(pchd.vat,0)/100)*(pcdt.amount/sf_get_acc_ewt),0),2), round(pcdt.amount*(nvl(pchd.vat,0)/100),2) ) ewt
       , pcdt.po_no
       , 15 stmt
  FROM   ACC_PCV_INV_DTL pcdt, ACC_PCV_HDR pchd, inv_po_hdr pohd
  WHERE  pcdt.pcv_no = pchd.pcv_no
  AND    substr(pcdt.po_no,3) = pohd.po_no
  AND    pcdt.amount > 0
  AND    pcdt.po_no like 'PO%'
  AND    pchd.pcv_status <> 'CANCELLED'
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code,  null i_po_no, null i_amount, null i_ap_no
       , null i_rr_no, null i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , pcdt.is_selected i_is_selected, NULL i_inv_type, jvhd.jv_no ref_code
       , 'JV' ref_type, NULL, NULL, NULL
       , (pcdt.amount-sum(rrdt.total_cost))*-1 debit
       , 0
       , jvdt.ref_type || '#' || jvdt.ref_code
       , 16 stmt
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, ACC_PCV_HDR pchd, ACC_PCV_INV_DTL pcdt, inv_po_hdr pohd, inv_dr_dtl rrdt, inv_dr_hdr rrhd
  WHERE  jvdt.ref_type = 'PCV'
  AND    jvdt.ref_code = pcdt.pcv_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code = '10009'
  AND    pcdt.pcv_no = pchd.pcv_no
  AND    substr(pcdt.po_no,3) = pohd.po_no
  AND    pcdt.amount > 0
  AND    pohd.po_no = rrhd.pohd_po_no (+)
  AND    rrhd.dr_no = rrdt.drhd_dr_no
  AND    jvdt.debit_php > 0
  AND    pcdt.po_no like 'PO%'
  GROUP BY jvhd.jv_date, pohd.supp_code, pcdt.is_selected, jvhd.jv_no, jvdt.ref_type, jvdt.ref_code, pcdt.amount
  UNION ALL
  SELECT i_rr_date, i_payee_type, i_supp_code, i_po_no, i_amount, i_ap_no
       , i_rr_no, i_rs_no, i_inv_no, i_rr_amt, i_is_selected, i_inv_type
       , NULL, NULL, NULL, NULL, NULL, 0, 0, null
       , 17 stmt
  FROM   acc_supplier_ledger_dtl

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SUPPLIER_LEDGER_BACKUP" ("I_RR_DATE", "I_PAYEE_TYPE", "I_SUPP_CODE", "I_PO_NO", "I_AMOUNT", "I_AP_NO", "I_RR_NO", "I_RS_NO", "I_INV_NO", "I_RR_AMT", "I_IS_SELECTED", "I_INV_TYPE", "REF_CODE", "REF_TYPE", "PRNBANK_NAME", "PRNCHECK_NO", "PRNCHECK_DATE", "PRNCHECK_AMT", "EWT", "A_PO_NO") AS
  SELECT   nvl(ap_beg_bal_dt,to_date('20000101','YYYYMMDD')) i_rr_date, 'SUPP' i_payee_type
       , code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, 0 ref_code
       , 'BB' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, ap_beg_bal prncheck_amt, 0 ewt, 'BEG. BAL.' a_po_no
  FROM   inv_suppliers
union all
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  -- AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_type = 'SOA'
union all
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  -- AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvhd.cv_no not in (select cv_no from acc_cv_dtl cvdt where cvdt.cv_no = cvhd.cv_no and cvdt.acco_code not in ('60005', '40004'))
  UNION ALL
  -- Expanded or EWT
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '60005'
  UNION ALL
  -- Advances to Supplier
  -- Expanded or EWT (Advances)
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'NEW'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '40004'
  AND    not exists (select 1 from acc_cv_dtl cvdt2 where cvdt2.cv_no = cvhd.cv_no and cvdt.acco_code in ('60005','60001'))
  UNION ALL
  -- Petty Cash
  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, pchd.pcv_no, 'PCV', NULL, NULL
       , pchd.pcv_date
       , pcid.amount
       , decode (pchd.vat_inc, 'Y', nvl((nvl(vat,0)/100) * (pcid.amount/sf_get_acc_ewt),0),
                                    pcid.amount*(nvl(vat,0)/100)
                )
       , null
  FROM   acc_pcv_inv_dtl pcid, acc_pcv_hdr pchd, inv_po_hdr pohd
  WHERE  pchd.pcv_no = pcid.pcv_no
  AND    pchd.pcv_status = 'REPLENISHED'
  AND    pcid.amount > 0
  AND    pohd.po_no = pcid.po_no
  UNION ALL
  -- Accounts Payable (discounts)
  SELECT aphd.ap_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, aphd.ap_no ref_code
       , 'APV' ref_type, NULL, NULL
       , null prncheck_date, apdt.credit_php debit, 0 credit , null
  FROM   acc_ap_hdr aphd, acc_ap_dtl apdt
  WHERE  aphd.ap_no = apdt.ap_no
  AND    apdt.acco_code = '944.1'
  AND    apdt.credit_php > 0
  UNION ALL
  -- Disbursment (CV discounts)
  SELECT cvhd.cv_date i_rr_date, 'SUPP' i_payee_type
       , cphd.cpa_payee_code i_supp_code, cpdt.ref_code i_po_no, cvdt.credit i_amount, null i_ap_no
       , lpad(to_char(cvhd.cv_no),6,'0') i_rr_no, NULL i_rs_no, NULL i_inv_no, cvdt.credit i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, null ref_code
       , null ref_type, NULL , NULL
       , NULL , 0 debit, 0 credit, null
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cvdt.acco_code = '944.1'
  AND    cvdt.credit > 0
  UNION ALL
  -- Accounts Payable (advances)
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit_php debit
       , nvl(jvdt2.debit_php,0) ewt
       , 'APV# ' || lpad(to_char(aphd.ap_no),6,'0')
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd, acc_jv_dtl jvdt2
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvhd.jv_no = jvdt2.jv_no
  AND    jvdt2.acco_code = '60005'
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  UNION ALL
  -- Accounts Payable (advances)
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , nvl(aphd.supp_code, aphd.ap_payee_code) i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit_php debit
       , 0 credit
       , 'APV# ' || lpad(to_char(aphd.ap_no),6,'0')
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  AND    not exists (select 1 from acc_jv_dtl jvdt2 where jvdt2.jv_no = jvhd.jv_no and jvdt2.acco_code = '60005')
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , johd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_jo_hdr johd
  WHERE  jvdt.ref_type = 'JO'
  AND    jvdt.ref_code = johd.jo_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, jvdt.ref_type || '# ' || jvdt.ref_code
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_po_hdr pohd
  WHERE  jvdt.ref_type = 'PO'
  AND    jvdt.ref_code = pohd.po_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    debit_php > 0
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code <> '60001'
  UNION ALL
  SELECT   cvhd.cv_date i_rr_date, aphd.ap_payee_type
         , aphd.ap_payee_code i_supp_code, NULL i_po_no, 0 i_amount
         , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no
         , 0 i_rr_amt, NULL i_is_selected, NULL i_inv_type, cvhd.cv_no, 'CV'
         , NULL, NULL, NULL
         , SUM ( DECODE (
               apdt.acco_code
             , '60001', apdt.credit
             , 0
             ) ) ap_amt
         , SUM ( DECODE (
               apdt.acco_code
             , '60005', apdt.credit
             , 0
             ) ) ap_ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  FROM     acc_ap_hdr aphd
         , acc_ap_dtl apdt
         , acc_cv_hdr cvhd
         ,
           --acc_cv_check_dtl cvcd,
           acc_cpa_dtl cpdt
         , acc_cpa_hdr cphd
         , acc_cv_cpa_dtl cvcp
  WHERE    aphd.ap_no = apdt.ap_no(+)
--and     cvhd.cv_no = cvcd.cv_no
  AND      cvcp.cv_no = cvhd.cv_no
  AND      cphd.cpa_no = cpdt.cpa_no
  AND      cphd.cpa_no = cvcp.cpa_no
  AND      cpdt.ref_type = 'APV'
  AND      cpdt.ref_code = aphd.ap_no
  AND      aphd.ap_status = 'APPROVED'
  AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
  AND      exists (select 1 from acc_cv_dtl cvdt where cvhd.cv_no = cvdt.cv_no)
  GROUP BY cvhd.cv_no, cvhd.cv_date, aphd.ap_payee_type, aphd.ap_payee_code, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  -- PCV
  UNION ALL
  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code,  null i_po_no, null i_amount, null i_ap_no
       , null i_rr_no, null i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , pcdt.is_selected i_is_selected, NULL i_inv_type, pchd.pcv_no ref_code
       , 'PCV' ref_type, NULL, NULL, NULL
       , pcdt.amount-(decode(pchd.vat_inc, 'Y', round(nvl((nvl(pchd.vat,0)/100)*(pcdt.amount/sf_get_acc_ewt),0),2), round(pcdt.amount*(nvl(pchd.vat,0)/100),2) )) debit
       , decode(pchd.vat_inc, 'Y', round(nvl((nvl(pchd.vat,0)/100)*(pcdt.amount/sf_get_acc_ewt),0),2), round(pcdt.amount*(nvl(pchd.vat,0)/100),2) ) ewt
       , pcdt.po_no
  FROM   ACC_PCV_INV_DTL pcdt, ACC_PCV_HDR pchd, inv_po_hdr pohd
  WHERE  pcdt.pcv_no = pchd.pcv_no
  AND    substr(pcdt.po_no,3) = pohd.po_no
  AND    pcdt.amount > 0
  AND    pchd.pcv_status <> 'CANCELLED'
  UNION ALL
  SELECT i_rr_date, i_payee_type, i_supp_code, i_po_no, i_amount, i_ap_no
       , i_rr_no, i_rs_no, i_inv_no, i_rr_amt, i_is_selected, i_inv_type
       , NULL, NULL, NULL, NULL, NULL, 0, 0, null
  FROM   acc_supplier_ledger_dtl

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SUPPLIER_LEDGER_DEBUG" ("STMT", "I_RR_DATE", "I_PAYEE_TYPE", "I_SUPP_CODE", "I_PO_NO", "I_AMOUNT", "I_AP_NO", "I_RR_NO", "I_RS_NO", "I_INV_NO", "I_RR_AMT", "I_IS_SELECTED", "I_INV_TYPE", "REF_CODE", "REF_TYPE", "PRNBANK_NAME", "PRNCHECK_NO", "PRNCHECK_DATE", "PRNCHECK_AMT", "EWT", "A_PO_NO") AS
  SELECT 1 stmt, nvl(ap_beg_bal_dt,to_date('20000101','YYYYMMDD')) i_rr_date, 'SUPP' i_payee_type
       , code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, 0 ref_code
       , 'BB' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, ap_beg_bal prncheck_amt, 0 ewt, 'BEG. BAL.' a_po_no
  FROM   inv_suppliers
union all
SELECT 2 stmt, cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  -- AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_type = 'SOA'
union all
SELECT 3 stmt, cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  -- AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvhd.cv_no not in (select cv_no from acc_cv_dtl cvdt where cvdt.cv_no = cvhd.cv_no and cvdt.acco_code not in ('60005', '40004'))
  UNION ALL
  -- Utilities 20110610
SELECT 4 stmt, cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount prncheck_amt
       , 0 ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type = 'APV'
  AND    cvdt.acco_code = '60001'
  AND    not exists (SELECT 1
                     FROM     acc_ap_hdr aphd
                            , acc_ap_dtl apdt
                            , acc_jv_dtl jvdt
                            , acc_jv_dtl jvdt2
                     WHERE    aphd.ap_no = apdt.ap_no(+)
                     AND      cpdt.ref_type = 'APV'
                     AND      cpdt.ref_code = aphd.ap_no
                     AND      aphd.ap_status = 'APPROVED'
                     AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
                     AND      exists (select 1 from acc_cv_dtl cvdt2 where cvhd.cv_no = cvdt2.cv_no)
                     AND      apdt.ap_no = jvdt.ref_code (+)
                     AND      jvdt.ref_type (+) = 'APV'
                     AND      jvdt.acco_code (+) = '60001'
                     AND      jvdt.jv_no = jvdt2.jv_no (+)
                     AND      jvdt2.acco_code (+) = '60005'
                    )
UNION ALL
-- Expanded or EWT
SELECT 5 stmt, cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '60005'
  UNION ALL
  -- Advances to Supplier
  -- Expanded or EWT (Advances)
SELECT 6 stmt, cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date
       , cpdt.amount - round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) prncheck_amt
       , round(decode(cphd.vat_inc,'Y', cpdt.amount/1.12, cpdt.amount) * (cphd.vat/100),2) ewt
       , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'NEW'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '40004'
  AND    not exists (select 1 from acc_cv_dtl cvdt2 where cvdt2.cv_no = cvhd.cv_no and cvdt2.acco_code in ('60005','60001'))
  UNION ALL
  -- Petty Cash
--  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
--       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
--       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
--       , NULL i_is_selected, NULL i_inv_type, pchd.pcv_no, 'PCV', NULL, NULL
--       , pchd.pcv_date
--       , pcid.amount
--       , decode (pchd.vat_inc, 'Y', nvl((nvl(vat,0)/100) * (pcid.amount/sf_get_acc_ewt),0),
--                                    pcid.amount*(nvl(vat,0)/100)
--                )
--       , null
--  FROM   acc_pcv_inv_dtl pcid, acc_pcv_hdr pchd, inv_po_hdr pohd
--  WHERE  pchd.pcv_no = pcid.pcv_no
--  AND    pchd.pcv_status = 'REPLENISHED'
--  AND    pcid.amount > 0
--  AND    pcid.po_no like 'PO%'
--  AND    pohd.po_no = substr(pcid.po_no,3)
--  UNION ALL
  -- Accounts Payable (discounts)
  SELECT 7 stmt, aphd.ap_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, aphd.ap_no ref_code
       , 'APV' ref_type, NULL, NULL
       , null prncheck_date, apdt.credit_php debit, 0 credit , null
  FROM   acc_ap_hdr aphd, acc_ap_dtl apdt
  WHERE  aphd.ap_no = apdt.ap_no
  AND    apdt.acco_code = '944.1'
  AND    apdt.credit_php > 0
  UNION ALL
  -- Disbursment (CV discounts)
  SELECT 8 stmt, cvhd.cv_date i_rr_date, 'SUPP' i_payee_type
       , cphd.cpa_payee_code i_supp_code, cpdt.ref_code i_po_no, cvdt.credit i_amount, null i_ap_no
       , lpad(to_char(cvhd.cv_no),6,'0') i_rr_no, NULL i_rs_no, NULL i_inv_no, cvdt.credit i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, null ref_code
       , null ref_type, NULL , NULL
       , NULL , 0 debit, 0 credit, null
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status <> 'CANCELLED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cvdt.acco_code = '944.1'
  AND    cvdt.credit > 0
  UNION ALL
  -- Accounts Payable (advances)
  SELECT 9 stmt, jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit_php debit
       , nvl(jvdt2.debit_php,0) ewt
       , 'APV# ' || lpad(to_char(aphd.ap_no),6,'0')
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd, acc_jv_dtl jvdt2
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvhd.jv_no = jvdt2.jv_no
  AND    jvdt2.acco_code = '60005'
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  UNION ALL
  -- Accounts Payable (advances)
  SELECT 10 stmt, jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , nvl(aphd.supp_code, aphd.ap_payee_code) i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, jvdt.debit_php debit
       , 0 credit
       , 'APV# ' || lpad(to_char(aphd.ap_no),6,'0')
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code = '60001'
  AND    jvdt.debit > 0
  AND    not exists (select 1 from acc_jv_dtl jvdt2 where jvdt2.jv_no = jvhd.jv_no and jvdt2.acco_code = '60005')
  UNION ALL
  SELECT 11 stmt, jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , johd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_jo_hdr johd
  WHERE  jvdt.ref_type = 'JO'
  AND    jvdt.ref_code = johd.jo_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT 12 stmt, jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, jvdt.ref_type || '# ' || jvdt.ref_code
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_po_hdr pohd
  WHERE  jvdt.ref_type = 'PO'
  AND    jvdt.ref_code = pohd.po_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    debit_php > 0
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT 13 stmt, jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit_php, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code <> '60001'
  UNION ALL
  SELECT 14 stmt, cvhd.cv_date i_rr_date, aphd.ap_payee_type
         , aphd.ap_payee_code i_supp_code, NULL i_po_no, 0 i_amount
         , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no
         , 0 i_rr_amt, NULL i_is_selected, NULL i_inv_type, cvhd.cv_no
         , 'CV', NULL, NULL, NULL
         , SUM ( DECODE ( apdt.acco_code, '60001', apdt.credit - nvl(jvdt.debit_php,0), 0) ) ap_amt
         , SUM ( DECODE ( apdt.acco_code, '60005', apdt.credit, nvl(jvdt.debit_php,0)) ) ap_ewt
         , cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  FROM     acc_ap_hdr aphd
         , acc_ap_dtl apdt
         , acc_cv_hdr cvhd
         , acc_cpa_dtl cpdt
         , acc_cpa_hdr cphd
         , acc_cv_cpa_dtl cvcp
         , acc_jv_dtl jvdt
         , acc_jv_dtl jvdt2
  WHERE    cvcp.cv_no = cvhd.cv_no
  AND      cphd.cpa_no = cpdt.cpa_no
  AND      cphd.cpa_no = cvcp.cpa_no
  AND      aphd.ap_no = apdt.ap_no(+)
  AND      cpdt.ref_type = 'APV'
  AND      cpdt.ref_code = aphd.ap_no
  AND      aphd.ap_status = 'APPROVED'
  AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
  AND      exists (select 1 from acc_cv_dtl cvdt where cvhd.cv_no = cvdt.cv_no)
  AND      apdt.ap_no = jvdt.ref_code (+)
  AND      jvdt.ref_type (+) = 'APV'
  AND      jvdt.acco_code (+) = '60001'
  AND      jvdt.jv_no = jvdt2.jv_no (+)
  AND      jvdt2.acco_code (+) = '60005'
  GROUP BY cvhd.cv_no, cvhd.cv_date, aphd.ap_payee_type, aphd.ap_payee_code, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  -- PCV
  UNION ALL
  SELECT 15 stmt, pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code,  null i_po_no, null i_amount, null i_ap_no
       , null i_rr_no, null i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , pcdt.is_selected i_is_selected, NULL i_inv_type, pchd.pcv_no ref_code
       , 'PCV' ref_type, NULL, NULL, NULL
       , pcdt.amount-(decode(pchd.vat_inc, 'Y', round(nvl((nvl(pchd.vat,0)/100)*(pcdt.amount/sf_get_acc_ewt),0),2), round(pcdt.amount*(nvl(pchd.vat,0)/100),2) )) debit
       , decode(pchd.vat_inc, 'Y', round(nvl((nvl(pchd.vat,0)/100)*(pcdt.amount/sf_get_acc_ewt),0),2), round(pcdt.amount*(nvl(pchd.vat,0)/100),2) ) ewt
       , pcdt.po_no
  FROM   ACC_PCV_INV_DTL pcdt, ACC_PCV_HDR pchd, inv_po_hdr pohd
  WHERE  pcdt.pcv_no = pchd.pcv_no
  AND    substr(pcdt.po_no,3) = pohd.po_no
  AND    pcdt.amount > 0
  AND    pcdt.po_no like 'PO%'
  AND    pchd.pcv_status <> 'CANCELLED'
  UNION ALL

  SELECT 16 stmt, jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code,  null i_po_no, null i_amount, null i_ap_no
       , null i_rr_no, null i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , pcdt.is_selected i_is_selected, NULL i_inv_type, jvhd.jv_no ref_code
       , 'JV' ref_type, NULL, NULL, NULL
       , (pcdt.amount-sum(rrdt.total_cost))*-1 debit
       , 0
       , jvdt.ref_type || '#' || jvdt.ref_code
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, ACC_PCV_HDR pchd, ACC_PCV_INV_DTL pcdt, inv_po_hdr pohd, inv_dr_dtl rrdt, inv_dr_hdr rrhd
  WHERE  jvdt.ref_type = 'PCV'
  AND    jvdt.ref_code = pcdt.pcv_no
  AND    jvdt.ref_code IS NOT NULL
  --AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  AND    jvdt.acco_code = '10009'
  AND    pcdt.pcv_no = pchd.pcv_no
  AND    substr(pcdt.po_no,3) = pohd.po_no
  AND    pcdt.amount > 0
  AND    pohd.po_no = rrhd.pohd_po_no (+)
  AND    rrhd.dr_no = rrdt.drhd_dr_no
  AND    jvdt.debit_php > 0
  AND    pcdt.po_no like 'PO%'
  GROUP BY jvhd.jv_date, pohd.supp_code, pcdt.is_selected, jvhd.jv_no, jvdt.ref_type, jvdt.ref_code, pcdt.amount
  UNION ALL
  SELECT 17 stmt, i_rr_date, i_payee_type, i_supp_code, i_po_no, i_amount, i_ap_no
       , i_rr_no, i_rs_no, i_inv_no, i_rr_amt, i_is_selected, i_inv_type
       , NULL, NULL, NULL, NULL, NULL, 0, 0, null
  FROM   acc_supplier_ledger_dtl

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SUPPLIER_LEDGER_DTL" ("I_INV_TYPE", "I_RR_DATE", "I_PAYEE_TYPE", "I_SUPP_CODE", "I_PO_NO", "I_AMOUNT", "I_AP_NO", "I_RR_NO", "I_RS_NO", "I_INV_NO", "I_RR_AMT", "I_IS_SELECTED") AS
  SELECT   i_inv_type, i_rr_date, i_payee_type, i_supp_code, i_po_no
         , i_amount, i_ap_no, i_rr_no, i_rs_no, i_inv_no, i_rr_amt
         , i_is_selected
  FROM     ( SELECT 'PO' i_inv_type
                  , DECODE (
                      NVL ( aaid.is_selected, 'N' )
                    , 'Y', aaid.ap_no
                    , 999999999999
                    ) i_ap_no
                  , drhd.dr_no i_rr_no, 'SUPP' i_payee_type
                  , drhd.supp_code i_supp_code, drhd.rs_no i_rs_no
                  , NVL ( drhd.invoice_no, drhd.supp_dr_no ) i_inv_no
                  , NVL ( drhd.invoice_dt, drhd.dr_date ) i_rr_date
                  , decode(drhd.po_currency, 'PHP', drhd.rr_amt, drhd.rr_amt*aaid.rr_conv) i_rr_amt, aaid.is_selected i_is_selected
                  , drhd.po_no i_po_no
                  , NVL ( DECODE (
                        aaid.is_selected
                      , 'Y', aaid.amount
                      , 0
                      )
                    , 0 ) i_amount
            FROM   acc_inv_rr_dtl drhd, acc_ap_inv_dtl aaid, acc_ap_hdr aphd
            WHERE  drhd.dr_no = aaid.rr_no
            AND    aphd.ap_no = aaid.ap_no
            AND    aphd.inv_type = 'PO'
            AND    aphd.ap_status <> 'CANCELLED'
            UNION ALL
            SELECT 'PO' i_inv_type, 999999999999 i_ap_no, drhd.dr_no i_rr_no
                 , 'SUPP' i_payee_type, drhd.supp_code i_supp_code
                 , drhd.rs_no i_rs_no
                 , NVL ( drhd.invoice_no, drhd.supp_dr_no ) i_inv_no
                 , NVL ( drhd.invoice_dt, drhd.dr_date ) i_rr_date
                 , decode(drhd.po_currency, 'PHP', drhd.rr_amt, drhd.rr_amt*nvl(aaid.rr_conv,1)) i_rr_amt
                 --, drhd.rr_amt i_rr_amt
                 , NULL i_is_selected
                 , drhd.po_no i_po_no, 0 i_amount
            FROM   acc_inv_rr_dtl drhd, acc_ap_inv_dtl aaid
            WHERE  drhd.dr_no = aaid.rr_no(+)
            AND    NOT EXISTS (SELECT 1
                               FROM   acc_ap_inv_dtl aaid, acc_ap_hdr aphd
                               WHERE  drhd.dr_no = aaid.rr_no
                               AND    aphd.ap_no = aaid.ap_no
                               AND    aphd.inv_type = 'PO'
                               AND    aphd.ap_status <> 'CANCELLED' )
            UNION ALL
            SELECT 'JO' i_inv_type
                 , DECODE (
                     NVL ( aaid.is_selected, 'N' )
                   , 'Y', aaid.ap_no
                   , 999999999999
                   ) i_ap_no
                 , drhd.jo_dr_no i_rr_no, 'SUPP' i_payee_type
                 , drhd.supp_code i_supp_code
                 , ( SELECT jshd_js_no
                    FROM   inv_jo_hdr
                    WHERE  jo_no = johd_jo_no ) i_rs_no
                 , drhd.supp_dr_no i_inv_no
                 , NVL ( drhd.invoice_dt, drhd.jo_dr_date ) i_rr_date
                 , sf_get_repair_cost_2 ( johd_jo_no, drhd.jo_dr_no ) i_rr_amt
                 , aaid.is_selected i_is_selected, drhd.johd_jo_no i_po_no
                 , NVL ( DECODE (
                       aaid.is_selected
                     , 'Y', aaid.amount
                     , 0
                     )
                   , 0 ) i_amount
            FROM   inv_jo_dr_hdr drhd, acc_ap_inv_dtl aaid, acc_ap_hdr aphd
            WHERE  drhd.jo_dr_no = aaid.rr_no AND drhd.status = 'APPROVED'
            AND    aphd.ap_no = aaid.ap_no
            AND    aphd.inv_type = 'JO'
            AND    drhd.rr_amt > 0
            AND    aphd.ap_status <> 'CANCELLED'
            UNION ALL
            SELECT 'JO' i_inv_type, 999999999999 i_ap_no
                 , drhd.jo_dr_no i_rr_no, 'SUPP' i_payee_type
                 , drhd.supp_code i_supp_code
                 , ( SELECT jshd_js_no
                    FROM   inv_jo_hdr
                    WHERE  jo_no = johd_jo_no ) i_rs_no
                 , drhd.supp_dr_no i_inv_no
                 , NVL ( drhd.invoice_dt, drhd.jo_dr_date ) i_rr_date
                 , sf_get_repair_cost_2 ( johd_jo_no, drhd.jo_dr_no ) i_rr_amt
                 , NULL i_is_selected, drhd.johd_jo_no i_po_no, 0 i_amount
            FROM   inv_jo_dr_hdr drhd
            WHERE  NOT EXISTS ( SELECT 1
                               FROM   acc_ap_inv_dtl aaid, acc_ap_hdr aphd
                               WHERE  drhd.jo_dr_no = aaid.rr_no
                               AND    aphd.ap_no = aaid.ap_no
                               AND    aphd.inv_type = 'JO'
                               AND    aphd.ap_status <> 'CANCELLED')
            AND    drhd.rr_amt > 0
            AND    drhd.status = 'APPROVED'
            UNION ALL
            SELECT 'OTHERS' i_inv_type
                 , DECODE (
                     NVL ( aaid.is_selected, 'N' )
                   , 'Y', aaid.ap_no
                   , 999999999999
                   ) i_ap_no
                 , NULL i_rr_no, aphd.ap_payee_type
                 , aphd.ap_payee_code i_supp_code, NULL i_rs_no
                 , aaid.invoice_no i_inv_no, aaid.invoice_date i_rr_date
                 -- , aaid.invoice_amount i_rr_amt
                 , aaid.amount i_rr_amt
                 , aaid.is_selected i_is_selected, NULL i_po_no
                 , NVL ( DECODE (
                       aaid.is_selected
                     , 'Y', aaid.amount
                     , 0
                     )
                   , 0 ) i_amount
            FROM   acc_ap_oth_dtl aaid, acc_ap_hdr aphd
            WHERE  aphd.ap_no = aaid.ap_no
            AND    aphd.ap_status <> 'CANCELLED')
  ORDER BY i_rr_date

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_SUPPLIER_LEDGER_NEW" ("I_RR_DATE", "I_PAYEE_TYPE", "I_SUPP_CODE", "I_PO_NO", "I_AMOUNT", "I_AP_NO", "I_RR_NO", "I_RS_NO", "I_INV_NO", "I_RR_AMT", "I_IS_SELECTED", "I_INV_TYPE", "REF_CODE", "REF_TYPE", "PRNBANK_NAME", "PRNCHECK_NO", "PRNCHECK_DATE", "PRNCHECK_AMT", "EWT", "A_PO_NO") AS
  SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, cpdt.amount prncheck_amt, 0 ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       ,
         --acc_cv_check_dtl ccdt,
         acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvhd.cv_no not in (select cv_no from acc_cv_dtl cvdt where cvdt.cv_no = cvhd.cv_no and cvdt.acco_code = '60005')
  UNION ALL
SELECT cvhd.cv_date i_rr_date, cphd.cpa_payee_type i_payee_type
       , cphd.cpa_payee_code i_supp_code, null i_po_no, 0 i_amount
       , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, cvhd.cv_no ref_code
       , 'CV' ref_type, NULL prnbank_name, NULL prncheck_no
       , NULL prncheck_date, ccdt.prncheck_amt prncheck_amt, cvdt.credit ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0') a_po_no
  FROM   acc_cv_hdr cvhd
       , acc_cv_dtl cvdt
       , acc_cv_check_dtl ccdt
       , acc_cpa_hdr cphd
       , acc_cpa_dtl cpdt
       , acc_cv_cpa_dtl cvcpdt
  WHERE  ccdt.cv_no = cvhd.cv_no
  AND    cvdt.cv_no = cvhd.cv_no
  AND    cphd.cpa_no = cvcpdt.cpa_no
  AND    cpdt.cpa_no = cphd.cpa_no
  AND    cvhd.cv_status = 'APPROVED'
  AND    cvhd.cv_no = cvcpdt.cv_no
  AND    cpdt.ref_code IS NOT NULL
  AND    cpdt.ref_type IN ( 'JO', 'PO' )
  AND    cvdt.acco_code = '60005'
  UNION ALL
  SELECT pchd.pcv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, pchd.pcv_no, 'PCV', NULL, NULL
       , pchd.pcv_date, pcid.amount, 0, null
  FROM   acc_pcv_inv_dtl pcid, acc_pcv_hdr pchd, inv_po_hdr pohd
  WHERE  pchd.pcv_no = pcid.pcv_no
  AND    pchd.pcv_status = 'REPLENISHED'
  AND    pcid.amount > 0
  AND    pohd.po_no = pcid.po_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , johd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_jo_hdr johd
  WHERE  jvdt.ref_type = 'JO'
  AND    jvdt.ref_code = johd.jo_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , pohd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, inv_po_hdr pohd
  WHERE  jvdt.ref_type = 'PO'
  AND    jvdt.ref_code = pohd.po_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT jvhd.jv_date i_rr_date, 'SUPP' i_payee_type
       , aphd.supp_code i_supp_code, NULL i_po_no, 0 i_amount, NULL i_ap_no
       , NULL i_rr_no, NULL i_rs_no, NULL i_inv_no, 0 i_rr_amt
       , NULL i_is_selected, NULL i_inv_type, jvhd.jv_no, 'JV', NULL, NULL
       , jvhd.jv_date, debit, 0, null
  FROM   acc_jv_hdr jvhd, acc_jv_dtl jvdt, acc_ap_hdr aphd
  WHERE  jvdt.ref_type = 'APV'
  AND    jvdt.ref_code = aphd.ap_no
  AND    jvdt.ref_code IS NOT NULL
  AND    jvhd.jv_status = 'APPROVED'
  AND    jvhd.jv_no = jvdt.jv_no
  UNION ALL
  SELECT   cvhd.cv_date i_rr_date, aphd.ap_payee_type
         , aphd.ap_payee_code i_supp_code, NULL i_po_no, 0 i_amount
         , NULL i_ap_no, NULL i_rr_no, NULL i_rs_no, NULL i_inv_no
         , 0 i_rr_amt, NULL i_is_selected, NULL i_inv_type, cvhd.cv_no, 'CV'
         , NULL, NULL, NULL
         , SUM ( DECODE (
               apdt.acco_code
             , '60001', apdt.credit
             , 0
             ) ) ap_amt
         , SUM ( DECODE (
               apdt.acco_code
             , '60005', apdt.credit
             , 0
             ) ) ap_ewt, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  FROM     acc_ap_hdr aphd
         , acc_ap_dtl apdt
         , acc_cv_hdr cvhd
         ,
           --acc_cv_check_dtl cvcd,
           acc_cpa_dtl cpdt
         , acc_cpa_hdr cphd
         , acc_cv_cpa_dtl cvcp
  WHERE    aphd.ap_no = apdt.ap_no(+)
--and     cvhd.cv_no = cvcd.cv_no
  AND      cvcp.cv_no = cvhd.cv_no
  AND      cphd.cpa_no = cpdt.cpa_no
  AND      cphd.cpa_no = cvcp.cpa_no
  AND      cpdt.ref_type = 'APV'
  AND      cpdt.ref_code = aphd.ap_no
  AND      aphd.ap_status = 'APPROVED'
  AND      (apdt.acco_code IN ( '60005', '60001' ) OR apdt.ap_no IS NULL )
  GROUP BY cvhd.cv_no, cvhd.cv_date, aphd.ap_payee_type, aphd.ap_payee_code, cpdt.ref_type||'# '||lpad(cpdt.ref_code, 6,'0')
  UNION ALL
  SELECT i_rr_date, i_payee_type, i_supp_code, i_po_no, i_amount, i_ap_no
       , i_rr_no, i_rs_no, i_inv_no, i_rr_amt, i_is_selected, i_inv_type
       , NULL, NULL, NULL, NULL, NULL, 0, 0, null
  FROM   acc_supplier_ledger_dtl

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."ACC_VALE_LISTING" ("VALE_TYPE", "TRAN_NO", "TX_DATE", "STATUS", "EMPL_EMPL_ID", "VESS_CODE", "APPROVED_AMT", "REQUESTED_AMT", "PCV_NO", "PCV_BAL_AMT", "OFC_CODE") AS
  SELECT   'RV' vale_type, v.tran_no, v.tx_date, v.status, v.empl_empl_id, v.vess_code
         , v.approved_amt, v.requested_amt, v.pcv_no, v.pcv_bal_amt, 'HO' ofc_code
  FROM     cms_request_vale v
  WHERE    v.status = 'APPROVED'
  UNION
  SELECT   'OP' vale_type, v.tran_no, v.tx_date, v.status, NULL empl_empl_id
         , MAX ( d.vess_code ) vess_code, SUM ( d.approved_amt ) approved_amt
         , SUM ( d.requested_amt ) requested_amt, v.pcv_no, v.pcv_bal_amt, 'HO' ofc_code
  FROM     cms_op_vale_hdr v, cms_op_vale_dtl d
  WHERE    v.tran_no = d.tran_no
  AND      v.status = 'APPROVED'
  AND      v.released_outside = 'N'
  and      d.approved_flag = 'Y'
  GROUP BY v.tran_no, v.tx_date, v.status, v.pcv_no, v.pcv_bal_amt
  UNION
SELECT   'RV' vale_type, v.tran_no, v.tx_date, v.status, v.empl_empl_id, v.vess_code
         , v.approved_amt, v.requested_amt, v.pcv_no, v.pcv_bal_amt, 'GENSAN' ofc_code
  FROM     cms_request_vale v
  WHERE    v.status = 'APPROVED'
  UNION
  SELECT   'OP' vale_type, v.tran_no, v.tx_date, v.status, NULL empl_empl_id
         , MAX ( d.vess_code ) vess_code, SUM ( d.approved_amt ) approved_amt
         , SUM ( d.requested_amt ) requested_amt, v.pcv_no, SUM ( d.release_amt) pcv_bal_amt, 'GENSAN' ofc_code
  FROM     cms_op_vale_hdr v, cms_op_vale_dtl d
  WHERE    v.tran_no = d.tran_no
  AND      v.status = 'APPROVED'
  AND      v.released_outside = 'Y'
  and      d.approved_flag = 'Y'
  GROUP BY v.tran_no, v.tx_date, v.status, v.pcv_no, v.pcv_bal_amt
  ORDER BY tran_no, tx_date

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."CMS_ACTIVE_CREW_V" ("EMPL_EMPL_ID", "VESS_CODE", "VOYAGE_DATE", "RANK_CODE", "TITLE", "DT_EMBARKED", "BASIC_RATE", "BASIC_RATE_G", "SEQ_NO", "TRAN_NO_EMBARKED", "ORIG_LIST", "CREATED_BY", "DT_CREATED", "MODIFIED_BY", "DT_MODIFIED") AS
  select a.empl_empl_id, a.voya_vess_code vess_code, a.voya_voyage_date voyage_date,
       a.rank_code, a.title, a.dt_embarked, a.basic_rate, a.basic_rate_g, a.seq_no,
       a.tran_no_embarked, a.orig_list, a.created_by, a.dt_created, a.modified_by, a.dt_modified
from cms_voyage_crew a, cms_voyages b
where a.dt_disembarked is null
and   a.voya_vess_code = b.vess_code
and   a.voya_voyage_date = b.voyage_date
and   a.empl_empl_id is not null
and   b.voyage_status <> 'CN'


 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."CMS_CREW_MOVEMENTS_VW" ("PAYROLL_NO", "EMPL_ID", "VESS_CODE", "VOYAGE_ST_DATE", "VOYAGE_END_DATE", "FR_POSI_CODE", "FR_VESS_CODE", "FR_EFF_DATE", "TO_POSI_CODE", "TO_VESS_CODE", "TO_EFF_DATE", "SELECT_NO", "VOYA_TITLE", "VOYA_WENTDOWN", "VOYA_ON_BOARD", "TRAN_NO", "WENTDOWN", "STAT", "GET_PASS_DETAIL") AS
  SELECT voya.payroll_no payroll_no,
                   voya.empl_id empl_id,
                   voya.vess_code,
                   voya.voyage_st_date voyage_st_date,
                   voya.voyage_end_date voyage_end_date,
                   DECODE(emmx.fr_vess_code,NULL,NULL,'Pass') fr_posi_code,
                   emmx.fr_vess_code,
                   (DECODE(emmx.fr_vess_code,NULL,TO_DATE(NULL),TRUNC(emmo.eff_st_date-1))) fr_eff_date,
                   DECODE(emmx.to_vess_code,NULL,NULL,'Pass') to_posi_code,
                   emmx.to_vess_code,
                   (DECODE(emmx.to_vess_code,NULL,TO_DATE(NULL),emmo.eff_st_date)) TO_eff_DATE,
                   '1' SELECT_No,
                   voya.title voya_title, voya.wentdown voya_wentdown, voya.on_board voya_on_board,
                   emmo.tran_no,
                   TO_DATE(NULL) wentdown,
                   'PE' stat,
                   'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS_PAX emmx, PMS_EMPLOYEE_MOVEMENTS emmo, CMS_VOYAGE_PAX cpax, pms_crew_list voya
            WHERE emmx.tran_no = emmo.tran_no
            AND   voya.empl_id = cpax.empl_empl_id
            AND   emmo.empl_empl_id = cpax.empl_empl_id
            and   cpax.tran_no_embarked = emmo.tran_no
            and   emmo.py_status = 'POSTED'
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --pass embarked not yet disembarked
            SELECT voya.payroll_no payroll_no,
                   voya.empl_id empl_id,
                   voya.vess_code,
                   voya.voyage_st_date voyage_st_date,
                   voya.voyage_end_date voyage_end_date,
                   DECODE(emmx.fr_vess_code,NULL,NULL,'Pass') fr_posi_code, emmx.fr_vess_code, (DECODE(emmx.fr_vess_code,NULL,TO_DATE(NULL),TRUNC(emmo.eff_st_date-1))) fr_eff_date,
                   DECODE(emmx.to_vess_code,NULL,NULL,'Pass') to_posi_code, emmx.to_vess_code, (DECODE(emmx.to_vess_code,NULL,TO_DATE(NULL),emmo.eff_st_date)) TO_eff_DATE,
                   '2' SELECT_No,
                   voya.title voya_title, voya.wentdown voya_wentdown, voya.on_board voya_on_board,
                   emmo.tran_no, TO_DATE(NULL) wentdown, 'PE' stat, 'Y' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS_PAX emmx, PMS_EMPLOYEE_MOVEMENTS emmo, CMS_VOYAGE_PAX cpax, pms_crew_list voya
            WHERE emmx.tran_no = emmo.tran_no
            AND   voya.empl_id = cpax.empl_empl_id
            AND   emmo.empl_empl_id = cpax.empl_empl_id
            and   cpax.tran_no_embarked = emmo.tran_no
            and   emmo.py_status = 'POSTED'
            AND   cpax.dt_disembarked is null
            and   trunc(emmo.eff_st_date) < voya.voyage_st_date
            --and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --pass disembarked
            SELECT voya.payroll_no payroll_no,
                   voya.empl_id empl_id,
                   voya.vess_code,
                   voya.voyage_st_date voyage_st_date,
                   voya.voyage_end_date voyage_end_date,
                   'Pass', emmx.fr_vess_code, (emmo.eff_st_date-1),
                   voya.title, voya.vess_code, emmo.eff_st_date,
                   '3' SELECT_No,
                   voya.title voya_title, voya.wentdown voya_wentdown, voya.on_board voya_on_board,
                   emmo.tran_no, TO_DATE(NULL), 'PD' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS_PAX emmx, PMS_EMPLOYEE_MOVEMENTS emmo, CMS_VOYAGE_PAX cpax, pms_crew_list voya
            WHERE emmx.tran_no = emmo.tran_no
            AND   voya.empl_id = cpax.empl_empl_id
            AND   emmo.empl_empl_id = cpax.empl_empl_id
            AND   emmx.to_vess_code IS NULL
            and   emmo.py_status = 'POSTED'
            AND   cpax.tran_no_disembarked = emmo.tran_no
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --crew embarked
            SELECT voya.payroll_no payroll_no,
                   voya.empl_id empl_id,
                   voya.vess_code,
                   voya.voyage_st_date voyage_st_date,
                   voya.voyage_end_date voyage_end_date,
                   emmo.fr_posi_code, emmo.fr_vess_code, (DECODE(emmo.fr_vess_code,NULL,TO_DATE(NULL),(emmo.eff_st_date)-1)) fr_eff_date,
                   emmo.to_posi_code, emmo.to_vess_code, emmo.eff_st_date to_eff_date,
                   '4' SELECT_No,
                   voya.title voya_title, voya.wentdown voya_wentdown, voya.on_board voya_on_board,
                   emmo.tran_no, TO_DATE(NULL) wentdown,'CE' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS emmo, pms_crew_list voya
            WHERE emmo.py_status = 'POSTED'
            and   emmo.empl_empl_id = voya.empl_id
            AND   emmo.to_vess_code is not null
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            UNION ALL
            --crew disembarked
            SELECT voya.payroll_no payroll_no,
                   voya.empl_id empl_id,
                   voya.vess_code,
                   voya.voyage_st_date voyage_st_date,
                   voya.voyage_end_date voyage_end_date,
                   emmo.fr_posi_code, emmo.fr_vess_code, emmo.eff_st_date,
                   NULL, NULL, NULL,
                   '5' SELECT_No,
                   voya.title voya_title, voya.wentdown voya_wentdown, voya.on_board voya_on_board,
                   emmo.tran_no, emmo.eff_st_date, 'CD' stat, 'N' get_pass_detail
            FROM  PMS_EMPLOYEE_MOVEMENTS emmo, pms_crew_list voya
            WHERE emmo.to_vess_code IS NULL
            and   emmo.fr_vess_code IS NOT NULL
            and   trunc(emmo.eff_st_date) >= voya.voyage_st_date
            and   trunc(emmo.eff_st_date) <= voya.voyage_end_date
            and   emmo.empl_empl_id = voya.empl_id
            and   emmo.py_status = 'POSTED'
            AND   emmo.fr_vess_code is not null



 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."CMS_VOYAGE_CREW_AUDIT_VW" ("EMPL_NAME", "N_VESS_CODE", "N_VOYAGE_DATE", "N_EMPL_ID", "N_BASIC", "N_BASIC_G", "O_BASIC", "O_BASIC_G", "ACTION", "DT_CREATED", "CREATED_BY", "N_RANK", "N_TITLE", "O_RANK", "O_TITLE", "N_EMBARKED", "N_DISEMBARKED", "O_EMBARKED", "O_DISEMBARKED", "N_TRN_EMBARKED", "N_TRN_DISEMBARKED", "O_TRN_EMBARKED", "O_TRN_DISEMBARKED", "N_SEQ_NO", "O_SEQ_NO", "O_VESS_CODE", "O_VOYAGE_DATE", "O_EMPL_ID", "USER_ID", "N_ORIG_LIST", "O_ORIG_LIST", "N_PASSENGE
R", "N_APPROVED", "O_PASSENGER", "O_APPROVED", "N_CREATED_BY", "N_DT_CREATED", "O_CREATED_BY", "O_DT_CREATED", "N_MODIFIED_BY", "N_DT_MODIFIED", "O_MODIFIED_BY", "O_DT_MODIFIED") AS
  select b.Last_Name || ', ' || b.First_name || ' ' || b.Middle_name EMpl_name,
       a.NEW_VOYA_VESS_CODE N_VESS_CODE, a.NEW_VOYA_VOYAGE_DATE N_VOYAGE_DATE, a.NEW_EMPL_EMPL_ID N_EMPL_ID,
       a.NEW_BASIC_RATE N_BASIC, a.NEW_BASIC_RATE_G N_BASIC_G, a.OLD_BASIC_RATE O_BASIC, a.OLD_BASIC_RATE_G O_BASIC_G,
       a.ACTION, a.DT_CREATED, a.CREATED_BY,
       a.NEW_RANK_CODE N_RANK, a.NEW_TITLE N_TITLE, a.OLD_RANK_CODE O_RANK, a.OLD_TITLE O_TITLE,
       a.NEW_DT_EMBARKED N_EMBARKED, a.NEW_DT_DISEMBARKED N_DISEMBARKED,
       a.OLD_DT_EMBARKED O_EMBARKED, a.OLD_DT_DISEMBARKED O_DISEMBARKED,
       a.NEW_TRAN_NO_EMBARKED N_TRN_EMBARKED, a.NEW_TRAN_NO_DISEMBARKED N_TRN_DISEMBARKED,
       a.OLD_TRAN_NO_EMBARKED O_TRN_EMBARKED, a.OLD_TRAN_NO_DISEMBARKED O_TRN_DISEMBARKED,
       a.NEW_SEQ_NO N_SEQ_NO, a.OLD_SEQ_NO O_SEQ_NO,
       a.OLD_VOYA_VESS_CODE O_VESS_CODE, a.OLD_VOYA_VOYAGE_DATE O_VOYAGE_DATE, a.OLD_EMPL_EMPL_ID O_EMPL_ID,
       a.USER_ID, a.NEW_ORIG_LIST N_ORIG_LIST, a.OLD_ORIG_LIST O_ORIG_LIST,
       a.NEW_PASSENGER N_PASSENGER, a.NEW_APPROVED N_APPROVED, a.OLD_PASSENGER O_PASSENGER, a.OLD_APPROVED O_APPROVED,
       a.NEW_CREATED_BY N_CREATED_BY, a.NEW_DT_CREATED N_DT_CREATED, a.OLD_CREATED_BY O_CREATED_BY, a.OLD_DT_CREATED O_DT_CREATED,
       a.NEW_MODIFIED_BY N_MODIFIED_BY, a.NEW_DT_MODIFIED N_DT_MODIFIED, a.OLD_MODIFIED_BY O_MODIFIED_BY, a.OLD_DT_MODIFIED O_DT_MODIFIED
from pms_employees b, cms_voyage_crew_audit a
where a.new_empl_empl_id = b.empl_id

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ACC_PO_VW" ("SRC", "REF_CODE", "REF_DATE", "RR_NO", "RS_NO", "PO_NO", "AMOUNT") AS
  select 'AP' src, a.ap_no ref_code, h.ap_date ref_date, a.rr_no, a.rs_no, a.po_no, a.amount from acc_ap_inv_dtl a, acc_ap_hdr h where a.ap_no=h.ap_no and h.ap_status <> 'CANCELLED' union
select 'PCV' src, a.pcv_no, h.pcv_date, a.rr_no, a.rs_no, a.po_no, a.amount  from acc_pcv_inv_dtl a, acc_pcv_hdr h where a.is_selected='Y' and a.pcv_no = h.pcv_no and h.pcv_status <> 'CANCELLED' union
select 'CV' src, a.cv_no, h.cv_date, '' rr_no, p.rshd_rs_no rs_no, lpad(a.cpa_ref_no, 6, '0') po_no, a.cpa_amt  from acc_cv_cpa_dtl a, acc_cv_hdr h, inv_po_hdr p where a.cv_no = h.cv_no and h.cv_status <> 'CANCELLED' and a.cpa_ref_type = 'PO' and lpad(a.cpa_ref_no, 6, '0') = p.po_no

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_BORROWING_MONITORING" ("TRAN_NO", "TRAN_DATE", "BORROWER", "BORROWER_RS", "LENDER", "LENDER_RS", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "QTY") AS
  select h.tran_no,
       h.tran_date,
       h.vess_code borrower,
       d.repl_rs_no borrower_rs,
       d.vess_code lender,
       d.repl_rs_no lender_rs,
       d.item_code,
       d.cate_code,
       d.itty_code,
       d.itgr_code,
       d.uome_code,
       d.qty
from   inv_borrowing_dtl d, inv_borrowing_hdr h,
       inv_dr_vw dr, inv_iss_vw iss,
       inv_dr_vw dr2, inv_iss_vw iss2
where  d.tran_no = h.tran_no
and    h.status = 'APPROVED'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_DR_VW" ("DR_NO", "DR_DATE", "STATUS", "SUPP_CODE", "PO_NO", "RS_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "QTY", "DT_POSTED", "DT_RECEIVED", "UNIT_COST", "CURR_CNV") AS
  select a.dr_no, a.dr_date, a.status, a.supp_code, b.pohd_po_no po_no, b.rshd_rs_no rs_no,
       b.item_code, b.cate_code, b.itty_code, b.itgr_code, b.uome_code,
       b.qty, a.dt_posted, a.dt_received, b.unit_cost, a.curr_cnv
from inv_dr_hdr a, inv_dr_dtl b
where a.dr_no = b.drhd_dr_no
and   a.status <> 'CANCELLED'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ISSUANCE_MONITORING_VW" ("ISS_NO", "ISSUED_TO", "ISS_DATE", "VESS_CODE", "DR_NO", "ITEM_CODE", "ITTY_CODE", "CATE_CODE", "ITGR_CODE", "UOME_CODE", "TOGENSAN", "TOGENSAN_BY", "GENSANWH", "GENSANWH_BY", "TOLAOT", "TOLAOT_BY", "ENDUSER", "ENDUSER_BY") AS
  select a.iss_no,
       a.issued_to,
       a.iss_date,
       a.vess_code,
       b.DR_NO,
       b.ITEM_CODE,
       b.ITTY_CODE,
       b.CATE_CODE,
       b.ITGR_CODE,
       b.UOME_CODE,
       b.TOGENSAN,
       b.TOGENSAN_BY,
       b.GENSANWH,
       b.GENSANWH_BY,
       b.TOLAOT,
       b.TOLAOT_BY,
       b.ENDUSER,
       b.ENDUSER_BY
from inv_iss_hdr a, (
select ishd_iss_no,
       DR_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE,
       max(TOGENSAN) TOGENSAN, max(TOGENSAN_BY) TOGENSAN_BY,
       max(GENSANWH) GENSANWH, max(GENSANWH_BY) GENSANWH_BY,
       max(TOLAOT) TOLAOT, max(TOLAOT_BY) TOLAOT_BY,
       max(ENDUSER) ENDUSER, max(ENDUSER_BY) ENDUSER_BY
from (
select ishd_iss_no, DR_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE, dt_received TOGENSAN, RECEIVED_BY_NAME TOGENSAN_BY, null GENSANWH, null GENSANWH_BY, null TOLAOT, null TOLAOT_BY, null ENDUSER, null ENDUSER_BY from inv_iss_transfer_log where transfer_code = 'In-Transit to GenSan' union
select ishd_iss_no, DR_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE, null, null, dt_received, RECEIVED_BY_NAME, null, null, null, null from inv_iss_transfer_log where transfer_code = 'GenSan Warehouse'  union
select ishd_iss_no, DR_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE, null, null, null, null, dt_received, RECEIVED_BY_NAME, null, null from inv_iss_transfer_log where transfer_code = 'In-Transit to Laot'  union
select ishd_iss_no, DR_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE, null, null, null, null, null, null, dt_received, RECEIVED_BY_NAME from inv_iss_transfer_log where transfer_code = 'End User' ) a
group by ishd_iss_no, DR_NO, ITEM_CODE, ITTY_CODE, CATE_CODE, ITGR_CODE, UOME_CODE) b
where a.iss_no = b.ishd_iss_no

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ISS_TRANSFER_LOV" ("TR_TYPE", "ISHD_ISS_NO", "VESS_CODE", "VESSEL_NAME", "ISS_DATE", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "ITEM_NAME", "ISS_QTY", "RSHD_RS_NO", "REF_TYPE", "REF_NO", "DR_NO") AS
  SELECT 'ISSUANCE' TR_TYPE,
       ISDT.ISHD_ISS_NO ISHD_ISS_NO,
       ISHD.VESS_CODE,
       VESS.NAME VESSEL_NAME,
       ISHD.ISS_DATE,
       ISDT.ITEM_CODE,
       ISDT.CATE_CODE,
       ISDT.ITTY_CODE,
       ISDT.ITGR_CODE,
       ISDT.UOME_CODE,
       GET_ITEM_DESC(ISDT.ITEM_CODE, ISDT.CATE_CODE, ISDT.ITTY_CODE, ISDT.ITGR_CODE) ITEM_NAME,
       ISDT.ISS_QTY-(re_qty+tr_qty) ISS_QTY,
       ISDT.RSHD_RS_NO RSHD_RS_NO,
       ISDT.REF_TYPE,
       ISDT.REF_NO,
       ISDT.DR_NO
FROM   INV_ISS_HDR ISHD, INV_ISS_DTL ISDT, INV_VESSELS VESS
WHERE  ISHD.ISS_NO = ISDT.ISHD_ISS_NO
AND    ISHD.STATUS = 'APPROVED'
AND    ISHD.VESS_CODE = VESS.CODE
-- union
-- SELECT 'TRANSFER' TR_TYPE,
--        TRDT.TRAN_NO,
--        TRDT.VESS_CODE_D,
--        VESS.NAME VESSEL_NAME,
--        TRHD.TRAN_DATE,
--        TRDT.ITEM_CODE,
--        TRDT.CATE_CODE,
--        TRDT.ITTY_CODE,
--        TRDT.ITGR_CODE,
--        TRDT.UOME_CODE,
--        GET_ITEM_DESC(TRDT.ITEM_CODE, TRDT.CATE_CODE, TRDT.ITTY_CODE, TRDT.ITGR_CODE) ITEM_NAME,
--        TRDT.QTY-(re_qty+tr_qty) ISS_QTY,
--        TRDT.RSHD_RS_NO RSHD_RS_NO,
--        TRDT.REF_TYPE,
--        TRDT.REF_NO,
--        TRDT.DR_NO
-- FROM   INV_TRANSFER_HDR TRHD, INV_TRANSFER_DTL TRDT, INV_VESSELS VESS
-- WHERE  TRHD.TRAN_NO = TRDT.TRAN_NO
-- AND    TRHD.STATUS = 'APPROVED'
-- AND    VESS.CODE = TRDT.VESS_CODE_D
ORDER BY ISS_DATE DESC, ISHD_ISS_NO

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ISS_VW" ("DR_NO", "DR_DATE", "STATUS", "SUPP_CODE", "PO_NO", "RS_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "QTY", "DT_POSTED", "DT_RECEIVED") AS
  select a.dr_no, a.dr_date, a.status, a.supp_code, b.pohd_po_no po_no, b.rshd_rs_no rs_no, b.item_code, b.cate_code, b.itty_code, b.itgr_code, b.uome_code, b.qty, a.dt_posted, a.dt_received
from inv_dr_hdr a, inv_dr_dtl b
where a.dr_no = b.drhd_dr_no
and   a.status <> 'CANCELLED'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ITEM_REQSLIP_VW" ("ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "WARE_CODE", "AVAIL_QTY", "ALLOC_QTY", "RESERVED_QTY") AS
  select item_code, cate_code, itty_code, itgr_code, uome_code, ware_code, sum(avail_qty) avail_qty, sum(alloc_qty) alloc_qty, sum(reserved_qty) reserved_qty from (
         select iw.item_code, iw.cate_code, iw.itty_code, iw.itgr_code, iw.uome_code, iw.ware_code, sum(iw.qty_avail) avail_qty, sum(iw.qty_alloc) alloc_qty, 0 reserved_qty
         from   inv_item_ware iw
         group by iw.item_code, iw.cate_code, iw.itty_code, iw.itgr_code, iw.uome_code, iw.ware_code
         union
         select rsdt.item_code, rsdt.cate_code, rsdt.itty_code, rsdt.itgr_code, rsdt.uome_code, rsdt.ware_code, 0, 0, sum(rsdt.approved_qty) reserved_qty
         from   inv_reqslip_hdr rshd, inv_reqslip_dtl rsdt
         where  rshd.with_stock = 'Y'
         and    rsdt.rshd_rs_no = rshd.rs_no
         and    rshd.status not in ('DISAPPROVED','CANCELLED')
         and    rshd.rs_iss_status <> 'FULLY ISSUED'
         group by rsdt.item_code, rsdt.cate_code, rsdt.itty_code, rsdt.itgr_code, rsdt.uome_code, rsdt.ware_code) a
         group by item_code, cate_code, itty_code, itgr_code, uome_code, ware_code

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ITEM_SEARCH_VW" ("ITEM_CODE", "ITEM_NAME") AS
  select code item_code, get_item_desc(code, cate_code, itty_code, itgr_code) item_name
from   inv_items



 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_ITEM_WARE_BEGBAL_NEW" ("ITEM_CODE", "ITTY_CODE", "ITGR_CODE", "CATE_CODE", "UOME_CODE", "POSTED_DT") AS
  select item_code, itty_code, itgr_code, cate_code, uome_code, max(posted_dt) posted_dt from inv_item_ware_begbal
where posted_dt is not null
group by item_code, itty_code, itgr_code, cate_code, uome_code


 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_JO_STOCKS" ("TRAN_TYPE", "REF_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "DT_CREATED", "STATUS", "SUPP_CODE", "INTENDED_FOR", "SUPP_NAME", "VESS_NAME", "COMPLAINTS", "FINDINGS", "REMARKS") AS
  SELECT 'JODR' "TRAN_TYPE", jodrhd.jo_dr_no REF_NO, jodrhd.item_code, jodrhd.cate_code, jodrhd.itty_code, jodrhd.itgr_code, jodrhd.dt_created, jodrhd.status, johd.supp_code, johd.intended_for, supp.NAME supp_name, vess.NAME vess_name, johd.complaints, johd.findings, johd.remarks
FROM   INV_JO_DR_HDR jodrhd, inv_suppliers supp, cms_vessels vess, inv_jo_hdr johd
WHERE jodrhd.status='APPROVED'
AND   vess.code = jodrhd.intended_for
AND   supp.code = jodrhd.supp_code
AND   johd.jo_no = jodrhd.johd_jo_no
UNION ALL
SELECT 'JOIS' "TRAN_TYPE", joisdt.joishd_joiss_no REF_NO, joisdt.item_code, joisdt.cate_code, joisdt.itty_code, joisdt.itgr_code, joisdt.dt_created, joishd.status, supp_code, intended_for, supp.NAME supp_name, vess.NAME vess_name, johd.complaints, johd.findings, johd.remarks
FROM   INV_JOISS_DTL joisdt, inv_suppliers supp, cms_vessels vess, inv_jo_hdr johd, inv_joiss_hdr joishd
WHERE joishd.status='APPROVED'
AND   vess.code = johd.intended_for
AND   supp.code = johd.supp_code
AND   joisdt.joishd_joiss_no  = joishd.joiss_no
AND   joisdt.johd_jo_no = johd.jo_no
UNION ALL
SELECT 'JOHD' "TRAN_TYPE", johd.jo_no REF_NO, johd.item_code, johd.cate_code, johd.itty_code, johd.itgr_code, johd.dt_created, johd.status, supp_code, intended_for, supp.NAME supp_name, vess.NAME vess_name, johd.complaints, johd.findings, johd.remarks
FROM   INV_JO_HDR johd, inv_suppliers supp, cms_vessels vess
WHERE johd.status='APPROVED'
AND   vess.code = johd.intended_for
AND   supp.code = johd.supp_code
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_JO_WRONG_AP" ("JO_DR_NO", "JO_DR_DATE", "JOHD_JO_NO", "SUPP_CODE", "SUPP_DR_NO", "PREPARED_BY", "DT_PREPARED", "RECEIVED_BY", "DT_RECEIVED", "APPROVED_BY", "DT_APPROVED", "STATUS", "REMARKS", "CREATED_BY", "DT_CREATED", "MODIFIED_BY", "DT_MODIFIED", "INTENDED_FOR", "LABOR_DISCOUNT", "MATRL_DISCOUNT", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "ITEM_CODE", "CURRENCY", "UOME_CODE", "PAID_AMT", "RR_AMT", "RR_PAID", "CPA_AMT", "INVOICE_DT", "AP_NO", "RR_PAID_TEMP", "DISCOUN
T_AMT") AS
  select "JO_DR_NO","JO_DR_DATE","JOHD_JO_NO","SUPP_CODE","SUPP_DR_NO","PREPARED_BY","DT_PREPARED","RECEIVED_BY","DT_RECEIVED","APPROVED_BY","DT_APPROVED","STATUS","REMARKS","CREATED_BY","DT_CREATED","MODIFIED_BY","DT_MODIFIED","INTENDED_FOR","LABOR_DISCOUNT","MATRL_DISCOUNT","CATE_CODE","ITTY_CODE","ITGR_CODE","ITEM_CODE","CURRENCY","UOME_CODE","PAID_AMT","RR_AMT","RR_PAID","CPA_AMT","INVOICE_DT","AP_NO","RR_PAID_TEMP","DISCOUNT_AMT" from inv_jo_dr_hdr a where a.ap_no is not null and not exists (select 1
from acc_ap_inv_dtl b where a.jo_dr_no = b.rr_no and a.ap_no = b.ap_no and b.po_no like 'JO%')


 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_PO_VW" ("PO_NO", "PO_DATE", "STATUS", "SUPP_CODE", "RSHD_RS_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "RS_QTY", "APPROVED_QTY", "DT_APPROVED") AS
  select a.po_no, a.po_date, a.status, a.supp_code, b.rshd_rs_no, b.item_code, b.cate_code, b.itty_code, b.itgr_code, b.uome_code, b.rs_qty, b.approved_qty, a.dt_approved
from inv_po_hdr a, inv_po_dtl b
where a.po_no = b.pohd_po_no
and   a.status <> 'CANCELLED'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_PROD_MONITORING_VW" ("RS_NO", "RS_DATE", "VESS_CODE", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "PROD_START", "PRODUCTION_TIME", "PROD_STA_DT", "PROD_END_DT", "PRODUCTION_DELIVERY_PLACE", "PREPARED_BY", "PRODN_RCVD_FLAG", "PRODN_RCVD_BY", "PRODN_RCVD_DT") AS
  select rshd.rs_no,
       rshd.rs_date,
       rshd.vess_code,
       rsdt.item_code,
       rsdt.cate_code,
       rsdt.itty_code,
       rsdt.itgr_code,
       rsdt.prod_start,
       rsdt.production_time,
       pohd.po_date prod_sta_dt,
       pohd.po_date+rsdt.production_time prod_end_dt,
       rsdt.production_delivery_place,
       rshd.prepared_by,
       nvl(rsdt.prodn_rcvd_flag, 'N') prodn_rcvd_flag,
       rsdt.prodn_rcvd_by,
       rsdt.prodn_rcvd_dt
from   inv_reqslip_dtl rsdt, inv_reqslip_hdr rshd, inv_po_hdr pohd, inv_po_dtl podt
where  rshd.rs_no = rsdt.rshd_rs_no
and    rsdt.production_time is not null
and    rsdt.prodn_rcvd_dt is null
and    rsdt.prod_start = 'PO'
and    podt.rshd_rs_no = rsdt.rshd_rs_no
and    podt.item_code = rsdt.item_code
and    podt.cate_code = rsdt.cate_code
and    podt.itty_code = rsdt.itty_code
and    podt.itgr_code = rsdt.itgr_code
and    podt.pohd_po_no = pohd.po_no
and    pohd.status <> 'CANCELLED'
union all
select rshd.rs_no,
       rshd.rs_date,
       rshd.vess_code,
       rsdt.item_code,
       rsdt.cate_code,
       rsdt.itty_code,
       rsdt.itgr_code,
       rsdt.prod_start,
       rsdt.production_time,
       min(aphd.ref_date) prod_sta_dt,
       min(aphd.ref_date)+rsdt.production_time prod_end_dt,
       rsdt.production_delivery_place,
       rshd.prepared_by,
       nvl(rsdt.prodn_rcvd_flag, 'N') prodn_rcvd_flag,
       rsdt.prodn_rcvd_by,
       rsdt.prodn_rcvd_dt
from   inv_reqslip_dtl rsdt, inv_reqslip_hdr rshd, inv_rs_acc_dtl aphd
where  aphd.rs_no = rshd.rs_no
and    rshd.rs_no = rsdt.rshd_rs_no
and    rsdt.production_time is not null
and    rsdt.prodn_rcvd_dt is null
and    rsdt.prod_start = 'AP'
and    aphd.ref_status <> 'CANCELLED'
group  by rshd.rs_no,
       rshd.rs_date,
       rshd.vess_code,
       rsdt.item_code,
       rsdt.cate_code,
       rsdt.itty_code,
       rsdt.itgr_code,
       rsdt.prod_start,
       rsdt.production_time,
       rsdt.production_delivery_place,
       rshd.prepared_by,
       nvl(rsdt.prodn_rcvd_flag, 'N'),
       rsdt.prodn_rcvd_by,
       rsdt.prodn_rcvd_dt
UNION ALL
select rshd.rs_no,
       rshd.rs_date,
       rshd.vess_code,
       rsdt.item_code,
       rsdt.cate_code,
       rsdt.itty_code,
       rsdt.itgr_code,
       rsdt.prod_start,
       rsdt.production_time,
       rshd.rs_date prod_sta_dt,
       rshd.rs_date+rsdt.production_time prod_end_dt,
       rsdt.production_delivery_place,
       rshd.prepared_by,
       nvl(rsdt.prodn_rcvd_flag, 'N') prodn_rcvd_flag,
       rsdt.prodn_rcvd_by,
       rsdt.prodn_rcvd_dt
from   inv_reqslip_dtl rsdt, inv_reqslip_hdr rshd
where  rshd.rs_no = rsdt.rshd_rs_no
and    rsdt.production_time is not null
and    rsdt.prodn_rcvd_dt is null
and    rsdt.prod_start = 'RS'
and    rshd.status <> 'CANCELLED'



 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_RR_WRONG_AP" ("DR_NO", "POHD_PO_NO", "SUPP_CODE", "SUPP_DR_NO", "DR_DATE", "INVOICE_NO", "RECEIVED_BY", "DT_RECEIVED", "REMARKS", "CREATED_BY", "DT_CREATED", "MODIFIED_BY", "DT_MODIFIED", "STATUS", "POSTED_BY", "DT_POSTED", "PREPARED_BY", "DT_PREPARED", "PAID_AMT", "RR_AMT", "RR_PAID", "INVOICE_DT", "CURR_CNV", "CURRENCY", "CPA_AMT", "ADDTL_DISC", "RR_PAID_FX", "AP_NO", "RR_PAID_TEMP", "RR_PAID_FX_TEMP") AS           
  select "DR_NO","POHD_PO_NO","SUPP_CODE","SUPP_DR_NO","DR_DATE","INVOICE_NO","RECEIVED_BY","DT_RECEIVED","REMARKS","CREATED_BY","DT_CREATED","MODIFIED_BY","DT_MODIFIED","STATUS","POSTED_BY","DT_POSTED","PREPARED_BY","DT_PREPARED","PAID_AMT","RR_AMT","RR_PAID","INVOICE_DT","CURR_CNV","CURRENCY","CPA_AMT","ADDTL_DISC","RR_PAID_FX","AP_NO","RR_PAID_TEMP","RR_PAID_FX_TEMP" from inv_dr_hdr a where a.ap_no is not null and not exists (select 1                      
from acc_ap_inv_dtl b where a.dr_no = b.rr_no and a.ap_no = b.ap_no and b.po_no not like 'JO%')


 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_RS_FORSTOCK_VW" ("DR_RS_NO", "DR_VESS", "DR_DEPT", "DR_RS_DATE", "DR_NO", "WARE_CODE", "APPROVED_QTY", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "ISS_QTY", "ISS_RS_NO", "ISS_NO", "ISS_DATE", "ISS_TYPE", "VESS_CODE", "DEPT_CODE", "RS_DATE") AS
  select drdt.rshd_rs_no dr_rs_no, rsdr.vess_code dr_vess, rsdr.dept_code dr_dept, rsdr.rs_date dr_rs_date,
       isdt.dr_no, isdt.ref_no ware_code, rsdrt.approved_qty,
       isdt.item_code, isdt.cate_code, isdt.itty_code, isdt.itgr_code, isdt.uome_code, isdt.iss_qty,
       isdt.rshd_rs_no iss_rs_no, ishd.iss_no, ishd.iss_date, ishd.iss_type, ishd.vess_code, rsis.dept_code, rsis.rs_date
from   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_dr_dtl drdt,
       inv_reqslip_hdr rsis, inv_reqslip_hdr rsdr, inv_reqslip_dtl rsdrt
where  isdt.ishd_iss_no = ishd.iss_no
and    ishd.status <> 'CANCELLED'
and    isdt.ref_type = 'WR'
and    isdt.dr_no <> 'STOCK'
and    isdt.item_code = drdt.item_code
and    isdt.cate_code = drdt.cate_code
and    isdt.itty_code = drdt.itty_code
and    isdt.itgr_code = drdt.itgr_code
and    isdt.uome_code = drdt.uome_code
and    isdt.dr_no = drdt.drhd_dr_no
and    rsdr.rs_no = drdt.rshd_rs_no
and    rsis.rs_no = isdt.rshd_rs_no
and    rsdrt.rshd_rs_no = rsdr.rs_no
and    drdt.item_code = rsdrt.item_code
and    drdt.cate_code = rsdrt.cate_code
and    drdt.itty_code = rsdrt.itty_code
and    drdt.itgr_code = rsdrt.itgr_code
and    drdt.uome_code = rsdrt.uome_code
and    drdt.rshd_rs_no = rsdrt.rshd_rs_no

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_GENSAN_HIST_SUMMARY" ("TRAN_TYPE", "REF_NO", "DT_CREATED", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "CURRENCY", "UNIT_COST", "OUT_QTY", "OUT_QTY_ALLOC", "IN_QTY", "IN_QTY_ALLOC", "BALANCE", "BALANCE_ALLOC", "OUT_COST", "IN_COST", "BALANCE_COST", "OUT_COST_PHP", "IN_COST_PHP", "BALANCE_COST_PHP", "REFERENCE", "OFC_CODE") AS
  SELECT   tran_type, ref_no, dt_created, item_code, cate_code, itty_code
         , itgr_code, uome_code, currency, unit_cost
         , DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) out_qty
         , DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) out_qty_alloc
         , DECODE (tran_type, 'DR',  qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) in_qty
         , DECODE (tran_type, 'DR',  qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty, 0) in_qty_alloc
         , SUM  ( DECODE ( tran_type, 'DR', qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance
         , SUM  ( DECODE ( tran_type, 'DR', qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_alloc
         , DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) out_cost
         , DECODE (tran_type, 'DR', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) in_cost
         , SUM ( DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost
         , DECODE (tran_type, 'ISS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'RET', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) out_cost_php
         , DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) in_cost_php
         , SUM ( DECODE ( tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost_php
         , REFERENCE
         , OFC_CODE
  FROM     inv_stocks_gensan_history
  ORDER BY item_code
         , cate_code
         , itty_code
         , itgr_code
         , uome_code
         , dt_created
         , tran_type

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_GENSAN_ORIG" ("TRAN_TYPE", "REF_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "QTY", "QTY_ALLOC", "CURRENCY", "UNIT_COST", "UNIT_COST_PHP", "DT_CREATED", "REFERENCE", "OFC_CODE") AS
  SELECT 'DR' "TRAN_TYPE", drhd.dr_no ref_no, drdt.item_code, drdt.cate_code
       , drdt.itty_code, drdt.itgr_code, drdt.uome_code
       , decode (rehd.for_stock, 'Y', drdt.qty, 0) qty
       , decode (rehd.for_stock, 'N', drdt.qty, 0) qty_alloc
       , drdt.currency, drdt.unit_cost
       , drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --drhd.dt_created ,
         nvl(drhd.dt_modified,drhd.dt_created) dt_created, drhd.supp_code "REFERENCE"
       , drhd.ofc_code
  FROM   inv_dr_dtl drdt, inv_dr_hdr drhd, inv_reqslip_hdr rehd
  WHERE  drhd.dr_no = drdt.drhd_dr_no AND drhd.status = 'POSTED'
  AND    drhd.ofc_code = 'GENSAN'
  AND    drdt.rshd_rs_no = rehd.rs_no
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code
       , decode (rehd.for_stock, 'Y', isdt.iss_qty, 0) qty
       , decode (rehd.for_stock, 'N', isdt.iss_qty, 0) qty_alloc
       , drdt.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --ishd.dt_created,
         ishd.dt_modified dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_dr_dtl drdt, inv_dr_hdr drhd, inv_reqslip_hdr rehd
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    isdt.ref_type = 'DR'
  AND    isdt.ref_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    ishd.status = 'APPROVED'
  AND    drdt.item_code = isdt.item_code
  AND    drdt.cate_code = isdt.cate_code
  AND    drdt.itty_code = isdt.itty_code
  AND    drdt.itgr_code = isdt.itgr_code
  AND    drdt.uome_code = isdt.uome_code
  AND    ishd.ofc_code = 'GENSAN'
  AND    drdt.rshd_rs_no = rehd.rs_no
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code
       , isdt.iss_qty
       , 0 qty_alloc
       , iware.currency
       , iware.unit_cost, iware.unit_cost unit_cost_php
       ,
         --ishd.dt_created,
         nvl(ishd.dt_modified,ishd.dt_created) dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_item_ware iware
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    ishd.status = 'APPROVED'
  AND    isdt.item_code = iware.item_code
  AND    isdt.cate_code = iware.cate_code
  AND    isdt.itty_code = iware.itty_code
  AND    isdt.itgr_code = iware.itgr_code
  AND    isdt.uome_code = iware.uome_code
  AND    isdt.rshd_rs_no <> 'M000000'
  --and    isdt.item_code = 'RICE'
  AND    isdt.ref_type = 'WR'
  AND    isdt.ref_no = iware.ware_code
  AND    isdt.dr_no = iware.dr_no
  AND    isdt.dr_no = 'STOCK'
  AND    ishd.ofc_code = 'GENSAN'
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code
       , decode (rehd.for_stock, 'Y', isdt.iss_qty, 0) qty
       , decode (rehd.for_stock, 'N', isdt.iss_qty, 0) qty_alloc
       , iware.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --ishd.dt_created,
         nvl(ishd.dt_modified,ishd.dt_created) dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt
       , inv_iss_hdr ishd
       , inv_item_ware iware
       , inv_dr_dtl drdt
       , inv_dr_hdr drhd
       , inv_reqslip_hdr rehd
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    ishd.status = 'APPROVED'
  AND    isdt.item_code = iware.item_code
  AND    isdt.cate_code = iware.cate_code
  AND    isdt.itty_code = iware.itty_code
  AND    isdt.itgr_code = iware.itgr_code
  AND    isdt.uome_code = iware.uome_code
  --and    isdt.item_code = 'RICE'
  AND    isdt.ref_type = 'WR'
  AND    isdt.ref_no = iware.ware_code
  AND    isdt.dr_no = iware.dr_no
  AND    drhd.dr_no = iware.dr_no
  AND    isdt.dr_no <> 'STOCK'
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    drdt.item_code = isdt.item_code
  AND    drdt.cate_code = isdt.cate_code
  AND    drdt.itty_code = isdt.itty_code
  AND    drdt.itgr_code = isdt.itgr_code
  AND    drdt.uome_code = isdt.uome_code
  AND    ishd.ofc_code = 'GENSAN'
  AND    drdt.rshd_rs_no = rehd.rs_no
  UNION ALL
  SELECT 'RET', rthd.ret_no, rtdt.item_code, rtdt.cate_code, rtdt.itty_code
       , rtdt.itgr_code, rtdt.uome_code
       , rtdt.returned_qty
       , 0
       , drdt.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --rthd.dt_created,
         nvl(rthd.dt_modified,rthd.dt_created) dt_created, rthd.supp_code
       , drhd.ofc_code
  FROM   inv_retslip_dtl rtdt
       , inv_retslip_hdr rthd
       , inv_dr_dtl drdt
       , inv_dr_hdr drhd
  WHERE  rtdt.rthd_ret_no = rthd.ret_no
  AND    rtdt.drhd_dr_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    rthd.status = 'APPROVED'
  AND    drdt.item_code = rtdt.item_code
  AND    drdt.cate_code = rtdt.cate_code
  AND    drdt.itty_code = rtdt.itty_code
  AND    drdt.itgr_code = rtdt.itgr_code
  AND    drdt.uome_code = rtdt.uome_code
  AND    drhd.ofc_code = 'GENSAN'
  UNION ALL
  SELECT 'TRANSFER', sthd.st_no, stdt.item_code, stdt.cate_code
       , stdt.itty_code, stdt.itgr_code, stdt.uome_code
       , stdt.qty
       , 0
       , NVL ( drdt.currency, 'PHP' ), NVL ( drdt.unit_cost, 0 )
       , drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --sthd.dt_created ,
         nvl(sthd.dt_modified,sthd.dt_created) dt_created, sthd.ware_code
       , drhd.ofc_code
  FROM   inv_st_dtl stdt, inv_st_hdr sthd, inv_dr_dtl drdt, inv_dr_hdr drhd
  WHERE  stdt.sthd_st_no = sthd.st_no
  AND    stdt.dr_no = drhd.dr_no
  AND    stdt.dr_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    sthd.status = 'APPROVED'
  AND    sthd.rehd_re_no <> '000000'
  AND    drdt.item_code = stdt.item_code
  AND    drdt.cate_code = stdt.cate_code
  AND    drdt.itty_code = stdt.itty_code
  AND    drdt.itgr_code = stdt.itgr_code
  AND    drdt.uome_code = stdt.uome_code
  AND    drhd.ofc_code = 'GENSAN'
  UNION ALL
  SELECT 'BEG_BAL', '00000', iwbb.item_code, iwbb.cate_code
       , iwbb.itty_code, iwbb.itgr_code, iwbb.uome_code
       , iwbb.qty
       , iwbb.qty_alloc
       , 'PHP', 0
       , 0 unit_cost_php,
                         --iwbb.dt_created ,
                         iwbb.posted_dt dt_created, iwbb.ware_code
       , 'GENSAN' ofc_code
  FROM   inv_item_ware_begbal iwbb
  WHERE  iwbb.posted_dt is not null
  and    iwbb.dr_no = '000000'
  and    iwbb.ware_code = '00004'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_GENSAN_SUMMARY" ("TRAN_TYPE", "REF_NO", "DT_CREATED", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "CURRENCY", "UNIT_COST", "OUT_QTY", "OUT_QTY_ALLOC", "IN_QTY", "IN_QTY_ALLOC", "BALANCE", "BALANCE_ALLOC", "OUT_COST", "IN_COST", "BALANCE_COST", "OUT_COST_PHP", "IN_COST_PHP", "BALANCE_COST_PHP", "REFERENCE", "OFC_CODE") AS
  SELECT   tran_type, ref_no, dt_created, item_code, cate_code, itty_code
         , itgr_code, uome_code, currency, unit_cost
         , DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) out_qty
         , DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) out_qty_alloc
         , DECODE (tran_type, 'DR',  qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) in_qty
         , DECODE (tran_type, 'DR',  qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty, 0) in_qty_alloc
         , SUM  ( DECODE ( tran_type, 'DR', qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance
         , SUM  ( DECODE ( tran_type, 'DR', qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_alloc
         , DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) out_cost
         , DECODE (tran_type, 'DR', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) in_cost
         , SUM ( DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost
         , DECODE (tran_type, 'ISS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'RET', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) out_cost_php
         , DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) in_cost_php
         , SUM ( DECODE ( tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost_php
         , REFERENCE
         , OFC_CODE
  FROM     inv_stocks_gensan
  ORDER BY item_code
         , cate_code
         , itty_code
         , itgr_code
         , uome_code
         , dt_created
         , tran_type

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_HISTORY_SUMMARY" ("TRAN_TYPE", "REF_NO", "DT_CREATED", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "CURRENCY", "UNIT_COST", "OUT_QTY", "OUT_QTY_ALLOC", "IN_QTY", "IN_QTY_ALLOC", "BALANCE", "BALANCE_ALLOC", "OUT_COST", "IN_COST", "BALANCE_COST", "OUT_COST_PHP", "IN_COST_PHP", "BALANCE_COST_PHP", "REFERENCE", "OFC_CODE") AS
  SELECT   tran_type, ref_no, dt_created, item_code, cate_code, itty_code
         , itgr_code, uome_code, currency, unit_cost
         , DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) out_qty
         , DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) out_qty_alloc
         , DECODE (tran_type, 'DR',  qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) in_qty
         , DECODE (tran_type, 'DR',  qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) in_qty_alloc
         , SUM  ( DECODE ( tran_type, 'DR', qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance
         , SUM  ( DECODE ( tran_type, 'DR', qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_alloc
         , DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) out_cost
         , DECODE (tran_type, 'DR', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) in_cost
         , SUM ( DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost
         , DECODE (tran_type, 'ISS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'RET', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) out_cost_php
         , DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) in_cost_php
         , SUM ( DECODE ( tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost_php
         , REFERENCE
         , OFC_CODE
  FROM     inv_stocks_history
  ORDER BY item_code
         , cate_code
         , itty_code
         , itgr_code
         , uome_code
         , dt_created
         , tran_type

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_ORIG" ("TRAN_TYPE", "REF_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "QTY", "QTY_ALLOC", "CURRENCY", "UNIT_COST", "UNIT_COST_PHP", "DT_CREATED", "REFERENCE", "OFC_CODE") AS
  SELECT 'DR' "TRAN_TYPE", drhd.dr_no ref_no, drdt.item_code, drdt.cate_code
       , drdt.itty_code, drdt.itgr_code, drdt.uome_code
       , decode (rehd.for_stock, 'Y', drdt.qty, 0) qty
       , decode (rehd.for_stock, 'N', drdt.qty, 0) qty_alloc
       , drdt.currency, drdt.unit_cost
       , drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --drhd.dt_created ,
         nvl(drhd.dt_modified,drhd.dt_created) dt_created, drhd.supp_code "REFERENCE"
       , drhd.ofc_code
  FROM   inv_dr_dtl drdt, inv_dr_hdr drhd, inv_reqslip_hdr rehd
  WHERE  drhd.dr_no = drdt.drhd_dr_no AND drhd.status = 'POSTED'
  AND    drhd.ofc_code = 'HO'
  AND    drdt.rshd_rs_no = rehd.rs_no
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code
       , decode (rehd.for_stock, 'Y', isdt.iss_qty, 0) qty
       , decode (rehd.for_stock, 'N', isdt.iss_qty, 0) qty_alloc
       , drdt.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --ishd.dt_created,
         ishd.dt_modified dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_dr_dtl drdt, inv_dr_hdr drhd, inv_reqslip_hdr rehd
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    isdt.ref_type = 'DR'
  AND    isdt.ref_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    ishd.status = 'APPROVED'
  AND    drdt.item_code = isdt.item_code
  AND    drdt.cate_code = isdt.cate_code
  AND    drdt.itty_code = isdt.itty_code
  AND    drdt.itgr_code = isdt.itgr_code
  AND    drdt.uome_code = isdt.uome_code
  AND    ishd.ofc_code = 'HO'
  AND    drdt.rshd_rs_no = rehd.rs_no
  UNION ALL
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code
       , isdt.iss_qty qty
       , 0 qty_alloc
       , iware.currency
       , iware.unit_cost, iware.unit_cost unit_cost_php
       ,
         --ishd.dt_created,
         nvl(ishd.dt_modified,ishd.dt_created) dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt, inv_iss_hdr ishd, inv_item_ware iware
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    ishd.status = 'APPROVED'
  AND    isdt.item_code = iware.item_code
  AND    isdt.cate_code = iware.cate_code
  AND    isdt.itty_code = iware.itty_code
  AND    isdt.itgr_code = iware.itgr_code
  AND    isdt.uome_code = iware.uome_code
  AND    isdt.rshd_rs_no <> 'M000000'
  --and    isdt.item_code = 'RICE'
  AND    isdt.ref_type = 'WR'
  AND    isdt.ref_no = iware.ware_code
  AND    isdt.dr_no = iware.dr_no
  AND    isdt.dr_no = 'STOCK'
  AND    ishd.ofc_code = 'HO'
  UNION ALL
  -- these are all with stock transactions and are sourced from warehouse
  SELECT 'ISS', iss_no, isdt.item_code, isdt.cate_code, isdt.itty_code
       , isdt.itgr_code, isdt.uome_code
       -- , decode (rehd.for_stock, 'Y', isdt.iss_qty, 0) qty
       -- , decode (rehd.for_stock, 'N', isdt.iss_qty, 0) qty_alloc
       , isdt.iss_qty qty
       , 0 qty_alloc
       , iware.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --ishd.dt_created,
         nvl(ishd.dt_modified,ishd.dt_created) dt_created, ishd.vess_code
       , ishd.ofc_code
  FROM   inv_iss_dtl isdt
       , inv_iss_hdr ishd
       , inv_item_ware iware
       , inv_dr_dtl drdt
       , inv_dr_hdr drhd
       -- , inv_reqslip_hdr rehd
  WHERE  ishd.iss_no = isdt.ishd_iss_no
  AND    ishd.status = 'APPROVED'
  AND    isdt.item_code = iware.item_code
  AND    isdt.cate_code = iware.cate_code
  AND    isdt.itty_code = iware.itty_code
  AND    isdt.itgr_code = iware.itgr_code
  AND    isdt.uome_code = iware.uome_code
  AND    isdt.ref_type = 'WR'
  AND    isdt.ref_no = iware.ware_code
  AND    isdt.dr_no = iware.dr_no
  AND    drhd.dr_no = iware.dr_no
  AND    isdt.dr_no <> 'STOCK'
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    drdt.item_code = isdt.item_code
  AND    drdt.cate_code = isdt.cate_code
  AND    drdt.itty_code = isdt.itty_code
  AND    drdt.itgr_code = isdt.itgr_code
  AND    drdt.uome_code = isdt.uome_code
  AND    ishd.ofc_code = 'HO'
  -- AND    drdt.rshd_rs_no = rehd.rs_no
  UNION ALL
  SELECT 'RET', rthd.ret_no, rtdt.item_code, rtdt.cate_code, rtdt.itty_code
       , rtdt.itgr_code, rtdt.uome_code
       , rtdt.returned_qty
       , 0
       , drdt.currency
       , drdt.unit_cost, drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --rthd.dt_created,
         nvl(rthd.dt_modified,rthd.dt_created) dt_created, rthd.supp_code
       , drhd.ofc_code
  FROM   inv_retslip_dtl rtdt
       , inv_retslip_hdr rthd
       , inv_dr_dtl drdt
       , inv_dr_hdr drhd
  WHERE  rtdt.rthd_ret_no = rthd.ret_no
  AND    rtdt.drhd_dr_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    rthd.status = 'APPROVED'
  AND    drdt.item_code = rtdt.item_code
  AND    drdt.cate_code = rtdt.cate_code
  AND    drdt.itty_code = rtdt.itty_code
  AND    drdt.itgr_code = rtdt.itgr_code
  AND    drdt.uome_code = rtdt.uome_code
  AND    drhd.ofc_code = 'HO'
  UNION ALL
  SELECT 'TRANSFER', sthd.st_no, stdt.item_code, stdt.cate_code
       , stdt.itty_code, stdt.itgr_code, stdt.uome_code
       , stdt.qty
       , 0
       , NVL ( drdt.currency, 'PHP' ), NVL ( drdt.unit_cost, 0 )
       , drdt.unit_cost * drhd.curr_cnv unit_cost_php
       ,
         --sthd.dt_created ,
         nvl(sthd.dt_modified,sthd.dt_created) dt_created, sthd.ware_code
       , drhd.ofc_code
  FROM   inv_st_dtl stdt, inv_st_hdr sthd, inv_dr_dtl drdt, inv_dr_hdr drhd
  WHERE  stdt.sthd_st_no = sthd.st_no
  AND    stdt.dr_no = drhd.dr_no

  AND    stdt.dr_no = drdt.drhd_dr_no
  AND    drhd.dr_no = drdt.drhd_dr_no
  AND    sthd.status = 'APPROVED'
  AND    sthd.rehd_re_no <> '000000'
  AND    drdt.item_code = stdt.item_code
  AND    drdt.cate_code = stdt.cate_code
  AND    drdt.itty_code = stdt.itty_code
  AND    drdt.itgr_code = stdt.itgr_code
  AND    drdt.uome_code = stdt.uome_code
  AND    drhd.ofc_code = 'HO'
  UNION ALL
  -- SELECT 'TRANSFER', sthd.st_no, stdt.item_code, stdt.cate_code
  --      , stdt.itty_code, stdt.itgr_code, stdt.uome_code
  --      , stdt.qty
  --      , 0
  --      , 'PHP', 0
  --      , 0 unit_cost_php,
  --                        --sthd.dt_created ,
  --                        sthd.dt_modified dt_created, sthd.ware_code
  --      , 'HO' ofc_code
  -- FROM   inv_st_dtl stdt, inv_st_hdr sthd
  -- WHERE  stdt.sthd_st_no = sthd.st_no
  -- AND    sthd.status = 'APPROVED'
  -- AND    sthd.rehd_re_no <> '000000'
  -- UNION ALL
  SELECT 'TRANSFERH', sthd.st_no, stdt.item_code, stdt.cate_code
       , stdt.itty_code, stdt.itgr_code, stdt.uome_code
       , stdt.qty
       , 0
       , 'PHP', 0
       , 0 unit_cost_php,
                         --sthd.dt_created ,
                         nvl(sthd.dt_modified,sthd.dt_created) dt_created, sthd.ware_code
       , 'HO' ofc_code
  FROM   inv_st_dtl stdt, inv_st_hdr sthd
  WHERE  stdt.sthd_st_no = sthd.st_no
  AND    sthd.status = 'APPROVED'
  AND    sthd.rehd_re_no = '000000'
  UNION ALL
  SELECT 'BEG_BAL', '00000', iwbb.item_code, iwbb.cate_code
       , iwbb.itty_code, iwbb.itgr_code, iwbb.uome_code
       , iwbb.qty
       , iwbb.qty_alloc
       , 'PHP', 0
       , 0 unit_cost_php,
                         --iwbb.dt_created ,
                         iwbb.posted_dt dt_created, iwbb.ware_code
       , 'HO' ofc_code
  FROM   inv_item_ware_begbal iwbb
  WHERE  iwbb.posted_dt is not null
  and    iwbb.dr_no = '000000'
  and    iwbb.ware_code <> '00004'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_SUMMARY" ("TRAN_TYPE", "REF_NO", "DT_CREATED", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "CURRENCY", "UNIT_COST", "OUT_QTY", "OUT_QTY_ALLOC", "IN_QTY", "IN_QTY_ALLOC", "BALANCE", "BALANCE_ALLOC", "OUT_COST", "IN_COST", "BALANCE_COST", "OUT_COST_PHP", "IN_COST_PHP", "BALANCE_COST_PHP", "REFERENCE", "OFC_CODE") AS
  SELECT   tran_type, ref_no, dt_created, item_code, cate_code, itty_code
         , itgr_code, uome_code, currency, unit_cost
         , DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) out_qty
         , DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) out_qty_alloc
         , DECODE (tran_type, 'DR',  qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) in_qty
         , DECODE (tran_type, 'DR',  qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) in_qty_alloc
         , SUM  ( DECODE ( tran_type, 'DR', qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance
         , SUM  ( DECODE ( tran_type, 'DR', qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_alloc
         , DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) out_cost
         , DECODE (tran_type, 'DR', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) in_cost
         , SUM ( DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost
         , DECODE (tran_type, 'ISS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'RET', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) out_cost_php
         , DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) in_cost_php
         , SUM ( DECODE ( tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost_php
         , REFERENCE
         , OFC_CODE
  FROM     inv_stocks
  -- WHERE  dt_created >= to_date('20121201','YYYYMMDD')
  -- WHERE  dt_created >= to_date('20140728','YYYYMMDD')
  ORDER BY item_code
         , cate_code
         , itty_code
         , itgr_code
         , uome_code
         , dt_created
         , tran_type

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_STOCKS_SUMMARY_GENSAN" ("TRAN_TYPE", "REF_NO", "DT_CREATED", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "CURRENCY", "UNIT_COST", "OUT_QTY", "OUT_QTY_ALLOC", "IN_QTY", "IN_QTY_ALLOC", "BALANCE", "BALANCE_ALLOC", "OUT_COST", "IN_COST", "BALANCE_COST", "OUT_COST_PHP", "IN_COST_PHP", "BALANCE_COST_PHP", "REFERENCE", "OFC_CODE") AS
  SELECT   tran_type, ref_no, dt_created, item_code, cate_code, itty_code
         , itgr_code, uome_code, currency, unit_cost
         , DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) out_qty
         , DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) out_qty_alloc
         , DECODE (tran_type, 'DR',  qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) in_qty
         , DECODE (tran_type, 'DR',  qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty, 0) in_qty_alloc
         , SUM  ( DECODE ( tran_type, 'DR', qty, 'TRANSFER', qty, 'TRANSFERH', qty, 'JO', qty, 'JODR', qty, 'BEG_BAL', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty, 'RET', qty, 'JOIS', qty, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance
         , SUM  ( DECODE ( tran_type, 'DR', qty_alloc, 'TRANSFER', qty_alloc, 'TRANSFERH', qty_alloc, 'JO', qty_alloc, 'JODR', qty_alloc, 'BEG_BAL', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS', qty_alloc, 'RET', qty_alloc, 'JOIS', qty_alloc, 0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_alloc
         , DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) out_cost
         , DECODE (tran_type, 'DR', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                              0) in_cost
         , SUM ( DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JO',        NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost
         , DECODE (tran_type, 'ISS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'RET', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) out_cost_php
         , DECODE (tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                              0 ) in_cost_php
         , SUM ( DECODE ( tran_type, 'DR',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFER',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'TRANSFERH', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JO',        NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     'JODR',      NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                     0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created )
           -
           SUM ( DECODE (tran_type, 'ISS',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'RET',  NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    'JOIS', NVL ( qty, 0 ) * NVL ( unit_cost_php, 0 ),
                                    0 ) )
           OVER ( PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code ORDER BY dt_created ) balance_cost_php
         , REFERENCE
         , OFC_CODE
  FROM     inv_stocks_gensan
  WHERE  dt_created >= to_date('20121201','YYYYMMDD')
  ORDER BY item_code
         , cate_code
         , itty_code
         , itgr_code
         , uome_code
         , dt_created
         , tran_type

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_SUMMARY" ("TRAN_TYPE", "REF_NO", "VESS_CODE", "DEPT_CODE", "REQ_NO", "PREPARED_BY", "STATUS", "DT_CREATED") AS
  SELECT 'REQUISITION' "TRAN_TYPE", rs_no "REF_NO", vess_code, dept_code, rs_no "REQ_NO", rshd.prepared_by, rshd.status, rshd.dt_created FROM INV_REQSLIP_HDR rshd
 UNION ALL
 SELECT 'CANVASS SHEET' "TRAN_TYPE", cs_no "REF_NO", vess_code, dept_code, rshd_rs_no "REQ_NO", cshd.prepared_by, cshd.status, cshd.dt_created FROM INV_CANVASS_HDR cshd, INV_REQSLIP_HDR rshd WHERE rshd.rs_no=cshd.rshd_rs_no
 UNION ALL
 SELECT 'PURCHASE ORDER' "TRAN_TYPE", po_no "REF_NO", vess_code, supp_code, rshd_rs_no "REQ_NO", pohd.prepared_by, pohd.status, pohd.dt_created FROM INV_PO_HDR pohd, INV_REQSLIP_HDR rshd WHERE rshd.rs_no=pohd.rshd_rs_no
 UNION ALL
 SELECT 'JOB REQUEST' "TRAN_TYPE", js_no "REF_NO", intended_for, get_item_desc(item_code, cate_code, itty_code, itgr_code), js_no "REQ_NO", prepared_by, status,dt_created FROM INV_JS_HDR
 UNION ALL
 SELECT 'JOB CANVASS' "TRAN_TYPE", js_no "REF_NO", intended_for, get_item_desc(item_code, cate_code, itty_code, itgr_code), js_no "REQ_NO", prepared_by, status,dt_created FROM INV_JS_HDR jshd WHERE  EXISTS (SELECT 1 FROM inv_jocs_hdr jocshd WHERE jocshd.jshd_js_no = jshd.js_no) AND    NOT EXISTS (SELECT 1 FROM inv_jo_hdr johd WHERE johd.jshd_js_no = jshd.js_no)
 UNION ALL
 SELECT 'JOB CANVASS' "TRAN_TYPE", jocs_no "REF_NO", jocshd.intended_for, get_item_desc(jocshd.item_code, jocshd.cate_code, jocshd.itty_code, jocshd.itgr_code), js_no "REQ_NO", jocshd.prepared_by, jocshd.status,jocshd.dt_created FROM INV_JS_HDR jshd, inv_jocs_hdr jocshd WHERE  jocshd.jshd_js_no = jshd.js_no AND jocshd.status='APPROVED' AND    EXISTS (SELECT 1 FROM inv_jo_hdr johd WHERE johd.jshd_js_no = jshd.js_no)
 UNION ALL
 SELECT 'JOB ORDER' "TRAN_TYPE", jo_no "REF_NO", intended_for, get_item_desc(item_code, cate_code, itty_code, itgr_code), jshd_js_no "REQ_NO", prepared_by, status,dt_created FROM INV_JO_HDR
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_VESSEL_LEDGER" ("REF_TYPE", "VESS_CODE", "REF_NO", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "QTY", "CURRENCY", "UNIT_COST", "DT_CREATED", "REFERENCE_CODE") AS
  SELECT 'ISS' ref_type, ishd.vess_code, iss_no ref_no, isdt.item_code, isdt.cate_code, isdt.itty_code, isdt.itgr_code, isdt.uome_code, isdt.iss_qty qty, drdt.currency, drdt.unit_cost, ishd.dt_created, ishd.issued_to reference_code
FROM INV_ISS_DTL isdt, INV_ISS_HDR ishd, INV_DR_DTL drdt
WHERE ishd.iss_no = isdt.ishd_iss_no
AND   isdt.ref_type = 'DR'
AND   isdt.dr_no = drdt.drhd_dr_no
AND   ishd.status = 'APPROVED'
AND   drdt.item_code = isdt.item_code
AND   drdt.cate_code = isdt.cate_code
AND   drdt.itty_code = isdt.itty_code
AND   drdt.itgr_code = isdt.itgr_code
AND   drdt.uome_code = isdt.uome_code
UNION ALL
SELECT 'RET', rshd.vess_code, ret_no, rtdt.item_code, rtdt.cate_code, rtdt.itty_code, rtdt.itgr_code, rtdt.uome_code, rtdt.returned_qty, drdt.currency, drdt.unit_cost, rtdt.dt_created, rthd.supp_code
FROM INV_RETSLIP_DTL rtdt, INV_RETSLIP_HDR rthd, INV_DR_DTL drdt, INV_REQSLIP_HDR rshd
WHERE rtdt.rthd_ret_no = rthd.ret_no
AND   rthd.drhd_dr_no  = drdt.drhd_dr_no
AND   rshd.rs_no = drdt.rshd_rs_no
AND   rthd.status = 'APPROVED'
AND   drdt.item_code = rtdt.item_code
AND   drdt.cate_code = rtdt.cate_code
AND   drdt.itty_code = rtdt.itty_code
AND   drdt.itgr_code = rtdt.itgr_code
AND   drdt.uome_code = rtdt.uome_code
UNION ALL
SELECT 'JOIS', jshd.intended_for, joishd.joiss_no, joisdt.item_code, joisdt.cate_code, joisdt.itty_code, joisdt.itgr_code, joisdt.uome_code, 1, 'PHP', Sf_Get_Repair_Cost(johd.jo_no) , joishd.joiss_date, joishd.issued_to
FROM   INV_JOISS_HDR joishd, INV_JOISS_DTL joisdt, INV_JO_HDR johd, INV_JS_HDR jshd
WHERE  joishd.status='APPROVED'
AND    joishd.joiss_no = joisdt.joishd_joiss_no
AND    joisdt.johd_jo_no = johd.jo_no
AND    johd.jshd_js_no = jshd.js_no
UNION ALL
SELECT 'RE', rshd.vess_code, re_no, redt.item_code, redt.cate_code, redt.itty_code, redt.itgr_code, redt.uome_code, redt.returned_qty, drdt.currency, drdt.unit_cost, redt.dt_created, rehd.returned_by
FROM INV_RE_DTL redt, INV_RE_HDR rehd, INV_DR_DTL drdt, INV_REQSLIP_HDR rshd
WHERE redt.rehd_re_no = rehd.re_no
AND   redt.drhd_dr_no  = drdt.drhd_dr_no
AND   rshd.rs_no = drdt.rshd_rs_no
AND   rehd.status = 'APPROVED'
AND   drdt.item_code = redt.item_code
AND   drdt.cate_code = redt.cate_code
AND   drdt.itty_code = redt.itty_code
AND   drdt.itgr_code = redt.itgr_code
AND   drdt.uome_code = redt.uome_code
AND   rehd.re_type   = 'TRS'
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_VESSEL_LEDGER_SUMMARY" ("REF_TYPE", "REF_NO", "VESS_CODE", "DT_CREATED", "ITEM_CODE", "CATE_CODE", "ITTY_CODE", "ITGR_CODE", "UOME_CODE", "CURRENCY", "UNIT_COST", "OUT_QTY", "IN_QTY", "BALANCE", "OUT_COST", "IN_COST", "BALANCE_COST", "REFERENCE_CODE") AS
  SELECT ref_type, ref_no, vess_code, dt_created, item_code, cate_code, itty_code, itgr_code, uome_code, currency, unit_cost,
DECODE(ref_type,'ISS',qty,'JOIS',qty, 0) OUT_QTY, DECODE(ref_type,'RET',qty,'RE',qty,0) IN_QTY,
     SUM(DECODE(ref_type,'ISS',qty,'JOIS',qty, 0))
    OVER (PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code
          ORDER BY dt_created  ) - SUM(DECODE(ref_type,'RET',qty,'RE',qty,0))
    OVER (PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code
          ORDER BY dt_created  )
    BALANCE,
DECODE(ref_type,'ISS',NVL(qty,0)*NVL(unit_cost,0),'JOIS',NVL(qty,0)*NVL(unit_cost,0),0) OUT_COST, DECODE(ref_type,'RE',NVL(qty,0)*NVL(unit_cost,0),'RET',NVL(qty,0)*NVL(unit_cost,0),0) IN_COST,
SUM(DECODE(ref_type,'ISS',NVL(qty,0)*NVL(unit_cost,0),'JOIS',NVL(qty,0)*NVL(unit_cost,0),0))
    OVER (PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code
          ORDER BY dt_created) -SUM(DECODE(ref_type,'RET',NVL(qty,0)*NVL(unit_cost,0),'RE',NVL(qty,0)*NVL(unit_cost,0),0))
    OVER (PARTITION BY item_code, cate_code, itty_code, itgr_code, uome_code
          ORDER BY dt_created)
    BALANCE_COST , reference_code
FROM inv_vessel_ledger
ORDER BY vess_code, item_code, cate_code, itty_code, itgr_code, uome_code, dt_created DESC
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_VESSEL_LEDGER_VW" ("TRAN_TYPE", "ISS_TYPE", "ISS_NO", "VESS_NAME", "UOME_NAME", "ITEM_DESC", "ISS_QTY", "UNIT_COST", "DISCOUNT", "TRAN_TOTAL_COST", "CATE_CODE", "ITTY_CODE", "VESS_CODE", "ISS_DATE") AS
  SELECT 'ISSUANCE' tran_type, ishd.iss_type, ishd.iss_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(isdt.item_code, isdt.cate_code, isdt.itty_code, isdt.itgr_code) item_desc, isdt.iss_qty ,
       (drdt.unit_cost*drhd.curr_cnv) unit_cost, drdt.discount, ((drdt.unit_cost*drhd.curr_cnv)*((100-drdt.discount)/100))*isdt.iss_qty tran_total_cost,
       isdt.cate_code, isdt.itty_code, ishd.vess_code, ishd.iss_date
FROM  INV_ISS_HDR ishd, INV_ISS_DTL isdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_DR_DTL drdt, INV_DR_HDR drhd
WHERE ishd.iss_no = isdt.ishd_iss_no
AND   ishd.status IN ('APPROVED','FOR APPROVAL')
AND   drhd.dr_no = drdt.drhd_dr_no
AND   ishd.vess_code = vess.code(+)
AND   isdt.uome_code = uome.code
AND   drdt.drhd_dr_no = isdt.dr_no-- OR (isdt.dr_no = 'STOCK' AND))
AND   isdt.item_code = drdt.item_code
AND   isdt.cate_code = drdt.cate_code
AND   isdt.itty_code = drdt.itty_code
AND   isdt.itgr_code = drdt.itgr_code
AND   isdt.uome_code = drdt.uome_code
UNION ALL
SELECT 'ISSUANCE' tran_type, ishd.iss_type, ishd.iss_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(isdt.item_code, isdt.cate_code, isdt.itty_code, isdt.itgr_code) item_desc, isdt.iss_qty ,
       0, 0, 0,
       isdt.cate_code, isdt.itty_code, ishd.vess_code, ishd.iss_date
FROM  INV_ISS_HDR ishd, INV_ISS_DTL isdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess
WHERE ishd.iss_no = isdt.ishd_iss_no
AND   status IN ('APPROVED','FOR APPROVAL')
AND   ishd.vess_code = vess.code(+)
AND   isdt.uome_code = uome.code
AND   isdt.dr_no = 'STOCK'
UNION ALL
SELECT 'RETURN', rehd.re_type, rehd.re_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(redt.item_code, redt.cate_code, redt.itty_code, redt.itgr_code) item_desc, redt.returned_qty,
       (drdt.unit_cost*drhd.curr_cnv) unit_cost, drdt.discount, ((drdt.unit_cost*drhd.curr_cnv)*((100-drdt.discount)/100))*redt.returned_qty total_cost,
       isdt.cate_code, isdt.itty_code, ishd.vess_code, rehd.dt_created
FROM  INV_ISS_HDR ishd, INV_ISS_DTL isdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_DR_DTL drdt, INV_RE_HDR rehd, INV_RE_DTL redt, INV_DR_HDR drhd
WHERE ishd.iss_no = isdt.ishd_iss_no
AND   ishd.status IN ('APPROVED','FOR APPROVAL')
AND   drhd.dr_no = drdt.drhd_dr_no
AND   rehd.re_no = redt.rehd_re_no
AND   rehd.status IN ('APPROVED','FOR APPROVAL')
AND   redt.ishd_iss_no = ishd.iss_no
AND   ishd.vess_code = vess.code(+)
AND   isdt.uome_code = uome.code
AND   drdt.drhd_dr_no = isdt.dr_no
AND   isdt.item_code = drdt.item_code
AND   isdt.cate_code = drdt.cate_code
AND   isdt.itty_code = drdt.itty_code
AND   isdt.itgr_code = drdt.itgr_code
AND   isdt.uome_code = drdt.uome_code
AND   isdt.item_code = redt.item_code
AND   isdt.cate_code = redt.cate_code
AND   isdt.itty_code = redt.itty_code
AND   isdt.itgr_code = redt.itgr_code
AND   isdt.uome_code = redt.uome_code
UNION ALL
SELECT 'RETURN', rehd.re_type, rehd.re_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(redt.item_code, redt.cate_code, redt.itty_code, redt.itgr_code) item_desc, redt.returned_qty,
       0, 0, 0,
       isdt.cate_code, isdt.itty_code, ishd.vess_code, rehd.dt_created
FROM  INV_ISS_HDR ishd, INV_ISS_DTL isdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_RE_HDR rehd, INV_RE_DTL redt
WHERE ishd.iss_no = isdt.ishd_iss_no
AND   ishd.status IN ('APPROVED','FOR APPROVAL')
AND   rehd.re_no = redt.rehd_re_no
AND   rehd.status IN ('APPROVED','FOR APPROVAL')
AND   redt.ishd_iss_no = ishd.iss_no
AND   ishd.vess_code = vess.code(+)
AND   isdt.uome_code = uome.code
AND   isdt.dr_no = 'STOCK'
AND   isdt.item_code = redt.item_code
AND   isdt.cate_code = redt.cate_code
AND   isdt.itty_code = redt.itty_code
AND   isdt.itgr_code = redt.itgr_code
AND   isdt.uome_code = redt.uome_code
UNION ALL
SELECT 'TRANSFER_TO', ishd.iss_type, trhd.tran_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(trdt.item_code, trdt.cate_code, trdt.itty_code, trdt.itgr_code) item_desc, trdt.qty,
       (drdt.unit_cost*drhd.curr_cnv) unit_cost, drdt.discount, ((drdt.unit_cost*drhd.curr_cnv)*((100-drdt.discount)/100))*trdt.qty total_cost,
       trdt.cate_code, trdt.itty_code, trhd.vess_code_d, trhd.tran_date
FROM  INV_TRANSFER_HDR trhd, INV_TRANSFER_DTL trdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_ISS_HDR ishd, INV_ISS_DTL isdt, INV_DR_DTL drdt, INV_DR_HDR drhd
WHERE trhd.tran_no = trdt.tran_no
-- AND   trhd.status IN ('APPROVED','FOR APPROVAL')
AND   trdt.uome_code = uome.code
AND   trhd.vess_code_d = vess.code(+)
AND   isdt.ishd_iss_no = trdt.ishd_iss_no
AND   isdt.item_code = trdt.item_code
AND   isdt.cate_code = trdt.cate_code
AND   isdt.itty_code = trdt.itty_code
AND   isdt.itgr_code = trdt.itgr_code
AND   isdt.uome_code = trdt.uome_code
AND   isdt.dr_no <> 'STOCK'
AND   ishd.iss_no = isdt.ishd_iss_no
AND   drhd.dr_no = drdt.drhd_dr_no
AND   drdt.drhd_dr_no = isdt.dr_no
AND   isdt.item_code = drdt.item_code
AND   isdt.cate_code = drdt.cate_code
AND   isdt.itty_code = drdt.itty_code
AND   isdt.itgr_code = drdt.itgr_code
AND   isdt.uome_code = drdt.uome_code
UNION ALL
SELECT 'TRANSFER_TO', ishd.iss_type, trhd.tran_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(trdt.item_code, trdt.cate_code, trdt.itty_code, trdt.itgr_code) item_desc, trdt.qty,
       0, 0, 0,
       trdt.cate_code, trdt.itty_code, trhd.vess_code_d, trhd.tran_date
FROM  INV_TRANSFER_HDR trhd, INV_TRANSFER_DTL trdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_ISS_HDR ishd, INV_ISS_DTL isdt
WHERE trhd.tran_no = trdt.tran_no
-- AND   trhd.status IN ('APPROVED','FOR APPROVAL')
AND   trdt.uome_code = uome.code
AND   trhd.vess_code_d = vess.code(+)
AND   ishd.iss_no = isdt.ishd_iss_no
AND   isdt.ishd_iss_no = trdt.ishd_iss_no
AND   isdt.item_code = trdt.item_code
AND   isdt.cate_code = trdt.cate_code
AND   isdt.itty_code = trdt.itty_code
AND   isdt.itgr_code = trdt.itgr_code
AND   isdt.uome_code = trdt.uome_code
AND   isdt.dr_no = 'STOCK'
UNION ALL
SELECT 'TRANSFER_FR', ishd.iss_type, trhd.tran_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(trdt.item_code, trdt.cate_code, trdt.itty_code, trdt.itgr_code) item_desc, trdt.qty,
       (drdt.unit_cost*drhd.curr_cnv) unit_cost, drdt.discount, ((drdt.unit_cost*drhd.curr_cnv)*((100-drdt.discount)/100))*trdt.qty total_cost,
       trdt.cate_code, trdt.itty_code, trhd.vess_code_o, trhd.tran_date
FROM  INV_TRANSFER_HDR trhd, INV_TRANSFER_DTL trdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_ISS_HDR ishd, INV_ISS_DTL isdt, INV_DR_DTL drdt, INV_DR_HDR drhd
WHERE trhd.tran_no = trdt.tran_no
-- AND   trhd.status IN ('APPROVED','FOR APPROVAL')
AND   trdt.uome_code = uome.code
AND   trhd.vess_code_o = vess.code(+)
AND   isdt.ishd_iss_no = trdt.ishd_iss_no
AND   isdt.item_code = trdt.item_code
AND   isdt.cate_code = trdt.cate_code
AND   isdt.itty_code = trdt.itty_code
AND   isdt.itgr_code = trdt.itgr_code
AND   isdt.uome_code = trdt.uome_code
AND   isdt.ref_type = trdt.ref_type
AND   isdt.ref_no = trdt.ref_no
AND   isdt.dr_no = trdt.dr_no
AND   isdt.dr_no <> 'STOCK'
AND   ishd.iss_no = isdt.ishd_iss_no
AND   drhd.dr_no = drdt.drhd_dr_no
AND   drdt.drhd_dr_no = isdt.dr_no
AND   isdt.item_code = drdt.item_code
AND   isdt.cate_code = drdt.cate_code
AND   isdt.itty_code = drdt.itty_code
AND   isdt.itgr_code = drdt.itgr_code
AND   isdt.uome_code = drdt.uome_code
UNION ALL
SELECT 'TRANSFER_FR', ishd.iss_type, trhd.tran_no, vess.NAME vess_name, uome.NAME uome_name,
       Get_Item_Desc(trdt.item_code, trdt.cate_code, trdt.itty_code, trdt.itgr_code) item_desc, trdt.qty ,
       0, 0, 0,
       trdt.cate_code, trdt.itty_code, trhd.vess_code_o, trhd.tran_date
FROM  INV_TRANSFER_HDR trhd, INV_TRANSFER_DTL trdt, INV_UNIT_OF_MEASURE uome, INV_VESSELS vess, INV_ISS_HDR ishd, INV_ISS_DTL isdt
WHERE trhd.tran_no = trdt.tran_no
-- AND   trhd.status IN ('APPROVED','FOR APPROVAL')
AND   trdt.uome_code = uome.code
AND   trhd.vess_code_o = vess.code(+)
AND   ishd.iss_no = isdt.ishd_iss_no
AND   isdt.ishd_iss_no = trdt.ishd_iss_no
AND   isdt.item_code = trdt.item_code
AND   isdt.cate_code = trdt.cate_code
AND   isdt.itty_code = trdt.itty_code
AND   isdt.itgr_code = trdt.itgr_code
AND   isdt.uome_code = trdt.uome_code
AND   isdt.ref_type = trdt.ref_type
AND   isdt.ref_no = trdt.ref_no
AND   isdt.dr_no = trdt.dr_no
AND   isdt.dr_no = 'STOCK'

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."INV_WAREHOUSE_VIEW" ("RS_DATE", "RS_NO", "VESS_NAME", "STATUS", "DESTINATION", "WITH_STOCK", "CS_NO", "CS_DATE", "CS_STATUS", "PO_NO", "PO_DATE", "PO_STATUS", "DR_NO", "DR_DATE", "DR_STATUS", "ISS_NO", "ISS_DATE", "ISS_STATUS", "RSHD_DT_CREATED") AS
  SELECT rs_date, rs_no, vess.NAME vess_name, rshd.status, vess.NAME destination, with_stock, cshd.cs_no, cshd.cs_date, cshd.status cs_status, pohd.po_no, pohd.po_date, pohd.status po_status, drhd.dr_no, drhd.dr_date, drhd.status dr_status, ishd.iss_no, ishd.iss_date, ishd.status iss_status, rshd.dt_created rshd_dt_created
FROM   INV_REQSLIP_HDR rshd, INV_VESSELS vess, INV_PO_HDR pohd, INV_DR_HDR drhd, INV_ISS_HDR ishd, INV_CANVASS_HDR cshd
WHERE  rshd.vess_code = vess.code
AND    pohd.rshd_rs_no(+) = rshd.rs_no
AND    ishd.rshd_rs_no(+) = rshd.rs_no
AND    cshd.rshd_rs_no(+) = rshd.rs_no
AND    pohd.po_no = drhd.pohd_po_no(+)
ORDER BY rs_no, cs_no, po_no, dr_no, iss_no
 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_EMPL_LATEST_MOVEMENT" ("EMPL_EMPL_ID", "DT_EMBARKED", "VESS_CODE", "POSI_CODE", "BASIC_RATE", "FR_VESS_CODE", "FR_POSI_CODE", "FR_BASIC_RATE", "EFF_EN_DATE", "TRAN_NO", "STATUS") AS
  select a.empl_empl_id, a.eff_st_date dt_embarked,
       a.to_vess_code vess_code, a.to_posi_code posi_code, a.to_basic_rate basic_rate,
       a.fr_vess_code, a.fr_posi_code, a.fr_basic_rate, a.eff_en_date, a.tran_no,
       decode(a.to_vess_code, NULL, 'DISEMBARKED', 'EMBARKED') status
from pms_employee_movements a, (select empl_empl_id, max(eff_st_date) eff_st_date
                                from pms_employee_movements
                                where py_status='POSTED'
                                group by empl_empl_id) b
where a.empl_empl_id = b.empl_empl_id
and   a.eff_st_date = b.eff_st_date
order by a.empl_empl_id

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_EMPL_LATEST_VOYAGE" ("EMPL_EMPL_ID", "DT_EMBARKED", "DT_DISEMBARKED", "VESS_CODE", "RANK_CODE", "TITLE", "BASIC_RATE", "BASIC_RATE_G", "VOYAGE_DATE", "SEQ_NO", "STATUS") AS
  select a.empl_empl_id, a.dt_embarked, a.dt_disembarked,
       a.voya_vess_code vess_code, a.rank_code, a.title,
       a.basic_rate, a.basic_rate_g, a.voya_voyage_date voyage_date, a.seq_no,
       decode(a.dt_disembarked, NULL, 'EMBARKED', 'DISEMBARKED') status
from   cms_voyage_crew a,
      (select crew.empl_empl_id, max(crew.dt_embarked) dt_embarked
       from   cms_voyage_crew crew, cms_voyages voya
       where crew.voya_vess_code = voya.vess_code
       and   crew.voya_voyage_date = voya.voyage_date
       and   voya.voyage_status <> 'CANCELLED' group by crew.empl_empl_id) b
where a.empl_empl_id = b.empl_empl_id
and   a.dt_embarked = b.dt_embarked
order by a.empl_empl_id

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_EMPL_SALDIFF" ("EMPL_ID", "LAST_NAME", "FIRST_NAME", "MIDDLE_NAME", "M_EMBARKED_DT", "M_VESSEL", "M_POSITION", "M_BASIC_RATE", "M_TRAN_NO", "C_VESSEL", "C_POSITION", "C_BASIC_RATE", "C_SEQ_NO", "C_VOYAGE_DATE", "SAL_DIFF") AS
  select a.empl_empl_id empl_id, c.last_name, c.first_name, c.middle_name,  a.dt_embarked m_embarked_dt,
       a.vess_code m_vessel, a.posi_code m_position, a.basic_rate m_basic_rate, a.tran_no m_tran_no,
       b.vess_code c_vessel, b.rank_code c_position, b.basic_rate c_basic_rate, b.seq_no c_seq_no, b.voyage_date c_voyage_date,
       a.basic_rate-b.basic_rate sal_diff
from pys_empl_latest_voyage b, pys_empl_latest_movement a, pms_employees c
where a.empl_empl_id = b.empl_empl_id
and   a.dt_embarked = b.dt_embarked
and   a.empl_empl_id = c.empl_id
order by a.empl_empl_id
--select * from PYS_EMPL_SALDIFF order by empl_id

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_HDMF_LOAN_DTL" ("PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "DEPT_CODE", "VESS_CODE", "PAG_IBIG_LOAN") AS
  select to_date('01' || to_char(period_to,'MMYYYY'), 'DDMMYYYY') period_fr,
       last_day(period_to) period_to, empl_id empl_empl_id, dept_code, vess_code, pag_ibig_loan
from   pys_payroll_summary
where  pag_ibig_loan > 0

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_PAYROLL_A" ("PAHD_PAYROLL_NO", "PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "BASIC_RATE", "NO_DAYS", "AMT", "PAGIBIG", "PAGIBIG_LOAN", "SAL_LOAN", "SSS", "SSS_LOAN", "PHILHEALTH", "WHTAX", "TITLE", "VESS_CODE", "DEPT_CODE", "OT", "COLA", "SAL_FREQ", "LATEST_VESS") AS
  select pahd_payroll_no, period_fr, period_to, empl_empl_id,
       max(basic_rate) basic_rate,
       sum(no_days) no_days,
       max(amt) amt,
       max(pagibig) pagibig,
       max(pagibig_loan) pagibig_loan,
       max(sal_loan) sal_loan,
       max(sss) sss,
       max(sss_loan) sss_loan,
       max(philhealth) philhealth,
       max(whtax) whtax,
       max(title) title,
       max(nvl(vess_code, ' ')) vess_code,
       max(nvl(dept_code,' ')) dept_code,
       sum(ot) ot,
       max(cola) cola,
       max(sal_freq) sal_freq,
       max(latest_vess) latest_vess
from
(
select d.pahd_payroll_no, d.period_fr, greatest(d.period_to,h.period_fr) period_to, d.empl_empl_id, decode(d.sal_freq,'MONTHLY',decode(d.dept_code,'FL',d.basic_rate,d.basic_rate_g),d.basic_rate_g) basic_rate, d.no_days, d.amt_g amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, d.vess_code, d.dept_code, 0 OT, 0 COLA, d.sal_freq, d.latest_vess
from   pys_payroll_dtl d, pys_payroll_hdr h
where  d.paty_code like 'REG%'
and    h.payroll_no = d.pahd_payroll_no
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,  0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, amt OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, amt COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where dety_code='HDMF LOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, null no_days, 0 amt, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, title, vess_code, dept_code, 0 OT, 0 COLA, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
)
group by pahd_payroll_no, period_fr, period_to, empl_empl_id

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_PAYROLL_B" ("PAHD_PAYROLL_NO", "PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "BASIC_RATE", "NO_DAYS", "AMT", "OT", "COLA", "PAGIBIG", "PAGIBIG_LOAN", "SAL_LOAN", "SSS", "SSS_LOAN", "PHILHEALTH", "WHTAX", "VALE", "TITLE", "VESS_CODE", "DEPT_CODE", "SAL_FREQ", "LATEST_VESS") AS
  select pahd_payroll_no, period_fr, period_to, empl_empl_id,
       basic_rate basic_rate,
       --max(no_days) no_days,
       sum(nvl(no_days,0)) no_days,
       sum(amt) amt,
       sum(ot) ot,
       max(cola) cola,
       max(pagibig) pagibig,
       max(pagibig_loan) pagibig_loan,
       max(sal_loan) sal_loan,
       max(sss) sss,
       max(sss_loan) sss_loan,
       max(philhealth) philhealth,
       max(whtax) whtax,
       max(vale) vale,
       max(title) title,
       max(nvl(vess_code, ' ')) vess_code,
       max(nvl(dept_code,' ')) dept_code,
       max(nvl(sal_freq,'AAAA')) sal_freq,
       max(latest_vess) latest_vess
from
(
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate, no_days, amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'REG%'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-EXC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, amt COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'HDMF LOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, amt VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'VALE'
)
group by pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_PAYROLL_B_20080708" ("PAHD_PAYROLL_NO", "PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "BASIC_RATE", "NO_DAYS", "AMT", "OT", "COLA", "PAGIBIG", "PAGIBIG_LOAN", "SAL_LOAN", "SSS", "SSS_LOAN", "PHILHEALTH", "WHTAX", "VALE", "TITLE", "VESS_CODE", "DEPT_CODE", "SAL_FREQ", "LATEST_VESS") AS
  select pahd_payroll_no, period_fr, period_to, empl_empl_id,
       max(basic_rate) basic_rate,
       --max(no_days) no_days,
       sum(nvl(no_days,0)) no_days,
       max(amt) amt,
       sum(ot) ot,
       max(cola) cola,
       max(pagibig) pagibig,
       max(pagibig_loan) pagibig_loan,
       max(sal_loan) sal_loan,
       max(sss) sss,
       max(sss_loan) sss_loan,
       max(philhealth) philhealth,
       max(whtax) whtax,
       max(vale) vale,
       max(title) title,
       max(nvl(vess_code, ' ')) vess_code,
       max(nvl(dept_code,' ')) dept_code,
       max(nvl(sal_freq,'AAAA')) sal_freq,
       max(latest_vess) latest_vess
from
(
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate, no_days, amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'REG%'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HOL')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HOL-FLT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL-FLT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HS')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HOL-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HS-FLT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS-FLT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-HS-OFC')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-HS-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-OFC')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-SUN')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT-SUN-FLT')) basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN-FLT')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN-OFC')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, amt COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'HDMF LOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, amt VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'VALE'
)
group by pahd_payroll_no, period_fr, period_to, empl_empl_id

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_PAYROLL_B_20080813" ("PAHD_PAYROLL_NO", "PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "BASIC_RATE", "NO_DAYS", "AMT", "OT", "COLA", "PAGIBIG", "PAGIBIG_LOAN", "SAL_LOAN", "SSS", "SSS_LOAN", "PHILHEALTH", "WHTAX", "VALE", "TITLE", "VESS_CODE", "DEPT_CODE", "SAL_FREQ", "LATEST_VESS") AS
  select pahd_payroll_no, period_fr, period_to, empl_empl_id,
       basic_rate basic_rate,
       --max(no_days) no_days,
       sum(nvl(no_days,0)) no_days,
       sum(amt) amt,
       sum(ot) ot,
       max(cola) cola,
       max(pagibig) pagibig,
       max(pagibig_loan) pagibig_loan,
       max(sal_loan) sal_loan,
       max(sss) sss,
       max(sss_loan) sss_loan,
       max(philhealth) philhealth,
       max(whtax) whtax,
       max(vale) vale,
       max(title) title,
       max(nvl(vess_code, ' ')) vess_code,
       max(nvl(dept_code,' ')) dept_code,
       max(nvl(sal_freq,'AAAA')) sal_freq,
       max(latest_vess) latest_vess
from
(
select pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate, no_days, amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'REG%'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, (basic_rate/(select a.rate from pys_payroll_types a where a.code='OT')) basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-EXC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HOL-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-HS-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
(no_days * (select a.rate from pys_payroll_types a where a.code='OT-SUN')) no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-FLT'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate,
no_days, 0 amt, amt OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code like 'OT-SUN-OFC'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, amt COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'COLA'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, amt pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PAGIBIG'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, amt pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'HDMF LOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, amt sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SALLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, amt sss, 0 sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'SSS'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, amt sss_loan, 0 philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'SSSLOAN'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, amt philhealth, 0 whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'PHILHEALTH'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, amt whtax, 0 VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  paty_code = 'WHTAX'
union all
select pahd_payroll_no, period_fr, period_to, empl_empl_id, 0 basic_rate, 0 no_days, 0 amt, 0 OT, 0 COLA, 0 pagibig, 0 pagibig_loan, 0 sal_loan, 0 sss, 0 sss_loan, 0 philhealth, 0 whtax, amt VALE, title, vess_code, dept_code, sal_freq, latest_vess
from   pys_payroll_dtl
where  dety_code = 'VALE'
)
group by pahd_payroll_no, period_fr, period_to, empl_empl_id, basic_rate

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_SSS_LOAN_DTL" ("PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "DEPT_CODE", "VESS_CODE", "SSS_LOAN") AS
  select to_date('01' || to_char(period_to,'MMYYYY'), 'DDMMYYYY') period_fr,
       last_day(period_to) period_to, empl_id empl_empl_id, dept_code, vess_code, sss_loan
from   pys_payroll_summary
where  sss_loan > 0

 /


  CREATE OR REPLACE FORCE VIEW "TPJ"."PYS_WHTAX_DEDUCTION_DTL" ("PERIOD_FR", "PERIOD_TO", "EMPL_EMPL_ID", "DEPT_CODE", "VESS_CODE", "WHTAX") AS
  select to_date('01' || to_char(period_to,'MMYYYY'), 'DDMMYYYY') period_fr,
       last_day(period_to) period_to, empl_id empl_empl_id, dept_code, vess_code, whtax
from   pys_payroll_summary
where  whtax > 0
 /
