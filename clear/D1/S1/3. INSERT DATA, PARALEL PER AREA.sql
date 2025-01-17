--CEK
-- PASTIKAN SOURCE( OBLIGOR ) DATANYA KOSONG
SELECT SUM(NVL(R.ACCT_ACCRUED_TOTAL, 0)), 'PENCADANGAN AR' SOURCE
  FROM AD1SYS.ACCT_PENCADANGAN_AR R
 WHERE R.ACCT_PERIODE = CASE
         WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
          TRUNC(SYSDATE)
         ELSE
          ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
       END
   AND R.ACCT_COLLECTABILITY_OID_BI <= 2
   AND NVL(R.ACCT_ACCRUED_TOTAL, 0) <> 0
   AND R.ACCT_ACCRUED_STATUS = 1
   AND R.STATUS = 'AKTIF'
   AND NOT EXISTS (SELECT 1
          FROM AD1SYS.ACCT_FINAL_COLLECT_JF B
         WHERE B.CONTRACT_NUMBER = R.ACCT_CONT_NO
           AND B.BRANCH = R.ACCT_BR_ID
           AND B.PERIODE = R.ACCT_PERIODE
           AND B.COLLECTABILITY > 2)
UNION ALL
SELECT SUM(A.ACCT_OVRD_ACCRUED + A.ACCT_CURR_ACCRUED), 'OBLIGOR' SOURCE
  FROM AD1SYS.ACCT_AREC_ACCRUED_OBLIGOR A
 WHERE A.ACCT_ACCR_PERIOD = CASE
         WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
          TRUNC(SYSDATE)
         ELSE
          ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
       END;
       
-- STEP 1 INSERT DATA, PARALEL PER AREA
---------------------------------------------------------------
/*
DECLARE
  SZAREA VARCHAR2(4) := '0001'; --02, 03, 04, 05, 06, 07, 08 , 11
  DTDUE DATE := CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END; --tgl Current EOM

BEGIN
  FOR REC IN (SELECT PBI.BRAN_BR_ID, PBI.BRAN_SYS_LASTDAY_CLOSING
                FROM AD1SYS.PARA_BRAN_INFO PBI
               WHERE PBI.BRAN_PARENT_ID <> '0000'
                 AND PBI.BRAN_PARENT_ID = SZAREA
                 AND PBI.BRAN_SYS_LASTDAY_CLOSING = DTDUE
                 AND EXISTS (SELECT 1
                        FROM AD1SYS.TEMP_ACCT_AREC_ACCRUED_MIS A
                       WHERE A.ACCT_BR_ID = PBI.BRAN_BR_ID
                         AND A.ACCT_ACCR_PERIOD =
                             PBI.BRAN_SYS_LASTDAY_CLOSING
                         AND ROWNUM = 1)) LOOP
  
    BEGIN
      INSERT INTO AD1SYS.ACCT_AREC_ACCRUED_OBLIGOR
        SELECT ACCT_BR_ID,
               ACCT_CONT_NO,
               ACCT_CUST_NO,
               ACCT_OBJT_CODE,
               ACCT_DAYS_ACCRUED,
               ACCT_OVRD_ACCRUED,
               ACCT_CURR_ACCRUED,
               ACCT_ACCRUED_STATUS,
               ACCT_ACCR_PERIOD,
               ACCT_KEGIATAN_USAHA,
               ACCT_CARA_PEMBIAYAAN,
               CUST_OID,
               APPL_BANK_PENDANAAN,
               BANK_GROUP,
               SOURCE_SYSTEM
          FROM (SELECT ACCT_BR_ID,
                       ACCT_CONT_NO,
                       ACCT_CUST_NO,
                       ACCT_OBJT_CODE,
                       ACCT_DAYS_ACCRUED,
                       ACCT_OVRD_ACCRUED,
                       ACCT_CURR_ACCRUED,
                       ACCT_ACCRUED_STATUS,
                       ACCT_ACCR_PERIOD,
                       ACCT_KEGIATAN_USAHA,
                       ACCT_CARA_PEMBIAYAAN,
                       (SELECT CM.CUST_OID
                          FROM AD1SYS.CUST_MASTER    CM,
                               AD1SYS.AREC_CONT_MAST ACM
                         WHERE CM.CUST_BR_ID = ACM.AREC_BR_ID
                           AND CM.CUST_NO = ACM.AREC_CUST_NO
                           AND CM.CUST_BR_ID = A.ACCT_BR_ID
                           AND ACM.AREC_CONT_NO = A.ACCT_CONT_NO) AS CUST_OID,
                       CA.APPL_BANK_PENDANAAN,
                       (CASE
                         WHEN CA.APPL_BANK_PENDANAAN = '196' THEN
                          'AQMF'
                         WHEN CA.APPL_BANK_PENDANAAN NOT IN
                              ('102',
                               '124',
                               '125',
                               '126',
                               '127',
                               '128',
                               '129') THEN
                          'ADMF'
                         ELSE
                          'BBDI'
                       END) AS BANK_GROUP,
                       'AOL' SOURCE_SYSTEM
                  FROM AD1SYS.TEMP_ACCT_AREC_ACCRUED_MIS A,
                       AD1SYS.CRED_APPL                  CA
                 WHERE A.ACCT_BR_ID = REC.BRAN_BR_ID
                   AND A.ACCT_ACCR_PERIOD = REC.BRAN_SYS_LASTDAY_CLOSING
                   AND A.ACCT_ACCRUED_STATUS = '1'
                   AND A.ACCT_BR_ID = CA.APPL_BR_ID
                   AND A.ACCT_CONT_NO = CA.APPL_CONTRACT_NO
                   AND 1 = (CASE
                         WHEN CA.APPL_FIN_TYPE = '2' AND
                              CA.APPL_INT_TYPE = '09' THEN
                          0
                         ELSE
                          1
                       END) --exclude pk imbt
                   AND EXISTS
                 (SELECT 1
                          FROM AD1SYS.RPT_AGING_MIS RAM
                         WHERE RAM.BRANCHID = A.ACCT_BR_ID
                           AND RAM.CONTRACTNO = A.ACCT_CONT_NO
                           AND RAM.REQDATE = A.ACCT_ACCR_PERIOD)) XX
         WHERE 0 = CASE
                 WHEN NVL((SELECT 1
                            FROM AD1SYS.ACCT_FINAL_COLLECT_JF AFJ
                           WHERE AFJ.BRANCH = XX.ACCT_BR_ID
                             AND AFJ.CIF = XX.ACCT_CUST_NO
                             AND AFJ.CONTRACT_NUMBER = XX.ACCT_CONT_NO
                             AND AFJ.PERIODE = XX.ACCT_ACCR_PERIOD
                             AND AFJ.COLLECTABILITY >= '3'),
                          0) = 1 THEN
                  1
                 WHEN NVL((SELECT 1
                            FROM AD1SYS.ACCT_PENCADANGAN_AR AR
                           WHERE AR.ACCT_BR_ID = XX.ACCT_BR_ID
                             AND AR.ACCT_CONT_NO = XX.ACCT_CONT_NO
                             AND AR.ACCT_PERIODE = XX.ACCT_ACCR_PERIOD
                             AND AR.ACCT_COLLECTABILITY_OID_BI >= '3'
                             AND ROWNUM = 1),
                          0) = 1 THEN
                  1
                 ELSE
                  0
               END;
    
      COMMIT;
    
    EXCEPTION
      WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR('-20000',
                                'ERROR PRC_INSERT_DETAIL_ACCR_OBLIGOR : ' ||
                                TO_CHAR(REC.BRAN_SYS_LASTDAY_CLOSING,
                                        'DD-MON-RRRR') || ' ' || SQLERRM);
    END;
  
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000', SQLERRM);
END;



*/

-- JALANKAN KEMBALI SCRIPT PENGECEKAN DAN PASTIKAN DATA DI SOURCE ( OBLIGORE ) SUDAH TERISI
---------------------------------------------------------------
--STEP 2 INSERT OBLIGOR DLB
---------------------------------------------------------------
DECLARE
  DTDUE DATE := CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END;
  AREA  VARCHAR2(4) := '0001'; --0001 0002 0003 0004 0005 0006 0007 0008 0011 7000
BEGIN
  AD1SYS.PRC_INSERT_OBLIGOR_DLB(AREA, DTDUE);
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000', SQLERRM);
END;


---------------------------------------------------------------
--3. INSERT REV DLB
---------------------------------------------------------------
DECLARE
  DTDUE DATE := CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END;
  AREA  VARCHAR2(4) := '0001'; --0001 0002 0003 0004 0005 0006 0007 0008 0011 7000
BEGIN
  -- Call the procedure
  AD1SYS.PRC_INSERT_REV_OBLIGOR_DLB(AREA, DTDUE);
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000', SQLERRM);
END;

---------------------------------------------------------------

--STEP 4 JURNAL ACCRUE
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


---------------------------------------------------------------

--6. REVERSE ACCRUE ONE OBLIGOR RESTRUKTUR
-- NOTE : MOHON RUNNING PARALEL UNTUK SEMUA AREA !!
---------------------------------------------------------------
/*
DECLARE
  SZAREA VARCHAR2(4) := '0001'; -- mohon running paralel untuk semua area !!
  SZDATE DATE := CASE
                   WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                    TRUNC(SYSDATE)
                   ELSE
                    ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                 END; --tgl Current EOM

BEGIN

  FOR BR IN (SELECT PB.BRAN_BR_ID BRID
               FROM PARA_BRAN_INFO PB
              WHERE PB.BRAN_REGION_ID <> '0000'
                AND PB.BRAN_PARENT_ID = SZAREA) LOOP
  
    BEGIN
      -- Call the procedure
      AD1SYS.PROC_REVERS_ACCRUE_BUNGA_REST(BR.BRID, SZDATE);
    END;
  
  END LOOP;
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000',
                            'ERROR PROC_REVERS_ACCRUE_BUNGA_REST ' ||
                            SQLERRM,
                            TRUE);
END;


*/


/*
SETELAH SELESAI MENJALANKAN SCRIPT STEP 2 MOHON UNTUK MELAKUKAN KONFIRMASI DI GRUP CLOSING 
->
Dear All,
Step 2 Insert Accrue Obligor telah selesai dilakukan.
Terimakasih.

*/
