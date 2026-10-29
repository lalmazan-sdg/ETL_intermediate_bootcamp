with
    parts as (select * from {{ ref("stg_tpch_sf10__parts") }}),

    final as (
        select
            part_id,
            part_name,
            manufacturer,
            brand,
            part_type,
            size,
            container,
            retail_price

        from parts
    )

select *
from final
