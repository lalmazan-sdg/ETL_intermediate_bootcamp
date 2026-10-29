select *
from {{ ref("int_order_lines") }}
where
    (
        shipping_lead_days is not null
        and delivery_days is not null
        and delivery_lead_days is not null
        and delivery_lead_days != shipping_lead_days + delivery_days
    )
    or (
        shipping_delay_days is not null
        and (is_late_delivery != (shipping_delay_days > 0))
    )
