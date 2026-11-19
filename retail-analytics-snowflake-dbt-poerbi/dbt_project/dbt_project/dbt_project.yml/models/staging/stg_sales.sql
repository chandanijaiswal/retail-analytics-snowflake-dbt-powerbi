-- Staging: clean every column of the raw sales data
with cleaned as (
    select
        upper(trim(order_id))    as order_id,
        coalesce(
            try_to_date(trim(order_date), 'YYYY-MM-DD'),
            try_to_date(trim(order_date), 'DD/MM/YYYY'),
            try_to_date(trim(order_date), 'DD-MON-YYYY')) as order_date,
        upper(trim(customer_id)) as customer_id,
        upper(trim(product_code)) as product_code,
        replace(upper(trim(store_code)), '-', '') as store_code,

        try_to_number(nullif(regexp_replace(quantity, '[^0-9]', ''), ''))
            as quantity,

        try_to_number(nullif(regexp_replace(unit_price, '[^0-9.]', ''), ''), 12, 2)
            as unit_price,

        case
            when nullif(trim(discount), '') is null then 0
            when contains(discount, '%')
              or try_to_number(regexp_replace(discount, '[^0-9.]', ''), 10, 4) > 1
                then try_to_number(regexp_replace(discount, '[^0-9.]', ''), 10, 4) / 100
            else try_to_number(regexp_replace(discount, '[^0-9.]', ''), 10, 4)
        end as discount,

        case
            when lower(trim(payment_mode)) in ('upi', 'g-pay', 'gpay', 'phonepe', 'paytm')
                then 'UPI'
            when lower(trim(payment_mode)) in ('credit card', 'cc')
                then 'Credit Card'
            when lower(trim(payment_mode)) in ('debit card', 'dc', 'debit')
                then 'Debit Card'
            when lower(trim(payment_mode)) in ('cash', 'cod', 'cash on delivery')
                then 'Cash'
            when lower(trim(payment_mode))
                in ('net banking', 'netbanking', 'net-banking', 'neft')
                then 'Net Banking'
        end as payment_mode,

        case
            when lower(trim(order_status)) = 'delivered' then 'Delivered'
            when lower(trim(order_status)) in ('cancelled', 'canceled')
                then 'Cancelled'
            when lower(trim(order_status)) in ('returned', 'return')
                then 'Returned'
        end as order_status
    from {{ source('raw', 'raw_sales') }}
)

select *
from cleaned
-- drop orders with no valid quantity
where quantity > 0
-- remove duplicates: keep one row per order_id
qualify row_number() over (partition by order_id order by order_date) = 1
