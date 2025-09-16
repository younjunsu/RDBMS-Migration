/*
    데이터베이스 유저별 테이블 용량 확인
*/
select
    owner, sum(bytes)/1024/1024 as sum_mb
from 
    dba_segments
where 
    (owner,segment_name) in 
    (select owner, table_name from dba_tables) 
group by owner 
order by sum_mb desc
;

/*
    데이터베이스 유저별 랍 용량 확인
*/
select
    owner, sum(bytes)/1024/1024 as sum_mb
    --owner, sum(bytes)/1024/1024 as sum_gb
from 
    dba_segments
where 
    (owner,segment_name) in 
    (select owner, segment_name from dba_lobs) 
group by owner 
order by sum_mb desc, onwer
--order by owner, sum_mb desc
;

/*
    사용 중인 JOB 정보 확인
*/
--Job Extract
set lines 10000
set pages 0
col CRE_JOB for a10000
alter session set nls_date_format='yyyy/mm/dd hh24:mi:ss';
select 
    'alter session set current_schema='||
    (select username from dba_users where USER_ID=SCHEMA_USER)||
    ';'||
    chr(10)||
    chr(13)||
    'DECLARE X NUMBER; BEGIN DBMS_JOB.SUBMIT (JOB => X, WHAT => '''||
    replace(WHAT,'''','''''')||
    ''', NEXT_DATE => '''||
    NEXT_DATE||
    ''', INTERVAL => '''||
    replace(INTERVAL,'''','''''')||
    ''', NO_PARSE => FALSE); 
    DBMS_JOB.BROKEN(X,'||
    case
         when BROKEN='Y' then 'TRUE'
         else 'FALSE' 
    end||
    '); END;'||chr(10)||chr(13)||'/' cre_job 
 from dba_jobs 
         where SCHEMA_USER not in (select user_id from dba_users where username in ('SYS','SYSCAT','SYSGIS','OUTLN','TIBERO','TIBERO1','WMSYS','PROSYNC'));