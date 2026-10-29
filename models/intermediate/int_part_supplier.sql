with
    partsupp as (select * from {{ ref("stg_tpch_sf10__partsupps") }}),

    part as (select * from {{ ref("stg_tpch_sf10__parts") }}),

    joined as (
        select
            ps.part_id,
            ps.supplier_id,
            {{ generate_composite_key("ps.part_id", "ps.supplier_id") }}
            as part_supplier_id,

            p.retail_price,
            ps.available_quantity,
            ps.supply_cost

        from partsupp as ps
        left join part as p on ps.part_id = p.part_id
    ),

    calculated as (
        select
            *,

            round(supply_cost * available_quantity, 2) as inventory_value,

            round(retail_price - supply_cost, 2) as price_cost_difference,

            round(retail_price * available_quantity, 2) as potential_revenue,

            round(
                (retail_price - supply_cost) * available_quantity, 2
            ) as potential_gross_profit,

            {{ calculate_percentage("retail_price - supply_cost", "retail_price") }}
            as potential_margin_pct,

            {{ calculate_percentage("retail_price - supply_cost", "supply_cost") }}
            as potential_markup_pct,

            case when available_quantity = 0 then true else false end as is_out_of_stock

        from joined
    )

select *
from calculated
