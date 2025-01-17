-- check user yang di blocking
select v.SID,
       v.SERIAL#,
       v.machine,
       v.BLOCKING_SESSION,
       v.USERNAME,
       v.STATUS,
       v.PROGRAM,
       v.SQL_ID,
       v.MODULE
  from v$session v
where v.FINAL_BLOCKING_SESSION_STATUS = 'VALID';

--- check user yang memblocking
Select lk.SID,
       se.SERIAL#,
       se.username,
       se.MACHINE,
       se.sql_id,
       se.PREV_SQL_ID,
       se.FINAL_BLOCKING_SESSION FinalBlock,
       se.status,+
       se.MODULE,
        se.LOGON_TIME,
       se.LAST_CALL_ET,
       se.CLIENT_INFO,
       
      -- se.SQL_HASH_VALUE,
       DECODE(lk.TYPE,
              'TX',
              'Transaction',
              'TM',
              'DML',
              'UL',
              'PL/SQL User Lock',
              lk.TYPE) lock_type,
       DECODE(lk.lmode,
              0,
              'None',
              1,
              'Null',
              2,
              'Row-S (SS)',
              3,
              'Row-X (SX)',
              4,
              'Share',
              5,
              'S/Row-X (SSX)',
              6,
              'Exclusive',
              TO_CHAR(lk.lmode)) mode_held,
       DECODE(lk.request,
              0,
              'None',
              1,
              'Null',
              2,
              'Row-S (SS)',
              3,
              'Row-X (SX)',
              4,
              'Share',
              5,
              'S/Row-X (SSX)',
              6,
              'Exclusive',
              TO_CHAR(lk.request)) mode_requested,
       TO_CHAR(lk.id1) lock_id1,
       TO_CHAR(lk.id2) lock_id2,
       decode(block, 0, 'No', 1, 'Yes', 2, 'Global') block,
       se.lockwait
  FROM v$lock lk, v$session se
WHERE (lk.type = 'TX')
   AND (lk.SID = se.SID)
   AND lk.BLOCK  = '1' order by 9 desc;



/* 
/*
alter system kill session '2264,45571';
alter system kill session '16506,11749';


-- cek hash plan 
select * from table(dbms_xplan.display_cursor('c4gc90hthfhwm'));
*/


/*
select sql_id,serial#,username,status,machine,module,client_info,logon_time
from v$session ss where ss.username='MODULHO' and ss.sid =  '11896';

select module,sql_fulltext from v$sqlarea where  sql_id = '943trd822dgbc';

select  username ,SID,SERIAL# ,'alter system kill session ''' || sid || ',' || serial# || '''' || ';' ,sql_id from v$session
where sql_id ='cukcf3dtk7brd';

select username, SID,SERIAL# ,machine,program, 'alter system kill session ''' || sid || ',' || serial# || '''' || ';' ,sql_id from v$session
where sql_id ='bh38uqk9mv6bs';
*/

/*
  select distinct v.BLOCKING_SESSION, count(1)
  from v$session v
where v.FINAL_BLOCKING_SESSION_STATUS = 'VALID'
group by v.BLOCKING_SESSION
having count (1) > 1;*/

/*select sql_id,serial#,username,status,machine,module,client_info,logon_time
from v$session ss where ss.username='MODULHO' and ss.sid =  '11896';*/
/*
alter system kill session '10712,55757';
*/
-- cek plan
-- select * from table(dbms_xplan.display_awr('aw5ruwxtjwa04')); 


