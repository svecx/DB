SELECT COUNT(1)
  FROM IT_OPR1_AOL.TEMP_PREMI_RENEWAL_MOTOR MCY, AD1SYS.PARA_BRAN_INFO A
 WHERE MCY.TEMP_PROSES = '1'
 AND MCY.TEMP_BR_ID = A.BRAN_BR_ID
 AND A.BRAN_PARENT_ID = '0003';
/
DECLARE
  SZBRID       VARCHAR2(4);
  PERSENOTR    VARCHAR2(200);
  USIA         NUMBER;
  SZERROR      VARCHAR2(1000);
  SZOBJT       VARCHAR2(3);
  SZTENOR      NUMBER := 12;
  SZTYPEINSR   VARCHAR2(1);
  SZINSRID     VARCHAR2(2) := '02';
  SZMOTOR      VARCHAR2(1);
  RATEPA       NUMBER;
  RATEUNIT     NUMBER;
  RATETPL      NUMBER;
  PREMI        NUMBER;
  PREUNIT      NUMBER;
  PREPA        NUMBER;
  PRETPL       NUMBER;
  HARGAOTRBARU NUMBER;
BEGIN

  ---DBMS_OUTPUT.PUT_LINE('NO KONTRAK| RATE UNIT |PREMI UNIT |RATE PA| PREMI PA|RATE TPL|PREMI TPL|TOTAL PREMI|JENIS ASURANSI|INSR ID| TENOR');
  FOR X IN (SELECT CA.APPL_CONTRACT_NO,
                   CA.APPL_BR_ID,
                   CA.APPL_OBJ_PRICE,
                   CA.APPL_OBJT_CODE,
                   B.TEMP_BR_ID,
                   CA.APPL_FIN_TYPE,
                   B.OTR,
                   CAD.APPL_INSC_TOP
              FROM IT_OPR1_AOL.TEMP_PREMI_RENEWAL_MOTOR B,
                   AD1SYS.CRED_APPL                     CA,
                   AD1SYS.PARA_BRAN_INFO                A,
                   CRED_APPL_DETAIL                     CAD
             WHERE B.TEMP_PROSES = '0'
               AND B.TEMP_BR_ID = CA.APPL_BR_ID
               AND B.TEMP_CONT_NO = CA.APPL_CONTRACT_NO
               AND A.BRAN_BR_ID = CA.APPL_BR_ID
               AND CA.APPL_BR_ID = CAD.APPL_BR_ID
               AND CA.APPL_NO = CAD.APPL_NO
               AND A.BRAN_PARENT_ID = '0003'
               --AND A.BRAN_BR_ID IN ('0261', '', '', '', '')
               --and ca.appl_contract_no in ('026118221211')
            ) LOOP
  
    SZMOTOR    := '';
    SZERROR    := '';
    SZTYPEINSR := '';
  
    BEGIN
      SELECT PO.OBJT_GROUP_CODE
        INTO SZOBJT
        FROM PARA_OBJECT PO
       WHERE PO.OBJT_CODE = X.APPL_OBJT_CODE
         AND ROWNUM = 1;
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ERROR GET OBJECT GROUP' ||
                             X.APPL_CONTRACT_NO);
        CONTINUE;
    END;
  
    SZBRID := AD1SYS.GET_BRIDREGOINBY_PK_NEW(X.APPL_CONTRACT_NO, 'C');
  
    IT_OPR1_AOL.PROC_VALIDATE_RENINS(SZBRID,
                                     X.APPL_CONTRACT_NO,
                                     SZOBJT,
                                     PERSENOTR,
                                     USIA,
                                     SZERROR);
    --Script awal
    /*IT_OPR1_AOL.PROC_VALIDATE_RENINS(SZBRID,
    X.APPL_CONTRACT_NO,
    SZOBJT,
    PERSENOTR,
    USIA,
    SZERROR);*/
  
    IF NVL(SZERROR, ' ') <> ' ' THEN
      ---DBMS_OUTPUT.PUT_LINE(SZERROR || ' ' || X.APPL_CONTRACT_NO);
      CONTINUE;
    END IF;
  
    IF NVL(SZOBJT, ' ') = '001' THEN
      SZTYPEINSR := '1';
    ELSIF NVL(SZOBJT, ' ') = '002' THEN
      IF NVL(USIA, 0) <= 7 THEN
        SZMOTOR    := '2';
        SZTYPEINSR := '1';
      ELSIF NVL(USIA, 0) > 7 AND USIA <= 15 THEN
        SZMOTOR    := '0';
        SZTYPEINSR := '1';
      END IF;
    END IF;
  
    IF NVL(SZTYPEINSR, ' ') = '1' THEN
    
      AD1SYS.PROC_VAL_RATEREN_CS(SZBRID,
                                 X.APPL_CONTRACT_NO,
                                 SZTYPEINSR,
                                 '12',
                                 
                                 X.APPL_OBJ_PRICE,
                                 SZOBJT,
                                 PERSENOTR,
                                 USIA,
                                 TO_CHAR(SYSDATE),
                                 LEFT(SZINSRID, 2),
                                 X.APPL_FIN_TYPE,
                                 RATEPA,
                                 RATEUNIT,
                                 RATETPL,
                                 PREMI,
                                 PREUNIT,
                                 PREPA,
                                 PRETPL,
                                 HARGAOTRBARU,
                                 SZERROR);
    END IF;
  
    IF NVL(SZERROR, ' ') <> ' ' THEN
      ---DBMS_OUTPUT.PUT_LINE(X.APPL_CONTRACT_NO || ' ' || SZERROR);
      CONTINUE;
    ELSE
      UPDATE IT_OPR1_AOL.TEMP_PREMI_RENEWAL_MOTOR A ---GANTI NAMA TABEL
         SET A.TEMP_RATE_UNIT   = RATEUNIT,
             A.TEMP_PREMI_UNIT  = PREUNIT,
             A.TEMP_RATE_PA     = RATEPA,
             A.TEMP_PREMI_PA    = PREPA,
             A.TEMP_RATE_TPL    = RATETPL,
             A.TEMP_PREMI_TPL   = PRETPL,
             A.TEMP_TENOR       = SZTENOR,
             A.TEMP_JENIS_INSR  = SZTYPEINSR,
             A.OTR              = X.APPL_OBJ_PRICE,
             A.TEMP_FINT_TYPE   = X.APPL_FIN_TYPE,
             A.TEMP_PROSES      = '1',
             A.TEMP_OTR_BARU    = HARGAOTRBARU,
             A.TEMP_TOTAL_PREMI = PREMI,
             A.TEMP_INSR_ID     = SZINSRID,
             A.TEMP_INSC_TOP    = X.APPL_INSC_TOP
       WHERE A.TEMP_CONT_NO = X.APPL_CONTRACT_NO
         AND A.TEMP_BR_ID = X.TEMP_BR_ID
         AND A.TEMP_PROSES = '0';
      /*DBMS_OUTPUT.PUT_LINE(X.APPL_CONTRACT_NO || '|' || RATEUNIT || '|' ||
      PREUNIT || '|' || RATEPA || '|' || PREPA || '|' ||
      RATETPL || '|' || PRETPL || '|' || PREMI || '|' ||
      SZTYPEINSR || '|' || SZINSRID || '|' || SZTENOR);*/
    END IF;
  
    IF NVL(SZMOTOR, ' ') = '2' THEN
      SZTYPEINSR := '2';
      AD1SYS.PROC_VAL_RATEREN_CS(SZBRID,
                                 X.APPL_CONTRACT_NO,
                                 SZTYPEINSR,
                                 '12',
                                 
                                 X.APPL_OBJ_PRICE,
                                 SZOBJT,
                                 PERSENOTR,
                                 USIA,
                                 TO_CHAR(SYSDATE),
                                 LEFT(SZINSRID, 2),
                                 X.APPL_FIN_TYPE,
                                 RATEPA,
                                 RATEUNIT,
                                 RATETPL,
                                 PREMI,
                                 PREUNIT,
                                 PREPA,
                                 PRETPL,
                                 HARGAOTRBARU,
                                 SZERROR);
    
      IF NVL(SZERROR, ' ') = ' ' THEN
        INSERT INTO IT_OPR1_AOL.TEMP_PREMI_RENEWAL_MOTOR ---GANTI NAMA TABEL
          (TEMP_BR_ID,
           TEMP_CONT_NO,
           TEMP_RATE_UNIT,
           TEMP_PREMI_UNIT,
           TEMP_RATE_PA,
           TEMP_PREMI_PA,
           TEMP_PREMI_TPL,
           TEMP_RATE_TPL,
           TEMP_TENOR,
           TEMP_JENIS_INSR,
           OTR,
           TEMP_GENERATE,
           TEMP_OTR_BARU,
           TEMP_FINT_TYPE,
           TEMP_TOTAL_PREMI,
           TEMP_INSR_ID,
           TEMP_PROSES,
           TEMP_INSC_TOP)
        VALUES
          (X.TEMP_BR_ID,
           X.APPL_CONTRACT_NO,
           RATEUNIT,
           PREUNIT,
           RATEPA,
           PREPA,
           PRETPL,
           RATETPL,
           SZTENOR,
           SZTYPEINSR,
           X.APPL_OBJ_PRICE,
           SYSDATE,
           HARGAOTRBARU,
           X.APPL_FIN_TYPE,
           PREMI,
           SZINSRID,
           '1',
           X.APPL_INSC_TOP);
        /* DBMS_OUTPUT.PUT_LINE(X.APPL_CONTRACT_NO || '|' || RATEUNIT || '|' ||
        PREUNIT || '|' || RATEPA || '|' || PREPA || '|' ||
        RATETPL || '|' || PRETPL || '|' || PREMI || '|' ||
        SZTYPEINSR || '|' || SZINSRID || '|' ||
        SZTENOR);*/
      END IF;
    END IF;
  
  END LOOP;
      COMMIT;
END;
/
SELECT COUNT(1)
  FROM IT_OPR1_AOL.TEMP_PREMI_RENEWAL_MOTOR MCY, AD1SYS.PARA_BRAN_INFO A
 WHERE MCY.TEMP_PROSES = '1'
 AND MCY.TEMP_BR_ID = A.BRAN_BR_ID
 AND A.BRAN_PARENT_ID = '0003';
