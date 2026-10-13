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
| Precios de equipos | Tabla `precios_referencia` en Supabase + editables (desde la Etapa 12, solo en Dart; la tabla se quitó) | Valores de referencia actualizables sin publicar otra versión; el usuario puede ajustarlos en cada cálculo |
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
- [x] Pantalla de inicio (dashboard) con accesos y resumen del último cálculo/simulación
- [x] Gráfica de SoH a lo largo del tiempo (con la banda de referencia 80–100 %)
- [x] Gráficas de consumo/generación mensual y energía comprada acumulada
- [x] Historial de **cálculos** y de **simulaciones** guardados en Supabase (filtrar por fecha o por política), con opción de eliminar
- [ ] Opcional: exportar un resumen en PDF de una simulación
- [x] Prueba manual en Chrome y Android

## Etapa 8 — Pulido de interfaz
- [x] Ajustes finales del tema (paleta solar, modo claro/oscuro)
- [x] Validación de formularios y mensajes de error claros (incluido "sin conexión" y "proyecto de Supabase pausado")
- [x] Estados de carga y de "aún no tienes simulaciones guardadas"
- [x] Revisar que se vea bien en distintos tamaños de pantalla (celular y navegador de escritorio)
- [x] Formato de moneda (COP) y números con `intl`
- [x] Prueba manual en Chrome y Android

## Etapa 9 — Paleta de colores y accesibilidad
Colores con significado y contraste legible (mínimo 4,5:1 para texto, WCAG AA). Hoy el primario sale ocre (`#784E11`) porque Material 3 oscurece el ámbar semilla; los colores se fijan a mano.

| Elemento | Modo claro | Modo oscuro |
|---|---|---|
| Primario (botones, ícono del sol) | `#F59E0B` con texto `#1C1917` | `#FBBF24` con texto carbón |
| Consciente / detalles ecológicos | verde `#059669` | verde `#34D399` |
| Consumo de la casa | azul `#0284C7` | azul `#38BDF8` |
| Generación y política convencional | ámbar | ámbar |
| Fin de vida (80 %) | rojo `#DC2626` | rojo `#F87171` |
| Fondo | crema `#FFFBEB`, tarjetas blancas | carbón `#1C1917`, tarjetas un tono más claro |
| Texto principal | `#1C1917` | blanco cálido |

- [x] Paleta nueva en el tema (claro y oscuro equivalente)
- [x] Colores fijos por política en todas las gráficas: consciente siempre verde, convencional siempre ámbar (sin importar cuál se eligió)
- [x] Generación en ámbar y consumo en azul; fin de vida en rojo
- [x] Botones secundarios ("Simular degradación de batería", "Crear cuenta"): texto carbón, borde de 1,5 px y fondo ámbar al 8 %
- [x] Tarjetas con sombra suave además del borde (en oscuro, el borde marca la separación)
- [x] Prueba automática del contraste de cada par texto/fondo (≥ 4,5:1) en claro y oscuro
- [x] Prueba manual en Chrome y Android

## Etapa 10 — Pruebas integrales
Guía de pruebas y lista de prueba manual: [`PRUEBAS.md`](PRUEBAS.md).
- [x] Pruebas de widgets en las pantallas principales (todas las pantallas ≥ 84 % de líneas cubiertas)
- [x] Prueba de integración de principio a fin: registro → calculadora → simulación de degradación → guardar → ver en historial (en `flutter test`/CI y en el celular con Supabase falso)
- [x] Prueba de integración con el Supabase real (cuenta de prueba y `prueba.json`)
- [x] Prueba manual en un celular Android real y en el navegador (lista en `PRUEBAS.md`)

## Etapa 11 — Despliegue
Pasos para repetirlo: [`DESPLIEGUE.md`](DESPLIEGUE.md).
- [x] Ícono de la app y pantalla de inicio (splash)
- [x] Configuración de firma del APK (`android/key.properties`, fuera del repo) y nombre visible "Solarix"
- [x] APK de Android firmado con la llave propia (solo APK, sin AAB para Google Play)
- [x] Prueba manual del APK firmado en el celular (ícono, splash, arranque en claro, app completa)
- [ ] *En espera:* publicar la versión web (por ejemplo, Netlify o Firebase Hosting)
- [ ] *En espera:* configurar en Supabase las URLs de redirección de Auth para la versión publicada

## Etapa 12 — Arreglos
*Grietas encontradas en la revisión crítica del proyecto (abogado del diablo, dos rondas, 2026-10-04). Ordenadas por gravedad dentro de cada bloque. Todo lo que toca Supabase se aplica solo con el visto bueno del autor.*

**Integración batería ↔ flujo de caja (la más grave)**
- [x] Tope calendario a la vida simulada de la batería: usar el menor entre la vida por ciclos (simulación) y una vida calendario por química (por ejemplo, 12–15 años para LiFePO₄), porque el modelo no incluye envejecimiento calendario (`t-bat` no entra en la degradación). Hoy la pérdida simulada es de ≈ 8–11 % en 10 años, la extrapolación da 19–26 años y, con un horizonte de 20, la batería casi nunca se reemplaza: la tarjeta "antes/después" siempre favorece a la simulación
- [x] Mostrar en la tarjeta las dos vidas (por ciclos y calendario) y cuál limita
- [x] Revisar la extrapolación lineal de `aniosHastaFinDeVida` (la curva es `SoH = 100·e^(−Z)`, no una recta) o justificarla
- [x] Reemplazo de batería cerca del final del horizonte: no cobrar la batería entera si solo se usa uno o dos años (valor residual o prorrateo)
- [x] El ahorro de cada año baja con la energía que la batería degradada deja de aportar (medida contra una batería que no se degrada, con el mismo clima), cada política paga su costo en energía, la tarjeta compara Calculadora | Convencional | Consciente y el resultado se guarda con la simulación y se ve en el historial
- [x] Prueba manual del bloque en Android (revisada en el celular del autor)

**Economía de la calculadora**
- [x] Excedentes por tramos según la CREG 174 de 2021: lo exportado hasta lo importado, a tarifa menos comercialización; lo que pase de ahí, a precio de bolsa (editable). Hoy todo el excedente vale el 70 % de la tarifa
- [x] Incentivos de la Ley 1715 de 2014 (exclusión de IVA y beneficios de renta), al menos como opción
- [x] Explicar en la app de dónde salen los supuestos fijos (autoconsumo 60 % on-grid y 90 % híbrido, fracción nocturna 50 %, factor de excedentes, PR 0,78, factor 1,25) o enlazar la fuente
- [x] Prueba manual del bloque en Android (`PRUEBAS.md`, paso 20, revisada en el celular del autor)

**Coherencia entre cálculo y simulación (clima por ciudad)**
*NetLogo y las ecuaciones de Dart (`submodelos.dart`, `simulador.dart`) no se tocan: solo cambian las entradas (`integracion.dart`, tabla de ciudades y pantallas). Así sigue siendo cierto que "las ecuaciones son las de NetLogo, validadas con sus configuraciones; la app ajusta las entradas a cada ciudad".*
- [x] Criterio escrito y medible para asignar la zona climática a cada ciudad (por ejemplo, días de lluvia al año de NASA POWER o del IDEAM con umbrales fijos, y polvo por región, como La Guajira), registrado en `BITACORA.md` antes de llenar la tabla
- [x] Tabla de ciudades con HSP (NASA POWER), temperatura media (NASA POWER) y zona climática según ese criterio
- [x] Irradiancia máxima ajustada por ciudad: búsqueda del valor con el que el modelo, en la zona de la ciudad, produce sus HSP reales (unas 6–8 corridas de un año), con tope físico de ≈ 1 100 W/m²; si se llega al tope, la zona asignada está mal
- [x] Temperatura media tomada de la ciudad, no del escenario
- [x] Pantalla de simulación con selector de ciudad (o la del perfil); irradiancia y zona pasan a "Avanzado"
- [x] En "Avanzado", los escenarios de NetLogo intactos ("configuración de NetLogo, validada") y sin combinaciones imposibles (por ejemplo, irradiancia baja con zona muy soleada)
- [x] Prueba que recorra todas las ciudades: falla si alguna llega al tope de irradiancia o se aleja más de ±5 % de sus HSP reales
- [x] `dart run tool/validar_motor.dart` da los mismos resultados que hoy en `VALIDACION_DART.md`
- [x] Prueba manual del bloque en Android (revisada en el celular del autor)

**Que la demo no dependa de servicios gratuitos**
- [x] Calculadora y simulación sin sesión, con los respaldos locales (`ciudadesBase` y precios en Dart); la cuenta solo para guardar e historial
- [x] Una sola fuente de verdad para precios y ciudades: hoy la migración y `modelos.dart`/`catalogos.dart` se sincronizan a mano (ahora solo Dart; las tablas quedan sin uso)
- [x] Revisar el remitente de los correos: `@gmail.com` enviado por Brevo puede caer en spam por DMARC; probar con una cuenta nueva y, si falla, usar el remitente que Brevo recomiende (con Hotmail llega a la bandeja de entrada)
- [x] Cuenta de demo ya verificada para la sustentación (la de prueba de la Etapa 10; arranca vacía)
- [x] Copia de respaldo de la llave de firma (`solarix.jks`) y de `key.properties` fuera de este PC (en el Google Drive privado del autor)

**Seguridad del backend (nueva migración)**
- [x] Límite de tamaño en las columnas `jsonb` (`entradas`, `resultados`, `parametros`, `serie`), por ejemplo con `pg_column_size`
- [x] Tope de filas por usuario en `calculos_consumo` y `simulaciones_degradacion` (trigger que rechace pasado el límite)
- [x] Verificar que `calculo_id` sea del mismo usuario en las políticas de crear y actualizar simulaciones
- [x] Quitar `perfiles.zona_irradiancia` (concepto de la Etapa 1 que la app ya no usa) o reemplazarla: se quitó y la ciudad del perfil se elige de la lista y es el lugar por defecto. También se quitaron las tablas `precios_referencia` y `ciudades`, sin uso desde el bloque de servicios gratuitos
- [x] Límites de frecuencia de registro y envío de correos en Auth, versionados en `supabase/config.toml` y aplicados en el panel (el de correos por hora va en el panel: ver `DESPLIEGUE.md`)
- [x] Alertas de uso de Supabase y de Brevo a un correo que se revise (instrucciones en `DESPLIEGUE.md`; configuradas por el autor)

**Protección de datos (Ley 1581 de 2012)**
- [x] Casilla de autorización de tratamiento de datos en el registro, con enlace a la política
- [x] Página corta con la política de tratamiento de datos
- [x] Botón "Eliminar mi cuenta" en Perfil (borra el usuario de Auth; `on delete cascade` borra sus filas)
- [x] Prueba manual del bloque en Android con el Supabase real (verificada por el autor)

**Cierre**
- [x] Pruebas de cada arreglo (fórmulas, políticas RLS y pantallas nuevas): pruebas de Dart por bloque y `supabase/pruebas/seguridad_rls.sql` contra el Supabase real (18 de 18, todo se deshace)
- [x] Prueba manual en Chrome y Android (`PRUEBAS.md`, pasos 20 a 26)

**Valor de la batería y tarifa real (revisión crítica 3, 2026-10-05)**
*Con la CREG 174, el excedente que se envía a la red se descuenta de la factura a la tarifa menos el Cv, así que en un sistema con red la batería casi no ahorra dinero. Con 200 kWh/mes, 4,5 HSP y $890/kWh: el híbrido da VPN $14,9 M (batería buena) a $12,8 M (batería degradada), y el mismo sistema sin batería $18,6 M. En el aislado la degradación sí cambia la decisión (VPN de $8,7 M a −$5,2 M), pero el modelo manda el faltante a "energía comprada a la red", que en una casa sin red no existe.*
- [x] Resultados del híbrido: comparar con el mismo sistema sin batería ("la batería resta $X al VPN; su valor está en cubrir los cortes"), corriendo `calcular` dos veces (tarjeta "¿Y sin batería?")
- [x] Sistema aislado: mostrar "energía comprada a la red" como "energía que faltó" (cortes, planta o combustible), con una nota; solo cambian la etiqueta y su interpretación, no las ecuaciones de NetLogo
- [x] Tarifa según el estrato: tarifa efectiva con el subsidio de los estratos 1 a 3 hasta el consumo de subsistencia y la contribución de los estratos 5 y 6 (verificar antes los porcentajes y el consumo de subsistencia vigentes, que depende de la altura). Si no da tiempo, que el ⓘ de la tarifa diga qué valor del kWh usar
- [x] Consumo de subsistencia con "Mi ubicación": tomarlo de la altitud (la ubicación aproximada no trae altitud del GPS, así que se pide por coordenadas al servicio de elevación de Open-Meteo); antes: tomarlo de la altitud del GPS (`posicion.altitude`, que ya se lee para la temperatura); sin altitud, aviso visible de que se usó 173 kWh/mes y que se cambie si se vive a 1.000 m o más. Con el estrato 1, 173 en vez de 130 cambia la recuperación de 5,6 a 6,9 años
- [x] Cali: confirmar su consumo de subsistencia en una factura de EMCALI o en la lista oficial de la UPME y fijarlo a mano en la tabla con un comentario; hoy queda en 1.000 m exactos y la regla `>= 1000` le da 130 (fijado en 173: la cabecera está a unos 995 m; falta confirmarlo con una factura de EMCALI)
- [x] Campo "Subsidio de tu factura" solo para los estratos 1 a 3, con el máximo legal (60 / 50 / 15 %) por defecto: el operador puede aplicar uno menor
- [x] Citar el concepto CREG 3023 de 2026 (el consumo facturable del autogenerador es el neto después de la permuta y el subsidio se aplica sobre ese neto) en `valorEnergiaMes`, en el ⓘ del estrato y en `BITACORA.md`
- [x] Pruebas: "Mi ubicación" a 2.600 m da 130; sin altitud da 173 con aviso; el subsidio editado cambia el ahorro
- [ ] Pruebas de los tres puntos y prueba manual en Chrome y Android (`PRUEBAS.md`, pasos 27 a 30)
- [ ] Tres commits separados: sin batería, aislado y estrato

## Etapa 13 — Rediseño de la interfaz según el mockup
*Guía completa, con el código de cada widget y pantalla: [`MEJORAS_UI_MOCKUP.md`](MEJORAS_UI_MOCKUP.md) (mockup "Solarix — Mockups UI/UX" en Figma, Ingeniería de Software, Clase 13). Solo cambia la capa de presentación: cálculos, Supabase, rutas y validaciones quedan igual. Diseño de celular por debajo de 900 px y diseño web desde 900 px.*
- [ ] Tema: colores `solarSuave` y `bordeFuerte`, botón secundario, campos, selector segmentado, barra superior y aviso flotante (guía, sección 2)
- [ ] Sol: declarar `assets/icono/sol.png` en `pubspec.yaml`, crear `SolSolarix` y reemplazar `Icons.wb_sunny_rounded` (guía, sección 2.4)
- [ ] Widgets base: `solarix_ui.dart` (burbuja, tarjeta de sección, fila de dato, mosaico, aviso, encabezado de paso) y `barra_web.dart` (barra superior y avatar con iniciales)
- [ ] Resultados: tarjetas con burbuja, destacado ámbar, nota de la Ley 1715 como aviso, guardar con acción "VER" y grilla 2×2 en web
- [ ] Inicio: saludo con el nombre, cifras en mosaicos, leyenda de la gráfica y, en web, historial reciente (leer también el VPN en `CalculoGuardado`)
- [ ] Perfil: avatar con iniciales, mosaicos de actividad, tarjetas "Datos personales" y "Apariencia", dos columnas en web
- [ ] Calculadora: indicador de pasos propio en lugar del `Stepper` (celular) y tarjeta de pasos lateral (web), con el paso como pregunta
- [ ] Equipos: lista en una tarjeta, banda verde con el consumo total y tabla en web
- [ ] Bienvenida web en dos columnas, con un enlace a la política de datos (sin "al continuar aceptas": la autorización expresa sigue en la casilla del registro, Ley 1581)
- [ ] Resto de pantallas (simulación, historial, detalle, acceso): barra web y tarjetas con burbuja (guía, sección 5.6)
- [ ] Pruebas: actualizar las que buscan textos que cambian (guía, sección 6), contraste de `solarSuave` en claro y oscuro, y mantener la prueba de 320 px
- [ ] Revisión visual contra el mockup en celular y web, claro y oscuro, y prueba manual en Chrome y Android

## Etapa 14 — Documentación y entrega
- [ ] README con instrucciones de instalación y variables de entorno de Supabase
- [ ] Manual breve de usuario (puedes reaprovechar texto de los dos Word que ya tienes)
- [ ] Documento de validación del modelo (Dart vs. NetLogo) de la Etapa 4
- [ ] Capturas de pantalla y, si la materia lo pide, video demo
- [ ] Preparar la sustentación: qué parte viene de cada materia y cómo se conectan
- [ ] Diapositiva de límites del modelo: sin envejecimiento calendario, validación Dart contra NetLogo (no contra baterías reales), coeficientes sin calibrar con datos medidos, y configuraciones por ciudad interpoladas que no se validaron una por una
- [ ] Hoja de fórmulas con el origen de cada constante, para responder sin mirar el código
- [ ] Reactivar Supabase y ensayar la demo 24 horas antes (registro con correo nuevo incluido)
