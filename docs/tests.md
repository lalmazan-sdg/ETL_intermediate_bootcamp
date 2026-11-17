{% docs assert_inventory_calculations_description %}

# Test - Inventory Calculations

## Descripción

Test singular que comprueba la consistencia de las métricas
de inventario calculadas en `int_part_supplier`.

Su finalidad es garantizar que los importes y los indicadores
de inventario cumplen las reglas de negocio definidas.

## Modelo validado

`int_part_supplier`

## Validaciones

### Valor del inventario

```sql
ROUND(supply_cost * available_quantity, 2)
```

Comprueba que `inventory_value` corresponde al coste total
de las unidades disponibles.

### Diferencia entre precio y coste

```sql
ROUND(retail_price - supply_cost, 2)
```

Comprueba que `price_cost_difference` representa
la diferencia unitaria entre precio y coste.

### Ingresos potenciales

```sql
ROUND(retail_price * available_quantity, 2)
```

Comprueba que `potential_revenue` corresponde
al valor de venta teórico de las existencias.

### Beneficio bruto potencial

```sql
ROUND((retail_price - supply_cost) * available_quantity, 2)
```

Comprueba la consistencia de `potential_gross_profit`.

### Indicador de existencias

```sql
available_quantity = 0
```

Comprueba que `is_out_of_stock` identifica correctamente
las combinaciones producto-proveedor sin existencias.

## Funcionamiento

El test recalcula las métricas esperadas
y las compara con los valores del modelo.

Utiliza `IS DISTINCT FROM` para detectar diferencias,
incluyendo las relacionadas con valores NULL.

## Resultado

Devuelve los registros que presentan inconsistencias
en alguna de las cinco validaciones.

El test se supera cuando no devuelve registros.

{% enddocs %}


{% docs assert_order_lines_amounts_description %}

# Test - Order Lines Amounts

## Descripción

Test singular que verifica la consistencia
de los importes económicos calculados
en el modelo `int_order_lines`.

## Modelo validado

`int_order_lines`

## Validaciones

### Importe del descuento

```sql
ROUND(extended_price * discount_percentage, 2)
```

Comprueba que `discount_amount` se calcula correctamente.

### Importe neto

```sql
ROUND(extended_price * (1 - discount_percentage), 2)
```

Comprueba que `net_amount` representa el importe
después del descuento y antes de impuestos.

### Importe total

```sql
ROUND(
    extended_price * (1 - discount_percentage) * (1 + tax_rate),
    2
)
```

Comprueba que `total_amount` incluye correctamente
el descuento y los impuestos.

## Funcionamiento

El test recalcula los tres importes
y los compara con los valores almacenados.

Utiliza `IS DISTINCT FROM` para identificar
diferencias entre los valores reales y esperados.

Los resultados de las tres comprobaciones
se combinan mediante `UNION ALL`.

## Resultado

Cada registro devuelto identifica:

- `order_line_id`: línea de pedido afectada.
- `failed_metric`: métrica incorrecta.
- `actual_value`: valor obtenido.
- `expected_value`: valor esperado.

El test se supera cuando no devuelve registros.

{% enddocs %}


{% docs assert_order_lines_consistency_description %}

# Test - Order Lines Consistency

## Descripción

Test singular que valida la coherencia
de las métricas logísticas calculadas
en el modelo `int_order_lines`.

## Modelo validado

`int_order_lines`

## Validaciones

### Consistencia de los tiempos de entrega

Comprueba que el tiempo total desde el pedido
hasta la recepción coincide con la suma
del tiempo hasta el envío y la duración del transporte.

```sql
delivery_lead_days = shipping_lead_days + delivery_days
```

### Consistencia del indicador de retraso

Comprueba que el indicador de entrega tardía
coincide con la diferencia entre la fecha comprometida
y la fecha de recepción.

```sql
is_late_delivery = (shipping_delay_days > 0)
```

## Funcionamiento

El test utiliza `IS DISTINCT FROM`
para comparar los valores calculados.

Esta comparación permite identificar inconsistencias
incluso cuando existen valores NULL.

## Resultado

Devuelve las líneas de pedido que incumplen
alguna de las condiciones.

El test se supera cuando no devuelve registros.

{% enddocs %}


{% docs assert_order_part_supplier_relationship_description %}

# Test - Order Part Supplier Relationship

## Descripción

Test singular que valida la integridad referencial
entre las líneas de pedido y las relaciones
de suministro de productos.

## Modelos validados

- `int_order_lines`
- `int_part_supplier`

## Regla de negocio

Cada combinación de producto y proveedor
presente en una línea de pedido debe existir
en el modelo de relaciones de suministro.

La relación se establece mediante:

- `part_id`
- `supplier_id`

## Funcionamiento

Se realiza un `LEFT JOIN` desde `int_order_lines`
hacia `int_part_supplier`.

La unión utiliza conjuntamente los identificadores
de producto y proveedor.

El test identifica las líneas para las que
no existe una relación de suministro correspondiente.

## Resultado

Devuelve:

- `order_line_id`
- `part_id`
- `supplier_id`

El test se supera cuando todas las líneas
tienen una relación producto-proveedor válida.

{% enddocs %}


{% docs assert_generate_composite_key_description %}

# Test - Generate Composite Key

## Descripción

Test singular que valida el funcionamiento
de la macro personalizada `generate_composite_key`.

Su finalidad es comprobar que la macro genera
identificadores compuestos utilizando
el formato esperado.

## Macro validada

`generate_composite_key`

## Casos de prueba

| Primer valor | Segundo valor | Resultado esperado |
|---|---|---|
| 123 | 1 | 123-1 |
| 123 | 2 | 123-2 |
| 456 | 10 | 456-10 |

## Funcionamiento

El test construye un conjunto de datos de prueba
mediante la cláusula SQL `VALUES`.

Posteriormente, ejecuta la macro sobre
las columnas de entrada y compara
los resultados con los valores esperados.

## Validaciones

Se comprueba que:

- Los identificadores se concatenan correctamente.
- Se utiliza un guion como separador.
- Los resultados coinciden con los valores esperados.
- Los resultados no son NULL.

## Resultado

Devuelve los casos en los que el resultado
de la macro es diferente del esperado
o contiene un valor NULL.

El test se supera cuando no devuelve registros.

{% enddocs %}


{% docs assert_date_dimension_coverage_description %}

# Test - Date Dimension Coverage

## Descripción

Test singular que comprueba que la dimensión
de tiempo contiene un calendario continuo,
sin fechas intermedias ausentes.

## Modelo validado

`dim_date`

## Regla de negocio

La cantidad de fechas distintas debe coincidir
con el número de días comprendidos
entre la fecha mínima y máxima del calendario.

## Funcionamiento

Se calculan:

- `min_date`: fecha mínima del calendario.
- `max_date`: fecha máxima del calendario.
- `actual_days`: cantidad de fechas distintas.
- `expected_days`: cantidad esperada de días.

El número esperado se calcula mediante:

```sql
DATEDIFF('day', min_date, max_date) + 1
```

## Validaciones

El test identifica inconsistencias cuando:

- No existen fechas distintas en el calendario.
- La cantidad de fechas distintas no coincide
  con el número de días esperado.

## Resultado

Devuelve los valores mínimo, máximo,
reales y esperados cuando detecta inconsistencias.

El test se supera cuando no devuelve registros.

La unicidad de las fechas se comprueba
mediante los tests definidos en `dim_date`.

{% enddocs %}


{% docs assert_order_lines_reconciliation_description %}

# Test - Order Lines Reconciliation

## Descripción

Test singular que comprueba la conciliación
de los importes económicos entre las capas
intermediate y marts.

Su finalidad es garantizar que la tabla de hechos
conserva correctamente los registros y métricas
procedentes del modelo intermedio.

## Modelos validados

- `int_order_lines`
- `fct_order_lines`

## Granularidad

Una fila por línea de pedido,
identificada mediante `order_line_id`.

## Validaciones

### Integridad de registros

Comprueba que todas las líneas presentes
en intermediate aparecen en la tabla de hechos
y viceversa.

### Importe neto

Comprueba que `net_amount` coincide
entre ambos modelos.

### Importe total

Comprueba que `total_amount` coincide
entre ambos modelos.

## Funcionamiento

Se realiza un `FULL OUTER JOIN`
entre `int_order_lines` y `fct_order_lines`.

La relación se establece mediante `order_line_id`.

El uso de `FULL OUTER JOIN` permite identificar
registros ausentes en cualquiera de los modelos.

Las comparaciones económicas utilizan
`IS DISTINCT FROM` para detectar diferencias
incluyendo valores NULL.

## Clasificación de errores

El test utiliza tres categorías:

### missing_in_intermediate

La línea existe en la tabla de hechos,
pero no en el modelo intermedio.

### missing_in_business

La línea existe en el modelo intermedio,
pero no en la tabla de hechos.

### amount_mismatch

La línea existe en ambos modelos,
pero presenta diferencias en los importes.

## Resultado

Devuelve los identificadores afectados,
los importes de ambos modelos
y el motivo de la inconsistencia.

El test se supera cuando no devuelve registros.

{% enddocs %}