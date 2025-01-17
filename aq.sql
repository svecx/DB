select JENIS_TRANSAKSI,
       TRANSACTION_DATE,
       INSERT_DATE,
       TRAN_CODE,
       sum(X2.JML_DT_TRAN) JML_DT_TRAN,
       sum(X2.JML_DT_AIT) JML_DT_AIT,
       sum(X2.AMOUNT_TRAN) AMOUNT_TRAN,
       sum(X2.AMOUNT_AIT) AMOUNT_AIT,
       NVL(sum(X2.JML_SAP), 0) JML_SAP,
       NVL(sum(X2.JML_DT_TRAN), 0) - NVL(sum(X2.JML_DT_AIT), 0) JML_TRAN_VS_AIT,
       NVL(sum(X2.AMOUNT_AIT), 0) - NVL(sum(X2.AMOUNT_TRAN), 0) AMT_TRAN_VS_AIT,
       NVL(sum(X2.AMOUNT_AIT), 0) - NVL(sum(X2.JML_SAP), 0) AMT_AIT_VS_SAP
  from (SELECT F1.JENIS_TRANSAKSI,
               F2.SOURCE_SYS,
               F1.GROUP_CODE,
               F1.TRAN_CODE,
               F2.INSERT_DATE,
               F1.TRANSACTION_DATE,
               --      F1.LINE_ITEM,
               F1.JML_DT_TRAN,
               F1.JML_DT_AIT,
               F1.AMOUNT_TRAN,
               F1.AMOUNT_AIT,
               F2.AMOUNT JML_SAP,
               F1.JML_DT_TRAN - F1.JML_DT_AIT JML_TRAN_VS_AIT,
               F1.AMOUNT_TRAN - F1.AMOUNT_AIT AMT_TRAN_VS_AIT,
               F1.AMOUNT_AIT - F2.AMOUNT AMT_AIT_VS_SAP,
               'SUM' KODE,
               CASE
                 WHEN F1.JML_DT_TRAN - F1.JML_DT_AIT = 0 AND
                      F1.AMOUNT_TRAN - F1.AMOUNT_AIT = 0 AND
                      F1.AMOUNT_AIT - F2.AMOUNT = 0 THEN
                  0
                 WHEN F1.JML_DT_TRAN - F1.JML_DT_AIT <> 0 OR
                      F1.AMOUNT_TRAN - F1.AMOUNT_AIT <> 0 OR
                      F1.AMOUNT_AIT - F2.AMOUNT <> 0 THEN
                  1
               END KET,
               SYSDATE
          FROM (SELECT ARM.GROUP_CODE,
                       ARM.TRAN_CODE,
                       ARM.LINE_ITEM,
                       ARM.TRANSACTION_DATE,
                       SUM(ARM.JML_DATA_TRX) JML_DT_TRAN,
                       SUM(ARM.JML_DATA_AIT) JML_DT_AIT,
                       SUM(ARM.SUM_TRANSAKSI) AMOUNT_TRAN,
                       SUM(ARM.SUM_AIT) AMOUNT_AIT,
                       (SELECT MAX(UPPER(AMC.JENIS_TRANSAKSI))
                          FROM AD1SYS.ACCT_MAPPING_CODE AMC
                         WHERE AMC.GROUP_CODE = ARM.GROUP_CODE
                           AND AMC.AIT_CODE = ARM.TRAN_CODE
                           AND AMC.LINE_ITEM = ARM.LINE_ITEM) JENIS_TRANSAKSI
                  FROM AD1SYS.ACCT_RECON_AM ARM
                 WHERE TRUNC(ARM.TRANSACTION_DATE) = '05FEB24'
                   AND ARM.TRAN_CODE IS NOT NULL
                --AND ARM.TRAN_CODE='0013001'
                 GROUP BY ARM.GROUP_CODE,
                          ARM.TRAN_CODE,
                          ARM.LINE_ITEM,
                          ARM.TRANSACTION_DATE) F1
          LEFT JOIN (SELECT JENIS_TRANSAKSI,
                           MAX(SOURCE_SYS) SOURCE_SYS,
                           MAX(GROUP_CODE) GROUP_CODE,
                           TRAN_CODE TRAN_CODE,
                           MAX(LINE_ITEM) LINE_ITEM,
                           ABS(SUM(AMOUNT)) AMOUNT,
                           INSERT_DATE
                      FROM (SELECT (SELECT MAX(UPPER(AMC.JENIS_TRANSAKSI))
                                      FROM AD1SYS.ACCT_MAPPING_CODE AMC
                                     WHERE AMC.GROUP_CODE = SLI.GROUP_CODE
                                       AND AMC.AIT_CODE = SLI.TRAN_CODE
                                       AND AMC.LINE_ITEM = SLI.LINE_ITEM) JENIS_TRANSAKSI,
                                   SLI.*
                              FROM AD1SYS.SAP_LINE_ITEM SLI
                             WHERE TRUNC(SLI.INSERT_DATE) = '05FEB24'
                            --  AND SLI.TRAN_CODE ='0013001'
                            
                            ) X1
                     GROUP BY JENIS_TRANSAKSI, TRAN_CODE, INSERT_DATE) F2
            ON F1.GROUP_CODE = F2.GROUP_CODE
           AND F1.TRAN_CODE = F2.TRAN_CODE
           AND F1.LINE_ITEM = F2.LINE_ITEM
           AND f1.transaction_date = f2.INSERT_DATE) X2
-- WHERE JENIS_TRANSAKSI = 'ONLINE PAYMENT'
 GROUP BY JENIS_TRANSAKSI, INSERT_DATE, TRANSACTION_DATE, TRAN_CODE;
