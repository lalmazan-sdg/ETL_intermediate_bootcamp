# Orquestación del pipeline de datos

## Descripción general

La orquestación del proyecto se realiza mediante **Prefect**, que actúa como herramienta central de coordinación y supervisión de las ejecuciones de dbt Cloud.

Esta arquitectura permite automatizar las distintas etapas del proceso ELT, garantizando que se ejecuten en el orden establecido y que las etapas posteriores dependan de la finalización correcta de las anteriores.

El sistema se compone de tres elementos principales:

- **Prefect:** responsable de programar, coordinar y monitorizar los pipelines.
- **dbt Cloud:** encargado de ejecutar los jobs de transformación, validación y actualización de datos.
- **Snowflake:** plataforma donde se encuentran las fuentes y se materializan los modelos analíticos.

La comunicación entre Prefect y dbt Cloud se realiza mediante la API REST de dbt Cloud.

## Arquitectura de orquestación

El proyecto dispone de dos pipelines principales:

1. **Pipeline diario:** actualización ordinaria de las distintas capas del proyecto.
2. **Pipeline semanal:** ejecución de mantenimiento que incorpora un full refresh de staging.

Ambos pipelines siguen una estructura secuencial, respetando las dependencias entre las distintas capas de transformación.

### Pipeline diario

El flujo `dbt-daily-pipeline` ejecuta los siguientes jobs:

| Orden | Job | Función |
|---|---|---|
| 1 | `00_SOURCE_FRESHNESS` | Comprueba la frescura de las fuentes de datos. |
| 2 | `01_STAGING_DAILY` | Actualiza los modelos de staging mediante su estrategia habitual de materialización. |
| 3 | `02_SNAPSHOTS` | Registra los cambios históricos de las entidades configuradas. |
| 4 | `03_INTERMEDIATE` | Actualiza los modelos de transformación e integración intermedia. |
| 5 | `04_MARTS` | Actualiza las dimensiones y tablas de hechos utilizadas para el análisis. |

Cada job comienza únicamente cuando el anterior ha terminado correctamente.

### Pipeline semanal

El flujo `dbt-weekly-full-refresh` mantiene la misma estructura general, pero sustituye la ejecución habitual de staging por un full refresh.

| Orden | Job | Función |
|---|---|---|
| 1 | `00_SOURCE_FRESHNESS` | Comprueba la frescura de las fuentes. |
| 2 | `STAGING_FULL_REFRESH` | Reconstruye completamente los modelos de staging seleccionados. |
| 3 | `02_SNAPSHOTS` | Actualiza los registros históricos. |
| 4 | `03_INTERMEDIATE` | Actualiza las transformaciones intermedias. |
| 5 | `04_MARTS` | Actualiza los modelos analíticos finales. |

El full refresh permite reconstruir los modelos de staging desde sus fuentes originales, evitando depender exclusivamente de las actualizaciones incrementales.

Esta operación resulta especialmente útil para corregir posibles inconsistencias acumuladas y aplicar cambios que requieran una reconstrucción completa.

El full refresh se limita a staging; las siguientes capas se ejecutan con su configuración habitual.

## Programación de las ejecuciones

La programación se encuentra definida en `orchestration/deployments.py` mediante expresiones Cron.

| Pipeline | Programación | Hora | Zona horaria |
|---|---|---|---|
| Diario | Sábado a jueves | 09:00 | Europe/Madrid |
| Semanal | Viernes | 09:00 | Europe/Madrid |

Las expresiones utilizadas son:

**Pipeline diario:**

`0 9 * * 0-4,6`

**Pipeline semanal:**

`0 9 * * 5`

Esta configuración permite ejecutar una actualización cada día, reservando los viernes para el proceso semanal de mantenimiento.

La zona horaria `Europe/Madrid` permite adaptar automáticamente las ejecuciones a los cambios de horario de verano e invierno.

## Gestión de dependencias

La ejecución de los jobs es secuencial y está controlada desde `orchestration/flows.py`.

Cada etapa espera a que finalice la anterior antes de iniciar la siguiente.

Esto garantiza que:

- Los modelos intermedios se actualicen después de staging.
- Los snapshots se ejecuten antes de las transformaciones intermedias.
- Los marts utilicen los resultados de las transformaciones anteriores.
- Un fallo impida continuar con las etapas dependientes.

Este mecanismo evita que las capas analíticas se actualicen utilizando datos de una ejecución anterior cuando una etapa previa ha fallado.

## Integración con dbt Cloud

La comunicación con dbt Cloud se implementa en `orchestration/dbt_client.py`.

La función `execute_dbt_job()` es responsable de:

1. Recuperar el token de autenticación.
2. Enviar una solicitud a la API de dbt Cloud para iniciar el job correspondiente.
3. Obtener el identificador de ejecución (`run_id`).
4. Consultar periódicamente su estado.
5. Comprobar si la ejecución ha finalizado correctamente.
6. Devolver el resultado o generar una excepción si se produce un error.

Los identificadores de los jobs y los parámetros generales de conexión se centralizan en `orchestration/config.py`.

Esta separación facilita el mantenimiento y evita duplicar la lógica de comunicación con dbt Cloud.

## Monitorización y gestión de errores

Prefect supervisa el estado de los jobs mediante consultas periódicas a la API de dbt Cloud.

Los estados contemplados son:

| Estado | Significado |
|---|---|
| Queued | La ejecución está en cola. |
| Starting | La ejecución está iniciándose. |
| Running | El job está ejecutándose. |
| Success | El job ha finalizado correctamente. |
| Error | La ejecución ha fallado. |
| Cancelled | La ejecución ha sido cancelada. |

La configuración establece:

- **Intervalo de consulta:** 10 segundos.
- **Tiempo máximo de espera:** 3600 segundos (60 minutos).

Si un job termina con error, se cancela o supera el tiempo máximo de monitorización, Prefect genera una excepción y detiene el pipeline correspondiente.

Los logs registran los jobs iniciados, sus identificadores, sus estados y el tiempo de monitorización cuando finalizan correctamente.

El tiempo máximo controla cuánto espera Prefect; no implica necesariamente que cancele una ejecución que continúe activa en dbt Cloud.

## Control de concurrencia

Ambos deployments están configurados con:

`concurrency_limit=1`

Esta configuración limita a una ejecución simultánea por deployment.

De esta manera, se evita que se solapen varias ejecuciones del mismo pipeline.

La configuración no establece por sí sola una exclusión global entre el pipeline diario y el semanal.

## Seguridad y autenticación

La autenticación con dbt Cloud se realiza mediante un token de API.

El sistema admite dos mecanismos:

- Variable de entorno `DBT_CLOUD_API_TOKEN`.
- Bloque `Secret` de Prefect denominado `dbt-cloud-api-token`.

El token no se incluye directamente en el código fuente.

Esto permite separar las credenciales de la lógica de orquestación y facilita su gestión entre entornos.

## Organización del código

La implementación se distribuye en los siguientes archivos:

| Archivo | Responsabilidad |
|---|---|
| `config.py` | Configuración de la API, identificadores de jobs y tiempos de espera. |
| `dbt_client.py` | Comunicación con dbt Cloud y monitorización de las ejecuciones. |
| `flows.py` | Definición de los pipelines diario y semanal. |
| `deployments.py` | Configuración de los deployments, horarios y work pool. |

Los deployments utilizan el repositorio GitHub del proyecto como origen del código y el work pool `dbt-cloud-serverless` para su ejecución.

## Calidad y observabilidad

La orquestación complementa los mecanismos de calidad implementados en dbt.

El proyecto incorpora:

- Tests de integridad, unicidad y reglas de negocio.
- Comprobaciones de frescura de las fuentes.
- Snapshots para conservar cambios históricos.
- Elementary para tareas de observabilidad y monitorización de datos.
- dbt Project Evaluator para evaluar buenas prácticas y estructura del proyecto.

La ejecución satisfactoria del pipeline depende de las comprobaciones incluidas en los jobs de dbt Cloud.

La definición de los flujos no incorpora un job independiente de Elementary.

## Consideraciones

La orquestación proporciona un mecanismo centralizado para ejecutar y supervisar las transformaciones del proyecto.

No obstante, deben considerarse algunas particularidades:

- TPC-H es un conjunto de datos de ejemplo estático, por lo que las advertencias de freshness no implican necesariamente un problema de actualización.
- Los snapshots permiten mantener un histórico de los cambios detectados durante sus ejecuciones.
- El full refresh semanal reconstruye staging, pero no implica reconstruir automáticamente todas las capas posteriores mediante full refresh.
- Las actualizaciones de los marts dependen de que las etapas anteriores finalicen correctamente.
- La configuración de los horarios está definida en el código de los deployments; su aplicación efectiva depende de que dichos deployments estén registrados y activos en Prefect.

## Conclusión

La integración de Prefect con dbt Cloud permite establecer un sistema de orquestación automatizado, supervisado y organizado según las dependencias del proyecto.

La separación entre la ejecución diaria y el mantenimiento semanal contribuye a mantener la consistencia de los datos y facilita la operación de los procesos ELT.

Asimismo, la centralización de los flujos, la gestión de errores y los registros de ejecución proporcionan una base para ampliar el sistema de orquestación conforme evolucionen las necesidades del proyecto.