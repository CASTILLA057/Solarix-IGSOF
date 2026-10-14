# Solarix — Material para la defensa

Tres piezas para la sustentación: la **hoja de fórmulas** (de dónde sale cada constante), la **diapositiva de límites** del modelo y el **guion**, cuyo hilo central es la conclusión del barrido de baterías ([`BARRIDO_BATERIA.md`](BARRIDO_BATERIA.md)).

## 1. Hoja de fórmulas

Una línea por constante o decisión. «Editable» = el usuario puede cambiarla en la app.

### 1.1 Calculadora (Proyecto Integrador I)

| Constante / decisión | Valor | Origen | Dónde |
|---|---|---|---|
| Energía diaria | Σ potencia × horas × cantidad (o factura ÷ 30) | Definición | `calculadora.dart` |
| Paneles | `⌈ E / (HSP · PR · P_panel) ⌉`, mínimo 1 | Dimensionamiento estándar | `numeroPaneles` |
| **PR** (rendimiento del sistema) | **0,78** | Pérdidas por temperatura, cableado, suciedad e inversor (típico 0,75–0,85). Editable | `Supuestos.rendimientoSistema` |
| Eficiencia del inversor | 0,90 | Valor típico de inversores residenciales. Editable | `Supuestos.eficienciaInversor` |
| Capacidad de batería | `E_cubrir · días / (DoD · η_inv)` | Dimensionamiento estándar | `capacidadBateriaWh` |
| DoD litio / plomo | 0,9 / 0,5 | Profundidad de descarga recomendada por química | `QuimicaBateria` |
| Autonomía (aislado) | 2 días | Práctica común. Editable | `Supuestos.diasAutonomia` |
| Parte nocturna (híbrido) | 0,5 del consumo | Consumo sin sol. Editable | `Supuestos.fraccionNocturna` |
| **Factor 1,25** del inversor y del controlador | × 1,25 | Margen de seguridad (NTC 2050, sección 690) | `calculadora.dart` |
| Voltaje del banco | 12 V hasta 1,5 kWh/día, 24 V hasta 4, 48 V más | Práctica común | `voltajeSistema` |
| Autoconsumo | 0,6 red / 0,9 híbrido / 1 aislado | Valores típicos. Editable | `autoconsumoPorDefecto` |
| **Cv** (comercialización) | **$ 100/kWh** | CREG 174/2021; EMCALI $ 67,9 y EPM $ 121,05 en 2026. Editable | `costoComercializacion` |
| **Precio de bolsa** | **$ 300/kWh** | XM 2026: de $ 120 (feb.) a $ 946,6 (ago.). Editable | `precioBolsa` |
| Excedente por tramos | permuta hasta lo importado; lo demás, bolsa | CREG 174/2021, arts. 23 y 25 | `valorEnergiaMes` |
| **Subsistencia 173 / 130 kWh** | 173 bajo 1.000 m; 130 desde 1.000 m | Resolución UPME 355 de 2004 | `ConsumoSubsistencia` |
| **Subsidios 60 / 50 / 15 %** | estratos 1 / 2 / 3 | Ley 1117 de 2006 y Ley 142 de 1994 (art. 99.6): se usa el máximo | `Estrato` |
| **Contribución 20 %** | estratos 5 y 6 | Ley 142 de 1994, art. 89 | `Estrato` |
| IVA excluido | 19 % de la inversión (opcional) | Ley 1715 de 2014 | `Supuestos.exclusionIva` |
| **Deducción de renta, año 1** | 50 % de la inversión × tarifa de renta (opcional) | Ley 1715; se toma en el año 1 (la ley permite repartirla en 15 años) | `fraccionDeduccionRenta` |
| Incremento de tarifa | 6 %/año | Supuesto. Editable | `incrementoTarifa` |
| Degradación de paneles | 0,5 %/año | Ficha típica de fabricantes. Editable | `degradacionPaneles` |
| Mantenimiento | 1 % de la inversión por año | Supuesto. Editable | `mantenimientoAnual` |
| Tasa de descuento / horizonte | 10 % / 20 años | Supuesto. Editable | `tasaDescuento`, `anios` |
| **Estructura** | **$ 300.000 por panel** | Calibración contra $ 2–5,5 M/kWp instalado | `Precios.estructuraPorPanel` |
| Precios de equipos | ver [`FUENTES.md`](FUENTES.md) | Tiendas colombianas, 2026-10-01 | `Precios.referencia` |

### 1.2 Simulador de degradación (Modelado y Simulación de Sistemas)

Las ecuaciones de NetLogo no se tocaron: solo cambian las entradas.

| Constante / decisión | Valor | Origen | Dónde |
|---|---|---|---|
| Horizonte | 10 años = 87.600 horas | NetLogo | `ParametrosSimulacion.anios` |
| Fin de vida | SoH < 80 % | Convención de la industria | `Constantes.sohUmbral` |
| Eficiencia de carga/descarga η | 0,95 | NetLogo | `Constantes.eficiencia` |
| Pérdida por polvo / por temperatura | 0,003 por g / 0,004 por °C sobre 25 | NetLogo | `kPolvo`, `coefTemp` |
| Escala α y exponente β de la degradación | 0,0000078 y 1,1 | Calibrados en NetLogo | `escalaDegradacion`, `exponenteDegradacion` |
| Pesos de corriente γ y de variación de carga δ | 2 y 1 | Calibrados en NetLogo | `pesoCorriente`, `pesoVariacionCarga` |
| **Política consciente: carga máxima 95 %** | no carga por encima de 95 % | NetLogo | `socMaxConsciente` |
| **Política consciente: tasa C 0,16** | limita la corriente a 0,16 C | NetLogo | `cMaxConsciente` |
| Política convencional | hasta 100 % y 0,5 C | NetLogo | `ParametrosSimulacion` |
| Zonas climáticas | 5 (factores de lluvia, nubes y polvo) | NetLogo | `ZonaClimatica` |

### 1.3 Capa que conecta los dos módulos (Etapa 12)

| Constante / decisión | Valor | Origen | Dónde |
|---|---|---|---|
| Escenario base del lugar | `alta` (forma del día, lluvia, nubes) | Decisión | `escenarioBase` |
| **Irradiancia ajustada por ciudad** | `800 · HSP / HSP_modelo(zona)`, **tope 1.100 W/m²** | Una proporción: la irradiancia del modelo es proporcional a la máxima | `irradianciaMaximaPara`, `irradianciaMaximaTope` |
| Temperatura del lugar | NASA `T2M` + 0,0065 · (altitud celda − altitud ciudad) | [`FUENTES.md`](FUENTES.md) | `climaDeCiudad` |
| Zona según el clima | lluvia y nubosidad (criterio de 5 reglas) | [`FUENTES.md`](FUENTES.md) | `zonaParaClima` |
| Consumo del modelo → consumo calculado | factor = consumo de la casa ÷ consumo del modelo | Escala el perfil de NetLogo | `factorConsumoPara` |
| Corrida de referencia | 10 años, semilla 1 | Medir el modelo sin azar | `_referencia` |
| **Vida calendario 15 / 6 años** | litio 15, plomo 6 | Vida de calendario típica; el modelo no la incluye | `QuimicaBateria` |
| **Vida usada en el flujo** | la menor entre la vida por uso y la calendario | Evita vidas irreales (p. ej. 44 años) | `vidaBateria` |
| **Exponente acotado entre 0,3 y 2** | al extrapolar el SoH hasta 80 % | Rango físico razonable para `Z = a·tᵇ` | `aniosHastaFinDeVida` |
| Aporte de la batería por año | energía de la batería ÷ energía de una batería sin degradación, mismo clima | Aísla la degradación del clima | `aporteAnual` |
| Más allá de lo simulado | tendencia lineal que no sube | La degradación no devuelve energía | `aportePorEdad` |

## 2. Diapositiva de límites del modelo

**Qué decir (una diapositiva):**

1. **Degradación más lenta que la literatura.** Con una batería bien dimensionada el modelo pierde ≈ 0,3 a 1,0 puntos de SoH por año; la literatura reporta 1,3–1,7. Por eso la simulación sola a veces da vidas de 40 años.
2. **Sin envejecimiento calendario.** El modelo solo desgasta por uso; por eso se pone el tope de 15 años (litio) y 6 (plomo).
3. **Validado contra NetLogo, no contra baterías reales.** El motor en Dart reproduce a NetLogo (SoH a ± 0,02 puntos, energía comprada a < 0,3 %), pero no hay medidas de una batería real.
4. **Coeficientes sin calibrar con datos medidos.** α, β, γ y δ vienen del modelo original.
5. **Configuraciones por ciudad interpoladas.** El clima de cada ciudad cambia las entradas, y no se validó cada una contra NetLogo. NASA tiene resolución de ≈ 50 km (Pasto queda como mixta).
6. **Con red, la batería no se paga.** Con la CREG 174 cada kWh que guarda la batería vale apenas el Cv frente a mandarlo a la red; el híbrido se compra por los cortes, no por el ahorro.
7. **Tarifas y precios con fecha.** Precios de tiendas del 2026-10-01; los subsidios son los máximos de ley, el real depende del operador.

**Frase de cierre:** *«Solarix no predice la vida real de una batería; muestra cómo cambia el desgaste del modelo con el tamaño, el clima y la política, y qué parte de la decisión depende de eso.»*

## 3. Guion de la sustentación (≈ 10 minutos)

**Hilo central:** *«¿Para qué simular la batería?»* La respuesta, medida en [`BARRIDO_BATERIA.md`](BARRIDO_BATERIA.md): la simulación y la política consciente **solo cambian la decisión cuando la batería es pequeña**; con una batería bien dimensionada la vida la fija el calendario y el dinero no cambia.

**De dónde viene cada parte**

| Parte | Materia | Qué aporta |
|---|---|---|
| Calculadora: consumo, dimensionamiento, costos, VPN | Proyecto Integrador I | Cuánto sistema necesito y cuánto cuesta |
| Simulador SimDeg-FV (NetLogo → Dart) | Modelado y Simulación de Sistemas | Cuánto se desgasta la batería en 10 años |
| Capa que las conecta | Las dos | El cálculo alimenta la simulación; la simulación corrige la vida y el ahorro del cálculo |
| App, nube y seguridad | Ambas | Flutter, Supabase, RLS, Ley 1581 |

**Secuencia**

1. **(1 min) El problema.** Una casa colombiana quiere energía solar: ¿cuántos paneles, cuánta batería, cuánto cuesta y cuánto dura la batería?
2. **(2 min) Demo — calculadora.** Sin cuenta: Cúcuta, 300 kWh/mes, híbrido, estrato 4. Mostrar paneles, inversión, recuperación, la comparación contra el mismo sistema sin batería, y la nota de la Ley 1715.
3. **(2 min) Demo — simulación.** Pulsar «Simular» desde el cálculo: SoH a 10 años de las dos políticas, años hasta el 80 % y VPN corregido. Notar el aviso cuando manda el tope calendario.
4. **(1 min) Cómo se conectan.** Clima de la ciudad → zona del modelo → irradiancia ajustada; el consumo de la casa escala el perfil; la vida usada es la menor entre uso y calendario (hoja de fórmulas, sección 1.3).
5. **(2 min) La pregunta central.** Tabla del barrido: batería de ~6 kWh (+1,5 puntos de SoH y +$ 0,25 M de VPN con la política consciente) frente a 12 kWh o más (diferencia de 0,0–0,1 puntos y $ 0). Qué significa: para **elegir el tamaño**, la simulación es útil; para **elegir la política**, solo importa con batería pequeña.
6. **(1 min) Validación.** El motor en Dart reproduce a NetLogo: SoH a ± 0,02 puntos (criterio ± 0,3), energía comprada a < 0,3 % (criterio 3 %); `VALIDACION_DART.md`.
7. **(1 min) Límites.** Diapositiva de la sección 2, sin esconder nada.
8. **Preguntas probables**
   - *¿Por qué el VPN con red no premia a la batería?* Por la CREG 174: el excedente se permuta al precio de la tarifa menos el Cv, así que guardar un kWh en la batería solo ahorra ese Cv.
   - *¿Por qué 15 años de tope?* Vida calendario típica del litio; el modelo no envejece por tiempo.
   - *¿Se puede confiar en la vida de 44 años?* No: por eso se limita al calendario y se declara en la diapositiva de límites.
   - *¿Dónde están los datos?* [`FUENTES.md`](FUENTES.md), con fechas de consulta.
   - *¿Qué pasa con mis datos?* Política de la Ley 1581 en la app; «Probar sin cuenta» no recoge datos personales.

**Antes de presentar**
- Reactivar el proyecto de Supabase y ensayar la demo completa 24 horas antes, con un registro de correo nuevo.
- Probar el APK `entregas/Solarix-1.1.0.apk` en un celular distinto al de desarrollo.
- No cambiar código en los dos días previos, salvo que algo esté roto.
