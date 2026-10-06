# ¿Cuánto tiene que viajar una familia del programa Juntos hasta la agencia más cercana del Banco de la Nación?

Perú, 2026 · Datos abiertos · SQL Server · Power BI

Cada dos meses, más de 760 mil familias en situación de pobreza reciben la transferencia del programa Juntos en una cuenta del Banco de la Nación. Quise saber qué tan lejos les queda una agencia y dónde haría más diferencia abrir una nueva.

![Conclusiones](img/04_conclusiones.png)

## Lo que encontré

**La mitad de las familias vive en un distrito sin agencia.** Son 374,165 familias (49.1%) en 1,402 distritos, y cada bimestre reciben S/ 73.8 millones.

![Resumen](img/01_resumen.png)

**Una de cada seis vive a más de 20 km de una agencia.** El problema cambia con la geografía: en la selva baja, las agencias quedan lejos; en la sierra alta, sobre los 3,500 m, faltan. Allí, 2 de cada 3 familias no tienen una en su distrito.

![Distancia](img/02_distancia.png)

**El problema está concentrado.** Para priorizar usé la carga de viaje: familias × km hasta la agencia más cercana. 100 distritos, el 7% de los que no tienen agencia, suman el 52% de esa carga. Dos tercios están en la selva baja amazónica, sobre todo en Loreto.

**Tener agente no siempre alcanza.** Revisé a mano los 10 distritos prioritarios: todos tienen al menos un agente, pero en Balsapuerto (Loreto) hay uno por cada 2,263 familias. En Pebas, uno por cada 125.

![Prioridades](img/03_prioridades.png)

**Las aperturas recientes no siguieron este criterio.** De las 5 agencias abiertas entre 2024 y 2026, solo la de Sepahua (Ucayali) quedó en un distrito prioritario. El banco abre agencias por varias razones; este análisis solo muestra que esas aperturas no coincidieron con la distancia que recorren las familias.

## Qué propongo

1. **Priorizar 100 distritos:** decidir las nuevas aperturas según la carga de viaje.
2. **Amazonía:** sumar agentes donde están saturados, como en Balsapuerto, y evaluar canales fluviales.
3. **Sierra alta:** instalar agentes o agencias donde faltan, y ofrecer pagos digitales donde haya señal.

Son propuestas: los datos no miden la conectividad ni la capacidad de cada agente.

## Cómo lo hice

**Datos abiertos → Power Query → SQL Server → Power BI**

| Paso | Herramienta | Qué resolví |
|---|---|---|
| Preparar | Power Query | Uní 3 años de Juntos (30,143 filas, 16 bimestres) y 3 cortes de agencias. Detecté archivos acumulados y duplicados que habrían inflado los resultados. |
| Cargar | SQL Server | Los CSV traían formato regional (coma decimal, fechas día/mes/año). Importé esas columnas como texto y las convertí en SQL, con controles de totales. |
| Validar | SQL Server | 7 controles: conteos, duplicados, ubigeo de 6 dígitos, coordenadas dentro del Perú y cruces sin pareja. Detectaron errores reales, como montos multiplicados por 100. |
| Medir distancias | SQL Server | Para cada uno de los 1,402 distritos sin agencia, busqué la agencia más cercana con `geography::Point`, `STDistance` y `OUTER APPLY`. |
| Priorizar | SQL Server | Calculé la carga de viaje, el ranking con `ROW_NUMBER()` y la curva de Pareto con `SUM() OVER()`. |
| Evaluar | SQL Server | Recalculé el ranking con la red de agencias de 2024 para juzgar las aperturas con la información de ese momento. |
| Visualizar | Power BI | Modelo con relaciones por ubigeo, medidas DAX (porcentajes, Pareto acumulado, colores condicionales) y mapa con Azure Maps. |
| Verificar | Manual | Revisé los agentes de los 10 distritos prioritarios en el buscador del Banco de la Nación. |

**¿Por qué carga de viaje y no un índice con pesos?** Porque no necesita pesos arbitrarios: mide directamente cuántas familias viajan y qué tan lejos, igual que en logística se mide el transporte (carga × distancia).

Los scripts están en [`sql/`](sql/), en orden de ejecución (00 a 05). Archivo de Power BI: [descargar](https://github.com/jeanpierrecs/juntos-banco-nacion/raw/main/pbix/juntos_banco_nacion.pbix).

## Datos

| Fuente | Para qué | Volumen |
|---|---|---|
| [MIDIS – Programa Juntos](https://www.datosabiertos.gob.pe/group/programa-nacional-de-apoyo-directo-los-m%C3%A1s-pobres-juntos-juntos) | Familias y montos por distrito | 30,143 filas · 2024-2026 |
| [Banco de la Nación – Agencias](https://www.datosabiertos.gob.pe/dataset/relacion-de-agencias-y-oficinas-especiales-nivel-nacional-banco-de-la-naci%C3%B3n-bn) | Agencias por distrito | 1,660 registros · junio de 2024, 2025 y 2026 |
| [Códigos equivalentes de ubigeo](https://www.datosabiertos.gob.pe/dataset/codigos-equivalentes-de-ubigeo-del-peru) | Distritos, altitud y superficie | 1,893 distritos |
| [ubigeo-peru-aumentado (GitHub)](https://github.com/jmcastagnetto/ubigeo-peru-aumentado) | Coordenadas de las capitales de distrito | 94,922 centros poblados · 1,874 capitales |
| Google Maps | Coordenadas de distritos creados recientemente | 18 distritos |
| [Banco de la Nación – Agentes](https://www.bn.com.pe/canales-atencion/agentes-nivel-nacional.asp) | Agentes en los distritos prioritarios | 10 distritos, revisión manual |

Todas las fuentes son públicas: datos abiertos del Estado peruano y un repositorio público en GitHub.

## Limitaciones

- La distancia es en línea recta entre capitales de distrito. Por carretera o por río es mayor, así que los resultados son un mínimo.
- Los agentes solo se verificaron en los 10 distritos prioritarios: el banco no publica un archivo descargable.
- No hay datos públicos de ventanillas móviles ni de conectividad.
- Tres distritos nuevos usan coordenadas aproximadas dentro de su provincia.

En el camino encontré 15 problemas de calidad en los datos, como archivos duplicados, coordenadas corruptas en la fuente y montos multiplicados por 100 al importar. Cada uno está documentado con su solución en el [registro de calidad](docs/registro_calidad.md).

---

*Si la próxima agencia se decidiera por la distancia que recorren las familias, ¿dónde estaría?*

**Jean Pierre Castañeda Silva** · Analista de Datos y BI · [LinkedIn](https://www.linkedin.com/in/jeanpierrecs)
