CREATE OR REPLACE PROCEDURE SP_COUNT_FLT_ATTENDANCE_LOG
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
   p_dEmplID    IN  VARCHAR2,
   p_sal_freq   IN  VARCHAR2

) IS

   dEmplID           VARCHAR2(16) := p_dEmplID;
   dLatestEmbarked   DATE;
   dLatestDismbarked DATE;
   vLatestVessel     VARCHAR2(16);
   vLatestPosition   VARCHAR2(32);
   vLatestTitle      VARCHAR2(32);
   nLatestBasic      NUMBER(8,2);
   nLatestBasicG     NUMBER(8,2);

   nCola      NUMBER(10,5) := 0;
   nRegHol    NUMBER(10,5) := 0;
   nHolSun    NUMBER(10,5) := 0;
   nRegSun    NUMBER(10,5) := 0;
   nEnd       NUMBER(10,5) := 0;
   dChkDate   DATE;
   dTmpDate   DATE;
   dStart     DATE;
   dEnd       DATE;
   vOnBoard   VARCHAR2(1);
   dColaEff     DATE;

BEGIN

   -- set cutoff date
   IF TO_CHAR(p_date_fr, 'DD') = '01' THEN
      dStart := TO_DATE(TO_CHAR(ADD_MONTHS(p_date_fr,-1), 'YYYYMM') || '26', 'YYYYMMDD');
      dEnd   := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '10', 'YYYYMMDD');
   ELSE
      dStart := TO_DATE(TO_CHAR(p_date_fr, 'YYYYMM') || '11', 'YYYYMMDD');
      dEnd   := TO_DATE(TO_CHAR(p_date_to, 'YYYYMM') || '25', 'YYYYMMDD');
   END IF;

   --- reset first, this is for re-compute
   UPDATE pys_payroll_dtl_log
   SET    a_vess_code    = NULL,
          a_posi_code    = NULL,
          a_title        = NULL,
          a_basic_rate   = 0,
          a_basic_rate_g = 0,
          a_ndays        = 0,
          a_amt          = 0,
          a_amt_g        = 0,
          a_ot_pay       = 0,
          a_ht_pay       = 0,
          a_oport        = 'N',
          a_su_pay       = 0,
          a_ho_pay       = 0,
          a_hs_pay       = 0,
          a_cola_pay     = 0
   WHERE empl_empl_id = p_empl_id
   AND   pay_date BETWEEN dStart AND (p_date_fr-1);

   -- check every day
   nEnd := (p_date_to - dStart) + 1;
   FOR j IN 1..nEnd LOOP
      dChkDate := (dStart-1) + j;
      IF dLatestEmbarked IS NULL AND dChkDate <= dEnd THEN
         dTmpDate := sf_get_latest_embark(p_empl_id, dChkDate);
         IF dTmpDate IS NOT NULL THEN
            BEGIN
               SELECT vocr.dt_embarked, vocr.dt_disembarked, vocr.voya_vess_code,
                      empl.posi_code, vocr.title, vocr.basic_rate, vocr.basic_rate_g
               INTO   dLatestEmbarked, dLatestDismbarked, vLatestVessel,
                      vLatestPosition, vLatestTitle, nLatestBasic, nLatestBasicG
               FROM   cms_voyage_crew vocr,
                      cms_vessels vess,
                      pms_employees empl
               WHERE  vocr.voya_voyage_date <= dTmpDate
               AND    vocr.dt_embarked = dTmpDate
               AND    vocr.voya_vess_code = vess.code
               AND    vocr.empl_empl_id = empl.empl_id
               AND    vocr.empl_empl_id = p_empl_id
               AND    vocr.passenger = 'N';
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  -- set latest embark and disembark to backdate, so as not to allow to compute
                  dLatestEmbarked   := TO_DATE('19000101', 'YYYYMMDD');
                  dLatestDismbarked := TO_DATE('19000101', 'YYYYMMDD');
               WHEN OTHERS THEN
                  RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log-get service for employee ' || p_empl_id || ' ' || SQLERRM);
            END;
         ELSE
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         END IF;
      ELSE
         IF dLatestEmbarked IS NULL THEN
            dLatestEmbarked   := dChkdate - 30;
            dLatestDismbarked := dChkdate - 30;
         END IF;
      END IF; -- <if dLatestEmbarked is null then>

      -- check if on duty
      IF dChkDate BETWEEN dLatestEmbarked AND NVL(dLatestDismbarked, dChkDate+2) THEN
         vOnBoard := 'Y';
      ELSE
         IF (dChkDate > dEnd) AND NVL(dLatestDismbarked, dChkDate+2) >= dEnd THEN  -- check if still on actual payroll period (10 and 25)
            vOnBoard := 'Y';
         ELSE
            vOnBoard := 'N';
         END IF;
      END IF;

      IF dEmplID = p_empl_id THEN
         DBMS_OUTPUT.PUT_LINE ('check: dChkDate=' || TO_CHAR(dChkDate) || ',dLatestEmbarked=' || TO_CHAR(dLatestEmbarked) ||
                               ',dLatestDismbarked=' || TO_CHAR(dLatestDismbarked) || ',vLatestVessel=' || vLatestVessel || ',vOnBoard=' || vOnBoard );
      END IF;

      IF vOnBoard = 'Y' THEN
         -- check if pay date is sunday or holiday
         IF sf_is_holiday (dChkDate) = 1 THEN
            IF sf_is_sunday(dChkDate) = 1 THEN
               nHolSun := p_HolSun_RF;
            ELSE
               nRegHol := p_Holiday_RF;
            END IF;
         ELSE
            IF sf_is_sunday(dChkDate) = 1 THEN
               nRegSun := p_Sunday_RF;
            END IF;
         END IF;

         -- check if with cola
         sp_get_latest_cola (p_empl_id, dChkDate, nCola, dColaEff);
         IF nCola > 0 AND dColaEff <= dEnd THEN
            nCola := nCola;
         ELSE
            nCola := 0;
         END IF;
            
         IF dEmplID = p_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check: nRegSun=' || TO_CHAR(nRegSun) || ',nRegHol =' || TO_CHAR(nRegHol ) ||
                                  ',nHolSun=' || TO_CHAR(nHolSun) || ',nCola=' || TO_CHAR(nCola) );
         END IF;

         -- create payroll log
         IF dChkDate < p_date_fr THEN    -- check assumed dates from previous payroll
            UPDATE pys_payroll_dtl_log
            SET    a_vess_code    = vLatestVessel,
                   a_posi_code    = vLatestPosition,
                   a_title        = vLatestTitle,
                   a_basic_rate   = nLatestBasic,
                   a_basic_rate_g = nLatestBasic,
                   a_ndays        = 1,
                   a_amt          = nLatestBasic,
                   a_amt_g        = nLatestBasic,
                   a_ot_pay       = 0,
                   a_ht_pay       = 0,
                   a_oport        = 'N',
                   a_su_pay       = nRegSun,
                   a_ho_pay       = nRegHol,
                   a_hs_pay       = nHolSun,
                   a_cola_pay     = nCola,
                   modified_by    = USER,
                   dt_modified    = SYSDATE
            WHERE empl_empl_id = p_empl_id
            AND   pay_date = dChkDate;
            IF SQL%NOTFOUND THEN
               INSERT INTO pys_payroll_dtl_log
                      ( payroll_no, empl_empl_id, pay_date, dept_code, a_vess_code, a_posi_code, a_title, sal_freq,
                        latest_vess, a_basic_rate, a_basic_rate_g, a_amt, a_amt_g, a_ot_pay, a_ht_pay, a_oport,
                        a_su_pay, a_ho_pay, a_hs_pay, a_cola_pay, a_ndays, created_by, dt_created
                      )
               VALUES ( p_payno, p_empl_id, dChkDate, 'FL', vLatestVessel, vLatestPosition, vLatestTitle, p_sal_freq,
                        vLatestVessel, nLatestBasic, nLatestBasic, nLatestBasic, nLatestBasic, 0, 0, 'N',
                        nRegSun, nRegHol, nHolSun, nCola, 1, USER, SYSDATE
                      );
            END IF;
         ELSE
            BEGIN
               INSERT INTO pys_payroll_dtl_log
                      ( payroll_no, empl_empl_id, pay_date, dept_code, vess_code, posi_code, title, sal_freq,
                        latest_vess, basic_rate, basic_rate_g, amt, amt_g, ot_pay, ht_pay, oport,
                        su_pay, ho_pay, hs_pay, cola_pay, ndays, created_by, dt_created
                      )
               VALUES ( p_payno, p_empl_id, dChkDate, 'FL', vLatestVessel, vLatestPosition, vLatestTitle, p_sal_freq,
                        vLatestVessel, nLatestBasic, nLatestBasic, nLatestBasic, nLatestBasic, 0, 0, 'N',
                        nRegSun, nRegHol, nHolSun, nCola, 1, USER, SYSDATE
                      );
            EXCEPTION
               WHEN DUP_VAL_ON_INDEX THEN
                  UPDATE pys_payroll_dtl_log
                  SET    vess_code    = vLatestVessel,
                         posi_code    = vLatestPosition,
                         title        = vLatestTitle,
                         basic_rate   = nLatestBasic,
                         basic_rate_g = nLatestBasic,
                         ndays        = 1,
                         amt          = nLatestBasic,
                         amt_g        = nLatestBasic,
                         ot_pay       = 0,
                         ht_pay       = 0,
                         oport        = 'N',
                         su_pay       = nRegSun,
                         ho_pay       = nRegHol,
                         hs_pay       = nHolSun,
                         cola_pay     = nCola,
                         modified_by  = USER,
                         dt_modified  = SYSDATE
                  WHERE empl_empl_id = p_empl_id
                  AND   pay_date = dChkDate;
            END;
         END IF; -- <if dChkDate < p_date_fr then>
      ELSE
         IF dChkDate < p_date_fr and TO_CHAR(p_date_fr, 'DD') = '16' THEN    -- check assumed dates from previous payroll
            UPDATE pys_payroll_dtl_log
            SET    ot_pay       = 0,
                   ht_pay       = 0,
                   su_pay       = 0,
                   ho_pay       = 0,
                   hs_pay       = 0,
                   modified_by  = USER,
                   dt_modified  = SYSDATE
            WHERE empl_empl_id = p_empl_id
            AND   pay_date = dChkDate;
         END IF;
      END IF; -- <if vOnDuty = 'Y' then>

      -- check if next pay date crew is still on board
      IF (dChkDate+1) BETWEEN dLatestEmbarked AND NVL(dLatestDismbarked, dChkDate+2) THEN
         NULL; -- still on duty
      ELSE
         IF (dChkDate+1) > dEnd AND NVL(dLatestDismbarked, dChkDate+2) > dEnd THEN    -- check if still on actual payroll period (10 and 25)
            NULL; -- assume crew still on duty
         ELSE
            dLatestEmbarked   := NULL;
            dLatestDismbarked := NULL;
            vLatestVessel     := NULL;
            vLatestPosition   := NULL;
            vLatestTitle      := NULL;
            nLatestBasic      := NULL;
            nLatestBasicG     := NULL;
         END IF;
      END IF;
      nHolSun := 0;
      nRegHol := 0;
      nRegSun := 0;
      nCola   := 0;

   END LOOP; -- <for j in 1..nEnd loop>


EXCEPTION
   WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR (-20001, 'Error on sp_count_flt_attendance_log employee ' || p_empl_id || ' ' || SQLERRM);
END SP_COUNT_FLT_ATTENDANCE_LOG;
/
