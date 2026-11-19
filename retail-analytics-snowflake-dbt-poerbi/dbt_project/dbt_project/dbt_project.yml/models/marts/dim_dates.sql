-- Dimension: one row per day of 2025 (generated, no source table)
with days as (
    select
        dateadd(day, row_number() over (order by seq4()) - 1, '2025-01-01'::date)
            as date_day
    from table(generator(rowcount => 365))
)

select
    date_day,
    year(date_day)                      as year,
    quarter(date_day)                   as quarter_num,
    'Q' || quarter(date_day)            as quarter_name,
    month(date_day)                     as month_num,
    to_char(date_day, 'MMMM')           as month_name,
    to_char(date_day, 'YYYY-MM')        as year_month,
    dayofweekiso(date_day)              as weekday_num,
    dayname(date_day)                   as weekday_name,
    dayofweekiso(date_day) in (6, 7)    as is_weekend
from days