-- 00. Ajuste de tipos después de importar los CSV (formato regional en español)
-- LATITUD, LONGITUD, FECHA_CORTE y TRANSFERENCIA se importan como texto y se convierten aquí.
USE JuntosBN;
GO

-- 1. Coordenadas: coma decimal -> número

ALTER TABLE dbo.coordenadas ADD LAT float NULL, LON float NULL;
GO
UPDATE dbo.coordenadas
SET LAT = TRY_CAST(REPLACE(LATITUD,  ',', '.') AS float),
    LON = TRY_CAST(REPLACE(LONGITUD, ',', '.') AS float);

-- Control: esperado 0 filas
SELECT UBIGEO, LATITUD, LONGITUD FROM dbo.coordenadas WHERE LAT IS NULL OR LON IS NULL;

ALTER TABLE dbo.coordenadas DROP COLUMN LATITUD, LONGITUD;
GO
EXEC sp_rename 'dbo.coordenadas.LAT', 'LATITUD',  'COLUMN';
EXEC sp_rename 'dbo.coordenadas.LON', 'LONGITUD', 'COLUMN';

ALTER TABLE dbo.coordenadas ALTER COLUMN UBIGEO nvarchar(6) NOT NULL;
GO
ALTER TABLE dbo.coordenadas ADD CONSTRAINT PK_coordenadas PRIMARY KEY (UBIGEO);
GO

-- 2. Fecha de corte de agencias: dd/mm/aaaa -> date (estilo 103)

ALTER TABLE dbo.agencias ADD FECHA date NULL;
GO
UPDATE dbo.agencias SET FECHA = TRY_CONVERT(date, FECHA_CORTE, 103);

-- Control: esperado 3 fechas (2024-06-03, 2025-06-03, 2026-06-09), sin NULL
SELECT FECHA, COUNT(*) AS agencias FROM dbo.agencias GROUP BY FECHA ORDER BY FECHA;

ALTER TABLE dbo.agencias DROP COLUMN FECHA_CORTE;
GO
EXEC sp_rename 'dbo.agencias.FECHA', 'FECHA_CORTE', 'COLUMN';

-- 3. Montos de Juntos: coma decimal -> número
-- Importados como número, los montos con decimales se multiplicaban por 100.

ALTER TABLE dbo.juntos ADD TRANSF decimal(14,2) NULL;
GO
UPDATE dbo.juntos
SET TRANSF = ROUND(TRY_CAST(REPLACE(TRANSFERENCIA, ',', '.') AS decimal(18,6)), 2);

-- Control: 2024 = 868,687,335.63 | 2025 = 873,413,651.42 | 2026 = 603,104,270.85
SELECT ANIO, SUM(TRANSF) AS total FROM dbo.juntos GROUP BY ANIO ORDER BY ANIO;

ALTER TABLE dbo.juntos DROP COLUMN TRANSFERENCIA;
GO
EXEC sp_rename 'dbo.juntos.TRANSF', 'TRANSFERENCIA', 'COLUMN';

-- 4. Corrección manual: Cochabamba (090725) quedó fuera del Perú (control 5 del script 01)

UPDATE dbo.coordenadas
SET LATITUD  = -00.0000000,   -- COMPLETAR
    LONGITUD = -00.0000000    -- COMPLETAR
WHERE UBIGEO = '090725';
