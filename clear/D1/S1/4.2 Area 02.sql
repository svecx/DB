DECLARE
  SZAREA VARCHAR2(4) := '0002'; -- mohon running paralel untuk semua area !!
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
