{{
    config(
        materialized="incremental",
        incremental_strategy="merge",
        unique_key=["order_id", "line_number"],
    )
}}

with
    source as (
        select *
        from {{ source("tpch_sf10", "lineitem") }}

        {% if is_incremental() %}
            where
                not exists (
                    select 1
                    from {{ this }} as target
                    where
                        target.order_id = l_orderkey
                        and target.line_number = l_linenumber
                )
        {% endif %}
    ),

    renamed as (
        select
            l_orderkey as order_id,
            l_linenumber as line_number,
            l_partkey as part_id,
            l_suppkey as supplier_id,
            l_quantity as quantity,
            l_extendedprice as extended_price,
            l_discount as discount_percentage,
            l_tax as tax_rate,
            l_returnflag as return_flag,
            l_linestatus as line_status,
            l_shipdate as ship_date,
            l_commitdate as commit_date,
            l_receiptdate as receipt_date,
            l_shipinstruct as ship_instructions,
            l_shipmode as ship_mode,
            l_comment as comment
        from source
    )

select *
from renamed
