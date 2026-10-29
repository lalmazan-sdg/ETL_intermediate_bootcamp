select order_id, line_number, count(*) as record_count
from {{ ref("stg_tpch_sf10__lineitems") }}
group by order_id, line_number
having count(*) > 1
