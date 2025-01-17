update ad1sys.para_domain_dtl a
   set a.low_value = '01-JUL-2099'
 where a.domain_id = 'SCLO5';
 
 select * from ad1sys.para_domain_dtl a
 where a.domain_id = 'SCLO5';

