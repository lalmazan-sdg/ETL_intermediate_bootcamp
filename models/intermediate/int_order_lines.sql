with
    orders as (select * from {{ ref("stg_tpch_sf10__orders") }}),

    lineitem as (select * from {{ ref("stg_tpch_sf10__lineitems") }}),

    joined as (
        select
            l.order_id,
            l.line_number,
            concat(l.order_id, '-', l.line_number) as order_line_id,
            o.customer_id,
            l.part_id,
            l.supplier_id,

            o.order_date,
            l.ship_date,
            l.commit_date,
            l.receipt_date,

            o.order_status,
            o.order_priority,
            l.line_status,
            l.return_flag,
            l.ship_mode,
            l.ship_instructions,

            l.quantity,
            l.extended_price,
            l.discount_percentage,
            l.tax_rate

        from lineitem as l
        inner join orders as o on l.order_id = o.order_id
    ),

    calculated as (
        select
            *,

            round(extended_price * discount_percentage, 2) as discount_amount,

            round(extended_price * (1 - discount_percentage), 2) as net_amount,

            round(
                extended_price * (1 - discount_percentage) * (1 + tax_rate), 2
            ) as total_amount,

            datediff('day', order_date, ship_date) as shipping_lead_days,

            datediff('day', order_date, receipt_date) as delivery_lead_days,

            datediff('day', ship_date, receipt_date) as delivery_days,

            datediff('day', commit_date, receipt_date) as shipping_delay_days,

            case
                when receipt_date > commit_date then true else false
            end as is_late_delivery,

            case when return_flag = 'R' then true else false end as is_returned

        from joined
    )

select *
from calculated
