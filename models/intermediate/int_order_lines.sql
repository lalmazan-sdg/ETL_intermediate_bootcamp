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
            l.tax_rate,

            round(l.extended_price * l.discount_percentage, 2) as discount_amount,
            round(l.extended_price * (1 - l.discount_percentage), 2) as net_amount,
            round(
                (l.extended_price * (1 - l.discount_percentage)) * (1 + l.tax_rate), 2
            ) as total_amount,

            datediff('day', l.ship_date, l.receipt_date) as delivery_days,
            case
                when l.receipt_date > l.commit_date then true else false
            end as is_late_delivery

        from lineitem as l
        inner join orders as o on l.order_id = o.order_id
    )

select *
from joined
