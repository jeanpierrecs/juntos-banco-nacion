-- 01. Validación de la carga. Cada consulta indica el resultado esperado.
USE JuntosBN;

-- 1. Filas por tabla: juntos 30,143 | agencias 1,660 | distritos 1,893 | coordenadas 1,892

SELECT 'juntos' AS tabla, COUNT(*) AS filas FROM dbo.juntos
UNION ALL SELECT 'agencias',    COUNT(*) FROM dbo.agencias
UNION ALL SELECT 'distritos',   COUNT(*) FROM dbo.distritos
UNION ALL SELECT 'coordenadas', COUNT(*) FROM dbo.coordenadas;

-- 2. Filas por año: juntos 11,307 / 11,303 / 7,533 | agencias 550 / 552 / 558

SELECT ANIO, COUNT(*) AS filas FROM dbo.juntos   GROUP BY ANIO ORDER BY ANIO;
SELECT ANIO, COUNT(*) AS filas FROM dbo.agencias GROUP BY ANIO ORDER BY ANIO;

-- 3. Ubigeos que no tienen 6 dígitos: 0 en las cuatro tablas

SELECT 'juntos' AS tabla, COUNT(*) AS errores FROM dbo.juntos WHERE LEN(UBIGEO) <> 6
UNION ALL SELECT 'agencias',    COUNT(*) FROM dbo.agencias    WHERE LEN(UBIGEO) <> 6
UNION ALL SELECT 'distritos',   COUNT(*) FROM dbo.distritos   WHERE LEN(UBIGEO) <> 6
UNION ALL SELECT 'coordenadas', COUNT(*) FROM dbo.coordenadas WHERE LEN(UBIGEO) <> 6;

-- 4. Duplicados en juntos (distrito repetido en un bimestre): 0 filas

SELECT ANIO, BIMESTRE_NUM, UBIGEO, COUNT(*) AS veces
FROM dbo.juntos
GROUP BY ANIO, BIMESTRE_NUM, UBIGEO
HAVING COUNT(*) > 1;

-- 5. Coordenadas fuera del Perú: 0 filas

SELECT UBIGEO, CAPITAL, LATITUD, LONGITUD
FROM dbo.coordenadas
WHERE LATITUD NOT BETWEEN -18.4 AND 0
   OR LONGITUD NOT BETWEEN -81.4 AND -68.6;

-- 6. Distritos de Juntos sin coordenadas: 0 filas

SELECT DISTINCT j.UBIGEO, j.DISTRITO
FROM dbo.juntos AS j
LEFT JOIN dbo.coordenadas AS c ON c.UBIGEO = j.UBIGEO
WHERE c.UBIGEO IS NULL;

-- 7. Agencias sin distrito en la tabla de distritos: 0 filas

SELECT a.ANIO, a.AGENCIA, a.UBIGEO
FROM dbo.agencias AS a
LEFT JOIN dbo.distritos AS d ON d.UBIGEO = a.UBIGEO
WHERE d.UBIGEO IS NULL;
