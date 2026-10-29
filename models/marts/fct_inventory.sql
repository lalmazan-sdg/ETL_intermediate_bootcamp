{{ config(materialized="table") }}

with
    part_supplier as (select * from {{ ref("int_part_supplier") }}),

    final as (
        select
            part_supplier_id,
            part_id,
            supplier_id,

            available_quantity,
            is_out_of_stock,

            retail_price,
            supply_cost,
            price_cost_difference,

            inventory_value,
            potential_revenue,
            potential_gross_profit,
            potential_margin_pct,
            potential_markup_pct

        from part_supplier
    )

select *
from final
