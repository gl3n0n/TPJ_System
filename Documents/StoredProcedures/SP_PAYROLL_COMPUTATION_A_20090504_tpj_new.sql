CREATE OR REPLACE PROCEDURE sp_payroll_computation_a
(
   p_payno   IN NUMBER,
   p_year    IN VARCHAR2,
   p_mon     IN VARCHAR2,
   p_date_fr IN DATE,
   p_date_to IN DATE
)
   AS

   --get attendance record
   CURSOR attr (p_period_fr IN DATE, p_period_to IN DATE ) IS
   SELECT b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          'OFC' empl_type,  b.dept_code dept_code, 'SEMI-MO' sal_freq
   FROM   PMS_EMPLOYEES b
   WHERE  EXISTS (SELECT 1
   FROM   PMS_ATTENDANCE_RECORDS a
   WHERE  a.empl_empl_id = b.empl_id
   AND    a.att_date BETWEEN p_period_fr AND p_period_to )
   AND    EXISTS (
      SELECT 1
      FROM   PYS_EMPLOYEE_SALARY c
      WHERE  eff_st_date  IN ( SELECT MAX(eff_st_date)
      FROM   PYS_EMPLOYEE_SALARY d
      WHERE  d.eff_st_date <= p_period_to
      AND    d.empl_empl_id = b.empl_id )
      AND    c.empl_empl_id = b.empl_id
      AND    c.sal_freq = 'SEMI-MO'
   )
   UNION
   SELECT vocr.empl_empl_id empl_empl_id, empl.taty_code, empl.posi_code posi_code,
          'FLT' empl_type, 'FL' dept_code, 'SEMI-MO' sal_freq
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess, PMS_EMPLOYEES empl
   WHERE  vocr.voya_voyage_date <= p_period_to
   AND    vocr.dt_embarked <= p_period_to
   AND   (vocr.dt_disembarked IS NULL
   OR    (vocr.dt_disembarked IS NOT NULL AND vocr.dt_disembarked >= p_period_fr) )
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id = empl.empl_id
   AND    NOT EXISTS (
      SELECT 1
      FROM   PYS_EMPLOYEE_SALARY c
      WHERE  eff_st_date  IN ( SELECT MAX(eff_st_date)
      FROM   PYS_EMPLOYEE_SALARY d
      WHERE  d.eff_st_date <= p_period_to
      AND    d.empl_empl_id = vocr.empl_empl_id )
      AND    c.empl_empl_id = vocr.empl_empl_id
      AND    c.sal_freq = 'MONTHLY'
   )
   GROUP  BY vocr.empl_empl_id, empl.taty_code, empl.posi_code,
          'FLT', NULL
   UNION
   SELECT b.empl_id empl_empl_id, b.taty_code, b.posi_code posi_code,
          DECODE(b.dept_code,'FL', 'FLT', 'OFC') empl_type, b.dept_code dept_code,  'MONTHLY' sal_freq
   FROM   PMS_EMPLOYEES b
   WHERE  EXISTS (
      SELECT 1
      FROM   PYS_EMPLOYEE_SALARY c
      WHERE  eff_st_date  IN ( SELECT MAX(eff_st_date)
      FROM   PYS_EMPLOYEE_SALARY d
      WHERE  d.eff_st_date <= p_period_to
      AND    d.empl_empl_id = b.empl_id )
      AND    c.empl_empl_id = b.empl_id
      AND    c.sal_freq = 'MONTHLY'
   );

   --get voyage crew
   CURSOR vocr IS
   SELECT empl_empl_id, dt_embarked, dt_disembarked
   FROM   CMS_VOYAGE_CREW
   WHERE  dt_embarked < p_date_fr
   AND    dt_disembarked <= p_date_to
   UNION
   SELECT empl_empl_id, dt_embarked, dt_disembarked
   FROM   CMS_VOYAGE_CREW
   WHERE  dt_embarked BETWEEN p_date_fr AND p_date_to;

   --get employee incentive
   CURSOR emin (p_empl_id IN VARCHAR2) IS
   SELECT empl_empl_id, inty_code, fiso_code, vess_code, basis, rate, YEAR, mo, amt
   FROM   PYS_EMPLOYEE_INCENTIVES
   WHERE  empl_empl_id = p_empl_id
   AND    YEAR = TO_CHAR(p_date_to, 'YYYY')
   AND    mo = TO_CHAR(p_date_to, 'MM');

   --get employee deductions
   CURSOR dedu (p_empl_id IN VARCHAR2) IS
   SELECT empl_empl_id, dety_code, seq_no, amt
   FROM   PYS_DEDUCTIONS
   WHERE  empl_empl_id = p_empl_id
   AND    end_date  >= p_date_to
   AND    start_date <= p_date_to
   --and    no_payday > 0
   AND    dety_code <> ('VALE'); -- not to include VALE in Payroll deductions for fleet; should be deducted from Incentives

   --get ofc employee deductions
   CURSOR ofc_dedu (p_empl_id IN VARCHAR2) IS
   SELECT empl_empl_id, dety_code, seq_no, amt
   FROM   PYS_DEDUCTIONS
   WHERE  empl_empl_id = p_empl_id
   AND    end_date  >= p_date_to
   AND    start_date <= p_date_to; -- include VALE in Payroll deductions for ofc;

   nSeqNo         NUMBER;
   bWithDeduction BOOLEAN;
   nPayNo         NUMBER(8);

   -- Overtime Rates for OFC and FLT
   nOvertm_RO   NUMBER(8,3);
   nSunday_RO   NUMBER(8,3);
   nHoliday_RO  NUMBER(8,3);
   nHolSun_RO   NUMBER(8,3);
   nOuter_RO    NUMBER(8,3);
   nOutAd_RO    NUMBER(8,3);
   nOvertm_RF   NUMBER(8,3);
   nSunday_RF   NUMBER(8,3);
   nHoliday_RF  NUMBER(8,3);
   nHolSun_RF   NUMBER(8,3);
   nCola        NUMBER(8,3);

   -- Actual OT pay
   nOtPay       NUMBER(8,2);
   nSuPay       NUMBER(8,2);
   nHoPay       NUMBER(8,2);
   nHSPay       NUMBER(8,2);
   nOPPay       NUMBER(8,2);
   nOPAdj       NUMBER(8,2);

   -- Employee Basic Rates and Computed Salary
   vIsManager   VARCHAR2(2);
   vSalFreq     VARCHAR2(16);
   nBasicR      NUMBER(8,2);
   nBasicG      NUMBER(8,2);
   nSalaryG     NUMBER(8,2);

   -- Deductions
   nSSS         NUMBER(8,2);
   nSSS_ER      NUMBER(8,2);
   nSSS_EC      NUMBER(8,2);
   nSSS_MO      NUMBER(8,2);
   nPagibig     NUMBER(8,2);
   nPagibig_ER  NUMBER(8,2);
   nPhHealth    NUMBER(8,2);
   nPhHealth_ER NUMBER(8,2);
   nTaxable     NUMBER(8,2);
   nWhTax       NUMBER(8,2);

   -- From Previous Pay Sched
   dPrevStart   DATE;
   nPrevSal     NUMBER(8,2);
   nPrevAllo    NUMBER(8,2);
   nPrevDays    NUMBER(8,2);

   nNumHrs      NUMBER(5,2);
   nAllowances  NUMBER(8,2);
   nDeduction   NUMBER(8,2) := 0;
   nVale        NUMBER(8,2) := 0;
   vLatestVess  VARCHAR2(32);
   vLatestTitle VARCHAR2(32);
   nSalaryG_D   NUMBER(8,2);
   nSalaryG_B   NUMBER(8,2);
   nSalaryG_R   NUMBER(8,2);
   dPeriodTOG   DATE;
   bFixMonthly  BOOLEAN;
   nAdjCount    NUMBER;
   nMaxPayNo    NUMBER;
   dEmplID      VARCHAR2(16) := 'S00022';

BEGIN

   -- cleanup before recompute
   DELETE FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno AND adj_approval ='N';
   DELETE FROM PYS_PAYROLL_DTL_ADJ_LOG WHERE pahd_payroll_no = p_payno AND adj_approval ='N';

   DELETE FROM PYS_SSS_CONTRIBUTION WHERE period_to = p_date_to
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);

   DELETE FROM PYS_PAGIBIG_CONTRIBUTION WHERE period_to = p_date_to
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);

   DELETE FROM PYS_PHILHEALTH_CONTRIBUTION WHERE period_to = p_date_to
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);

   DELETE FROM PYS_SSS_CONTRI_DTL WHERE psch_payroll_no = p_payno
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);

   DELETE FROM PYS_PAGIBIG_CONTRI_DTL WHERE ppch_payroll_no = p_payno
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);

   DELETE FROM PYS_HEALTH_CONTRI_DTL WHERE phch_payroll_no = p_payno
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);

   DELETE FROM PYS_PAYROLL_DTL_LOG WHERE payroll_no = p_payno
      AND empl_empl_id NOT IN (SELECT empl_empl_id FROM PYS_PAYROLL_DTL WHERE pahd_payroll_no = p_payno);
   -- end of cleanup

   -- get Max SeqNo
   SELECT NVL(MAX(seq_no),0)
   INTO   nSeqNo
   FROM   PYS_PAYROLL_DTL
   WHERE  pahd_payroll_no = p_payno;

   -- get OFC and FLT Overtime Rate
   sp_get_ofc_ot_rates ( nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO);
   sp_get_flt_ot_rates ( nSunday_RF, nHoliday_RF, nHolSun_RF );

   -- check pay period
   IF p_date_to <= TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '15', 'YYYYMMDD') THEN

      bWithDeduction := FALSE;
      dPrevStart     := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      --dPrevStart     := p_date_fr;

   ELSE

      bWithDeduction := TRUE;

      -- get Max Previous Start
      SELECT payroll_no, period_fr
      INTO   nPayNo, dPrevStart
      FROM   PYS_PAYROLL_HDR
      WHERE  period_fr = TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '01', 'YYYYMMDD');

   END IF;

   DBMS_OUTPUT.PUT_LINE ('check M0: dPrevStart:' || TO_CHAR(dPrevStart)  || ',p_date_to:' || TO_CHAR(p_date_to) );
   FOR i IN attr ( dPrevStart, p_date_to ) LOOP

      nSalaryG   := 0;
      nOPPay     := 0;
      nOPAdj     := 0;
      nOtPay     := 0;
      nSuPay     := 0;
      nHoPay     := 0;
      nHsPay     := 0;
      nAllowances := 0;
      nPrevSal   := 0;
      nPrevAllo  := 0;
      vLatestVess := NULL;
      vLatestTitle := NULL;
      nSalaryG_D  := 0;
      nSalaryG_B  := 0;
      bFixMonthly := FALSE;

      -- get basic rate and salary mode/frequency
      -- check attendance

      -- check if with approved adjustment
      nAdjCount := 0;
      SELECT COUNT(1)
      INTO   nAdjCount
      FROM   PYS_PAYROLL_DTL
      WHERE  empl_empl_id = i.empl_empl_id
      AND    pahd_payroll_no = p_payno
      AND    adj_approval = 'Y';

      vSalFreq := i.sal_freq;
      IF i.empl_type = 'OFC' THEN
         sp_get_basic_rate ( i.empl_empl_id, p_date_fr, p_date_to, nBasicR, nBasicG, vSalFreq, vIsManager );
      END IF;


      IF i.empl_empl_id = dEmplID THEN
         DBMS_OUTPUT.PUT_LINE ('check M00:' || i.empl_empl_id || ',nBasicG:' || TO_CHAR(nBasicG) ||
                                ',nBasicR:' || TO_CHAR(nBasicR) || ',i.empl_type:' || i.empl_type||
                                ',vSalFreq:' || vSalFreq || ',vIsManager:' || vIsManager || ',i.taty_code:' || i.taty_code);
      END IF;

       -- check if Employee has assigned Tax Type
      IF i.taty_code IS NOT NULL AND NVL(nAdjCount,0)=0 THEN         -- START: Tax Type checking (no Deduction loop)

         IF i.empl_type = 'OFC' THEN
            IF vSalFreq = 'MONTHLY' THEN
               IF vIsManager = 'Y' THEN
                  sp_count_mgr_attendance_new ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, nBasicR, nBasicG,
                                            nSunday_RO, nHoliday_RO, nHolSun_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nSuPay, nHoPay, nHSPay, nAllowances, nSeqNo);
               ELSE
                  sp_count_ofc_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                                i.dept_code, i.posi_code, 'Y', nBasicR, nBasicG,
                                                nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO, dEmplID );

                  sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                            i.dept_code, i.posi_code, 'Y', nBasicR, nBasicG,
                                            nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                            nSeqNo, dEmplID, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
               END IF;
            ELSE
               sp_count_ofc_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                             i.dept_code, i.posi_code, 'N', nBasicR, nBasicG,
                                             nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO, dEmplID );

               sp_count_ofc_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                         i.dept_code, i.posi_code, 'N', nBasicR, nBasicG,
                                         nOvertm_RO, nSunday_RO, nHoliday_RO, nHolSun_RO, nOuter_RO, nOutAd_RO,
                                         nSeqNo, dEmplID, nNumHrs, nSalaryG, nOtPay, nSuPay, nHoPay, nHSPay, nOPPay, nOPAdj, nAllowances, nSeqNo);
            END IF;
         ELSE
            sp_count_flt_attendance_log ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                          nSunday_RF, nHoliday_RF, nHolSun_RF, dEmplID, vSalFreq );

            sp_count_flt_attendance ( i.empl_empl_id, p_payno, p_year, p_mon, p_date_fr, p_date_to,
                                      nSunday_RF, nHoliday_RF, nHolSun_RF,
                                      vSalFreq, nSeqNo, dEmplID, vLatestVess, vLatestTitle, nSeqNo);
         END IF;

         -- Start Compution for deductions
         -- No Deduction for Employees with no Government rate


         IF i.empl_empl_id = dEmplID THEN
            DBMS_OUTPUT.PUT_LINE ('check M1:' || i.empl_empl_id || ',nSalaryG:' || TO_CHAR(nSalaryG) ||
                                  ',vIsManager:' || vIsManager || ',nPayNo:' || TO_CHAR(nPayNo) || ',p_payno:' || TO_CHAR(p_payno));
         END IF;


         IF (bWithDeduction) THEN

            nCola := 0;
            FOR k IN (SELECT pahd_payroll_no, BASIC_RATE_G, basic_rate, dept_code, SAL_FREQ, no_days, period_to
                      FROM   PYS_PAYROLL_DTL
                      WHERE  empl_empl_id = i.empl_empl_id
                      AND    pahd_payroll_no = p_payno
                      AND    paty_code LIKE 'REG%'
                      UNION
                      SELECT pahd_payroll_no, BASIC_RATE_G, basic_rate, dept_code, SAL_FREQ, no_days, period_to
                      FROM   PYS_PAYROLL_DTL
                      WHERE  empl_empl_id = i.empl_empl_id
                      AND    pahd_payroll_no = nPayNo
                      AND    paty_code LIKE 'REG%'
                      ORDER  BY period_to DESC)
            LOOP
               IF i.empl_empl_id = dEmplID THEN
                  DBMS_OUTPUT.PUT_LINE ('check M2a: k.sal_freq:' || k.sal_freq || ',k.dept_code:' || k.dept_code ||
                                        ', k.BASIC_RATE_G:' || TO_CHAR(k.BASIC_RATE_G));
               END IF;
               IF k.sal_freq = 'MONTHLY' THEN
                  IF k.dept_code='FL' THEN
                     nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                     --nSalaryG_B := k.BASIC_RATE_G/30;  -- check crew
                     nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);  -- check crew
                  ELSE
                     IF k.dept_code='MA-CREW' THEN
                        nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                        nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);  -- check crew
                     ELSE
                        nSalaryG_B := k.BASIC_RATE_G;
                        bFixMonthly := TRUE;
                     END IF;
                  END IF;
               ELSE
                  IF k.dept_code='FL' THEN
                     nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                     nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);
                  ELSE
                     IF k.dept_code='MA-CREW' THEN
                        nCola := sf_get_payroll_cola(i.empl_empl_id, nPayNo, p_payno);
                        nSalaryG_B := k.BASIC_RATE + NVL(nCola,0);  -- check crew
                     ELSE
                        nSalaryG_B := k.BASIC_RATE_G;
                        bFixMonthly := TRUE;
                     END IF;
                  END IF;
               END IF;
               dPeriodTOG := k.period_to;
               nMaxPayNo := k.pahd_payroll_no;
               EXIT;
            END LOOP;
            IF i.dept_code='MA-CREW' THEN
               FOR k IN (SELECT paty_code, SUM(no_days) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = p_payno
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code LIKE 'REG%'
                         GROUP  BY paty_code
                         UNION ALL
                         SELECT paty_code, SUM(no_days) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = nPayNo
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code LIKE 'REG%'
                         GROUP  BY paty_code
                         )
               LOOP
                  IF i.empl_empl_id = dEmplID THEN
                     DBMS_OUTPUT.PUT_LINE ('check M2b: k.paty_code:' || k.paty_code || ', k.no_days:' || TO_CHAR(k.no_days));
                  END IF;
                  nSalaryG_D := nSalaryG_D + k.no_days;
               END LOOP;
            ELSE
               FOR k IN (SELECT paty_code, SUM(no_days) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = p_payno
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code <> 'COLA'
                         GROUP  BY paty_code
                         UNION ALL
                         SELECT paty_code, SUM(no_days) no_days
                         FROM   PYS_PAYROLL_DTL
                         WHERE  pahd_payroll_no = nPayNo
                         AND    empl_empl_id = i.empl_empl_id
                         AND    paty_code <> 'COLA'
                         GROUP  BY paty_code
                         )
               LOOP
                  IF i.empl_empl_id = dEmplID THEN
                     DBMS_OUTPUT.PUT_LINE ('check M2b: k.paty_code:' || k.paty_code || ', k.no_days:' || TO_CHAR(k.no_days));
                  END IF;
                  nSalaryG_D := nSalaryG_D + k.no_days;
               END LOOP;
            END IF;

            IF i.empl_empl_id = dEmplID THEN
               DBMS_OUTPUT.PUT_LINE ('check M2: nSalaryG_D:' || TO_CHAR(nSalaryG_D) || ',' || 'nSalaryG_B:' || TO_CHAR(nSalaryG_B) ||
                                     ', dPrevStart:' || TO_CHAR( dPrevStart) || ', p_date_to:' || TO_CHAR( p_date_to));
            END IF;

            BEGIN
               IF dPeriodTOG IS NULL THEN
                  dPeriodTOG := p_date_to;
               END IF;
               IF bFixMonthly THEN
                  nSalaryG   := NVL(nSalaryG_B,0);
               ELSE
                  nSalaryG   := (NVL(nSalaryG_D,0)* NVL(nSalaryG_B,0));
               END IF;
            END;

            IF i.empl_empl_id = dEmplID THEN
               DBMS_OUTPUT.PUT_LINE ('check M3: nSalaryG:   ' || TO_CHAR(nSalaryG) ||  ', nMaxPayNo:' || TO_CHAR(NVL(nMaxPayNo,0)) || ', p_payno:' || TO_CHAR(NVL(p_payno,0)) || ', nOtPay:' || TO_CHAR(NVL(nOtPay,0)) || ', ' ||
                                     'nSuPay:' || TO_CHAR(NVL(nSuPay,0)) || ', nHoPay:' || TO_CHAR(NVL(nHoPay,0)) || ', nHsPay:' || TO_CHAR(NVL(nHsPay,0)) || ', nAllowances:' || TO_CHAR(NVL(nAllowances,0)) || ', ' ||
                                     'nPrevSal:' || TO_CHAR(NVL(nPrevSal,0)) || ', nPrevAllo:' || TO_CHAR(NVL(nPrevAllo,0)) );
            END IF;

            IF (NVL(nSalaryG,0) > 0) THEN
               -- check there are records
               IF nMaxPayNo < p_payno THEN
                  IF dPeriodTOG IS NULL OR dPeriodTOG < p_date_fr THEN
                     dPeriodTOG := p_date_to;
                  END IF;
                  -- check if there is header...
                  FOR k IN (SELECT pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, posi_code, title, basic_rate, vess_code, dept_code, sal_freq, latest_vess
                            FROM   PYS_PAYROLL_DTL
                            WHERE  empl_empl_id = i.empl_empl_id
                            AND    paty_code LIKE 'REG%'
                            AND    pahd_payroll_no <= p_payno
                            ORDER  BY period_to DESC)
                  LOOP
                     nSeqNo := nSeqNo + 1;
                     INSERT INTO PYS_PAYROLL_DTL
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                     VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, k.posi_code, k.title, 'REG-ADJ', 0, 0, k.basic_rate, 0, k.basic_rate, k.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', k.sal_freq, k.latest_vess );
                     EXIT;
                  END LOOP;
               END IF;

               -- compute SSS
               BEGIN
                  --if nSalaryG >= 1000 then   -- added by thess 04042008 to filter salaries less than 1000
                     nSeqNo := nSeqNo + 1;
                     sp_get_sss_contribution_er_ee (nSalaryG, p_date_to, nSSS, nSSS_ER, nSSS_EC, nSSS_MO);
                     INSERT INTO PYS_PAYROLL_DTL
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'SSS', nSSS, nSalaryG, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );

                     -- populate sss ER and EE contribution
                     INSERT INTO PYS_SSS_CONTRIBUTION
                            ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, ec_er, mo_sal_credit, created_by, dt_created )
                     VALUES ( dPrevStart, p_date_to, i.empl_empl_id, nSSS, nSSS_ER, NVL(nSSS_EC,0), nSSS_MO, USER, SYSDATE );
                  --end if;
               EXCEPTION
                  WHEN OTHERS THEN
                     RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - sss contribution for ' || i.empl_empl_id || ' period: ' || TO_CHAR(dPrevStart) || '-' || TO_CHAR(p_date_to) || nSSS || '/' || nSSS_ER || '/' || nSSS_EC || '/' || TO_CHAR(nSalaryG));

               END;

               -- compute Pag-ibig
               BEGIN

                  nSeqNo := nSeqNo + 1;
                  -- nPagibig := sf_get_pagibig_contribution(nBasic);
                  sp_get_pagibig_ee_er (nSalaryG, nPagibig, nPagibig_ER);
                  INSERT INTO PYS_PAYROLL_DTL
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                  VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'PAGIBIG', nPagibig, nSalaryG, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );

                  -- populate pag-ibig ER and EE contribution
                  INSERT INTO PYS_PAGIBIG_CONTRIBUTION
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
                  VALUES ( dPrevStart, p_date_to, i.empl_empl_id, nPagibig, nPagibig_ER, USER, SYSDATE );

               END;

               -- compute Philhealth
               BEGIN

                  nSeqNo := nSeqNo + 1;
                  --nPhHealth := sf_get_philhealth_contribution(nBasic);
                  sp_get_philhealth_ee_er (nSalaryG, p_date_to, nPhHealth, nPhHealth_ER);
                  INSERT INTO PYS_PAYROLL_DTL
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_Freq, latest_vess, title )
                  VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'PHILHEALTH', nPhHealth, nSalaryG, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );

                  -- populate pag-ibig ER and EE contribution
                  INSERT INTO PYS_PHILHEALTH_CONTRIBUTION
                         ( period_fr, period_to, empl_empl_id, ee_cont, er_cont, created_by, dt_created )
                  VALUES ( dPrevStart, p_date_to, i.empl_empl_id, nPhHealth, nPhHealth_ER, USER, SYSDATE );

               END;

               -- compute WH TAX
               BEGIN
                  nTaxable := NVL(nSalaryG,0) - (nSSS + nPagibig + nPhHealth);
      IF nTaxable >= 0 THEN  -- added by thess 04042008 to validate net taxable salary
         nSeqNo   := nSeqNo + 1;
         nWhTax   := sf_get_whtax(i.empl_empl_id, p_date_to, i.taty_code, nTaxable);
         INSERT INTO PYS_PAYROLL_DTL
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, paty_code, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
         VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, 'WHTAX', nWhTax, nTaxable, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
      END IF;
               END;

            END IF;                     -- END : No salary

            IF i.empl_empl_id = dEmplID THEN
               DBMS_OUTPUT.PUT_LINE ('check deduction: nSalaryG:   ' || TO_CHAR(nSalaryG) ||  ', i.empl_type :' || i.empl_type );
            END IF;

            -- Deductions
            IF i.empl_type = 'FLT' THEN
               IF (NVL(nSalaryG,0) <> 0) THEN
                  FOR z IN dedu (i.empl_empl_id) LOOP
                     nSeqNo := nSeqNo + 1;
                     INSERT INTO PYS_PAYROLL_DTL
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                     nDeduction := NVL(nDeduction,0) + z.amt;
                  END LOOP;
               END IF;
            ELSE
               FOR z IN ofc_dedu (i.empl_empl_id) LOOP
                  BEGIN
                     nSeqNo := nSeqNo + 1;
                     INSERT INTO PYS_PAYROLL_DTL
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, dety_code, dedu_seq_no, amt, basic_rate, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_vess, title )
                     VALUES ( p_payno, p_year, p_mon, p_date_fr, dPeriodTOG, nSeqNo, i.empl_empl_id, i.posi_code, z.dety_code, z.seq_no, z.amt, 0, i.dept_code, USER, SYSDATE, 'LESS', vSalFreq, vLatestVess, vLatestTitle );
                     nDeduction := NVL(nDeduction,0) + z.amt;
                  EXCEPTION
                     WHEN OTHERS THEN
                        RAISE_APPLICATION_ERROR (-20001, SQLERRM || ' ERROR - deductions ' || i.empl_empl_id || ' z.amt: ' || TO_CHAR(z.amt) || ',z.dety_code:' || TO_CHAR(z.dety_code) );
                  END;
               END LOOP;

               --nVale := nSalaryG-(nWhTax+nPhHealth+nPagibig+nSSS+nDeduction);
               --if nVale < 0 then
               --   nVale := nVale * -1;
               --   begin
               --      update pys_deductions
               --      set    total_amt = total_amt + (nVale-amt)
               --      where  empl_empl_id = i.empl_empl_id
               --      and    dety_code = 'VALE'
               --      and    amt <> nVale;
               --      if sql%NOTFOUND then
               --         insert into pys_deductions (seq_no, empl_empl_id, dety_code, start_date, end_date, no_payday, amt, frequency, total_amt, dt_created, created_by )
               --         values (DEDU_SEQ.NEXTVAL, i.empl_empl_id, 'VALE', p_date_to, p_date_to+1, 1, 0, 'MO', nVale, sysdate, user);
               --      end if;
               --      insert into pys_deductions_log (empl_empl_id, pahd_payroll_no, amt, dt_created, created_by )
               --      values (i.empl_empl_id, p_payno, nVale, sysdate, user);
               --   end;
               --end if;
            END IF; -- <if i.empl_type = 'FL' then>
         END IF;                        -- END : Deduction Computation -- No Deduction for Employees with no Government rate

      END IF;                           -- END: Tax Type checking  (no Deduction loop)

   END LOOP;

   -- summarizes computation
   SP_PAYROLL_SUMMARY(p_payno);

END sp_payroll_computation_a;
/
