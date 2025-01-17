/*

Mohon untuk menjalankan Script Step 3(1.2.3 b) setelah ada konfirmasi dari PIC (Juni) di Grup Closing 

*/

--STEP 1
DECLARE
  DTPROS DATE := CASE
                   WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                    TRUNC(SYSDATE)
                   ELSE
                    ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                 END;
BEGIN
  -- CALL THE PROCEDURE
  IFRS.PROC_UPDATE_INFO_REVEIR(DTPROS);
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000',
                            'PROC_UPDATE_INFO_REVEIR ' || SQLERRM,
                            TRUE);
END;
/
--SCRIPT CEK STEP 1
SELECT *
  FROM IFRS.T_REV_EIR_TEMP RET
 WHERE RET.AOL_PROSES_DATE = TRUNC(SYSDATE) - 1; --GANTI HARI H CLOSING

SELECT *
  FROM IFRS.T_REV_EIR RE
 WHERE RE.AOL_PROSES_DATE = TRUNC(SYSDATE) - 1; --GANTI HARI H CLOSING

--STEP 2 SCRIPT JURNAL REV EIR, MOHON RUN PARALEL SELURUH AREA
/*
DECLARE

  SZAREA VARCHAR2(4) := '0001'; -- SAMPLE AREA 1
  DDATE DATE := (CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END);

BEGIN

  FOR REC IN (SELECT BRAN_BR_ID
                FROM AD1SYS.PARA_BRAN_INFO PBI
               WHERE PBI.BRAN_PARENT_ID <> '0000'
                 AND PBI.BRAN_PARENT_ID = SZAREA
               ORDER BY BRAN_BR_ID DESC) LOOP
  
    BEGIN
      AD1SYS.PROC_LOGS_CLOSING(REC.BRAN_BR_ID,
                               'PROC_JOUR_REVS_EIR',
                               '1',
                               DDATE);
    END;
  
    BEGIN
      -- CALL THE PROCEDURE
      IFRS.PROC_JOUR_REVS_EIR(REC.BRAN_BR_ID, DDATE);
    END;
  
    BEGIN
      AD1SYS.PROC_LOGS_CLOSING(REC.BRAN_BR_ID,
                               'PROC_JOUR_REVS_EIR',
                               '2',
                               DDATE);
    END;
  
  END LOOP;
END;
*/

--SCRIPT CEK STEP 2
SELECT *
  FROM AD1SYS.ACCT_INTEGRATION_TRAN AIT
 WHERE AIT.AIT_CODE IN ('0023013', '0023012', '0023014', '0023027')
   AND trunc(AIT.AIT_SYSDATE) = TRUNC(SYSDATE);
