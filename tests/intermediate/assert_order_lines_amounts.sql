{{ config(tags=['intermediate', 'business_rules']) }}
with
    order_lines as (
        select *
        from {{ ref("int_order_lines") }}
    ),

    expected_amounts as (
        select
            order_line_id,

            discount_amount,
            net_amount,
            total_amount,

            round(
                extended_price * discount_percentage, 2
            ) as expected_discount_amount,

            round(
                extended_price * (1 - discount_percentage), 2
            ) as expected_net_amount,

            round(
                extended_price * (1 - discount_percentage) * (1 + tax_rate), 2
            ) as expected_total_amount

        from order_lines
    ),

    failures as (
        select
            order_line_id,
            'discount_amount' as failed_metric,
            discount_amount as actual_value,
            expected_discount_amount as expected_value
        from expected_amounts
        where discount_amount is distinct from expected_discount_amount

        union all

        select
            order_line_id,
            'net_amount' as failed_metric,
            net_amount as actual_value,
            expected_net_amount as expected_value
        from expected_amounts
        where net_amount is distinct from expected_net_amount

        union all

        select
            order_line_id,
            'total_amount' as failed_metric,
            total_amount as actual_value,
            expected_total_amount as expected_value
        from expected_amounts
        where total_amount is distinct from expected_total_amount
    )

select *
from failures
