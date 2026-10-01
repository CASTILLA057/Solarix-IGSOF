# Solarix — Guía para variar las variables y leer los resultados

Sirve para saber **qué mover, cuánto y qué esperar**. Las variables y sus valores por defecto están en `VARIABLES_INTERFAZ.md` y `EXPLICACION_MODELO.md`. Las cifras corresponden al modelo con **días reales** y **clima aleatorio** (etapas 11 a 13), calibrado y validado en la etapa 14: 10 años = 87 600 horas.

## 1. Método para experimentar

1. Sube `velocidad` (8 o 9) para llegar rápido al final; con `velocidad` 2 a 5 puedes ver los días pasar. Pulsa `setup`, luego `go`. La corrida termina sola a los 87 600 ticks (10 años) o cuando el SoH baja de 80 %, y la escena muestra "FIN: SoH …".
2. **Cambia una sola variable por corrida** y mantén las demás en su valor por defecto; si mueves varias, no sabrás cuál causó el cambio.
3. **Ojo con el azar.** Cada corrida usa un clima distinto y los resultados cambian un poco aunque no muevas nada (sección 2, "Azar entre corridas"). Para comparar dos configuraciones sin ese ruido, repite cada una varias veces y promedia.
4. Después de mover un slider vuelve a pulsar `setup`; el cambio se aplica a la corrida nueva. (`velocidad` sí se puede mover durante la corrida.)
5. Lee los resultados **al final** de la corrida (sección 4). Durante la corrida los monitores acumulan.

## 2. Qué esperar al mover cada variable

Cada cifra es el **promedio de 5 corridas aleatorias** de 10 años, escenario **alto**, política **convencional**, zona **mixta**, moviendo una variable a la vez (las demás en su valor por defecto). Medido después de la calibración de la etapa 14. Referencia: **SoH final ≈ 85,0 % (1,5 % por año), energía comprada ≈ 24 000 kWh, ≈ 70 limpiezas (varía entre 40 y 110 según la corrida), ≈ 2 700 ciclos.** Diferencias de menos de ≈ 1 % en energía comprada o de unas 20–30 limpiezas están dentro del ruido del azar.

### Escenario y política

| Variable | Valores probados | SoH final | Energía comprada (kWh) | Qué pasa |
|---|---|---|---|---|
| `escenario-irradiancia` | baja / media / alta | 100,00 / 86,07 / 84,99 | 59 845 / 23 842 / 23 975 | Con sol bajo casi no hay excedente para cargar la batería, así que casi no se degrada, pero se compra casi todo a la red. Media y alta se parecen: la batería se llena igual. |
| `politica` | convencional / consciente | 84,99 / 86,57 | 23 983 / 25 428 | La consciente no carga por encima de 95 % y limita la corriente a 0,16 C: la caída del SoH baja ≈ 10 % a cambio de comprar ≈ 5 % más energía a la red (patrón de Mitsunaga et al., 2026; ver `VALIDACION.md`). |

### Sistema físico

| Variable | Valores probados | SoH final | Energía comprada (kWh) | Qué pasa |
|---|---|---|---|---|
| `capacidad-bateria` | 5 / 10 / 20 | 84,20 / 84,98 / 88,76 | 36 875 / 23 986 / 5 901 | Más batería = se compra mucho menos a la red y la degradación baja algo (mismo trabajo repartido en más capacidad). Es la variable que más reduce la energía comprada. |
| `potencia-panel` | 2 / 5 / 10 | 94,20 / 84,97 / 84,49 | 41 467 / 24 006 / 21 577 | Un panel chico casi no carga la batería (poca degradación, mucha compra). Pasar de 5 a 10 kW ayuda poco: la batería ya se llena. |
| `tasa-c-maxima` | 0,2 / 0,5 / 1 | 85,24 / 84,97 / 84,98 | 24 021 / 23 983 / 24 068 | De 0,5 en adelante no cambia nada porque la potencia de esta casa nunca llega al límite. A 0,2 apenas se nota. |
| `carga-minima` | 10 / 20 / 40 | 82,76 / 84,98 / 89,44 | 21 204 / 23 930 / 29 918 | Permitir descargar más profundo (10 %) da más energía usable y menos compra, pero desgasta más. Subir a 40 % protege la batería y aumenta la compra a la red. |
| `carga-maxima` (solo convencional) | 60 / 80 / 100 | 93,62 / 89,44 / 84,98 | 36 149 / 29 882 / 23 972 | Cargar solo hasta 60 % reduce mucho el desgaste pero deja poca energía utilizable. Lo que importa es el **ancho de la ventana** de uso: `carga-maxima` 80 con `carga-minima` 20 (ventana de 60 %) da lo mismo que 100 con 40. Con política consciente el tope es el menor entre este valor y 95 %. |

### Polvo y limpieza

| Variable | Valores probados | SoH final | Energía comprada (kWh) | Limpiezas (promedio y rango) | Qué pasa |
|---|---|---|---|---|---|
| `tasa-polvo` | 0 / 0,036 / 0,1 | 84,95 / 84,98 / 84,99 | 23 869 / 23 980 / 23 962 | 0 / 89 (70–110) / 260 (230–293) | Más polvo obliga a limpiar más veces; la producción casi no cae porque el EMS limpia a tiempo. |
| `umbral-limpieza` | 2 / 10 / 40 | 84,95 / 84,99 / 85,06 | 23 917 / 23 948 / 24 166 | 409 (343–458) / 64 (42–107) / 3 (1–7) | Con 2 % se limpia muy seguido; con 40 % casi nunca se llega al umbral y se compra solo ≈ 1 % más energía, porque la lluvia lava parte del polvo. El efecto en la salud de la batería es mínimo. |

### Zona climática

**Qué cambia la zona.** Cada zona multiplica tres factores del clima (detalle en `EXPLICACION_MODELO.md`, sección 5). Encima se aplican las variaciones aleatorias de cada año (años más secos o lluviosos y con más o menos polvo).

| `zona` | Probabilidad de lluvia | Nubosidad | Polvo que llega (y tormentas) |
|---|---|---|---|
| mixta | × 1 | × 1 | × 1 |
| muy soleada | × 0,3 | × 0,6 | × 1,5 |
| muy nublada | × 1,3 | × 1,35 | × 0,7 |
| lluviosa | × 2 | × 1,2 | × 0,4 |
| polvorienta | × 0,6 | × 0,9 | × 4 |

**Resultados con los valores por defecto** (panel de 5 kW, batería de 10 kWh). Promedio de 8 corridas de 10 años, escenario alto, política convencional; los días son por año y los cambios entre paréntesis son frente a la zona mixta:

| `zona` | Días soleados / nublados / lluvia / tormenta | Irradiancia media (W/m²) | Generación solar (kWh) | Energía comprada (kWh) | Limpiezas (rango) | Polvo medio (g) | SoH final |
|---|---|---|---|---|---|---|---|
| mixta | 146 / 112 / 98 / 9,5 | 190 | 74 130 | 24 047 | 74 (49–99) | 14,0 | 84,98 |
| muy soleada | 198 / 136 / 18 / 13,6 | 224 | 85 998 (+16 %) | 23 566 (−2,0 %) | 212 (152–288) | 18,1 | 84,83 |
| muy nublada | 106 / 84 / 169 / 6,1 | 165 | 66 142 (−11 %) | 24 383 (+1,4 %) | 18 (14–27) | 8,4 | 85,12 |
| lluviosa | 56 / 50 / 255 / 3,6 | 153 | 62 507 (−16 %) | 24 298 (+1,0 %) | 1 (0–3) | 2,8 | 85,18 |
| polvorienta | 174 / 128 / 38 / 25,1 | 205 | 78 867 (+6 %) | 23 911 (−0,6 %) | 535 (412–661) | 21,4 | 84,91 |

**Con un panel más chico la zona sí pesa** (panel de 2 kW, lo demás igual, 8 corridas):

| `zona` | Generación solar (kWh) | Energía comprada (kWh) | Ciclos equiv. | SoH final |
|---|---|---|---|---|
| mixta | 29 673 | 41 603 | 1 348 | 94,23 |
| muy soleada | 34 378 (+16 %) | 37 561 (−9,7 %) | 1 720 | 92,17 |
| muy nublada | 26 826 (−10 %) | 43 887 (+5,5 %) | 1 130 | 95,36 |
| lluviosa | 25 484 (−14 %) | 44 780 (+7,6 %) | 1 029 | 95,88 |
| polvorienta | 31 439 (+6 %) | 40 124 (−3,6 %) | 1 485 | 93,49 |

**Qué pasa en cada zona**
- **Mixta (referencia):** clima intermedio, con unos 100 días de lluvia al año. Se limpia ≈ 7 veces por año.
- **Muy soleada:** casi no llueve (≈ 18 días al año) y las nubes son más delgadas: la irradiancia media sube ≈ 18 % y la generación ≈ 16 %. Como la lluvia casi no lava los paneles y llega 1,5 veces más polvo, se limpia unas 3 veces más (≈ 21 por año). Con más energía disponible la batería trabaja más, así que es la zona donde **más se degrada** la batería (con panel de 2 kW pierde ≈ 36 % más SoH que en la mixta).
- **Muy nublada:** las nubes son más gruesas y llueve más; la generación baja ≈ 11 %. Llega menos polvo y la lluvia lo lava, así que casi no se limpia (≈ 2 por año). La batería se usa menos y se degrada un poco menos.
- **Lluviosa:** llueve ≈ 255 días al año; es la zona con **menos sol** (−16 % de generación) y con los paneles más limpios: prácticamente nunca hace falta limpiar. Es la zona donde **menos se degrada** la batería y donde más energía se compra.
- **Polvorienta:** llega 4 veces más polvo y hay ≈ 25 días de tormenta de polvo al año: se limpia ≈ 53 veces por año, 7 veces más que en la mixta. Aun así genera ≈ 6 % **más** que la mixta, porque llueve menos y hay menos nubes, y el EMS limpia antes de que el polvo haga perder mucha potencia.

**Cómo leer estos resultados**
- Con el panel de 5 kW la zona cambia mucho la **generación** (de −16 % a +16 %) pero muy poco la **energía comprada** (±2 %) y el **SoH** (±0,2 puntos): la batería se llena casi todos los días con cualquier clima y la energía que sobra se pierde (no se vende a la red). Con un panel de 2 kW la batería ya no se llena siempre, y la zona sí cambia la compra (−10 % a +8 %) y el desgaste.
- Los **días nublados** de la tabla no cuentan los de lluvia, que también son nublados. Por eso la zona muy soleada tiene más días "nublados" que la mixta (al casi no llover, esos días se reparten entre soleados y nublados), aunque sus nubes son más delgadas; y la muy nublada tiene más días de lluvia que nublados.
- El **polvo medio** no crece tanto como el polvo que llega porque el EMS limpia cada vez que la pérdida de potencia supera `umbral-limpieza`; la zona se nota sobre todo en el **número de limpiezas**.
- La zona es el único control del clima. Para un sistema sin polvo se puede poner `tasa-polvo` en 0.
- **Ojo al guardar el modelo:** NetLogo guarda la zona (y los demás selectores) que esté elegida en ese momento, y es la que aparece al volver a abrirlo. Revisa la zona antes de pulsar `setup`.

### Degradación (calibración)

Estos cuatro no describen la casa sino **qué tan rápido se gasta la batería**. Cámbialos solo para analizar sensibilidad del modelo. Sus valores por defecto se calibraron en la etapa 14 (`VALIDACION.md`).

| Variable | Valores probados | SoH final | Qué pasa |
|---|---|---|---|
| `escala-degradacion` | 0,0000039 / 0,0000078 / 0,0000156 | 91,85 / 84,98 / 80,00 (fin de vida al tick ≈ 64 200, ≈ 7,3 años) | Escala general: duplicarla casi duplica la pérdida. Es la perilla principal de calibración. |
| `exponente-degradacion` | 0,9 / 1,1 / 1,3 | 96,95 / 84,98 / 80,00 (fin de vida al tick ≈ 30 400, ≈ 3,5 años) | **Muy sensible.** Menor que 1 frena la degradación con el tiempo; mayor que 1 la acelera. Con 1,1 la pérdida es casi constante año a año. Si lo cambias, hay que recalibrar `escala-degradacion`. |
| `peso-corriente` | 0 / 2 / 6 | 87,32 / 84,97 / 80,77 | Castiga el uso a potencias altas. A 0 se ignora ese efecto. |
| `peso-variacion-carga` | 0 / 1 / 5 | 88,33 / 84,99 / 80,00 (fin de vida al tick ≈ 63 400, ≈ 7,2 años) | Castiga los vaivenes de la carga (microciclos por nubes). |

### Azar entre corridas

Con las mismas variables, 10 corridas del escenario alto dieron una caída de SoH con desviación estándar de ≈ 0,02 puntos y energía comprada con ≈ 70 kWh (± 0,3 %); las limpiezas varían mucho más (entre ≈ 40 y 110). La semilla es siempre aleatoria: no se puede repetir una corrida exacta.

El SoH casi no cambia entre corridas porque en 10 años el clima diario se promedia y la batería se llena casi todos los días; el azar se nota más en las limpiezas, la energía comprada y, mientras corre, en el polvo, el cielo y la producción del panel.

## 3. Resumen rápido: "quiero…"

| Quiero… | Muevo… |
|---|---|
| Que la batería dure más | `politica` = consciente, o bajar `carga-maxima`, o subir `carga-minima` (todos aumentan la energía comprada a la red) |
| Comprar menos energía a la red | Subir `capacidad-bateria` (lo más efectivo); permitir una `carga-minima` más baja (desgasta más) |
| Ver el efecto de la zona | `zona` (por ejemplo `polvorienta` vs `lluviosa`) |
| Ver el efecto del polvo | `tasa-polvo` alta (más limpiezas) o `umbral-limpieza` alto (casi no se limpia) |
| Un sistema sin sol | `escenario-irradiancia` = baja |
| Ver sensibilidad del modelo de degradación | `escala-degradacion`, `exponente-degradacion`, `peso-corriente`, `peso-variacion-carga` |
| Ver la simulación con detalle | `velocidad` entre 1 y 4 |

## 4. Qué significa cada casilla de resultados

Las casillas de abajo están en dos filas. Unas muestran **el valor de la hora actual** y otras **lo acumulado desde el inicio**. La lista completa está en `VARIABLES_INTERFAZ.md`.

### Fila 1: reloj y entorno (valor de la hora actual)

| Casilla | Significado |
|---|---|
| Hora del dia | Hora simulada, de 0 a 23. |
| Dia del anio (1-365) | Día del año en curso. |
| Anio (0-9) | Año simulado, de 0 a 9 (el año 1 es el 0). |
| Irradiancia (W/m2) | Potencia solar que llega al panel; 0 de noche, máxima al mediodía. |
| Temp. ambiente (C) | Temperatura del aire. |
| Consumo casa (kW) | Potencia que pide la casa en esa hora. |
| Polvo panel (g) | Polvo acumulado sobre el panel; cae a 0 cuando se limpia (se ve el diente de sierra), baja con la lluvia y sube de golpe en una tormenta de polvo. |
| Clima | Clima de la hora: soleado, nublado, lluvia o tormenta de polvo. |

### Fila 2: sistema y resultados

| Casilla | Tipo | Significado |
|---|---|---|
| Potencia panel (kW) | hora actual | Lo que el panel genera ahora, ya descontados temperatura y polvo. |
| SOC bateria (%) | hora actual | Nivel de carga de la batería. Debe quedar entre `carga-minima` y el máximo de la política. |
| SoH bateria (%) | actual | **Resultado principal.** Capacidad que le queda a la batería respecto a la nueva (100 % = nueva). Nunca sube. |
| Energia comprada (kWh) | acumulado | Total que se compró a la red desde el inicio. Más alto = el sistema depende más de la red. |
| Limpiezas | acumulado | Cuántas veces el EMS ordenó limpiar los paneles. |
| Ciclos equiv. | acumulado | Ciclos completos equivalentes de carga y descarga (energía movida dividida entre 2 veces la capacidad). Más ciclos = más desgaste. |
| Estado bateria | hora actual | Qué hace la batería ahora: carga, descarga o reposo. |

### Cómo interpretar una corrida terminada

- **SoH bateria** es el indicador de degradación: cuanto más bajo, más se degradó. Con 80 % la corrida se detiene (fin de vida) y el tick al que se detuvo indica cuántos años duró la batería (8 760 ticks = 1 año).
- **Energia comprada** es lo que cuesta, en dependencia de la red, proteger la batería: normalmente mejorar el SoH sube este valor.
- **Ciclos equiv.** ayuda a explicar el SoH: menos ciclos, menos degradación.
- Cambia una variable a la vez y, para comparar limpio, promedia varias corridas.
