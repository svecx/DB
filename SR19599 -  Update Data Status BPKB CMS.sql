INSERT INTO IT_OPR1_AOL.EXEC_LOGS_AOL
    VALUES
  ('SR19599 ', -- TICKET
   'SK - 51211457', -- NIK
   'AD1CMS', -- MODUL
   'TEMP_COLLA_AUTOREGIS', -- NAMA TABEL
   '1', -- ROW INSERT
   '0', -- ROW UPDATE
   '0', -- ROW DELETE
   TRUNC(SYSDATE),
   '3', -- BATCH
   'ARU',--EXECUTOR
   'Update Data Status BPKB CMS'--KETERANGAN
   );

SELECT  rowid, tca.* FROM AD1CMS.TEMP_COLLA_AUTOREGIS TCA WHERE TCA.APPL_CONTRACT_NO IN ('012824112608');

insert into AD1CMS.TEMP_COLLA_AUTOREGIS (APPL_DATE_ADD, APPL_BRID, APPLNO, APPL_CONTRACT_NO, APPL_CLID, APPL_TRANSID, APPL_PPD_NO, APPL_PPD_DATE, STATUS, SZLOGID, APPL_CUSTNO, APPL_CONT_STATUS, APPL_CONT_OLD, SZTRANSAKSI, APPL_SYSDATE, APPL_DESC_1, APPL_DESC_2, APPL_DESC_3, APPL_DESC_4, APPL_DESC_5, APPL_DESC_6, APPL_DESC_7, APPL_DESC_8, APPL_DESC_9, APPL_DESC_10, APPL_DESC_11, APPL_DESC_12, APPL_DESC_13, APPL_DESC_14, APPL_DESC_16, APPL_DESC_15, APPL_DESC_17, APPL_DESC_18, APPL_DESC_19, APPL_DESC_20, APPL_DESC_21, APPL_DESC_22, APPL_DESC_23, APPL_DESC_24, APPL_DESC_25, APPL_DESC_26, APPL_DESC_27, APPL_DESC_28, APPL_DESC_29, APPL_DESC_30, APPL_DESC_31, APPL_DESC_32, APPL_DESC_33, APPL_DESC_34, APPL_DESC_35, COLA_AD1FAST)
values (to_date('05-04-2024', 'dd-mm-yyyy'), '0128', '0000240128016708', '012824112608', null, '00', '010024061621', to_date('07-03-2024', 'dd-mm-yyyy'), 0, '[130E8CAF-4750-0880-E063-9B015B0A2691]', '012801523524', '00', null, '9', to_date('07-03-2024 15:13:44', 'dd-mm-yyyy hh24:mi:ss'), 'MH1JMD117RK480315', 'JMD1E1480527', null, null, null, '145            ', '021', '2024', null, '125', '0HU', 'BLACK', 'EKA SULISTIWATI', 'JL KH HASYIM ASHARI GG JAMBU', '05', '001', 'EKA SULISTIWATI', '007156', '012824INSR016613', null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null, null);
