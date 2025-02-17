--STEP 2 JURNAL ACCRUE
---------------------------------------------------------------
--Cek Before
SELECT COUNT(AIT.AIT_DOC_NO_APP),
       SUM(AIT.AIT_AMOUNT1),
       TRUNC(AIT.AIT_POSTING_DATE)
  FROM AD1SYS.ACCT_INTEGRATION_TRAN AIT
 WHERE AIT.AIT_POSTING_DATE = CASE
         WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
          TRUNC(SYSDATE)
         ELSE
          ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
       END --tgl Current EOM
   AND AIT.AIT_CODE IN ('0023001')
   AND AIT.AIT_LINE_GT = '1'
 GROUP BY TRUNC(AIT.AIT_POSTING_DATE);

SELECT COUNT(1), SUM(X.ACCRUED) ACCRUED, X.ACCT_ACCR_PERIOD
  FROM (SELECT OBLIGOR.ACCT_BR_ID,
               OBLIGOR.ACCT_OBJT_CODE APPL_OBJT_CODE,
               SUM(OBLIGOR.ACCT_OVRD_ACCRUED + OBLIGOR.ACCT_CURR_ACCRUED) ACCRUED,
               CAE.APPL_FUND_TYPE CP,
               CAE.APPL_WORK_ACTIVITY KU,
               CAE.APPL_PROD_MATRIX_ID,
               CAE.APPL_PROD_CHANNEL_ID,
               CAE.APPL_GROUP_SALES,
               OBLIGOR.ACCT_ACCR_PERIOD
          FROM AD1SYS.ACCT_AREC_ACCRUED_OBLIGOR OBLIGOR,
               AD1SYS.CRED_APPL_EXTEND          CAE
         WHERE OBLIGOR.ACCT_BR_ID = CAE.APPL_BR_ID(+)
           AND OBLIGOR.ACCT_CONT_NO = CAE.APPL_CONTRACT_NO(+)
           AND OBLIGOR.ACCT_ACCR_PERIOD = CASE
                 WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                  TRUNC(SYSDATE)
                 ELSE
                  ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
               END --tgl Current EOM
           AND OBLIGOR.ACCT_BR_ID =
               (SELECT PBI.BRAN_BR_ID
                  FROM AD1SYS.PARA_BRAN_INFO PBI
                 WHERE PBI.BRAN_BR_ID = OBLIGOR.ACCT_BR_ID)
         GROUP BY OBLIGOR.ACCT_BR_ID,
                  OBLIGOR.ACCT_OBJT_CODE,
                  CAE.APPL_WORK_ACTIVITY,
                  CAE.APPL_FUND_TYPE,
                  CAE.APPL_PROD_MATRIX_ID,
                  CAE.APPL_PROD_CHANNEL_ID,
                  CAE.APPL_GROUP_SALES,
                  OBLIGOR.ACCT_ACCR_PERIOD) X
 WHERE X.ACCRUED > 0
 GROUP BY X.ACCT_ACCR_PERIOD
/

---------------------------------------------------------------

--STEP 2 JURNAL ACCRUE
---------------------------------------------------------------
DECLARE
  DTDUE DATE := CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END; --tgl Current EOM
BEGIN
  AD1SYS.PROC_JURNAL_OBLIGOR(DTDUE);
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000', SQLERRM);
END;

/
---------------------------------------------------------------

--STEP 5 JURNAL REV OBLIGOR DLB
---------------------------------------------------------------
DECLARE
  DTDUE DATE := CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END; --tgl Current EOM
BEGIN
  -- Call the procedure
  AD1SYS.PROC_JURNAL_REV_DLB_OBLIGOR(DTDUE);

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000', SQLERRM);
END;
/

--Cek After
SELECT COUNT(AIT.AIT_DOC_NO_APP),
       SUM(AIT.AIT_AMOUNT1),
       TRUNC(AIT.AIT_POSTING_DATE)
  FROM AD1SYS.ACCT_INTEGRATION_TRAN AIT
 WHERE AIT.AIT_POSTING_DATE = CASE
         WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
          TRUNC(SYSDATE)
         ELSE
          ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
       END --tgl Current EOM
   AND AIT.AIT_CODE IN ('0023001')
   AND AIT.AIT_LINE_GT = '1'
 GROUP BY TRUNC(AIT.AIT_POSTING_DATE);

SELECT COUNT(1), SUM(X.ACCRUED) ACCRUED, X.ACCT_ACCR_PERIOD
  FROM (SELECT OBLIGOR.ACCT_BR_ID,
               OBLIGOR.ACCT_OBJT_CODE APPL_OBJT_CODE,
               SUM(OBLIGOR.ACCT_OVRD_ACCRUED + OBLIGOR.ACCT_CURR_ACCRUED) ACCRUED,
               CAE.APPL_FUND_TYPE CP,
               CAE.APPL_WORK_ACTIVITY KU,
               CAE.APPL_PROD_MATRIX_ID,
               CAE.APPL_PROD_CHANNEL_ID,
               CAE.APPL_GROUP_SALES,
               OBLIGOR.ACCT_ACCR_PERIOD
          FROM AD1SYS.ACCT_AREC_ACCRUED_OBLIGOR OBLIGOR,
               AD1SYS.CRED_APPL_EXTEND          CAE
         WHERE OBLIGOR.ACCT_BR_ID = CAE.APPL_BR_ID(+)
           AND OBLIGOR.ACCT_CONT_NO = CAE.APPL_CONTRACT_NO(+)
           AND OBLIGOR.ACCT_ACCR_PERIOD = CASE
                 WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                  TRUNC(SYSDATE)
                 ELSE
                  ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
               END --tgl Current EOM
           AND OBLIGOR.ACCT_BR_ID =
               (SELECT PBI.BRAN_BR_ID
                  FROM AD1SYS.PARA_BRAN_INFO PBI
                 WHERE PBI.BRAN_BR_ID = OBLIGOR.ACCT_BR_ID)
         GROUP BY OBLIGOR.ACCT_BR_ID,
                  OBLIGOR.ACCT_OBJT_CODE,
                  CAE.APPL_WORK_ACTIVITY,
                  CAE.APPL_FUND_TYPE,
                  CAE.APPL_PROD_MATRIX_ID,
                  CAE.APPL_PROD_CHANNEL_ID,
                  CAE.APPL_GROUP_SALES,
                  OBLIGOR.ACCT_ACCR_PERIOD) X
 WHERE X.ACCRUED > 0
 GROUP BY X.ACCT_ACCR_PERIOD
