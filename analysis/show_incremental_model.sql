-- Analysis models in the `analysis` folder are compiled by dbt but not executed.

select * from {{ ref('incremental_dim_orders') }}


-- 7 rows of order and 6 rows of orders of order_date
