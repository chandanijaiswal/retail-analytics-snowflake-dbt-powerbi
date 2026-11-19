-- Staging: clean the raw customer data
with cleaned as (
    select
        upper(trim(customer_id)) as customer_id,
        initcap(trim(regexp_replace(customer_name, ' +', ' '))) as customer_name,

        case upper(left(trim(gender), 1))
            when 'M' then 'Male'
            when 'F' then 'Female'
            else 'Unknown'
        end as gender,

        case lower(trim(city))
            when 'bombay'    then 'Mumbai'
            when 'poona'     then 'Pune'
            when 'amdavad'   then 'Ahmedabad'
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
            when 'gj' then 'Gujarat'
            when 'dl' then 'Delhi'
            when 'hr' then 'Haryana'
            when 'up' then 'Uttar Pradesh'
            when 'rj' then 'Rajasthan'
            when 'ka' then 'Karnataka'
            when 'tn' then 'Tamil Nadu'
            when 'ts' then 'Telangana'
            when 'kl' then 'Kerala'
            when 'wb' then 'West Bengal'
            when 'od' then 'Odisha'
            else initcap(trim(state))
        end as state,

        right(regexp_replace(phone, '[^0-9]', ''), 10) as phone,

        case when lower(trim(email)) like '%_@_%._%'
             then lower(trim(email)) end as email,

        coalesce(
            try_to_date(trim(signup_date), 'YYYY-MM-DD'),
            try_to_date(trim(signup_date), 'DD/MM/YYYY'),
            try_to_date(trim(signup_date), 'DD-MON-YYYY')) as signup_date,

        case
            when lower(trim(segment)) in ('consumer', 'individual')
                then 'Consumer'
            when lower(trim(segment)) in ('corporate', 'corp', 'corp.')
                then 'Corporate'
            when lower(trim(segment)) in ('small business', 'smb', 'small biz')
                then 'Small Business'
        end as segment
    from {{ source('raw', 'raw_customers') }}
)

select *
from cleaned
qualify row_number() over (partition by customer_id order by signup_date) = 1 