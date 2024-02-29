{%- macro deduplicate(relation, partition_by, order_by=none, relation_alias=none) -%}

    {%- set error_message_group_by -%}
Warning: the `group_by` parameter of the `deduplicate` macro is no longer supported and will be deprecated in a future release of dbt-utils.
Use `partition_by` instead.
The {{ model.package_name }}.{{ model.name }} model triggered this warning.
    {%- endset -%}

    {% if kwargs.get('group_by') %}
    {%- do exceptions.warn(error_message_group_by) -%}
    {%- endif -%}

    {%- set error_message_order_by -%}
Warning: `order_by` as an optional parameter of the `deduplicate` macro is no longer supported and will be deprecated in a future release of dbt-utils.
Supply a non-null value for `order_by` instead.
The {{ model.package_name }}.{{ model.name }} model triggered this warning.
    {%- endset -%}

    {% if not order_by %}
    {%- do exceptions.warn(error_message_order_by) -%}
    {%- endif -%}

    {%- set error_message_alias -%}
Warning: the `relation_alias` parameter of the `deduplicate` macro is no longer supported and will be deprecated in a future release of dbt-utils.
If you were using `relation_alias` to point to a CTE previously then you can now pass the alias directly to `relation` instead.
The {{ model.package_name }}.{{ model.name }} model triggered this warning.
    {%- endset -%}

    {% if relation_alias %}
    {%- do exceptions.warn(error_message_alias) -%}
    {%- endif -%}

    {% set partition_by = partition_by or kwargs.get('group_by') %}
    {% set relation = relation_alias or relation %}
    {% set order_by = order_by or "'1'" %}

    {{ return(adapter.dispatch('deduplicate', 'dbt_utils')(relation, partition_by, order_by)) }}
{% endmacro %}

{%- macro default__deduplicate(relation, partition_by, order_by) -%}

    with row_numbered as (
        select
            _inner.*,
            row_number() over (
                partition by {{ partition_by }}
                order by {{ order_by }}
            ) as rn
        from {{ relation }} as _inner
    )

    select
        distinct data.*
    from {{ relation }} as data
    {#

    #}
    natural join row_numbered
    where row_numbered.rn = 1

{%- endmacro -%}

{# Redshift should use default instead of Postgres #}
{% macro redshift__deduplicate(relation, partition_by, order_by) -%}

    {{ return(dbt_utils.default__deduplicate(relation, partition_by, order_by=order_by)) }}

{% endmacro %}

{#

#}
{%- macro postgres__deduplicate(relation, partition_by, order_by) -%}

    select
        distinct on ({{ partition_by }}) *
    from {{ relation }}
    order by {{ partition_by }}{{ ',' ~ order_by }}

{%- endmacro -%}

{#

#}
{%- macro snowflake__deduplicate(relation, partition_by, order_by) -%}

    select *
    from {{ relation }}
    qualify
        row_number() over (
            partition by {{ partition_by }}
            order by {{ order_by }}
        ) = 1

{%- endmacro -%}

{#

#}
{%- macro bigquery__deduplicate(relation, partition_by, order_by) -%}

    select unique.*
    from (
        select
            array_agg (
                original
                order by {{ order_by }}
                limit 1
            )[offset(0)] unique
        from {{ relation }} original
        group by {{ partition_by }}
    )

{%- endmacro -%}
