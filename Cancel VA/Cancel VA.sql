/*
� Tim Opr,
Mohon bantuannya untuk execute script Cancel VA_WO_REPO dan jika script Cancel VA_WO_REPO sudah executemohon 
diinformasikan ke tim Opr HO agar bisa lanjut ke step berikutnya.

� Tim Opr HO,
Mohon execute script Delete VA_WO_REPO setelah tim Opr memberi konfirmasi selesai execute script VA_WO_REPO. 
Dan mohon untuk dibuatkan tiketnya
*/
--pastikan data t_flag = 3  dan masih ada di t_pembayaran@dbgapura setalah ada bisa langsung jalankan script dibawah dengan mengganti no va dan cabangnya
--perhatikan field handling dan cabang harus sama, jika tidak update field handling = cabang
--pastikan va_amt harus sama dengna script pengecekan.
-- pastikan t-flag 3 dan br_id = br_id_handling dan branchid
select * from ad1sys.t_pembayaran_clar a where a.no_va='7227992400000044';
select * from ad1sys.t_pembayaran_detail_clar d where d.no_va='7227992400000044';
--bisa jadi kosong
SELECT * FROM AD1SYS.AREC_COLL_VA_RMK A
WHERE A.AREC_NO_KONTRAK='010820449445';



--script cek ada dibagian paling bawah
--COMMIT setelah script cek sesuai

DECLARE
  SZBRID   VARCHAR2(4) := '0131'; --MOHON UNTUK DISESUAIKAN 
  SZUSER   VARCHAR2(30) := 'SR15435'; --MOHON UNTUK DISESUAIKAN 
  SZMENU   VARCHAR2(10) := '';
  SZBUTTON VARCHAR2(10) := '';
  SZIPADDR VARCHAR2(10) := '';
  VANO     VARCHAR2(20) := '7227992400000044'; -- MOHON UNTUK DISESUAIKAN

  TYPE REC_VA IS RECORD(
    NO_VA       AD1SYS.T_PEMBAYARAN_CLAR.NO_VA%TYPE,
    BRANCHID    AD1SYS.T_PEMBAYARAN_CLAR.BRANCHID%TYPE,
    NO_REF      AD1SYS.T_PEMBAYARAN_CLAR.NO_REF%TYPE,
    T_CLASSCODE AD1SYS.T_PEMBAYARAN_CLAR.T_CLASSCODE%TYPE,
    BR_ID       AD1SYS.T_PEMBAYARAN_DETAIL_CLAR.BR_ID%TYPE,
    CONTRACT_NO AD1SYS.T_PEMBAYARAN_DETAIL_CLAR.CONTRACT_NO%TYPE);

  TYPE LIST_VA_TABLE IS TABLE OF REC_VA;
  ROWS_VA LIST_VA_TABLE := LIST_VA_TABLE();

  SZCONSTNAME VARCHAR2(50);
  SZLOGID     VARCHAR2(50);
  SZDESC      VARCHAR2(100);
  SZREFF_NO   VARCHAR2(50);
  SZBRIDPK    VARCHAR2(4);
  SZERR_MSG   VARCHAR2(1000);
  SZBRAN_NAME VARCHAR2(100);
  SZCEK_STAT  VARCHAR2(3);
  SZWOREPO#   VARCHAR2(1);
  VCOUNT_PK   NUMBER;
  SZCEK_TPC   VARCHAR2(2);
  VMAX_SEQ    NUMBER;
BEGIN
  SZERR_MSG := '';

  BEGIN
    SELECT TRIM(PBI.BRAN_BR_NAME)
      INTO SZBRAN_NAME
      FROM AD1SYS.PARA_BRAN_INFO PBI
     WHERE PBI.BRAN_BR_ID = SZBRID
       AND ROWNUM = 1;
  END;

  UPDATE AD1SYS.T_PEMBAYARAN_CLAR TPC
     SET TPC.TANGGAL_PROSES_CABANG = SYSDATE,
         TPC.T_FLAG_VA             = '2',
         TPC.STATUS_PROSES         = '2'
   WHERE TPC.NO_VA = VANO
     AND TPC.BRANCHID = SZBRID
     AND TPC.T_FLAG_VA = '3';

  BEGIN
    SELECT TPC.NO_VA,
           TPC.BRANCHID,
           TPC.NO_REF,
           TPC.T_CLASSCODE,
           TPDC.BR_ID,
           TPDC.CONTRACT_NO BULK COLLECT
      INTO ROWS_VA
      FROM AD1SYS.T_PEMBAYARAN_CLAR        TPC,
           AD1SYS.T_PEMBAYARAN_DETAIL_CLAR TPDC
     WHERE TPC.BRANCHID = SZBRID
       AND TPC.BRANCHID = TPDC.BR_ID_HANDLING
       AND TPC.NO_VA = TPDC.NO_VA
       AND TPC.STATUS_PROSES = '2'
       AND TPC.T_FLAG_VA = '2'
       AND TPC.STATUS_PROSES_CABANG = '0'
       AND TPDC.FLAG_VA = '0'
       AND TPC.NO_VA = VANO
       AND NOT EXISTS (SELECT 1
              FROM AD1SYS.AREC_COLL_VA_RMK ACV
             WHERE ACV.AREC_SZBRANCHID = TPC.BRANCHID
               AND ACV.AREC_NO_KONTRAK = TPC.NO_VA);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      ROWS_VA.DELETE;
    WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR('-20000',
                              'ERROR GET LIST VA ' || SZBRID || ' - ' ||
                              SQLERRM || ' !');
  END;

  FOR TMP IN NVL(ROWS_VA.FIRST, 0) .. NVL(ROWS_VA.LAST, -1) LOOP
    IF NVL(SZERR_MSG, ' ') <> ' ' THEN
      AD1SYS.PROC_MANAGE_SENDEMAIL('M-RMK',
                                   'ERROR JURNAL VA REMARKETING CAB. ' ||
                                   SZBRID || ' - ' || SZBRAN_NAME,
                                   'MESSAGE ERROR - ' || SZERR_MSG);
    END IF;
    SZERR_MSG := '';
  
    SZCONSTNAME := F_GETCONSTNAME(ROWS_VA(TMP).T_CLASSCODE);
  
    IF AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('E-RMK',
                                      'EXC_CC',
                                      UPPER(TRIM(SZCONSTNAME)),
                                      3) = TRIM(SZCONSTNAME) THEN
      SZREFF_NO := ROWS_VA(TMP).CONTRACT_NO;
    
      BEGIN
        SELECT AP.AREC_BR_ID
          INTO SZBRIDPK
          FROM AD1SYS.AREC_WORKFLOW_WO AP
         WHERE AP.AREC_CONT_NO = SZREFF_NO
           AND AP.AREC_RV_NO = ROWS_VA(TMP).NO_VA
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR GET PK AREC_WORKFLOW_WO - ' || ROWS_VA(TMP)
                      .NO_REF || ' !' || SQLERRM;
        
          ROLLBACK;
          CONTINUE;
      END;
    ELSE
      BEGIN
        SELECT AP.AREC_BR_ID
          INTO SZBRIDPK
          FROM AD1SYS.AREC_PAYMENT_WH AP
         WHERE AP.AREC_BIDDER = ROWS_VA(TMP).NO_REF
           AND AP.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND AP.AREC_CONT_NO = ROWS_VA(TMP).CONTRACT_NO
           AND ROWNUM = 1;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR GET PK AREC_PAYMENT_WH - ' || ROWS_VA(TMP)
                      .NO_REF || ' !' || SQLERRM;
        
          ROLLBACK;
          CONTINUE;
      END;
    
      SZREFF_NO := ROWS_VA(TMP).CONTRACT_NO;
    END IF;
  
    IF UPPER(SZCONSTNAME) = 'RT_WOPRETERM' THEN
      BEGIN
        UPDATE AD1SYS.AREC_CONT_WO A
           SET A.AREC_RECV_NO = NULL
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_CONT_WO A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND NVL(A.AREC_RECV_NO, ' ') = ' ';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        UPDATE AD1SYS.AREC_WORKFLOW_WO AW
           SET AW.FLAG_RV = '2'
         WHERE AW.AREC_CONT_NO = SZREFF_NO
           AND AW.AREC_RV_NO = ROWS_VA(TMP).NO_VA
           AND AW.AREC_WORKFLOW_FLAG = 'L';
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE ACCT_DEPOSIT - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_WORKFLOW_WO A
         WHERE A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RV_NO = ROWS_VA(TMP).NO_VA
           AND A.AREC_WORKFLOW_FLAG = 'L'
           AND A.FLAG_RV = '2';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_WORKFLOW_WO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      SZDESC := ' AREC_CONT_NO = ' || TRIM(SZREFF_NO) || ' AREC_RV_NO = ' || ROWS_VA(TMP)
               .NO_VA || ' FLAG_RV = 2';
      PCKG_LOGS.P_INSERTLOG(SZLOGID,
                            SZUSER,
                            'U|' || SZMENU || '|' || SZBUTTON || '|' ||
                            'PROSES UPDATE AREC_WORKFLOW_WO ' || '|' ||
                            TRIM(UPPER(SZDESC)),
                            SZIPADDR,
                            SZBRIDPK);
    ELSIF UPPER(SZCONSTNAME) = 'RT_WO_BERTAHAP' THEN
      BEGIN
        SELECT LOGID
          INTO SZLOGID
          FROM AD1SYS.ACCT_DEPOSIT
         WHERE DEPO_BRANC_ID = SZBRIDPK
           AND DEPO_REF_NO = RPAD(SZREFF_NO, 13, ' ')
           AND DEPO_TRANS_CODE = RPAD('PPA65', 12, ' ');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          NULL;
      END;
    
      BEGIN
        UPDATE AD1SYS.ACCT_DEPOSIT A
           SET A.DEPO_STATUS = '1'
         WHERE A.DEPO_BRANC_ID = SZBRIDPK
           AND A.DEPO_REF_NO = RPAD(SZREFF_NO, 13, ' ')
           AND A.DEPO_TRANS_CODE = RPAD('PPA65', 12, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE ACCT_DEPOSIT - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.ACCT_DEPOSIT A
         WHERE A.DEPO_BRANC_ID = SZBRIDPK
           AND A.DEPO_REF_NO = RPAD(SZREFF_NO, 13, ' ')
           AND A.DEPO_TRANS_CODE = RPAD('PPA65', 12, ' ')
           AND A.DEPO_STATUS = '1';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE ACCT_DEPOSIT - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      SZDESC := ' DEPO_REF_NO = ' || TRIM(SZREFF_NO) ||
                ' DEPO_TRANS_CODE = PPA65 DEPO_STATUS = 1';
      PCKG_LOGS.P_INSERTLOG(SZLOGID,
                            SZUSER,
                            'U|' || SZMENU || '|' || SZBUTTON || '|' ||
                            'PROSES UPDATE ACCT_DEPOSIT ' || '|' ||
                            TRIM(UPPER(SZDESC)),
                            SZIPADDR,
                            SZBRID);
    
      BEGIN
        UPDATE AD1SYS.AREC_CONT_WO A
           SET A.AREC_RECV_NO = NULL
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_CONT_WO A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND NVL(A.AREC_RECV_NO, ' ') = ' ';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        UPDATE AD1SYS.AREC_WORKFLOW_WO AW
           SET AW.FLAG_RV = '2'
         WHERE AW.AREC_CONT_NO = SZREFF_NO
           AND AW.AREC_RV_NO = ROWS_VA(TMP).NO_VA
           AND AW.AREC_WORKFLOW_FLAG = 'A';
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE ACCT_DEPOSIT - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_WORKFLOW_WO A
         WHERE A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RV_NO = ROWS_VA(TMP).NO_VA
           AND A.AREC_WORKFLOW_FLAG = 'A'
           AND A.FLAG_RV = '2';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_WORKFLOW_WO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      SZDESC := ' AREC_CONT_NO = ' || TRIM(SZREFF_NO) || ' AREC_RV_NO = ' || ROWS_VA(TMP)
               .NO_VA || ' FLAG_RV = 2';
      PCKG_LOGS.P_INSERTLOG(SZLOGID,
                            SZUSER,
                            'U|' || SZMENU || '|' || SZBUTTON || '|' ||
                            'PROSES UPDATE AREC_WORKFLOW_WO ' || '|' ||
                            TRIM(UPPER(SZDESC)),
                            SZIPADDR,
                            SZBRIDPK);
    ELSIF UPPER(SZCONSTNAME) = 'RT_UNITSOLD' THEN
      BEGIN
        UPDATE AD1SYS.AREC_CONT_REPO A
           SET A.AREC_RECV_NO = NULL
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
     EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_CONT_REPO A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND NVL(A.AREC_RECV_NO, ' ') = ' ';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        CACCTDEPOSIT_UPDATEACCTDEPOSIT(NVL(SZBRIDPK, SZBRID),
                                       TRIM(SZREFF_NO),
                                       'PPA47',
                                       '1',
                                       SZUSER,
                                       SZMENU,
                                       SZBUTTON,
                                       SZIPADDR);
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR RUNNING SP CACCTDEPOSIT_UPDATEACCTDEPOSIT - ' ||
                       SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        UPDATE AD1SYS.AREC_PAYMENT_WH A
           SET A.AREC_FLAG_RV = '2', A.AREC_STATUS = '2'
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND A.AREC_CONT_NO = SZREFF_NO;
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_PAYMENT_WH A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND A.AREC_FLAG_RV = '2'
           AND A.AREC_STATUS = '2';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
    ELSIF UPPER(SZCONSTNAME) = 'RT_BID' THEN
      BEGIN
        UPDATE AD1SYS.AREC_CONT_REPO A
           SET A.AREC_RECV_NO = NULL
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_CONT_REPO A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND NVL(A.AREC_RECV_NO, ' ') = ' ';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        CACCTDEPOSIT_UPDATEACCTDEPOSIT(NVL(SZBRIDPK, SZBRID),
                                       TRIM(SZREFF_NO),
                                       'PPA49',
                                       '1',
                                       SZUSER,
                                       SZMENU,
                                       SZBUTTON,
                                       SZIPADDR);
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR RUNNING SP CACCTDEPOSIT_UPDATEACCTDEPOSIT - ' ||
                       SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        UPDATE AD1SYS.AREC_PAYMENT_WH A
           SET A.AREC_FLAG_RV = '2', A.AREC_STATUS = '2'
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND A.AREC_CONT_NO = SZREFF_NO;
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_PAYMENT_WH A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND A.AREC_FLAG_RV = '2'
           AND A.AREC_STATUS = '2';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    ELSIF UPPER(TRIM(SZCONSTNAME)) =
          AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('E-RMK',
                                         'WO_TRF',
                                         UPPER(TRIM(SZCONSTNAME)),
                                         3) THEN
      BEGIN
        SELECT NVL(AR.AREC_FLAG_WO, '0')
          INTO SZWOREPO#
          FROM AD1SYS.AREC_UNIT_REPO AR
         WHERE AR.AREC_BR_ID = SZBRIDPK
           AND AR.AREC_CONT_NO = SZREFF_NO
           AND AR.AREC_SOLD_STATUS IN ('W', 'R');
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | DATA PK ' || SZREFF_NO ||
                       ' TIDAK DITEMUKAN AREC_UNIT_REPO (WOJUAL) - ' ||
                       SQLERRM;
          ROLLBACK;
          CONTINUE;
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR GET PK ' || SZREFF_NO ||
                       ' AREC_UNIT_REPO (WOJUAL) - ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      IF SZWOREPO# = '1' THEN
        BEGIN
          UPDATE AD1SYS.AREC_CONT_REPO A
             SET A.AREC_RECV_NO = NULL
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_CONT_NO = SZREFF_NO
             AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
        EXCEPTION
          WHEN OTHERS THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          SELECT '1'
            INTO SZCEK_STAT
            FROM AD1SYS.AREC_CONT_REPO A
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_CONT_NO = SZREFF_NO
             AND NVL(A.AREC_RECV_NO, ' ') = ' ';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          CACCTDEPOSIT_UPDATEACCTDEPOSIT(NVL(SZBRIDPK, SZBRID),
                                         TRIM(SZREFF_NO),
                                         'PPA47',
                                         '1',
                                         SZUSER,
                                         SZMENU,
                                         SZBUTTON,
                                         SZIPADDR);
        EXCEPTION
          WHEN OTHERS THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR RUNNING SP CACCTDEPOSIT_UPDATEACCTDEPOSIT - ' ||
                         SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          UPDATE AD1SYS.AREC_PAYMENT_WH A
             SET A.AREC_FLAG_RV = '2', A.AREC_STATUS = '2'
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
             AND A.AREC_CONT_NO = SZREFF_NO;
        EXCEPTION
          WHEN OTHERS THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          SELECT '1'
            INTO SZCEK_STAT
            FROM AD1SYS.AREC_PAYMENT_WH A
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_CONT_NO = SZREFF_NO
             AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
             AND A.AREC_FLAG_RV = '2'
             AND A.AREC_STATUS = '2';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      ELSE
        BEGIN
          UPDATE AD1SYS.AREC_CONT_REPO A
             SET A.AREC_RECV_NO = NULL
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_CONT_NO = SZREFF_NO
             AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
        EXCEPTION
          WHEN OTHERS THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          SELECT '1'
            INTO SZCEK_STAT
            FROM AD1SYS.AREC_CONT_REPO A
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_CONT_NO = SZREFF_NO
             AND NVL(A.AREC_RECV_NO, ' ') = ' ';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          CACCTDEPOSIT_UPDATEACCTDEPOSIT(NVL(SZBRIDPK, SZBRID),
                                         TRIM(SZREFF_NO),
                                         'PPA88',
                                         '1',
                                         SZUSER,
                                         SZMENU,
                                         SZBUTTON,
                                         SZIPADDR);
        EXCEPTION
          WHEN OTHERS THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR RUNNING SP CACCTDEPOSIT_UPDATEACCTDEPOSIT - ' ||
                         SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        IF NVL(SZERR_MSG, ' ') <> ' ' THEN
          ROLLBACK;
          CONTINUE;
        END IF;
      
        BEGIN
          UPDATE AD1SYS.AREC_PAYMENT_WH A
             SET A.AREC_FLAG_RV = '2', A.AREC_STATUS = '2'
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
             AND A.AREC_CONT_NO = SZREFF_NO;
        EXCEPTION
          WHEN OTHERS THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      
        BEGIN
          SELECT '1'
            INTO SZCEK_STAT
            FROM AD1SYS.AREC_PAYMENT_WH A
           WHERE A.AREC_BR_ID = SZBRIDPK
             AND A.AREC_CONT_NO = SZREFF_NO
             AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
             AND A.AREC_FLAG_RV = '2'
             AND A.AREC_STATUS = '2';
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                         SZREFF_NO || ' | ' || SQLERRM;
            ROLLBACK;
            CONTINUE;
        END;
      END IF;
    ELSIF UPPER(SZCONSTNAME) = 'RT_BID_WO' THEN
      BEGIN
        UPDATE AD1SYS.AREC_CONT_REPO A
           SET A.AREC_RECV_NO = NULL
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RECV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ');
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_CONT_REPO A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND NVL(A.AREC_RECV_NO, ' ') = ' ';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_CONT_REPO - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        CACCTDEPOSIT_UPDATEACCTDEPOSIT(NVL(SZBRIDPK, SZBRID),
                                       TRIM(SZREFF_NO),
                                       'PPA25',
                                       '1',
                                       SZUSER,
                                       SZMENU,
                                       SZBUTTON,
                                       SZIPADDR);
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR RUNNING SP CACCTDEPOSIT_UPDATEACCTDEPOSIT - ' ||
                       SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        UPDATE AD1SYS.AREC_PAYMENT_WH A
           SET A.AREC_FLAG_RV = '2', A.AREC_STATUS = '2'
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND A.AREC_CONT_NO = SZREFF_NO;
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      BEGIN
        SELECT '1'
          INTO SZCEK_STAT
          FROM AD1SYS.AREC_PAYMENT_WH A
         WHERE A.AREC_BR_ID = SZBRIDPK
           AND A.AREC_CONT_NO = SZREFF_NO
           AND A.AREC_RV_NO = RPAD(ROWS_VA(TMP).NO_VA, 20, ' ')
           AND A.AREC_FLAG_RV = '2'
           AND A.AREC_STATUS = '2';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE AREC_PAYMENT_WH - ' ||
                       SZREFF_NO || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    END IF;
  
    --CEK DETAIL VA
    BEGIN
      SELECT NVL(MAX(TPDC.DETAIL_SEQ_NO), 0)
        INTO VMAX_SEQ
        FROM AD1SYS.T_PEMBAYARAN_DETAIL_CLAR TPDC
       WHERE TPDC.BR_ID_HANDLING = SZBRID
         AND TPDC.NO_VA = ROWS_VA(TMP).NO_VA;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        VMAX_SEQ := 0;
      WHEN OTHERS THEN
        SZERR_MSG := 'PROC_CNCL_VARMK | ERROR CEK MAX AD1SYS.T_PEMBAYARAN_DETAIL_CLAR - ' || ROWS_VA(TMP)
                    .NO_VA || ' | ' || SQLERRM;
        ROLLBACK;
        CONTINUE;
    END;
  
    IF NVL(VMAX_SEQ, 0) = 0 THEN
      SZERR_MSG := 'PROC_CNCL_VARMK | TIDAK ADA DETAIL AD1SYS.T_PEMBAYARAN_DETAIL_CLAR - ' || ROWS_VA(TMP)
                  .NO_VA || ' | ' || SQLERRM;
      ROLLBACK;
      CONTINUE;
    END IF;
  
    --UPDATE FLAG CANCEL VA DETAIL
    BEGIN
      UPDATE AD1SYS.T_PEMBAYARAN_DETAIL_CLAR TPDC
         SET TPDC.FLAG_VA = '2'
       WHERE TPDC.BR_ID_HANDLING = SZBRID
         AND TPDC.NO_VA = ROWS_VA(TMP).NO_VA
         AND TPDC.CONTRACT_NO = SZREFF_NO;
    EXCEPTION
      WHEN OTHERS THEN
        SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE T_PEMBAYARAN_DETAIL_CLAR - ' ||
                     SZREFF_NO || ' | ' || SQLERRM;
        ROLLBACK;
        CONTINUE;
    END;
  
    --CEK HASIL UPDATE CANCEL VA DETAIL
    BEGIN
      SELECT '1'
        INTO SZCEK_TPC
        FROM AD1SYS.T_PEMBAYARAN_DETAIL_CLAR TPDC
       WHERE TPDC.BR_ID_HANDLING = SZBRID
         AND TPDC.NO_VA = ROWS_VA(TMP).NO_VA
         AND TPDC.CONTRACT_NO = SZREFF_NO
         AND TPDC.FLAG_VA = '2';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE T_PEMBAYARAN_DETAIL_CLAR - ' ||
                     SZREFF_NO || ' | ' || SQLERRM;
        ROLLBACK;
        CONTINUE;
      WHEN OTHERS THEN
        SZERR_MSG := 'PROC_CNCL_VARMK | ERROR CEK AD1SYS.T_PEMBAYARAN_DETAIL_CLAR - ' ||
                     SZREFF_NO || ' | ' || SQLERRM;
        ROLLBACK;
        CONTINUE;
    END;
  
    --COUNT DETAIL VA BERHASIL CANCEL VA
    BEGIN
      SELECT COUNT(1)
        INTO VCOUNT_PK
        FROM AD1SYS.T_PEMBAYARAN_DETAIL_CLAR TPDC
       WHERE TPDC.BR_ID_HANDLING = SZBRID --TPDC.BR_ID = SZBRIDPK --MOD BY AZZY 06JUL20
         AND TPDC.NO_VA = ROWS_VA(TMP).NO_VA
         AND TPDC.FLAG_VA = '2';
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        VCOUNT_PK := 0;
      WHEN OTHERS THEN
        SZERR_MSG := 'PROC_CNCL_VARMK | ERROR CEK AD1SYS.T_PEMBAYARAN_DETAIL_CLAR - ' ||
                     SZREFF_NO || ' | ' || SQLERRM;
        ROLLBACK;
        CONTINUE;
    END;
  
    --UPDATE FLAG STATUS PROSES CABANG CANCEL VA HEADER
    IF VCOUNT_PK = VMAX_SEQ THEN
      BEGIN
        UPDATE AD1SYS.T_PEMBAYARAN_CLAR TPC
           SET TPC.STATUS_PROSES_CABANG  = '2',
               TPC.TANGGAL_PROSES_CABANG = SYSDATE
         WHERE TPC.BRANCHID = SZBRID
           AND TPC.NO_VA = ROWS_VA(TMP).NO_VA
           AND TPC.STATUS_PROSES = '2'
           AND TPC.T_FLAG_VA = '2'
           AND TPC.STATUS_PROSES_CABANG = '0';
      EXCEPTION
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE T_PEMBAYARAN_CLAR - ' || ROWS_VA(TMP)
                      .NO_VA || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    
      --CEK HASIL UPDATE CANCEL VA HEADER
      BEGIN
        SELECT '1'
          INTO SZCEK_TPC
          FROM AD1SYS.T_PEMBAYARAN_CLAR TPC
         WHERE TPC.BRANCHID = SZBRID
           AND TPC.NO_VA = ROWS_VA(TMP).NO_VA
           AND TPC.STATUS_PROSES = '2'
           AND TPC.T_FLAG_VA = '2'
           AND TPC.STATUS_PROSES_CABANG = '2';
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR UPDATE T_PEMBAYARAN_CLAR - ' || ROWS_VA(TMP)
                      .NO_VA || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
        WHEN OTHERS THEN
          SZERR_MSG := 'PROC_CNCL_VARMK | ERROR CEK AD1SYS.T_PEMBAYARAN_CLAR - ' || ROWS_VA(TMP)
                      .NO_VA || ' | ' || SQLERRM;
          ROLLBACK;
          CONTINUE;
      END;
    END IF;
  
  END LOOP;
  IF NVL(SZERR_MSG, ' ') <> ' ' THEN
    AD1SYS.PROC_MANAGE_SENDEMAIL('M-RMK',
                                 'ERROR JURNAL VA REMARKETING CAB. ' ||
                                 SZBRID || ' - ' || SZBRAN_NAME,
                                 'MESSAGE ERROR - ' || SZERR_MSG);
  END IF;
  SZERR_MSG := '';
EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000', 'ERROR PROC_CNCL_VARMK ' || SQLERRM);
END;

/*---Script Cek
-- Pastikan kosong
SELECT * FROM AD1SYS.T_PEMBAYARAN_CLAR TPC --1ROW
WHERE TPC.NO_VA IN ('7227992400000044') --MOHON DISESUAIKAN
   AND TPC.T_FLAG_VA = '2' and TPC.STATUS_PROSES  = '2';


SELECT * FROM AD1SYS.T_PEMBAYARAN_DETAIL_CLAR TPDC --1ROW
WHERE TPDC.NO_VA = '7227992400000044' --MOHON DISESUAIKAN
and TPDC.FLAG_VA = '2';
*/

