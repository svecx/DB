-- sap
SELECT JENIS_TRANSAKSI,
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
                               WHERE TRUNC(SLI.INSERT_DATE) >= '01MAR24'
                               and trunc(SLI.INSERT_DATE) < '04MAR24'
                              AND SLI.TRAN_CODE ='0018016'
                              
                              ) X1
                       GROUP BY JENIS_TRANSAKSI, TRAN_CODE, INSERT_DATE;
                       
-- am
 SELECT  A.TRAN_CODE,
         SUM(A.SUM_TRANSAKSI),
         SUM(A.SUM_AIT),
         A.TRANSACTION_DATE 
    FROM AD1SYS.ACCT_RECON_AM A
   WHERE  A.TRANSACTION_DATE >= '01MAR24' and A.TRANSACTION_DATE < '04MAR24' --ubah sesuai tanggal rekon/ h-1 tanggal email notif 
     and a.TRAN_CODE = '0018016'
     AND EXISTS
   (SELECT 1
            FROM AD1SYS.ACCT_MAPPING_CODE B
           WHERE A.TRAN_CODE = B.AIT_CODE
             AND A.LINE_ITEM = B.LINE_ITEM
             AND UPPER(B.JENIS_TRANSAKSI) = UPPER(A.KODE_SCRIPT))
   GROUP BY A.TRAN_CODE, A.TRANSACTION_DATE;     
                    
   
-- cek 
select * from ad1sys.acct_integration_tran where AIT_CODE = '0002001' AND AIT_POSTING_DATE = '02MAR24'
