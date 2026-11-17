{% docs dim_customers_description %}

# Dimensión de clientes

## Descripción

Dimensión analítica que contiene información identificativa, comercial,
geográfica y financiera de los clientes.

Se construye a partir de `int_customers` y permite analizar las operaciones
comerciales según las características de cada cliente.

## Granularidad

Una fila por cliente, identificado mediante `customer_id`.

## Atributos

- Identificación y nombre del cliente.
- Dirección y teléfono.
- Segmento de mercado.
- País y región geográfica.
- Saldo de la cuenta.
- Indicadores de saldo positivo y negativo.

## Reglas de negocio

El modelo conserva los indicadores calculados en `int_customers`:

- `is_negative_balance`: verdadero cuando `account_balance < 0`.
- `is_positive_balance`: verdadero cuando `account_balance > 0`.

Ambos indicadores son falsos cuando el saldo es igual a cero.

## Relaciones

La dimensión se relaciona con `fct_order_lines` mediante `customer_id`.

## Materialización

Vista en Snowflake.

## Calidad de datos

Se valida la unicidad del identificador del cliente y la ausencia
de valores nulos en los principales atributos.

{% enddocs %}


{% docs dim_parts_description %}

# Dimensión de productos

## Descripción

Dimensión analítica que contiene los atributos descriptivos
y comerciales de los productos.

Se construye a partir de `stg_tpch_sf10__parts` y proporciona
información para el análisis de ventas e inventario.

## Granularidad

Una fila por producto, identificado mediante `part_id`.

## Atributos

- Identificador y nombre del producto.
- Fabricante.
- Marca comercial.
- Tipo de producto.
- Tamaño.
- Tipo de embalaje.
- Precio de catálogo.

## Transformaciones

Se seleccionan los atributos necesarios para el análisis,
sin realizar agregaciones ni cálculos adicionales.

## Relaciones

La dimensión se relaciona mediante `part_id` con:

- `fct_order_lines`.
- `fct_inventory`.

## Materialización

Vista en Snowflake.

## Calidad de datos

Se valida la unicidad del identificador del producto
y la ausencia de valores nulos en los principales atributos.

{% enddocs %}


{% docs dim_suppliers_description %}

# Dimensión de proveedores

## Descripción

Dimensión analítica que contiene información identificativa,
geográfica y financiera de los proveedores.

Se construye a partir de `int_suppliers`, incorporando
la información de países y regiones.

## Granularidad

Una fila por proveedor, identificado mediante `supplier_id`.

## Atributos

- Identificador y nombre del proveedor.
- País y región geográfica.
- Dirección y teléfono.
- Saldo de la cuenta.
- Información descriptiva adicional.

## Transformaciones

Se seleccionan los atributos del proveedor previamente
enriquecidos con información geográfica.

No se realizan agregaciones ni cálculos adicionales.

## Relaciones

La dimensión se relaciona mediante `supplier_id` con:

- `fct_order_lines`.
- `fct_inventory`.

## Materialización

Vista en Snowflake.

## Calidad de datos

Se valida la unicidad del identificador del proveedor,
la integridad referencial geográfica y la ausencia de
valores nulos en los atributos obligatorios.

{% enddocs %}


{% docs dim_date_description %}

# Dimensión de tiempo

## Descripción

Dimensión calendario que proporciona una estructura temporal
común para el análisis de pedidos, envíos y recepciones.

Se construye a partir de `int_date`, que genera un calendario
continuo utilizando las fechas disponibles en los pedidos.

## Granularidad

Una fila por día natural, identificado mediante `date_key`.

## Atributos

- Clave temporal en formato YYYYMMDD.
- Fecha completa.
- Año y trimestre.
- Mes y nombre del mes.
- Semana ISO.
- Día del mes y de la semana.
- Indicador de fin de semana.
- Primer y último día del mes.

## Transformaciones

Se seleccionan los atributos temporales generados
en `int_date`, sin realizar transformaciones adicionales.

## Relaciones

La dimensión se relaciona con `fct_order_lines`
mediante cuatro claves temporales:

- `order_date_key`.
- `ship_date_key`.
- `commit_date_key`.
- `receipt_date_key`.

Estas relaciones permiten analizar distintas fechas
de un mismo proceso comercial utilizando
una dimensión temporal común.

## Materialización

Vista en Snowflake.

## Calidad de datos

Se valida la unicidad y ausencia de valores nulos
en `date_key` y `date_day`.

{% enddocs %}


{% docs fct_order_lines_description %}

# Tabla de hechos de líneas de pedido

## Descripción

Tabla de hechos que contiene el detalle de las líneas
de pedido con métricas económicas, logísticas y temporales.

Se construye a partir de `int_order_lines` y constituye
el principal modelo para el análisis de las operaciones comerciales.

## Granularidad

Una fila por línea de pedido, identificada mediante `order_line_id`.

La clave procede de la combinación de `order_id`
y `line_number`.

## Dimensiones relacionadas

- `dim_customers`, mediante `customer_id`.
- `dim_parts`, mediante `part_id`.
- `dim_suppliers`, mediante `supplier_id`.
- `dim_date`, mediante las cuatro claves temporales.

## Métricas económicas

### Cantidad

`quantity`

Número de unidades del producto incluidas en la línea de pedido.

### Importe bruto

`extended_price`

Importe de la línea antes de aplicar descuentos e impuestos.

### Descuento

`discount_amount = ROUND(extended_price * discount_percentage, 2)`

Importe del descuento aplicado a la línea.

### Importe neto

`net_amount = ROUND(extended_price * (1 - discount_percentage), 2)`

Importe después del descuento y antes de impuestos.

### Importe total

`total_amount = ROUND(extended_price * (1 - discount_percentage) * (1 + tax_rate), 2)`

Importe después del descuento e incluyendo impuestos.

## Métricas logísticas

### Tiempo hasta el envío

`shipping_lead_days = DATEDIFF('day', order_date, ship_date)`

### Tiempo hasta la recepción

`delivery_lead_days = DATEDIFF('day', order_date, receipt_date)`

### Duración del transporte

`delivery_days = DATEDIFF('day', ship_date, receipt_date)`

### Diferencia respecto a la fecha comprometida

`shipping_delay_days = DATEDIFF('day', commit_date, receipt_date)`

Los valores positivos indican retraso respecto
a la fecha comprometida.

### Entrega tardía

`is_late_delivery = receipt_date > commit_date`

### Devolución

`is_returned = return_flag = 'R'`

## Consideraciones analíticas

El modelo permite analizar importes y cantidades
al nivel de línea de pedido.

Para contar pedidos distintos debe utilizarse
`COUNT(DISTINCT order_id)`, ya que un pedido
puede contener varias líneas.

Las métricas monetarias representan importes
de las líneas de pedido, no necesariamente
ingresos reconocidos contablemente.

## Materialización

Tabla física en Snowflake.

Se utiliza esta materialización para facilitar
la consulta de las métricas comerciales y logísticas.

## Calidad y observabilidad

Se aplican pruebas de unicidad, ausencia de valores nulos
e integridad referencial con las dimensiones.

También se utilizan las siguientes pruebas de Elementary:

- `volume_anomalies`.
- `schema_changes`.
- `all_columns_anomalies`, con seguimiento de valores
  nulos y valores iguales a cero.

{% enddocs %}


{% docs fct_inventory_description %}

# Tabla de hechos de inventario

## Descripción

Tabla de hechos que contiene información sobre
existencias, costes y rentabilidad potencial
por combinación de producto y proveedor.

Se construye a partir de `int_part_supplier`.

## Granularidad

Una fila por combinación de producto y proveedor,
identificada mediante `part_supplier_id`.

## Dimensiones relacionadas

- `dim_parts`, mediante `part_id`.
- `dim_suppliers`, mediante `supplier_id`.

## Métricas de inventario

### Cantidad disponible

`available_quantity`

Número de unidades disponibles del producto
para el proveedor correspondiente.

### Valor del inventario

`inventory_value = ROUND(supply_cost * available_quantity, 2)`

Valoración de las existencias a coste de suministro.

### Diferencia entre precio y coste

`price_cost_difference = ROUND(retail_price - supply_cost, 2)`

Diferencia unitaria entre el precio de catálogo
y el coste de suministro.

## Métricas de rentabilidad potencial

### Ingresos potenciales

`potential_revenue = ROUND(retail_price * available_quantity, 2)`

Importe teórico de vender todas las unidades disponibles
al precio de catálogo.

### Beneficio bruto potencial

`potential_gross_profit = ROUND((retail_price - supply_cost) * available_quantity, 2)`

Beneficio bruto teórico derivado de vender
todas las existencias disponibles.

### Margen potencial

`potential_margin_pct`

Porcentaje calculado mediante la macro `calculate_percentage`,
utilizando la diferencia entre precio y coste
respecto al precio de catálogo.

### Markup potencial

`potential_markup_pct`

Porcentaje calculado mediante la macro `calculate_percentage`,
utilizando la diferencia entre precio y coste
respecto al coste de suministro.

### Indicador de falta de existencias

`is_out_of_stock = available_quantity = 0`

Identifica las combinaciones producto-proveedor
sin unidades disponibles.

## Consideraciones analíticas

Las métricas de ingresos y beneficios son estimaciones potenciales.

No representan ventas realizadas ni beneficios contabilizados.

El inventario corresponde a las cantidades disponibles
en los datos utilizados para construir el modelo.

No representa un histórico de existencias.

Los porcentajes de margen y markup no deben agregarse
mediante una suma simple. Para calcular porcentajes
agregados deben utilizarse las magnitudes económicas
correspondientes.

## Materialización

Tabla física en Snowflake.

## Calidad y observabilidad

Se aplican pruebas de unicidad, ausencia de valores nulos
e integridad referencial con las dimensiones.

También se utilizan las siguientes pruebas de Elementary:

- `volume_anomalies`.
- `schema_changes`.

{% enddocs %}