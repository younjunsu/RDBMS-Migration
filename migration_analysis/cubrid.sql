/*
    데이터베이스 버전 확인
*/
select version();

/*
    데이터베이스 문자셋 조회
*/
select
    b.charset_name
from
    db_root a,
    db_collation b
where
    a.charset = b.coll_id
;


/*
*/
-- dba 유저로 작업 해주어야 합니다.
select
    owner,
    object_name,
    object_type
from     
    (   select
            CAST(owner.name AS VARCHAR(255)) owner,
            class_name object_name,
            case class_type 
                when 0 then 'TABLE'
                when 1 then 'VIEW'
                else 'UNKNOW'
            end object_type
        from
            _db_class
        where
            is_system_class = 0 and
            class_name not in (select partition_class_name from db_partition union all select class_name from db_partition)
    union all
        select
            CAST(b.owner.name AS VARCHAR(255)) owner,
            b.class_name object_name,
            'PARTITION '||a.partition_type||' TABLE' object_type
        from
           db_partition a, _db_class b
        where
            a.class_name = b.class_name
            -- 11.2 이상 버전
            -- and a.owner_name= CAST(b.owner.name AS VARCHAR(255))
        group by 
            b.owner, b.class_name
    union all
        select 
            CAST(b.owner.name AS VARCHAR(255)) owner,
            b.class_name object_name,
            'PARTITION '||a.partition_type||' TABLE' object_type
        from
            db_partition a, _db_class b
        where
            a.partition_class_name = b.class_name
            -- 11.2 이상 버전
            -- and a.owner_name= CAST(b.owner.name AS VARCHAR(255))        
        group by
            b.owner, b.class_name
    union all
        select
            -- 11.1 이하 버전
            (select owner_name from db_class where is_system_class = 'NO' and db_idx.class_name = class_name) owner,
            -- 11.2 이상 버전
            -- db_idx.owner_name owner,
            db_idx.index_name object_name,
            case
                when db_idx.is_unique = 'YES' and db_idx.is_primary_key = 'NO' then 'INDEX (UNIQUE)'
                -- 9 이상 버전 (8버전 비활성화)
                --when db_idx.have_function = 'YES' then 'INDEX (FUNCTION)'
                when db_idx.is_primary_key = 'YES' then 'INDEX (PRIMARY KEY)'
                when db_idx.is_foreign_key = 'YES' then 'INDEX (FOREIGN KEY)'        
                else 'INDEX (NORMAL)'
            end object_type
        from
            db_index db_idx
        where
            db_idx.class_name in (select class_name from db_class where is_system_class='NO')
    union all
        select 
            CAST(owner.name AS VARCHAR(255)) owner,
            name object_name,
            'SERIAL' object_type
        from
            db_serial
    union all
        select
            CAST(owner.name AS VARCHAR(255)) owner,
            sp_name object_name,
            'Java Stored Procedure'||sp_type object_type
        from
            _db_stored_procedure
    union all
        select
            CAST(owner.name AS VARCHAR(255)) owner,
            name object_name,
            'TRIGGER' object_type
        from
            db_trigger
    
        /* 
            CUBRID 11.2버전 부터 SYNONYM 개념이 생겨, CUBRID 11.2 사용 시에만 활성 
        */
    -- union all
        --     synonym_owner_name,
        --     synonym_name,
        --     'SYNONYM'
        -- from
        --     db_synonym
    ) object_result;



/*
    데이터 타입 확인
*/
select 
    cls.owner_name,
    cls.class_name,
    att.attr_name,
    att.data_type,
    att.prec,
    att.scale,
    att.default_value,
    att.is_nullable
from 
    db_class cls inner join 
    /* CUBRID 11.1 이하 */
    db_attribute att on cls.class_name = att.class_name
    /* CUBRID 11.2 이상 */
    --db_attribute att on cls.class_name = att.class_name and cls.owner_name = att.owner_name
where 
    cls.is_system_class='NO' and cls.class_type='CLASS';
