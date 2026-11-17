# Estrategia de calidad de datos

## Descripción

El proyecto ETL_intermediate_bootcamp incorpora un conjunto de pruebas
automatizadas destinadas a garantizar la integridad, consistencia
y fiabilidad de los datos durante su transformación.

Las validaciones se implementan mediante dbt Core, dbt_utils,
dbt_expectations, Elementary y tests personalizados.

## Tests de integridad

### Unicidad

El test `unique` comprueba que una columna no contiene
valores duplicados.

Se utiliza principalmente para validar las claves primarias
de dimensiones, tablas de hechos y modelos intermedios.

### Valores nulos

El test `not_null` comprueba que las columnas obligatorias
no contienen valores NULL.

Se aplica sobre identificadores, claves de relación
y métricas esenciales.

### Integridad referencial

El test `relationships` comprueba que los identificadores
de una tabla tienen correspondencia en otra.

Se utiliza para verificar las relaciones entre
tablas de hechos, dimensiones y modelos intermedios.

### Valores permitidos

El test `accepted_values` comprueba que una columna
contiene exclusivamente los valores definidos.

Se utiliza para validar los indicadores de eliminación
de los snapshots.

## Tests de claves compuestas

El test `dbt_utils.unique_combination_of_columns`
comprueba la unicidad de una combinación de columnas.

Se utiliza en modelos cuya granularidad depende
de más de un identificador.

Entre ellos:

- Líneas de pedido: `order_id` y `line_number`.
- Relaciones de suministro: `part_id` y `supplier_id`.
- Versiones vigentes de snapshots con claves compuestas.

## Tests de reglas de negocio

### Validaciones mediante expresiones SQL

El test `dbt_utils.expression_is_true` permite comprobar
condiciones específicas sobre los datos.

Se utiliza para validar:

- La consistencia de los importes netos.
- La correspondencia entre saldos e indicadores financieros.
- La coherencia de los intervalos temporales de snapshots.

### Validación de descuentos

Se utiliza `dbt_expectations.expect_column_values_to_be_between`
para comprobar que los descuentos se encuentran entre 0 y 1.

### Validación de fechas

Se utilizan tests de comparación entre columnas
para verificar el orden cronológico de los acontecimientos.

Entre las condiciones comprobadas se encuentran:

- La fecha de envío no es anterior a la fecha del pedido.
- La fecha de recepción no es anterior a la fecha de envío.
- La fecha de recepción no es anterior a la fecha del pedido.

## Tests de historización

Los snapshots implementan una estrategia SCD tipo 2.

Se utilizan validaciones específicas para garantizar
la integridad de las diferentes versiones históricas.

### Integridad temporal

Se comprueba que el final de vigencia
no es anterior al inicio de vigencia.

### Unicidad de versiones

Se valida que cada versión histórica dispone
de un identificador único mediante `dbt_scd_id`.

También se comprueba la unicidad de las claves
de negocio entre las versiones vigentes.

### Ausencia de solapamientos

El test personalizado `no_overlapping_validity`
comprueba que las versiones históricas de una misma
entidad no presentan intervalos de vigencia solapados.

Este test se aplica a:

- `snap_customers`.
- `snap_parts`.
- `snap_partsupps`.

## Observabilidad

El proyecto utiliza Elementary para monitorizar
el comportamiento de los modelos analíticos.

### Anomalías de volumen

`elementary.volume_anomalies`

Permite detectar variaciones anómalas
en el número de registros.

### Cambios de esquema

`elementary.schema_changes`

Permite identificar modificaciones
en la estructura de las tablas.

### Anomalías en columnas

`elementary.all_columns_anomalies`

Se utiliza para monitorizar métricas como:

- Cantidad de valores nulos.
- Cantidad de valores iguales a cero.

## Integración con CI/CD

Las pruebas de calidad forman parte
de los procesos automatizados de dbt Cloud.

El pipeline de integración continua utiliza Slim CI
para validar los modelos modificados y sus dependencias
descendentes antes de incorporar cambios a la rama principal.

La rama `main` dispone de una regla de protección
que exige completar correctamente la comprobación
de dbt Cloud antes de realizar el merge.

## Gobierno del dato

Las pruebas automatizadas contribuyen al gobierno del dato
mediante la detección temprana de inconsistencias
y la validación de reglas de negocio.

La documentación de los modelos, columnas y tests
facilita la trazabilidad de las transformaciones
y permite comprender las condiciones que deben cumplir
los datos utilizados en los análisis.


{% docs no_overlapping_validity_description %}

# Test - No Overlapping Validity

## Descripción

Test genérico personalizado que comprueba
que las versiones históricas de una misma entidad
no presentan intervalos de vigencia solapados.

Se utiliza para validar snapshots SCD tipo 2.

## Argumentos

- `model`: snapshot sobre el que se ejecuta la validación.
- `key_columns`: lista de columnas que identifican
  la entidad de negocio.

## Funcionamiento

El test utiliza la función de ventana `LEAD`
para obtener el inicio de vigencia de la siguiente versión
de cada entidad.

Las versiones se agrupan mediante las columnas
definidas en `key_columns`.

Dentro de cada grupo, los registros se ordenan
por `dbt_valid_from` y `dbt_scd_id`.

Para cada versión se compara:

- `dbt_valid_to`: final de vigencia actual.
- `next_valid_from`: inicio de vigencia de la siguiente versión.

## Regla de validación

Se considera que existe un solapamiento cuando
hay una versión posterior y se cumple alguna
de las siguientes condiciones:

- `dbt_valid_to` es NULL.
- `dbt_valid_to` es posterior a `next_valid_from`.

La igualdad entre ambas fechas está permitida.

## Ejemplo

Para un cliente con identificador 100:

| Versión | Inicio | Fin |
|---|---|---|
| 1 | 2026-01-01 | 2026-03-01 |
| 2 | 2026-03-01 | 2026-06-01 |
| 3 | 2026-06-01 | NULL |

El test se supera porque las versiones
no presentan solapamientos.

Si la primera versión terminara el 15 de marzo,
existiría un solapamiento con la segunda versión.

## Resultado

El test devuelve las filas que incumplen
la condición de no solapamiento.

Si la consulta no devuelve registros,
la validación se considera satisfactoria.

## Utilización en el proyecto

Se utiliza en los tres snapshots:

- `snap_customers`, mediante `customer_id`.
- `snap_parts`, mediante `part_id`.
- `snap_partsupps`, mediante `part_id` y `supplier_id`.

## Consideraciones

El test comprueba la ausencia de solapamientos,
pero no garantiza que los intervalos de vigencia
sean continuos ni que no existan huecos temporales.

Tampoco verifica por sí solo la unicidad
de las claves de negocio.

Estas propiedades se comprueban mediante
otras pruebas complementarias.

{% enddocs %}