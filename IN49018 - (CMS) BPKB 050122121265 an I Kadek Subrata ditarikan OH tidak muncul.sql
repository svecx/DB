-- BATCHING AOL
INSERT INTO IT_OPR1_AOL.EXEC_LOGS_AOL
    VALUES
  ('IN49018', -- TICKET
   'SK - 51211457', -- NIK
   'AD1CMS', -- MODUL
   'cola_header', -- NAMA TABEL
   '0', -- ROW INSERT
   '1', -- ROW UPDATE
   '0', -- ROW DELETE
   TRUNC(SYSDATE),
   '4', -- BATCH
   'ARU',--EXECUTOR
   '(CMS) BPKB 050122121265 an I Kadek Subrata ditarikan OH tidak muncul'--KETERANGAN
   );
   
SELECT ROWID, CH.* FROM ad1sys.cola_header ch where ch.cola_cont_no = '050122121269'; -- RO -- 0501  
