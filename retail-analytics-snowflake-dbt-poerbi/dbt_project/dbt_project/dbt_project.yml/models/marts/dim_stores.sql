-- Dimension: stores
select
    store_code, store_name, city, state, region, store_type, open_date
from {{ ref('stg_stores') }}