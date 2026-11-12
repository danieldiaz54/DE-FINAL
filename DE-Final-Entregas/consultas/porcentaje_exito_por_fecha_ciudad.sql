SELECT
    fecha,
    ciudad,
    CAST(
        ROUND(
            100.0 * SUM(CASE WHEN estado = 'entregado' THEN 1 ELSE 0 END) / COUNT(*),
            2
        ) AS DECIMAL(5, 2)
    ) AS porcentaje_exito
FROM entregas
WHERE fecha BETWEEN '2026-10-01' AND '2026-10-03'
GROUP BY fecha, ciudad
ORDER BY fecha ASC, ciudad ASC;
