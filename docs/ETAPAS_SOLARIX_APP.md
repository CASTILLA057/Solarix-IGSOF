# Solarix — App Flutter: etapas del proyecto

> Une en una sola app los dos proyectos: la calculadora de consumo, dimensionamiento y costos de paneles solares (Proyecto Integrador I) y el modelo de degradación de baterías de iones de litio en sistemas fotovoltaicos (Modelado y Simulación de Sistemas, SimDeg-FV). Alcance generalizado: ya no es solo para zonas rurales, sino para cualquier instalación solar residencial.

**Cómo usar este archivo:** marca cada tarea con `[x]` cuando la termines. Las etapas están pensadas para completarse en orden, aunque la 3 y la 4 se pueden avanzar en paralelo si trabajas en pareja o con tiempo dividido.

**Flujo de trabajo con git:** al terminar cada etapa se revisa, se verifica que `flutter analyze` y `flutter test` pasen, y se sube con un commit y push (`Etapa N: <resumen>`). GitHub Actions vuelve a correr el análisis y las pruebas en cada push.

**Regla de pruebas:** toda fórmula (consumo, costos, payback, degradación) se prueba en la misma etapa en que se escribe, no al final.

**Bitácora:** todo lo que se hace, corrige o elimina queda registrado en [`BITACORA.md`](BITACORA.md).

## Decisiones técnicas de partida

| Decisión | Elección | Por qué |
|---|---|---|
| Framework | Flutter + Dart | Ya definido por ti |
| Plataformas | **Android + Web** | Android para uso real; Web para mostrarla fácilmente en la sustentación |
| País / moneda | Colombia / COP (editable) | Tarifas, HSP por ciudad y normativa de autogeneración (CREG 174 de 2021) |
| Backend / base de datos | **Supabase** (Postgres + Auth + Storage) | Plan gratis real: 2 proyectos, 500 MB de base de datos, 1 GB de archivos, 50 000 usuarios activos de Auth al mes, 5 GB de salida de datos, sin límite de peticiones a la API. Es Postgres (SQL), cercano a lo que ya manejas con MySQL/MariaDB en XAMPP, tiene el paquete oficial `supabase_flutter` maduro, y ya lo usaste en TuCasaConstrucciones. Único detalle: el proyecto gratis se pausa tras una semana sin uso (se reactiva con un clic, sin perder datos). |
| Gestión de estado | Riverpod | Separa bien la lógica de cálculo/simulación de la interfaz y es fácil de probar. |
| Navegación | go_router | Estándar actual de Flutter; fácil de proteger rutas según si hay sesión activa |
| Gráficas | fl_chart | Para SoH, consumo/generación y costos acumulados |
| Credenciales | `--dart-define-from-file=env.json` | `env.json` está en `.gitignore`; en el repo solo va `env.example.json` |
| Esquema de BD | Migraciones SQL en `supabase/migrations/` | El esquema queda versionado en git junto con el código |
| Recurso solar (HSP) | Tabla de ciudades + API NASA POWER | La tabla funciona sin internet; "usar mi ubicación" consulta NASA POWER (gratis, por latitud/longitud) |
| Química de batería | Litio (LiFePO₄) y plomo-ácido | La calculadora ofrece ambas; la simulación de degradación solo aplica a litio (el modelo es de iones de litio) |
| Precios de equipos | Tabla `precios_referencia` en Supabase + editables | Valores de referencia actualizables sin publicar otra versión; el usuario puede ajustarlos en cada cálculo |
| Referencia de validación | `docs/referencia/GUIA_VARIACION.md` | Promedios de 5 corridas de NetLogo por configuración: son los valores esperados para el motor en Dart |

## Etapa 0 — Preparación
- [x] Definir el alcance en una frase: "Solarix: calculadora de dimensionamiento/costos de paneles solares + simulador de degradación de batería, con cuenta de usuario e historial en la nube."
- [x] Decidir si el módulo de consumo/costos se reescribe desde cero o se reutiliza algo del Proyecto Integrador I → **desde cero** (la versión anterior estaba hecha en HTML, no en Flutter; sirve como referencia de qué cálculos mostrar, no como código a portar)
- [x] Confirmar plataformas objetivo → **Android + Web**
- [x] Crear el repositorio privado `Solarix` en GitHub
- [x] Crear el proyecto en Supabase (gratis) y guardar la URL y la publishable key (`sb_publishable_...`) en `env.json` → organización propia **Solarix**, proyecto `solarix` (ref `byopepmwxjdwdyhyrwch`, región us-east-1); la contraseña de la BD está en `supabase/.db-password` (solo local, fuera de git)
- [x] Copiar a `docs/referencia/` el material de origen: modelo NetLogo (`DegradacionBateriasSistemasFotovoltaicos.nlogox`, NetLogo 7.0.4), informe (`Degradacion_Baterias_Fotovoltaicos_corregido.docx`), calculadora HTML del Proyecto Integrador I (`index.html`) y guía de resultados (`GUIA_VARIACION.md`)
- [x] Revisar el material de origen y definir mejoras (ver `BITACORA.md`)

## Etapa 1 — Configuración del proyecto Flutter y del backend
- [x] `flutter create` y estructura de carpetas por funcionalidad (`lib/core`, `lib/features/auth`, `lib/features/calculadora`, `lib/features/degradacion`, `lib/features/dashboard`)
- [x] `.gitignore` de Flutter (incluyendo `env.json`) y README inicial
- [x] Agregar dependencias: `supabase_flutter`, `flutter_riverpod`, `go_router`, `fl_chart`, `intl`
- [x] Credenciales de Supabase con `--dart-define-from-file=env.json` y plantilla `env.example.json`
- [x] Tema base (paleta solar, modo claro/oscuro) definido desde ya para no rehacer pantallas después
- [x] Migración SQL inicial con las tablas `perfiles`, `calculos_consumo`, `simulaciones_degradacion`
- [x] Row Level Security (RLS) activado desde el inicio: cada usuario solo ve sus propias filas
- [x] Ejecutar la migración en el proyecto de Supabase (SQL Editor o Supabase CLI)
- [x] GitHub Actions: `flutter analyze` + `flutter test` en cada push
- [x] La app arranca en Android y Web mostrando una pantalla inicial

## Etapa 2 — Autenticación de usuarios
- [x] Pantallas: registro, inicio de sesión, recuperar contraseña
- [x] Integrar Supabase Auth (correo/contraseña; Google opcional más adelante)
- [x] Confirmación de correo y recuperación de contraseña con **código de 6 dígitos** (OTP) en la app, sin enlaces
- [x] Persistir la sesión para que no pida login cada vez que se abre la app
- [x] Rutas protegidas con go_router (sin sesión → login)
- [x] Pantalla de perfil (nombre, ciudad/zona por defecto)
- [x] Cerrar sesión
- [x] Pruebas: validadores, mensajes de error, reglas de navegación y flujos completos con repositorio falso
- [x] Correo propio (SMTP de Brevo, remitente `solarixapp@gmail.com`) configurado en Supabase
- [x] Plantillas de correo de Supabase ("Confirm signup" y "Reset password") con el código `{{ .Token }}` (versionadas en `supabase/config.toml` y `supabase/templates/`)
- [x] Prueba manual con Supabase real en Chrome y Android (registro → código → inicio → perfil → cerrar sesión → recuperar)

**Mejoras de experiencia pedidas tras la prueba manual**
- [x] **Pantalla de bienvenida** (web y Android): al abrir la app sin sesión, mostrar una presentación de Solarix (logo, nombre y una frase corta) con dos botones: **Iniciar sesión** y **Crear cuenta**. Con sesión guardada se sigue entrando directo al inicio.
- [x] **Transiciones suaves entre pantallas** en toda la app (web y Android): al pasar a "Crear cuenta", "¿Olvidaste tu contraseña?" o cualquier otra vista, un fundido con un desplazamiento leve (≈ 250–300 ms), en lugar del cambio de golpe. Sobrio, sin efectos llamativos.
- [x] **Recuperar contraseña en tres pasos**, mostrando solo los campos de cada paso:
  1. Escribir el correo → enviar el código.
  2. Escribir el código → **verificarlo**. Si es incorrecto o venció, mostrar el error y permitir pedir otro.
  3. Solo con el código correcto, mostrar **Contraseña nueva** y **Repite la contraseña nueva** → guardar.
  - Al verificar el código Supabase abre una sesión temporal: si el usuario sale en el paso 3 sin cambiar la contraseña, cerrar esa sesión.
  - Transición suave al pasar de un paso a otro.
- [x] Pruebas de la bienvenida, de la navegación con transiciones y del nuevo flujo de recuperación (código incorrecto, código correcto, salir sin cambiar la contraseña)
- [x] Prueba manual de las mejoras en Chrome y Android

## Etapa 3 — Módulo de calculadora solar (consumo, dimensionamiento y costos)
*Evolución del proyecto de Proyecto Integrador I, ahora para cualquier zona, no solo rural. Corrige los supuestos fijos del HTML original (ver `BITACORA.md`, revisión del HTML).*

**Entradas**
- [x] Tipo de sistema: **conectado a red (on-grid), aislado (off-grid) o híbrido**; cambia el dimensionamiento de batería y el cálculo de ahorro
- [x] Consumo por electrodomésticos: lista base editable + **equipos personalizados** (nombre, potencia W, horas/día, cantidad); los equipos cíclicos (nevera) se ingresan en kWh/día
- [x] Consumo alternativo desde la factura: kWh/mes y tarifa COP/kWh
- [x] Recurso solar (HSP): tabla de ciudades principales de Colombia (sin internet) + opción "usar mi ubicación" con la API NASA POWER + HSP a mano
- [x] Equipos: potencia del panel editable (por defecto 550 W), química de batería (LiFePO₄ / plomo-ácido), días de autonomía (off-grid)

**Cálculos** (cada fórmula con prueba unitaria)
- [x] Energía: `E_día = Σ P·h·cantidad` (+ kWh/día de equipos cíclicos); E_mes = E_día · 30
- [x] Paneles: `n = ceil(E_día / (HSP · PR) / W_panel)`, con PR (rendimiento del sistema) ≈ 0,78 editable
- [x] Batería: `C = E_cubrir · días_autonomía / (DoD · η_inv)`; DoD según química (plomo 50 %, LiFePO₄ 90 %); E_cubrir = consumo diario (off-grid) o consumo nocturno (híbrido); voltaje del banco según tamaño (12 / 24 / 48 V)
- [x] Inversor: mayor entre potencia simultánea · 1,25 y el pico de arranque (factor de arranque por equipo: motores 3–5×)
- [x] Controlador de carga: `I = P_paneles / V_sistema · 1,25`
- [x] Costos: equipos + estructura/cableado + **instalación**, desde `precios_referencia` y editables por el usuario
- [x] Ahorro: off-grid frente al gasto actual (combustible, etc.); on-grid/híbrido = autoconsumo · tarifa + excedentes · precio de excedentes (editable, CREG 174 de 2021)
- [x] Flujo de caja a N años: incremento anual de tarifa, pérdida de rendimiento de paneles (≈ 0,5 %/año), mantenimiento, **reemplazo de batería** (vida típica por química hasta tener la simulación de la Etapa 6), VPN con tasa de descuento, payback simple y descontado
- [ ] Opcional: incentivos de la Ley 1715 de 2014 (exclusión de IVA, deducción de renta)
- [x] Pruebas unitarias de todas las fórmulas de esta etapa

**Datos y pantallas**
- [x] Migración SQL `20261001000100_calculadora.sql`: tablas `precios_referencia` y `ciudades` (lectura con sesión; se editan desde el panel de Supabase) con valores de referencia 2026
- [x] Aplicar la migración en Supabase
- [x] Guardar cada cálculo en Supabase (tabla `calculos_consumo`)
- [x] Pantalla de resultados con el resumen (energía, paneles/batería/inversor recomendados, costos, ahorro, payback, VPN)
- [x] Acceso desde el inicio ("Calcular mi sistema solar")
- [x] Permiso de internet en el manifiesto principal de Android (faltaba para el APK de producción) y de ubicación aproximada
- [x] Revisar los precios y las HSP de referencia con datos reales (precios de tiendas colombianas, HSP de NASA POWER; detalle en `BITACORA.md`)
- [x] Prueba manual en Chrome y Android (incluido guardar un cálculo y "usar mi ubicación")
- [x] Corregir etiquetas cortadas en "Equipos y costos" (margen superior en los bloques que recortan)

## Etapa 4 — Motor SimDeg-FV en Dart puro (sin interfaz)
*Trae la lógica del modelo de NetLogo como una librería Dart independiente de Flutter, fácil de probar. La fuente es el código de `DegradacionBateriasSistemasFotovoltaicos.nlogox` (no el Word), porque es la versión calibrada.*

**Diferencias Word ↔ modelo NetLogo** (se sigue el modelo; se explican en la sustentación):

| Aspecto | Word (diseño ODD) | Modelo NetLogo (implementado) |
|---|---|---|
| Horizonte | 2 880 ticks (día típico mensual) | 87 600 ticks (días reales, 10 años) |
| Política consciente | SOC entre 20 % y 50 % | SOC máximo 95 % y tasa C máxima 0,16 (calibrada etapa 14) |
| Limpieza | Por costo (Ec. 8, costo p_c) | Por umbral de pérdida de potencia, evaluada a medianoche |
| Precio de la energía p_e | Entrada del modelo | No se usa |
| Envejecimiento calendario | Mencionado (temperatura) | `t-bat` se calcula pero no entra en la degradación |
| Excedente solar | — | Lo que no cabe en la batería se pierde (no se vende); en la Etapa 6 la venta de excedentes on-grid se calcula aparte |

- [x] Modelo de datos para los parámetros de entrada: capacidad de batería, potencia del panel, tasa C máxima, SOC mínimo/máximo, política (convencional/consciente), zona climática, escenario de irradiancia, tasa de polvo, umbral de limpieza y los cuatro coeficientes de degradación (`escala`, `exponente`, `peso-corriente`, `peso-variacion-carga`), con los valores por defecto del modelo
- [x] Generador de números aleatorios con semilla, para que una corrida de Dart sea reproducible (NetLogo usa semilla aleatoria, así que la comparación con NetLogo es estadística)
- [x] Generador de entorno hora a hora: irradiancia (campana solar + variación estacional), temperatura, consumo de la casa (picos de mañana y noche), clima diario con cadena de Markov, anomalías anuales de lluvia y polvo, tormentas de polvo y las cinco zonas climáticas (mixta, muy soleada, muy nublada, lluviosa, polvorienta)
- [x] Motor de reparto de energía por hora: panel → casa, excedente → batería, déficit → batería o red, respetando los límites de SOC y de potencia de carga/descarga (eficiencia η = 0,95)
- [x] Polvo y limpieza: acumulación de polvo por hora según el clima, lavado con lluvia, orden de limpieza del EMS al superar el umbral
- [x] Fórmulas de degradación: energía acumulada normalizada (x), estrés por corriente eficaz (c-rms), variabilidad del SOC (sigma-soc), `Z` y `SoH = 100·e^(−Z)` (el SoH nunca sube)
- [x] Factor de escala del perfil de consumo (por defecto 1 = igual a NetLogo, ≈ 20 kWh/día) para poder ajustarlo al consumo del usuario en la Etapa 6
- [x] Pruebas unitarias de cada componente (entorno, reparto, polvo, degradación)
- [x] **Validación estadística contra NetLogo**, con la misma estructura que `herramientas/validar_modelo.py` (escenarios media/alta × política convencional/consciente, zona mixta, 10 semillas):
  - SoH **año a año** contra la tabla de `VALIDACION.md` (tolerancia ±0,3 puntos por año) → mayor diferencia 0,05
  - Energía comprada (±3 %), ciclos equivalentes y limpiezas (dentro del rango reportado)
  - R², RMSE contra la proyección de 1,5 %/año, igual que el script
  - Configuraciones de `GUIA_VARIACION.md` como pruebas de sensibilidad (20 semillas: con 5 las limpiezas varían demasiado) → 30 de 30 cumplen
  - Comparación lado a lado en `docs/VALIDACION_DART.md` (se regenera con `dart run tool/validar_motor.dart`)
- [x] Medir el tiempo de una corrida de 87 600 horas → **60–80 ms** en un PC; la Etapa 5 se simplifica

## Etapa 5 — Simulación de degradación dentro de la app
- [x] Formulario de parámetros con los valores por defecto del modelo (sistema, entorno, operación y una sección avanzada con polvo y coeficientes α, β, γ, δ)
- [x] Ejecución de la simulación sin congelar la interfaz: *isolate* (`compute()`) en Android; en web corre en el mismo hilo con un indicador (tarda poco)
- [x] Resultados: SoH final, pérdida por año, energía comprada a la red, limpiezas, ciclos equivalentes, SoH año a año y comparación lado a lado de política convencional vs. consciente **con la misma semilla (mismo clima)**
- [x] Reducir la serie a una serie **mensual** antes de guardar (120 meses en 10 años, en lugar de 87 600 horas)
- [x] Guardar cada corrida en Supabase (tabla `simulaciones_degradacion`): parámetros con la semilla + resultados (con el resumen de la otra política) + serie mensual
- [x] Acceso desde el inicio ("Simular degradación de batería")
- [x] Prueba manual en Chrome y Android (incluido medir cuánto tarda en el celular y guardar una simulación)

## Etapa 6 — Conectar los dos módulos
*Le da sentido a unir ambos proyectos en una sola app.*
- [x] Pasar automáticamente la capacidad de batería y la potencia de panel dimensionadas en la Etapa 3 como valores iniciales de la simulación (solo para batería de litio; botón "Simular la salud de esta batería" en los resultados de la calculadora)
- [x] Ajustar el perfil de consumo de la simulación al consumo diario calculado en la Etapa 3: el factor se mide con un año de referencia del modelo para el escenario elegido
- [x] Mapear las HSP del cálculo al escenario de irradiancia del modelo más cercano (alto ≈ 5 HSP, medio ≈ 3,5, bajo ≈ 0,3); la zona climática queda en mixta y es editable
- [x] Venta de excedentes calculada aparte: la hace la calculadora (Etapa 3); el modelo no la usa porque en él el excedente que no cabe en la batería se pierde
- [x] **Usar el año en que el SoH cae por debajo de 80 % como año de reemplazo de batería en el flujo de caja** (si no llega en la simulación, se extrapola con la pérdida anual)
- [x] Vincular la simulación con el cálculo que la originó (llave foránea `calculo_id`; el cálculo guardado devuelve su `id`)
- [x] Pantalla de cierre: tarjeta "Con el sistema que dimensionaste" con la vida de la batería y el retorno de inversión antes (vida típica) y después (vida simulada)
- [x] Prueba manual en Chrome y Android (calcular un sistema híbrido, guardarlo, simular su batería y guardar la simulación)

## Etapa 7 — Dashboard e historial
- [ ] Pantalla de inicio (dashboard) con accesos y resumen del último cálculo/simulación
- [ ] Gráfica de SoH a lo largo del tiempo (con la banda de referencia 80–100 %)
- [ ] Gráficas de consumo/generación mensual y energía comprada acumulada
- [ ] Historial de **cálculos** y de **simulaciones** guardados en Supabase (filtrar por fecha o por política), con opción de eliminar
- [ ] Opcional: exportar un resumen en PDF de una simulación

## Etapa 8 — Pulido de interfaz
- [ ] Ajustes finales del tema (paleta solar, modo claro/oscuro)
- [ ] Validación de formularios y mensajes de error claros (incluido "sin conexión" y "proyecto de Supabase pausado")
- [ ] Estados de carga y de "aún no tienes simulaciones guardadas"
- [ ] Revisar que se vea bien en distintos tamaños de pantalla (celular y navegador de escritorio)
- [ ] Formato de moneda (COP) y números con `intl`

## Etapa 9 — Pruebas integrales
- [ ] Pruebas de widgets en las pantallas principales
- [ ] Prueba de integración de principio a fin: registro → calculadora → simulación de degradación → guardar → ver en historial
- [ ] Prueba manual en un celular Android real y en el navegador

## Etapa 10 — Despliegue
- [ ] Ícono de la app y pantalla de inicio (splash)
- [ ] APK/AAB de Android firmado (keystore fuera del repo)
- [ ] Publicar la versión web (por ejemplo, Firebase Hosting, Netlify o GitHub Pages)
- [ ] Configurar en Supabase las URLs de redirección de Auth para la versión publicada

## Etapa 11 — Documentación y entrega
- [ ] README con instrucciones de instalación y variables de entorno de Supabase
- [ ] Manual breve de usuario (puedes reaprovechar texto de los dos Word que ya tienes)
- [ ] Documento de validación del modelo (Dart vs. NetLogo) de la Etapa 4
- [ ] Capturas de pantalla y, si la materia lo pide, video demo
- [ ] Preparar la sustentación: qué parte viene de cada materia y cómo se conectan
