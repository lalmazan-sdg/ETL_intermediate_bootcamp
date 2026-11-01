{{ config(materialized="view") }}

with
    suppliers as (select * from {{ ref("int_suppliers") }}),

    final as (
        select
            supplier_id,
            supplier_name,
            nation_id,
            nation_name,
            region_id,
            region_name,
            address,
            phone_number,
            account_balance,
            comment
        from suppliers
    )

select *
from final
