{% docs tpch_description %}

# TPC-H — Origen de los datos

## Descripción general

TPC-H es un conjunto de datos de referencia utilizado para simular
las operaciones comerciales de una empresa dedicada a la distribución
de productos.

En este proyecto se utiliza el conjunto de datos proporcionado
por Snowflake, con un factor de escala SF10.

Los datos se encuentran en:

- Base de datos: `SNOWFLAKE_SAMPLE_DATA`
- Esquema: `TPCH_SF10`
- Plataforma: Snowflake

## Estructura de los datos

El conjunto de datos está formado por ocho tablas:

| Tabla | Descripción | Granularidad |
|---|---|---|
| CUSTOMER | Información de clientes | Un registro por cliente |
| ORDERS | Cabeceras de pedidos | Un registro por pedido |
| LINEITEM | Detalle de líneas de pedido | Un registro por línea de pedido |
| PART | Catálogo de productos | Un registro por producto |
| SUPPLIER | Información de proveedores | Un registro por proveedor |
| PARTSUPP | Relación entre productos y proveedores | Un registro por producto y proveedor |
| NATION | Catálogo de países | Un registro por país |
| REGION | Catálogo de regiones | Un registro por región |

## Relaciones entre las tablas

Las tablas están relacionadas mediante identificadores que permiten
conectar la información comercial y geográfica.

Las principales relaciones son:

- CUSTOMER se relaciona con ORDERS mediante el identificador del cliente.
- ORDERS se relaciona con LINEITEM mediante el identificador del pedido.
- LINEITEM se relaciona con PART y SUPPLIER mediante los identificadores
  de producto y proveedor.
- PARTSUPP relaciona los productos con sus proveedores.
- CUSTOMER y SUPPLIER se relacionan con NATION.
- NATION se relaciona con REGION.

## Integración con dbt

Las tablas originales se declaran como fuentes mediante la función
`source()` de dbt.

A partir de estas fuentes se construyen tres capas de transformación:

1. Staging: preparación, limpieza y estandarización de los datos.
2. Intermediate: integración de entidades y aplicación de reglas de negocio.
3. Marts: construcción de dimensiones y tablas de hechos para el análisis.

Esta arquitectura permite mantener la trazabilidad de los datos desde
su origen hasta los modelos analíticos finales.

## Calidad y gobierno del dato

Las fuentes incorporan pruebas de calidad para comprobar propiedades
como la unicidad, la ausencia de valores nulos y la integridad
referencial.

La documentación de las tablas y columnas facilita la comprensión
del modelo y permite identificar el origen de la información.

El acceso a los modelos analíticos se gestiona mediante los permisos
configurados en Snowflake.

## Actualización de los datos

TPC-H es un conjunto de datos de ejemplo estáticos.

El proyecto mantiene una configuración de freshness con un umbral
de advertencia de 24 horas.

Debido a la naturaleza estática de estos datos, las advertencias
de freshness no deben interpretarse necesariamente como errores
del proceso de actualización.

{% enddocs %}