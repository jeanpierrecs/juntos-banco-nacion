-- 04. Carga de viaje, ranking de prioridad y validación de agentes (preguntas 4 y 5)
-- Carga de viaje = familias x km a la agencia más cercana (solo distritos sin agencia).

USE JuntosBN;
GO

-- 1. Tabla final para Power BI

DROP TABLE IF EXISTS dbo.resultado_distrito;
GO

SELECT
    b.*,
    CASE WHEN b.N_AGENCIAS = 0
         THEN CAST(b.FAMILIAS_ABONADAS * b.DIST_KM AS decimal(14,1)) ELSE 0 END AS CARGA_VIAJE,
    CASE
        WHEN b.N_AGENCIAS > 0 THEN '1. Con agencia en su distrito'
        WHEN b.DIST_KM < 20   THEN '2. Menos de 20 km'
        WHEN b.DIST_KM < 50   THEN '3. De 20 a 50 km'
        WHEN b.DIST_KM < 100  THEN '4. De 50 a 100 km'
        ELSE                       '5. Más de 100 km'
    END AS RANGO_DISTANCIA,
    CASE
        WHEN b.ALTITUD IS NULL THEN '0. Sin dato'
        WHEN b.ALTITUD < 500   THEN '1. Menos de 500 m'
        WHEN b.ALTITUD < 2500  THEN '2. De 500 a 2500 m'
        WHEN b.ALTITUD < 3500  THEN '3. De 2500 a 3500 m'
        ELSE                        '4. Más de 3500 m'
    END AS PISO_ALTITUDINAL
INTO dbo.resultado_distrito
FROM dbo.base_distancia AS b;
GO

ALTER TABLE dbo.resultado_distrito ADD RANKING_PRIORIDAD int NULL;
GO

-- 2. Ranking: 1 = mayor carga de viaje

WITH r AS (
    SELECT UBIGEO, ROW_NUMBER() OVER (ORDER BY CARGA_VIAJE DESC) AS puesto
    FROM dbo.resultado_distrito
    WHERE N_AGENCIAS = 0 AND FAMILIAS_ABONADAS > 0
)
UPDATE d SET RANKING_PRIORIDAD = r.puesto
FROM dbo.resultado_distrito AS d
JOIN r ON r.UBIGEO = d.UBIGEO;

-- Los 10 prioritarios (esperado: Río Santiago primero)
SELECT TOP 10 RANKING_PRIORIDAD, DEPARTAMENTO, DISTRITO, FAMILIAS_ABONADAS, DIST_KM, CARGA_VIAJE
FROM dbo.resultado_distrito
WHERE RANKING_PRIORIDAD IS NOT NULL
ORDER BY RANKING_PRIORIDAD;

-- 3. Pareto: % de la carga en los primeros 10, 50, 100 y 200 (esperado: 17.0 / 39.2 / 52.0 / 67.5)
WITH acumulado AS (
    SELECT RANKING_PRIORIDAD,
           SUM(CARGA_VIAJE) OVER ()                          AS total,
           SUM(CARGA_VIAJE) OVER (ORDER BY RANKING_PRIORIDAD) AS acum
    FROM dbo.resultado_distrito
    WHERE RANKING_PRIORIDAD IS NOT NULL
)
SELECT RANKING_PRIORIDAD AS primeros_distritos,
       CAST(100.0 * acum / total AS decimal(5,1)) AS pct_carga_acumulada
FROM acumulado
WHERE RANKING_PRIORIDAD IN (10, 50, 100, 200);

-- 4. Validación manual de agentes en los 10 prioritarios
-- Fuente: https://www.bn.com.pe/canales-atencion/agentes-nivel-nacional.asp (revisado el 2026-10-02)

DROP TABLE IF EXISTS dbo.validacion_agentes;
GO

SELECT UBIGEO, DEPARTAMENTO, PROVINCIA, DISTRITO,
       CAST('SI' AS nvarchar(2))           AS TIENE_AGENTE,
       CASE UBIGEO
           WHEN '160107' THEN 3    -- Napo
           WHEN '010403' THEN 4    -- Río Santiago
           WHEN '120608' THEN 10   -- Río Tambo
           WHEN '160202' THEN 1    -- Balsapuerto
           WHEN '160303' THEN 2    -- Tigre
           WHEN '160304' THEN 4    -- Trompeteros
           WHEN '160305' THEN 5    -- Urarinas
           WHEN '160402' THEN 8    -- Pebas
           WHEN '160605' THEN 2    -- Sarayacu
           WHEN '160706' THEN 1    -- Andoas
       END                                 AS N_AGENTES,
       CAST('2026-10-02' AS date)          AS FECHA_REVISION
INTO dbo.validacion_agentes
FROM dbo.resultado_distrito
WHERE RANKING_PRIORIDAD <= 10;
GO

-- Familias por agente (esperado: Balsapuerto primero, con 2,263)
SELECT r.RANKING_PRIORIDAD, r.DISTRITO, r.FAMILIAS_ABONADAS, v.N_AGENTES,
       r.FAMILIAS_ABONADAS / v.N_AGENTES AS FAMILIAS_POR_AGENTE
FROM dbo.resultado_distrito AS r
JOIN dbo.validacion_agentes AS v ON v.UBIGEO = r.UBIGEO
ORDER BY FAMILIAS_POR_AGENTE DESC;
