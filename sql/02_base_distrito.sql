-- 02. Tabla base por distrito y distancia a la agencia más cercana
-- Familias: bimestre IV de 2026. Agencias: junio de 2026.
-- Distancia en línea recta entre capitales de distrito (km).

USE JuntosBN;
GO

DROP TABLE IF EXISTS dbo.base_distrito;
GO

WITH juntos_ultimo AS (
    SELECT UBIGEO, DEPARTAMENTO, PROVINCIA, DISTRITO, ABONADOS, TRANSFERENCIA
    FROM dbo.juntos
    WHERE ANIO = 2026 AND BIMESTRE_NUM = 4
),
agencias_2026 AS (
    SELECT UBIGEO, COUNT(*) AS N_AGENCIAS
    FROM dbo.agencias
    WHERE ANIO = 2026
    GROUP BY UBIGEO
)
SELECT
    c.UBIGEO,
    COALESCE(d.DEPARTAMENTO, j.DEPARTAMENTO) AS DEPARTAMENTO,
    COALESCE(d.PROVINCIA,    j.PROVINCIA)    AS PROVINCIA,
    COALESCE(d.DISTRITO,     j.DISTRITO)     AS DISTRITO,
    c.CAPITAL, c.LATITUD, c.LONGITUD, d.ALTITUD, d.SUPERFICIE,
    ISNULL(j.ABONADOS, 0)      AS FAMILIAS_ABONADAS,
    ISNULL(j.TRANSFERENCIA, 0) AS MONTO_BIMESTRE,
    ISNULL(a.N_AGENCIAS, 0)    AS N_AGENCIAS
INTO dbo.base_distrito
FROM dbo.coordenadas AS c
LEFT JOIN dbo.distritos AS d ON d.UBIGEO = c.UBIGEO
LEFT JOIN juntos_ultimo AS j ON j.UBIGEO = c.UBIGEO
LEFT JOIN agencias_2026 AS a ON a.UBIGEO = c.UBIGEO;
GO

-- Distancia: 0 si el distrito tiene agencia; si no, la del distrito con agencia más cercano

DROP TABLE IF EXISTS dbo.base_distancia;
GO

SELECT
    b.*,
    CASE WHEN b.N_AGENCIAS > 0 THEN 0 ELSE ROUND(x.DIST_KM, 1) END    AS DIST_KM,
    CASE WHEN b.N_AGENCIAS > 0 THEN b.UBIGEO   ELSE x.UBIGEO_AGENCIA   END AS UBIGEO_AGENCIA_CERCANA,
    CASE WHEN b.N_AGENCIAS > 0 THEN b.DISTRITO ELSE x.DISTRITO_AGENCIA END AS DISTRITO_AGENCIA_CERCANA
INTO dbo.base_distancia
FROM dbo.base_distrito AS b
OUTER APPLY (
    SELECT TOP 1
        g.UBIGEO   AS UBIGEO_AGENCIA,
        g.DISTRITO AS DISTRITO_AGENCIA,
        geography::Point(b.LATITUD, b.LONGITUD, 4326)
            .STDistance(geography::Point(g.LATITUD, g.LONGITUD, 4326)) / 1000.0 AS DIST_KM
    FROM dbo.base_distrito AS g
    WHERE g.N_AGENCIAS > 0
    ORDER BY DIST_KM
) AS x;
GO

-- Controles: 1,892 filas | familias iguales (762,810) | 481 con agencia | 0 sin distancia

SELECT COUNT(*) AS filas FROM dbo.base_distancia;

SELECT (SELECT SUM(ABONADOS) FROM dbo.juntos WHERE ANIO = 2026 AND BIMESTRE_NUM = 4) AS familias_origen,
       (SELECT SUM(FAMILIAS_ABONADAS) FROM dbo.base_distancia) AS familias_base;

SELECT COUNT(*) AS con_agencia  FROM dbo.base_distancia WHERE N_AGENCIAS > 0;
SELECT COUNT(*) AS sin_distancia FROM dbo.base_distancia WHERE DIST_KM IS NULL;

-- Pregunta 2: familias en distritos sin agencia (esperado: 1,402 distritos, 374,165 familias, 49.1%)

SELECT COUNT(*)               AS distritos_sin_agencia,
       SUM(FAMILIAS_ABONADAS) AS familias_sin_agencia,
       CAST(100.0 * SUM(FAMILIAS_ABONADAS)
            / (SELECT SUM(FAMILIAS_ABONADAS) FROM dbo.base_distancia) AS decimal(5,1)) AS porcentaje
FROM dbo.base_distancia
WHERE N_AGENCIAS = 0 AND FAMILIAS_ABONADAS > 0;
