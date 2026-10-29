with
    customers as (select * from {{ ref("stg_tpch_sf10__customers") }}),

    geography as (select * from {{ ref("int_geography") }}),

    enriched as (
        select
            c.customer_id,
            c.customer_name,
            c.address,
            c.phone_number,
            c.account_balance,
            c.market_segment,
            c.comment,

            c.nation_id,
            g.nation_name,
            g.region_id,
            g.region_name,

            case
                when c.account_balance < 0 then true else false
            end as is_negative_balance,

            case
                when c.account_balance > 0 then true else false
            end as is_positive_balance

        from customers as c
        left join geography as g on c.nation_id = g.nation_id
    )

select *
from enriched
