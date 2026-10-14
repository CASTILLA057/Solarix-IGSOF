# Solarix — ¿Para qué simular la batería? Barrido de configuraciones (Etapa 14)

Generado por `dart run tool/barrido_bateria.dart` el 2026-10-13. Casa de 300 kWh/mes, litio, 10 años simulados, promedio de las semillas 1, 2, 3. Una ciudad por zona climática.

## 1. Degradación

- **SoH**: salud de la batería a los 10 años (%), con cada política.
- **Δ SoH**: consciente − convencional, en puntos.
- **Vida por uso**: años hasta el 80 % según la simulación ("no llega" si casi no se degrada).
- **Vida usada**: la que entra al flujo de caja, la menor entre la vida por uso y la vida calendario (15 años).

| Zona (ciudad) | Sistema | Batería (kWh) | SoH conv. | SoH consc. | Δ SoH | Vida por uso conv. | Vida por uso consc. | Vida usada conv. | Vida usada consc. |
|---|---|---|---|---|---|---|---|---|---|
| Muy soleada (Barranquilla) | Híbrido | 6,2 | 85,0 | 86,6 | 1,6 | 13,3 | 14,9 | 13,3 | 14,9 |
| Muy soleada (Barranquilla) | Aislado, 1 día | 12,3 | 89,7 | 89,8 | 0,0 | 19,3 | 19,4 | 15,0 | 15,0 |
| Muy soleada (Barranquilla) | Aislado, 2 días | 24,7 | 95,8 | 95,8 | 0,0 | 44,5 | 44,5 | 15,0 | 15,0 |
| Muy soleada (Barranquilla) | Aislado, 3 días | 37,0 | 97,4 | 97,4 | 0,0 | 70,5 | 70,4 | 15,0 | 15,0 |
| Mixta (Arauca) | Híbrido | 6,2 | 85,1 | 86,6 | 1,5 | 13,4 | 14,9 | 13,4 | 14,9 |
| Mixta (Arauca) | Aislado, 1 día | 12,3 | 90,0 | 90,1 | 0,1 | 19,8 | 20,1 | 15,0 | 15,0 |
| Mixta (Arauca) | Aislado, 2 días | 24,7 | 95,5 | 95,6 | 0,0 | 42,2 | 42,5 | 15,0 | 15,0 |
| Mixta (Arauca) | Aislado, 3 días | 37,0 | 97,2 | 97,3 | 0,0 | 65,3 | 65,7 | 15,0 | 15,0 |
| Muy nublada (Armenia) | Híbrido | 6,2 | 85,0 | 86,6 | 1,5 | 13,3 | 14,9 | 13,3 | 14,9 |
| Muy nublada (Armenia) | Aislado, 1 día | 12,3 | 89,6 | 89,7 | 0,1 | 19,0 | 19,1 | 15,0 | 15,0 |
| Muy nublada (Armenia) | Aislado, 2 días | 24,7 | 95,7 | 95,7 | 0,0 | 43,3 | 43,4 | 15,0 | 15,0 |
| Muy nublada (Armenia) | Aislado, 3 días | 37,0 | 97,4 | 97,4 | 0,0 | 68,3 | 68,3 | 15,0 | 15,0 |

## 2. Valor presente neto (VPN, 20 años, millones de pesos)

- **Calculadora**: sin simulación, con la vida típica del litio (10 años, la que usa una cotización).
- **Convencional / consciente**: con la vida usada y el aporte de la batería según la simulación.
- **Simulación − calculadora**: cuánto cambia el VPN por simular (política convencional).
- **Gasto actual**: lo que el aislado deja de gastar en la planta diésel. El híbrido ahorra en la factura ($ 890/kWh, estrato 4).

| Zona (ciudad) | Sistema | Gasto actual | Calculadora | Convencional | Consciente | Simulación − calculadora | Consciente − convencional |
|---|---|---|---|---|---|---|---|
| Muy soleada (Barranquilla) | Híbrido | factura | 22,92 | 23,53 | 23,78 | 0,62 | 0,25 |
| Muy soleada (Barranquilla) | Aislado, 1 día | $ 300.000 | 16,65 | 19,08 | 18,97 | 2,43 | -0,11 |
| Muy soleada (Barranquilla) | Aislado, 1 día | $ 450.000 | 39,25 | 41,66 | 41,49 | 2,41 | -0,17 |
| Muy soleada (Barranquilla) | Aislado, 2 días | $ 300.000 | -1,53 | 3,43 | 3,43 | 4,97 | 0,00 |
| Muy soleada (Barranquilla) | Aislado, 2 días | $ 450.000 | 21,07 | 26,03 | 26,03 | 4,97 | 0,00 |
| Muy soleada (Barranquilla) | Aislado, 3 días | $ 300.000 | -19,72 | -12,27 | -12,27 | 7,45 | 0,00 |
| Muy soleada (Barranquilla) | Aislado, 3 días | $ 450.000 | 2,88 | 10,33 | 10,33 | 7,45 | 0,00 |
| Mixta (Arauca) | Híbrido | factura | 21,60 | 22,22 | 22,47 | 0,62 | 0,25 |
| Mixta (Arauca) | Aislado, 1 día | $ 300.000 | 16,65 | 18,98 | 18,77 | 2,33 | -0,21 |
| Mixta (Arauca) | Aislado, 1 día | $ 450.000 | 39,25 | 41,50 | 41,19 | 2,25 | -0,31 |
| Mixta (Arauca) | Aislado, 2 días | $ 300.000 | -1,53 | 3,42 | 3,38 | 4,95 | -0,03 |
| Mixta (Arauca) | Aislado, 2 días | $ 450.000 | 21,07 | 26,01 | 25,96 | 4,94 | -0,05 |
| Mixta (Arauca) | Aislado, 3 días | $ 300.000 | -19,72 | -12,27 | -12,28 | 7,45 | -0,01 |
| Mixta (Arauca) | Aislado, 3 días | $ 450.000 | 2,88 | 10,33 | 10,31 | 7,44 | -0,02 |
| Muy nublada (Armenia) | Híbrido | factura | 21,34 | 21,95 | 22,20 | 0,61 | 0,25 |
| Muy nublada (Armenia) | Aislado, 1 día | $ 300.000 | 15,07 | 17,50 | 17,40 | 2,43 | -0,10 |
| Muy nublada (Armenia) | Aislado, 1 día | $ 450.000 | 37,67 | 40,08 | 39,93 | 2,40 | -0,15 |
| Muy nublada (Armenia) | Aislado, 2 días | $ 300.000 | -3,11 | 1,85 | 1,85 | 4,97 | 0,00 |
| Muy nublada (Armenia) | Aislado, 2 días | $ 450.000 | 19,49 | 24,45 | 24,45 | 4,97 | 0,00 |
| Muy nublada (Armenia) | Aislado, 3 días | $ 300.000 | -21,29 | -13,85 | -13,85 | 7,45 | 0,00 |
| Muy nublada (Armenia) | Aislado, 3 días | $ 450.000 | 1,31 | 8,75 | 8,75 | 7,45 | 0,00 |

## Conclusión

**Qué se midió.** Con la misma casa (300 kWh/mes, ≈ 10 kWh/día), el mismo
clima y las dos políticas, se varió el tamaño de la batería (el híbrido, con
≈ 6 kWh para la noche, y el aislado con 1, 2 y 3 días de autonomía) y la zona
climática. El aislado se evaluó con dos gastos actuales en la planta diésel,
$ 300.000 y $ 450.000 al mes (fuente en `FUENTES.md`).

**1. La política consciente cuida la batería solo cuando la batería trabaja.**
En el híbrido (6,2 kWh) deja el SoH a 10 años en 86,6 % frente a 85,0 % (+1,5
puntos) y alarga la vida por uso de 13,3 a 14,9 años. Con un día de autonomía
(12 kWh) o más, la diferencia es de 0,0 a 0,1 puntos: la batería casi nunca
llega a 95 % de carga ni a 0,16 C, y la política no tiene qué proteger.

**2. En dinero, la política casi no pesa.** En el híbrido la consciente suma
$ 0,25 millones de VPN. En el aislado de un día resta $ 0,1 a 0,3 millones:
al no cargar por encima de 95 % guarda algo menos de energía, y la vida que
entra al flujo ya está en el tope. Con dos días o más la diferencia es $ 0.

**3. Simular sí cambia el VPN frente a la calculadora, y puede cambiar la
decisión.** La calculadora supone que el litio dura 10 años (la garantía
habitual que usa una cotización); la simulación usa la vida por uso, con el
tope calendario de 15 años. Con eso el VPN sube $ 0,6 millones en el híbrido,
≈ $ 2,4 millones en el aislado de un día, ≈ $ 5 millones con dos días y
≈ $ 7,5 millones con tres. En el aislado de dos días con $ 300.000 al mes, la
calculadora dice que no conviene (VPN de −$ 1,5 a −$ 3,1 millones) y la
simulación dice que sí (+$ 1,9 a +$ 3,4 millones).

**4. Pero con baterías grandes lo que mueve el dinero es el supuesto
calendario, no el desgaste.** Desde un día de autonomía la vida por uso (19 a
70 años) supera el tope, así que la mejora del punto 3 sale de comparar 15
años de vida calendario con 10 años de vida típica. Lo que aporta la
simulación es mostrar que esa batería **no se gasta por uso** antes de que la
envejezca el tiempo; cuánto dura por tiempo es un supuesto de 15 años. Si la
vida calendario fuera 10 años, la mejora sería cero. Solo en el híbrido (13,3
años) la vida la fija de verdad el desgaste simulado.

**5. Más batería no siempre conviene.** Con $ 300.000 al mes, pasar de uno a
tres días de autonomía baja el VPN de ≈ +$ 19 a ≈ −$ 12 millones: el ahorro
tiene techo (lo que hoy se gasta en la planta) y la batería extra cuesta más
de lo que ahorra.

**6. La zona climática casi no cambia la degradación, y es por el método.**
El SoH final varía menos de 0,5 puntos entre Barranquilla (muy soleada),
Arauca (mixta) y Armenia (muy nublada) porque la irradiancia de cada ciudad
se ajusta para que el modelo produzca sus HSP reales: la zona solo cambia
cómo se reparten los días nublados, no cuánta energía llega. No es un
hallazgo sobre el clima.

**Qué significa para la decisión de inversión.** Para **elegir cuánta
batería**, la simulación es útil: muestra cuándo una batería pequeña se
desgasta antes de tiempo y cuándo una grande queda limitada por el
calendario, y en un aislado cerca del punto de equilibrio puede inclinar la
decisión. Para **elegir la política**, solo importa con batería pequeña, y en
dinero muy poco.

**Límites de este barrido** (más en `docs/DEFENSA.md`): el modelo está
calibrado a ≈ 1,5 puntos de SoH por año con una batería que trabaja (el
híbrido llega a 85 % a los 10 años, igual que la literatura); con baterías
grandes da 0,3 a 1,0 puntos por año porque solo cuenta el desgaste por uso.
No incluye envejecimiento calendario (por eso el tope), se validó solo contra
NetLogo, el gasto del aislado cuenta solo el combustible (sin mantenimiento
de la planta) y en el modelo el aislado siempre tiene red: lo que compra es
energía que faltó.
