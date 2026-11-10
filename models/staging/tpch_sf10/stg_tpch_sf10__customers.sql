with
    source as (select * from {{ source("tpch_sf10", "customer") }}),

    renamed as (
        select
            c_custkey as customer_id,
            c_nationkey as nation_id,
            c_name as customer_name,
            c_address as address,
            c_phone as phone_number,
            c_acctbal as account_balance,
            c_mktsegment as market_segment,
            c_comment as comment
        from source
    )

select *
from renamed
