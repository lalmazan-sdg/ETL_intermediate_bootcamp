with
    test_cases as (
        select column1, column2, expected_result
        from
        values
            (123, 1, '123-1'),
            (123, 2, '123-2'),
            (456, 10, '456-10') as t(column1, column2, expected_result)
    ),

    calculated as (
        select *, {{ generate_composite_key("column1", "column2") }} as actual_result
        from test_cases
    )

select *
from calculated
where actual_result != expected_result or actual_result is null
