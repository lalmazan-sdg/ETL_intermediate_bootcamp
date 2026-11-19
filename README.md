# ETL Intermediate Bootcamp

## 1. Descripción del proyecto

Este proyecto implementa un pipeline de transformación de datos
utilizando dbt y Snowflake, siguiendo los principios de Analytics
Engineering y una arquitectura ELT (Extract, Load, Transform).

El objetivo es transformar datos transaccionales de origen en un
modelo analítico estructurado, documentado y preparado para su
explotación mediante herramientas de Business Intelligence.

Como fuente de información se utiliza el conjunto de datos
TPC-H SF10 proporcionado por Snowflake.

El proyecto incorpora:

- Arquitectura de transformación por capas.
- Modelos incrementales.
- Modelado dimensional.
- Macros reutilizables.
- Pruebas de calidad e integridad de datos.
- Snapshots para conservar información histórica.
- Documentación técnica integrada con dbt.
- Observabilidad mediante Elementary.
- Evaluación de buenas prácticas con dbt Project Evaluator.
- Integración continua mediante dbt Cloud.
- Orquestación automatizada mediante Prefect.

El resultado es una arquitectura orientada a la mantenibilidad,
trazabilidad, calidad y reutilización de los datos.

---

## 2. Tecnologías utilizadas

| Tecnología | Función |
|---|---|
| Snowflake | Almacenamiento y procesamiento de datos |
| dbt | Transformación, modelado y validación |
| SQL | Desarrollo de transformaciones |
| Jinja | Parametrización y reutilización de lógica |
| dbt Cloud | Ejecución de jobs e integración continua |
| Prefect | Orquestación y monitorización de pipelines |
| Python | Integración entre Prefect y dbt Cloud |
| Elementary | Observabilidad y calidad de datos |
| dbt Project Evaluator | Evaluación de buenas prácticas |
| Git y GitHub | Control de versiones |

---

## 3. Arquitectura del proyecto

El proyecto sigue una arquitectura ELT organizada en tres
capas principales de transformación:

1. Staging
2. Intermediate
3. Marts

Los datos originales se encuentran en Snowflake y se declaran
como fuentes de dbt.

### Flujo de datos

```text
SNOWFLAKE SAMPLE DATA
        |
        v
     SOURCES
        |
        v
     STAGING
        |
        v
   INTERMEDIATE
        |
        v
      MARTS
        |
        v
  ANALYTICS / BI
```

Adicionalmente, el proyecto incorpora mecanismos transversales:

- Tests de calidad.
- Snapshots históricos.
- Documentación.
- Observabilidad.
- Integración continua.
- Orquestación.

Esta separación permite mantener una clara diferenciación
entre la preparación de los datos, la aplicación de reglas
de negocio y su exposición para el análisis.

---

## 4. Fuentes de datos

El proyecto utiliza el conjunto de datos TPC-H SF10,
disponible en Snowflake:

- Base de datos: `SNOWFLAKE_SAMPLE_DATA`
- Esquema: `TPCH_SF10`

Se utilizan ocho tablas de origen:

| Fuente | Descripción |
|---|---|
| CUSTOMER | Información de clientes |
| ORDERS | Cabeceras de pedidos |
| LINEITEM | Detalle de líneas de pedido |
| PART | Catálogo de productos |
| SUPPLIER | Información de proveedores |
| PARTSUPP | Relación entre productos y proveedores |
| NATION | Catálogo de países |
| REGION | Catálogo de regiones |

Las fuentes se declaran mediante `source()` y se documentan
a través de archivos YAML y bloques Markdown de dbt.

También se incorporan comprobaciones de integridad y una
configuración de freshness.

Dado que TPC-H es un conjunto de datos estático, las
advertencias de freshness no implican necesariamente
problemas en la actualización de los datos.

**Documentación:**

- [Origen TPC-H](docs/tpch.md)
- [Documentación de fuentes](docs/sources.md)

---

## 5. Capa Staging

La capa staging constituye el primer nivel de transformación.

Su objetivo es preparar y estandarizar los datos originales
sin introducir reglas de negocio complejas.

Entre las principales operaciones realizadas se encuentran:

- Renombrado de columnas.
- Estandarización de identificadores.
- Selección de atributos relevantes.
- Preparación de los datos para transformaciones posteriores.

Los modelos utilizan la siguiente nomenclatura:

`stg_tpch_sf10__<entidad>`

### Modelos

| Modelo | Entidad |
|---|---|
| stg_tpch_sf10__customers | Clientes |
| stg_tpch_sf10__orders | Pedidos |
| stg_tpch_sf10__lineitems | Líneas de pedido |
| stg_tpch_sf10__parts | Productos |
| stg_tpch_sf10__suppliers | Proveedores |
| stg_tpch_sf10__partsupps | Productos y proveedores |
| stg_tpch_sf10__nations | Países |
| stg_tpch_sf10__regions | Regiones |

### Materialización

Como configuración general, los modelos de staging
se materializan como tablas.

Sin embargo, el modelo `stg_tpch_sf10__lineitems` utiliza
una materialización incremental.

Esta decisión se debe a su volumen de datos y a su naturaleza
transaccional.

La estrategia incremental utilizada es `MERGE`, con una
clave única compuesta por:

- `order_id`
- `line_number`

De esta forma, se pueden insertar nuevos registros y
actualizar registros existentes.

La implementación actual no limita la lectura de la fuente
a registros nuevos o modificados, por lo que el beneficio
principal reside en la estrategia de actualización de la
tabla de destino.

**Documentación:**

[Modelos de staging](docs/staging.md)

---

## 6. Capa Intermediate

La capa intermediate concentra las transformaciones
de integración y la aplicación de reglas de negocio.

Su objetivo es construir entidades enriquecidas que
puedan reutilizarse en distintos modelos analíticos.

### Modelos

| Modelo | Función |
|---|---|
| int_customers | Enriquecimiento de clientes |
| int_suppliers | Enriquecimiento de proveedores |
| int_geography | Integración de países y regiones |
| int_part_supplier | Información de productos y proveedores |
| int_order_lines | Integración de pedidos y líneas |
| int_date | Generación del calendario |

### Transformaciones principales

**int_customers**

Incorpora atributos comerciales y financieros de los
clientes, incluyendo indicadores asociados al signo
del saldo de cuenta.

**int_suppliers**

Prepara la información de proveedores y sus atributos
geográficos para su utilización en los modelos analíticos.

**int_geography**

Integra la información de países y regiones para
facilitar los análisis geográficos.

**int_part_supplier**

Combina productos con proveedores e incorpora indicadores
relacionados con inventario, disponibilidad, costes
y márgenes potenciales.

**int_order_lines**

Integra las cabeceras y líneas de pedido.

Incorpora cálculos como:

- Importe del descuento.
- Importe neto.
- Importe total con impuestos.
- Tiempos logísticos.
- Indicadores de retraso.
- Indicadores de devolución.
- Claves temporales.

**int_date**

Genera un calendario a partir del rango de fechas
presente en los datos transaccionales.

Incluye atributos como año, trimestre, mes, semana,
día de la semana y otros indicadores temporales.

### Materialización

Los modelos intermediate se materializan generalmente
como vistas.

Esta decisión evita almacenar resultados intermedios
innecesarios y facilita la reutilización de las
transformaciones.

La excepción es `int_date`, materializado como tabla
para disponer de un calendario persistente y reutilizable.

**Documentación:**

[Modelos intermediate](docs/intermediate.md)

---

## 7. Capa Marts

La capa marts representa la capa analítica final del proyecto.

Los modelos siguen un enfoque de modelado dimensional,
separando las dimensiones descriptivas de las tablas
de hechos.

El objetivo es facilitar su utilización por parte
de analistas y herramientas de Business Intelligence.

### Dimensiones

| Modelo | Descripción |
|---|---|
| dim_customers | Dimensión de clientes |
| dim_parts | Dimensión de productos |
| dim_suppliers | Dimensión de proveedores |
| dim_date | Dimensión temporal |

Las dimensiones permiten contextualizar los indicadores
mediante atributos descriptivos y criterios de agrupación.

### Tablas de hechos

**fct_order_lines**

Contiene las operaciones comerciales a nivel de línea
de pedido.

Su granularidad es una fila por línea de pedido.

Incluye:

- Identificadores de cliente, producto y proveedor.
- Cantidades.
- Precios e importes.
- Descuentos e impuestos.
- Fechas.
- Indicadores logísticos.
- Indicadores de devolución.

**fct_inventory**

Contiene información de inventario y suministro.

Su granularidad es una fila por combinación de
producto y proveedor.

Incluye indicadores como:

- Cantidad disponible.
- Coste de suministro.
- Valor de inventario.
- Ingresos potenciales.
- Beneficio bruto potencial.
- Margen y markup potenciales.

### Materialización

Las dimensiones se materializan como vistas.

Las tablas de hechos se materializan como tablas,
permitiendo almacenar los resultados de las
transformaciones analíticas.

El acceso de consulta a los modelos de marts
se configura mediante permisos para el rol
`DBT_ANALYST`.

**Documentación:**

[Modelos marts](docs/marts.md)

---

## 8. Macros

El proyecto incorpora macros reutilizables desarrolladas
mediante Jinja.

Su objetivo es centralizar operaciones frecuentes,
evitar duplicaciones y facilitar el mantenimiento.

| Macro | Función |
|---|---|
| calculate_percentage | Cálculo de porcentajes |
| generate_composite_key | Generación de claves compuestas |
| generate_date_key | Generación de claves temporales |

Las macros permiten aplicar criterios consistentes
entre distintos modelos.

También se incorpora el test personalizado
`no_overlapping_validity`, utilizado para comprobar
la ausencia de solapamientos entre versiones históricas.

**Documentación:**

[Macros](docs/macros.md)

---

## 9. Calidad de datos

La calidad de datos constituye un componente transversal
de la arquitectura.

El proyecto utiliza pruebas genéricas, pruebas
proporcionadas por paquetes externos y pruebas
singulares desarrolladas específicamente.

### Tests genéricos

Se utilizan principalmente:

- `not_null`
- `unique`
- `relationships`
- `accepted_values`

Estos tests permiten comprobar la integridad
de las claves, la obligatoriedad de los campos
y las relaciones entre entidades.

### Tests de paquetes externos

Se utilizan pruebas adicionales mediante
dbt Utils y dbt Expectations.

Entre ellas:

- `unique_combination_of_columns`
- `expression_is_true`
- `expect_column_values_to_be_between`

Estas comprobaciones permiten validar claves
compuestas, expresiones de negocio y rangos
de valores.

### Tests singulares

El proyecto también incluye pruebas SQL
personalizadas para validar:

- Cálculos económicos.
- Consistencia de líneas de pedido.
- Relaciones entre pedidos, productos y proveedores.
- Cálculos de inventario.
- Conciliación de importes.
- Cobertura de la dimensión temporal.
- Funcionamiento de macros.

### Ejecución

Los tests pueden ejecutarse mediante:

```bash
dbt test
```

O integrarse en el proceso completo de construcción:

```bash
dbt build
```

La ejecución de `dbt build` permite construir los
recursos seleccionados y realizar sus validaciones
siguiendo las dependencias del proyecto.

**Documentación:**

- [Tests](docs/tests.md)
- [Calidad de datos](docs/data_quality.md)

---

## 10. Snapshots e histórico

El proyecto incorpora snapshots de dbt para conservar
el histórico de los cambios detectados en determinadas
entidades.

Se han implementado los siguientes snapshots:

| Snapshot | Entidad |
|---|---|
| snap_customers | Clientes |
| snap_parts | Productos |
| snap_partsupps | Productos y proveedores |

Los snapshots permiten mantener diferentes versiones
de un mismo registro a lo largo del tiempo.

### Estrategia

Se utiliza la estrategia `check`, que identifica
cambios comparando los atributos configurados.

La configuración `check_cols: all` permite detectar
modificaciones en cualquiera de las columnas
incluidas en cada snapshot.

También se utiliza:

`hard_deletes: new_record`

Esta configuración permite representar eliminaciones
detectadas mediante registros específicos.

### Gestión del histórico

dbt incorpora atributos de control como:

- `dbt_scd_id`
- `dbt_updated_at`
- `dbt_valid_from`
- `dbt_valid_to`
- `dbt_is_deleted`

Estos atributos permiten identificar versiones
históricas y sus periodos de vigencia.

Se incluyen tests específicos para validar
las versiones vigentes y evitar solapamientos
temporales.

### Utilidad

Los snapshots permiten conservar información histórica
sin necesidad de incorporar inicialmente dimensiones
históricas adicionales a los marts.

Esto ofrece la posibilidad de desarrollar modelos
SCD de tipo 2 para consumo analítico cuando
los requisitos de negocio lo justifiquen.

**Documentación:**

[Snapshots](docs/snapshots.md)

---

## 11. Observabilidad y buenas prácticas

El proyecto incorpora herramientas adicionales
para evaluar la calidad y el mantenimiento
de la arquitectura.

### Elementary

Elementary proporciona capacidades de observabilidad
sobre los modelos y sus ejecuciones.

Permite centralizar información relacionada con:

- Resultados de tests.
- Ejecuciones de dbt.
- Estado de los modelos.
- Información de monitorización.

Sus recursos se almacenan en un esquema específico
de Snowflake.

### dbt Project Evaluator

dbt Project Evaluator permite comprobar buenas prácticas
relacionadas con el diseño y mantenimiento del proyecto.

Entre los aspectos evaluados se encuentran:

- Documentación.
- Estructura del DAG.
- Dependencias.
- Tests.
- Organización de modelos.

Estas herramientas complementan los tests convencionales
y facilitan el mantenimiento de la calidad del proyecto.

---

## 12. Orquestación

La ejecución automatizada del proyecto se gestiona
mediante Prefect, integrado con dbt Cloud.

Prefect es responsable de coordinar y supervisar
los distintos jobs del pipeline.

La comunicación se realiza mediante la API REST
de dbt Cloud.

### Pipeline diario

El pipeline diario ejecuta secuencialmente:

1. SOURCE_FRESHNESS
2. STAGING_DAILY
3. SNAPSHOTS
4. INTERMEDIATE
5. MARTS

Cada etapa comienza únicamente cuando la anterior
ha finalizado correctamente.

### Pipeline semanal

El pipeline semanal mantiene la misma estructura,
sustituyendo la ejecución habitual de staging
por un full refresh.

1. SOURCE_FRESHNESS
2. STAGING_FULL_REFRESH
3. SNAPSHOTS
4. INTERMEDIATE
5. MARTS

Esta ejecución permite reconstruir periódicamente
los modelos de staging.

### Programación

| Pipeline | Frecuencia | Hora |
|---|---|---|
| Diario | Sábado a jueves | 09:00 |
| Semanal | Viernes | 09:00 |

Zona horaria: `Europe/Madrid`.

### Monitorización

Prefect consulta periódicamente el estado de los
jobs ejecutados en dbt Cloud.

La implementación contempla:

- Control de dependencias.
- Registro de ejecuciones.
- Identificación de errores.
- Control del tiempo máximo de espera.
- Detención del pipeline ante fallos.

La lógica se encuentra implementada en
el directorio `orchestration/`.

**Documentación:**

[Orquestación](docs/orchestration.md)

---

## 13. Integración continua

El proyecto utiliza GitHub y dbt Cloud para
gestionar los cambios en el código.

El objetivo es validar las modificaciones antes
de integrarlas en la rama principal.

El proceso contempla:

1. Desarrollo en una rama de trabajo.
2. Creación de una Pull Request.
3. Ejecución del job de CI.
4. Validación de los recursos afectados.
5. Revisión e integración de los cambios.

La integración continua utiliza mecanismos
de Slim CI para seleccionar los recursos
modificados y sus dependencias descendentes.

Esto permite reducir el alcance de las
validaciones respecto a una ejecución completa
del proyecto.

Los entornos de CI utilizan esquemas de destino
separados para evitar interferencias con
los modelos de producción.

---

## 14. Estructura del repositorio

```text
ETL_intermediate_bootcamp/
│
├── models/
│   ├── staging/
│   │   └── tpch_sf10/
│   ├── intermediate/
│   └── marts/
│
├── snapshots/
│
├── macros/
│   └── tests/
│
├── tests/
│   ├── intermediate/
│   ├── macros/
│   └── marts/
│
├── docs/
│   ├── tpch.md
│   ├── sources.md
│   ├── staging.md
│   ├── intermediate.md
│   ├── marts.md
│   ├── macros.md
│   ├── snapshots.md
│   ├── tests.md
│   ├── data_quality.md
│   └── orchestration.md
│
├── orchestration/
│   ├── config.py
│   ├── dbt_client.py
│   ├── flows.py
│   └── deployments.py
│
├── dbt_project.yml
├── packages.yml
├── package-lock.yml
└── README.md
```

---

## 15. Instalación y ejecución

### Requisitos

Para ejecutar el proyecto es necesario disponer de:

- Acceso a Snowflake.
- dbt con adaptador para Snowflake.
- Credenciales y permisos adecuados.
- Dependencias definidas en `packages.yml`.

Para la orquestación también se requiere:

- Python.
- Prefect.
- Requests.
- python-dotenv.
- Acceso a la API de dbt Cloud.

### Instalación de dependencias dbt

```bash
dbt deps
```

### Validación del proyecto

```bash
dbt parse
```

### Ejecución de modelos y tests

```bash
dbt build
```

### Ejecución de snapshots

```bash
dbt snapshot
```

### Full refresh de staging

```bash
dbt run --select tag:staging --full-refresh
```

### Generación de documentación

```bash
dbt docs generate
```

### Visualización local de documentación

```bash
dbt docs serve
```

### Ejecución manual de Prefect

Desde la raíz del repositorio:

Pipeline diario:

```bash
python -m orchestration.flows --mode daily
```

Pipeline semanal:

```bash
python -m orchestration.flows --mode weekly
```

Estas ejecuciones requieren disponer de las
credenciales correspondientes de dbt Cloud.

---

## 16. Documentación técnica

La documentación detallada del proyecto se encuentra
distribuida en archivos Markdown, integrados cuando
corresponde con el sistema de documentación de dbt.

| Componente | Documentación |
|---|---|
| Origen de datos | [TPC-H](docs/tpch.md) |
| Fuentes | [Sources](docs/sources.md) |
| Staging | [Staging](docs/staging.md) |
| Intermediate | [Intermediate](docs/intermediate.md) |
| Marts | [Marts](docs/marts.md) |
| Macros | [Macros](docs/macros.md) |
| Tests | [Tests](docs/tests.md) |
| Calidad | [Data Quality](docs/data_quality.md) |
| Snapshots | [Snapshots](docs/snapshots.md) |
| Orquestación | [Orchestration](docs/orchestration.md) |

La documentación de los recursos dbt incluye
descripciones de modelos, columnas y relaciones,
facilitando su consulta mediante dbt Catalog.

---

## 17. Conclusiones

Este proyecto desarrolla una arquitectura de datos
organizada siguiendo principios de Analytics Engineering.

La separación por capas permite mantener las
transformaciones desacopladas y reutilizables.

El modelado dimensional facilita la explotación
analítica de la información, mientras que los
mecanismos de calidad garantizan la validación
de las principales reglas de integridad y negocio.

Los snapshots incorporan capacidades de seguimiento
histórico, y las herramientas de observabilidad
permiten supervisar la evolución del proyecto.

Finalmente, la integración de dbt Cloud con Prefect
automatiza las ejecuciones y proporciona un control
centralizado de los pipelines.

En conjunto, el proyecto constituye una implementación
de un proceso ELT completo, documentado, validado
y preparado para su mantenimiento y evolución.