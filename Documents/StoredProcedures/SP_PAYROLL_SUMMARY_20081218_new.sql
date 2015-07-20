create or replace procedure sp_payroll_summary (
   p_payroll_no in number
   ) as
   nRegDay      Number(8,4) := 0;
   nSalary      Number(8,2) := 0;
   nOtAmt       Number(8,2) := 0;
   nOtDay       Number(8,4) := 0;
   nColaAmt     Number(8,2) := 0;
   nColaDay     Number(8,4) := 0;
   nNetAmt      Number(8,2) := 0;
   nPAGIBIG     Number(8,2) := 0;
   nPHILHEALTH  Number(8,2) := 0;
   nSSS         Number(8,2) := 0;
   nWHTAX       Number(8,2) := 0;
   nPAGIBIGLOAN Number(8,2) := 0;
   nSSSLOAN     Number(8,2) := 0;
   nVALE        Number(8,2) := 0;
   nBasic       Number(8,2) := 0;
   nLBasic      Number(8,2) := 0;
   vLVess       Varchar2(16);
   vDept        Varchar2(16);
   vLTitle      Varchar2(32);
   bFirst       Boolean;
   nRecAmt      Number(10,2);
   vPrevEmplID  Varchar2(16) := 'x x x';
   dStart       Date;
   dEnd         Date;
   nPrevPayrollNo Number;
   nColaRate    Number(8,2);
   nAmt_a       Number(8,2);
   n13th_n_mon  Number(9,2);
   n13th_a      Number(9,2);  
   n13th_b      Number(9,2);  
   nSILP_a      Number(9,2);  
   nSILP_b      Number(9,2);  
   n13th_amt_a  Number(12,2);  
   n13th_amt_b  Number(12,2);
   dPeriodFr    Date;
   dPeriodTo    Date;
   vOPort       Varchar2(1);
   vLOPort      Varchar2(1);
   nOuterR      Number(8,4);
begin
   -- clear summary 
   delete from pys_payroll_summary
   where  payroll_no = p_payroll_no;
   commit;
   -- clear summary 
   delete from pys_13th_month
   where  payroll_no = p_payroll_no;
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

   for i in (select empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq, 
                    min(period_fr) period_fr, sum(no_days) no_days, sum(amt) amt, 
                    max(basic_rate_g) basic_rate_g, max(amt_g) amt_g, max(paty_code) paty_code
             from   pys_payroll_dtl
             where  pahd_payroll_no = p_payroll_no
             and    paty_code like 'REG%'
             group  by empl_empl_id, period_to, basic_rate, dept_code, title, vess_code, sal_freq
             order  by empl_empl_id, period_to desc
            )
   loop
       -- get OT total
       select nvl(sum(no_days),0) ot_days, nvl(sum(amt),0) ot_amt
       into   nOtDay, nOtAmt
       from   pys_payroll_dtl
       where  pahd_payroll_no = p_payroll_no
       and    empl_empl_id = i.empl_empl_id
       and    paty_code like 'OT%'        
       and    period_to between i.period_fr and i.period_to
       and    not exists (select 1 from pys_payroll_summary 
                           where pys_payroll_dtl.empl_empl_id = pys_payroll_summary.empl_id
                           and   pys_payroll_dtl.pahd_payroll_no = pys_payroll_summary.payroll_no
                           and   pys_payroll_dtl.period_fr = pys_payroll_summary.period_fr
                           and   pys_payroll_dtl.period_to = pys_payroll_summary.period_to
                          );

       if vPrevEmplID <> i.empl_empl_id then
          -- get COLA total
          select nvl(sum(no_days),0) cola_days, nvl(sum(amt),0) cola_amt
          into   nColaDay, nColaAmt
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    paty_code like 'COLA';
          --and    period_to between i.period_fr and i.period_to;
          nColaRate := 0;
          if i.dept_code = 'FL' then
             nColaRate := sf_get_payroll_cola(i.empl_empl_id, p_payroll_no, p_payroll_no);
          else
             if nColaAmt > 0 then
                nColaRate := (nColaAmt/nColaDay);
             end if;
          end if;
       end if;

       -- get PAGIBIG total
       begin
          select amt
          into   nPAGIBIG
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    paty_code like 'PAGIBIG'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nPAGIBIG := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for PAGIBIG amt of ' || to_char(i.empl_empl_id));
       end;
       -- get PHILHEALTH total
       begin
          select amt
          into   nPHILHEALTH
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    paty_code like 'PHILHEALTH'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nPHILHEALTH := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for PHILHEALTH amt of ' || to_char(i.empl_empl_id));
       end;
       -- get SSS total
       begin
          select amt
          into   nSSS
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    paty_code like 'SSS'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nSSS := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for SSS amt of ' || to_char(i.empl_empl_id));
       end;
       -- get WHTAX total
       begin
          select amt
          into   nWHTAX
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    paty_code like 'WHTAX'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nWHTAX := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for WHTAX amt of ' || to_char(i.empl_empl_id));
       end;
       -- get HDMF LOAN/PAGIBIGLOAN total
       begin
          select nvl(sum(amt),0)
          into   nPAGIBIGLOAN
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    dety_code like 'HDMF LOAN'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nPAGIBIGLOAN := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for PAGIBIGLOAN amt of ' || to_char(i.empl_empl_id));
       end;
       -- get SSSLOAN total
       begin
          select nvl(sum(amt),0)
          into   nSSSLOAN
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    dety_code like 'SSSLOAN'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nSSSLOAN := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for SSSLOAN amt of ' || to_char(i.empl_empl_id));
       end;
       -- get VALE total
       begin
          select nvl(sum(amt),0)
          into   nVALE
          from   pys_payroll_dtl
          where  pahd_payroll_no = p_payroll_no
          and    empl_empl_id = i.empl_empl_id
          and    dety_code like 'VALE'
          and    period_to between i.period_fr and i.period_to;
       exception
          when no_data_found then nVALE := 0;
          when too_many_rows then
             raise_application_error (-20001, 'ERROR on payroll summary for VALE amt of ' || to_char(i.empl_empl_id));
       end;

       if i.dept_code is null then
          select dept_code into vDept
          from   pms_employees
          where  empl_id = i.empl_empl_id;
       else
          vDept := i.dept_code;
       end if;

       nBasic  := i.basic_rate;
       vLOPort := 'N';
       for k in (select basic_rate, title, vess_code, paty_code
                 from   pys_payroll_dtl
                 where  empl_empl_id = i.empl_empl_id
                 and    pahd_payroll_no = p_payroll_no
                 and    paty_code like 'REG%'
                 order  by period_to desc)
       loop
          nLBasic := k.basic_rate;
          vLVess  := k.vess_code;
          vLTitle := k.title;
          if i.paty_code like 'REG-OP%' then
             vLOPort := 'Y';
          end if;
          exit;
       end loop;
       vOPort := 'N';
       if vDept = 'FL' then
          nSalary := i.amt + nOtAmt;
          nOtAmt  := 0;
          nRegDay := i.no_days + nOtDay;
          nOtDay  := 0;
       elsif vDept = 'MA-CREW' then
          nRegDay  := i.no_days;
          nSalary  := i.amt;
       else
          nSalary := i.amt;
          nRegDay := i.no_days;
          if nBasic > 10000 then
             nBasic := nBasic/30;
          end if;
          if i.paty_code like 'REG-OP%' then
             vOPort := 'Y';
          end if;
       end if;

       nNetAmt := (nSalary + nOtAmt + nColaAmt) -
                  (nPAGIBIG + nPAGIBIGLOAN + nSSS + nSSSLOAN + nPHILHEALTH + nWHTAX + nVALE);

       insert into pys_payroll_summary
              ( payroll_no, period_fr, period_to, empl_id, dept_code, vess_code,
               title, sal_freq, basic_rate, no_days, amount, cola_amt, cola_day, cola_rate,
               ot_amt, ot_day, pag_ibig_amt, pag_ibig_loan, sss_amt, sss_loan,
               medicare, whtax, vale, net_amount, l_basic_rate, l_vess_code, l_title,
               basic_rate_g, amount_g, oport, l_oport 
              )
       values ( p_payroll_no, i.period_fr, i.period_to, i.empl_empl_id, vDept, i.vess_code,
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
      vLVess       := null;
      vLTitle      := null;
      vPrevEmplID  := i.empl_empl_id;
   end loop;

   -- check employees with negative net amount
   for i in (select empl_id empl_empl_id, sum(net_amount) net_amt, sum(no_days) no_days, count(1) nRec
             from   pys_payroll_summary
             where  payroll_no = p_payroll_no
             group  by empl_id 
             having sum(net_amount) < 0 )
   loop
      bFirst := TRUE;
      nRecAmt := 0;
      for j in (select rowid, vale, net_amount 
                from   pys_payroll_summary
                where  empl_id = i.empl_empl_id
                and    payroll_no = p_payroll_no 
                for    update
                order  by net_amount desc)
      loop  
         if i.nRec = 1 then
            update pys_payroll_summary
            set    vale = (vale + net_amount),
                   net_amount = 0
            where  rowid = j.rowid;
         else
            if bFirst then
               update pys_payroll_summary
               set    net_amount =0
               where  rowid = j.rowid;
               nRecAmt := j.net_amount;
            else
               update pys_payroll_summary
               set    net_amount =0,
                      vale = net_amount + nRecAmt
               where  rowid = j.rowid;
            end if; 
         end if;
         bFirst := FALSE;
      end loop;
   end loop;
   commit;

   -- if end of month generate Payroll A Summary
   select period_fr, period_to 
   into   dStart, dEnd 
   from   pys_payroll_hdr 
   where  payroll_no = p_payroll_no;
   if to_char(dStart, 'DD') = '16' then 
      select max(payroll_no)
      into   nPrevPayrollNo
      from   pys_payroll_hdr 
      where  payroll_no < p_payroll_no;
    
      for i in (select empl_id, max(period_to) period_to, max(sal_freq) sal_freq, max(dept_code) dept_code, 
                       sum(cola_amt) cola_amt, sum(cola_day) cola_day, max(cola_rate) cola_rate
                from   pys_payroll_summary
                where  payroll_no in (nPrevPayrollNo, p_payroll_no)
                group  by empl_id)
      loop 
         for k in (select empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g, oport
                   from   pys_payroll_summary
                   where  empl_id = i.empl_id
                   and    payroll_no in (nPrevPayrollNo, p_payroll_no)
                   order  by payroll_no desc, period_to desc)
         loop 
            if i.sal_freq = 'MONTHLY' then
               nColaRate := 0;
               if i.dept_code = 'FL' then
                  if i.cola_amt > 0 then 
                     nColaRate := i.cola_rate;
                  end if;
               end if;
               update pys_payroll_summary
               set    l_vess_code_a  = k.l_vess_code,
                      l_title_a      = nvl(k.l_title, k.title),
                      l_basic_rate_a = k.basic_rate_g+nColaRate
               where  empl_id = i.empl_id
               and    payroll_no in (nPrevPayrollNo, p_payroll_no);
            else
               if i.dept_code = 'FL' then
                  nColaRate := 0;
                  if i.cola_amt > 0 then 
                     nColaRate := i.cola_rate;
                  end if;
                  update pys_payroll_summary
                  set    l_vess_code_a  = k.l_vess_code,
                         l_title_a      = nvl(k.l_title, k.title),
                         l_basic_rate_a = nvl(k.l_basic_rate, k.basic_rate) +  nColaRate 
                  where  empl_id = i.empl_id
                  and    payroll_no in (nPrevPayrollNo, p_payroll_no);
               else
                  nColaRate := 0;
                  if i.dept_code = 'MA-CREW' then
                     if i.cola_amt > 0 then 
                        nColaRate := i.cola_rate;
                     end if;
                     update pys_payroll_summary
                     set    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = nvl(k.l_title, k.title),
                            l_basic_rate_a = k.basic_rate_g+nColaRate
                     where  empl_id = i.empl_id
                     and    payroll_no in (nPrevPayrollNo, p_payroll_no);
                  else 
                     update pys_payroll_summary
                     set    l_vess_code_a  = k.l_vess_code,
                            l_title_a      = nvl(k.l_title, k.title),
                            l_basic_rate   = k.basic_rate,
                            l_basic_rate_a = k.basic_rate_g,
                            l_oport        = k.oport
                     where  empl_id = i.empl_id
                     and    payroll_no in (nPrevPayrollNo, p_payroll_no);
                  end if;
               end if;
            end if;

            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            -- compute for 13th MONTH and SILP
            nSILP_a := 0;    n13th_amt_a := 0;   n13th_n_mon := 0;
            nSILP_b := 0;    n13th_amt_b := 0;
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
                             -- decode(max(pay.dept_code),'FL', sum(pay.no_days)*max(pay.cola_rate),'MA-CREW', sum(pay.no_days)*max(pay.cola_rate), 0 ) )  amount_g
                      from   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
                      where  pay.empl_id = i.empl_id
                      and    pay.payroll_no = pahd.payroll_no
                      and    pahd.period_to between dPeriodFr and dPeriodTo
                      group  by to_char(pahd.period_to,'YYYYMM'))
            loop
               n13th_n_mon := n13th_n_mon + n.nMon;
               n13th_amt_b := n13th_amt_b + nvl(n.amount,0);
               n13th_amt_a := n13th_amt_a + nvl(n.amount_g,0);
            end loop;
            n13th_b := (n13th_amt_b/n13th_n_mon) * (n13th_n_mon/12);
            n13th_a := (n13th_amt_a/n13th_n_mon) * (n13th_n_mon/12);
            
            for n in (select basic_rate, sum(nMon) nMon from (
                      select to_char(pahd.period_to,'YYYYMM') cur_mon, 
                             decode(max(l_oport),'Y',max(pay.l_basic_rate)/nOuterR,max(pay.l_basic_rate))  basic_rate, 
                             decode(greatest(sum(pay.no_days),15),15,.5,1) nMon
                      from   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
                      where  pay.empl_id = i.empl_id
                      and    pay.payroll_no = pahd.payroll_no
                      and    pahd.period_to between dPeriodFr and dPeriodTo
                      group  by to_char(pahd.period_to,'YYYYMM') )
                      group  by basic_rate
                     )
            loop
               nSILP_b := nSILP_b + (n.basic_rate * 5 * (n.nMon/12));
            end loop;
            
            for n in (select basic_rate, sum(nMon) nMon from (
                      select to_char(pahd.period_to,'YYYYMM') cur_mon, 
                             decode(max(pay.dept_code), 'FL', nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate)), 
                                                        'MA-CREW', nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate)),  
                                                         nvl(max(pay.l_basic_rate_a),max(pay.l_basic_rate))/30)  basic_rate, 
                             decode(greatest(sum(pay.no_days),15),15,.5,1) nMon
                      from   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
                      where  pay.empl_id = i.empl_id
                      and    pay.payroll_no = pahd.payroll_no
                      and    pahd.period_to between dPeriodFr and dPeriodTo
                      group  by to_char(pahd.period_to,'YYYYMM') )
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
   end if;

   commit;

end sp_payroll_summary;
/
