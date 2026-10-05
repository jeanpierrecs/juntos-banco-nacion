# Registro de calidad de datos

Observaciones encontradas al preparar y validar los datos del proyecto, con su impacto y la decisión tomada.

## Programa Juntos

| # | Observación | Impacto | Decisión |
|---|---|---|---|
| 1 | El portal publica **versiones acumuladas** con el mismo nombre. En 2024, cada archivo bimestral incluye los anteriores (el archivo 6B contiene los bimestres 1 a 6), y los archivos 3B y 4B son idénticos. En 2025 había una versión I-IV y otra I-VI. | Al unir todos los archivos, el bimestre 1 de 2024 se habría repetido seis veces y todos los resultados se habrían inflado. | Usar un solo archivo por año, el más completo. Resultado: 16 bimestres, 30,143 filas y cero duplicados. |
| 2 | Cada bimestre trae unos 1,884 distritos, más que los 1,874 de las tablas de ubigeo de 2016. | Algunos distritos creados recientemente no tienen coordenadas en las tablas de referencia. | Identificarlos en el cruce y completarlos (ver observación 11). |
| 3 | 1,094 de 11,303 filas de 2025 (casi 10%) tienen **más hogares abonados que afiliados**. | Posibles diferencias de fecha de corte o pagos atrasados. No afecta el análisis, que usa hogares abonados. | Documentarlo y usar siempre hogares abonados. |
| 4 | Pocsí (Arequipa), bimestre 2025-2: sin afiliados ni miembros objetivo, pero con 1 hogar abonado y S/ 200. | Caso aislado. | Mantenerlo. |
| 5 | La ficha del dataset indica que la transferencia se separa por afiliación y cumplimiento, pero el archivo trae un solo total. | Ninguno: el análisis usa el monto total. | Documentarlo. |

## Agencias del Banco de la Nación

| # | Observación | Impacto | Decisión |
|---|---|---|---|
| 6 | Los archivos 2026-1 y 2026-2 son idénticos. | Duplicaría las agencias de 2026. | Usar uno solo. |
| 7 | Encabezados distintos entre años ("FECHA_ CORTE" con espacio y "DIRECCIÓN" con tilde en 2025); el archivo de 2024 no tiene encabezado; el de 2026 tiene una fila vacía al final; codificación Windows (latin1). | Al anexar los años, se creaban columnas duplicadas con valores vacíos, y las tildes y la Ñ se leían mal. | Normalizar nombres de columnas, cargar con codificación 1252 y filtrar la fila vacía. Resultado: 550, 552 y 558 agencias por año. |

## Tablas de ubigeo y coordenadas

| # | Observación | Impacto | Decisión |
|---|---|---|---|
| 8 | Las **coordenadas de la tabla oficial de ubigeos vienen corruptas desde el origen**: por ejemplo, Chachapoyas figura con latitud -62,294 en lugar de -6,2294. El error no es uniforme, y 19 distritos no tienen coordenadas. | Todas las distancias habrían salido mal. | No usar esas coordenadas. Usar la capital de cada distrito desde la tabla de centros poblados (código terminado en 0001). |
| 9 | 811 filas de la tabla de centros poblados venían **envueltas en comillas** y se leían como una sola columna. Entre ellas, capitales como Nasca, Nauta, Namora y Naván. | Esos distritos aparecían sin coordenadas. | Corregirlo en una copia del archivo (`TB_UBIGEOS-2_limpio.csv`), quitando solo las comillas externas. Resultado: 1,874 capitales con coordenadas. |
| 10 | Juntos y las agencias usan el **código de ubigeo del INEI** (1,886 de 1,889 distritos de Juntos coinciden), no el de RENIEC. | Cruzar por el código equivocado habría dejado distritos sin pareja. | Cruzar siempre por el ubigeo del INEI, como texto de 6 dígitos. |
| 11 | 18 distritos creados recientemente no tienen coordenadas en ninguna tabla (4,342 hogares, 0.57% del total). Varios están en zonas alejadas, como el VRAEM. | Excluirlos sesgaría el análisis contra las zonas con peor acceso. | Completar sus coordenadas a mano con Google Maps, ubicando la municipalidad distrital (`coordenadas_manual.csv`). |

## Carga en SQL Server

| # | Observación | Impacto | Decisión |
|---|---|---|---|
| 12 | Los CSV exportados desde Excel usan la **configuración regional en español**: punto y coma como separador, coma decimal y fechas en formato día/mes/año. | Riesgo de leer mal coordenadas y fechas (por ejemplo, 03/06/2024 como 6 de marzo). | Importar esas columnas como texto y convertirlas con SQL de forma controlada (script 00). |
| 13 | Una coordenada ingresada a mano (Cochabamba, 090725) quedó **fuera del territorio peruano**. | Habría distorsionado la distancia de ese distrito. | Detectada por el control de rango del script 01; corregida en la plantilla y en la base. |
| 14 | 3,206 **montos con decimales se multiplicaron por 100** al importarse, por la coma decimal. | El monto total de un bimestre aparecía como S/ 387.9 millones en lugar de S/ 149.9 millones. | Detectado al comparar el porcentaje de dinero con el de familias, que no coincidían. Se volvió a importar la columna como texto y se convirtió con SQL. Los totales se verificaron contra los archivos originales. |
| 15 | Tres coordenadas manuales correspondían a lugares homónimos en otros departamentos: Ninabamba (050514) quedó en Cajamarca, San Antonio (180107) cerca de Lima y Santa Lucía (221006) en Puno. Pasaron el control de rango porque estaban dentro del Perú. | Distancias incorrectas en esos 3 distritos. | Se reemplazaron por coordenadas aproximadas dentro de su provincia correcta. Al recalcular, el top 10 y el 52% del Pareto no cambiaron. Pendiente: ubicar la capital exacta de cada distrito. Lección: además del rango, validar que cada coordenada caiga en su departamento. |
