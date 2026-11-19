-- Fact: one row per valid order, with amounts and profit
with sales as (
    select * from {{ ref('stg_sales') }}
),

products as (
    select product_code, cost_price from {{ ref('stg_products') }}
),

customers as (
    select customer_id from {{ ref('stg_customers') }}
)

select
    s.order_id,
    s.order_date,
    coalesce(c.customer_id, 'UNKNOWN') as customer_id,
    s.product_code,
    s.store_code,
    s.quantity,
    s.unit_price,
    s.discount,
    round(s.quantity * s.unit_price, 2) as gross_amount,
    round(s.quantity * s.unit_price * (1 - s.discount), 2) as net_amount,
    round(s.quantity * s.unit_price * (1 - s.discount), 2)
        - s.quantity * p.cost_price as profit,
    s.payment_mode,
    s.order_status
from sales s
left join products  p on s.product_code = p.product_code
left join customers c on s.customer_id  = c.customer_id