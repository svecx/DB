--CEK JURNAL AIT CKPN ALL
select * from ad1sys.acct_integration_tran ait
 where ait.ait_sysdate>='31JUL2024' --ganti ketanggal hari ini atau sebelumnya
 and ait.ait_code='0023020';
 
--CEK BY AREA
select A.ACTION, A.SQL_ID,  A.* from v$session A where A.status = 'ACTIVE' AND A.OSUSER = '51206614';
SELECT * FROM AD1SYS.TEMP_JOB_CKPN job
WHERE job.periode = '31JUL2024'; --ganti tanggal akhir bulan

SELECT * FROM ad1sys.ACCT_PROVISION_RISK_syar A WHERE A.PERIODE = '31JUL2024';

SELECT * FROM IT_OPR1_AOL.TMP_ACI_020523;

SELECT * FROM AD1SYS.ACCT_CKPN_IMBT ACI WHERE ACI.PERIODE >= '31JUL2024';
