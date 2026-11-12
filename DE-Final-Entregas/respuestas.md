# Respuestas a las preguntas conceptuales

## 1. ¿Por qué se pudo consultar el tercer día sin registrar una partición nueva?

Se pudo consultar la fecha `2026-10-03` de forma inmediata tras subir el archivo `s3://de-final-entregas-daniel-202610/entregas/fecha=2026-10-03/entregas.csv` porque la tabla externa `entregas` en AWS Glue Data Catalog fue configurada desde su despliegue inicial con **Partition Projection** (`"projection.enabled" = "true"`).

Con este mecanismo, Amazon Athena **no consulta particiones almacenadas estáticamente en el catálogo de Glue**, sino que calcula dinámicamente en tiempo de consulta cuáles son las particiones válidas y en qué ruta de S3 se ubican a partir de las reglas definidas en los parámetros de la tabla (`infraestructura/principal.tf`):

- **Tipo y formato:** `"projection.fecha.type" = "date"` y `"projection.fecha.format" = "yyyy-MM-dd"`.
- **Rango e intervalo:** `"projection.fecha.range" = "2026-10-01,2026-10-03"` con pasos de `1` día (`"projection.fecha.interval" = "1"`, `"projection.fecha.interval.unit" = "DAYS"`).
- **Plantilla de ubicación en S3:** `"storage.location.template" = "s3://de-final-entregas-daniel-202610/entregas/fecha=${fecha}/"`.

En la etapa inicial (ejecuciones `06b3458f-cde9-4df0-8df9-7cdde3bcd0cb` y `d046004b-5bf4-4cdb-a895-87d750e0632d`), aunque Athena ya proyectaba la fecha `2026-10-03` porque estaba dentro del rango `2026-10-01,2026-10-03`, dicho prefijo aún no contenía objetos en S3, por lo que Athena leyó únicamente los 12 registros de los días 1 y 2 (`DataScannedInBytes: 640`). En cuanto se subió el tercer archivo CSV respetando exactamente el prefijo de la plantilla (`entregas/fecha=2026-10-03/`), las consultas de la etapa final (`f73bad3d-63fd-448e-af7a-0d3b57d99ebf`, `9064a6d1-e590-4548-950d-0c41fe32cab4`, `d862519d-f2c0-4085-bed0-cf20f715e3cc` y `4ef0e65b-2c0b-42e6-b8bb-f4d0b350e393`) localizaron y leyeron automáticamente los 6 nuevos registros (pasando a 18 registros en total y `DataScannedInBytes: 970`), sin necesidad de ejecutar un Glue Crawler, `MSCK REPAIR TABLE` ni `ALTER TABLE ADD PARTITION`.

---

## 2. Si se subiera un archivo para el 4 de octubre manteniendo la configuración actual, ¿qué resultado se esperaría y qué se debería modificar para incluirlo?

### Resultado esperado con la configuración actual
Si se subiera un archivo en `s3://de-final-entregas-daniel-202610/entregas/fecha=2026-10-04/entregas.csv` manteniendo la configuración actual, **Athena no devolvería ningún registro para el `2026-10-04`** (una consulta filtrando por `WHERE fecha = '2026-10-04'` retornaría `0` filas y las consultas agregadas seguirían reportando únicamente los 18 registros de los días 1 al 3).

Esto ocurre porque la propiedad `"projection.fecha.range"` de la tabla está fijada actualmente en `"2026-10-01,2026-10-03"`. Athena solo genera y escanea ubicaciones de partición que se encuentren dentro del rango proyectado; cualquier fecha fuera de ese límite superior (`2026-10-03`) es descartada durante la planificación de la consulta antes siquiera de inspeccionar S3, aunque el objeto exista físicamente en el bucket.

### Qué se debería modificar para incluirlo
1. **En la configuración de la tabla en Terraform (`infraestructura/variables.tf` / `infraestructura/principal.tf`):**
   Ampliar el límite superior del parámetro `"projection.fecha.range"` en la tabla `aws_glue_catalog_table.entregas` para que incluya el 4 de octubre (por ejemplo, cambiar `projection_date_range` a `"2026-10-01,2026-10-04"` o utilizar una expresión dinámica relativa como `"2026-10-01,NOW"` si se tratara de ingestión diaria en tiempo real) y aplicar el cambio con `terraform apply`.
2. **En las consultas SQL (`consultas/`):**
   Si las consultas tienen un filtro explícito en la cláusula `WHERE` acotado al día 3 (como `WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'`), actualizar dicho predicado para abarcar `2026-10-04` (por ejemplo, `WHERE fecha BETWEEN '2026-10-01' AND '2026-10-04'`).
