DECLARE
  MEMO        VARCHAR2(20) := ''; -- PILIH SALAH SATU
  SURAT_JALAN VARCHAR2(20) := '080324SJBB00292'; -- PILIH SALAH SATU
  TIKET       VARCHAR2(20) := '42636'; -- NO TIKET
  PIC         VARCHAR2(3)  := 'SK'; -- DIISI

  --- 
  STATUS VARCHAR2(10);
  LOKASI VARCHAR2(20);
  BRAN   VARCHAR2(20);
  KET    VARCHAR2(20);
  CUP    NUMBER;
  CDEL   NUMBER;

BEGIN
  -- CEK UPDATE
  CUP  := 0;
  CDEL := 0;

  IF TRIM(SURAT_JALAN) IS NOT NULL THEN
    FOR H IN (SELECT CTH.COLA_MEMO_NO AS MEMO
                FROM AD1CMS.COLA_TRANSACT_HEADER CTH
               WHERE CTH.COLA_SURAT_JALAN = SURAT_JALAN) LOOP
      -- CEK MEMO C / D
      IF H.MEMO LIKE '%C%' THEN
      
        -- UPDATE MEMO JADI CANCEL
        UPDATE AD1CMS.COLA_TRANSACT_HEADER CTH
           SET CTH.COLA_CONFIRMED = '2', CTH.COLA_LOG_ID = H.MEMO
        --SELECT AD1CMS.COLA_TRANSACT_HEADER CTH
         WHERE CTH.COLA_MEMO_NO = H.MEMO;
      
        CUP := CUP + 1;
      
        -- UPDATE JUMLAH LACI
        FOR I IN (SELECT CTD.COLA_DESC_20 AS LACI,
                         COUNT(CTD.COLA_DESC_20) AS TOTAL,
                         CTD.COLA_BR_ID AS BR_ID
                    FROM AD1CMS.COLA_TRANSACT_DETAIL CTD
                   WHERE CTD.COLA_MEMO_NO = H.MEMO
                   GROUP BY CTD.COLA_DESC_20, CTD.COLA_BR_ID) LOOP
        
          BEGIN
          
            UPDATE AD1CMS.COLA_MASTER_LACI CML
               SET CML.COLA_JML_CURRENT = CML.COLA_JML_CURRENT + I.TOTAL
            --SELECT * FROM AD1CMS.COLA_MASTER_LACI A
             WHERE CML.COLA_LACI_ID = I.LACI
               AND CML.COLA_TEMPAT = I.BR_ID;
          
            CUP := CUP + 1;
          
          END;
        END LOOP;
      
        FOR J IN (SELECT DISTINCT CTD.COLA_ID      AS COLA_ID,
                                  CTD.COLA_DESC_20 AS LACI
                    FROM AD1CMS.COLA_TRANSACT_DETAIL CTD
                   WHERE CTD.COLA_MEMO_NO = H.MEMO) LOOP
        
          SELECT CMH.COLA_STATUS, CMH.COLA_LOCATION, CMH.COLA_BRAN_LOC
            INTO STATUS, LOKASI, BRAN
            FROM AD1CMS.COLA_MASTER_HISTORY CMH
           WHERE CMH.COLA_ID = J.COLA_ID
             AND CMH.COLA_STATUS NOT IN ('RLT')
             AND CMH.COLA_SEQNO =
                 ((SELECT MAX(CMH.COLA_SEQNO)
                     FROM AD1CMS.COLA_MASTER_HISTORY CMH
                    WHERE CMH.COLA_ID = J.COLA_ID) - 1);
        
          -- DELETE COLA MASTER HISTORY
          DELETE AD1CMS.COLA_MASTER_HISTORY CMH
          --SELECT AD1CMS.COLA_MASTER_HISTORY CMH
           WHERE CMH.COLA_MEMO_NO = H.MEMO
             AND CMH.COLA_ID = J.COLA_ID;
        
          -- UPDATE COLA_MASTER_DATA
          UPDATE AD1CMS.COLA_MASTER_DATA CMD
             SET CMD.COLA_STATUS   = TRIM(STATUS),
                 CMD.COLA_LOCATION = TRIM(LOKASI),
                 CMD.COLA_BRAN_LOC = TRIM(BRAN),
                 CMD.COLA_DESC_35  = J.LACI
          --SELECT * FROM AD1CMS.COLA_MASTER_DATA CMD
           WHERE CMD.COLA_ID = J.COLA_ID;
        
          CUP  := CUP + 1;
          CDEL := CDEL + 1;
        
        END LOOP;
      
        -- CEK MEMO C / D
      ELSIF H.MEMO LIKE '%D%' THEN
      
        UPDATE AD1CMS.COLA_TRANSACT_HEADER CTH
           SET CTH.COLA_CONFIRMED = '2'
        --SELECT * FROM AD1CMS.COLA_TRANSACT_HEADER CTH
         WHERE CTH.COLA_MEMO_NO = H.MEMO;
      
        CUP := CUP + 1;
      
      END IF;
    END LOOP;
  
  ELSIF TRIM(MEMO) IS NOT NULL THEN
    -- CEK MEMO C / D
    IF TRIM(MEMO) LIKE '%C%' THEN
    
      -- UPDATE MEMO JADI CANCEL
      UPDATE AD1CMS.COLA_TRANSACT_HEADER CTH
         SET CTH.COLA_CONFIRMED = '2', CTH.COLA_LOG_ID = TRIM(TIKET)
      --SELECT AD1CMS.COLA_TRANSACT_HEADER CTH
       WHERE CTH.COLA_MEMO_NO = TRIM(MEMO);
    
      CUP := CUP + 1;
    
      -- UPDATE JUMLAH LACI
      FOR I IN (SELECT CTD.COLA_DESC_20 AS LACI,
                       COUNT(CTD.COLA_DESC_20) AS TOTAL,
                       CTD.COLA_BR_ID AS BR_ID
                  FROM AD1CMS.COLA_TRANSACT_DETAIL CTD
                 WHERE CTD.COLA_MEMO_NO = TRIM(MEMO)
                 GROUP BY CTD.COLA_DESC_20, CTD.COLA_BR_ID) LOOP
      
        UPDATE AD1CMS.COLA_MASTER_LACI CML
           SET CML.COLA_JML_CURRENT = CML.COLA_JML_CURRENT + I.TOTAL
        --SELECT * FROM AD1CMS.COLA_MASTER_LACI A
         WHERE CML.COLA_LACI_ID = I.LACI
           AND CML.COLA_TEMPAT = I.BR_ID;
      
        CUP := CUP + 1;
      
      END LOOP;
    
      FOR J IN (SELECT DISTINCT CTD.COLA_ID      AS COLA_ID,
                                CTD.COLA_DESC_20 AS LACI
                  FROM AD1CMS.COLA_TRANSACT_DETAIL CTD
                 WHERE CTD.COLA_MEMO_NO = TRIM(MEMO)) LOOP
      
        SELECT CMH.COLA_STATUS, CMH.COLA_LOCATION, CMH.COLA_BRAN_LOC
          INTO STATUS, LOKASI, BRAN
          FROM AD1CMS.COLA_MASTER_HISTORY CMH
         WHERE CMH.COLA_ID = J.COLA_ID
           AND CMH.COLA_SEQNO =
               ((SELECT MAX(CMH.COLA_SEQNO)
                   FROM AD1CMS.COLA_MASTER_HISTORY CMH
                  WHERE CMH.COLA_ID = J.COLA_ID) - 1);
      
        -- DELETE COLA MASTER HISTORY
        DELETE AD1CMS.COLA_MASTER_HISTORY CMH
        --SELECT AD1CMS.COLA_MASTER_HISTORY CMH
         WHERE CMH.COLA_MEMO_NO = TRIM(MEMO)
           AND CMH.COLA_ID = J.COLA_ID;
      
        -- UPDATE COLA_MASTER_DATA
        UPDATE AD1CMS.COLA_MASTER_DATA CMD
           SET CMD.COLA_STATUS   = TRIM(STATUS),
               CMD.COLA_LOCATION = TRIM(LOKASI),
               CMD.COLA_BRAN_LOC = TRIM(BRAN),
               CMD.COLA_DESC_35  = J.LACI
        --SELECT * FROM AD1CMS.COLA_MASTER_DATA CMD
         WHERE CMD.COLA_ID = J.COLA_ID;
      
        CUP  := CUP + 1;
        CDEL := CDEL + 1;
      
      END LOOP;
    
      -- CEK MEMO C / D
    ELSIF TRIM(MEMO) LIKE '%D%' THEN
    
      UPDATE AD1CMS.COLA_TRANSACT_HEADER CTH
         SET CTH.COLA_CONFIRMED = '2'
      --SELECT * FROM AD1CMS.COLA_TRANSACT_HEADER CTH
       WHERE CTH.COLA_MEMO_NO = TRIM(MEMO);
    
    END IF;
  END IF;

  -- BATCHING
  IF CUP > 0 THEN
    -- BATCHING
    BEGIN
      --- Batching
      IT_OPR.SP_INJECT_BATCH(CUP, -- update
                             NULL, -- insert
                             NULL, -- delete
                             TRIM(TIKET), -- tiket
                             'CANCEL MEMO', -- keterangan update
                             'cancel_memo.sql', -- nama script
                             NULL,
                             TRIM(PIC) -- WAJIB GANTI
                             );
    END;
  END IF;
END;

SELECT * FROM ad1cms.cola_transact_header cth where cth.COLA_SURAT_JALAN in ('080324SJBB00292');
