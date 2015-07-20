CREATE OR REPLACE PROCEDURE sp_count_flt_attendance
(
   p_empl_id    IN  VARCHAR2,
   p_payno      IN  NUMBER,
   p_year       IN  VARCHAR2,
   p_mon        IN  VARCHAR2,
   p_date_fr    IN  DATE,
   p_date_to    IN  DATE,
   p_Sunday_RF  IN  NUMBER,
   p_Holiday_RF IN  NUMBER,
   p_HolSun_RF  IN  NUMBER,
   p_sal_freq   IN  VARCHAR2,
   p_seq_no     IN  NUMBER,
   p_dEmplID    IN  VARCHAR2,
   p_latestvess  OUT VARCHAR2,
   p_latesttitle OUT VARCHAR2,
   p_o_seq_no   OUT NUMBER

) IS

   dEmplID      VARCHAR2(16) := p_dEmplID;
   nSalaryR     NUMBER(8,2)  := 0;
   nASalaryR     NUMBER(8,2)  := 0;
   nSeqNo       NUMBER;
   dPeriodMo    DATE;
   dPeriodFr    DATE;
   dPeriodTo    DATE;
   vLatestVess  VARCHAR2(32);
   vLatestTitle VARCHAR2(32);
   vLatestRate  NUMBER(10,3) := 0;
   nDays        NUMBER(10,5) := 0;
   nADays        NUMBER(10,5) := 0;
   bIsEndOfMonth BOOLEAN;

BEGIN

   nSeqNo := p_seq_no;

   -- set cutoff date
   IF TO_CHAR(p_date_fr, 'DD') = '01' THEN
      dPeriodFr := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dPeriodTo := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
      bIsEndOfMonth := FALSE;
   ELSE
      dPeriodMo := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '01', 'YYYYMMDD'); -- for overtimes
      dPeriodFr := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dPeriodTo := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
      bIsEndOfMonth := TRUE;
   END IF;

   -- get latest vessel
   FOR i IN ( SELECT vess_code, title, basic_rate
              FROM   pys_payroll_dtl_log
              WHERE  empl_empl_id = p_empl_id
              AND    pay_date BETWEEN p_date_fr AND p_date_to
              ORDER  BY pay_date DESC
            )
   LOOP
      vLatestVess  := i.vess_code;
      vLatestTitle := i.title;
      vLatestRate  := i.basic_rate;
      EXIT;
   END LOOP;
   IF vLatestVess IS NULL THEN
      -- get latest vessel
      FOR i IN ( SELECT vess_code, title, basic_rate
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 ORDER  BY pay_date DESC
               )
      LOOP
         vLatestVess  := i.vess_code;
         vLatestTitle := i.title;
         vLatestRate  := i.basic_rate;
         EXIT;
      END LOOP;
   END IF;

   -- set latest vess
   UPDATE pys_payroll_dtl_log
   SET    latest_vess = vLatestVess
   WHERE  empl_empl_id = p_empl_id
   AND    pay_date BETWEEN p_date_fr AND p_date_to;


   -- regular days
   FOR j IN ( SELECT posi_code,
                     title,
                     basic_rate,
                     vess_code,
                     sal_freq,
                     MIN(pay_date)               dStart,
                     MAX(pay_date)               dEnd,
                     SUM(nDays)                  nNumday,
                     SUM(AMT)                    nSalaryR,
                     SUM(COLA_PAY)               nCola
              FROM   pys_payroll_dtl_log
              WHERE  empl_empl_id = p_empl_id
              AND    pay_date BETWEEN p_date_fr AND p_date_to
              GROUP  BY  posi_code, title, basic_rate, vess_code, sal_freq
             )
   LOOP

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: j.nNumDay=' || TO_CHAR(j.nNumDay) || ',j.vess_code=' || j.vess_code ||
                               ',j.dStart=' || TO_CHAR(j.dStart) || ',j.dEnd=' || TO_CHAR(j.dEnd) );
      END IF;

      IF j.sal_freq = 'MONTHLY' AND bIsEndOfMonth AND TO_CHAR(j.dEnd,'DD') >= '28' THEN
         IF TO_CHAR(j.dEnd,'DD') = '31' THEN
            nDays    := j.nNumday  - 1;
            nSalaryR := j.nSalaryR - j.basic_rate;
         ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
            nDays    := j.nNumday  + (30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')));
            nSalaryR := j.nSalaryR + (j.basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
         ELSE
            nDays    := j.nNumday;
            nSalaryR := j.nSalaryR;
         END IF;
      ELSE
         nDays    := j.nNumday;
         nSalaryR := j.nSalaryR;
      END IF;

      -- insert attendance summary
      nSeqNo  := nSeqNo + 1;
      INSERT INTO pys_payroll_dtl
             ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
      VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG', nSalaryR, nDays, j.basic_rate, nSalaryR, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

      IF j.nCola > 0 THEN
         nSeqNo := nSeqNo + 1;
         INSERT INTO pys_payroll_dtl
                ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
         VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'COLA', (j.nCola/j.nNumday)*nDays, nDays, (j.nCola/j.nNumday), j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
      END IF;

   END LOOP;

   IF dEmplID = p_empl_id THEN
      DBMS_OUTPUT.PUT_LINE ('check: before ''if bIsEndOfMonth then'' ');
   END IF;

   IF bIsEndOfMonth THEN

      -- sundays and holidays
      FOR j IN ( SELECT posi_code,
                        NVL(a_title,title) title,
                        DECODE(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE) basic_rate,
                        vess_code,
                        MIN(pay_date)               dStart,
                        MAX(pay_date)               dEnd,
                        SUM(DECODE(SU_PAY,0,A_SU_PAY,SU_PAY))   nSuDays,
                        SUM(DECODE(SU_PAY,0,A_SU_PAY,SU_PAY)*DECODE(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nSuPay,
                        SUM(DECODE(HO_PAY,0,A_HO_PAY,HO_PAY))   nHoDays,
                        SUM(DECODE(HO_PAY,0,A_HO_PAY,HO_PAY)*DECODE(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nHoPay,
                        SUM(DECODE(HS_PAY,0,A_HS_PAY,HS_PAY))   nHSDays,
                        SUM(DECODE(HS_PAY,0,A_HS_PAY,HS_PAY)*DECODE(A_BASIC_RATE,0,BASIC_RATE,A_BASIC_RATE))      nHSPay
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 AND    pay_date BETWEEN dPeriodMo AND p_date_to          -- 16 to eod
                 GROUP  BY  posi_code, NVL(a_title,title), DECODE(A_BASIC_RATE,0,basic_rate,A_BASIC_RATE), vess_code
                )
      LOOP

         IF ( j.nSuPay+j.nHoPay+j.nHSPay ) > 0 THEN
            -- check if there is header...
            FOR k IN (SELECT pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, posi_code, title, basic_rate, vess_code, dept_code, sal_freq, latest_vess
                      FROM   pys_payroll_dtl
                      WHERE  empl_empl_id = p_empl_id
                      AND    j.dEnd BETWEEN period_fr AND period_to
                      AND    paty_code LIKE 'REG%'
                      AND    pahd_payroll_no <= p_payno
                      ORDER  BY period_to DESC)
            LOOP
               IF j.dStart BETWEEN k.period_fr AND k.period_to THEN
                  IF k.pahd_payroll_no <> p_payno THEN
                     nSeqNo := nSeqNo + 1;
                     INSERT INTO pys_payroll_dtl
                            ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                     VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', 0, 0, j.basic_rate, 0, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
                  END IF;
                  EXIT;
               END IF;
            END LOOP;
         END IF;

         IF j.nSuPay > 0 THEN
            nSeqNo := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, latest_Vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-SUN-FLT', j.nSuPay, j.nSuDays, j.basic_rate*p_Sunday_RF, j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
         END IF;

         IF j.nHoPay > 0 THEN
            nSeqNo := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HOL-FLT', j.nHoPay, j.nHoDays, j.basic_rate*p_Holiday_RF, j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
         END IF;

         IF j.nHSPay > 0 THEN
            nSeqNo := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'OT-HS-FLT', j.nHSPay, j.nHSDays, j.basic_rate*p_HolSun_RF, j.vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
         END IF;

      END LOOP;

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: before ''bIsEndOfMonth adjustments'' ');
      END IF;

      -- adjustments
      FOR j IN ( SELECT posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        a_basic_rate,
                        MIN(pay_date)                 dStart,
                        MAX(pay_date)                 dEnd,
                        SUM(nDays)                    nNumday,
                        SUM(AMT)                      nSalaryR,
                        SUM(DECODE(COLA_PAY,0,0,1))   nColaD,
                        SUM(COLA_PAY)                 nCola,
                        SUM(A_nDays)                  nANumday,
                        SUM(A_AMT)                    nASalaryR,
                        SUM(DECODE(A_COLA_PAY,0,0,1)) nAColaD,
                        SUM(A_COLA_PAY)               nACola
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 AND    pay_date BETWEEN dPeriodFr AND (p_date_fr-1)
                 GROUP  BY posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        a_basic_rate)
      LOOP
         IF dEmplID = p_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check: j.nNumday=' || TO_CHAR(j.nNumday) || ',j.nANumday=' || TO_CHAR(j.nANumday) ||
                                  ',j.basic_rate=' || TO_CHAR(j.basic_rate) || ',j.a_basic_rate=' || TO_CHAR(j.a_basic_rate) ||
                                  ',j.nCola=' || TO_CHAR(j.nCola) || ',j.nACola=' || TO_CHAR(j.nACola) || ',j.vess_code=' || j.vess_code ||
                                  ',j.dStart=' || TO_CHAR(j.dStart) || ',j.dEnd=' || TO_CHAR(j.dEnd) );
         END IF;

         -- insert attendance summary
         IF j.basic_rate = 0 AND j.a_basic_rate > 0 THEN

            nSeqNo  := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nANumday, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

            IF j.nACola > 0 THEN
               nSeqNo := nSeqNo + 1;
               INSERT INTO pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', j.nACola, nDays, j.nACola/j.nANumday, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
            END IF;
         ELSE
            IF (j.basic_rate-j.a_basic_rate) <> 0 THEN
               IF j.basic_rate > 0 AND j.a_basic_rate = 0 THEN
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, j.nSalaryR*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               ELSE
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', j.nASalaryR, j.nNumDay, j.a_basic_rate, j.nASalaryR, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', j.nSalaryR*-1, j.nNumDay*-1, j.basic_rate, j.nSalaryR*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               END IF;
            END IF;

            IF (j.nACola-j.nCola) <> 0 THEN
               nSeqNo := nSeqNo + 1;
               INSERT INTO pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola-j.nCola), (j.nAColaD-j.nColaD), (j.nACola-j.nCola)/(j.nAColaD-j.nColaD), j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
            END IF;
         END IF;

      END LOOP;

   ELSE
      -- adjustments
      FOR j IN ( SELECT posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        sal_freq,
                        a_basic_rate,
                        MIN(pay_date)                 dStart,
                        MAX(pay_date)                 dEnd,
                        SUM(nDays)                    nNumday,
                        SUM(AMT)                      nSalaryR,
                        SUM(DECODE(SU_PAY,0,0,SU_PAY))     nSuDays,
                        SUM(SU_PAY*BASIC_RATE)        nSuPay,
                        SUM(DECODE(HO_PAY,0,0,HO_PAY))     nHoDays,
                        SUM(HO_PAY*BASIC_RATE)        nHoPay,
                        SUM(DECODE(HS_PAY,0,0,HS_PAY))     nHSDays,
                        SUM(HS_PAY*BASIC_RATE)        nHSPay,
                        SUM(DECODE(COLA_PAY,0,0,1))   nColaD,
                        SUM(COLA_PAY)                 nCola,
                        SUM(a_nDays)                  nANumday,
                        SUM(A_AMT)                    nASalaryR,
                        SUM(DECODE(A_SU_PAY,0,0,A_SU_PAY))   nASuDays,
                        SUM(A_SU_PAY*A_BASIC_RATE)    nASuPay,
                        SUM(DECODE(A_HO_PAY,0,0,A_HO_PAY))   nAHoDays,
                        SUM(A_HO_PAY*A_BASIC_RATE)    nAHoPay,
                        SUM(DECODE(A_HS_PAY,0,0,A_HS_PAY))   nAHSDays,
                        SUM(A_HS_PAY*A_BASIC_RATE)    nAHSPay,
                        SUM(DECODE(A_COLA_PAY,0,0,1)) nAColaD,
                        SUM(A_COLA_PAY)               nACola
                 FROM   pys_payroll_dtl_log
                 WHERE  empl_empl_id = p_empl_id
                 AND    pay_date BETWEEN dPeriodFr AND (p_date_fr-1)
                 GROUP  BY posi_code,
                        title,
                        vess_code,
                        basic_rate,
                        a_posi_code,
                        a_title,
                        a_vess_code,
                        sal_freq,
                        a_basic_rate)
      LOOP
         -- insert attendance summary
         IF j.basic_rate = 0 AND j.a_basic_rate > 0 THEN

            IF j.sal_freq = 'MONTHLY' AND  TO_CHAR(j.dEnd,'DD') >= '28' THEN
               IF TO_CHAR(j.dEnd,'DD') = '31' THEN
                  nDays    := j.nANumday  - 1;
                  nSalaryR := j.nASalaryR - j.a_basic_rate;
               ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
                  nDays    := j.nANumday  + (30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')));
                  nSalaryR := j.nASalaryR + (j.a_basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
               ELSE
                  nDays    := j.nANumday;
                  nSalaryR := j.nASalaryR;
               END IF;
            ELSE
               nDays    := j.nANumday;
               nSalaryR := j.nASalaryR;
            END IF;

            nSeqNo  := nSeqNo + 1;
            INSERT INTO pys_payroll_dtl
                   ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
            VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nSalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nDays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, nSalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

            IF j.nACola > 0 THEN
               nSeqNo := nSeqNo + 1;
               INSERT INTO pys_payroll_dtl
                      ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
               VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola/j.nANumday)*nDays, nDays, j.nACola/j.nANumday, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
            END IF;
         ELSE
            IF (j.basic_rate-j.a_basic_rate) <> 0 THEN

               IF j.sal_freq = 'MONTHLY' AND  TO_CHAR(j.dEnd,'DD') >= '28' THEN
                  IF TO_CHAR(j.dEnd,'DD') = '31' THEN
                     nDays     := j.nANumday  - 1;
                     nADays    := nDays;
                     nSalaryR  := j.nSalaryR - j.basic_rate;
                     nASalaryR := j.nASalaryR - j.a_basic_rate;
                  ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
                     nDays     := j.nANumday  + (30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')));
                     nADays    := nDays;
                     nSalaryR  := j.nSalaryR + (j.basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
                     nASalaryR := j.nASalaryR + (j.a_basic_rate*(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))));
                  ELSE
                     nDays     := j.nANumday;
                     nADays    := nDays;
                     nSalaryR  := j.nSalaryR;
                     nASalaryR := j.nASalaryR;
                  END IF;
               ELSE
                  nDays     := j.nNumday;
                  nADays    := j.nANumday;
                  nSalaryR  := j.nSalaryR;
                  nASalaryR := j.nASalaryR;
               END IF;


               IF j.basic_rate > 0 AND j.a_basic_rate = 0 THEN
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               ELSE
                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'REG-ADJ', nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, nADays+j.nASuDays+j.nAHoDays+j.nAHSDays, j.a_basic_rate, nASalaryR+j.nASuPay+j.nAHoPay+j.nAHSPay, j.a_basic_rate, j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );

                  nSeqNo  := nSeqNo + 1;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, amt_g, basic_rate_g, vess_code, dept_code, created_by, dt_created, pay_flag, adj_flag, sal_freq, latest_vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.posi_code, j.title, 'REG-ADJ', (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, (nDays+j.nSuDays+j.nHoDays+j.nHSDays)*-1, j.basic_rate, (nSalaryR+j.nSuPay+j.nHoPay+j.nHSPay)*-1, j.basic_rate, j.vess_code, 'FL', USER, SYSDATE, 'ADD', 'N', p_sal_freq, vLatestVess );
               END IF;
            END IF;

            IF (j.nACola-j.nCola) <> 0 THEN
               nSeqNo := nSeqNo + 1;
               IF j.sal_freq = 'MONTHLY' AND  TO_CHAR(j.dEnd,'DD') >= '28' THEN
                  IF TO_CHAR(j.dEnd,'DD') = '31' THEN
                     nDays    := (GREATEST(j.nAColaD-1,0)-(j.nColaD-1));
                     nSalaryR := nDays*((j.nACola-j.nCola)/(j.nAColaD-j.nColaD));
                  ELSIF TO_CHAR(j.dEnd,'DD') < '30' THEN
                     nDays    := (GREATEST(j.nAColaD-(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD'))),0)-(j.nColaD-(30-TO_NUMBER(TO_CHAR(j.dEnd,'DD')))));
                     nSalaryR :=  nDays*((j.nACola-j.nCola)/(j.nAColaD-j.nColaD));
                  ELSE
                     nDays    := (j.nAColaD-j.nColaD);
                     nSalaryR := (j.nACola-j.nCola);
                  END IF;
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess, modified_by )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', nSalaryR, nDays, (j.nACola-j.nCola)/(j.nAColaD-j.nColaD), j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess, TO_CHAR(j.nAColaD) || ',' || TO_CHAR(j.nColaD) );
               ELSE
                  INSERT INTO pys_payroll_dtl
                         ( pahd_payroll_no, pahd_year, pahd_mo, period_fr, period_to, seq_no, empl_empl_id, posi_code, title, paty_code, amt, no_days, basic_rate, vess_code, dept_code, created_by, dt_created, pay_flag, sal_freq, Latest_Vess )
                  VALUES ( p_payno, p_year, p_mon, j.dStart, j.dEnd, nSeqNo, p_empl_id, j.a_posi_code, j.a_title, 'COLA', (j.nACola-j.nCola), (j.nAColaD-j.nColaD), (j.nACola-j.nCola)/(j.nAColaD-j.nColaD), j.a_vess_code, 'FL', USER, SYSDATE, 'ADD', p_sal_freq, vLatestVess );
               END IF;
            END IF;
         END IF;

      END LOOP;

   END IF;  --<if bIsEndOfMonth then>

   p_o_seq_no    := nSeqNo;
   p_latestvess  := vLatestVess;
   p_latesttitle := vLatestTitle;


EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance employee ' || p_empl_id || ' ' || SQLERRM);
END sp_count_flt_attendance;
/
