-- 1. Verificar los 6 registros correspondientes a la fecha 2026-10-03
SELECT
    id_envio,
    ciudad,
    transportadora,
    estado,
    duracion_minutos,
    fecha
FROM entregas
WHERE fecha = '2026-10-03'
ORDER BY id_envio ASC;

-- 2. Verificar que la tabla contiene 18 registros en total en el rango proyectado
SELECT
    COUNT(*) AS total_registros
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03';

-- 3. Verificar los conteos por estado del tercer día (2026-10-03)
SELECT
    fecha,
    estado,
    COUNT(*) AS total_intentos
FROM entregas
WHERE fecha = '2026-10-03'
GROUP BY fecha, estado
ORDER BY fecha ASC, estado ASC;
