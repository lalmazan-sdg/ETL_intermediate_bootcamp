{% docs int_geography_description %}

# Intermediate - Geography

## Descripción

Modelo que integra la información de países y regiones
procedente de los modelos de staging.

Su finalidad es proporcionar una estructura geográfica
unificada para enriquecer la información de clientes
y proveedores.

## Granularidad

Una fila por país, identificado mediante `nation_id`.

## Transformaciones

Se realiza un `LEFT JOIN` entre:

- `stg_tpch_sf10__nations`
- `stg_tpch_sf10__regions`

La relación se establece mediante `region_id`.

El uso de `LEFT JOIN` permite conservar todos los países,
incluso si alguno no encuentra correspondencia en la tabla
de regiones.

## Resultado

El modelo proporciona:

- Identificador y nombre del país.
- Identificador y nombre de la región.

## Calidad de datos

Se comprueba la unicidad de los países, la ausencia
de valores nulos en los campos geográficos y la integridad
referencial de las regiones.

## Materialización

Vista en Snowflake.

{% enddocs %}


{% docs int_customers_description %}

# Intermediate - Customers

## Descripción

Modelo que enriquece la información de los clientes
con datos geográficos e indicadores derivados de su saldo.

Permite analizar clientes por país, región,
segmento comercial y situación financiera.

## Granularidad

Una fila por cliente, identificado mediante `customer_id`.

## Transformaciones

Se realiza un `LEFT JOIN` entre:

- `stg_tpch_sf10__customers`
- `int_geography`

La relación se establece mediante `nation_id`.

Se conservan los atributos originales del cliente
y se incorporan el nombre del país y de la región.

## Reglas de negocio

Se calculan dos indicadores:

### is_negative_balance

Indica si el cliente presenta un saldo negativo.

```sql
case
    when account_balance < 0 then true
    else false
end
```

### is_positive_balance

Indica si el cliente presenta un saldo positivo.

```sql
case
    when account_balance > 0 then true
    else false
end
```

Cuando el saldo es exactamente cero, ambos indicadores
tienen valor `false`.

## Calidad de datos

Se comprueba:

- Unicidad de `customer_id`.
- Integridad referencial de los países.
- Ausencia de valores nulos en los campos obligatorios.
- Correspondencia entre los indicadores calculados y el saldo real.

## Materialización

Vista en Snowflake.

{% enddocs %}


{% docs int_suppliers_description %}

# Intermediate - Suppliers

## Descripción

Modelo que enriquece la información de los proveedores
con los atributos geográficos de sus países y regiones.

Permite realizar análisis de proveedores por ubicación
geográfica y características financieras.

## Granularidad

Una fila por proveedor, identificado mediante `supplier_id`.

## Transformaciones

Se realiza un `LEFT JOIN` entre:

- `stg_tpch_sf10__suppliers`
- `int_geography`

La relación se establece mediante `nation_id`.

Se conservan los atributos identificativos y financieros
del proveedor y se incorporan los nombres de país y región.

## Calidad de datos

Se comprueba:

- Unicidad de `supplier_id`.
- Ausencia de valores nulos en los campos obligatorios.
- Integridad referencial del identificador del país.

## Materialización

Vista en Snowflake.

{% enddocs %}


{% docs int_part_supplier_description %}

# Intermediate - Part Supplier

## Descripción

Modelo que integra la información de productos y proveedores
para calcular métricas relacionadas con inventario,
costes y rentabilidad potencial.

Constituye la principal fuente de información
para la tabla de hechos de inventario.

## Granularidad

Una fila por combinación de producto y proveedor.

La combinación se identifica mediante `part_supplier_id`,
generada a partir de `part_id` y `supplier_id`.

## Transformaciones

Se realiza un `LEFT JOIN` entre:

- `stg_tpch_sf10__partsupps`
- `stg_tpch_sf10__parts`

La relación se establece mediante `part_id`.

## Reglas de negocio

### Valor del inventario

Representa el coste total de las unidades disponibles.

`inventory_value = supply_cost × available_quantity`

### Diferencia entre precio y coste

Representa la diferencia unitaria entre el precio
de catálogo y el coste de suministro.

`price_cost_difference = retail_price - supply_cost`

### Ingresos potenciales

Representa el importe que se obtendría al vender
todas las unidades disponibles al precio de catálogo.

`potential_revenue = retail_price × available_quantity`

### Beneficio bruto potencial

Representa el beneficio bruto teórico asociado
a la venta de todas las unidades disponibles.

`potential_gross_profit = (retail_price - supply_cost) × available_quantity`

### Margen potencial

Calcula la relación porcentual entre la diferencia
precio-coste y el precio de venta.

`potential_margin_pct = ((retail_price - supply_cost) / retail_price) × 100`

### Markup potencial

Calcula la relación porcentual entre la diferencia
precio-coste y el coste de suministro.

`potential_markup_pct = ((retail_price - supply_cost) / supply_cost) × 100`

Ambos porcentajes se calculan mediante la macro
`calculate_percentage`.

La macro utiliza `NULLIF` para evitar divisiones
por cero y redondea el resultado a dos decimales.

Cuando el denominador es cero, el resultado es NULL.

### Indicador de falta de existencias

`is_out_of_stock = available_quantity = 0`

El indicador identifica las combinaciones
producto-proveedor sin unidades disponibles.

## Consideraciones

Las métricas de ingresos y beneficios son potenciales.

No representan ventas realizadas ni beneficios
contabilizados, sino estimaciones basadas en
las existencias y precios disponibles.

## Calidad de datos

Se comprueba la unicidad de la clave compuesta,
la integridad referencial y la ausencia de valores
nulos en los atributos y métricas obligatorios.

## Materialización

Vista en Snowflake.

{% enddocs %}


{% docs int_order_lines_description %}

# Intermediate - Order Lines

## Descripción

Modelo que integra pedidos y líneas de pedido
para obtener una estructura detallada de operaciones
comerciales con métricas económicas y logísticas.

Es la principal fuente de información
para la tabla de hechos de ventas.

## Granularidad

Una fila por línea de pedido, identificada
mediante `order_line_id`.

La clave se genera a partir de `order_id`
y `line_number` utilizando la macro
`generate_composite_key`.

## Transformaciones

Se realiza un `INNER JOIN` entre:

- `stg_tpch_sf10__orders`
- `stg_tpch_sf10__lineitems`

La relación se establece mediante `order_id`.

El uso de `INNER JOIN` conserva únicamente
las líneas que tienen un pedido correspondiente.

## Métricas económicas

### Importe del descuento

`discount_amount = extended_price × discount_percentage`

### Importe neto

`net_amount = extended_price × (1 - discount_percentage)`

Representa el importe después de aplicar el descuento
y antes de impuestos.

### Importe total

`total_amount = extended_price × (1 - discount_percentage) × (1 + tax_rate)`

Representa el importe después del descuento
e incluyendo los impuestos.

Los tres importes se redondean a dos decimales.

## Métricas logísticas

### Tiempo hasta el envío

`shipping_lead_days = ship_date - order_date`

### Tiempo hasta la recepción

`delivery_lead_days = receipt_date - order_date`

### Duración del transporte

`delivery_days = receipt_date - ship_date`

### Diferencia respecto a la fecha comprometida

`shipping_delay_days = receipt_date - commit_date`

Un resultado positivo indica recepción posterior
a la fecha comprometida.

Un resultado negativo indica recepción anticipada.

### Entrega tardía

`is_late_delivery = receipt_date > commit_date`

### Devolución

`is_returned = return_flag = 'R'`

## Claves temporales

Se generan cuatro claves mediante la macro
`generate_date_key`:

- `order_date_key`
- `ship_date_key`
- `commit_date_key`
- `receipt_date_key`

Estas claves permiten relacionar los acontecimientos
comerciales y logísticos con la dimensión temporal.

## Calidad de datos

Se valida:

- Unicidad de `order_line_id`.
- Integridad referencial de clientes, pedidos, productos y proveedores.
- Ausencia de valores nulos en identificadores y métricas obligatorias.
- Consistencia del importe neto respecto al importe bruto.
- Orden cronológico de las principales fechas logísticas.

## Materialización

Vista en Snowflake.

{% enddocs %}


{% docs int_date_description %}

# Intermediate - Date

## Descripción

Modelo que genera un calendario continuo a partir
de las fechas presentes en las líneas de pedido.

Permite disponer de una estructura temporal centralizada
para el análisis de operaciones comerciales y logísticas.

## Granularidad

Una fila por día natural, identificado mediante `date_key`.

## Origen

El calendario se genera a partir de `int_order_lines`.

Se utilizan las siguientes fechas:

- `order_date`
- `ship_date`
- `commit_date`
- `receipt_date`

## Transformaciones

Se identifica la fecha mínima y máxima disponible
entre los cuatro campos temporales.

A continuación, se utiliza la macro
`dbt_utils.date_spine` para generar
una secuencia continua de días.

La fecha máxima se incrementa en un día
porque el límite superior de `date_spine`
es exclusivo.

## Atributos temporales

Se generan los siguientes atributos:

- Clave de fecha en formato YYYYMMDD.
- Fecha completa.
- Año.
- Trimestre.
- Mes y nombre del mes.
- Semana ISO del año.
- Día del mes.
- Día de la semana según ISO.
- Indicador de fin de semana.
- Primer día del mes.
- Último día del mes.

El indicador `is_weekend` identifica
los sábados y domingos.

## Calidad de datos

Se comprueba la unicidad y ausencia de valores
nulos de las claves temporales.

También se valida la presencia de valores
en los principales atributos del calendario.

## Materialización

Tabla física en Snowflake.

Se utiliza esta materialización porque el calendario
es reutilizado en las consultas temporales
y su contenido se genera mediante una secuencia de fechas.

{% enddocs %}