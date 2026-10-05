-- 03. ¿A qué distancia de una agencia viven las familias? (pregunta 3)

USE JuntosBN;

-- 1. Familias por rango de distancia

SELECT
    CASE
        WHEN N_AGENCIAS > 0 THEN '1. Con agencia en su distrito'
        WHEN DIST_KM < 20   THEN '2. Menos de 20 km'
        WHEN DIST_KM < 50   THEN '3. De 20 a 50 km'
        WHEN DIST_KM < 100  THEN '4. De 50 a 100 km'
        ELSE                     '5. Más de 100 km'
    END AS RANGO_DISTANCIA,
    COUNT(*)               AS distritos,
    SUM(FAMILIAS_ABONADAS) AS familias,
    CAST(100.0 * SUM(FAMILIAS_ABONADAS) / SUM(SUM(FAMILIAS_ABONADAS)) OVER () AS decimal(5,1)) AS porcentaje
FROM dbo.base_distancia
WHERE FAMILIAS_ABONADAS > 0
GROUP BY
    CASE
        WHEN N_AGENCIAS > 0 THEN '1. Con agencia en su distrito'
        WHEN DIST_KM < 20   THEN '2. Menos de 20 km'
        WHEN DIST_KM < 50   THEN '3. De 20 a 50 km'
        WHEN DIST_KM < 100  THEN '4. De 50 a 100 km'
        ELSE                     '5. Más de 100 km'
    END
ORDER BY RANGO_DISTANCIA;

-- 2. Por departamento: % de familias sin agencia y distancia promedio ponderada por familias

SELECT
    DEPARTAMENTO,
    SUM(FAMILIAS_ABONADAS) AS familias,
    SUM(CASE WHEN N_AGENCIAS = 0 THEN FAMILIAS_ABONADAS ELSE 0 END) AS familias_sin_agencia,
    CAST(100.0 * SUM(CASE WHEN N_AGENCIAS = 0 THEN FAMILIAS_ABONADAS ELSE 0 END)
         / SUM(FAMILIAS_ABONADAS) AS decimal(5,1)) AS pct_sin_agencia,
    CAST(SUM(FAMILIAS_ABONADAS * DIST_KM) / SUM(FAMILIAS_ABONADAS) AS decimal(6,1)) AS dist_promedio_km
FROM dbo.base_distancia
WHERE FAMILIAS_ABONADAS > 0
GROUP BY DEPARTAMENTO
ORDER BY familias_sin_agencia DESC;

-- 3. Por piso altitudinal

SELECT
    CASE
        WHEN ALTITUD IS NULL THEN '0. Sin dato'
        WHEN ALTITUD < 500   THEN '1. Menos de 500 m'
        WHEN ALTITUD < 2500  THEN '2. De 500 a 2500 m'
        WHEN ALTITUD < 3500  THEN '3. De 2500 a 3500 m'
        ELSE                      '4. Más de 3500 m'
    END AS PISO_ALTITUDINAL,
    SUM(FAMILIAS_ABONADAS) AS familias,
    CAST(100.0 * SUM(CASE WHEN N_AGENCIAS = 0 THEN FAMILIAS_ABONADAS ELSE 0 END)
         / SUM(FAMILIAS_ABONADAS) AS decimal(5,1)) AS pct_sin_agencia,
    CAST(SUM(FAMILIAS_ABONADAS * DIST_KM) / SUM(FAMILIAS_ABONADAS) AS decimal(6,1)) AS dist_promedio_km
FROM dbo.base_distancia
WHERE FAMILIAS_ABONADAS > 0
GROUP BY
    CASE
        WHEN ALTITUD IS NULL THEN '0. Sin dato'
        WHEN ALTITUD < 500   THEN '1. Menos de 500 m'
        WHEN ALTITUD < 2500  THEN '2. De 500 a 2500 m'
        WHEN ALTITUD < 3500  THEN '3. De 2500 a 3500 m'
        ELSE                      '4. Más de 3500 m'
    END
ORDER BY PISO_ALTITUDINAL;
