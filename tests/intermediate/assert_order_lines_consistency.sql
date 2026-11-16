{{ config(tags=['intermediate', 'business_rules', 'custom']) }}

select *
from {{ ref("int_order_lines") }}

where
    (
        delivery_lead_days is distinct from
        (shipping_lead_days + delivery_days)
    )

    or (
        is_late_delivery is distinct from
        (shipping_delay_days > 0)
    )