create or replace function sf_generate_item_descrtiption 
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

create public synonym sf_generate_item_descrtiption for sf_generate_item_descrtiption;
grant execute on sf_generate_item_descrtiption to public;
grant execute on sf_generate_item_descrtiption to TPJ_INV_MAINTENACE_READ;
grant execute on sf_generate_item_descrtiption to TPJ_INV_MAINTENACE_READ;



JORR no.  005215, 005216, 005217, 005219, 005236, 005237
APV no. 6969








UPDATE pms_employee_movements Set py_status='POSTED' where tran_no = '002525';
UPDATE cms_voyage_crew SET dt_disembarked = to_date('20120502', 'YYYYMMDD') where seq_no = 112 and voya_vess_code = '76' and empl_empl_id = 'P00037';
UPDATE cms_voyage_crew SET dt_disembarked = to_date('20120507', 'YYYYMMDD') where seq_no = 115 and voya_vess_code = '76' and empl_empl_id = 'P00037';
UPDATE cms_voyage_crew SET dt_embarked = to_date('20120516', 'YYYYMMDD'), dt_disembarked = null where seq_no = 27 and voya_vess_code = '76' and empl_empl_id = 'P00037';



