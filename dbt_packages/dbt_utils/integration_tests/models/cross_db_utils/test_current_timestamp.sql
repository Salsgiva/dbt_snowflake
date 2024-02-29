select
    {{ dbt_utils.current_timestamp() }} as actual,
    {{ dbt_utils.current_timestamp() }} as expected

