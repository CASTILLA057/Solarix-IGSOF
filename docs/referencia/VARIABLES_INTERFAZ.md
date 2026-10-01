# Solarix — Variables de la interfaz (estado: etapa 15)

Lista completa de lo que hay en la pestaña Interface de NetLogo y qué significa cada elemento. Corresponde al modelo completo, hasta la etapa 15 (tiempo en días reales: 1 tick = 1 hora, 87 600 ticks = 10 años; clima aleatorio, zonas climáticas, calibración validada y dashboard de resultados).

Documentos relacionados: `EXPLICACION_MODELO.md` (cómo funciona), `GUIA_VARIACION.md` (cómo afecta cada variable, con resultados medidos), `ETAPAS.md` (estado del proyecto).

**Azar:** cada `setup` usa un azar nuevo, así que dos corridas con las mismas variables dan resultados algo distintos (el clima cambia). No hay controles de semilla.

## 1. Botones

| Elemento | Qué hace |
|---|---|
| `setup` | Reinicia el modelo: crea los cuatro agentes con sus valores iniciales y pone el reloj en cero. Se pulsa siempre antes de `go` y cada vez que se cambia un parámetro. |
| `go` | Ejecuta la simulación de forma continua, una hora por paso. Cada pulsación interna avanza tantas horas como indique `velocidad` y redibuja la escena. Se detiene sola a los 87 600 ticks (10 años) o cuando el SoH baja de 80 %, y muestra "FIN: SoH …"; al terminar abre el dashboard en el navegador. Pulsarlo de nuevo la detiene. |
| Abrir dashboard | Guarda los resultados simulados hasta ese momento en `dashboard/datos.js` y abre `dashboard/dashboard.html` en el navegador (extensión `shell`). Se puede pulsar en cualquier momento después de simular al menos un día. Detalle en `EXPLICACION_MODELO.md`, sección 12. |

## 2. Parámetros del sistema (sliders)

| Variable | Rango | Valor por defecto | Unidad | Significado |
|---|---|---|---|---|
| `capacidad-bateria` | 1 – 30 | 10 | kWh | Capacidad nominal de la batería nueva: cuánta energía puede guardar. Con el desgaste, la capacidad efectiva baja en proporción al SoH. |
| `potencia-panel` | 1 – 15 | 5 | kW | Potencia pico del arreglo de paneles: lo máximo que entrega limpio, sin calor y con 1 000 W/m² de irradiancia. |
| `tasa-c-maxima` | 0,1 – 1 | 0,5 | 1/h | Límite de potencia de carga y descarga de la batería, expresado como fracción de su capacidad. La potencia máxima es `tasa-c-maxima × capacidad` (5 kW con los valores por defecto). |
| `carga-minima` | 0 – 50 | 20 | % | Nivel de carga (SOC) por debajo del cual la batería no se descarga; protege la batería de descargas profundas. |
| `carga-maxima` | 50 – 100 | 100 | % | Nivel de carga hasta el que se carga la batería con la política **convencional**. Con la política consciente el tope es 95 % (o este valor si fuera menor). |
| `tasa-polvo` | 0 – 0,2 | 0,036 | g/h | Polvo que se deposita sobre los paneles por hora (valor derivado de Mkansi et al., 2025). Aumenta con clima seco y se reduce con lluvia. |
| `umbral-limpieza` | 1 – 40 | 10 | % | Pérdida de potencia del panel por polvo a partir de la cual el EMS ordena limpiar (se evalúa una vez al día). Más bajo = se limpia más seguido. |

### Velocidad (slider)

| Variable | Rango | Valor por defecto | Significado |
|---|---|---|---|
| `velocidad` | 1 – 9 | 2 | Cuánto tiempo simulado avanza cada cuadro de la animación. 1 = 1 hora con pausa (lento); 2 = 1 hora; 3 = 3 horas; 4 = 6 horas; 5 = 1 día; 6 = 3 días; 7 = 1 semana; 8 = 30 días; 9 = 1 año. Se puede mover durante la corrida. Solo cambia la rapidez de la animación, no los resultados. |

## 3. Selectores (choosers)

| Variable | Opciones | Por defecto | Significado |
|---|---|---|---|
| `politica` | convencional, consciente | convencional | Política de gestión del EMS. **Convencional:** usa la batería libremente hasta `carga-maxima`. **Consciente:** no carga por encima de 95 % y limita la potencia de la batería a 0,16 × capacidad (1,6 kW con 10 kWh); la caída del SoH baja ≈ 10 % a cambio de comprar ≈ 5 % más energía a la red. Calibrada en la etapa 14 (`VALIDACION.md`). |
| `zona` | mixta, muy soleada, muy nublada, lluviosa, polvorienta | mixta | Lugar donde está instalado el sistema: cambia la frecuencia de lluvia, nubes y polvo (tabla en `EXPLICACION_MODELO.md`, sección 5). Es el único control del clima: no hay sliders de ajuste. |
| `escenario-irradiancia` | baja, media, alta | baja | Nivel de sol y temperatura del entorno (cuánta radiación llega con el cielo despejado y qué tan cálido es). **Baja:** irradiancia máxima de 50 W/m² y 22 °C de media. **Media:** 560 W/m² y 24 °C. **Alta:** 800 W/m² y 27 °C. |

## 4. Parámetros de degradación (sliders)

Definen la fórmula de pérdida de salud de la batería (Ecs. 4 y 5 del Word):
`Z = escala-degradacion × x^exponente-degradacion × (1 + peso-corriente × c-rms) × (1 + peso-variacion-carga × sigma-soc)` y `SoH = 100 × e^(−Z)`.
No describen la casa sino **qué tan rápido se gasta la batería**; están calibrados (etapa 14) para ≈ 1,5 % de pérdida de SoH por año en escenario alto, casi constante año a año.

| Variable | Rango | Valor por defecto | Símbolo del Word | Significado |
|---|---|---|---|---|
| `escala-degradacion` | 0 – 0,0001 | 0,0000078 | α | Escala general de la degradación. Duplicarla casi duplica la pérdida de SoH. Es la perilla principal de calibración. |
| `exponente-degradacion` | 0,3 – 1,5 | 1,1 | β | Cómo crece la degradación con la energía acumulada. 1 = proporcional; menor que 1 = se frena con el tiempo; mayor que 1 = se acelera. Muy sensible: si se cambia, hay que recalibrar `escala-degradacion`. |
| `peso-corriente` | 0 – 10 | 2 | γ | Cuánto agrava la degradación el uso a potencias altas (estrés por corriente eficaz). |
| `peso-variacion-carga` | 0 – 10 | 1 | δ | Cuánto agravan la degradación los vaivenes de la carga (microciclos provocados por las nubes). |

## 5. Monitores (resultados)

Solo muestran valores; no se modifican. Están en dos filas bajo el mundo.

### Fila 1: reloj y entorno (valor de la hora actual)

| Monitor | Variable interna | Unidad | Significado |
|---|---|---|---|
| Hora del dia | `hora` | 0–23 | Hora simulada del día. |
| Dia del anio (1-365) | `dia-anio` | 1–365 | Día del año en curso. |
| Anio (0-9) | `anio` | 0–9 | Año simulado (el primer año es 0). |
| Irradiancia (W/m2) | `irradiancia` | W/m² | Potencia solar que llega al panel; 0 de noche, máxima al mediodía, reducida por las nubes. |
| Temp. ambiente (C) | `t-amb` | °C | Temperatura del aire. |
| Consumo casa (kW) | `carga` | kW | Potencia que pide la casa en esa hora. |
| Polvo panel (g) | `polvo-actual` | g | Polvo acumulado sobre el panel; vuelve a 0 al limpiar, baja con la lluvia y sube de golpe en una tormenta de polvo. |
| Clima | `clima-texto` | texto | Clima de la hora: soleado, nublado, lluvia o tormenta de polvo. |

### Monitor de velocidad (columna de controles)

| Monitor | Variable interna | Significado |
|---|---|---|
| Velocidad actual | `descripcion-velocidad` | Texto que dice cuánto tiempo avanza cada cuadro con el valor actual de `velocidad`. |

### Fila 2: sistema y resultados

| Monitor | Variable interna | Unidad | Tipo | Significado |
|---|---|---|---|---|
| Potencia panel (kW) | `p-panel` | kW | hora actual | Potencia que genera el panel ahora, ya descontados temperatura y polvo. |
| SOC bateria (%) | `soc-actual` | % | hora actual | Estado de carga: qué tan llena está la batería. |
| SoH bateria (%) | `soh-actual` | % | actual | **Resultado principal.** Estado de salud: capacidad restante frente a la batería nueva (100 % = nueva). Nunca sube; la corrida se detiene al llegar a 80 %. |
| Energia comprada (kWh) | `comprada-total` | kWh | acumulado | Total de energía comprada a la red desde el inicio. |
| Limpiezas | `limpiezas-total` | número | acumulado | Cuántas veces el EMS ordenó limpiar los paneles. |
| Ciclos equiv. | `ciclos-eq` | ciclos | acumulado | Ciclos completos equivalentes de carga y descarga de la batería; más ciclos, más desgaste. |
| Estado bateria | `estado-bateria` | texto | hora actual | Qué hace la batería ahora: carga, descarga o reposo. |

## 6. Vista del mundo (escena animada)

El mundo (0–40 en x e y, origen abajo a la izquierda) muestra una escena que cambia con la simulación:

| Elemento | Qué muestra |
|---|---|
| Cielo | Azul de día despejado, gris si está nublado o llueve, pardo en una tormenta de polvo, oscuro de noche. |
| Sol y luna | El sol cruza el cielo de 6:00 a 18:00 (se oculta si llueve); de noche aparece la luna. |
| Nubes | Más nubes cuanto mayor es la nubosidad; se ponen grises al llover o de noche. |
| Lluvia | Gotas que caen en las horas de lluvia de un día lluvioso. |
| Paneles (izquierda) | Azules cuando están limpios y marrones con motas de polvo cuando se ensucian. La etiqueta indica la potencia y los gramos de polvo. |
| Limpieza | Al limpiar, el polvo desaparece y el EMS muestra "limpiando paneles" durante 12 horas. |
| Casa (centro) | Muestra el consumo en kW. |
| Batería (derecha abajo) | Verde al cargar, naranja al descargar, gris en reposo; una barra verde al lado indica su nivel de carga. |
| Red externa (derecha) | Se pone roja y muestra los kW cuando la casa compra energía; gris si no se usa. |
| Líneas de energía | Amarilla panel→casa, verde/naranja batería↔casa y roja red→casa; solo se ven cuando hay flujo. |
| Reloj (arriba) | Año, día, hora, clima (soleado, nublado, lluvia, tormenta de polvo) y zona. |
