declare
   p_payroll_no number := 20120630;
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
   vLTitle      VARCHAR2(32);
   bFirst       BOOLEAN;
   nRecAmt      NUMBER(10,2);
   vPrevEmplID  VARCHAR2(16) := 'x x x';
   dStart       DATE;
   dStart2      DATE;
   dEnd         DATE;
   nPrevPayrollNo NUMBER;
   nColaRate    pys_payroll_dtl.basic_rate%type;
   nColaRateO   pys_payroll_dtl.basic_rate%type;
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
BEGIN
   -- if end of month generate Payroll A Summary
   SELECT period_fr, period_to
   INTO   dStart, dEnd
   FROM   pys_payroll_hdr
   WHERE  payroll_no = p_payroll_no;

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
                       SUM(cola_amt) cola_amt, SUM(cola_day) cola_day
                FROM   pys_payroll_summary
                WHERE  payroll_no IN (nPrevPayrollNo, p_payroll_no)
                GROUP  BY empl_id
                HAVING MAX(period_to) > dStart2)
      LOOP
         nColaRateO := SF_GET_LATEST_COLA(i.empl_id, i.period_to);
         FOR k IN (SELECT empl_id, l_vess_code, l_title, l_basic_rate, basic_rate, title, basic_rate_g, oport, nColaRateO cola_rate
                   FROM   pys_payroll_summary
                   WHERE  empl_id = i.empl_id
                   AND    payroll_no IN (nPrevPayrollNo, p_payroll_no)
                   ORDER  BY payroll_no DESC, period_to DESC)
         LOOP
            IF i.sal_freq = 'MONTHLY' THEN
               nColaRate := 0;
               IF i.dept_code = 'FL' THEN
                  IF i.cola_amt > 0 THEN
                     nColaRate := k.cola_rate;
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
                     nColaRate := k.cola_rate;
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
                        nColaRate := k.cola_rate;
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
            EXIT;
         END LOOP;
      END LOOP;
   END IF;

END;
/


