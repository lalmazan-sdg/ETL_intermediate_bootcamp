{{ config(materialized="view") }}

with
    dates as (select * from {{ ref("int_date") }}),

    final as (
        select
            date_key,
            date_day,
            year,
            quarter,
            month,
            month_name,
            week_of_year,
            day_of_month,
            day_of_week,
            is_weekend,
            month_start_date,
            month_end_date

        from dates
    )

select *
from final
