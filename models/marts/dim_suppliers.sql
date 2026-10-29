with
    suppliers as (select * from {{ ref("stg_tpch_sf10__suppliers") }}),

    geography as (select * from {{ ref("int_geography") }}),

    final as (
        select
            s.supplier_id,
            s.supplier_name,
            s.address,
            s.phone_number,
            s.account_balance,

            s.nation_id,
            g.nation_name,
            g.region_id,
            g.region_name

        from suppliers as s
        left join geography as g on s.nation_id = g.nation_id
    )

select *
from final
