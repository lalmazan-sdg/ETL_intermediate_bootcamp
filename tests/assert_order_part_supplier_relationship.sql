select o.order_line_id, o.part_id, o.supplier_id
from {{ ref("int_order_lines") }} as o
left join
    {{ ref("int_part_supplier") }} as ps
    on o.part_id = ps.part_id
    and o.supplier_id = ps.supplier_id
where ps.part_supplier_id is null
