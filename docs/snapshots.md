{% docs snap_customers_description %}

# Snapshot - Customers

## Descripción

Snapshot que conserva el histórico de los clientes
del sistema TPC-H mediante una estrategia de
historización SCD tipo 2.

Permite registrar diferentes versiones de los atributos
de cada cliente a lo largo del tiempo.

## Origen

`stg_tpch_sf10__customers`

## Granularidad

Una fila por versión histórica de cada cliente.

Un mismo `customer_id` puede aparecer varias veces,
pero cada versión se identifica de forma única
mediante `dbt_scd_id`.

## Estrategia de historización

Se utiliza la estrategia `check` con `check_cols: all`.

En cada ejecución, dbt compara los valores actuales
de las columnas con los de la versión vigente.

Cuando detecta cambios, cierra la versión anterior
y registra una nueva versión del cliente.

## Clave de negocio

`customer_id`

Esta clave permite identificar al mismo cliente
a través de sus diferentes versiones históricas.

## Gestión de eliminaciones

Se utiliza `hard_deletes: new_record`.

Cuando un cliente desaparece de la fuente,
dbt registra una nueva versión que indica
su eliminación mediante `dbt_is_deleted`.

Esto permite conservar el historial de eliminaciones
sin perder los registros anteriores.

## Metadatos históricos

- `dbt_scd_id`: identificador único de cada versión.
- `dbt_updated_at`: momento de actualización registrado por dbt.
- `dbt_valid_from`: inicio de vigencia de la versión.
- `dbt_valid_to`: final de vigencia de la versión.
- `dbt_is_deleted`: indicador de eliminación del registro.

Las versiones vigentes tienen `dbt_valid_to` igual a NULL.

## Calidad de datos

Se comprueba:

- Ausencia de identificadores de cliente nulos.
- Unicidad de los clientes entre las versiones vigentes.
- Unicidad de `dbt_scd_id`.
- Ausencia de valores nulos en los metadatos obligatorios.
- Consistencia de los intervalos temporales.
- Ausencia de solapamientos entre versiones de un mismo cliente.
- Validez de los indicadores de eliminación.

## Utilización analítica

El snapshot permite recuperar el estado histórico
de los atributos de un cliente.

También proporciona la base necesaria para construir
una dimensión histórica de clientes en el futuro.

El snapshot no sustituye directamente a `dim_customers`,
que representa la información actual utilizada
en el modelo analítico.

{% enddocs %}


{% docs snap_parts_description %}

# Snapshot - Parts

## Descripción

Snapshot que conserva las diferentes versiones
históricas de los productos del sistema TPC-H.

Permite registrar cambios en sus características
comerciales y descriptivas, incluyendo precios,
marcas, fabricantes y clasificaciones.

Se implementa mediante una estrategia SCD tipo 2.

## Origen

`stg_tpch_sf10__parts`

## Granularidad

Una fila por versión histórica de cada producto.

Un mismo `part_id` puede tener varias versiones,
identificadas individualmente mediante `dbt_scd_id`.

## Estrategia de historización

Se utiliza la estrategia `check` con `check_cols: all`.

dbt compara todos los atributos del producto
con los correspondientes a su versión vigente.

Cuando detecta una modificación, registra una nueva
versión y establece el final de vigencia
de la versión anterior.

## Clave de negocio

`part_id`

Permite relacionar las diferentes versiones
históricas de un mismo producto.

## Gestión de eliminaciones

Se utiliza `hard_deletes: new_record`.

Cuando un producto desaparece de la fuente,
dbt registra una versión que identifica
su eliminación mediante `dbt_is_deleted`.

Las versiones históricas anteriores se conservan.

## Metadatos históricos

- `dbt_scd_id`: identificador único de cada versión.
- `dbt_updated_at`: momento de actualización registrado por dbt.
- `dbt_valid_from`: inicio de vigencia de la versión.
- `dbt_valid_to`: final de vigencia de la versión.
- `dbt_is_deleted`: indicador de eliminación del producto.

Las versiones vigentes tienen `dbt_valid_to` igual a NULL.

## Calidad de datos

Se comprueba:

- Ausencia de identificadores de producto nulos.
- Unicidad de las versiones vigentes por producto.
- Unicidad de `dbt_scd_id`.
- Consistencia de los intervalos temporales.
- Ausencia de solapamientos históricos.
- Validez de los indicadores de eliminación.

## Utilización analítica

El snapshot permite consultar las características
de un producto en diferentes momentos históricos.

Por ejemplo, permite conocer el precio de catálogo
registrado para un producto en una fecha determinada.

También proporciona la base para construir
una dimensión histórica de productos en el futuro.

{% enddocs %}


{% docs snap_partsupps_description %}

# Snapshot - Partsupps

## Descripción

Snapshot que conserva el histórico de las relaciones
entre productos y proveedores.

Permite registrar cambios en las cantidades disponibles,
costes de suministro y demás atributos asociados
a cada relación comercial.

Se implementa mediante una estrategia SCD tipo 2.

## Origen

`stg_tpch_sf10__partsupps`

## Granularidad

Una fila por versión histórica de cada combinación
de producto y proveedor.

La combinación de `part_id` y `supplier_id`
identifica la relación de suministro.

Cada versión histórica se identifica mediante
`dbt_scd_id`.

## Estrategia de historización

Se utiliza la estrategia `check` con `check_cols: all`.

En cada ejecución, dbt compara los atributos
de cada combinación producto-proveedor
con los de su versión vigente.

Cuando detecta cambios, cierra la versión anterior
y registra una nueva versión histórica.

## Clave de negocio

La clave está formada por:

- `part_id`
- `supplier_id`

Esta combinación permite identificar una misma
relación de suministro a lo largo del tiempo.

## Gestión de eliminaciones

Se utiliza `hard_deletes: new_record`.

Cuando una combinación producto-proveedor
desaparece de la fuente, dbt registra
una nueva versión que indica su eliminación.

Las versiones anteriores permanecen disponibles.

## Metadatos históricos

- `dbt_scd_id`: identificador único de cada versión.
- `dbt_updated_at`: momento de actualización registrado por dbt.
- `dbt_valid_from`: inicio de vigencia de la versión.
- `dbt_valid_to`: final de vigencia de la versión.
- `dbt_is_deleted`: indicador de eliminación de la relación.

Las versiones vigentes tienen `dbt_valid_to` igual a NULL.

## Calidad de datos

Se comprueba:

- Ausencia de valores nulos en las claves de negocio.
- Unicidad de las combinaciones producto-proveedor vigentes.
- Unicidad de `dbt_scd_id`.
- Consistencia de los intervalos temporales.
- Ausencia de solapamientos entre versiones históricas.
- Validez de los indicadores de eliminación.

## Utilización analítica

El snapshot permite analizar la evolución histórica
de las existencias y los costes de suministro.

Puede utilizarse para conocer las cantidades
y costes registrados en una fecha determinada.

También proporciona la base para construir
modelos históricos de inventario en el futuro.

El snapshot conserva los estados observados
durante sus ejecuciones, por lo que no garantiza
registrar cambios que ocurran y se reviertan
entre dos ejecuciones consecutivas.

{% enddocs %}