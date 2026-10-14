# Solarix — ¿Para qué simular la batería? Barrido de configuraciones (Etapa 14)

Generado por `dart run tool/barrido_bateria.dart` el 2026-10-13. Casa de 300 kWh/mes, litio, 10 años simulados, promedio de las semillas 1, 2, 3. Una ciudad por zona climática.

- **SoH**: salud de la batería a los 10 años (%), con cada política.
- **Δ SoH**: consciente − convencional, en puntos.
- **Vida usada**: años que dura la batería en el flujo de caja (la menor entre la vida por uso y la vida calendario de 15 años).
- **VPN**: valor presente neto a 20 años, en millones de pesos. `Calc.` es el de la calculadora, sin simulación.

| Zona (ciudad) | Sistema | Batería (kWh) | SoH conv. | SoH consc. | Δ SoH | Vida uso conv. | Vida uso consc. | Vida usada conv. | Vida usada consc. | VPN calc. | VPN conv. | VPN consc. | Δ VPN (consc − conv) |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| muySoleada (Barranquilla) | Híbrido | 6,2 | 85,0 | 86,6 | 1,6 | 13,3 | 14,9 | 13,3 | 14,9 | 22,92 | 23,53 | 23,78 | 0,25 |
| muySoleada (Barranquilla) | Aislado 0,5 d | 6,2 | 85,0 | 86,6 | 1,6 | 13,3 | 14,9 | 13,3 | 14,9 | -19,46 | -18,62 | -18,22 | 0,41 |
| muySoleada (Barranquilla) | Aislado 1 d | 12,3 | 89,7 | 89,8 | 0,0 | 19,3 | 19,4 | 15,0 | 15,0 | -28,55 | -26,07 | -26,07 | 0,00 |
| muySoleada (Barranquilla) | Aislado 2 d | 24,7 | 95,8 | 95,8 | 0,0 | 44,5 | 44,5 | 15,0 | 15,0 | -46,73 | -41,77 | -41,77 | 0,00 |
| muySoleada (Barranquilla) | Aislado 3 d | 37,0 | 97,4 | 97,4 | 0,0 | 70,5 | 70,4 | 15,0 | 15,0 | -64,92 | -57,47 | -57,47 | 0,00 |
| mixta (Arauca) | Híbrido | 6,2 | 85,1 | 86,6 | 1,5 | 13,4 | 14,9 | 13,4 | 14,9 | 21,60 | 22,22 | 22,47 | 0,25 |
| mixta (Arauca) | Aislado 0,5 d | 6,2 | 85,1 | 86,6 | 1,5 | 13,4 | 14,9 | 13,4 | 14,9 | -19,46 | -18,62 | -18,22 | 0,41 |
| mixta (Arauca) | Aislado 1 d | 12,3 | 90,0 | 90,1 | 0,1 | 19,8 | 20,1 | 15,0 | 15,0 | -28,55 | -26,07 | -26,07 | 0,00 |
| mixta (Arauca) | Aislado 2 d | 24,7 | 95,5 | 95,6 | 0,0 | 42,2 | 42,5 | 15,0 | 15,0 | -46,73 | -41,77 | -41,77 | 0,00 |
| mixta (Arauca) | Aislado 3 d | 37,0 | 97,2 | 97,3 | 0,0 | 65,3 | 65,7 | 15,0 | 15,0 | -64,92 | -57,47 | -57,47 | 0,00 |
| muyNublada (Armenia) | Híbrido | 6,2 | 85,0 | 86,6 | 1,5 | 13,3 | 14,9 | 13,3 | 14,9 | 21,34 | 21,95 | 22,20 | 0,25 |
| muyNublada (Armenia) | Aislado 0,5 d | 6,2 | 85,0 | 86,6 | 1,5 | 13,3 | 14,9 | 13,3 | 14,9 | -21,03 | -20,20 | -19,79 | 0,41 |
| muyNublada (Armenia) | Aislado 1 d | 12,3 | 89,6 | 89,7 | 0,1 | 19,0 | 19,1 | 15,0 | 15,0 | -30,13 | -27,64 | -27,64 | 0,00 |
| muyNublada (Armenia) | Aislado 2 d | 24,7 | 95,7 | 95,7 | 0,0 | 43,3 | 43,4 | 15,0 | 15,0 | -48,31 | -43,34 | -43,34 | 0,00 |
| muyNublada (Armenia) | Aislado 3 d | 37,0 | 97,4 | 97,4 | 0,0 | 68,3 | 68,3 | 15,0 | 15,0 | -66,49 | -59,04 | -59,04 | 0,00 |

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
