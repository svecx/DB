--> [11.2] PARAREL DENGAN 11.1
/*CREATE OR REPLACE PROCEDURE AD1SYS.PROC_RUN_JOB_CKPN_ECL(DTPERIODE DATE,
                                                         SZJOB     VARCHAR2) IS*/

  --V.4 BY Roni, MTC parameter input ckpn osx
DECLARE
  dtPeriode   DATE := '31JUL2024'; --TANGGAL CLOSING 1 (EOM)
  SZJOB       VARCHAR2(50) := 'CALC ECL';
  ID_JOB      NUMBER;
  PLSQL_BLOCK VARCHAR2(5000);
  DTDUE       VARCHAR2(15) := TO_CHAR(DTPERIODE);
  SZAREA      VARCHAR2(4);
  SZCEKAR     NUMBER := 0;
  SZCEKTEMP   NUMBER := 0;

  LNGSEQUENCE NUMBER;
  BATCH_SEQ   VARCHAR2(13);

  COUNTER NUMBER := 0;

BEGIN

  --GENERATE SEQUENCE BATCH ID
  CSEQUENCEMGR_INCREASESEQUENCE('SEQJOBCKPN',
                                TO_CHAR(DTPERIODE, 'rrrr'),
                                '0000');
  CSEQUENCEMGR_GETSEQUENCENEW('SEQJOBCKPN',
                              TO_CHAR(DTPERIODE, 'rrrr'),
                              '0000',
                              LNGSEQUENCE);

  BATCH_SEQ := '0000' || TO_CHAR(DTPERIODE, 'RR') || 'J' ||
               LPAD(LNGSEQUENCE, 6, '0');

  FOR REC IN (SELECT DISTINCT A.BRAN_PARENT_ID AS BRAN_PARENT_ID
                FROM AD1SYS.PARA_BRAN_INFO A
               WHERE A.BRAN_PARENT_ID <> '0000'
                 AND 1 = (CASE
                       WHEN AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('AM004',
                                                           'RUN_JOB',
                                                           '1',
                                                           '4') = 'OSX' THEN
                        (SELECT 1
                           FROM IFRS.OSX_DATA_STAGING B
                          WHERE B.BRANCH_ID = A.BRAN_BR_ID
                            AND B.COB_DATE = DTPERIODE
                            AND ROWNUM = 1)
                       WHEN AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('AM004',
                                                           'RUN_JOB',
                                                           '1',
                                                           '4') = 'AOL' THEN
                        (SELECT 1
                           FROM AD1SYS.ACCT_CKPN_ALL_TEMP AR
                          WHERE AR.ACCT_BR_ID = A.BRAN_BR_ID
                            AND AR.PERIODE = DTPERIODE
                            AND ROWNUM = 1)
                     END)
                 AND NOT EXISTS
               (SELECT 1
                        FROM AD1SYS.TEMP_JOB_CKPN JOB
                       WHERE JOB.PERIODE = DTPERIODE
                         AND JOB.JOB_NAME = SZJOB
                         AND JOB.AREA = A.BRAN_PARENT_ID
                         AND JOB.STATUS IN ('DONE', 'RUN'))) LOOP
  
    COUNTER := COUNTER + 1;
    SZAREA  := TRIM(REC.BRAN_PARENT_ID);
  
    IF AD1SYS.FUNC_CEK_IN_PARA_DOMAIN('AM004', 'RUN_JOB', '1', '4') = 'OSX' THEN
      --move to sp ad1sys.PROC_INSERT_CKPN_ALL v.3
      PLSQL_BLOCK := 'begin ad1sys.PROC_CALC_CKPN_ALL_OSX(''' || (DTDUE) ||
                     ''',''' || SZAREA ||
                     ''');

ad1sys.PROC_UPDATE_FLAG_JOB_CKPN(''' || DTDUE ||
                     ''',''' || BATCH_SEQ || ''',''' || SZJOB || ''',''' ||
                     SZAREA || ''',''' || '0' ||
                     ''');
exception
when others then
rollback;
ad1sys.PROC_UPDATE_FLAG_JOB_CKPN(''' || DTDUE ||
                     ''',''' || BATCH_SEQ || ''',''' || SZJOB || ''',''' ||
                     SZAREA || ''',''' || '1' || ''');
end;';
    
    ELSE
      PLSQL_BLOCK := 'begin ad1sys.PROC_INSERT_CKPN_ALL(''' || SZAREA ||
                     ''',''' || (DTDUE) ||
                     ''');

ad1sys.PROC_UPDATE_FLAG_JOB_CKPN(''' || DTDUE ||
                     ''',''' || BATCH_SEQ || ''',''' || SZJOB || ''',''' ||
                     SZAREA || ''',''' || '0' ||
                     ''');
exception
when others then
rollback;
ad1sys.PROC_UPDATE_FLAG_JOB_CKPN(''' || DTDUE ||
                     ''',''' || BATCH_SEQ || ''',''' || SZJOB || ''',''' ||
                     SZAREA || ''',''' || '1' || ''');
end;';
    END IF;
  
    DBMS_JOB.SUBMIT(ID_JOB, PLSQL_BLOCK);
  
    INSERT INTO AD1SYS.TEMP_JOB_CKPN
      (PERIODE, JOB_NAME, START_TIME, JOB_ID, AREA, STATUS, SEQ_ID)
    VALUES
      (TRUNC(DTPERIODE), SZJOB, SYSDATE, ID_JOB, SZAREA, 'RUN', BATCH_SEQ);
    COMMIT;
  
  END LOOP;

  --ROLLBACK SEQUENCE
  IF COUNTER = 0 THEN
  
    SELECT COUNT(1)
      INTO COUNTER
      FROM AD1SYS.TEMP_JOB_CKPN A
     WHERE A.PERIODE = TRUNC(DTPERIODE)
       AND A.JOB_NAME = SZJOB;
  
    IF COUNTER = 0 THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR('-20000',
                              'DATA CABANG PENCADANGAN AR KOSONG / PROSES CKPN SUDAH DILAKUKAN');
    END IF;
  
  END IF;

  AD1SYS.PROC_CHECK_JOB_CKPN(DTDUE, SZJOB, BATCH_SEQ);

EXCEPTION
  WHEN OTHERS THEN
    RAISE_APPLICATION_ERROR('-20000',
                            'ERR PROC_RUN_JOB_CKPN || ' || SQLERRM);
END;
