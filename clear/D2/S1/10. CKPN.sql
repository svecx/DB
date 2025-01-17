--step 1 update domain cut off proses ckpn

/*
UPDATE AD1SYS.PARA_DOMAIN_DTL A
   SET A.LOW_VALUE = '01-JAN-2019'
   --SELECT * FROM AD1SYS.PARA_DOMAIN_DTL A
 WHERE A.DOMAIN_ID = 'CTERP'
   AND A.DOMAIN_VALUE = 'SCCKPN';

UPDATE AD1SYS.PARA_DOMAIN_DTL A
   SET A.LOW_VALUE = '01-JAN-2999'
   --SELECT * FROM AD1SYS.PARA_DOMAIN_DTL A
 WHERE A.DOMAIN_ID = 'CTERP'
   AND A.DOMAIN_VALUE = 'SCECL';

UPDATE AD1SYS.PARA_DOMAIN_DTL A
   SET A.LOW_VALUE = '01-JUL-2099'
   --SELECT * FROM AD1SYS.PARA_DOMAIN_DTL A
 WHERE A.DOMAIN_ID = 'SCLO5';
 */



----Step 2 
DECLARE 
  DTPERIODE   DATE := '31JUL2024'; --TANGGAL CLOSING 1 (EOM)


  TYPE REC_PROVISI IS RECORD(
    PROD_ID     AD1SYS.ACCT_PROVISION_RISK.PRODUCT_ID%TYPE,
    AR1         AD1SYS.ACCT_PROVISION_RISK.SUM_AR_PRIN_1%TYPE,
    AR2         AD1SYS.ACCT_PROVISION_RISK.SUM_AR_PRIN_2%TYPE,
    AR1_BENCANA AD1SYS.ACCT_PROVISION_RISK.SUM_AR_PRIN_1%TYPE,
    AR2_BENCANA AD1SYS.ACCT_PROVISION_RISK.SUM_AR_PRIN_1%TYPE,
    AR_ALL      AD1SYS.ACCT_PROVISION_RISK.SUM_AR_PRIN_ALL%TYPE,
    NEW_RATE    AD1SYS.ACCT_PROVISION_RISK.NEW_RATE%TYPE);

  TYPE TAB_PROVISI IS TABLE OF REC_PROVISI;
  --  LIST_PROVISI      TAB_PROVISI := TAB_PROVISI();
  LIST_PROVISI_SYAR TAB_PROVISI := TAB_PROVISI();
  LIST_PROVISI_KON  TAB_PROVISI := TAB_PROVISI();
  LIST_IMBT         TAB_PROVISI := TAB_PROVISI(); --add v.11

  CTSYA  DATE;
  CTKON  DATE;
  CTIMBT DATE; --V11

BEGIN

  CTKON  := TO_DATE(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('CTERP',
                                                   'CKPNKON',
                                                   '',
                                                   3));
  CTSYA  := TO_DATE(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('CTERP',
                                                   'CKPNSYA',
                                                   '',
                                                   3));
  CTIMBT := TO_DATE(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('CTERP',
                                                   'CKPNIMBT',
                                                   '',
                                                   3)); --V11

  BEGIN
    IF DTPERIODE >= CTKON THEN
      --- PK KONVEN
      SELECT T.PROD_ID_RISK,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) <
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR1,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) >=
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR2,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) <
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) AND
                        T.RD_CONTRACT_NO IS NOT NULL THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR1_BENCANA,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) >=
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) AND
                        T.RD_CONTRACT_NO IS NOT NULL THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR2_BENCANA,
             SUM(T.ACCT_BAL_PRIN) AR_ALL,
             0 NEW_RATE
        BULK COLLECT
        INTO LIST_PROVISI_KON
        FROM (SELECT (SELECT TRIM(B.DOMAIN_VALUE)
                        FROM AD1SYS.PARA_DOMAIN_HEAD A,
                             AD1SYS.PARA_DOMAIN_DTL  B
                       WHERE A.DOMAIN_ID = B.DOMAIN_ID
                         AND A.DOMAIN_ID = 'SCLO4'
                         AND TRIM(B.LOW_VALUE) = TRIM(AR.ACCT_PC_CODE)
                         AND A.STATUS = 'Y') AS PROD_ID_RISK,
                     AR.ACCT_BAL_PRIN,
                     AR.ACCT_COLLECTABILITY_OID_BI, --EDIT V.10
                     RD.RD_CONTRACT_NO,
                     AFC.COLLECTABILITY --ADD V.10
                FROM AD1SYS.ACCT_PENCADANGAN_AR AR
                LEFT JOIN AD1SYS.RISK_DETAIL_UPLOAD RD
                  ON RD.RD_BRANCH_ID = AR.ACCT_BR_ID
                 AND RD.RD_CONTRACT_NO = TRIM(AR.ACCT_CONT_NO)
              --ADD V.10
                LEFT JOIN AD1SYS.ACCT_FINAL_COLLECT_JF AFC
                  ON AR.ACCT_CONT_NO = AFC.CONTRACT_NUMBER
                 AND AR.ACCT_CUST_NO = AFC.CIF
                 AND AR.ACCT_BR_ID = AFC.BRANCH
                 AND AR.ACCT_PERIODE = AFC.PERIODE
              --END
               WHERE AR.ACCT_PERIODE = DTPERIODE
                 AND AR.STATUS = 'AKTIF'
                 AND AR.APPL_FIN_TYPE = '1'
                 AND EXISTS
               (SELECT 1
                        FROM AD1SYS.PARA_DOMAIN_HEAD DH,
                             AD1SYS.PARA_DOMAIN_DTL  DD
                       WHERE DH.DOMAIN_ID = DD.DOMAIN_ID
                         AND DD.DOMAIN_ID = 'SCLO4'
                         AND DH.STATUS = 'Y'
                         AND DD.LOW_VALUE = TRIM(AR.ACCT_PC_CODE))) T
       GROUP BY T.PROD_ID_RISK;
    END IF;
  END;

  BEGIN
    IF DTPERIODE >= CTSYA THEN
      --PK SYARIAH
      SELECT T.PROD_ID_RISK,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) <
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR1,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) >=
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR2,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) <
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) AND
                        T.RD_CONTRACT_NO IS NOT NULL THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR1_BENCANA,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) >=
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) AND
                        T.RD_CONTRACT_NO IS NOT NULL THEN
                    T.ACCT_BAL_PRIN
                   ELSE
                    0
                 END) AS AR2_BENCANA,
             SUM(T.ACCT_BAL_PRIN) AR_ALL,
             0 NEW_RATE
        BULK COLLECT
        INTO LIST_PROVISI_SYAR
        FROM (SELECT (SELECT TRIM(B.DOMAIN_VALUE)
                        FROM AD1SYS.PARA_DOMAIN_HEAD A,
                             AD1SYS.PARA_DOMAIN_DTL  B
                       WHERE A.DOMAIN_ID = B.DOMAIN_ID
                         AND A.DOMAIN_ID = 'SCLO4'
                         AND TRIM(B.LOW_VALUE) = TRIM(AR.ACCT_PC_CODE)
                         AND A.STATUS = 'Y') AS PROD_ID_RISK,
                     (CASE
                       WHEN NVL((AD1SYS.FUNC_CEK_IMBT_CLOSING(AR.ACCT_BR_ID, AR.ACCT_CONT_NO)), 0) = 1 THEN --v.15 imbt get amnt ke aging
                        NVL((SELECT RAM.BAL_PRIN
                              FROM AD1SYS.RPT_AGING_MIS RAM
                             WHERE RAM.BRANCHID = AR.ACCT_BR_ID
                               AND RAM.CONTRACTNO = AR.ACCT_CONT_NO
                               AND TRUNC(RAM.REQDATE) = TRUNC(AR.ACCT_PERIODE)),
                            0)
                       ELSE
                        AR.ACCT_BAL_PRIN
                     END) ACCT_BAL_PRIN,
                     AR.ACCT_COLLECTABILITY_OID_BI, --EDIT V.10
                     RD.RD_CONTRACT_NO,
                     AFC.COLLECTABILITY --ADD V.10
                FROM AD1SYS.ACCT_PENCADANGAN_AR AR
                LEFT JOIN AD1SYS.RISK_DETAIL_UPLOAD RD
                  ON RD.RD_BRANCH_ID = AR.ACCT_BR_ID
                 AND RD.RD_CONTRACT_NO = TRIM(AR.ACCT_CONT_NO)
              --ADD V.10
                LEFT JOIN AD1SYS.ACCT_FINAL_COLLECT_JF AFC
                  ON AR.ACCT_CONT_NO = AFC.CONTRACT_NUMBER
                 AND AR.ACCT_CUST_NO = AFC.CIF
                 AND AR.ACCT_BR_ID = AFC.BRANCH
                 AND AR.ACCT_PERIODE = AFC.PERIODE
              --END
               WHERE AR.ACCT_PERIODE = DTPERIODE
                 AND AR.STATUS = 'AKTIF'
                 AND (AR.APPL_FIN_TYPE = '2' OR
                     1 = NVL(AD1SYS.FUNC_CEK_PK_BENCANA(AR.ACCT_BR_ID,
                                                         AR.ACCT_CONT_NO),
                              0))
                    -- remark v.15  AND AD1SYS.FUNC_CEK_IMBT_CLOSING(AR.ACCT_BR_ID, AR.ACCT_CONT_NO) = 0 -- MOD by Beni (2022/02/03) #015134/II/22
                 AND EXISTS
               (SELECT 1
                        FROM AD1SYS.PARA_DOMAIN_HEAD DH,
                             AD1SYS.PARA_DOMAIN_DTL  DD
                       WHERE DH.DOMAIN_ID = DD.DOMAIN_ID
                         AND DD.DOMAIN_ID = 'SCLO4'
                         AND DH.STATUS = 'Y'
                         AND DD.LOW_VALUE = TRIM(AR.ACCT_PC_CODE))) T
       GROUP BY T.PROD_ID_RISK;
    END IF;
  END;

  --ADD BY FADLI
  BEGIN
    IF DTPERIODE >= CTIMBT THEN
      --PK IMBT
      SELECT T.PROD_ID_RISK,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) <
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) THEN
                    T.BAL_PRIN --V.11
                   ELSE
                    0
                 END) AS AR1,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) >=
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) THEN
                    T.BAL_PRIN --V.11
                   ELSE
                    0
                 END) AS AR2,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) <
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) AND
                        T.RD_CONTRACT_NO IS NOT NULL THEN
                    T.BAL_PRIN --V.11
                   ELSE
                    0
                 END) AS AR1_BENCANA,
             SUM(CASE
                   WHEN NVL(T.COLLECTABILITY, T.ACCT_COLLECTABILITY_OID_BI) >=
                        TRIM(AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('SCCOL', 'COLL', 'COLL6', 4)) AND
                        T.RD_CONTRACT_NO IS NOT NULL THEN
                    T.BAL_PRIN --V.11
                   ELSE
                    0
                 END) AS AR2_BENCANA,
             SUM(T.BAL_PRIN) AR_ALL,
             0 NEW_RATE
        BULK COLLECT
        INTO LIST_IMBT
        FROM (SELECT (SELECT TRIM(B.DOMAIN_VALUE)
                        FROM AD1SYS.PARA_DOMAIN_HEAD A,
                             AD1SYS.PARA_DOMAIN_DTL  B
                       WHERE A.DOMAIN_ID = B.DOMAIN_ID
                         AND A.DOMAIN_ID = 'SCLO4'
                         AND TRIM(B.LOW_VALUE) = TRIM(AR.ACCT_PC_CODE)
                         AND A.STATUS = 'Y') AS PROD_ID_RISK,
                     AR.ACCT_BAL_PRIN,
                     AR.ACCT_COLLECTABILITY_OID_BI, --EDIT V.10
                     RD.RD_CONTRACT_NO,
                     AFC.COLLECTABILITY, --ADD V.10
                     RAM.BAL_PRIN --ADD V.11
                FROM AD1SYS.ACCT_PENCADANGAN_AR AR
                LEFT JOIN AD1SYS.RISK_DETAIL_UPLOAD RD
                  ON RD.RD_BRANCH_ID = AR.ACCT_BR_ID
                 AND RD.RD_CONTRACT_NO = TRIM(AR.ACCT_CONT_NO)
              --ADD V.10
                LEFT JOIN AD1SYS.ACCT_FINAL_COLLECT_JF AFC
                  ON AR.ACCT_CONT_NO = AFC.CONTRACT_NUMBER
                 AND AR.ACCT_CUST_NO = AFC.CIF
                 AND AR.ACCT_BR_ID = AFC.BRANCH
                 AND AR.ACCT_PERIODE = AFC.PERIODE
              --END
              --V.11 FADLI
               INNER JOIN AD1SYS.RPT_AGING_MIS RAM
                  ON AR.ACCT_CONT_NO = RAM.CONTRACTNO
                 AND AR.ACCT_BR_ID = RAM.BRANCHID
                 AND AR.ACCT_PERIODE = RAM.REQDATE --add wakur
              --END
               WHERE AR.ACCT_PERIODE = DTPERIODE
                 AND AR.STATUS = 'AKTIF'
                 AND (AR.APPL_FIN_TYPE = '2' OR
                     1 = NVL(AD1SYS.FUNC_CEK_PK_BENCANA(AR.ACCT_BR_ID,
                                                         AR.ACCT_CONT_NO),
                              0))
                 AND AD1SYS.FUNC_CEK_IMBT_CLOSING(AR.ACCT_BR_ID, AR.ACCT_CONT_NO) = 1 -- V.11--mod wakur
                 AND EXISTS
               (SELECT 1
                        FROM AD1SYS.PARA_DOMAIN_HEAD DH,
                             AD1SYS.PARA_DOMAIN_DTL  DD
                       WHERE DH.DOMAIN_ID = DD.DOMAIN_ID
                         AND DD.DOMAIN_ID = 'SCLO4'
                         AND DH.STATUS = 'Y'
                         AND DD.LOW_VALUE = TRIM(AR.ACCT_PC_CODE))) T
       GROUP BY T.PROD_ID_RISK;
    END IF;
  END;
  --END ADD

  IF LIST_PROVISI_KON.COUNT <> 0 THEN
    IF DTPERIODE >= CTKON THEN
      -- HITUNG RATE PK KONVEN
      FORALL I2 IN LIST_PROVISI_KON.FIRST .. LIST_PROVISI_KON.LAST
        UPDATE AD1SYS.ACCT_PROVISION_RISK_KONVEN PROVK
           SET PROVK.SUM_AR_PRIN_1   = LIST_PROVISI_KON(I2).AR1,
               PROVK.SUM_AR_PRIN_2   = LIST_PROVISI_KON(I2).AR2,
               PROVK.SUM_AR_PRIN_ALL = LIST_PROVISI_KON(I2).AR_ALL,
               PROVK.NEW_RATE       =
               ((PROVK.PROVISION - (LIST_PROVISI_KON(I2)
               .AR2 - LIST_PROVISI_KON(I2).AR2_BENCANA)) /
               (LIST_PROVISI_KON(I2).AR1 - LIST_PROVISI_KON(I2).AR1_BENCANA)),
               PROVK.CKPN_TO_RECEIVE = PROVK.PROVISION /
                                       (LIST_PROVISI_KON(I2)
                                       .AR_ALL -
                                        (LIST_PROVISI_KON(I2).AR1_BENCANA + LIST_PROVISI_KON(I2)
                                        .AR2_BENCANA)),
               PROVK.SUM_OS_RKB_1    = LIST_PROVISI_KON(I2).AR1_BENCANA,
               PROVK.SUM_OS_RKB_2    = LIST_PROVISI_KON(I2).AR2_BENCANA
         WHERE PROVK.PERIODE = DTPERIODE
           AND PROVK.PRODUCT_ID = LIST_PROVISI_KON(I2).PROD_ID;
    END IF;
  END IF;

  IF LIST_PROVISI_SYAR.COUNT <> 0 THEN
    IF DTPERIODE >= CTSYA THEN
      --PK SYARIAH
      FORALL I3 IN LIST_PROVISI_SYAR.FIRST .. LIST_PROVISI_SYAR.LAST
        UPDATE AD1SYS.ACCT_PROVISION_RISK_SYAR PROVS
           SET PROVS.SUM_AR_PRIN_1   = LIST_PROVISI_SYAR(I3).AR1,
               PROVS.SUM_AR_PRIN_2   = LIST_PROVISI_SYAR(I3).AR2,
               PROVS.SUM_AR_PRIN_ALL = LIST_PROVISI_SYAR(I3).AR_ALL,
               PROVS.NEW_RATE       =
               ((PROVS.PROVISION -
               (LIST_PROVISI_SYAR(I3)
               .AR2 - LIST_PROVISI_SYAR(I3).AR2_BENCANA)) /
               (LIST_PROVISI_SYAR(I3)
               .AR1 - LIST_PROVISI_SYAR(I3).AR1_BENCANA)),
               PROVS.CKPN_TO_RECEIVE = PROVS.PROVISION /
                                       (LIST_PROVISI_SYAR(I3)
                                       .AR_ALL -
                                        (LIST_PROVISI_SYAR(I3).AR1_BENCANA + LIST_PROVISI_SYAR(I3)
                                        .AR2_BENCANA)),
               PROVS.SUM_OS_RKB_1    = LIST_PROVISI_SYAR(I3).AR1_BENCANA,
               PROVS.SUM_OS_RKB_2    = LIST_PROVISI_SYAR(I3).AR2_BENCANA
         WHERE PROVS.PERIODE = DTPERIODE
           AND PROVS.PRODUCT_ID = LIST_PROVISI_SYAR(I3).PROD_ID;
    END IF;
  END IF;

  --ADD BY FADLI V.11
  IF LIST_IMBT.COUNT <> 0 THEN
    IF DTPERIODE >= CTIMBT THEN
      --PK IMBT
      FORALL I4 IN LIST_IMBT.FIRST .. LIST_IMBT.LAST
        UPDATE AD1SYS.ACCT_PROVISION_RISK_IMBT PROIMBT
           SET PROIMBT.SUM_AR_PRIN_1   = LIST_IMBT(I4).AR1,
               PROIMBT.SUM_AR_PRIN_2   = LIST_IMBT(I4).AR2,
               PROIMBT.SUM_AR_PRIN_ALL = LIST_IMBT(I4).AR_ALL,
               PROIMBT.NEW_RATE       =
               ((PROIMBT.PROVISION -
               (LIST_IMBT(I4).AR2 - LIST_IMBT(I4).AR2_BENCANA)) /
               (LIST_IMBT(I4).AR1 - LIST_IMBT(I4).AR1_BENCANA)),
               PROIMBT.CKPN_TO_RECEIVE = PROIMBT.PROVISION /
                                         (LIST_IMBT(I4)
                                         .AR_ALL - (LIST_IMBT(I4).AR1_BENCANA + LIST_IMBT(I4)
                                          .AR2_BENCANA)),
               PROIMBT.SUM_OS_RKB_1    = LIST_IMBT(I4).AR1_BENCANA,
               PROIMBT.SUM_OS_RKB_2    = LIST_IMBT(I4).AR2_BENCANA
         WHERE PROIMBT.PERIODE = DTPERIODE
           AND PROIMBT.PRODUCT_ID = LIST_IMBT(I4).PROD_ID;
    END IF;
  
    BEGIN
      --add wakur. roni
      UPDATE AD1SYS.ACCT_PROVISION_RISK_IMBT IMBT
         SET NEW_RATE = IMBT.CKPN_TO_RECEIVE
       WHERE IMBT.PERIODE = DTPERIODE
         AND IMBT.NEW_RATE < 0;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR('-20000',
                                'error when update new rate : ' || SQLERRM || '-' ||
                                SQLCODE);
    END; --end add
  
  END IF;
  --END ADD

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000',
                            'ERR PROC_UPDATE_INFO_CKPN : ' || SQLERRM || '-' ||
                            SQLCODE);
  
END;
/
SELECT * FROM ad1sys.ACCT_PROVISION_RISK_syar A WHERE A.PERIODE = '31JUL2024';

