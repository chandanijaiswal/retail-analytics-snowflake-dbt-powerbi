-- Dimension: customers + one "Unknown" row for orders whose customer is missing
select
    customer_id, customer_name, gender, city, state, phone, email, signup_date, segment
from {{ ref('stg_customers') }}

union all

select
    'UNKNOWN', 'Unknown Customer', 'Unknown', 'Unknown', 'Unknown',
    null, null, null, 'Unknown'