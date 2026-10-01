# Solarix — Validación del modelo (etapa 14)

Generado por `python herramientas/validar_modelo.py` el 2026-09-29 23:21. Cada cifra es el promedio de **10 corridas** de 10 años (semilla aleatoria), zona mixta y el resto de variables en su valor por defecto.

## (a) Pérdida anual de SoH — política convencional

Referencia: proyección lineal de la Figura 6, 1,5 %/año (banda 1,3–1,7 %, Sidi Lekhel et al., 2026). Umbrales de aceptación del Word: R² ≥ 96,55 % y RMSE ≤ 0,0015 (Onori et al., 2026).

| Escenario | SoH final (%) | Pérdida media (%/año) | ¿En la banda? | R² | RMSE | MAPE (%) | ¿Cumple R² y RMSE? |
|---|---|---|---|---|---|---|---|
| media | 86,09 | 1,39 | sí | 98,19 % | 0,0064 | 0,627 | no |
| alta | 84,98 | 1,50 | sí | 99,93 % | 0,0012 | 0,112 | sí |

SoH año a año (promedio de las réplicas) frente a la referencia:

| Año | Referencia | Media | Alta |
|---|---|---|---|
| 0 | 100,00 | 100,00 | 100,00 |
| 1 | 98,50 | 98,75 | 98,60 |
| 2 | 97,00 | 97,34 | 97,06 |
| 3 | 95,50 | 95,93 | 95,48 |
| 4 | 94,00 | 94,49 | 93,91 |
| 5 | 92,50 | 93,05 | 92,35 |
| 6 | 91,00 | 91,61 | 90,81 |
| 7 | 89,50 | 90,20 | 89,30 |
| 8 | 88,00 | 88,81 | 87,83 |
| 9 | 86,50 | 87,43 | 86,39 |
| 10 | 85,00 | 86,09 | 84,98 |

## (c) Política consciente frente a convencional

Referencia: Mitsunaga et al. (2026), Figura 3: energía comprada +4,8 %, flujo de carga acumulado −34,0 %, caída del SoH −8,7 %. El flujo de carga se mide con los ciclos equivalentes (Ec. 1).

| Escenario | Medida | Convencional | Consciente | Cambio | Objetivo del Word |
|---|---|---|---|---|---|
| media | Energía comprada (kWh) | 23 941 | 24 964 | 4,3 % | +4,8 % |
| media | Flujo de carga (ciclos equiv.) | 2 606 | 2 492 | -4,4 % | −34,0 % |
| media | Caída del SoH (puntos %) | 13,91 | 12,84 | -7,7 % | −8,7 % |
| media | Limpiezas | 73 | 73 | — | — |
| alta | Energía comprada (kWh) | 23 958 | 25 402 | 6,0 % | +4,8 % |
| alta | Flujo de carga (ciclos equiv.) | 2 702 | 2 556 | -5,4 % | −34,0 % |
| alta | Caída del SoH (puntos %) | 15,02 | 13,43 | -10,6 % | −8,7 % |
| alta | Limpiezas | 71 | 79 | — | — |

Dispersión entre réplicas (desviación estándar): media/convencional: caída de SoH ± 0,097 puntos, energía ± 190 kWh; media/consciente: caída de SoH ± 0,087 puntos, energía ± 152 kWh; alta/convencional: caída de SoH ± 0,013 puntos, energía ± 73 kWh; alta/consciente: caída de SoH ± 0,003 puntos, energía ± 144 kWh.

Promedio de los dos escenarios: energía comprada 5,1 % (objetivo +4,8 %), flujo de carga -4,9 % (objetivo −34,0 %), caída del SoH -9,2 % (objetivo −8,7 %).

## Calibración usada

- Degradación (Ec. 5): `escala-degradacion` α = 0,0000078 y `exponente-degradacion` β = 1,1 (antes α = 0,00002 y β = 1). Con β = 1 la pérdida era más rápida los primeros años (≈ 1,9 % el primero y ≈ 1,3 % el décimo) y la curva se alejaba de la proyección lineal; con β = 1,1 la pérdida es casi constante (≈ 1,5 % cada año) y α se ajustó para que el escenario alto termine en 85 %.
- Política consciente: SOC máximo 95 % (`soc-max-consciente`) y tasa C máxima 0,16 (`c-max-consciente`), constantes fijadas en `setup`. La restricción 20–50 % del Word (Satomi et al., 2026) da aquí −67 % de caída del SoH y +62 % de energía comprada: un efecto diez veces más fuerte que el de referencia, por eso se reemplazó.

## Interpretación

- **Patrón (a) — cumple.** Con la política convencional la pérdida es de 1,4–1,5 %/año, dentro de la banda 1,3–1,7 %. El escenario alto (el de referencia del proyecto) supera los umbrales de Onori et al. (R² ≥ 96,55 %, RMSE ≤ 0,0015). El escenario medio tiene R² alto pero RMSE mayor porque la curva es paralela y queda ≈ 1 punto por encima de la línea de 1,5 %/año: pierde menos (≈ 1,4 %/año) porque hay menos sol y la batería cicla algo menos. Sigue dentro de la banda del Word.
- **Patrón (c) — cumple en energía y SoH, no en flujo.** La política consciente reproduce el compromiso del Word: se compra ≈ 5 % más energía a cambio de ≈ 9 % menos caída del SoH. El flujo de carga, en cambio, baja ≈ 5 % y no 34 %. No es posible reproducir los tres números a la vez en este modelo por dos razones: (1) la batería solo sirve para autoconsumo, así que cada kWh que deja de pasar por ella se compra a la red (bajar el flujo 34 % subiría la compra ≈ 35 %); (2) las Ec. 4–5 no incluyen envejecimiento por calendario, así que la caída del SoH es casi proporcional al flujo. Mitsunaga et al. (2026) usan PyBaMM con el modelo electroquímico DFN, donde la capa SEI también crece con el tiempo aunque la batería no se use; es probable que por eso allí −34 % de flujo dé solo −8,7 % de caída del SoH.
- **R², RMSE y MAPE** se calculan contra la proyección de la Figura 6, que es una referencia bibliográfica y no una medición de la batería simulada; por eso el ajuste valida la tendencia, no cada punto.
- **Azar:** la dispersión entre réplicas (tabla anterior) es muy pequeña frente a las diferencias entre políticas, así que las conclusiones no dependen de la semilla.
