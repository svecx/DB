DECLARE
  SZAREA VARCHAR2(4) := '0002'; --02, 03, 04, 05, 06, 07, 08 , 11
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
