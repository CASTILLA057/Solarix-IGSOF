# Solarix — Cómo funciona el modelo (etapas 1 a 15)

Archivo del modelo: `DegradacionBateriasSistemasFotovoltaicos.nlogox` (NetLogo 7.0.4).
Lista de etapas y su estado: `ETAPAS.md`. Código fuente legible: `herramientas/codigo_modelo.txt`.

## 1. Qué hace el proyecto

Simula durante 10 años una casa con paneles solares, una batería de iones de litio y conexión a la red eléctrica. Cada hora simulada, el sistema decide cómo repartir la energía (solar, batería o red) y la batería va perdiendo salud (SoH) según cuánto y cómo se usa. Se puede comparar una política **convencional** (usar la batería sin restricciones) con una **consciente de la degradación** (no cargar por encima de 95 % y limitar la corriente a 0,16 C; calibrada en la etapa 14).

## 2. Escala de tiempo

- **1 tick = 1 hora real.** Se simula cada día de los 10 años: 24 ticks por día, 8 760 por año, **87 600 ticks en total**.
- Cada día tiene su propio clima (sección 5) y el polvo se acumula día a día. Ya no se usa el "día típico por mes" ni el factor de 30 días.
- Reloj: `hora` (0–23), `dia-anio` (1–365), `anio` (0–9).
- La simulación se detiene a los 87 600 ticks o cuando el SoH baja de 80 % (fin de vida).
- **Velocidad:** cada pulsación interna de `go` avanza tantas horas como indique el slider `velocidad` (de 1 hora a 1 año) y redibuja la escena una sola vez. Así se puede ver un día en detalle o pasar años en segundos. No cambia los resultados.

## 3. Los agentes y qué hace cada uno en un paso

Orden de cada hora simulada (procedimiento `paso`):

1. **Entorno** genera irradiancia, temperatura y consumo.
2. **EMS** (sistema de gestión de energía) decide si se limpian los paneles.
3. **Paneles** se limpian (si se ordenó), acumulan polvo y generan potencia.
4. **EMS** reparte la energía: panel → casa, excedente → batería, déficit → batería o red.
5. **Batería** actualiza su carga, acumula estrés y recalcula su salud.

Después de avanzar las horas del cuadro, `go` **redibuja la escena** (procedimiento `actualizar-visual`).

| Agente | Qué representa | Ubicación en el mundo |
|---|---|---|
| Paneles FV (`paneles`) | Arreglo fotovoltaico | (7, 15) |
| Batería (`baterias`) | Banco de baterías de iones de litio | (27, 8) |
| EMS (`controladores`) | Cerebro que decide limpieza y reparto de energía | (12, 4) |
| Red eléctrica (`redes`, singular `redelec`) | Compra el déficit, sin límite | (37, 15) |
| Entorno/Carga | No es agente; son variables globales (clima y consumo) | se ve en el cielo y el reloj |

Elementos solo visuales: casa (`casas`), sol/luna (`astros`), nubes (`nubes`), lluvia (`gotas`), motas de polvo sobre el panel (`motas`) y el rótulo del reloj (`rotulos`). La posición es solo visual; el modelo no tiene espacio real. La descripción de cada elemento de la escena está en `VARIABLES_INTERFAZ.md`, sección 6.

## 4. Interfaz

**Parámetros que modifican el sistema (sliders y selectores).** Los controles usan nombres descriptivos en español, los mismos que el código (`codigo_modelo.txt`). Si algún día se renombra uno, debe cambiarse igual en el código y en la interfaz; si no, NetLogo da el error `Nothing named ... has been defined`. Para ver cómo afecta cada una, ver `GUIA_VARIACION.md`.

| Lo que ves en la interfaz | Nombre en el código | Valor por defecto | Qué hace |
|---|---|---|---|
| Capacidad nominal de la batería (kWh) | `capacidad-bateria` | 10 | Tamaño de la batería nueva. |
| Potencia pico del panel (kW) | `potencia-panel` | 5 | Lo máximo que entrega el panel limpio con 1000 W/m². |
| Tasa C máxima (potencia / capacidad) | `tasa-c-maxima` | 0,5 | Límite de potencia de carga y descarga: `tasa-c-maxima × capacidad` (5 kW con los valores por defecto). |
| SOC mínimo permitido (%) | `carga-minima` | 20 | Nivel de carga por debajo del cual no se descarga. |
| SOC máximo, política convencional (%) | `carga-maxima` | 100 | Nivel de carga hasta el que se carga en la política convencional. |
| Tasa de acumulación de polvo (g/h) | `tasa-polvo` | 0,036 | Polvo que se deposita sobre el panel por hora (Mkansi et al., 2025). |
| Pérdida por polvo que dispara la limpieza (%) | `umbral-limpieza` | 10 | Cuando el polvo le quita al panel más de este porcentaje de potencia, el EMS ordena limpiar. |
| Zona climática | `zona` | mixta | mixta, muy soleada, muy nublada, lluviosa o polvorienta: cambia la lluvia, las nubes y el polvo (ver sección 5). Es el único control del clima. |
| Velocidad de la simulación | `velocidad` | 2 | 1 = 1 hora con pausa … 5 = 1 día por cuadro … 9 = 1 año por cuadro. Solo cambia la rapidez de la animación. |
| Política de gestión (EMS) | `politica` | convencional | `consciente` no carga por encima de 95 % y limita la potencia de la batería a 0,16 × capacidad. |
| Escenario de irradiancia | `escenario-irradiancia` | baja | Baja, media o alta (ver sección 5). |
| Degradación: coef. alfa (escala) | `escala-degradacion` | 0,0000078 | Qué tan rápido se degrada la batería (calibrado en la etapa 14). |
| Degradación: exponente beta (energía acumulada) | `exponente-degradacion` | 1,1 | 1 = pérdida proporcional a la energía movida; menor que 1 = se frena con el tiempo. Con 1,1 la pérdida anual es casi constante (calibrado en la etapa 14). |
| Degradación: gamma (peso corriente eficaz) | `peso-corriente` | 2 | Cuánto agrava el uso a potencias altas. |
| Degradación: delta (peso variabilidad SOC) | `peso-variacion-carga` | 1 | Cuánto agravan los cambios bruscos de carga. |

**Monitores** (solo muestran, no se modifican; su explicación detallada está en `GUIA_VARIACION.md`, sección 4): hora, día del año, año, irradiancia, temperatura, consumo, polvo en paneles, potencia del panel, SOC, SoH, energía comprada a la red, limpiezas y ciclos equivalentes, y el estado de la batería (carga, descarga o reposo).

**Sin gráficas:** todas se muestran en el dashboard, que se abre en el navegador al terminar la corrida o con el botón **Abrir dashboard** (sección 12). En su lugar, el mundo es una escena animada del sistema (ver sección 3 y `VARIABLES_INTERFAZ.md`).

## 5. El entorno y el clima (etapas 3 y 12)

**Azar en cada corrida.** Cada `setup` toma una semilla nueva (`random-seed new-seed`): con las mismas variables el resultado es siempre algo distinto. No hay controles de semilla en la interfaz.

**Escenario de irradiancia:** baja / media / alta ajusta la irradiancia máxima (50, 560, 800 W/m²) y la temperatura media (22, 24, 27 °C). Es cuánta radiación llega con cielo despejado.

**Zona climática (etapa 13):** dice **con qué frecuencia** hay nubes, lluvia y polvo en el lugar donde está el sistema. Cada zona multiplica tres cosas: la probabilidad de lluvia, la nubosidad de cada tipo de día y el polvo que llega.

| Zona | Lluvia | Nubosidad | Polvo | Idea |
|---|---|---|---|---|
| mixta | × 1 | × 1 | × 1 | Clima intermedio (por defecto). |
| muy soleada | × 0,3 | × 0,6 | × 1,5 | Poca lluvia y pocas nubes; al ser seca, llega algo más de polvo. |
| muy nublada | × 1,3 | × 1,35 | × 0,7 | Muchas nubes y algo más de lluvia; menos polvo. |
| lluviosa | × 2 | × 1,2 | × 0,4 | Mucha lluvia: el polvo casi no se acumula. |
| polvorienta | × 0,6 | × 0,9 | × 4 | Mucha tierra en el ambiente: el polvo llega 4 veces más rápido y hay más tormentas de polvo. |

Sobre la zona se aplican las anomalías del año (más o menos lluvia y polvo), multiplicándose. La probabilidad de tormenta de polvo (≈ 1,2 % por día) se escala con el factor de polvo total, con un máximo de 3 veces. El polvo total que llega a los paneles es `tasa-polvo × factor del clima del día × factor de polvo total` (zona × anomalía del año).

Los valores de las zonas son supuestos del modelo, no datos de una estación real; se eligieron para que las zonas se diferencien claramente.

**Clima de cada día.** Cada día a las 0:00 se sortea el tipo de día con una cadena de Markov (el clima de hoy depende del de ayer, así hay rachas):

| Ayer \ Hoy | soleado | nublado | lluvia |
|---|---|---|---|
| soleado | 70 % | 25 % | 5 % |
| nublado | 30 % | 45 % | 25 % |
| lluvia | 15 % | 35 % | 50 % |

A largo plazo resulta ≈ 45 % de días soleados, 34 % nublados y 21 % de lluvia (un clima mixto).

**Anomalías del año.** Cada año es distinto: se sortea un factor de lluvia (0,6 a 1,6, que escala la probabilidad de lluvia: hay años secos y años lluviosos) y un factor de polvo (típicamente entre 0,5 y 2, con más o menos polvo en el ambiente).

**Tormentas de polvo.** Cada día hay ≈ 1,2 % de probabilidad (escalada por el factor de polvo del año) de que empiece una tormenta de 1 a 3 días, unas 4 al año. Durante la tormenta no llueve, el cielo se pone pardo y llega mucho más polvo a los paneles.

**Variables de cada hora**
- **Nubosidad** (0 despejado a 1 cubierto): sigue el tipo de día (≈ 0,15 soleado, 0,6 nublado, 0,9 lluvia; mínimo 0,6 en tormenta) con inercia y ruido. Reduce la irradiancia hasta la mitad.
- **Lluvia:** en un día de lluvia llueve en ≈ 60 % de las horas.
- **Irradiancia (W/m²):** campana solar de 6:00 a 18:00 × variación estacional (±5 % a lo largo del año) × efecto de las nubes.
- **Temperatura (°C):** media del escenario + variación del día (±2 °C) + ciclo diario de ±5 °C con máximo a las 15:00 + ruido; 2 °C menos mientras llueve.
- **Consumo (kW):** 0,3 kW de base, pico a las 7:00 y pico mayor a las 20:00; sube 3 % por cada °C sobre 24 °C; con una variación diaria (±10 %) y ruido por hora. Detalle, fuentes y supuestos en la sección siguiente.

### Perfil de consumo de la casa (LOAD)

**De dónde sale.** El Word no da una ecuación del consumo; solo dice que LOAD es una entrada exógena por hora con componente estacional y aleatoria (sección 7) y cita dos rangos (Tabla 5):

| Fuente | Qué reporta |
|---|---|
| Onori et al. (2026), Figura 1 | Perfiles horarios de un día típico por estación; consumo de 0,1 a 1,1 kW |
| Sidi Lekhel et al. (2026) | Tres semanas de datos horarios; consumo de ≈ 0,2 a 5 kW |

El perfil del modelo **se construyó** con la forma típica de una vivienda (dos picos, mañana y noche) y se ajustó para quedar dentro de esos rangos. **No es una serie medida copiada de las fuentes.**

**Fórmula** (procedimiento `actualizar-entorno`):

```
base    = 0,3 + 1,2·e^(−((hora−7)/1,5)²) + 2,0·e^(−((hora−20)/2)²)      [kW]
consumo = máx(0,1 ; base × (1 + 0,03·máx(0, T_amb − 24)) × factor del día × ruido de la hora)
```

| Parte | Qué representa | Valor |
|---|---|---|
| Consumo de fondo | Nevera, equipos en espera | 0,3 kW todo el día |
| Pico de la mañana | Desayuno, ducha | +1,2 kW alrededor de las 7:00 |
| Pico de la noche | Cocina, luces, TV | +2,0 kW alrededor de las 20:00 |
| Efecto del calor | Aire acondicionado o ventiladores | +3 % por cada °C sobre 24 °C |
| Factor del día (`factor-carga-dia`) | Hay días de más y de menos consumo | Normal de media 1 y desviación 0,1 (mínimo 0,6), se sortea a las 0:00 |
| Ruido de la hora | Variación de hora a hora | Normal de media 1 y desviación 0,15 |
| Mínimo | Nunca baja de este valor | 0,1 kW |

**Resultado.** Va de ≈ 0,1 kW de madrugada a ≈ 3–4 kW en el pico de la noche de un día caluroso (dentro del rango de Sidi Lekhel), unos 20 kWh por día (≈ 7 000 kWh por año; ver la tabla anual del dashboard). El pico de consumo cae de noche, cuando no hay sol, y el mínimo al mediodía, cuando más se genera: por eso la batería es necesaria, porque guarda el sobrante del mediodía para la noche (el desacople que describe la introducción del Word). El clima influye solo a través de la temperatura: en días calurosos se consume más, y la lluvia, al bajar la temperatura 2 °C, reduce un poco el consumo.

**Supuestos propios (no vienen de una fuente).** La hora y el tamaño de los picos, el 3 % por grado y los niveles de azar (±10 % por día y ±15 % por hora). Solo se verificó que el resultado quedara dentro de los rangos del Word.

**Diferencias con el Word.**
- El Word pide un componente **estacional** del consumo y el modelo no lo tiene: el perfil es el mismo todo el año (tampoco hay estaciones en la temperatura, y la irradiancia solo varía ±5 % entre meses).
- El pico del modelo supera el máximo de 1,1 kW de Onori et al.; se acerca más a los datos de Sidi Lekhel et al.

## 6. El panel solar y el polvo

- **Temperatura de la celda** = temperatura ambiente + 0,025 × irradiancia.
- **Polvo:** cada hora suma `tasa-polvo × factor del clima × factor de polvo total`. El factor del clima es 1,3 en día soleado (seco), 1 en nublado, 0,2 con lluvia y 15 en tormenta de polvo; el factor de polvo total es zona × anomalía del año. Cada hora de lluvia lava además el 1,5 % del polvo acumulado.
- **Potencia** = `potencia-panel × (irradiancia / 1000) × (1 − 0,004 × (T celda − 25)) × factor de polvo`.
  - Factor de polvo = `1 − 0,003 × gramos de polvo` (mínimo 0,4).
- Al limpiar, el polvo vuelve a 0.
- En la escena, el panel pasa de azul a marrón y aparecen motas de polvo a medida que el polvo se acumula (el color llega al máximo con 45 g).

## 7. Reparto de energía y batería (etapas 6 y 7)

En cada hora, con `consumo` = LOAD y `potencia` = producción del panel:

1. **Solar directo a la casa:** P₂ = mínimo entre potencia y consumo.
2. **Excedente** = potencia − P₂; **déficit** = consumo − P₂.
3. **Carga de la batería:** con el excedente, hasta el SOC máximo permitido (`carga-maxima` en convencional; mínimo entre `carga-maxima` y 95 % en consciente), sin pasar de `tasa-c-maxima × capacidad` (en consciente, de `0,16 × capacidad`). Eficiencia 95 %. Lo que no cabe se pierde (no se vende).
4. **Descarga de la batería:** cubre el déficit hasta el SOC mínimo, con el mismo límite de potencia y eficiencia 95 %.
5. **Red (P₄):** compra lo que falte. Así siempre se cumple P₂ + batería + P₄ = consumo.
6. **Capacidad efectiva** = `capacidad-bateria × SoH / 100`: cuando la batería se degrada, guarda menos energía.

## 8. Decisión de limpieza del EMS (etapa 8)

Una vez al día (hora 0) el EMS mide cuánta potencia pierde el panel por el polvo: `pérdida (%) = (1 − factor de polvo) × 100`. Si supera `umbral-limpieza`, ordena limpiar: el polvo vuelve a 0, se suma una limpieza al contador y la escena muestra el aviso. El modelo **no maneja precios ni costos**: la energía se mide en kWh y el resultado que importa es la salud de la batería.

## 9. Degradación (etapa 9)

Cada hora la batería acumula tres factores de estrés (Ecs. 1–3 del Word):

| Factor | Símbolo | Qué significa |
|---|---|---|
| Energía acumulada normalizada | `x` | Energía total que ha pasado por la batería dividida entre su capacidad nominal. |
| Estrés por corriente eficaz | `c-rms` | Qué tan exigentes han sido en promedio las potencias de carga y descarga. |
| Variabilidad del SOC | `sigma-soc` | Cuánto ha oscilado la carga (microciclos por las nubes). |

Con ellos se calcula el **estado de salud** (Ecs. 4–5):

`Z = escala-degradacion × x^exponente-degradacion × (1 + peso-corriente × c-rms) × (1 + peso-variacion-carga × sigma-soc)` y `SoH = 100 × e^(−Z)`.

El SoH nunca sube y se recalcula cada tick. Con los valores por defecto se pierde ≈ 1,5 % de SoH por año en escenario alto y ≈ 1,4 % en medio, dentro del rango del Word (1,3–1,7 %) y casi constante año a año. La validación completa (R², RMSE, MAPE y comparación de políticas) está en `VALIDACION.md`.

## 10. Glosario de variables internas

| Nombre en el código | Significado |
|---|---|
| `irradiancia` | Radiación solar de la hora (W/m²). |
| `t-amb` | Temperatura ambiente (°C). |
| `carga` | Consumo de la casa (kW), la demanda LOAD. |
| `nubosidad` | Cubierta de nubes, de 0 a 1. |
| `clima-dia` | Tipo del día: soleado, nublado o lluvia. |
| `llueve-ahora` | Verdadero si esta hora está lloviendo. |
| `dias-tormenta` | Días que le quedan a la tormenta de polvo en curso (0 = no hay). |
| `factor-lluvia-anio`, `factor-polvo-anio` | Anomalías del año: cuánto más o menos llueve y cuánto polvo hay. |
| `offset-temp-dia`, `factor-carga-dia` | Variación del día en temperatura (°C) y en consumo (multiplicador). |
| `parametros-zona` | Lista [lluvia, nubosidad, polvo] de la zona elegida. |
| `f-lluvia-total`, `f-nubes`, `f-polvo-total` | Factores finales: valor de la zona (× anomalía del año en lluvia y polvo). |
| `hora`, `mes`, `anio` | Reloj del modelo (hora 0–23, mes 0–11, año 0–9). |
| `dia-anio` | Día del año en curso (1–365). |
| `aviso-limpieza` | Horas que quedan mostrando el aviso de limpieza en la escena (solo visual). |
| `p1` | Potencia generada por el panel (kW). |
| `polvo` | Polvo acumulado en el panel (g). |
| `t-cel` | Temperatura de la celda solar (°C). |
| `condicion` | Estado del panel: limpio o ensuciándose. |
| `soc` | Estado de carga de la batería (%). |
| `soh` | Estado de salud de la batería (%). |
| `t-bat` | Temperatura de la batería (°C). |
| `modo` | Estado de la batería: carga, descarga o reposo. |
| `p-ch`, `p-dis` | Potencia de carga y de descarga de la batería (kW). |
| `v` | Orden de limpieza: 1 = limpiar, 0 = no. |
| `limpiezas` | Número de limpiezas realizadas. |
| `p4` | Potencia comprada a la red en la hora (kW). |
| `energia-comprada` | Energía total comprada a la red (kWh). |
| `eta` | Eficiencia de carga y descarga (0,95). |
| `k-polvo` | Pérdida de potencia por gramo de polvo (0,003). |
| `coef-temp` | Pérdida de potencia por grado sobre 25 °C (0,004). |
| `soh-umbral` | SoH que marca el fin de vida (80 %). |
| `soc-max-consciente`, `c-max-consciente` | Límites de la política consciente: SOC máximo 95 % y tasa C máxima 0,16 (etapa 14). |
| `horizonte` | Ticks totales de la simulación (87 600). |

## 11. Cómo comprobar que funciona

- Pulsa siempre `setup` antes de `go` (si pulsas `go` primero, el modelo avisa "Primero presiona el boton setup."). Luego `go`: se ve pasar el tiempo en la escena y los monitores cambian.
- Cambia la **zona** (por ejemplo a `polvorienta` o `lluviosa`) y observa el polvo del panel y el número de limpiezas.
- Pulsa `setup` varias veces con las mismas variables: cada corrida da un resultado distinto (limpiezas, energía comprada, clima).
- Cambia el **escenario** y pulsa `setup` otra vez: con `baja` casi no hay energía solar, el SoH apenas baja y se compra casi todo a la red; con `alta` la batería cicla mucho y el SoH baja ≈ 1,5 % al año.
- Cambia la **política** a `consciente`: la caída del SoH baja ≈ 10 % y la energía comprada sube ≈ 5 %, como en el Word (Mitsunaga et al., 2026).
- Deja correr la simulación hasta el final: se abre el navegador con el dashboard. O pulsa **Abrir dashboard** a mitad de la corrida para ver lo que va.
- Para validar el modelo completo corre `python herramientas/validar_modelo.py` (≈ 15 s): regenera `VALIDACION.md`.
- Con `umbral-limpieza` en 40 % casi nunca se limpia; la lluvia lava parte del polvo, así que el efecto en la energía comprada es pequeño (≈ 3 %).
- Sube `velocidad` (8 o 9) para llegar rápido al final; con 1 a 4 se ve el detalle de cada día.

## 12. Dashboard de resultados (etapa 15)

El dashboard está en `dashboard/dashboard.html` y lee los datos de `dashboard/datos.js`, que escribe NetLogo. Se abre en el navegador (Chrome, Edge…) mediante la extensión `shell`, que va incluida en la carpeta `shell/` del proyecto: no hay que instalar nada, pero la carpeta del proyecto debe entregarse completa (el `.nlogox` junto a `shell/` y `dashboard/`).

- **Cuándo se abre:** solo al terminar la simulación (10 años o SoH < 80 %), o en cualquier momento con el botón **Abrir dashboard** (muestra lo simulado hasta ese día). En corridas de BehaviorSpace no se abre.
- **Qué guarda NetLogo:** una fila por día simulado (hasta 3 650): SoH, SOC medio, generación, consumo y energía comprada del día, polvo al final del día, si hubo limpieza, tipo de día, irradiancia y temperatura medias. Además, los parámetros de la corrida y el resumen final.
- **Qué muestra:** tarjetas con SoH final, pérdida media de SoH por año (y si está en la banda 1,3–1,7 % del Word), energía comprada, limpiezas y ciclos; y cuatro secciones de gráficas: (1) SoH con la banda de referencia del Word y SOC medio mensual; (2) generación, consumo y energía comprada por mes, y compra acumulada; (3) polvo diario (diente de sierra) con las limpiezas marcadas y limpiezas por año; (4) irradiancia y temperatura medias mensuales y tipo de día por año. Al pasar el mouse cada gráfica muestra los valores. Al final hay una tabla con el resumen por año.
- **Funciona sin internet:** las gráficas se dibujan con SVG dentro de la página, sin librerías externas. Se adapta al modo claro u oscuro del sistema.
- Si el navegador no se puede abrir, NetLogo muestra un mensaje con la ruta del archivo para abrirlo a mano.

Con la etapa 15 el proyecto queda completo (ver `ETAPAS.md`).
