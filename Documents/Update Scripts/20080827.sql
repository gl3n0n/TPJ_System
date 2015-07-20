# AUG 31 2008
# PAYROLL A - rate di dapat kasama ang cola. tama ang deductions(SEVILLA, JURLY at VENDERO, RAYMUNDO)
#           - error in designation (AGUSTIN, WODY)
#           - error in rate (CEDERIO, RONALD). tama ang deductions.
#           - error in rate (CUETARA, ELORDE with adjustment). tama ang deductions.
#           - department MA-CREW (SEVILLA, JURLY at VENDERO, RAYMUNDO)
# PAYSLIP - cola = actual no of days na present(hindi kasama ang holiday na hindi sya pumasok) * 5.00 (DIMERIN, ROBERT)
#         - error in cola (CEPEDA, EDWIN CALIMUTAN)
#         - malaki ang rate ng holiday (MAYOR, MARLENE)
#         
#         
# PAG-IBIG LOAN- AUG 31 2008 - may nacocompute na loan sa payroll_dtl kahit resign na at may date sa  date_disembarked sa PMST080. (CALUMPANG AURELIO)



MA-CREW. plus cola ata sila sabi ni ms jenny.
ung rate nila ay plus cola
377+5 na cola = 382 (SEVILLA JURLY)

AUG 31 2008
PAYSLIP-error ang cola ni cruz, emmanuel at bagadiong
PAYROLL A-error sa rate ni espanol, bobby (vessel paul reynald).
PAYROLL B-2 ang record ni espanol, bobby (vessel paul reynald), dapat ung isa ay 0.00 (imbes na 164.50) 
            dahil mas malaki ung isang negative na record(-1,742.70). ibabawas ung positive sa negative.
PAYROLL B - dapat lalabas ang deductions ni olmillo, rosito kahit nagresign na (may 1 day sa payroll a). 
            pero walang netamount, ilalagay na lang sa vale.

begin
   update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where empl_empl_id = 'B00001' and pay_date between to_date('20080811', 'YYYYMMDD') and to_date('20080815','YYYYMMDD');
   update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where empl_empl_id = 'C00030' and pay_date between to_date('20080811', 'YYYYMMDD') and to_date('20080815','YYYYMMDD');

   update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where empl_empl_id = 'V00013' and pay_date between to_date('20080811', 'YYYYMMDD') and to_date('20080815','YYYYMMDD');
   update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where empl_empl_id = 'S00034' and pay_date between to_date('20080811', 'YYYYMMDD') and to_date('20080815','YYYYMMDD');
   update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where empl_empl_id = 'C00024' and pay_date between to_date('20080811', 'YYYYMMDD') and to_date('20080815','YYYYMMDD');
   update pys_payroll_dtl_log set cola_pay=5, cola_day=1 where empl_empl_id = 'D00016' and pay_date between to_date('20080811', 'YYYYMMDD') and to_date('20080815','YYYYMMDD');
   commit;
end;



20080829
INVT010-commented out msg_alert when RS was already been APPROVED, CANCELLED or DISAPPROVED @ pre-update, pre-insert and pre-delete. already handled at new-record-instance block trigger.
INVT020-commented out msg_alert when RS was already been APPROVED, CANCELLED or DISAPPROVED @ pre-update, pre-insert and pre-delete. already handled at new-record-instance block trigger.
       -added msg_alert to save first before approving when there are changes made.
       -added msg_alert to save first before getting items from RS when there are changes made at detail block.
INVT030R-added display of deparment name
INVT030-added new dialog window for PO clauses.
INVM210-new module for PO Clauses.

PENDING
Testing of Job Screens
Testing of DR, ISS, Return Slip by receiveng
Printout modification ng Purchase Order Slip - added PO clause, concat with remarks.


PENDING
CATCH screens - will test by sir rene.
PO Terms on imported items - ms marlene umalis ulet sa office.
Testing Job Screens by moffats.
Testing Issuance, DR, Return Slip by tao sa baba.


            