# Solarix — Bitácora del proyecto

Registro de lo que se **hizo**, **corrigió** o **eliminó** en el proyecto, en orden cronológico (lo más reciente al final). El plan está en [`ETAPAS_SOLARIX_APP.md`](ETAPAS_SOLARIX_APP.md).

**Cómo registrar:** una entrada por fecha y etapa. Cada línea empieza con una etiqueta:
`HECHO` (algo nuevo) · `CORREGIDO` (se arregló algo que estaba mal) · `ELIMINADO` (se quitó algo) · `DECISIÓN` (se eligió un camino) · `PENDIENTE` (quedó por hacer).

---

## 2026-10-01 — Etapa 0: preparación

- `HECHO` Revisión del plan original (10 etapas) y reestructuración a 12 etapas (0–11): la Etapa 4 se dividió en motor en Dart puro (4) y simulación en la app (5); se agregaron la Etapa 10 (despliegue) y las pruebas por etapa.
- `DECISIÓN` Plataformas: Android + Web. Backend: Supabase. País/moneda: Colombia / COP.
- `DECISIÓN` Flujo de git: al cerrar cada etapa el autor la revisa y hace commit + push.
- `HECHO` Repositorio privado creado: `github.com/CASTILLA057/Solarix`. Primer commit con el plan (`Etapa 0: plan del proyecto Solarix`).
- `HECHO` Organización de Supabase propia **Solarix** y proyecto `solarix` (ref `byopepmwxjdwdyhyrwch`, us-east-1), separados de cualquier otro proyecto del autor.
- `HECHO` `env.json` creado con la URL y la publishable key (fuera de git). Contraseña de la base de datos aleatoria guardada en `supabase/.db-password` (fuera de git).
- `CORREGIDO` El primer intento de crear el proyecto en otra organización fue rechazado por permisos; no se creó nada allí y se creó la organización propia.
- `HECHO` Material de origen copiado a `docs/referencia/`: `index.html`, `Degradacion_Baterias_Fotovoltaicos_corregido.docx`, `DegradacionBateriasSistemasFotovoltaicos.nlogox`, `GUIA_VARIACION.md`.
- `CORREGIDO` (por el autor) `ETAPAS_SOLARIX_APP.md` y `README.md` movidos de la raíz a `docs/`.

## 2026-10-01 — Etapa 1: configuración (pendiente de revisión y commit)

- `HECHO` Proyecto Flutter creado para Android y Web (`com.castilla057.solarix`), Flutter 3.47.5 / Dart 3.13.4.
- `HECHO` Dependencias: `supabase_flutter` 2.18, `flutter_riverpod` 3.4, `go_router` 18.0, `fl_chart` 1.2, `intl` 0.20.
- `HECHO` Estructura: `lib/core/{config,theme,router}`, `lib/features/{auth,calculadora,degradacion,dashboard}`, `lib/app.dart`, `lib/main.dart`.
- `HECHO` Tema solar (semilla ámbar `#F59E0B`) con modo claro/oscuro; pantalla de inicio provisional que indica si Supabase está configurado.
- `ELIMINADO` App de ejemplo del contador de `flutter create` (`main.dart` y su prueba), reemplazada por la estructura de Solarix.
- `HECHO` Credenciales por `--dart-define-from-file=env.json`; plantilla `env.example.json`; `env.json`, `supabase/.db-password` y `supabase/.temp/` en `.gitignore`.
- `HECHO` Migración `supabase/migrations/20261001000000_esquema_inicial.sql`: tablas `perfiles`, `calculos_consumo`, `simulaciones_degradacion`, trigger que crea el perfil al registrarse, índices y RLS (cada usuario solo ve sus filas).
- `HECHO` CI en `.github/workflows/ci.yml`: formato, `flutter analyze` y `flutter test` en cada push a `main`.
- `CORREGIDO` `anonKey` (obsoleto en supabase_flutter 2.18) reemplazado por `publishableKey`; la variable pasó de `SUPABASE_ANON_KEY` a `SUPABASE_PUBLISHABLE_KEY`.
- `CORREGIDO` Formato de `env.dart` y `app_theme.dart` con `dart format` (el CI lo exige).
- `HECHO` Verificado: `flutter analyze` sin advertencias, prueba de widget pasa, `flutter build web` compila.
- `HECHO` Carpeta del proyecto vinculada al proyecto de Supabase (`supabase link`). Prueba en seco de la migración: solo aplicaría `esquema_inicial.sql`.
- ~~`PENDIENTE` Aplicar la migración en Supabase (requiere confirmación del autor).~~ → Hecho, ver la entrada "Etapa 1: migración aplicada".
- `PENDIENTE` Probar la app en Chrome y Android con `env.json`.

## 2026-10-01 — Revisión del material de origen

### Calculadora HTML (Proyecto Integrador I)

Supuestos fijos encontrados y su corrección planeada en la Etapa 3:

| Cálculo | En el HTML | Problema | Corrección |
|---|---|---|---|
| Paneles | `ceil(Wh·1,25 / HSP / 250)` | Panel fijo de 250 W (hoy 450–600 W) | Potencia del panel editable; `n = ceil(E_día / (HSP·PR) / W_panel)` |
| Batería | `Wh·2 / 12 V / 0,5` | Siempre 12 V, 2 días, DoD de plomo-ácido; ignora η del inversor | Química, voltaje y autonomía configurables; `C = E·días / (DoD·η_inv)` |
| Inversor | `Σ W · 1,3` | Ignora el pico de arranque de motores (nevera, bomba) | Mayor entre potencia continua y arranque |
| Nevera | 150 W × 12 h | Funciona por ciclos durante 24 h | kWh/día o % de tiempo encendida |
| Controlador | Por número de paneles | Debe depender de la corriente | `I = P_paneles / V_sistema · 1,25` |
| Costos | Precios 2024 en el código; instalación fuera del total | Se desactualizan | Tabla `precios_referencia` en Supabase, editable; instalación incluida |
| ROI | Deslizadores independientes de la calculadora; `inversión / ahorro` | No incluye reemplazo de baterías, alza de tarifa, pérdida de rendimiento ni valor del dinero | Flujo de caja con esos factores; el reemplazo de batería vendrá de la simulación (Etapa 6) |
| Alcance | Solo Zonas No Interconectadas | No sirve para hogares conectados a la red | Tipos on-grid / off-grid / híbrido, consumo desde la factura y excedentes (CREG 174) |
| HSP | 3 valores fijos (5,5 / 4,5 / 3,5) | Poco preciso | Tabla de ciudades + NASA POWER |
| Equipos | 8 fijos ("x4" en el nombre) | No se pueden agregar | Equipos personalizados con cantidad |

### Modelo NetLogo e informe

- `HECHO` Leído el código del modelo (NetLogo 7.0.4) y el informe ODD. El motor de Dart seguirá el **código del modelo**, que es la versión calibrada.
- `DECISIÓN` Diferencias Word ↔ modelo documentadas en la Etapa 4 (horizonte 2 880 vs 87 600 h, política consciente 20–50 % vs tope 95 % y 0,16 C, limpieza por costo vs por umbral, precio de energía no usado, `t-bat` no usado en la degradación).
- `HECHO` El perfil de consumo del modelo da ≈ 18 kWh/día; la Etapa 4 incluirá un factor de escala para ajustarlo al consumo del usuario en la Etapa 6.
- `DECISIÓN` El modelo usa semilla aleatoria; la validación Dart vs NetLogo será estadística (promedios de varias semillas).

### Guía de variación (`GUIA_VARIACION.md`)

- `HECHO` Revisada. Sirve como **tabla de valores esperados** para validar el motor en Dart: promedios de 5 corridas por configuración (referencia: SoH ≈ 85,0 %, ≈ 24 000 kWh comprados, ≈ 70 limpiezas, ≈ 2 700 ciclos).
- `HECHO` Verificaciones de coherencia que pasan: la política consciente reduce la caída de SoH en 10,5 % (13,43 vs 15,01 puntos); "carga-maxima 80 + carga-minima 20" da lo mismo que "100 + 40" (89,44 %); escenario bajo da SoH 100 % porque el panel (≤ 0,25 kW) nunca supera el consumo y la batería no carga.
- ~~`CORREGIDO` La guía dice que la política consciente compra "≈ 5 %" más energía; con sus propias cifras es ≈ 6 %.~~ → Ver entrada siguiente: no era un error.
- ~~`PENDIENTE` El `.nlogox` está guardado con `zona = lluviosa`.~~ → Resuelto en la entrada siguiente.
- ~~`PENDIENTE` Faltan `VARIABLES_INTERFAZ.md`, `EXPLICACION_MODELO.md` y `VALIDACION.md`.~~ → Resuelto en la entrada siguiente.

### Decisiones tomadas tras la revisión

- `DECISIÓN` HSP: tabla de ciudades + API NASA POWER.
- `DECISIÓN` Baterías: litio y plomo-ácido en la calculadora; la simulación de degradación solo para litio.
- `DECISIÓN` Precios: tabla `precios_referencia` en Supabase con valores de referencia 2026, editables.
- `DECISIÓN` Validación: se usan los resultados de NetLogo del autor (`GUIA_VARIACION.md`).
- `HECHO` `ETAPAS_SOLARIX_APP.md` actualizado con todo lo anterior (Etapas 0, 3, 4, 5 y 6 y tabla de decisiones).

## 2026-10-01 — Revisión de la documentación del modelo y de `herramientas/`

- `HECHO` (por el autor) `.nlogox` guardado con `zona = mixta` y ubicado en `docs/referencia/`. Copiados `VARIABLES_INTERFAZ.md`, `EXPLICACION_MODELO.md`, `VALIDACION.md`, `herramientas/` (`validar_modelo.py`, `construir_modelo.py`, `codigo_modelo.txt`) y `dashboard/` (`dashboard.html`, `datos.js`).
- `CORREGIDO` La observación sobre el "≈ 5 %" de la guía era errónea: 5 % es el **promedio** de los escenarios medio (+4,3 %) y alto (+6,0 %), como explica `VALIDACION.md`. La guía está bien.
- `HECHO` `VALIDACION.md` revisado: los porcentajes cuadran (caída de SoH −7,7 % media y −10,6 % alta; energía +4,3 % y +6,0 %; flujo −4,4 % y −5,4 %). Aporta el **SoH año a año** (promedio de 10 corridas) y la desviación estándar de cada caso (SoH ± 0,003–0,097 puntos), que se usarán como prueba del motor en Dart.
- `HECHO` `EXPLICACION_MODELO.md` revisado contra el código: coinciden (cadena de Markov ≈ 45/34/21 %, ≈ 4 tormentas de polvo al año, máximo de temperatura a las 15:00). Precisa que el consumo es **≈ 20 kWh/día** (la estimación previa de ≈ 18 no contaba el efecto del calor) y que el excedente que no cabe en la batería **se pierde, no se vende**.
- `HECHO` `codigo_modelo.txt` es idéntico al código dentro del `.nlogox`: hay una sola fuente del modelo.
- `CORREGIDO` Se supuso que `validar_modelo.py` contenía el modelo programado en Python; en realidad ejecuta NetLogo 7.0.4 sin interfaz (BehaviorSpace) sobre el `.nlogox`. No existe una segunda implementación del modelo.
- `HECHO` `validar_modelo.py` revisado: método correcto (velocidad 9 = 1 año por paso, 10 réplicas, zona fijada en `mixta` por código). Detalles menores: usa desviación estándar poblacional; fallaría si una corrida terminara antes por fin de vida; al ejecutarse sobrescribe `VALIDACION.md` y necesita la carpeta `shell/` junto al modelo.
- `HECHO` `construir_modelo.py` explica la diferencia de valores por defecto: genera escenario `baja` y velocidad 2 (lo que dicen los documentos); el `.nlogox` guardado tiene `alta` y velocidad 1 porque se cambió después en la interfaz de NetLogo. Los documentos están bien. Requiere un `.nlogox.bak` que no está en la carpeta; no se necesita para la app.
- `HECHO` `dashboard/datos.js` es una corrida de 10 años con zona `lluviosa` (SoH 85,21 %, 3 limpiezas) y una fila por día (≈ 280 KB). Sirve como trayectoria de referencia de forma en la Etapa 4 y confirma que en Supabase debe guardarse la serie mensual, no la diaria (Etapa 5).
- `HECHO` `ETAPAS_SOLARIX_APP.md` actualizado en la Etapa 4: consumo ≈ 20 kWh/día, tolerancia de SoH ±0,3, validación con la estructura de `validar_modelo.py` y la tabla año a año, y nota de que el excedente se pierde (Etapa 6).

## 2026-10-01 — Etapa 1: migración aplicada

- `HECHO` Migración `20261001000000_esquema_inicial.sql` aplicada al proyecto `solarix` con `supabase db push` (confirmado por el autor).
- `HECHO` Verificado con consultas de solo lectura: migración registrada en local y remoto; tablas `perfiles` (RLS activo, 2 políticas), `calculos_consumo` (RLS activo, 4 políticas) y `simulaciones_degradacion` (RLS activo, 4 políticas); trigger `al_crear_usuario` creado.
- `PENDIENTE` Probar la app en Chrome y Android con `env.json` (última tarea de la Etapa 1).

## 2026-10-01 — Etapa 1: ejecución desde VS Code

- `HECHO` La app abre en Chrome y muestra "Supabase conectado" al ejecutarla con `--dart-define-from-file=env.json` (verificado por el autor).
- `CORREGIDO` La app mostraba "Supabase sin configurar" porque se había ejecutado sin el parámetro `--dart-define-from-file=env.json` (las credenciales se incluyen al compilar). `env.json` estaba bien.
- `HECHO` Creado `.vscode/launch.json` con las configuraciones "Solarix (Chrome)" y "Solarix (Android)", que agregan el parámetro automáticamente al ejecutar con F5. No contiene credenciales; se sube a git.

## 2026-10-01 — Etapa 1: completada

- `HECHO` La app se instala y abre en un celular Android real (configuración "Solarix (Android)" de VS Code) y muestra "Supabase conectado" (verificado por el autor). También verificada en Chrome.
- `HECHO` Todas las tareas de la Etapa 1 completas. Queda pendiente la revisión del autor y el commit + push (`Etapa 1: configuración del proyecto Flutter y Supabase`).
- `HECHO` Subida a GitHub en 5 commits separados por tema (Flutter base, esquema de Supabase, CI, VS Code, documentación), hechos por Claude a pedido del autor.

## 2026-10-01 — Etapa 2: autenticación

- `DECISIÓN` Recuperación de contraseña y confirmación de correo con **código de 6 dígitos** escrito en la app (OTP), en lugar de enlaces: funciona igual en Android y web, sin deep links.
- `HECHO` Capa de datos: `AuthRepository` (interfaz) con `SupabaseAuthRepository` y `SinBackendAuthRepository` (para CI/pruebas sin `env.json`); `PerfilRepository` sobre la tabla `perfiles`. Los errores de Supabase se traducen a mensajes en español (`ErrorApp`, `mensajeErrorAuth`).
- `HECHO` Pantallas: iniciar sesión, crear cuenta, confirmar correo con código (con reenvío), recuperar contraseña en dos pasos, perfil (nombre, ciudad, irradiancia por defecto) con cerrar sesión. Acceso al perfil desde el inicio.
- `HECHO` Navegación protegida (`redirigir` en `lib/core/router/rutas.dart`): sin sesión → login; con sesión no se ven login, registro ni verificación; la pantalla de recuperar se permite en ambos casos porque validar el código abre la sesión antes de cambiar la contraseña. El router se reevalúa con cada cambio de sesión.
- `HECHO` La sesión la persiste `supabase_flutter` (SharedPreferences en Android, localStorage en web).
- `HECHO` Registro con un correo ya existente: Supabase responde éxito sin identidades (para no revelar cuentas); se detecta y se muestra "Ya existe una cuenta con ese correo".
- `ELIMINADO` `InicioScreen.ruta`, reemplazado por las constantes de `Rutas`; `lib/features/auth/.gitkeep`.
- `CORREGIDO` Filas "¿No tienes cuenta? / ¿Ya tienes cuenta?" cambiadas de `Row` a `Wrap`, y lista de irradiancia con `isExpanded`: se desbordaban en pantallas angostas o con letra grande (detectado por las pruebas).
- `HECHO` 25 pruebas pasan (validadores, mensajes de error, reglas de navegación, flujos de login, registro, recuperación, perfil y cierre de sesión con repositorio falso); `flutter analyze` sin advertencias.
- `PENDIENTE` Agregar `{{ .Token }}` a las plantillas "Confirm signup" y "Reset password" de Supabase.
- `PENDIENTE` Prueba manual con Supabase real en Chrome y Android.
- `CORREGIDO` `android/build/` (salida de compilación de Android generada al ejecutar en el celular) agregado al `.gitignore`.
- `HECHO` Subida a GitHub en commits separados por tema (capa de datos, pantallas y navegación, pruebas, `.gitignore`, documentación), a pedido del autor.

## 2026-10-01 — Etapa 2: plantillas de correo con código

- `HECHO` Plantillas versionadas en git: `supabase/config.toml` (solo declara las plantillas "confirmation" y "recovery") y `supabase/templates/confirmacion.html` y `recuperacion.html` con `{{ .Token }}`. `supabase config push` solo sube lo declarado; `supabase config diff` confirmó que únicamente cambiarían las dos plantillas.
- `HECHO` Encontrado en el `config diff`: el proyecto usa códigos de **8 dígitos** (`otp_length = 8`) y la confirmación de correo está activa. La app acepta códigos de 6 a 10 dígitos, así que no requiere cambios.
- `CORREGIDO` El `config push` fue **rechazado por Supabase**: en el plan gratis con el correo incluido no se pueden modificar las plantillas; hace falta un proveedor de correo propio (SMTP). Verificado con `config diff` que el proyecto quedó sin cambios.
- ~~`PENDIENTE` Configurar un SMTP propio y volver a ejecutar `supabase config push`.~~ → Hecho, ver la entrada siguiente.

## 2026-10-01 — Etapa 2: SMTP propio y plantillas aplicadas

- `DECISIÓN` Proveedor de correo: **Brevo** (gratis, 300 correos/día, sin dominio propio), con un correo dedicado al proyecto como remitente (`solarixapp@gmail.com`) en lugar del correo personal. Adelantado desde la Etapa 10.
- `HECHO` (por el autor) Cuenta de Brevo, remitente verificado y SMTP configurado en Supabase (las credenciales las maneja solo el autor).
- `HECHO` Verificado con `config diff` (solo lectura): SMTP activo con `smtp-relay.brevo.com:587`, remitente "Solarix" y límite de 30 correos/hora.
- `HECHO` `supabase config push`: aplicadas 4 propiedades (asunto y contenido de las plantillas "confirmation" y "recovery"); las otras 19 propiedades del proyecto, incluido el SMTP, quedaron sin cambios. Verificado después con `config diff`: 0 diferencias en lo declarado.
- `HECHO` Prueba real: el correo de Solarix con el código llega correctamente a través de Brevo (verificado por el autor).
- `HECHO` Subida a GitHub en commits separados (plantillas de correo, documentación).
- ~~`PENDIENTE` Completar la prueba manual del resto del flujo: perfil, cerrar sesión y recuperar contraseña.~~ → Hecho, ver la entrada siguiente.

## 2026-10-01 — Etapa 2: prueba manual y nuevas tareas

- `HECHO` Prueba manual completa con Supabase real, verificada por el autor: registro, código de confirmación, inicio, perfil, cerrar sesión, iniciar sesión y recuperar contraseña funcionan.
- `DECISIÓN` Se agregan tres mejoras de experiencia a la Etapa 2, pedidas por el autor tras la prueba:
  - Pantalla de **bienvenida** al abrir sin sesión, con botones para iniciar sesión o crear cuenta (web y Android).
  - **Transiciones suaves** (fundido con desplazamiento leve) al cambiar de pantalla, en lugar del cambio de golpe.
  - **Recuperar contraseña en tres pasos**: correo → verificar el código → solo si es correcto, contraseña nueva y repetirla. Hoy el código y la contraseña nueva se piden juntos.
- ~~`PENDIENTE` Implementar las tres mejoras y sus pruebas.~~ → Hecho, ver la entrada siguiente.

## 2026-10-01 — Etapa 2: bienvenida, transiciones y recuperación en tres pasos

- `HECHO` **Bienvenida** (`bienvenida_screen.dart`): logo, "Bienvenido a Solarix", una frase, tres características y los botones **Iniciar sesión** y **Crear cuenta**; el contenido aparece con un fundido y un leve ascenso (600 ms). Sin sesión la app abre aquí; con sesión guardada sigue entrando directo al inicio.
- `HECHO` Rutas de acceso como **hijas de la bienvenida** (`/bienvenida/login`, `/bienvenida/registro`, `/bienvenida/verificar`, `/bienvenida/recuperar`): el botón atrás de web y Android vuelve a la bienvenida. Sin sesión, cualquier ruta privada redirige a `/bienvenida` (antes a `/login`).
- `HECHO` **Transiciones suaves** (`TransicionSuave` en `lib/core/theme/transicion_suave.dart`): fundido con desplazamiento horizontal del 4 % y curva `easeOutCubic`, aplicado en el tema para todas las plataformas, así cubre también las pantallas futuras.
- `HECHO` **Recuperar contraseña en tres pasos**: (1) correo → enviar código; (2) verificar el código, con "Reenviar código" y "Usar otro correo"; (3) solo con el código correcto aparecen "Contraseña nueva" y "Repite la contraseña nueva". Cambio animado entre pasos (fundido + tamaño, 300 ms). Si el usuario sale en el paso 3 sin cambiar la contraseña, se cierra la sesión temporal que abre la verificación.
- `CORREGIDO` `AuthRepository.restablecerContrasena` se dividió en `verificarCodigoRecuperacion` y `cambiarContrasena`, para poder verificar el código antes de pedir la contraseña nueva.
- `CORREGIDO` Detectado por las pruebas: al abrir recuperar con `push` desde el login, la ubicación base seguía siendo el login; al verificar el código (sesión temporal) el router redirigía al inicio antes del paso 3. Ahora se navega con `go` a la ruta de recuperación.
- `HECHO` 30 pruebas pasan: 5 nuevas (el botón atrás vuelve a la bienvenida, código incorrecto, salir sin cambiar la contraseña, rutas de acceso hijas de la bienvenida, transición suave en el tema) y las existentes adaptadas a la bienvenida y a los tres pasos; `flutter analyze` sin advertencias.
- `HECHO` Prueba manual de las mejoras en Chrome y Android, verificada por el autor: bienvenida, transiciones y recuperación en tres pasos funcionan.
- `HECHO` **Etapa 2 completa.** Subida a GitHub en commits separados por tema (transiciones, recuperación en tres pasos, bienvenida y rutas, pruebas, documentación).

## 2026-10-01 — Etapa 3: calculadora solar

- `HECHO` **Núcleo de cálculo** en Dart puro (`lib/features/calculadora/domain/`): modelos (`TipoSistema`, `QuimicaBateria`, `Equipo`, `Precios`, `Supuestos`, `EntradasCalculo`, `ResultadoCalculo`) y fórmulas (`calculadora.dart`): energía diaria, paneles, voltaje del banco (12/24/48 V), batería, inversor con arranque de motores, controlador, costos con instalación, ahorro con autoconsumo y excedentes, flujo de caja con alza de tarifa, pérdida de rendimiento de paneles, mantenimiento y reemplazo de batería, VPN y recuperación simple y descontada.
- `HECHO` **Catálogos**: 12 equipos comunes con potencias típicas (la nevera por ciclos, 1,2 kWh/día) y 28 ciudades de Colombia con HSP aproximadas; clasificación de HSP en las zonas del modelo (≥ 5 alta, ≥ 4 media, < 4 baja).
- `HECHO` **NASA POWER** (`recurso_solar.dart`): "usar mi ubicación" con `geolocator` (ubicación aproximada) y la climatología de NASA (`ALLSKY_SFC_SW_DWN`, promedio anual = HSP). Verificado con la API real: Ocaña = 5,03 HSP; permite llamadas desde el navegador (CORS). La API tarda más de 60 s, así que la app espera hasta 90 s y muestra un aviso; si falla, se elige una ciudad.
- `HECHO` **Supabase**: migración `20261001000100_calculadora.sql` con `precios_referencia` (9 precios 2026 en COP) y `ciudades` (28 ciudades), lectura con sesión y RLS; guardado de cada cálculo en `calculos_consumo` (entradas y resultados en jsonb). Si las tablas no responden se usan los valores locales.
- `HECHO` **Pantallas**: asistente de 4 pasos (tipo de sistema → consumo por equipos o factura → ubicación por ciudad, NASA o a mano → panel, batería, supuestos y precios editables) y pantalla de resultados (consumo, sistema recomendado, costos, ahorro, recuperación, VPN) con botón para guardar. Acceso desde el inicio.
- `HECHO` Dependencias nuevas: `http` y `geolocator`. Lectura de números escritos a la colombiana (`1.500.000`, `4,5`) en `Formato.leer`.
- `CORREGIDO` El `AndroidManifest.xml` principal **no tenía el permiso de internet**: Flutter solo lo agrega en la compilación de desarrollo, así que el APK de producción no habría podido conectarse a Supabase. Agregado junto con el permiso de ubicación aproximada.
- `CORREGIDO` Detectado por las pruebas: el `Stepper` construye los botones y mensajes de todos los pasos (los ocultos con altura cero), lo que duplicaba botones para lectores de pantalla. Ahora solo se dibujan los del paso actual.
- `HECHO` 60 pruebas pasan (30 nuevas: fórmulas con valores calculados a mano, flujo de caja, NASA POWER, formato de números y el flujo completo del asistente); `flutter analyze` sin advertencias; la versión web compila.
- `DECISIÓN` Valores por defecto (todos editables en la app): tarifa 950 COP/kWh, panel 550 W, rendimiento del sistema 78 %, eficiencia del inversor 90 %, autonomía 2 días, autoconsumo 60 % (red) y 90 % (híbrido), excedentes al 70 % de la tarifa, alza de tarifa 6 %/año, pérdida de paneles 0,5 %/año, mantenimiento 1 %/año, tasa de descuento 10 %, horizonte 20 años; vida de batería 10 años (litio) y 4 (plomo).
- ~~`PENDIENTE` Aplicar la migración en Supabase.~~ → Hecho, ver la entrada siguiente.
- ~~`PENDIENTE` Revisar los precios y las HSP de referencia con cotizaciones y datos reales.~~ → Hecho, ver la entrada siguiente.
- `PENDIENTE` Opcional: incentivos de la Ley 1715 de 2014.
- `PENDIENTE` Prueba manual en Chrome y Android.

## 2026-10-01 — Etapa 3: precios y HSP con datos reales, migración aplicada

- `CORREGIDO` **Precios de referencia** actualizados con precios publicados por tiendas colombianas (consultados el 2026-10-01):

  | Clave | Antes | Ahora | Base |
  |---|---|---|---|
  | Panel | 900 COP/Wp | **1.050 COP/Wp** | Panel de 550 W ~ $580.000 (rango $400.000–750.000) |
  | Inversor de red | 600 COP/W | **900 COP/W** | Growatt MIN 5000TL-X ~ $4,68 M |
  | Inversor aislado/híbrido | 900 COP/W | **1.000 COP/W** | 5 kW: $2,4 M (económicos) a $8 M (Deye, Growatt) |
  | Batería de litio | 1.500.000 COP/kWh | **820.000 COP/kWh** | LiFePO4 48 V 100 Ah (5,12 kWh): $3,59 M–4,65 M |
  | Batería de plomo | 500.000 COP/kWh | **650.000 COP/kWh** | Gel 12 V 200 Ah (2,4 kWh): $1,29 M–2,5 M |
  | Controlador | 15.000 COP/A | **12.000 COP/A** | MPPT 60 A: $550.000–850.000 |
  | Estructura, cableado y protecciones | 150.000 COP/panel | **300.000 COP/panel** | Calibración (ver abajo) |
  | Instalación, RETIE y trámites | 15 % (mín. $500.000) | **30 % (mín. $1,5 M)** | Calibración (ver abajo) |
  | Tarifa por defecto | 950 COP/kWh | **890 COP/kWh** | Costo unitario CENS (Norte de Santander), enero 2026: $888/kWh |

- `HECHO` **Calibración del costo total**: con solo los precios de equipos, un sistema conectado a la red de 5,5 kWp salía en ~ $12,7 M, por debajo del mercado (**$18–25 M por 5 kWp instalado; $2–5,5 M por kWp** con RETIE y trámites). Con estructura y protecciones a $300.000/panel e instalación al 30 %, queda en ~ $3,3 M/kWp. Una prueba nueva verifica que sistemas de 150, 300 y 600 kWh/mes queden en el rango de $2–5,5 M/kWp.
- `HECHO` Hallazgo: con precios reales, el litio (820.000 COP/kWh, 90 % usable) sale más barato por kWh útil que el plomo (650.000 COP/kWh, 50 % usable) y dura más del doble.
- `CORREGIDO` **HSP de las 28 ciudades** reemplazadas por la climatología de NASA POWER (`ALLSKY_SFC_SW_DWN`, promedio anual) consultada en las coordenadas de cada ciudad, redondeada a un decimal. Cambios notables: Bogotá 4,1 → 4,6; Cúcuta 5,0 → 4,3; Medellín 4,5 → 4,9; Bucaramanga 4,6 → 5,1; Santa Marta 5,5 → 5,7; Riohacha 6,0 → 5,5; Quibdó 3,5 → 4,0. Ocaña se mantiene en 5,0 (5,03).
- `DECISIÓN` Limitación documentada: NASA POWER tiene una resolución de unos 50 km, así que ciudades cercanas comparten valor (Armenia, Ibagué y Pereira: 4,5468) y en zonas montañosas puede diferir del Atlas de Radiación del IDEAM. Se eligió por ser una fuente pública, consistente para todo el país y la misma que usa "usar mi ubicación".
- `HECHO` Prueba nueva que lee la migración SQL y verifica que sus precios y ciudades coincidan con los valores locales del código (`Precios.referencia`, `ciudadesBase`). 63 pruebas pasan.
- `HECHO` Migración `20261001000100_calculadora.sql` aplicada al proyecto `solarix` (confirmado por el autor). Verificado con consultas de solo lectura: `precios_referencia` con 9 filas y `ciudades` con 28, ambas con RLS activo; panel a 1.050 COP/Wp y Ocaña con 5,0 HSP.
- `HECHO` Prueba manual de la calculadora en Chrome y Android, verificada por el autor; 2 cálculos guardados en `calculos_consumo` (híbrido y aislado), comprobado con una consulta de solo lectura.
- `CORREGIDO` Reportado por el autor: las etiquetas "Potencia de cada panel", "Rendimiento del sistema (PR)" y "Panel" aparecían cortadas. Eran el primer campo de bloques que recortan su contenido (el paso del Stepper y las dos secciones desplegables), y la etiqueta flotante sobresale por arriba del campo. Se agregó un margen superior de 12 px a esos bloques.
- `DECISIÓN` "Mi ubicación" se deja como está: tarda 40–70 s porque NASA POWER calcula en el momento el promedio de unos 20 años. Se evaluaron dar al instante el valor de la ciudad más cercana y guardar las consultas por zona en Supabase; el autor prefirió no hacerlo por ahora. PVGIS se descartó porque bloquea las llamadas desde el navegador (CORS).
- `HECHO` **Etapa 3 completa** (salvo la tarea opcional de la Ley 1715). Subida a GitHub en commits separados por tema.
- Fuentes consultadas (Etapa 3): [Autosolar — precios de paneles 2026](https://autosolar.co/energia-solar/cuanto-cuesta-un-panel-solar-en-colombia), [Solartech — precios 2026](https://solartech.com.co/precios-paneles-solares-colombia/), [Ineldec — baterías LiFePO4 48 V](https://ineldec.com/producto/bateria-de-litio-lifepo4-100ah-48v-must/), [Emergente — inversores híbridos](https://www.emergente.com.co/categoria-producto/inversores-solares/inversores-hibridos), [Autosolar — Growatt MIN 5000TL-X](https://autosolar.co/inversores-on-grid-bifasicos/inversor-growatt-min-5000tl-x-doble-mppt), [Emergente — baterías de gel 12 V 200 Ah](https://www.emergente.com.co/producto/bateria-de-gel-12v-200ah-csbattery), [Autosolar — controlador MPPT 60 A](https://autosolar.co/controladores-de-carga-mppt/controlador-carga-mppt-60a-ml4860-122448-lcd-srne), [OPS Colombia — costo real de un sistema solar 2026](https://www.opscolombia.com/blog/cuanto-cuesta-realmente-un-sistema-solar-en-colombia), [CENS — tarifas enero 2026](https://www.cens.com.co/Portals/cens/clientes-y-usuarios/Tarifas-de-energia/T2026/Tarifas_CENS_202601_.pdf), [NASA POWER](https://power.larc.nasa.gov/).

## 2026-10-01 — Etapa 4: motor SimDeg-FV en Dart

- `HECHO` **Motor en Dart puro** (`lib/features/degradacion/domain/`, sin Flutter), portado línea por línea del código del `.nlogox` (no del Word, porque el código es la versión calibrada): `parametros.dart` (mismos valores por defecto que NetLogo), `aleatorio.dart` (generador con semilla, normal por Box–Muller), `submodelos.dart` (clima con cadena de Markov, anomalías anuales y tormentas de polvo; entorno hora a hora en grados como NetLogo; panel y polvo; reparto de energía; factores de estrés y SoH, Ec. 1–5) y `simulador.dart` (mismo orden del procedimiento `paso`: entorno → decisión de limpieza → panel → despacho → batería), con SoH año a año y una fila por día igual a la del dashboard de NetLogo.
- `HECHO` Factor de consumo (1 = perfil de NetLogo, ≈ 20 kWh/día) para ajustar la demanda al cálculo del usuario en la Etapa 6.
- `HECHO` **Validación contra NetLogo** con `tool/validar_motor.dart` (equivalente a `validar_modelo.py`), que genera `docs/VALIDACION_DART.md`:
  - Los 4 casos de `VALIDACION.md` (10 semillas) cumplen: SoH final igual a NetLogo con diferencias de 0,00 a 0,02 puntos; **mayor diferencia año a año 0,05 puntos** (criterio ±0,3); energía comprada a menos de 0,3 %; ciclos equivalentes prácticamente iguales; R² y RMSE iguales a los de NetLogo (alta: 99,93 % y 0,0012).
  - La política consciente reproduce los cambios de NetLogo: caída del SoH −7,7 % (media) y −10,6 % (alta), flujo −4,4 % y −5,4 %, energía +4,5 % y +5,8 % (NetLogo +4,3 % y +6,0 %).
  - **30 de 30** casos de `GUIA_VARIACION.md` cumplen (escenarios, política, batería, panel, tasa C, SOC mínimo y máximo, polvo, umbral de limpieza, las 5 zonas y los 4 coeficientes de degradación, incluidos los 3 casos de fin de vida).
- `HECHO` Una corrida de 10 años (87 600 horas) tarda **60–80 ms** en un PC: la Etapa 5 no necesita dividir la simulación en bloques.
- `CORREGIDO` Con 5 semillas, el caso "polvo 0,1 g/h" daba 223 limpiezas (rango de NetLogo 230–293). Un diagnóstico con 100 semillas mostró que era azar: promedio 245 (referencia: 68,3 frente a ≈ 70 de NetLogo); las semillas 1–5 tienen por casualidad pocas tormentas de polvo. La sensibilidad se valida ahora con 20 semillas.
- `DECISIÓN` Criterio de energía comprada en la sensibilidad: el mayor entre 3 % y dos errores estándar de la diferencia de medias. Con una batería de 20 kWh se compra poca energía (≈ 6 000 kWh en 10 años) y varía mucho entre corridas (± 407 kWh), así que un 3 % fijo confundía azar con error (+6,3 % frente a una tolerancia estadística de ±6,9 %). El criterio queda explicado en `VALIDACION_DART.md`.
- `HECHO` 90 pruebas pasan (27 nuevas: submodelos con valores calculados a mano, reproducibilidad por semilla, fin de vida, factor de consumo, tiempo de corrida y los 4 casos de validación contra NetLogo con el SoH año a año); `flutter analyze` sin advertencias.
