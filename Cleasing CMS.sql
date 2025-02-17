--- Get Data (Untuk ambil PK)
-- Ad1cms
--MERK / BRAN, TYPE, MODEL NULL 
SELECT TCA.APPL_DESC_6,
       TCA.APPL_DESC_7,
       TCA.APPL_DESC_11,
       TCA.APPL_DESC_15,
       TCA.APPLNO,
       TCA.APPL_CONTRACT_NO,
       TCA.APPL_BRID
  FROM AD1CMS.TEMP_COLLA_AUTOREGIS TCA
 WHERE (TCA.APPL_DESC_6 IS NULL OR TCA.APPL_DESC_7 IS NULL OR
       TCA.APPL_DESC_11 IS NULL OR TCA.APPL_DESC_15 IS NULL)
   AND TCA.APPL_DATE_ADD >= '01JAN23'
   AND TCA.SZTRANSAKSI <> '8';

--- Get Data dan PK (Untuk di-inject)
-- Ad1sys
--TARIK DATA BRAND, TYPE, MODEL BY DB ACCTION
SELECT TRIM((SELECT RPAD((SELECT OBBR_CODE
                          FROM AD1SYS.PARA_OBJECT_BRAND B,
                               AD1SYS.PARA_OBJECT_MODEL M
                         WHERE M.OBMO_OBBR_CODE = B.OBBR_CODE
                           AND B.OBBR_CODE_ACCT =
                               SUBSTR(AAOCO.AC_BRAND_OBJECT, 1, 3)
                           AND M.OBMO_CODE =
                               SUBSTR(AAOCO.AC_OBJECT_MODEL, 1, 3)
                           AND B.OBBR_OBJT_CODE =
                               SUBSTR(AAOCO.AC_OBJECT_TYPE, 1, 3)
                           AND B.OBBR_DELETED = 0
                           AND M.OBMO_DELETED = 0),
                        15)
              FROM DUAL)) COLA_BRAND,
       TRIM(AAOCO.AC_OBJECT_TYPE) COLA_OBJ_TYPE,
       TRIM(AAOCO.AC_OBJECT_MODEL) COLA_OBJ_MODEL,
       CASE
         WHEN AAO.AC_OBJECT IN ('014', '015') THEN
          (SELECT PARA_OBJECT_AOL
             FROM PARAMS.T_PARA_OBJECT_CODE_AOL@TO_ACCTSBY
            WHERE PARA_OBJECT_GROUP_COLA = NVL(AAOCO.AC_GROUP_OBJECT, '004')
              AND PARA_OBJECT_ACCT = AAO.AC_OBJECT
              AND ACTIVE = 0)
         ELSE
          AAOCO.AC_OBJECT
       END OBJT_CODE,
       AA.AC_UNIT_C APPL_BRID,
       TRIM(AAO.AC_REFERENCE_NO) CONT_OLD,
       AAO.AC_APPL_CONTRACT_NO NOMOR_PK,
       AC.AC_CUST_ID APPL_CUSTNO,
       AAO.AC_APPL_OBJT_ID APPLNO,
       TRIM(AAOCO.AC_FRAME_NO) NO_RANGKA,
       TRIM(AAOCO.AC_ENGINE_NO) NO_MESIN,
       TRIM(AAOCO.AC_POLICE_NO) NO_POLISI
  FROM ACCTION.AC_APPLICATION@TO_ACCTSBY         AA,
       ACCTION.AC_APPL_OBJT@TO_ACCTSBY           AAO,
       ACCTION.AC_APPL_OBJT_COLL_OTO@TO_ACCTSBY  AAOCO,
       ACCTION.AC_APPL_OBJT_COLL_PROP@TO_ACCTSBY AAOCP,
       ACCTION.AC_CUSTOMER@TO_ACCTSBY            AC
 WHERE AAO.SK_APPL_OBJECT = AAOCO.FK_AC_APPL_OBJT(+)
   AND AAO.SK_APPL_OBJECT = AAOCP.FK_AC_APPL_OBJT(+)
   AND AA.SK_AC_APPLICATION = AAO.FK_AC_APPLICATION
   AND AC.AC_CUST_ID = AA.FK_AC_CUSTOMER
   AND AAO.AC_APPL_OBJT_ID IN ('0000240119045154');

--- Insert Pada Tabel Dibawah
-- Ad1cms
--SELECT * FROM IT_OPR.TEMP_BRAND_NULL_230223;

--- Update Data 
-- Ad1cms

DECLARE

  DESC_6  VARCHAR2(100);
  DESC_7  VARCHAR2(100);
  DESC_11 VARCHAR2(100);
  DESC_15 VARCHAR2(100);

BEGIN
  FOR I IN (SELECT * FROM IT_OPR.TEMP_BRAND_NULL_230223) LOOP
  
    SELECT A.APPL_DESC_6, A.APPL_DESC_7, A.APPL_DESC_11, A.APPL_DESC_15
      INTO DESC_6, DESC_7, DESC_11, DESC_15
      FROM AD1CMS.TEMP_COLLA_AUTOREGIS A
     WHERE A.APPL_CONTRACT_NO = I.NOMOR_KONTRAK;
  
    --TCA.APPL_DESC_6 BRAN/MERK
    IF DESC_6 IS NULL THEN
      UPDATE AD1CMS.TEMP_COLLA_AUTOREGIS TCA
         SET TCA.APPL_DESC_6 = I.COLA_BRAND
       WHERE TCA.APPL_CONTRACT_NO = I.NOMOR_PK;
      --TCA.APPL_DESC_7 TYPE
    ELSIF DESC_7 IS NULL THEN
      UPDATE AD1CMS.TEMP_COLLA_AUTOREGIS TCA
         SET TCA.APPL_DESC_7 = I.COLA_OBJ_TYPE
       WHERE TCA.APPL_CONTRACT_NO = I.NOMOR_PK;
      --TCA.APPL_DESC_11 MODEL
    ELSIF DESC_11 IS NULL THEN
      UPDATE AD1CMS.TEMP_COLLA_AUTOREGIS TCA
         SET TCA.APPL_DESC_11 = I.COLA_OBJ_MODEL
       WHERE TCA.APPL_CONTRACT_NO = I.NOMOR_PK;
      --TCA.APPL_DESC_15 OBJT CODE
    ELSIF DESC_15 IS NULL THEN
      UPDATE AD1CMS.TEMP_COLLA_AUTOREGIS TCA
         SET TCA.APPL_DESC_15 = I.COLA_OBJT_CODE
       WHERE TCA.APPL_CONTRACT_NO = I.NOMOR_PK;
    END IF;

    UPDATE IT_OPR.TEMP_BRAND_NULL_230223 A
       SET A.FLAG = '1'
     WHERE A.NOMOR_PK = I.NOMOR_PK;

  END LOOP;
END;

SELECT A.APPL_DESC_6, A.APPL_DESC_7, A.APPL_DESC_11, A.APPL_DESC_15, a.appl_contract_no FROM ad1cms.temp_colla_autoregis a, IT_OPR.TEMP_BRAND_NULL_230223 b
WHERE a.appl_contract_no = b.nomor_pk
