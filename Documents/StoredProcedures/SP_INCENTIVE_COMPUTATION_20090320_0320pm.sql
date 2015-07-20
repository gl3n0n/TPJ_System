CREATE OR REPLACE PROCEDURE Sp_Incentive_Computation
(
   p_tranno  IN NUMBER,
   p_year    IN VARCHAR2,
   p_mon     IN VARCHAR2,
   p_date_fr IN DATE,
   p_date_to IN DATE
)
   AS

   --get voyage crew
   CURSOR vocr IS
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, NVL(dt_disembarked,p_date_to) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NULL
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id IS NOT NULL
   UNION
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked+1 dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NOT NULL
   AND    vocr.dt_disembarked >= p_date_fr
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id IS NOT NULL
   ORDER  BY dt_embarked;

   CURSOR vocr_e (p_empl_id IN VARCHAR2) IS
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, NVL(dt_disembarked+1,p_date_to) dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NULL
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id = p_empl_id
   UNION
   SELECT vocr.voya_vess_code vessel, vess.vety_code, vocr.empl_empl_id empl_empl_id, vocr.rank_code,
          vocr.dt_embarked, vocr.dt_disembarked+1 dt_disembarked, vocr.basic_rate, vocr.passenger,
          vess.vety_code vess_type
   FROM   CMS_VOYAGE_CREW vocr, CMS_VESSELS vess
   WHERE  vocr.voya_voyage_date <= p_date_to
   AND    vocr.dt_embarked <= p_date_to
   AND    vocr.dt_disembarked IS NOT NULL
   AND    vocr.dt_disembarked >= p_date_fr
   AND    vocr.voya_vess_code = vess.code
   AND    vocr.empl_empl_id = p_empl_id
   ORDER  BY dt_embarked;

   --get vessel total catch
   CURSOR mcsu_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_catcher
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end;

   --get vessel catch per source
   CURSOR dcsu_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_catcher
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY fiso_code, tx_date;

   CURSOR drdt_c ( p_catcher IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT SUM(tot_catch) total_catch
   FROM   CMS_CATCHES_DR_DTLS
   WHERE  to_vess_code = p_catcher
   AND    tx_date BETWEEN p_start AND p_end;
   --GROUP  BY tx_date;

   --get vessel lightboat
   CURSOR dcsu_l ( p_lighted IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_lighted = p_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY  vess_lighted, vess_surveyed, fiso_code
   UNION
   SELECT vess_lighted, vess_surveyed, fiso_code, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_surveyed = p_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY vess_lighted, vess_surveyed, fiso_code;

   --get vessel surveyed
   CURSOR dcsu_s ( p_surveyed_by IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, surveyed_by, vess_catcher, surveyed_by_vess, SUM(total_catch) total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  surveyed_by = p_surveyed_by
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted < p_end
   GROUP  BY  tx_date, surveyed_by, vess_catcher, surveyed_by_vess;

   --get vessel catch per day 300 600
   CURSOR dcsu_d ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_catcher = p_surveyed
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;

   CURSOR dcsu_d2 ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_lighted = p_surveyed
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;

   CURSOR dcsu_d3 ( p_surveyed IN VARCHAR2, p_start IN DATE, p_end IN DATE ) IS
   SELECT vess_lighted, vess_surveyed, tx_date, total_catch
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  vess_surveyed = p_surveyed
   AND    vess_surveyed <> vess_lighted
   AND    tx_date BETWEEN p_start AND p_end
   AND    time_setted <= p_end;

   --get vessel delivered per day
   -- cursor drsu_d ( p_surveyed in varchar2, p_start in date, p_end in date ) is
   -- select tx_date, sum(total_catch) total_catch
   -- from   cms_catches_dr_dtls
   -- where  vess_surveyed = p_surveyed
   -- and    tx_date between p_start and p_end
   -- group  by tx_date;

   CURSOR dedu (p_empl_id IN VARCHAR2 ) IS
   SELECT empl_empl_id, dety_code, seq_no, amt
   FROM   PYS_DEDUCTIONS
   WHERE  empl_empl_id = p_empl_id
   AND    end_date  <= p_date_to
   AND    start_date >= p_date_fr
   --and    no_payday > 0
   AND    dety_code = ('VALE'); -- VALE should be deducted from Incentives

   dStart       DATE;
   dEnd         DATE;
   nTotalCatch  NUMBER(12,2);
   nDummy       NUMBER;
   n300_600_cnt NUMBER;
   nRate        PYS_EMPLOYEE_INCENTIVES.rate%TYPE;
   nBasis       PYS_EMPLOYEE_INCENTIVES.basis%TYPE;
   nAmt         PYS_EMPLOYEE_INCENTIVES.amt%TYPE;
   vErrMsg      VARCHAR2(2000);
   nCheck       NUMBER;
   nCATCHER     NUMBER;
   nLIGHTBOAT   NUMBER;
   nLighted     NUMBER:= 0;
   nSurveyed    NUMBER:= 0;

   d_empl_id    VARCHAR2(16) := 'B00013';

BEGIN

   -- CATCHER
   SELECT COUNT(1) INTO nDummy
   FROM   CMS_DAILY_CATCH_SUMMARY
   WHERE  tx_date BETWEEN  p_date_fr AND p_date_to;

   IF nDummy > 0 THEN
      DELETE FROM CMS_DAILY_CATCH_SUMMARY WHERE  tx_date BETWEEN  p_date_fr AND p_date_to;
   END IF;

   -- clear first
   BEGIN
      delete from PYS_EMPLOYEE_INCENTIVES where inhd_tran_no = p_tranno;             
      delete from PYS_KAWAN_TROSO_INCENTIVES where inhd_tran_no = p_tranno;             
   END;

   BEGIN
      INSERT INTO CMS_DAILY_CATCH_SUMMARY
             (
             tx_date, time_setted, vess_catcher, vess_surveyed, vess_lighted, fiso_code, surveyed_by, surveyed_by_vess, total_catch, created_by, dt_created
             )
      SELECT chdr.tx_date, TO_DATE(TO_CHAR(chdr.tx_date, 'YYYYMMDD') || TO_CHAR(chdr.time_setted, 'HH24MI'), 'YYYYMMDDHH24MI') time_setted,
             chdr.vess_code vess_catcher, chdr.vess_surveyed, chdr.vess_lighted, clog.fiso_code, chdr.surveyed_by, chdr.surveyed_by_vess,
             --SUM(NVL(clog.tot_jmb_catch,0) + NVL(clog.tot_lrg_catch,0) + NVL(clog.tot_reg_catch,0)  + NVL(clog.tot_med_catch,0) + NVL(clog.tot_sml_catch,0)) total_catch,
			 SUM(NVL(tot_catch,0)) total_catch,
			 USER, SYSDATE
      FROM   CMS_CATCHES_LOG clog, CMS_CATCHES_HDR chdr
      WHERE  clog.cahd_tx_no = chdr.tx_no
      AND    chdr.tx_date BETWEEN p_date_fr AND p_date_to
      GROUP  BY chdr.tx_date, TO_DATE(TO_CHAR(chdr.tx_date, 'YYYYMMDD') || TO_CHAR(chdr.time_setted, 'HH24MI'), 'YYYYMMDDHH24MI'),
            chdr.vess_code, chdr.vess_surveyed, chdr.vess_lighted, clog.fiso_code, chdr.surveyed_by, chdr.surveyed_by_vess;
      COMMIT;
   EXCEPTION
      WHEN OTHERS THEN
         vErrMsg := SQLERRM;
         RAISE_APPLICATION_ERROR (-20001, vErrMsg);
   END;

   -- CARRIER
   -- select count(1) into nDummy
   -- from   cms_daily_delivery_summary
   -- where  tx_date between  p_date_fr and p_date_to;

   -- if nDummy > 0 then
   --    delete from cms_daily_catch_summary where  tx_date between  p_date_fr and p_date_to;
   -- end if;

   -- begin
   --    insert into cms_daily_catch_summary
   --           (
   --           tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code, total_catch, created_by, dt_created
   --           )
   --    select tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code,
   --           sum(nvl(tot_jmb_catch,0) + nvl(tot_lrg_catch,0) + nvl(tot_reg_catch,0)  + nvl(tot_med_catch,0) + nvl(tot_sml_catch,0)) total_catch, user, sysdate
   --    from   cms_catches_log
   --    where  tx_date between p_date_fr and p_date_to
   --    group  by tx_date, vess_catcher, vess_surveyed, vess_lighted, fiso_code;
   --    commit;
   -- exception
   --    when others then
   --       vErrMsg := SQLERRM;
   --       raise_application_error (-20001, vErrMsg);
   -- end;

   FOR i IN vocr LOOP

      nCATCHER    := 0 ;
      nLIGHTBOAT  := 0 ;
      nTotalCatch := 0;

      if i.empl_empl_id = d_empl_id then
         DBMS_OUTPUT.PUT_LINE('empl empl id '||i.empl_empl_id||', i.passenger '||i.passenger || ',i.vessel:' || i.vessel);
      end if;

      IF i.passenger <> 'Y' THEN

         IF i.dt_embarked < p_date_fr THEN
            dStart := p_date_fr;
         ELSE
            dStart := i.dt_embarked ;
         END IF;

         IF i.dt_disembarked >= p_date_to THEN
            dEnd := p_date_to+1;
         ELSE
            dEnd := i.dt_disembarked ;
         END IF;

         -- total catch
         -- scenarios: rate should be based on total catch provided vessels
         nTotalCatch := 0;
         FOR k IN vocr_e ( i.empl_empl_id ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check carrier i.vess_type:' || i.vess_type || ',k.vess_type:' || k.vess_type);
            END IF;
            IF i.vess_type = k.vess_type THEN
               FOR j IN dcsu_c ( i.vessel, dStart, dEnd ) LOOP
                  IF i.empl_empl_id = d_empl_id THEN
                     DBMS_OUTPUT.PUT_LINE ('check carrier j.total_catch:' || to_char(j.total_catch));
                  END IF;
                  nTotalCatch := nTotalCatch + j.total_catch;
               END LOOP;
            END IF;
         END LOOP;

         -- kawan/troso report detail
         -- catcher per source
         FOR j IN dcsu_c ( i.vessel, dStart, dEnd ) LOOP
            nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, j.total_catch );
            --nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, nTotalCatch );
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check carrier rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
            END IF;
            IF j.total_catch > 0 AND nRate > 0 THEN
               Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL );
               -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL, NULL, NULL );
            END IF;
            nCATCHER := nCATCHER + (nRate);
         END LOOP;
         IF nCATCHER > 0 THEN
            FOR j IN (SELECT code FROM CMS_FISHING_SOURCES WHERE status = 'ACTIVE') LOOP
               BEGIN
                  SELECT count(1) INTO nCheck
                  FROM   PYS_KAWAN_TROSO_INCENTIVES
                  WHERE  YEAR          = p_year
                  AND    MO            = p_mon
                  AND    INTY_CODE     = 'CATCHER'
                  AND    EMPL_EMPL_ID  = i.empl_empl_id
                  AND    VESS_CODE     = i.vessel
                  AND    FISO_CODE     = j.code
                  AND    RANK_CODE     = i.rank_code;
                  IF nCheck = 0 then
                     Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL, NULL, NULL );
                  END IF;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     --Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL );
                     Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'CATCHER', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL, NULL, NULL );
                  WHEN TOO_MANY_ROWS THEN null;
               END;
            END LOOP;
         END IF;

         -- lighted
         -- scenarios for catcher with lighted and/or surveyed, applicable only for PAYAO
         -- if catcher is entitled for lighted and surveyed 15% of lighted + surveyed
         -- if catcher is entitled for lighted 5% of lighted + surveyed
         -- if catcher is entitled for surveyed 10% of lighted + surveyed
         nLighted  := 0;
         nSurveyed := 0;
         FOR j IN dcsu_l ( i.vessel, dStart, dEnd ) LOOP
            -- total catch is divided to lighted and surveyed
            nLighted  := j.total_catch/2;
            nSurveyed := j.total_catch/2;
            IF i.vess_type = 'CATCHER' THEN
               IF j.fiso_code = 'PAYAO' THEN
                  IF i.empl_empl_id = d_empl_id THEN
                     DBMS_OUTPUT.PUT_LINE ('check lighted rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',i.vess_type:' || i.vess_type || ',j.fiso_code :' || j.fiso_code );
                  END IF;
                  IF j.vess_lighted = j.vess_surveyed THEN
                     nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch);
                     --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch);
                     IF j.total_catch > 0 AND nRate > 0 THEN
                        Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, ((nLighted*.15)+nSurveyed), nRate, ((nLighted*.15)+nSurveyed)*nRate, p_tranno, NULL );
                        -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, ((nLighted*.15)+nSurveyed), nRate, ((nLighted*.15)+nSurveyed)*nRate, p_tranno, NULL, NULL, NULL );
                     END IF;
                     nLIGHTBOAT := nLIGHTBOAT + (((nLighted*.15)+nSurveyed)*nRate);
                  ELSIF j.vess_lighted = i.vessel THEN
                     nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch/2);
                     --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                     IF j.total_catch > 0 AND nRate > 0 THEN
                        Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nLighted*.05), nRate, (nLighted*.05)*nRate, p_tranno, NULL );
                        -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nLighted*.05), nRate, (nLighted*.05)*nRate, p_tranno, NULL, NULL, NULL );
                     END IF;
                     nLIGHTBOAT := nLIGHTBOAT + ((nLighted*.05)*nRate);
                  ELSIF j.vess_surveyed = i.vessel THEN
                     nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch/2);
                     --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                     IF j.total_catch > 0 AND nRate > 0 THEN
                        Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nSurveyed*.10), nRate, (nSurveyed*.10)*nRate, p_tranno, NULL );
                        -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, (nSurveyed*.10), nRate, (nSurveyed*.10)*nRate, p_tranno, NULL, NULL, NULL );
                     END IF;
                     nLIGHTBOAT := nLIGHTBOAT + ((nSurveyed*.10)*nRate);
                  END IF;
               END IF;
               IF i.empl_empl_id = d_empl_id THEN
                  DBMS_OUTPUT.PUT_LINE ('check lighted rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',i.vess_type:' || i.vess_type);
               END IF;
            ELSE
               IF j.vess_lighted = j.vess_surveyed THEN
                  nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch);
                  --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch);
                  IF j.total_catch > 0 AND nRate > 0 THEN
                     Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL );
                     -- Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL, NULL, NULL );
                  END IF;
                  nLIGHTBOAT := nLIGHTBOAT + (j.total_catch*nRate);
               ELSE
                  nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.total_catch/2);
                  --nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, nTotalCatch/2);
                  IF j.total_catch > 0 AND nRate > 0 THEN
                     Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, nLighted*nRate, p_tranno, NULL );
                     --Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.total_catch/2, nRate, nLighted*nRate, p_tranno, NULL, NULL, NULL );
                  END IF;
                  nLIGHTBOAT := nLIGHTBOAT + (nLighted*nRate);
               END IF;
               IF i.empl_empl_id = d_empl_id THEN
                  DBMS_OUTPUT.PUT_LINE ('check lighted rate:' || TO_CHAR(nRate) || ',j.fiso_code:' || j.fiso_code || ',i.rank_code:' ||  i.rank_code || ',j.total_catch:' || TO_CHAR(j.total_catch) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
               END IF;
            END IF;
         END LOOP;
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check LIGHTBOAT:' || TO_CHAR(nRate) || ',i.vess_type:' || i.vess_type || ',i.rank_code:' ||  i.rank_code || ',nLIGHTBOAT:' || TO_CHAR(nLIGHTBOAT) || ',nTotalCatch:' || TO_CHAR(nTotalCatch));
         END IF;
         IF nLIGHTBOAT > 0 THEN
            IF i.vess_type <> 'CATCHER' THEN
               FOR j IN (SELECT code FROM CMS_FISHING_SOURCES WHERE status = 'ACTIVE') LOOP
                  BEGIN
                     SELECT count(1) INTO nCheck
                     FROM   PYS_KAWAN_TROSO_INCENTIVES
                     WHERE  YEAR          = p_year
                     AND    MO            = p_mon
                     AND    INTY_CODE     = 'LIGHTBOAT'
                     AND    EMPL_EMPL_ID  = i.empl_empl_id
                     AND    VESS_CODE     = i.vessel
                     AND    FISO_CODE     = j.code
                     AND    RANK_CODE     = i.rank_code;
                  IF nCheck = 0 then
                     Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL, NULL, NULL );
                  END IF;
                  EXCEPTION
                     WHEN NO_DATA_FOUND THEN
                        --Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL );
                        Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.code, 0, 0, 0, p_tranno, NULL, NULL, NULL );
                  END;
               END LOOP;
            END IF;
         END IF;

         -- Surveyed By
         FOR j IN dcsu_s ( i.empl_empl_id, dStart, dEnd ) LOOP
            nRate := Sf_Get_Surveyed_Rate ( j.total_catch );
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check surveyed rate:' || TO_CHAR(nRate) || ',i.rank_code:' ||  i.rank_code || ',n300_600_cnt:' || TO_CHAR(n300_600_cnt));
            END IF;
            IF nRate > 0 THEN
               Sp_ins_kawan_troso_incentive ( i.empl_empl_id, p_year, p_mon, j.tx_date, j.tx_date, 'SURVEYED', j.vess_catcher, i.rank_code, NULL, j.total_catch, nRate, j.total_catch * nRate, p_tranno, j.surveyed_by_vess );
               --Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, j.tx_date, j.tx_date, 'SURVEYED', j.vess_catcher, i.rank_code, NULL, j.total_catch, nRate, j.total_catch * nRate, p_tranno, j.surveyed_by_vess, NULL, NULL );
            END IF;
         END LOOP;

         -- kawan/troso report summary
         for j in (select INTY_CODE, FISO_CODE, RANK_CODE, sum(basis) basis
                   from   pys_kawan_troso_incentives
                   where  year = p_year
                   and    mo   = p_mon
                   and    empl_empl_id = i.empl_empl_id 
                   group  by INTY_CODE, FISO_CODE, RANK_CODE)
         loop
             if j.INTY_CODE = 'CATCHER' then  
                nRate := Sf_Get_Catcher_Rate ( j.fiso_code, i.rank_code, j.basis );
             elsif j.INTY_CODE = 'LIGHTHOUSE' then  
                nRate := Sf_Get_Lighted_Rate ( j.fiso_code, i.rank_code, j.basis);
             elsif j.INTY_CODE = 'SURVEYED' then  
                nRate := Sf_Get_Surveyed_Rate ( j.basis );
             end if;  
             Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'LIGHTBOAT', i.vessel, i.rank_code, j.fiso_code, j.basis, nRate, j.basis*nRate, p_tranno, NULL, NULL, NULL );
         end loop;


         -- 300/600
         n300_600_cnt := 0;
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check 300_600 i.vessel:' || i.vessel || ', dStart:' || TO_CHAR(dStart) || ', dEnd:' || TO_CHAR(dEnd, 'YYYYMMDD HH24MISS'));
         END IF;
         FOR j IN dcsu_d ( i.vessel, dStart, dEnd ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check 300_600 j.total_catch:' || TO_CHAR(j.total_catch) || ', j.tx_date:' || TO_CHAR(j.tx_date));
            END IF;
            IF Sf_Is_Fullmoon ( j.tx_date ) = 1 THEN
               IF j.total_catch >= 300 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            ELSE
               IF j.total_catch >= 600 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            END IF;
         END LOOP;
         -- for lighted 
         FOR j IN dcsu_d2 ( i.vessel, dStart, dEnd ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check 300_600 j.total_catch:' || TO_CHAR(j.total_catch) || ', j.tx_date:' || TO_CHAR(j.tx_date));
            END IF;
            IF Sf_Is_Fullmoon ( j.tx_date ) = 1 THEN
               IF j.total_catch >= 300 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            ELSE
               IF j.total_catch >= 600 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            END IF;
         END LOOP;
         -- for surveyed
         FOR j IN dcsu_d3 ( i.vessel, dStart, dEnd ) LOOP
            IF i.empl_empl_id = d_empl_id THEN
               DBMS_OUTPUT.PUT_LINE ('check 300_600 j.total_catch:' || TO_CHAR(j.total_catch) || ', j.tx_date:' || TO_CHAR(j.tx_date));
            END IF;
            IF Sf_Is_Fullmoon ( j.tx_date ) = 1 THEN
               IF j.total_catch >= 300 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            ELSE
               IF j.total_catch >= 600 THEN
                  n300_600_cnt := n300_600_cnt + 1;
               END IF;
            END IF;
         END LOOP;
         nRate := Sf_300_600_Rate ( i.rank_code, n300_600_cnt );
         IF i.empl_empl_id = d_empl_id THEN
            DBMS_OUTPUT.PUT_LINE ('check 300_600 rate:' || TO_CHAR(nRate) || ', i.rank_code:' ||  i.rank_code || ', n300_600_cnt:' || TO_CHAR(n300_600_cnt));
         END IF;
         IF n300_600_cnt > 0  AND nRate > 0 THEN
            Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, '300_600', i.vessel, i.rank_code, NULL, n300_600_cnt, nRate, n300_600_cnt*nRate, p_tranno, NULL, NULL, NULL );
         END IF;

         -- carrier/delivery
         for j in drdt_c ( i.vessel, dStart, dEnd ) loop
            nRate := sf_get_delivery_rate ( i.rank_code, j.total_catch );
            if j.total_catch > 0 and nRate > 0 then
               begin
                  Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, dStart, dEnd, 'DELIVERIES', i.vessel, i.rank_code, NULL, j.total_catch, nRate, j.total_catch*nRate, p_tranno, NULL, NULL, NULL );  
               EXCEPTION
                  WHEN OTHERS THEN
                     vErrMsg := SQLERRM;
                     RAISE_APPLICATION_ERROR (-20001, 'CARRIER ERROR:' || vErrMsg);
               END;
            end if;
         end loop;

      END IF;

   END LOOP;

   FOR x IN (SELECT empl_empl_id, SUM(DECODE(inty_code,'CATCHER',amt,'LIGHTBOAT', amt, 0)) amt
             FROM   PYS_EMPLOYEE_INCENTIVES
             WHERE  inhd_tran_no = p_tranno
             GROUP  BY empl_empl_id
            )
   LOOP
      FOR i IN (SELECT empl_empl_id, period_to, period_fr, vess_code vessel, rank_code
                FROM   PYS_EMPLOYEE_INCENTIVES
                WHERE  inhd_tran_no = p_tranno
                AND    empl_empl_id = x.empl_empl_id
                ORDER  BY period_to DESC, period_fr DESC
               )
      LOOP
         IF (x.amt > 0) THEN
            FOR z IN dedu (i.empl_empl_id) LOOP
               Sp_Insert_Employee_Incentive ( i.empl_empl_id, p_year, p_mon, p_date_fr, p_date_to, NULL, i.vessel, i.rank_code, NULL, z.amt, 1, z.amt, p_tranno, NULL, z.dety_code, z.seq_no );
            END LOOP;
         END IF;
         UPDATE PYS_EMPLOYEE_INCENTIVES
         SET    l_vess_code = i.vessel,
                l_rank_code = i.rank_code
         WHERE  empl_empl_id = x.empl_empl_id
         AND    inhd_tran_no = p_tranno;
         EXIT;
      END LOOP;
   END LOOP;

   COMMIT;

EXCEPTION
   WHEN OTHERS THEN
      vErrMsg := SQLERRM;
      RAISE_APPLICATION_ERROR (-20001, vErrMsg);

END Sp_Incentive_Computation;
/
