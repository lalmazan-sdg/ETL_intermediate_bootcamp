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