with
    customers as (select * from {{ ref("int_customers") }}),

    final as (
        select
            customer_id,
            customer_name,
            address,
            phone_number,
            market_segment,

            nation_id,
            nation_name,
            region_id,
            region_name,

            account_balance,
            is_negative_balance,
            is_positive_balance

        from customers
    )

select *
from final
