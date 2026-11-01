{{ config(materialized="table") }}

with
    order_lines as (
        select order_date, ship_date, commit_date, receipt_date
        from {{ ref("int_order_lines") }}
    ),

    date_bounds as (
        select
            min(
                least_ignore_nulls(order_date, ship_date, commit_date, receipt_date)
            ) as min_date,

            max(
                greatest_ignore_nulls(order_date, ship_date, commit_date, receipt_date)
            ) as max_date

        from order_lines
    ),

    date_spine as (
        select
            dateadd(
                day, row_number() over (order by seq4()) - 1, date_bounds.min_date
            )::date as date_day

        from date_bounds
        cross join table(generator(rowcount => 4000))
    ),

    filtered_dates as (
        select date_spine.date_day

        from date_spine
        cross join date_bounds

        where date_spine.date_day <= date_bounds.max_date
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

        from filtered_dates
    )

select *
from final
