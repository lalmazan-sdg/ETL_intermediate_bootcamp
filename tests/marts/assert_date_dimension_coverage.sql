
{{ config(tags=['marts', 'business_rules']) }}

with date_bounds as (
    select
        min(date_day) as min_date,
        max(date_day) as max_date,
        count(distinct date_day) as actual_days
    from {{ ref('dim_date') }}
),

validation as (
    select
        min_date,
        max_date,
        actual_days,
        datediff('day', min_date, max_date) + 1 as expected_days
    from date_bounds
)

select *
from validation
where
    actual_days != expected_days
