# Data Quality Problem Log

Before writing any code, I explored the four raw CSV files (`raw_sales`, `raw_customers`, `raw_products`, `raw_stores`) in a text editor, without saving them in Excel, and logged every problem. Each problem is fixed in a dbt staging model, so the fix repeats automatically when new data arrives. Nothing was corrected by hand.

## Problems found and fixes

| # | File | Problem | Example from the data | Fix (dbt model) | Snowflake function |
|---|---|---|---|---|---|
| 1 | sales | Duplicate orders | Same `order_id` twice (60 extra rows) | `stg_sales` | `QUALIFY ROW_NUMBER() OVER (PARTITION BY order_id ...) = 1` |
| 2 | sales | Mixed case and spaces in IDs | `ord-25-00302`, `p033`, `st05` | `stg_sales` | `UPPER(TRIM())` |
| 3 | sales | Three date formats | `2025-11-21`, `01/12/2025`, `15-Mar-2025` | `stg_sales` | `COALESCE(TRY_TO_DATE(...))` |
| 4 | sales | Text inside prices | `₹39,999`, `INR 61999` | `stg_sales` | `REGEXP_REPLACE` + `TRY_TO_NUMBER` |
| 5 | sales | Text inside quantity | `1 pcs`, `3 Nos` | `stg_sales` | `REGEXP_REPLACE` + `TRY_TO_NUMBER` |
| 6 | sales | Blank or `NA` quantity | 8 orders with no valid quantity | `stg_sales` | `WHERE quantity > 0` |
| 7 | sales | Mixed discount styles | `10%`, `10 %`, `0.10`, `5`, blank | `stg_sales` | `CASE WHEN` |
| 8 | sales | Many spellings of payment mode | `UPI`, `upi`, `G-Pay`, `GPay`, `PhonePe`, `Paytm`, `COD` | `stg_sales` | `CASE WHEN ... IN (...)` |
| 9 | sales | Many spellings of order status | `Canceled` vs `Cancelled`, `Return` vs `Returned` | `stg_sales` | `CASE WHEN ... IN (...)` |
| 10 | sales | Store code formats | `ST-07` vs `ST07` | `stg_sales`, `stg_stores` | `REPLACE(UPPER(TRIM()), '-', '')` |
| 11 | sales | Orders from customers missing in the customer file | 12 orders, customers C9001 to C9006 | `dim_customers`, `fct_sales` | `UNKNOWN` customer row + `COALESCE` |
| 12 | customers | Duplicate customers | 12 customers appear twice | `stg_customers` | `QUALIFY ROW_NUMBER()` |
| 13 | customers | Name case and extra spaces | `rahul SHARMA`, `Priya   Nair` | `stg_customers` | `INITCAP(TRIM(REGEXP_REPLACE(...)))` |
| 14 | customers | Old or short city names | `Bombay`, `Bangalore`, `BLR`, `Madras`, `Gurgaon`, `Calcutta`, `Cochin` | `stg_customers`, `stg_stores` | `CASE WHEN` mapping |
| 15 | customers | State codes and mixed case | `KA`, `MH`, `TS`, `karnataka`, `TELANGANA` | `stg_customers`, `stg_stores` | `CASE WHEN` + `INITCAP` |
| 16 | customers | Phone number formats | `+91 98765 43210`, `09876543210`, `98765-43210` | `stg_customers` | `RIGHT(REGEXP_REPLACE(phone, '[^0-9]', ''), 10)` |
| 17 | customers | Invalid emails | `NA`, no domain | `stg_customers` | `CASE WHEN email LIKE '%_@_%._%'` |
| 18 | customers | Mixed segment spellings | `SMB`, `Small Biz`, `Individual`, `Corp.` | `stg_customers` | `CASE WHEN ... IN (...)` |
| 19 | products | Text inside prices | `₹13,534`, `INR 14935` | `stg_products` | `REGEXP_REPLACE` + `TRY_TO_NUMBER` |
| 20 | products | Category spellings | `Mobile`, `Mobile Phones`, `MOBILES`, `TV` | `stg_products` | `CASE WHEN ... IN (...)` |
| 21 | products | Brand and name casing, extra spaces | `SAMSUNG`, `xiaomi` | `stg_products` | `INITCAP(TRIM())` |
| 22 | stores | Region short forms | `N`, `south`, `All India` variants | `stg_stores` | `CASE WHEN` on first letter |
| 23 | stores | Store type spellings | `Shopping Mall`, `MALL`, `High St.` | `stg_stores` | `CASE WHEN ... LIKE` |

## Before and after

| Check | Raw | Clean |
|---|---|---|
| Sales rows | 2,468 | 2,400 |
| Customers | 312 | 300 (301 in `dim_customers` with the `UNKNOWN` row) |
| Products | 40 | 40 |
| Stores | 12 | 12 |
| Payment mode values | 23 spellings | 5 (UPI, Credit Card, Debit Card, Cash, Net Banking) |
| Order status values | several spellings | 3 (Delivered, Cancelled, Returned) |

## Why raw tables use text columns

Every column in the `RAW` schema is `VARCHAR`. A value such as `2 pcs` or `₹17,999` would make a numeric load fail, so the raw layer accepts everything exactly as received and dbt converts the types in staging. This keeps the original data available for audit.

## Decision on orders from unknown customers

12 orders belong to customer IDs that are not in the customer file. They are real sales, so deleting them would understate revenue. They are kept and linked to an `UNKNOWN` customer ("Unknown Customer" in Power BI). In dbt, the relationship test on `stg_sales.customer_id` is set to `severity: warn`, so the pipeline reports the 12 orders without stopping.

## Tests that prove the fixes

27 dbt tests: 26 pass, 1 intentional warning (the 12 unknown-customer orders).

- `unique` and `not_null` on every key
- `accepted_values` on payment mode, order status, segment, category and region (proves no stray spellings remain)
- `relationships` from `fct_sales` to every dimension (proves every fact row finds its dimension row)
