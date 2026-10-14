
## Conclusión

**Qué se midió.** Con la misma casa (10 kWh/día), el mismo clima y las dos
políticas, se varió el tamaño de la batería (de 0,5 a 3 días de autonomía) y
la zona climática (muy soleada, mixta y muy nublada).

**1. La política consciente importa solo cuando la batería es pequeña.**
Con una batería de unos 6 kWh (el híbrido típico de esta casa, o un aislado
de medio día) la política consciente deja el SoH a 10 años en 86,6 % frente a
85,0 % de la convencional (+1,5 puntos) y alarga la vida por uso de 13,4 a
14,9 años. Con un día de autonomía (12 kWh) o más, la diferencia entre
políticas es de 0,0 a 0,1 puntos: la batería casi no trabaja al límite y la
política no tiene qué proteger.

**2. En dinero, la diferencia es pequeña aun en el mejor caso.** Con batería
pequeña, la política consciente mejora el VPN en unos $ 0,25 millones
(híbrido, ≈ 1 % de su VPN) a $ 0,41 millones (aislado de medio día). Con
batería bien dimensionada la diferencia es $ 0: la vida usada en el flujo de
caja la fija la vida calendario (15 años), no el uso.

**3. La zona climática casi no cambia el resultado.** Entre Barranquilla (muy
soleada), Arauca (mixta) y Armenia (muy nublada) el SoH final varía menos de
0,5 puntos. El clima mueve el VPN por la generación solar, no por la
degradación.

**4. Qué significa para la decisión de inversión.**

- Para decidir **cuánta batería comprar**, la simulación muestra que una
  batería pequeña (≈ medio día) se degrada más (85 % a los 10 años), mientras
  que con un día o más la vida la limita el calendario y más capacidad no la
  alarga en el flujo de caja: solo encarece la inversión (el VPN del aislado
  baja de −$ 19 a −$ 65 millones al pasar de 0,5 a 3 días).
- Para decidir **qué política usar**, importa solo con batería pequeña; con
  batería bien dimensionada es indiferente en dinero y la convencional
  entrega más energía desde el primer año.
- La simulación **no cambia el signo del VPN** en ningún caso probado: no
  convierte una mala inversión en buena ni al revés. Su valor es explicar
  cuánto se desgasta la batería y por qué, y mostrar cuándo el tope calendario
  manda sobre el uso.

**Límites de este barrido** (más en `docs/DEFENSA.md`): el modelo pierde menos
SoH por año que la literatura con una batería bien dimensionada (≈ 0,3 a 1,0
puntos por año con 1 a 3 días de autonomía, frente a 1,3–1,7), no
incluye envejecimiento calendario (por eso el tope de 15 años) y se validó
solo contra NetLogo, no contra baterías reales. Con coeficientes más
agresivos, la política consciente podría importar también con baterías
mayores; con los actuales, no.
