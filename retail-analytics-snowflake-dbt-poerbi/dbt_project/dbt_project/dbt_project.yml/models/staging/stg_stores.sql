-- Staging: clean the raw store data
select
    replace(upper(trim(store_code)), '-', '') as store_code,
    initcap(trim(regexp_replace(store_name, ' +', ' '))) as store_name,

    case lower(trim(city))
        when 'bombay'    then 'Mumbai'
        when 'poona'     then 'Pune'
        when 'new delhi' then 'Delhi'
        when 'gurgaon'   then 'Gurugram'
        when 'bangalore' then 'Bengaluru'
        when 'blr'       then 'Bengaluru'
        when 'madras'    then 'Chennai'
        when 'hyd'       then 'Hyderabad'
        when 'cochin'    then 'Kochi'
        when 'calcutta'  then 'Kolkata'
        else initcap(trim(city))
    end as city,

    case lower(trim(state))
        when 'mh' then 'Maharashtra'
        when 'dl' then 'Delhi'
        when 'hr' then 'Haryana'
        when 'rj' then 'Rajasthan'
        when 'ka' then 'Karnataka'
        when 'tn' then 'Tamil Nadu'
        when 'ts' then 'Telangana'
        when 'kl' then 'Kerala'
        when 'wb' then 'West Bengal'
        when 'od' then 'Odisha'
        else initcap(trim(state))
    end as state,

    case
        when lower(trim(region)) like 'all%' then 'All India'
        when upper(left(trim(region), 1)) = 'N' then 'North'
        when upper(left(trim(region), 1)) = 'S' then 'South'
        when upper(left(trim(region), 1)) = 'E' then 'East'
        when upper(left(trim(region), 1)) = 'W' then 'West'
    end as region,

    case
        when lower(store_type) like '%mall%' then 'Mall'
        when lower(trim(store_type)) like 'high%' then 'High Street'
        when lower(trim(store_type)) in ('online', 'e-commerce') then 'Online'
    end as store_type,

    coalesce(
        try_to_date(trim(open_date), 'YYYY-MM-DD'),
        try_to_date(trim(open_date), 'DD/MM/YYYY'),
        try_to_date(trim(open_date), 'DD-MON-YYYY')) as open_date
from {{ source('raw', 'raw_stores') }}