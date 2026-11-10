
{{ config(materialized="table") }}

{% set order_lines = ref("int_order_lines") %}

{% set min_date_query %}
    (
        select
            min(
                least_ignore_nulls(
                    order_date,
                    ship_date,
                    commit_date,
                    receipt_date
                )
            )::date
        from {{ order_lines }}
    )
{% endset %}

{% set max_date_query %}
    (
        select
            dateadd(
                day,
                1,
                max(
                    greatest_ignore_nulls(
                        order_date,
                        ship_date,
                        commit_date,
                        receipt_date
                    )
                )::date
            )
        from {{ order_lines }}
    )
{% endset %}

with
    date_spine as (
        {{
            dbt_utils.date_spine(
                datepart="day",
                start_date=min_date_query,
                end_date=max_date_query
            )
        }}
    ),

    final as (
        select
            {{ generate_date_key("date_day") }} as date_key,

            date_day,
            year(date_day) as year,
            quarter(date_day) as quarter,
            month(date_day) as month,
            monthname(date_day) as month_name,
            weekiso(date_day) as week_of_year,
            day(date_day) as day_of_month,
            dayofweekiso(date_day) as day_of_week,
            dayofweekiso(date_day) in (6, 7) as is_weekend,
            date_trunc('month', date_day)::date as month_start_date,
            last_day(date_day)::date as month_end_date

        from date_spine
    )

select *
from final
