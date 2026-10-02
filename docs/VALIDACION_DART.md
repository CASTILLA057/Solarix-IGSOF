# Solarix — Validación del motor en Dart frente a NetLogo (Etapa 4)

Generado por `dart run tool/validar_motor.dart` el 2026-10-01. Motor: `lib/features/degradacion/domain/`. Referencias: `docs/referencia/VALIDACION.md` (10 corridas de NetLogo por caso) y `docs/referencia/GUIA_VARIACION.md` (5 corridas por caso).

NetLogo usa una semilla aleatoria distinta en cada corrida y su propio generador, así que la comparación es **estadística**: promedios de varias semillas en cada lado. Criterios del plan: SoH promedio a ±0,3 puntos (año a año), energía comprada a ±3 % y limpiezas dentro del rango observado.

Tiempo de una corrida de 10 años (87 600 horas): **63 ms**.

## 1. Casos de VALIDACION.md (10 semillas)

| Escenario | Política | SoH final Dart | SoH final NetLogo | Dif. | Comprada Dart (kWh) | NetLogo | Dif. | Ciclos Dart | NetLogo | Limpiezas Dart | NetLogo | ¿Cumple? |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| media | convencional | 86,07 | 86,09 | −0,02 | 23872 | 23941 | −0,3 % | 2608 | 2606 | 67 | 73 | sí |
| media | consciente | 87,14 | 87,16 | −0,02 | 24952 | 24964 | −0,0 % | 2494 | 2492 | 67 | 73 | sí |
| alta | convencional | 84,98 | 84,98 | +0,00 | 23990 | 23958 | +0,1 % | 2702 | 2702 | 67 | 71 | sí |
| alta | consciente | 86,57 | 86,57 | +0,00 | 25374 | 25402 | −0,1 % | 2556 | 2556 | 67 | 79 | sí |

### SoH año a año, política convencional

| Año | Media Dart | Media NetLogo | Dif. | Alta Dart | Alta NetLogo | Dif. |
|---|---|---|---|---|---|---|
| 0 | 100,00 | 100,00 | +0,00 | 100,00 | 100,00 | +0,00 |
| 1 | 98,74 | 98,75 | −0,01 | 98,60 | 98,60 | +0,00 |
| 2 | 97,33 | 97,34 | −0,01 | 97,05 | 97,06 | −0,01 |
| 3 | 95,91 | 95,93 | −0,02 | 95,48 | 95,48 | +0,00 |
| 4 | 94,45 | 94,49 | −0,04 | 93,90 | 93,91 | −0,01 |
| 5 | 93,00 | 93,05 | −0,05 | 92,34 | 92,35 | −0,01 |
| 6 | 91,57 | 91,61 | −0,04 | 90,81 | 90,81 | −0,00 |
| 7 | 90,19 | 90,20 | −0,01 | 89,31 | 89,30 | +0,01 |
| 8 | 88,78 | 88,81 | −0,03 | 87,83 | 87,83 | +0,00 |
| 9 | 87,42 | 87,43 | −0,01 | 86,39 | 86,39 | −0,00 |
| 10 | 86,07 | 86,09 | −0,02 | 84,98 | 84,98 | +0,00 |

Mayor diferencia año a año: **0,05 puntos** (criterio ±0,3).

### Ajuste a la referencia de 1,5 %/año (igual que validar_modelo.py)

| Escenario | R² Dart | R² NetLogo | RMSE Dart | RMSE NetLogo |
|---|---|---|---|---|
| media | 98,31 % | 98,19 % | 0,0062 | 0,0064 |
| alta | 99,93 % | 99,93 % | 0,0012 | 0,0012 |

### Política consciente frente a convencional

| Escenario | Medida | Cambio Dart | Cambio NetLogo | Objetivo del Word |
|---|---|---|---|---|
| media | Energía comprada | +4,5 % | +4,3 % | +4,8 % |
| media | Flujo de carga (ciclos) | −4,4 % | −4,4 % | −34,0 % |
| media | Caída del SoH | −7,7 % | −7,7 % | −8,7 % |
| alta | Energía comprada | +5,8 % | +6,0 % | +4,8 % |
| alta | Flujo de carga (ciclos) | −5,4 % | −5,4 % | −34,0 % |
| alta | Caída del SoH | −10,6 % | −10,6 % | −8,7 % |

## 2. Sensibilidad: casos de GUIA_VARIACION.md (20 semillas; NetLogo: 5 corridas)

Escenario alto, política convencional y zona mixta, cambiando una variable a la vez. Las limpiezas varían mucho entre corridas (de 32 a 113 en 100 semillas del caso de referencia), así que el promedio se compara con el rango de NetLogo y se usan más semillas que en NetLogo: con solo 5 el promedio de limpiezas depende demasiado de qué años tuvieron tormentas de polvo.

La energía comprada se muestra como promedio ± desviación estándar entre semillas. La diferencia con NetLogo cumple si no supera el mayor entre 3 % y dos errores estándar de la diferencia de medias (2·σ·√(1/20 + 1/5)): cuando se compra poca energía (batería grande) el valor depende de pocas rachas nubladas y varía mucho entre corridas, así que un 3 % fijo confundiría azar con error.

| Caso | SoH Dart | SoH NetLogo | Dif. | Comprada Dart | NetLogo | Dif. | Limpiezas Dart | NetLogo | ¿Cumple? |
|---|---|---|---|---|---|---|---|---|---|
| Referencia | 84,98 | 84,99 | −0,01 | 24017 ± 139 | 23975 | +0,2 % (±3,0 %) | 68 | 40–110 | sí |
| Escenario bajo | 100,00 | 100,00 | −0,00 | 59833 ± 155 | 59845 | −0,0 % (±3,0 %) | 68 | — | sí |
| Escenario medio | 86,06 | 86,07 | −0,01 | 23886 ± 180 | 23842 | +0,2 % (±3,0 %) | 68 | — | sí |
| Política consciente | 86,57 | 86,57 | +0,00 | 25401 ± 139 | 25428 | −0,1 % (±3,0 %) | 68 | — | sí |
| Batería 5 kWh | 84,21 | 84,20 | +0,01 | 36896 ± 139 | 36875 | +0,1 % (±3,0 %) | 68 | — | sí |
| Batería 20 kWh | 88,84 | 88,76 | +0,08 | 6271 ± 407 | 5901 | +6,3 % (±6,9 %) | 68 | — | sí |
| Panel 2 kW | 94,18 | 94,20 | −0,02 | 41470 ± 305 | 41467 | +0,0 % (±3,0 %) | 68 | — | sí |
| Panel 10 kW | 84,49 | 84,49 | −0,00 | 21601 ± 130 | 21577 | +0,1 % (±3,0 %) | 68 | — | sí |
| Tasa C 0,2 | 85,24 | 85,24 | +0,00 | 23981 ± 139 | 24021 | −0,2 % (±3,0 %) | 68 | — | sí |
| Tasa C 1 | 84,98 | 84,98 | +0,00 | 24017 ± 139 | 24068 | −0,2 % (±3,0 %) | 68 | — | sí |
| Carga mínima 10 % | 82,75 | 82,76 | −0,01 | 21197 ± 140 | 21204 | −0,0 % (±3,0 %) | 68 | — | sí |
| Carga mínima 40 % | 89,45 | 89,44 | +0,01 | 29940 ± 139 | 29918 | +0,1 % (±3,0 %) | 68 | — | sí |
| Carga máxima 60 % | 93,61 | 93,62 | −0,01 | 36216 ± 139 | 36149 | +0,2 % (±3,0 %) | 68 | — | sí |
| Carga máxima 80 % | 89,45 | 89,44 | +0,01 | 29938 ± 139 | 29882 | +0,2 % (±3,0 %) | 68 | — | sí |
| Sin polvo | 84,94 | 84,95 | −0,01 | 23849 ± 135 | 23869 | −0,1 % (±3,0 %) | 0 | 0–0 | sí |
| Polvo 0,1 g/h | 84,99 | 84,99 | +0,00 | 24052 ± 137 | 23962 | +0,4 % (±3,0 %) | 244 | 230–293 | sí |
| Umbral de limpieza 2 % | 84,95 | 84,95 | −0,00 | 23891 ± 136 | 23917 | −0,1 % (±3,0 %) | 434 | 343–458 | sí |
| Umbral de limpieza 40 % | 85,07 | 85,06 | +0,01 | 24293 ± 178 | 24166 | +0,5 % (±3,0 %) | 3 | 1–7 | sí |
| Zona muy soleada | 84,83 | 84,83 | −0,00 | 23574 ± 104 | 23488 | +0,4 % (±3,0 %) | 203 | 173–311 | sí |
| Zona muy nublada | 85,11 | 85,11 | +0,00 | 24327 ± 83 | 24295 | +0,1 % (±3,0 %) | 18 | 9–44 | sí |
| Zona lluviosa | 85,18 | 85,18 | −0,00 | 24301 ± 110 | 24171 | +0,5 % (±3,0 %) | 2 | 0–5 | sí |
| Zona polvorienta | 84,91 | 84,91 | +0,00 | 23851 ± 105 | 23961 | −0,5 % (±3,0 %) | 519 | 488–615 | sí |
| Escala de degradación ×0,5 | 91,85 | 91,85 | −0,00 | 23025 ± 139 | — | — | 68 | — | sí |
| Escala de degradación ×2 (fin de vida) | 80,00 | 80,00 | −0,00 | 18147 ± 86 | — | — | 52 | — | sí |
| Exponente 0,9 | 96,95 | 96,95 | +0,00 | 22365 ± 139 | — | — | 68 | — | sí |
| Exponente 1,3 (fin de vida) | 80,00 | 80,00 | −0,00 | 8512 ± 68 | — | — | 22 | — | sí |
| Peso corriente 0 | 87,32 | 87,32 | +0,00 | 23668 ± 139 | — | — | 68 | — | sí |
| Peso corriente 6 | 80,76 | 80,77 | −0,01 | 24667 ± 140 | — | — | 68 | — | sí |
| Peso variación de carga 0 | 88,33 | 88,33 | +0,00 | 23527 ± 139 | — | — | 68 | — | sí |
| Peso variación de carga 5 (fin de vida) | 80,00 | 80,00 | −0,00 | 17961 ± 88 | — | — | 51 | — | sí |

Casos que cumplen: **30 de 30**.

Tiempo total de la validación: 18 s.
