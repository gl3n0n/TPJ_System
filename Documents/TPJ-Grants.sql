grant select, insert, update, delete on PMS_DEPARTMENTS            to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_RANKS                  to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_POSITIONS              to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_SALARY_GRADE           to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_TYPES         to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on CMS_VESSEL_CREW            to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_LEAVE_TYPES            to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_APPLICANT_REQUIREMENTS to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_COMPANY_TRAININGS      to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_COMPANY_REWARDS        to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_POLICIES               to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_HACCP_COMPLIANCE       to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_ISPS_COMPLIANCE        to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_LICENSURE              to TPJ_PMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on PMS_POLICIES_ACTION        to TPJ_PMS_MAINTENANCE_WRITE;


grant select, insert, update, delete on PMS_APPLICANTS             to TPJ_PMS_APPLICANT_WRITE;
grant select, insert, update, delete on PMS_APPL_ALLOWANCES        to TPJ_PMS_APPLICANT_WRITE;
grant select, insert, update, delete on PMS_APPL_REQUIREMENTS      to TPJ_PMS_APPLICANT_WRITE;

grant select, insert, update, delete on PMS_EMPLOYEES              to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_FAMILIES               to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EDUCATION_TRAININGS    to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYMENT_HISTORIES   to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_MEDICAL_PROFILES       to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_REWARDS       to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_TRAININGS     to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_PERFORMANCE_APPRAISALS to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_VIOLATIONS    to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_LICENSES      to TPJ_PMS_EMPLOYEES_WRITE; 
grant select, insert, update, delete on PMS_MEDICAL_CERTIFICATES   to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_SERVICE_RECORDS        to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_MOVEMENTS     to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_MOVEMENTS_LOG to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEE_MOVEMENTS_PAX to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPL_MOVE_ALLOW        to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPL_MOVE_LOG          to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on PMS_EMPL_PAX_LOG           to TPJ_PMS_EMPLOYEES_WRITE;

grant select, insert, update, delete on PMS_LEAVE_ASSIGNMENT       to TPJ_PMS_LEAVES_WRITE;
grant select, insert, update, delete on PMS_LEAVE_RECORDS          to TPJ_PMS_LEAVES_WRITE;

grant select, insert, update, delete on PMS_VESSEL_HACCP_DTL       to TPJ_PMS_VOYAGES_WRITE;
grant select, insert, update, delete on PMS_VESSEL_HACCP_HDR       to TPJ_PMS_VOYAGES_WRITE;
grant select, insert, update, delete on PMS_VESSEL_ISPS_DTL        to TPJ_PMS_VOYAGES_WRITE;
grant select, insert, update, delete on PMS_VESSEL_ISPS_HDR        to TPJ_PMS_VOYAGES_WRITE;
grant select, insert, update, delete on CMS_VOYAGES                to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_CREW            to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on CMS_CREW_ALLOWANCES        to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_CREW_AUDIT      to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_PAX             to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_ROUTE           to TPJ_PMS_EMPLOYEES_WRITE;
grant select, insert, update, delete on CMS_VESS_CREW_ALLO         to TPJ_PMS_EMPLOYEES_WRITE;

grant select, insert, update, delete on PMS_MEMO_LOG               to TPJ_PMS_SUPER_USER;
grant select, insert, update, delete on PMS_REGULARIZATION_LOG     to TPJ_PMS_SUPER_USER;

-- on PYS
--PMS_ALLOWANCES
--PMS_ATTENDANCE_RECORDS


grant select, insert, update, delete on CMS_VESSEL_TYPES           to TPJ_CMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on CMS_VESSELS                to TPJ_CMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on CMS_FISHING_SOURCES        to TPJ_CMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on CMS_TYPE_OF_FISHES         to TPJ_CMS_MAINTENANCE_WRITE;
grant select, insert, update, delete on CMS_CATCH_LOCATIONS        to TPJ_CMS_MAINTENANCE_WRITE;

grant select, insert, update, delete on CMS_CATCHES_HDR            to TPJ_CMS_CATCH_WRITE;
grant select, insert, update, delete on CMS_CATCHES_LOG            to TPJ_CMS_CATCH_WRITE;
grant select, insert, update, delete on CMS_CATCHES_DR             to TPJ_CMS_DELIVERIES_WRITE;
grant select, insert, update, delete on CMS_CATCHES_DR_DTLS        to TPJ_CMS_DELIVERIES_WRITE;
grant select, insert, update, delete on CMS_DAILY_CATCH_SUMMARY    to TPJ_CMS_CATCH_WRITE;

-- on CMS
--CMS_VESSEL_CREW

grant select, insert, update, delete on CMS_VOYAGES                to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_CREW            to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on CMS_CREW_ALLOWANCES        to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_CREW_AUDIT      to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_PAX             to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on CMS_VOYAGE_ROUTE           to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on CMS_VESS_CREW_ALLO         to TPJ_PYS_PAYROLL_WRITE;



grant select, insert, update, delete on PYS_SSS_TABLE               to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_PHILHEALTH_TABLE        to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_TAX_TYPES               to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_TAX_HEADER              to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_WITHHOLDING_TAX         to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_TAX_EXEMPTIONS          to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_TAX_RATES               to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PMS_ALLOWANCES              to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_HOLIDAYS                to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_INCENTIVE_TYPES         to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_FULLMOON                to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_DEDUCTION_TYPES         to TPJ_PYS_MAINTENANCE_WRTIE;
grant select, insert, update, delete on PYS_PAYROLL_TYPES           to TPJ_PYS_MAINTENANCE_WRTIE;

grant select, insert, update, delete on PMS_ATTENDANCE_RECORDS      to TPJ_PYS_ATTENDANCE_WRITE;
grant select, insert, update, delete on PYS_INCENTIVES              to TPJ_PYS_INCENTIVE_WRITE;
grant select, insert, update, delete on PYS_INCENTIVE_HDR           to TPJ_PYS_INCENTIVE_WRITE;

grant select, insert, update, delete on PYS_13TH_MONTH              to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_13TH_MONTH_SUMMARY      to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_DEDUCTIONS              to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_DEDUCTIONS_LOG          to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_EMPLOYEE_ALLOWANCES     to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_EMPLOYEE_INCENTIVES     to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_EMPLOYEE_SALARY         to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_HEALTH_CONTRI_DTL       to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_HEALTH_CONTRI_HDR       to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAGIBIG_CONTRIBUTION    to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAGIBIG_CONTRI_DTL      to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAGIBIG_CONTRI_HDR      to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_A_DTL           to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_BREAK           to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_DTL             to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_DTL_ADJ_LOG     to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_DTL_CHECKED     to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_DTL_LOG         to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_HDR             to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PAYROLL_SUMMARY         to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_PHILHEALTH_CONTRIBUTION to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_SSS_CONTRIBUTION        to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_SSS_CONTRI_DTL          to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PYS_SSS_CONTRI_HDR          to TPJ_PYS_PAYROLL_WRITE;
grant select, insert, update, delete on PMS_EMPLOYEES               to TPJ_PYS_PAYROLL_WRITE;

grant select, update on PMS_EMPLOYEES to TPJ_PMS_SUPER_USER;
grant select, update on PMS_EMPLOYEES to TPJ_PYS_SUPER_USER;
grant select, update on PMS_EMPLOYEES to TPJ_CMS_SUPER_USER;
grant select, update on PMS_EMPLOYEES to TPJ_INV_SUPER_USER;
