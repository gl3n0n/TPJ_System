CREATE OR REPLACE PROCEDURE sp_payroll_summary (
   p_payroll_no IN NUMBER
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
   vLTitle      VARCHAR2(32);
   bFirst       BOOLEAN;
   nRecAmt      NUMBER(10,2);
   vPrevEmplID  VARCHAR2(16) := 'x x x';
   dStart       DATE;
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
       if i.dept_code = 'FL' then
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

       else
          SELECT NVL(SUM(no_days),0) ot_days, NVL(SUM(amt),0) ot_amt
          INTO   nOtDay, nOtAmt
          FROM   pys_payroll_dtl
          WHERE  pahd_payroll_no = p_payroll_no
          AND    empl_empl_id = i.empl_empl_id
          AND    paty_code LIKE 'OT%'        
          AND    period_to BETWEEN i.period_fr AND i.period_to;
       end if;

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
   IF TO_CHAR(dStart, 'DD') = '16' THEN 
      SELECT MAX(payroll_no)
      INTO   nPrevPayrollNo
      FROM   pys_payroll_hdr 
      WHERE  payroll_no < p_payroll_no;
    
      FOR i IN (SELECT empl_id, MAX(period_to) period_to, MAX(sal_freq) sal_freq, MAX(dept_code) dept_code, 
                       SUM(cola_amt) cola_amt, SUM(cola_day) cola_day, MAX(cola_rate) cola_rate
                FROM   pys_payroll_summary
                WHERE  payroll_no IN (nPrevPayrollNo, p_payroll_no)
                GROUP  BY empl_id)
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
                      FROM   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
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
                      FROM   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
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
                      FROM   pys_payroll_summary pay, 
                             pys_payroll_hdr pahd
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
            EXIT; 
         END LOOP;      
      END LOOP;      
   END IF;

   COMMIT;

END sp_payroll_summary;
/
