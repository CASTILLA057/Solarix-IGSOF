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
