alter table PCV_VOUCHER_HDR add pcv_payee varchar2(64) not null;
alter table PCV_VOUCHER_HDR add pcv_status varchar2(16) default 'FOR APPROVAL' not null;
