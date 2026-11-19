{% docs src_tpch_sf10__customer_description %}

# CUSTOMER — Clientes

## Propósito

Tabla maestra de clientes del conjunto TPC-H. Identifica a las entidades que realizan pedidos e incorpora sus datos de contacto, país, segmento comercial y saldo de cuenta.

## Granularidad y claves

- **Granularidad:** una fila por cliente.
- **Clave primaria:** `c_custkey`.
- **Clave de relación:** `c_nationkey` → `NATION.n_nationkey`.
- **Relación descendente:** `ORDERS.o_custkey` → `CUSTOMER.c_custkey` (un cliente puede tener varios pedidos).

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `c_custkey` | Identificador técnico del cliente. |
| `c_name`, `c_address`, `c_phone` | Datos descriptivos y de contacto; no sustituyen a la clave primaria. |
| `c_nationkey` | País del cliente, que puede agruparse por región a través de `NATION`. |
| `c_acctbal` | Saldo de cuenta; admite valores negativos y positivos. No equivale a ventas ni a ingresos. |
| `c_mktsegment` | Segmento de mercado utilizado para clasificar clientes. |
| `c_comment` | Texto descriptivo sin estructura comercial garantizada. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__customers` y, posteriormente, los modelos de cliente y análisis de pedidos. Permite segmentar ventas y cruzarlas con la geografía.

## Consideraciones

- El segmento describe al cliente, no necesariamente la categoría de cada producto comprado.
- El saldo es un atributo de origen, no una medida de facturación; sus signos requieren interpretación separada.
- La fuente procede de datos sintéticos de ejemplo (`SNOWFLAKE_SAMPLE_DATA.TPCH_SF10`), no de un CRM operativo.

{% enddocs %}

{% docs src_tpch_sf10__lineitem_description %}

# LINEITEM — Líneas de pedido

## Propósito

Detalle transaccional de los artículos asociados a cada pedido, con cantidades, importes, descuentos, impuestos y fechas e indicadores logísticos. Es la base de los análisis comerciales a nivel de línea.

## Granularidad y claves

- **Granularidad:** una fila por línea dentro de un pedido.
- **Clave natural compuesta:** (`l_orderkey`, `l_linenumber`); `l_linenumber` por sí solo no es único.
- **Relaciones:** `l_orderkey` → `ORDERS.o_orderkey`; `l_partkey` → `PART.p_partkey`; `l_suppkey` → `SUPPLIER.s_suppkey`.
- La pareja (`l_partkey`, `l_suppkey`) se corresponde con `PARTSUPP` y permite analizar el suministrador del producto concreto.

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `l_quantity` | Cantidad de producto de la línea. |
| `l_extendedprice` | Importe extendido anterior a descuentos e impuestos. |
| `l_discount` | Fracción de descuento (por ejemplo, `0.05` representa el 5 %). |
| `l_tax` | Fracción de impuesto; no es un importe monetario. |
| `l_returnflag` | Indicador de devolución según la codificación TPC-H. |
| `l_linestatus` | Estado de la línea según la codificación del conjunto de datos. |
| `l_shipdate` | Fecha de expedición. |
| `l_commitdate` | Fecha comprometida. |
| `l_receiptdate` | Fecha de recepción. |
| `l_shipinstruct`, `l_shipmode` | Instrucciones y modalidad de envío. |
| `l_comment` | Observaciones de texto libre. |

## Reglas de interpretación

- **Importe tras descuento:** `l_extendedprice * (1 - l_discount)`.
- **Importe tras descuento e impuesto:** `l_extendedprice * (1 - l_discount) * (1 + l_tax)`.
- Los indicadores de estado y devolución no deben interpretarse como importes ni como cantidades devueltas sin reglas de negocio adicionales.
- Las fechas de envío, compromiso y recepción tienen significados distintos; no deben reemplazarse unas por otras.

## Uso en el proyecto

Alimenta `stg_tpch_sf10__lineitems`, se combina con cabeceras de pedido en `int_order_lines` y contribuye a `fct_order_lines`. En staging se ha definido una materialización incremental mediante `MERGE` con clave lógica formada por pedido y número de línea.

## Consideraciones

Para evitar duplicaciones al agregar importes, respeta siempre la granularidad de línea. Al unir con `PARTSUPP`, utiliza tanto producto como proveedor, no únicamente el producto.

{% enddocs %}

{% docs src_tpch_sf10__nation_description %}

# NATION — Países

## Propósito

Catálogo geográfico de países de TPC-H. Permite ubicar clientes y proveedores y asignar cada país a su región de referencia.

## Granularidad y claves

- **Granularidad:** una fila por país del catálogo.
- **Clave primaria:** `n_nationkey`.
- **Clave externa:** `n_regionkey` → `REGION.r_regionkey`.
- `CUSTOMER.c_nationkey` y `SUPPLIER.s_nationkey` apuntan a esta tabla.

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `n_nationkey` | Identificador del país dentro de TPC-H. |
| `n_name` | Nombre del país. |
| `n_regionkey` | Identificador de la región a la que se asigna. |
| `n_comment` | Texto complementario. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__nations` y se une a `REGION` para construir `int_geography`, que enriquece las entidades comerciales con atributos geográficos.

## Consideraciones

No es un catálogo ISO completo ni debe asumirse que sus identificadores coinciden con códigos internacionales oficiales. La relación país-región es la clasificación propia de TPC-H.

{% enddocs %}

{% docs src_tpch_sf10__orders_description %}

# ORDERS — Cabeceras de pedido

## Propósito

Registra cada pedido realizado por un cliente, con fecha, estado, prioridad, responsable administrativo e importe total informado en origen.

## Granularidad y claves

- **Granularidad:** una fila por pedido.
- **Clave primaria:** `o_orderkey`.
- **Clave externa:** `o_custkey` → `CUSTOMER.c_custkey`.
- **Relación descendente:** `LINEITEM.l_orderkey` → `ORDERS.o_orderkey` (un pedido puede tener varias líneas).

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `o_orderstatus` | Estado general del pedido; distinto del estado de una línea. |
| `o_totalprice` | Total del pedido registrado por la fuente. |
| `o_orderdate` | Fecha en que se realizó el pedido. |
| `o_orderpriority` | Prioridad asignada al pedido. |
| `o_clerk` | Identificador textual del agente o empleado. |
| `o_shippriority` | Prioridad de expedición. |
| `o_comment` | Observaciones libres. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__orders`, aporta el contexto de cliente y pedido a `int_order_lines` y posibilita análisis por fecha, prioridad y estado.

## Consideraciones

- `o_totalprice` está al nivel de **pedido**: al unirlo con las líneas se repite en cada una. No debe sumarse tras esa unión sin deduplicar por pedido.
- El estado de cabecera no sustituye a `l_linestatus` ni a `l_returnflag`.
- `o_orderdate` no es la fecha de envío o recepción de la mercancía.

{% enddocs %}

{% docs src_tpch_sf10__part_description %}

# PART — Catálogo de productos

## Propósito

Catálogo maestro de artículos de TPC-H. Contiene atributos descriptivos, fabricante, marca, clasificación y precio de referencia del producto.

## Granularidad y claves

- **Granularidad:** una fila por producto.
- **Clave primaria:** `p_partkey`.
- Se relaciona con `LINEITEM.l_partkey` y `PARTSUPP.ps_partkey`.

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `p_name` | Denominación descriptiva del producto. |
| `p_mfgr` | Fabricante. |
| `p_brand` | Marca. |
| `p_type` | Tipo o clasificación del artículo. |
| `p_size` | Tamaño dentro de la nomenclatura TPC-H. |
| `p_container` | Tipo de contenedor o embalaje. |
| `p_retailprice` | Precio minorista de referencia, no precio efectivo de cada operación. |
| `p_comment` | Observaciones de texto libre. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__parts` y `dim_parts`. Facilita el desglose de las ventas por marca, fabricante, tipo y tamaño; puede cruzarse con proveedores mediante `PARTSUPP`.

## Consideraciones

- `p_retailprice` no debe utilizarse para reconstruir ingresos reales; las líneas de pedido tienen importes y descuentos específicos.
- Un producto puede tener varios proveedores, por lo que unir directamente `PART` a `PARTSUPP` multiplica sus filas.
- Las clasificaciones son propias de los datos de ejemplo; no equivalen automáticamente a una jerarquía corporativa de categorías.

{% enddocs %}

{% docs src_tpch_sf10__partsupp_description %}

# PARTSUPP — Oferta producto-proveedor

## Propósito

Tabla puente que representa qué proveedores pueden suministrar cada producto. Incluye disponibilidad y coste de suministro para cada combinación.

## Granularidad y claves

- **Granularidad:** una fila por combinación de producto y proveedor.
- **Clave compuesta:** (`ps_partkey`, `ps_suppkey`). Ninguna de las dos columnas identifica por sí sola un registro único.
- **Relaciones:** `ps_partkey` → `PART.p_partkey`; `ps_suppkey` → `SUPPLIER.s_suppkey`.
- La misma pareja aparece en las líneas de pedido a través de (`l_partkey`, `l_suppkey`).

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `ps_partkey` | Producto ofertado. |
| `ps_suppkey` | Proveedor del producto. |
| `ps_availqty` | Cantidad disponible indicada por la fuente para esa pareja. |
| `ps_supplycost` | Coste unitario de suministro para la pareja producto-proveedor. |
| `ps_comment` | Información complementaria. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__partsupps`, se enriquece en `int_part_supplier` y contribuye a `fct_inventory` para análisis de disponibilidad, costes e indicadores de margen potencial.

## Consideraciones

- No representa transacciones de venta ni movimientos históricos de almacén: es una disponibilidad de referencia del conjunto de datos.
- El coste es específico de cada proveedor, incluso cuando se trata del mismo producto.
- Para evitar uniones de muchos a muchos, la asociación con `LINEITEM` debe hacerse con las dos claves.

{% enddocs %}

{% docs src_tpch_sf10__region_description %}

# REGION — Regiones geográficas

## Propósito

Catálogo de las grandes regiones utilizadas para agrupar países en el conjunto de datos TPC-H.

## Granularidad y claves

- **Granularidad:** una fila por región.
- **Clave primaria:** `r_regionkey`.
- **Relación descendente:** `NATION.n_regionkey` → `REGION.r_regionkey` (varios países pueden pertenecer a una región).

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `r_regionkey` | Identificador de región. |
| `r_name` | Nombre de la región. |
| `r_comment` | Información complementaria. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__regions` y se combina con `NATION` en `int_geography`. Permite agrupar métricas de clientes, proveedores y pedidos por una geografía de nivel superior.

## Consideraciones

Las regiones son agrupaciones propias de TPC-H, no divisiones administrativas oficiales ni una cobertura exhaustiva de todos los países del mundo.

{% enddocs %}

{% docs src_tpch_sf10__supplier_description %}

# SUPPLIER — Proveedores

## Propósito

Maestro de proveedores del sistema TPC-H, con datos de contacto, localización geográfica y saldo de cuenta.

## Granularidad y claves

- **Granularidad:** una fila por proveedor.
- **Clave primaria:** `s_suppkey`.
- **Clave externa:** `s_nationkey` → `NATION.n_nationkey`.
- Se relaciona con `PARTSUPP.ps_suppkey` y `LINEITEM.l_suppkey`.

## Campos relevantes

| Campo | Interpretación |
|---|---|
| `s_name`, `s_address`, `s_phone` | Nombre y contacto del proveedor. |
| `s_nationkey` | País al que se asigna el proveedor. |
| `s_acctbal` | Saldo de cuenta de origen, que puede ser negativo o positivo. |
| `s_comment` | Observaciones libres. |

## Uso en el proyecto

Alimenta `stg_tpch_sf10__suppliers` y se utiliza para enriquecer `int_part_supplier` y los modelos analíticos de proveedores. Posibilita analizar la oferta por país y región, junto con disponibilidad y coste.

## Consideraciones

- Un proveedor puede suministrar múltiples productos; el precio y la cantidad disponibles pertenecen a `PARTSUPP`, no a esta tabla.
- `s_acctbal` no representa por sí mismo el coste de compra ni el volumen de suministros.
- Los nombres y direcciones son descriptores; las relaciones deben construirse mediante identificadores.

{% enddocs %}
