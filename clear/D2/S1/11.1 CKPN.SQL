--BISA PARALEL DENGAN 5.2 CKPN ECL --> [11.2]
DECLARE
  dtPeriode   DATE := '31JUL2024'; --TANGGAL CLOSING 1 (EOM)
  SZJOB       VARCHAR2(50) := 'CALC IMBT';
  id_job      number;
  plsql_block varchar2(5000);
  dtDue       DATE := TRUNC(dtPeriode);
  szarea      varchar2(4);

  lngsequence number;
  batch_seq   varchar2(13);

  counter number := 0;

begin

  --GENERATE SEQUENCE BATCH ID
  csequencemgr_increasesequence('SEQJOBCKPN',
                                to_char(dtPeriode, 'rrrr'),
                                '0000');
  csequencemgr_getsequencenew('SEQJOBCKPN',
                              to_char(dtPeriode, 'rrrr'),
                              '0000',
                              lngsequence);

  batch_seq := '0000' || to_char(dtPeriode, 'RR') || 'J' ||
               lpad(lngsequence, 6, '0');

  for rec in (select distinct a.bran_parent_id as bran_parent_id
                from ad1sys.para_bran_info a
               where a.bran_parent_id <> '0000'
                 and exists (select 1
                        from ad1sys.acct_pencadangan_ar ar
                       where ar.acct_br_id = a.bran_br_id
                         and ar.acct_periode = dtPeriode
                         and 1 =
                             AD1SYS.FUNC_CEK_IMBT_CLOSING(ar.acct_br_id,
                                                          AR.ACCT_CONT_NO)
                         and rownum = 1)
                 and not exists
               (select 1
                        from ad1sys.temp_job_ckpn job
                       where job.periode = dtPeriode
                         and job.job_name = szjob
                         and job.area = a.bran_parent_id
                         and job.status in ('DONE', 'RUN'))) loop
  
    counter := counter + 1;
    szarea  := trim(rec.bran_parent_id);
  
    plsql_block := 'begin ad1sys.PROC_CALC_CKPN_IMBT(''' || (dtDue) ||
                   ''',''' || szarea || ''');

ad1sys.PROC_UPDATE_FLAG_JOB_CKPN(''' || dtDue || ''',''' ||
                   batch_seq || ''',''' || szjob || ''',''' || szarea ||
                   ''',''' || '0' || ''');
exception
when others then
rollback;
ad1sys.PROC_UPDATE_FLAG_JOB_CKPN(''' || dtDue || ''',''' ||
                   batch_seq || ''',''' || szjob || ''',''' || szarea ||
                   ''',''' || '1' || ''');
end;';
  
    dbms_job.submit(id_job, plsql_block);
  
    insert into ad1sys.temp_job_ckpn
      (periode, JOB_NAME, start_time, job_id, area, status, SEQ_ID)
    values
      (trunc(dtPeriode), szjob, sysdate, id_job, szarea, 'RUN', batch_seq);
    commit;
  
  end loop;

  --ROLLBACK SEQUENCE
  if counter = 0 then
  
    select count(1)
      into counter
      from ad1sys.temp_job_ckpn a
     where a.periode = trunc(dtPeriode)
       and a.job_name = szjob;
  
    if counter = 0 then
      rollback;
      raise_application_error('-20000',
                              'DATA CABANG PENCADANGAN AR IMBT KOSONG / PROSES CKPN SUDAH DILAKUKAN');
    end if;
  
  end if;

  ad1sys.PROC_CHECK_JOB_CKPN(dtDue, szjob, batch_seq);

exception
  when others then
    raise_application_error('-20000',
                            'ERR PROC_RUN_JOB_CKPN_IMBT || ' || SQLERRM);
end;
