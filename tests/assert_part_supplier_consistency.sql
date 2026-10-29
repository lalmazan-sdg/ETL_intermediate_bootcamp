select *
from {{ ref("int_part_supplier") }}
where abs(potential_revenue - inventory_value - potential_gross_profit) > 0.02
