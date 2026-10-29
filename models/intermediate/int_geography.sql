with nations as (
    select * from {{ ref('stg_tpch_sf10__nations') }}
),

regions as (
    select * from {{ ref('stg_tpch_sf10__regions') }}
),

joined as (
    select
        n.nation_id,
        n.nation_name,
        r.region_id,
        r.region_name
    from nations as n
    left join regions as r
        on n.region_id = r.region_id
)

select * from joined