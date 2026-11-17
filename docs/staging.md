{% docs stg_tpch_sf10__customers_description %}

# Staging - Customers

## Descripción

Modelo de preparación de los datos de clientes procedentes de
`TPCH_SF10.CUSTOMER`.

Su finalidad es estandarizar los nombres de las columnas originales
y proporcionar una estructura homogénea para su utilización en
las capas posteriores del proyecto.

Contiene información identificativa, geográfica, comercial
y financiera de los clientes.

## Granularidad

Una fila por cliente, identificado mediante `customer_id`.

## Transformaciones

- Renombrado de las columnas originales para mejorar su legibilidad.
- Conservación de los atributos identificativos y comerciales.
- Estandarización del identificador geográfico mediante `nation_id`.
- Preparación de los datos para su integración con pedidos y geografía.

No se realizan agregaciones ni modificaciones de los valores originales.

## Calidad de datos

Se aplican las siguientes validaciones:

- `unique`: comprueba la unicidad de `customer_id`.
- `not_null`: garantiza que todos los clientes tienen identificador.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}


{% docs stg_tpch_sf10__lineitems_description %}

# Staging - Lineitems

## Descripción

Modelo de preparación de las líneas de pedido procedentes de
`TPCH_SF10.LINEITEM`.

Contiene información sobre productos, proveedores, cantidades,
precios, descuentos, impuestos y fechas relacionadas con
el proceso logístico.

Constituye una de las principales fuentes de información
para los cálculos económicos realizados en la capa intermediate.

## Granularidad

Una fila por línea de pedido.

Cada registro se identifica mediante la combinación de:

- `order_id`
- `line_number`

Esta combinación constituye la clave de negocio del modelo.

## Transformaciones

- Renombrado de las columnas originales.
- Estandarización de identificadores de pedidos, productos y proveedores.
- Renombrado de los atributos económicos y logísticos.
- Conservación de las fechas de envío, compromiso y recepción.
- Preparación de los datos para su integración con los pedidos.

Los valores económicos se conservan sin aplicar cálculos
de descuentos o impuestos en esta capa.

## Materialización

El modelo utiliza materialización incremental mediante
la estrategia `MERGE` de Snowflake.

La clave única está formada por:

`order_id`, `line_number`

Durante una ejecución incremental, los registros que coinciden
con la clave definida pueden actualizarse y los nuevos
pueden insertarse.

El modelo no incorpora un filtro incremental adicional,
por lo que procesa los registros disponibles en la fuente
durante cada ejecución.

## Calidad de datos

Se aplican las siguientes validaciones:

- Unicidad de la combinación `order_id` y `line_number`.
- Ausencia de valores nulos en `order_id`.
- Ausencia de valores nulos en `line_number`.
- Ausencia de valores nulos en `discount_percentage`.
- Validación de que `discount_percentage` se encuentra entre 0 y 1.

{% enddocs %}


{% docs stg_tpch_sf10__nations_description %}

# Staging - Nations

## Descripción

Modelo de preparación de los países procedentes de
`TPCH_SF10.NATION`.

Proporciona información geográfica para relacionar
clientes y proveedores con sus respectivos países.

## Granularidad

Una fila por país, identificado mediante `nation_id`.

## Transformaciones

- Renombrado de los identificadores originales.
- Estandarización del nombre del país mediante `nation_name`.
- Conservación de la relación con las regiones mediante `region_id`.
- Preparación de los datos para su integración con el modelo
  intermedio de geografía.

No se realizan agregaciones ni modificaciones
de los valores originales.

## Calidad de datos

Se aplican las siguientes validaciones:

- `unique`: garantiza la unicidad de `nation_id`.
- `not_null`: garantiza que todos los países tienen identificador.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}


{% docs stg_tpch_sf10__orders_description %}

# Staging - Orders

## Descripción

Modelo de preparación de los pedidos procedentes de
`TPCH_SF10.ORDERS`.

Contiene información comercial y administrativa
de los pedidos realizados por los clientes.

Incluye identificadores, fechas, estados,
prioridades e importes.

## Granularidad

Una fila por pedido, identificado mediante `order_id`.

## Transformaciones

- Renombrado de los identificadores de pedido y cliente.
- Estandarización de los atributos comerciales.
- Renombrado de las columnas de fecha, estado y prioridad.
- Conservación del importe total registrado en la fuente.
- Preparación de los datos para su integración con las líneas de pedido.

Los valores originales se conservan sin realizar
agregaciones ni cálculos económicos adicionales.

## Calidad de datos

Se aplican las siguientes validaciones:

- Unicidad de `order_id`.
- Ausencia de valores nulos en `order_id`.
- Ausencia de valores nulos en `customer_id`.
- Integridad referencial entre pedidos y clientes.
- Ausencia de valores nulos en `order_date`.
- Validación de que `order_date` es igual o posterior
  al 1 de enero de 1992.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}


{% docs stg_tpch_sf10__parts_description %}

# Staging - Parts

## Descripción

Modelo de preparación del catálogo de productos procedente
de `TPCH_SF10.PART`.

Contiene información descriptiva y comercial de los productos,
incluyendo fabricante, marca, tipo, tamaño, embalaje y precio.

## Granularidad

Una fila por producto, identificado mediante `part_id`.

## Transformaciones

- Renombrado del identificador del producto.
- Estandarización de los atributos descriptivos.
- Renombrado de las columnas comerciales.
- Conservación del precio de venta de referencia.
- Preparación de los datos para su utilización
  en las dimensiones y modelos de inventario.

No se realizan agregaciones ni modificaciones
de los valores originales.

## Calidad de datos

Se aplican las siguientes validaciones:

- `unique`: garantiza la unicidad de `part_id`.
- `not_null`: garantiza que todos los productos tienen identificador.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}


{% docs stg_tpch_sf10__partsupps_description %}

# Staging - Partsupps

## Descripción

Modelo de preparación de las relaciones entre productos
y proveedores procedentes de `TPCH_SF10.PARTSUPP`.

Contiene información sobre disponibilidad de productos
y costes de suministro para cada proveedor.

Es una de las principales fuentes utilizadas
para construir los modelos de inventario.

## Granularidad

Una fila por combinación de producto y proveedor.

Cada registro se identifica mediante:

- `part_id`
- `supplier_id`

Esta combinación constituye la clave de negocio del modelo.

## Transformaciones

- Renombrado de los identificadores de producto y proveedor.
- Estandarización de la cantidad disponible mediante
  `available_quantity`.
- Renombrado del coste de suministro mediante `supply_cost`.
- Conservación de los atributos originales de inventario.
- Preparación de los datos para los cálculos de inventario
  realizados en intermediate.

No se realizan agregaciones ni cálculos
sobre las cantidades o costes originales.

## Calidad de datos

Se aplican las siguientes validaciones:

- Unicidad de la combinación `part_id` y `supplier_id`.
- Ausencia de valores nulos en `part_id`.
- Ausencia de valores nulos en `supplier_id`.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}


{% docs stg_tpch_sf10__regions_description %}

# Staging - Regions

## Descripción

Modelo de preparación de las regiones geográficas procedentes
de `TPCH_SF10.REGION`.

Permite clasificar los países en diferentes regiones
para facilitar el análisis geográfico de las operaciones.

## Granularidad

Una fila por región, identificada mediante `region_id`.

## Transformaciones

- Renombrado del identificador de la región.
- Estandarización del nombre mediante `region_name`.
- Conservación de la información descriptiva.
- Preparación de los datos para su integración
  con los países.

No se realizan agregaciones ni modificaciones
de los valores originales.

## Calidad de datos

Se aplican las siguientes validaciones:

- `unique`: garantiza la unicidad de `region_id`.
- `not_null`: garantiza que todas las regiones tienen identificador.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}


{% docs stg_tpch_sf10__suppliers_description %}

# Staging - Suppliers

## Descripción

Modelo de preparación de los proveedores procedentes
de `TPCH_SF10.SUPPLIER`.

Contiene información identificativa, geográfica
y financiera de los proveedores.

Permite relacionar los proveedores con los productos,
el inventario y las regiones geográficas.

## Granularidad

Una fila por proveedor, identificado mediante `supplier_id`.

## Transformaciones

- Renombrado del identificador del proveedor.
- Estandarización de los nombres de las columnas.
- Conservación de los atributos identificativos y financieros.
- Renombrado de la referencia geográfica mediante `nation_id`.
- Preparación de los datos para su integración
  con productos, inventario y geografía.

No se realizan agregaciones ni modificaciones
de los valores originales.

## Calidad de datos

Se aplican las siguientes validaciones:

- `unique`: garantiza la unicidad de `supplier_id`.
- `not_null`: garantiza que todos los proveedores tienen identificador.

## Materialización

El modelo se materializa como tabla física en Snowflake.

{% enddocs %}