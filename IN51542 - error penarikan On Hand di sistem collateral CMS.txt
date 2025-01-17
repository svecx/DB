-- BATCHING AOL
INSERT INTO IT_OPR1_AOL.EXEC_LOGS_AOL
    VALUES
  ('IN51542', -- TICKET
   'SK - 51211457', -- NIK
   'AD1CMS', -- MODUL
   'cola_header', -- NAMA TABEL
   '0', -- ROW INSERT
   '2', -- ROW UPDATE
   '0', -- ROW DELETE
   TRUNC(SYSDATE),
   '1', -- BATCH
   'ARU',--EXECUTOR
   'error penarikan On Hand di sistem collateral CMS'--KETERANGAN
   );
   
SELECT ROWID, CH.* FROM ad1sys.cola_header ch where ch.cola_cont_no = '060321113312'; -- OH / RMT   / 06AB- 

SELECT ROWID, CH.* FROM ad1sys.cola_header ch where ch.cola_cont_no = '060320119576'; -- OH / RMT   / 06AB- 
