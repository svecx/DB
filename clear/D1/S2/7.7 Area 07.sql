DECLARE

  SZAREA VARCHAR2(4) := '0007'; -- SAMPLE AREA 1
  DDATE DATE := (CASE
                  WHEN TRUNC(SYSDATE) = LAST_DAY(TRUNC(SYSDATE)) THEN
                   TRUNC(SYSDATE)
                  ELSE
                   ADD_MONTHS(LAST_DAY(TRUNC(SYSDATE)), -1)
                END);

BEGIN

  FOR REC IN (SELECT BRAN_BR_ID
                FROM AD1SYS.PARA_BRAN_INFO PBI
               WHERE PBI.BRAN_PARENT_ID <> '0000'
                 AND PBI.BRAN_PARENT_ID = SZAREA
               ORDER BY BRAN_BR_ID DESC) LOOP
  
    BEGIN
      AD1SYS.PROC_LOGS_CLOSING(REC.BRAN_BR_ID,
                               'PROC_JOUR_REVS_EIR',
                               '1',
                               DDATE);
    END;
  
    BEGIN
      -- CALL THE PROCEDURE
      IFRS.PROC_JOUR_REVS_EIR(REC.BRAN_BR_ID, DDATE);
    END;
  
    BEGIN
      AD1SYS.PROC_LOGS_CLOSING(REC.BRAN_BR_ID,
                               'PROC_JOUR_REVS_EIR',
                               '2',
                               DDATE);
    END;
  
  END LOOP;
END;
