# Electronics Retail Sales Analytics: Snowflake + dbt + Power BI

An end-to-end ELT pipeline that turns four messy CSV files from a multi-city electronics retail chain in India (2025) into a clean star schema and an interactive Power BI dashboard.

<img width="1351" height="768" alt="Dashboard" src="https://github.com/user-attachments/assets/801a6b50-0bb3-41b4-8bd6-5a82dea31839" />


## Business problem

The business sends raw sales, customer, product and store files with more than 25 data-quality problems (duplicates, mixed date formats, text inside numbers, many spellings of one value, broken customer links). Management needs one trusted view of revenue, profit, returns and cancellations.

## Architecture

```
4 messy CSV files  ->  Snowflake RAW tables  ->  dbt staging views  ->  dbt star schema  ->  Power BI dashboard
```

| Layer | Where | What happens |
|---|---|---|
| CSV files | Local | Data as the business sends it |
| Stage + RAW tables | `DBT_DEMO_DB.RAW` | Files loaded with `COPY INTO`, every column as text |
| Staging (4 views) | `DBT_DEMO_DB.RETAIL` | Cleaning: formats, spellings, duplicates, invalid rows |
| Marts (5 tables) | `DBT_DEMO_DB.RETAIL` | `fct_sales` + `dim_customers`, `dim_products`, `dim_stores`, `dim_date` |
| Power BI | Desktop | Relationships, DAX measures, dashboard |

<img width="1472" height="760" alt="DAG " src="https://github.com/user-attachments/assets/2104c6fd-81bd-4d6d-bfe2-d3e03d2213b1" />


## Tech stack

Snowflake, dbt (1.9), SQL, Power BI Desktop, DAX, GitHub

## Data quality problems fixed

| Problem | Example | Fix in dbt |
|---|---|---|
| Duplicate orders / customers | 60 duplicate orders, 12 duplicate customers | `QUALIFY ROW_NUMBER()` |
| Mixed date formats | `2025-03-15`, `15/03/2025`, `15-Mar-2025` | `COALESCE(TRY_TO_DATE(...))` |
| Text inside numbers | `2 pcs`, `₹17,999`, `INR 17999` | `REGEXP_REPLACE` + `TRY_TO_NUMBER` |
| Mixed discount styles | `10%`, `0.10`, `10`, blank | `CASE WHEN` |
| Many spellings of one value | `G-Pay`, `PhonePe`, `Paytm` -> `UPI` | `CASE WHEN ... IN (...)` |
| Old city names and state codes | `Bombay`, `Bangalore`, `MH`, `TS` | `CASE WHEN` mapping |
| Phone and email formats | `+91 98765 43210`, invalid emails | Keep last 10 digits, validate email pattern |
| Invalid rows | blank or `NA` quantity (8 orders) | `WHERE quantity > 0` |
| Broken links | 12 orders from customers not in the customer file | Mapped to an `UNKNOWN` customer, kept as real sales |

**Row counts:** 2,468 raw sales rows -> 2,400 clean orders; 312 raw customers -> 300; 23 payment-mode spellings -> 5.

## Data model (star schema)

<img width="1298" height="707" alt="star_schema" src="https://github.com/user-attachments/assets/80974c59-699f-4d37-8f55-a952748ab3dd" />


- `fct_sales`: one row per valid order (gross amount, net amount, profit)
- `dim_customers`, `dim_products`, `dim_stores`, `dim_date`

## Data testing

27 dbt tests (unique, not_null, accepted_values, relationships): **26 pass, 1 intentional warning**. The warning reports the 12 orders from customers missing in the customer file. They are real sales, so they are kept and shown as "Unknown Customer".

## DAX measures

Total Orders, Delivered Orders, Net Revenue, Total Profit, Units Sold, Avg Order Value, Profit Margin %, Return Rate %, Cancellation Rate %, Revenue MoM %, plus display measures in crore and lakh. Revenue, profit and units count **delivered orders only**.

## Key results (delivered orders)

| KPI | Value |
|---|---|
| Net revenue | ₹8.18 Cr |
| Profit | ₹1.48 Cr |
| Delivered orders | 2,046 |
| Avg order value | ₹39,961 |
| Return rate | 6.6% |
| Cancellation rate | 8.1% |

## Insights

- Mobiles generate about 55.5% of revenue.
- Revenue peaks in November (about ₹100.2 L), the Diwali season.
- Apple is the top brand by revenue, followed by Samsung.
- UPI is the most used payment mode.
- The online store is the top store by revenue.

## Repository structure

```
.
├── README.md
├── data/                 # the 4 raw CSV files
├── sql/                  # retail_setup.sql, explore.sql
├── dbt_project/          # retail_analytics (models, schema.yml, dbt_project.yml)
├── powerbi/              # retail_sales_dashboard.pbix
├── screenshots/          # dashboard, DAG, star schema
└── docs/problem_log.md   # data-quality problem log
```

## How to run

1. Run `sql/retail_setup.sql` in Snowflake (warehouse, schemas, stage, file format, RAW tables).
2. Upload the CSV files to `RAW.CSV_STAGE` and run the `COPY INTO` statements.
3. Create the dbt project `retail_analytics`, add the files from `dbt_project/`, then run `dbt build`.
4. Open `powerbi/retail_sales_dashboard.pbix`, connect to your Snowflake account and refresh.

## Author

**Chandani Jaiswal**
