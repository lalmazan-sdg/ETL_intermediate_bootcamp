{{ config(tags=['marts', 'business_rules']) }}
with
intermediate as (
    select
        order_line_id,
        net_amount,
        total_amount
    from {{ ref("int_order_lines") }}
),

business as (
    select
        order_line_id,
        net_amount,
        total_amount
    from {{ ref("fct_order_lines") }}
),

differences as (
    select
        i.net_amount as int_net_amount,

        b.net_amount as fct_net_amount,

        i.total_amount as int_total_amount,
        b.total_amount as fct_total_amount,
        coalesce(i.order_line_id, b.order_line_id)
            as order_line_id,
        case
            when i.order_line_id is null then 'missing_in_intermediate'
            when b.order_line_id is null then 'missing_in_business'
            else 'amount_mismatch'
        end as failure_reason

    from intermediate as i
    full outer join business as b
        on i.order_line_id = b.order_line_id

    where
        i.order_line_id is null
        or b.order_line_id is null
        or i.net_amount is distinct from b.net_amount
        or i.total_amount is distinct from b.total_amount
)

select *
from differences
