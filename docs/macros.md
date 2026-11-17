{% docs calculate_percentage_description %}

# Macro - Calculate Percentage

## Descripción

Macro que calcula porcentajes a partir de dos expresiones SQL,
permitiendo configurar el número de decimales del resultado.

Incorpora una protección frente a divisiones por cero
mediante la función `NULLIF`.

## Argumentos

- `numerator`: expresión SQL que representa el numerador.
- `denominator`: expresión SQL que representa el denominador.
- `decimals`: número de decimales del resultado. Por defecto, 2.

## Funcionamiento

La macro genera la siguiente expresión SQL:

```sql
ROUND(numerator / NULLIF(denominator, 0) * 100, decimals)
```

El cálculo consiste en dividir el numerador entre el denominador,
multiplicar el resultado por 100 y redondearlo al número
de decimales especificado.

Cuando el denominador es igual a cero, `NULLIF` devuelve NULL,
evitando un error por división entre cero.

En ese caso, el resultado del cálculo también es NULL.

## Ejemplo de uso

```sql
{{ calculate_percentage("retail_price - supply_cost", "retail_price") }}
```

Si el precio de catálogo es 100 y el coste de suministro es 70,
el resultado es 30.00.

## Utilización en el proyecto

Se utiliza en `int_part_supplier` para calcular:

- `potential_margin_pct`: margen potencial respecto al precio de catálogo.
- `potential_markup_pct`: recargo potencial respecto al coste de suministro.

## Consideraciones

Los resultados se expresan como porcentajes entre magnitudes
económicas y no como proporciones entre 0 y 1.

El resultado puede superar el 100 % o ser negativo,
dependiendo de los valores utilizados.

{% enddocs %}


{% docs generate_composite_key_description %}

# Macro - Generate Composite Key

## Descripción

Macro que genera un identificador a partir
de la concatenación de dos columnas o expresiones SQL.

Permite representar mediante una única columna
una clave de negocio formada por dos identificadores.

## Argumentos

- `column1`: primera columna o expresión SQL.
- `column2`: segunda columna o expresión SQL.

## Funcionamiento

La macro convierte ambos valores a texto
y los concatena utilizando un guion como separador.

La expresión SQL generada es:

```sql
CONCAT(
    CAST(column1 AS VARCHAR),
    '-',
    CAST(column2 AS VARCHAR)
)
```

## Ejemplo de uso

```sql
{{ generate_composite_key("l.order_id", "l.line_number") }}
```

Para los valores:

- `order_id = 12345`
- `line_number = 2`

El resultado es:

`12345-2`

## Utilización en el proyecto

Se utiliza en dos modelos intermedios:

### int_order_lines

Genera `order_line_id` a partir de:

- `order_id`
- `line_number`

### int_part_supplier

Genera `part_supplier_id` a partir de:

- `part_id`
- `supplier_id`

## Consideraciones

La macro no genera un identificador secuencial
ni utiliza funciones de hashing.

La unicidad del resultado depende de los valores
de entrada y de que su concatenación no produzca
colisiones entre combinaciones diferentes.

El uso de un separador fijo permite distinguir
los componentes de la clave.

Si alguno de los argumentos es NULL,
la expresión puede devolver NULL.

La validez de las claves generadas se comprueba
mediante tests de unicidad y ausencia de valores nulos.

{% enddocs %}


{% docs generate_date_key_description %}

# Macro - Generate Date Key

## Descripción

Macro que transforma una fecha en un identificador
numérico con formato YYYYMMDD.

Permite generar claves temporales homogéneas
para relacionar los modelos de hechos
con la dimensión de tiempo.

## Argumentos

- `date_column`: columna o expresión SQL que contiene la fecha.

## Funcionamiento

La macro utiliza las funciones `TO_CHAR`
y `TO_NUMBER` de Snowflake.

La expresión SQL generada es:

```sql
TO_NUMBER(TO_CHAR(date_column, 'YYYYMMDD'))
```

Primero se transforma la fecha en una cadena
con formato YYYYMMDD.

Posteriormente, la cadena se convierte
en un valor numérico.

## Ejemplo de uso

```sql
{{ generate_date_key("order_date") }}
```

Para la fecha:

`2026-11-17`

El resultado es:

`20261117`

## Utilización en el proyecto

### int_order_lines

Se utiliza para generar cuatro claves temporales:

- `order_date_key`
- `ship_date_key`
- `commit_date_key`
- `receipt_date_key`

Estas claves permiten relacionar los acontecimientos
comerciales y logísticos con la dimensión temporal.

### int_date

Se utiliza para generar `date_key`
a partir de `date_day`.

Esta columna identifica de forma única
cada fecha del calendario.

## Relación con dbt_utils.date_spine

La macro `generate_date_key` no genera fechas nuevas.

Su función consiste exclusivamente en convertir
fechas existentes en identificadores numéricos.

La generación del calendario continuo se realiza
mediante `dbt_utils.date_spine`, utilizada en `int_date`.

## Consideraciones

El formato YYYYMMDD permite representar las fechas
mediante identificadores numéricos consistentes.

La macro no modifica el valor de la fecha original.

Si el argumento contiene NULL, el resultado es NULL.

{% enddocs %}