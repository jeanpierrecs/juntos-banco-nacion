-- 05. Hallazgos adicionales: el dinero, la evaluación de aperturas y la verificación de la conclusión
USE JuntosBN;
GO

-- 1. Monto del bimestre que llega a distritos sin agencia (esperado: S/ 73.8 M de S/ 149.9 M, 49.2%)

SELECT SUM(MONTO_BIMESTRE) AS monto_total,
       SUM(CASE WHEN N_AGENCIAS = 0 THEN MONTO_BIMESTRE ELSE 0 END) AS monto_sin_agencia,
       CAST(100.0 * SUM(CASE WHEN N_AGENCIAS = 0 THEN MONTO_BIMESTRE ELSE 0 END)
            / SUM(MONTO_BIMESTRE) AS decimal(5,1)) AS pct_sin_agencia
FROM dbo.resultado_distrito;

-- 2. Evaluación de aperturas 2024 -> 2026
-- Ranking recalculado con la red de agencias de junio de 2024 y las familias del bimestre III de 2024.

DROP TABLE IF EXISTS dbo.ranking_2024;
GO

WITH agencias_2024 AS (
    SELECT DISTINCT UBIGEO FROM dbo.agencias WHERE ANIO = 2024
),
familias_2024 AS (
    SELECT UBIGEO, ABONADOS FROM dbo.juntos WHERE ANIO = 2024 AND BIMESTRE_NUM = 3
),
base_2024 AS (
    SELECT c.UBIGEO, c.LATITUD, c.LONGITUD,
           ISNULL(f.ABONADOS, 0) AS FAMILIAS,
           CASE WHEN a.UBIGEO IS NULL THEN 0 ELSE 1 END AS TIENE_AGENCIA
    FROM dbo.coordenadas AS c
    LEFT JOIN familias_2024 AS f ON f.UBIGEO = c.UBIGEO
    LEFT JOIN agencias_2024 AS a ON a.UBIGEO = c.UBIGEO
)
SELECT b.UBIGEO, b.FAMILIAS,
       ROUND(x.DIST_KM, 1)                           AS DIST_KM,
       CAST(b.FAMILIAS * x.DIST_KM AS decimal(14,1)) AS CARGA_VIAJE,
       ROW_NUMBER() OVER (ORDER BY b.FAMILIAS * x.DIST_KM DESC) AS RANKING_2024
INTO dbo.ranking_2024
FROM base_2024 AS b
CROSS APPLY (
    SELECT TOP 1 geography::Point(b.LATITUD, b.LONGITUD, 4326)
                 .STDistance(geography::Point(g.LATITUD, g.LONGITUD, 4326)) / 1000.0 AS DIST_KM
    FROM base_2024 AS g
    WHERE g.TIENE_AGENCIA = 1
    ORDER BY DIST_KM
) AS x
WHERE b.TIENE_AGENCIA = 0 AND b.FAMILIAS > 0;
GO

-- Distritos que ganaron agencia y su puesto en 2024 (esperado: 5; solo Sepahua en el top 100)

DROP TABLE IF EXISTS dbo.evaluacion_aperturas;
GO

WITH nuevos AS (
    SELECT UBIGEO FROM dbo.agencias WHERE ANIO = 2026
    EXCEPT
    SELECT UBIGEO FROM dbo.agencias WHERE ANIO = 2024
)
SELECT n.UBIGEO, r.DEPARTAMENTO, r.PROVINCIA, r.DISTRITO,
       k.FAMILIAS AS FAMILIAS_2024, k.DIST_KM AS DIST_KM_2024,
       k.CARGA_VIAJE AS CARGA_VIAJE_2024, k.RANKING_2024
INTO dbo.evaluacion_aperturas
FROM nuevos AS n
LEFT JOIN dbo.ranking_2024       AS k ON k.UBIGEO = n.UBIGEO
LEFT JOIN dbo.resultado_distrito AS r ON r.UBIGEO = n.UBIGEO;
GO

SELECT * FROM dbo.evaluacion_aperturas ORDER BY RANKING_2024;

-- Distritos que perdieron agencia (esperado: Rázuri, La Libertad)

SELECT d.UBIGEO, d.DEPARTAMENTO, d.DISTRITO
FROM (
    SELECT UBIGEO FROM dbo.agencias WHERE ANIO = 2024
    EXCEPT
    SELECT UBIGEO FROM dbo.agencias WHERE ANIO = 2026
) AS p
JOIN dbo.resultado_distrito AS d ON d.UBIGEO = p.UBIGEO;

-- 3. Verificación de la conclusión: "sobre todo de la Amazonía"
-- Carga de los 100 prioritarios por piso altitudinal (resultado: 67.8% por debajo de 500 m)

SELECT PISO_ALTITUDINAL, COUNT(*) AS distritos,
       CAST(100.0 * SUM(CARGA_VIAJE) / SUM(SUM(CARGA_VIAJE)) OVER () AS decimal(5,1)) AS pct_carga
FROM dbo.resultado_distrito
WHERE RANKING_PRIORIDAD <= 100
GROUP BY PISO_ALTITUDINAL
ORDER BY PISO_ALTITUDINAL;

-- Por debajo de 500 m, por departamento (resultado: ~96% en departamentos amazónicos)

SELECT DEPARTAMENTO, COUNT(*) AS distritos,
       CAST(100.0 * SUM(CARGA_VIAJE) / SUM(SUM(CARGA_VIAJE)) OVER () AS decimal(5,1)) AS pct_carga
FROM dbo.resultado_distrito
WHERE RANKING_PRIORIDAD <= 100 AND ALTITUD < 500
GROUP BY DEPARTAMENTO
ORDER BY pct_carga DESC;
