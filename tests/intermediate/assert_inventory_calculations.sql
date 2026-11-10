{{ config(tags=['intermediate', 'business_rules']) }}
with
    inventory as (
        select *
        from {{ ref("int_part_supplier") }}
    ),

    expected_values as (
        select
            part_supplier_id,

            inventory_value,
            price_cost_difference,
            potential_revenue,
            potential_gross_profit,
            is_out_of_stock,

            round(
                supply_cost * available_quantity, 2
            ) as expected_inventory_value,

            round(
                retail_price - supply_cost, 2
            ) as expected_price_cost_difference,

            round(
                retail_price * available_quantity, 2
            ) as expected_potential_revenue,

            round(
                (retail_price - supply_cost) * available_quantity, 2
            ) as expected_potential_gross_profit,

            (available_quantity = 0) as expected_is_out_of_stock

        from inventory
    ),

    failures as (
        select
            part_supplier_id,

            inventory_value is distinct from expected_inventory_value
                as invalid_inventory_value,

            price_cost_difference is distinct from expected_price_cost_difference
                as invalid_price_cost_difference,

            potential_revenue is distinct from expected_potential_revenue
                as invalid_potential_revenue,

            potential_gross_profit is distinct from expected_potential_gross_profit
                as invalid_potential_gross_profit,

            is_out_of_stock is distinct from expected_is_out_of_stock
                as invalid_stock_flag

        from expected_values
    )

select *
from failures
where
    invalid_inventory_value
    or invalid_price_cost_difference
    or invalid_potential_revenue
    or invalid_potential_gross_profit
    or invalid_stock_flag
