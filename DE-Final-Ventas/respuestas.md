# Entregable — Examen Final: Ventas diarias con control de actualidad

## 1. Archivos modificados

1. [`dbt/models/ventas_diarias.sql`](dbt/models/ventas_diarias.sql): Modelo analítico que agrupa `{{ ref('stg_ventas') }}` por `fecha_venta` y calcula `numero_ventas`, `unidades_vendidas` e `ingreso_total` (`decimal(12, 2)`).
2. [`dbt/models/sources.yml`](dbt/models/sources.yml): Configuración de `loaded_at_field: _loaded_at` y `freshness` (`warn_after: 12 hour`, `error_after: 24 hour`) en la tabla `raw.ventas`.
3. [`airflow/dags/examen_ventas.py`](airflow/dags/examen_ventas.py): Incorporación de la tarea `comprobar_actualidad` (`run_dbt` con `["source", "freshness"]`) como dependencia previa a `construir_resumen` (`comprobar_actualidad >> construir_resumen`).

---

## 2. Evidencias de las dos ejecuciones obligatorias

### Escenario 1: Fuente actualizada (`actualizada` — última carga hace ~2 horas)

- **Identificador de ejecución (`run_id`):** `manual__2026-11-12T11:49:14+00:00`
- **Estados en Airflow:**
  - `comprobar_actualidad`: `success` (`INICIO dbt ['source', 'freshness']` → `FIN dbt ['source', 'freshness']`)
  - `construir_resumen`: `success` (`INICIO dbt ['build']` → `FIN dbt ['build']`)
- **Capturas de pantalla:**
  - [`evidencias/captura_1_actualizada_graph.png`](evidencias/captura_1_actualizada_graph.png)
  - [`evidencias/captura_1_actualizada_details.png`](evidencias/captura_1_actualizada_details.png)
  - [`evidencias/captura_1_actualizada_log_freshness.png`](evidencias/captura_1_actualizada_log_freshness.png)
  - [`evidencias/captura_1_actualizada_log_build.png`](evidencias/captura_1_actualizada_log_build.png)
- **Resumen consultado antes del bloqueo (`select * from analytics.ventas_diarias order by fecha_venta`):**
  ```text
  ['fecha_venta', 'numero_ventas', 'unidades_vendidas', 'ingreso_total']
  (datetime.date(2026, 1, 10), 2, 3, Decimal('46.00'))
  (datetime.date(2026, 1, 11), 3, 6, Decimal('51.25'))
  (datetime.date(2026, 1, 12), 1, 4, Decimal('12.40'))
  ```
  *(Guardado en [`evidencias/resumen_antes_bloqueo.txt`](evidencias/resumen_antes_bloqueo.txt))*.

---

### Escenario 2: Fuente desactualizada (`desactualizada` — última carga hace ~30 horas)

- **Identificador de ejecución (`run_id`):** `manual__2026-11-12T11:52:51+00:00`
- **Estados en Airflow:**
  - `comprobar_actualidad`: `failed`
  - `construir_resumen`: `upstream_failed` (sin intentos ejecutados ni marca `INICIO dbt` para esta ejecución)
- **Capturas de pantalla:**
  - [`evidencias/captura_2_desactualizada_graph.png`](evidencias/captura_2_desactualizada_graph.png)
  - [`evidencias/captura_2_desactualizada_details.png`](evidencias/captura_2_desactualizada_details.png)
  - [`evidencias/captura_2_desactualizada_log_freshness.png`](evidencias/captura_2_desactualizada_log_freshness.png)
  - [`evidencias/captura_2_desactualizada_log_build.png`](evidencias/captura_2_desactualizada_log_build.png)
- **Log que explica el fallo de freshness:**
  - En el log de Airflow ([`evidencias/log_desactualizada_freshness_airflow.txt`](evidencias/log_desactualizada_freshness_airflow.txt)):
    ```text
    [2026-11-12T11:52:57.015+0000] {logging_mixin.py:190} INFO - INICIO dbt ['source', 'freshness']
    subprocess.CalledProcessError: Command '['/opt/dbt/bin/dbt', 'source', 'freshness', '--project-dir', '/workspace/dbt', '--profiles-dir', '/workspace/dbt']' returned non-zero exit status 1.
    [2026-11-12T11:53:01.628+0000] {taskinstance.py:1226} INFO - Marking task as FAILED. dag_id=examen_ventas, task_id=comprobar_actualidad, run_id=manual__2026-11-12T11:52:51+00:00
    ```
  - En el log de dbt ([`evidencias/log_desactualizada_freshness_dbt.txt`](evidencias/log_desactualizada_freshness_dbt.txt)) y artefacto `sources.json` ([`evidencias/artefactos_desactualizada.txt`](evidencias/artefactos_desactualizada.txt)):
    ```text
    11:53:01.166742 [info ] [Thread-1 (]: 1 of 1 START freshness of ventas_raw.ventas .................................... [RUN]
    11:53:01.200421 [error] [Thread-1 (]: 1 of 1 ERROR STALE freshness of ventas_raw.ventas .............................. [ERROR STALE in 0.03s]
    11:53:01.255814 [debug] [MainThread]: Command `dbt source freshness` failed at 11:53:01.255681 after 1.64 seconds
    ```
    Con `"max_loaded_at": "2026-11-11T05:52:46.173276+00:00"`, `"snapshotted_at": "2026-11-12T11:53:01.193000+00:00"`, `"max_loaded_at_time_ago_in_s": 108015.019724` (~30 horas, superando el umbral `error_after` de 24 horas).
- **Resumen consultado después del bloqueo (`select * from analytics.ventas_diarias order by fecha_venta`):**
  ```text
  ['fecha_venta', 'numero_ventas', 'unidades_vendidas', 'ingreso_total']
  (datetime.date(2026, 1, 10), 2, 3, Decimal('46.00'))
  (datetime.date(2026, 1, 11), 3, 6, Decimal('51.25'))
  (datetime.date(2026, 1, 12), 1, 4, Decimal('12.40'))
  ```
  *(Guardado en [`evidencias/resumen_despues_bloqueo.txt`](evidencias/resumen_despues_bloqueo.txt), comprobando que `analytics.ventas_diarias` conserva intacto el resumen anterior al bloquearse `construir_resumen` en estado `upstream_failed`)*.

---

## 3. Preguntas conceptuales

### 1. ¿Por qué usar `_loaded_at` y no `fecha_venta` para este control?

Porque representan dos dimensiones temporales distintas:
- **`fecha_venta` (tiempo del evento de negocio):** indica la fecha comercial en que ocurrió la venta (`2026-01-10`, `2026-01-11`, `2026-01-12`). Una transacción con `fecha_venta` de días o meses atrás puede ser legítima y haberse cargado hoy (por ejemplo, una venta rezagada o un reprocesamiento). Inversamente, en un día sin ventas nuevas o con cierre al día anterior, `fecha_venta` sería anterior al día actual aunque el pipeline de ingestión acabe de actualizar `raw.ventas`.
- **`_loaded_at` (tiempo de ingestión en el sistema):** registra la marca de tiempo (`TIMESTAMPTZ` en UTC) en que el proceso de carga insertó los datos en `raw.ventas`. El propósito de `dbt source freshness` es verificar que la fuente fue actualizada recientemente por el pipeline de ingestión dentro del umbral permitido (advertencia > 12 h, error > 24 h), con independencia de la fecha comercial de las operaciones.

### 2. ¿Por qué las pruebas de integridad no garantizan actualidad?

Las pruebas de integridad (`unique`, `not_null` en `sources.yml` y `schema.yml`, y la prueba singular `valores_ventas.sql` que comprueba `cantidad > 0` y `precio_unitario >= 0`) evalúan únicamente la **consistencia y validez interna de los registros almacenados actualmente** en las tablas.

Si el proceso de carga hacia `raw.ventas` se retrasa más de 24 horas o deja de ejecutarse (como en el escenario `desactualizada`, con 30 horas de antigüedad), las filas presentes en la tabla siguen siendo estructuralmente válidas: tienen `id_venta` único y no nulo, fechas y montos no nulos y cantidades positivas. Por lo tanto, `dbt test` (o `dbt build` por sí solo) aprobaría todas las pruebas de integridad sin detectar que los datos son obsoletos. Solo el control explícito de `dbt source freshness` compara `max(_loaded_at)` contra el tiempo actual en UTC para garantizar que la fuente esté vigente antes de reconstruir el resumen.
