--AMAN 
/*
--/OP 06-OCT-23 0005004/
UPDATE AD1SYS.ACCT_RECON_AM A
   SET A.JML_DATA_TRX  = A.JML_DATA_TRX + 1,
       A.SUM_TRANSAKSI = A.SUM_TRANSAKSI + 30976000,
       A.JML_DATA_AIT  = A.JML_DATA_AIT + 1,
       A.SUM_AIT       = A.SUM_AIT + 30976000
--SELECT * FROM AD1SYS.ACCT_RECON_AM A
 WHERE UPPER(A.KODE_SCRIPT) = 'ONLINE PAYMENT'
   AND TRUNC(A.TRANSACTION_DATE) = '06-OCT-23'
   AND A.TRAN_CODE = '0005004'
   AND A.JML_DATA_TRX = '4825';
*/

/*UPDATE AD1SYS.ACCT_RECON_AM A
   SET A.JML_DATA_TRX  = A.JML_DATA_TRX + 1,
       A.SUM_TRANSAKSI = A.SUM_AIT + 50000000,
       -- A.SELISIH_AMOUNT = 0,
      --  A.STATUS = 'OKE'
      A.JML_DATA_AIT  = A.JML_DATA_AIT + 1,
      A.SUM_AIT       = A.SUM_AIT + 50000000
--SELECT * FROM AD1SYS.ACCT_RECON_AM A
 WHERE UPPER(A.KODE_SCRIPT) = 'RV TRADE'
   AND TRUNC(A.TRANSACTION_DATE) = '02-FEB-24'
   AND A.TRAN_CODE = '0001017'
   AND A.JML_DATA_TRX = '2';*/


SELECT * /*A.TRAN_CODE,
       SUM(A.SUM_TRANSAKSI),
       SUM(A.SUM_AIT),
       A.TRANSACTION_DATE */
  FROM AD1SYS.ACCT_RECON_AM A
 WHERE UPPER(A.KODE_SCRIPT) = 'RV TRADE' --ubah sesuai nama menu yang selisih 
   AND A.TRANSACTION_DATE = '02FEB24' --ubah sesuai tanggal rekon/ h-1 tanggal email notif 
	 and a.TRAN_CODE = '0001017'
   AND EXISTS
 (SELECT 1
          FROM AD1SYS.ACCT_MAPPING_CODE B
         WHERE A.TRAN_CODE = B.AIT_CODE
           AND A.LINE_ITEM = B.LINE_ITEM
           AND UPPER(B.JENIS_TRANSAKSI) = UPPER(A.KODE_SCRIPT));
 --GROUP BY A.TRAN_CODE, A.TRANSACTION_DATE;

--SAP 

SELECT A.TRAN_CODE, A.AMOUNT, A.INSERT_DATE, a.LINE_ITEM
  FROM AD1SYS.SAP_LINE_ITEM A
 WHERE EXISTS (SELECT 1
          FROM AD1SYS.ACCT_MAPPING_CODE B
         WHERE A.TRAN_CODE = B.AIT_CODE
           AND A.LINE_ITEM = B.LINE_ITEM
           AND UPPER(B.JENIS_TRANSAKSI) = 'RV TRADE')
   AND A.INSERT_DATE = '02FEB24';
/*
62843930553
62843930553
62566025576.00000
62566025576
*/
select count(1), sum(a.AIT_AMOUNT1) from ad1sys.acct_integration_tran a
where a.AIT_CODE = '0001017'
and a.AIT_POSTING_DATE >= '02FEB24'
and a.ait_posting_date < '03FEB24'
and a.AIT_LINE_GT = '1';


--Cek Transaksi 

SELECT *
  FROM AD1SYS.ACCT_MAPPING_CODE A
 WHERE UPPER(A.JENIS_TRANSAKSI) = 'ONLINE PAYMENT';

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
                 WHERE TRUNC(ARM.TRANSACTION_DATE) = '02FEB24'
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
                             WHERE TRUNC(SLI.INSERT_DATE) = '02FEB24'
                            --  AND SLI.TRAN_CODE ='0013001'
                            
                            ) X1
                     GROUP BY JENIS_TRANSAKSI, TRAN_CODE, INSERT_DATE) F2
            ON F1.GROUP_CODE = F2.GROUP_CODE
           AND F1.TRAN_CODE = F2.TRAN_CODE
           AND F1.LINE_ITEM = F2.LINE_ITEM
           AND f1.transaction_date = f2.INSERT_DATE) X2
 WHERE JENIS_TRANSAKSI = 'RV TRADE'
 GROUP BY JENIS_TRANSAKSI, INSERT_DATE, TRANSACTION_DATE, TRAN_CODE;
