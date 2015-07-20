create or replace procedure sp_recompute_13month (
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

