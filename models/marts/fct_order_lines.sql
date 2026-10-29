{{ config(materialized="table") }}

with
    order_lines as (select * from {{ ref("int_order_lines") }}),

    final as (
        select
            order_line_id,
            order_id,
            line_number,
            customer_id,
            part_id,
            supplier_id,

            order_date,
            ship_date,
            commit_date,
            receipt_date,

            order_status,
            order_priority,
            line_status,
            return_flag,
            ship_mode,
            ship_instructions,

            quantity,
            extended_price,
            discount_percentage,
            tax_rate,
            discount_amount,
            net_amount,
            total_amount,

            shipping_lead_days,
            delivery_lead_days,
            delivery_days,
            shipping_delay_days,
            is_late_delivery,
            is_returned

        from order_lines
    )

select *
from final
