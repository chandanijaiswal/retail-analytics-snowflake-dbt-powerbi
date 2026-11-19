-- Staging: clean the raw product catalogue
select
    upper(trim(product_code)) as product_code,
    trim(regexp_replace(product_name, ' +', ' ')) as product_name,

    case
        when lower(trim(category)) in ('mobiles', 'mobile', 'mobile phones')
            then 'Mobiles'
        when lower(trim(category)) in ('laptops', 'laptop', 'notebooks')
            then 'Laptops'
        when lower(trim(category)) in ('televisions', 'television', 'tv')
            then 'Televisions'
        when lower(trim(category)) = 'audio'
            then 'Audio'
        when lower(trim(category)) in ('accessories', 'accessory', 'acc.')
            then 'Accessories'
        when lower(trim(category)) in ('home appliances', 'home appliance', 'appliances')
            then 'Home Appliances'
    end as category,

    initcap(trim(brand)) as brand,

    try_to_number(regexp_replace(cost_price, '[^0-9.]', ''), 12, 2) as cost_price,
    try_to_number(regexp_replace(list_price, '[^0-9.]', ''), 12, 2) as list_price
from {{ source('raw', 'raw_products') }}