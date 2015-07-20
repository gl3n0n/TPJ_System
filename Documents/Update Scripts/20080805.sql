alter table pys_payroll_dtl add (
   adjusted varchar2(1) default 'N' not null, 
   adj_remarks varchar2(128), 
   adj_approval varchar2(1), 
   adj_approved_by varchar2(32),
   adj_approved_dt date
);

