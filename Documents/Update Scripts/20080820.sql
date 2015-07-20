truncate table pys_employee_incentives;
alter table pys_employee_incentives add period_fr date not null;
alter table pys_employee_incentives add period_to date not null;


select '01', 'January' from dual
union
select '02', 'February' from dual
union
select '03', 'March' from dual
union
select '04', 'April' from dual
union
select '05', 'May' from dual
union
select '06', 'June' from dual
union
select '07', 'July' from dual
union
select '08', 'August' from dual
union
select '09', 'September' from dual
union
select '10', 'October' from dual
union
select '11', 'November' from dual
union
select '12', 'December' from dual