with
    partsupp as (select * from {{ ref("stg_tpch_sf10__partsupps") }}),

    part as (select * from {{ ref("stg_tpch_sf10__parts") }}),

    supplier as (select * from {{ ref("stg_tpch_sf10__suppliers") }}),

    joined as (
        select

            ps.part_id,
            ps.supplier_id,
            concat(ps.part_id, '-', ps.supplier_id) as part_supplier_id,

            p.part_name,
            p.manufacturer,
            p.brand,
            p.part_type,
            p.size,
            p.container,
            p.retail_price,
            p.comment as part_comment,

            s.supplier_name,
            s.address as supplier_address,
            s.nation_id as supplier_nation_id,
            s.phone_number as supplier_phone_number,
            s.account_balance as supplier_account_balance,
            s.comment as supplier_comment,

            ps.available_quantity,
            ps.supply_cost,
            ps.comment as partsupp_comment,

            round(ps.supply_cost * ps.available_quantity, 2) as inventory_value,
            round(p.retail_price - ps.supply_cost, 2) as price_cost_difference

        from partsupp as ps
        left join part as p on ps.part_id = p.part_id
        left join supplier as s on ps.supplier_id = s.supplier_id
    )

select *
from joined
