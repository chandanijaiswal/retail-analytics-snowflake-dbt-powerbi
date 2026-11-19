-- Dimension: products with margin
select
    product_code,
    product_name,
    category,
    brand,
    cost_price,
    list_price,
    round((list_price - cost_price) / list_price, 4) as margin_pct
from {{ ref('stg_products') }}