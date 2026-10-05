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

## 2026-10-01 — Etapa 5: simulación dentro de la app

- `HECHO` **Formulario** (`simulacion_screen.dart`) con los parámetros del modelo y sus valores por defecto de NetLogo: sistema (batería, paneles, tasa C), entorno (irradiancia y zona), operación (política, SOC mínimo y máximo, años) y una sección avanzada (polvo, umbral de limpieza y coeficientes α, β, γ, δ).
- `DECISIÓN` Cada simulación corre la política elegida y la otra **con la misma semilla** (mismo clima), para que la comparación muestre solo el efecto de la política. La semilla queda guardada con los parámetros.
- `HECHO` **Ejecución** con `compute()` (isolate en Android; en web corre en el mismo hilo con indicador, porque tarda poco). El ejecutor es un provider que las pruebas reemplazan por una ejecución directa.
- `HECHO` **Resultados** (`resultados_simulacion_screen.dart`): SoH final destacado (o el año de fin de vida), pérdida por año frente a la banda de la literatura (1,3–1,7), tabla convencional vs. consciente (SoH, pérdida, energía comprada, ciclos, limpiezas) con el cambio porcentual, y SoH año a año de ambas políticas.
- `HECHO` **Guardado** en `simulaciones_degradacion`: `politica`, `parametros` (+ semilla), `resultados` (resumen + resumen de la otra política + SoH anual) y `serie` **mensual** (120 meses en 10 años). Acceso desde el inicio.
- `CORREGIDO` `Formato.leer` interpretaba "0.036" como 36 (lo tomaba como separador de miles). Un número que empieza en "0." ahora siempre es decimal; prueba agregada. No afectaba los campos de la calculadora, pero sí la tasa de polvo de este formulario.
- `HECHO` 94 pruebas pasan (nuevas: misma semilla en las dos políticas, serie mensual sin pérdida de energía, fila para Supabase y el flujo completo simular → comparar → guardar); `flutter analyze` sin advertencias; la versión web compila.
- `HECHO` Prueba manual en Chrome y Android, verificada por el autor: simular, comparar y guardar funcionan.
- `HECHO` **Etapa 5 completa.** Subida a GitHub en commits separados por tema.

## 2026-10-01 — Etapa 6: conexión de la calculadora con la simulación

- `HECHO` En los resultados de la calculadora, si el sistema lleva batería de litio, aparece **"Simular la salud de esta batería"**: abre la simulación con la capacidad de batería y la potencia de paneles dimensionadas (con plomo-ácido u on-grid no aparece, porque el modelo es de iones de litio).
- `HECHO` **Consumo ajustado** (`integracion.dart`): el factor de consumo = consumo calculado ÷ consumo del perfil de NetLogo, medido con un año de referencia del modelo para el escenario elegido (el consumo del modelo sube con la temperatura, así que cambia según el escenario).
- `DECISIÓN` **Escenario de irradiancia por cercanía**: se mide cuántas HSP produce cada escenario del modelo (alto ≈ 5, medio ≈ 3,5, bajo ≈ 0,3) y se elige el más cercano a las HSP del lugar. No se usaron los umbrales de la calculadora porque el escenario "bajo" de NetLogo (50 W/m²) es casi sin sol y daría resultados absurdos. La zona climática queda en mixta y el usuario la puede cambiar.
- `HECHO` **Vida simulada en el flujo de caja**: `calcular` acepta una vida de batería externa. La vida es el año en que el SoH baja de 80 %; si no ocurre en el horizonte simulado, se extrapola con la pérdida anual (20 puntos ÷ pérdida por año; con 1,5 %/año ≈ 13 años). Si la batería casi no se degrada, no hay reemplazo.
- `HECHO` **Pantalla de cierre**: en los resultados de la simulación, la tarjeta "Con el sistema que dimensionaste" compara vida de la batería, recuperación de la inversión, VPN y costo total con la vida típica (calculadora) y con la vida simulada.
- `HECHO` **Vínculo en Supabase**: guardar un cálculo devuelve su `id`; la simulación se guarda con `calculo_id`. Si el cálculo no se guardó, la simulación queda sin vínculo (se avisa en pantalla).
- `HECHO` 99 pruebas pasan (nuevas: escenario más cercano, consumo ajustado a 10 kWh/día, vida extrapolada y por fin de vida, reemplazo con la vida simulada y el flujo completo calculadora → simulación → guardado con `calculo_id`); `flutter analyze` sin advertencias.
- `HECHO` Prueba manual en Chrome y Android, verificada por el autor: calcular, simular la batería del cálculo y guardar vinculado funcionan.
- `HECHO` **Etapa 6 completa.** Subida a GitHub en commits separados por tema.

## 2026-10-01 — Etapa 7: dashboard e historial

- `HECHO` **Inicio como dashboard** (`inicio_screen.dart`): accesos a la calculadora y a la simulación, resumen del último cálculo (paneles, costo, recuperación) y de la última simulación con su gráfica de SoH, y enlace al historial. Se quitó el indicador "Supabase conectado" de la Etapa 0.
- `HECHO` **Gráficas** con `fl_chart` (`widgets/graficas.dart`): SoH mes a mes con la banda de referencia 80–100 % y la línea de fin de vida (80 %), con la otra política punteada; generación y consumo por mes; energía comprada a la red acumulada. La gráfica de SoH también se agregó a los resultados de la simulación.
- `HECHO` **Historial** (`historial_screen.dart`): pestañas de cálculos y simulaciones leídas de Supabase (más recientes primero), filtro por fecha (7 días, 30 días, este año) y por política, y eliminar con confirmación. Al tocar una simulación se abre su detalle con las tres gráficas a partir de la serie mensual guardada.
- `DECISIÓN` Las filas se leen con la misma estructura que escriben la calculadora y la simulación (`resultados`, `parametros`, `serie`), sin cambios en las tablas ni migraciones nuevas. Las RLS existentes ya limitan la lectura y el borrado a las filas del usuario.
- `HECHO` Al guardar un cálculo o una simulación se refresca el dashboard y el historial.
- `DECISIÓN` Las fechas se muestran con nombres de mes en español escritos en el código ("2 oct 2026"), para no tener que inicializar los datos de idioma de `intl`.
- `PENDIENTE` Exportar a PDF (tarea opcional) no se hizo.
- `HECHO` 105 pruebas pasan (nuevas: lectura de las filas de Supabase a partir de un cálculo y una simulación reales, filtros por fecha y política, dashboard con datos y vacío, e historial: filtrar, abrir el detalle y eliminar); `flutter analyze` sin advertencias; la versión web compila.
- `HECHO` Prueba manual en Chrome y Android, verificada por el autor: dashboard, gráficas, filtros, detalle y eliminar funcionan.
- `HECHO` **Etapa 7 completa** (salvo el PDF opcional, que queda pendiente por decisión del autor). Subida a GitHub en commits separados por tema.

## 2026-10-02 — Etapa 8: pulido de interfaz

- `HECHO` **Tema**: paleta solar con ámbar como color principal y azul cielo como terciario (la otra política en las gráficas); tarjetas planas con borde, botones de 48 px de alto con esquinas redondeadas, campos con fondo, avisos flotantes. Claro y oscuro salen del mismo esquema.
- `HECHO` **Modo claro/oscuro** elegible en "Mi perfil" → Apariencia (Sistema, Claro, Oscuro). Se guarda en el dispositivo con `shared_preferences` (dependencia nueva; `supabase_flutter` ya la usaba por dentro), así que se recuerda al volver a abrir la app.
- `HECHO` **Errores claros** con un traductor central (`core/errors/traducir_error.dart`) que usan todos los repositorios de Supabase:
  - Sin conexión (sin internet, servidor inalcanzable o tiempo agotado).
  - **Proyecto de Supabase pausado** (respuesta HTTP 540): "El servidor de Solarix está en pausa por inactividad…".
  - Sesión expirada (JWT vencido).
  - Cualquier otro error: "No se pudo [guardar el cálculo, cargar tus simulaciones…]. Intenta de nuevo." Antes, cualquier error desconocido se mostraba como "sin conexión".
- `DECISIÓN` Los mensajes de error pasaron de `features/auth/domain` a `core/errors/mensajes_error.dart`, porque ya los usaban todas las funciones de la app, no solo Auth.
- `PENDIENTE` La detección del proyecto pausado se probó con respuestas simuladas (código 540 y el texto "Project paused"), no con el proyecto real pausado, para no tener que pausar `solarix`.
- `CORREGIDO` El dashboard mostraba "Aún no tienes cálculos guardados" mientras cargaba o si la consulta fallaba. Ahora cada tarjeta muestra "Cargando…" o el error con un botón para reintentar.
- `HECHO` **Estados de carga, vacío y error** reutilizables (`core/widgets/estados.dart`), usados en el historial y el perfil. El historial vacío ofrece ir a la calculadora o a la simulación; si los filtros ocultan todo, ofrece "Quitar filtros".
- `CORREGIDO` La simulación mostraba el error técnico (`No se pudo simular: <excepción>`); ahora da un mensaje claro y el detalle queda en la consola de depuración.
- `HECHO` **Validación**: los campos numéricos muestran el error mientras se escribe (después del primer cambio) y los límites salen sin decimales de sobra ("Debe ser al menos 1", no "1,0"), con `Formato.corto`.
- `HECHO` **Tamaños de pantalla**: el historial ahora tiene ancho máximo en escritorio, como las demás pantallas. Una prueba recorre todas las pantallas (inicio, perfil, calculadora y resultados, simulación y resultados, historial y detalle) en un celular de 320 × 640, en un celular en modo oscuro y en un escritorio de 1440 × 900, sin desbordes.
- `HECHO` Formato de moneda (COP) y números con `intl` ya estaba en `core/formato.dart` desde la Etapa 3; se revisó que ninguna pantalla muestre números sin formato.
- `HECHO` 118 pruebas pasan (13 nuevas: traducción de errores, `Formato.corto`, modo de tema elegido y recordado, dashboard con error y reintento, historial con "Quitar filtros" y el recorrido de pantallas en tres tamaños); `flutter analyze` sin advertencias; la versión web compila.
- `CORREGIDO` Reportado por el autor en la prueba manual, en las gráficas:
  - SoH: aparecían "101" (el tope del eje, 100,5) y "78" (el mínimo) en el eje Y. fl_chart rotula también los extremos del eje; ahora solo se rotulan los múltiplos del intervalo (cada 5 puntos, o cada 10 si el SoH baja más de 30).
  - Generación y consumo: el "9" salía repetido en el eje X (el último mes, 119, también se rotulaba como año 9). Se aplica la misma regla a los años.
  - Generación y consumo usaban dos tonos marrones parecidos; ahora la generación es ámbar vivo y el consumo azul cielo.
  - Energía comprada: las etiquetas del eje Y se partían en dos líneas ("24.05" / "2"). El ancho del eje se calcula según el número más largo y las etiquetas van en una sola línea. Como en el SoH, ya no se rotula el extremo sin redondear (24.052), sino los valores redondos (5.000, 10.000…).
  - 3 pruebas nuevas de los ejes; 121 pruebas pasan.
- `CORREGIDO` Reportado por el autor: al tocar una gráfica (o pasar el mouse) el valor salía con muchos decimales. Ahora sale con máximo 3 decimales, coma decimal y la unidad (p. ej. "99,123 %", "1.250,5 kWh"), en el color de cada línea. Prueba nueva; 122 pruebas pasan.
- `CORREGIDO` Reportado por el autor: al tocar la gráfica de SoH, en algunos puntos solo aparecía el valor de una política. La otra tenía un punto por año y la principal uno por mes, así que entre años no había punto que mostrar. Ahora las dos van mes a mes: en los resultados de la simulación con la serie mensual real de la otra política, y en el historial y el inicio interpolando entre años, porque lo guardado en Supabase solo trae el SoH anual de la otra política (la serie mensual guardada es la de la política elegida). Prueba nueva.
- `HECHO` Prueba manual en Chrome y Android, verificada por el autor: tema claro/oscuro recordado, mensajes de error, estados vacíos, validación y gráficas corregidas funcionan.
- `HECHO` **Etapa 8 completa.** Subida a GitHub en commits separados por tema.

## 2026-10-03 — Corrección: aviso de "sin conexión"

- `CORREGIDO` Reportado por el autor: al desconectar el internet la pantalla se quedaba en "Cargando…" y no aparecía el mensaje de sin conexión. Las consultas a Supabase no tenían tiempo límite. Sin una red que responda, o mientras Supabase reintenta renovar la sesión, una petición puede quedar esperando minutos en vez de fallar enseguida.
- `HECHO` `ejecutarRemoto` (`core/errors/traducir_error.dart`): todas las consultas de los repositorios (Auth, perfil, guardar cálculo y simulación, historial) tienen un límite de **15 s**. Al pasar ese tiempo se muestra "No se pudo conectar con el servidor. Revisa tu conexión a internet." con el botón para reintentar.
- `HECHO` Precios y ciudades de la calculadora esperan como máximo **8 s** y luego usan los valores locales, para que la calculadora funcione sin internet.
- `HECHO` 3 pruebas nuevas (consulta colgada → sin conexión, resultado y traducción de errores, límite por defecto); 126 pruebas pasan.
- `CORREGIDO` A pedido del autor (15 s se sentía muy lento), el límite bajó a **5 s** para todas las consultas, incluidos precios y ciudades de la calculadora.
- `DECISIÓN` Registrarse, reenviar el código y recuperar la contraseña conservan **15 s**: envían un correo por SMTP (Brevo), que puede tardar varios segundos aun con buena conexión, y con 5 s podrían mostrar un falso "sin conexión" aunque el correo sí se envíe. 126 pruebas pasan.

## 2026-10-03 — Plan: nueva Etapa 9 (paleta de colores y accesibilidad)

- `DECISIÓN` El autor propuso una paleta nueva. Se acordó:
  - Primario ámbar vivo `#F59E0B` con texto carbón `#1C1917` (contraste ≈ 8:1). Se descartaron `#D97706` con texto blanco (3,8:1, no cumple AA) y `#EAB308`.
  - Verde `#059669` para la política consciente y azul `#0284C7` para el consumo, con colores fijos por política en las gráficas.
  - Fondo crema `#FFFBEB` y una versión oscura equivalente.
- `HECHO` Se agregó como **Etapa 9** del plan. Las siguientes se corrieron un número: Pruebas integrales pasa a la 10, Despliegue a la 11 y Documentación y entrega a la 12. El plan queda con 13 etapas (0–12). Las menciones a números de etapa en entradas anteriores de esta bitácora se refieren a la numeración de su momento.

## 2026-10-03 — Etapa 9: paleta de colores y accesibilidad

- `HECHO` **Paleta fija** en `app_theme.dart`. El esquema ya no sale solo de la semilla: los colores se fijan a mano en claro y en oscuro. Fondo crema `#FFFBEB` con tarjetas blancas y texto carbón `#1C1917`; en oscuro, fondo carbón `#1C1917` con tarjetas `#292524`. Verde como secundario y azul como terciario.
- `HECHO` **`ColoresSolarix`** (extensión del tema): colores con significado que cambian con el modo: solar, generación, consumo, consciente, convencional y fin de vida.
- `HECHO` **Botón principal** en ámbar vivo `#F59E0B` con texto carbón (≈ 8:1). **Botón secundario** con texto carbón (claro en oscuro), borde ámbar de 1,5 px y fondo ámbar al 8 %. El ícono del sol (inicio, bienvenida y pantallas de acceso) va en ámbar vivo.
- `DECISIÓN` El ámbar vivo **no** se usa como color de texto. Material usa el primario también en enlaces ("¿Olvidaste tu contraseña?", "Crear cuenta"), pestañas y etiquetas de campos, y `#F59E0B` sobre el crema da 2,1:1. El primario del esquema en modo claro es `#B45309` (ámbar oscuro, 4,8:1); los botones principales sí usan `#F59E0B`. En modo oscuro el `#FBBF24` sirve para todo (10:1).
- `DECISIÓN` En las gráficas del modo claro, generación y convencional usan `#D97706` en vez de `#F59E0B`: sobre las tarjetas blancas el ámbar vivo queda en 2,1:1 y `#D97706` en 3,8:1 (mínimo para elementos gráficos: 3:1).
- `HECHO` **Gráficas**:
  - Colores fijos por política: consciente siempre verde (`#059669` / `#34D399`), convencional siempre ámbar, sea la elegida (línea continua) o la comparada (punteada). `GraficaSoh` recibe ahora las políticas en vez de sus nombres.
  - Generación en ámbar, consumo en azul (`#0284C7` / `#38BDF8`) y fin de vida en rojo (`#DC2626` / `#F87171`).
  - El valor al tocar se escribe en el color del texto, con una marca (●) del color de la línea, para que se lea en cualquier modo.
- `HECHO` **Tarjetas** con sombra suave en claro, además del borde; en oscuro, el borde marca la separación.
- `HECHO` Prueba de contraste (`test/core/paleta_contraste_test.dart`) con los colores reales del tema, en claro y en oscuro: 13 pares de texto y fondo ≥ 4,5:1 (fondo, tarjetas, enlaces, botones, verde, azul, rojo y errores) y las 5 líneas de las gráficas ≥ 3:1 sobre las tarjetas. Otra prueba verifica el color fijo de cada política en la gráfica de SoH. 133 pruebas pasan; `flutter analyze` sin advertencias; la versión web compila.
- `DECISIÓN` El ícono del sol en ámbar vivo sobre el crema no cumple 3:1, pero es decorativo: siempre va junto al nombre o al título, y WCAG no exige contraste a elementos decorativos.
- `HECHO` Prueba manual en Chrome y Android, verificada por el autor: paleta, botones, tarjetas y colores de las gráficas, en claro y en oscuro.
- `HECHO` **Etapa 9 completa.** Subida a GitHub en commits separados por tema.

## 2026-10-03 — Etapa 10: pruebas integrales

- `HECHO` **Recorrido de principio a fin** compartido (`test/helpers/flujo_completo.dart`): registro con código → calculadora híbrida con litio y nombre → guardar → simular la batería del cálculo → guardar la simulación vinculada → inicio (último cálculo y última simulación) → historial (cálculo, simulación "de un cálculo") → detalle con sus tres gráficas.
  - `test/flujo_completo_test.dart`: corre en `flutter test` y en CI, en tamaño de celular (360 × 800).
  - `integration_test/flujo_completo_test.dart`: el mismo recorrido en el celular, con la app real manejándose sola. **Pasó en el Honor del autor (Android 14) en 1 min.**
- `HECHO` **Supabase falso en memoria** (`test/helpers/backend_memoria.dart`): guarda filas con las mismas columnas que las tablas y el historial las lee con los mismos `desdeFila` de producción, incluido `on delete set null` del vínculo.
- `HECHO` **Prueba con el Supabase real** (`integration_test/supabase_real_test.dart`): inicia sesión con una cuenta de prueba, hace el recorrido con un nombre único, verifica las filas en la base de datos y al final borra lo que guardó y cierra la sesión, aunque falle. Las credenciales van en `prueba.json` (en `.gitignore`, plantilla `prueba.example.json`); sin él se omite.
- `DECISIÓN` El registro no se automatiza contra el Supabase real porque exige el código del correo. Queda cubierto por la prueba con Supabase falso y por la prueba manual.
- `CORREGIDO` Encontrado por la prueba de principio a fin en tamaño de celular: los botones "Siguiente / Atrás" de la calculadora se desbordaban 0,5 px en pantallas de 360 px de ancho (franja amarilla y negra). Ahora van en un `Wrap`. La prueba de pantallas de la Etapa 8 no lo veía porque solo revisaba el primer paso del formulario.
- `CORREGIDO` En el celular, la prueba no encontraba "Guardar cálculo": en una pantalla pequeña lo que está más abajo en una lista no se construye hasta desplazarse. El recorrido ahora desplaza la lista hasta encontrar lo que busca.
- `HECHO` **Cobertura** (`flutter test --coverage`): **88,5 %** de las líneas, frente a 85,4 % al empezar la etapa. Pruebas nuevas del editor de equipos (agregar del catálogo, "Otro equipo…" con validación, editar cantidad y consumo por ciclos, cancelar, quitar: 24 % → 100 %) y de "Confirma tu correo" (reenviar código, error, correo inválido, volver al login: 66 % → 95 %). Todas las pantallas quedan ≥ 84 %. Los repositorios de Supabase quedan bajos en `flutter test` porque ahí no hay backend; los cubre la prueba con el Supabase real.
- `HECHO` Guía [`PRUEBAS.md`](PRUEBAS.md): cómo correr cada tipo de prueba y **lista de prueba manual** de 19 pasos para Android y Chrome. CI revisa también el formato de `integration_test/`.
- `HECHO` Paquete `integration_test` (de Flutter) como dependencia de desarrollo.
- `DECISIÓN` El celular Honor del autor tenía los registros del sistema apagados (`persist.log.tag = S`). Flutter los necesita para conectarse a una prueba de integración, que arranca la app en pausa: la app se quedaba en la pantalla negra con el ícono de Flutter. El autor los activó desde el menú oculto (`*#*#2846579#*#*` → Background Settings → LOG Settings → AP Log) y reinició. Queda anotado en `PRUEBAS.md`.
- `HECHO` 142 pruebas pasan; `flutter analyze` sin advertencias; la versión web compila.
- `HECHO` El autor creó la cuenta de prueba y `prueba.json`. **La prueba con el Supabase real pasó en su celular en 1 min 12 s**: inicio de sesión, cálculo y simulación vinculada guardados en `calculos_consumo` y `simulaciones_degradacion`, inicio, historial y detalle. Al final borró lo que guardó y cerró la sesión.
- `CORREGIDO` Notado por el autor al ver las pruebas: al terminar un cálculo o una simulación, para volver al inicio había que tocar la flecha atrás varias veces (resultados de la simulación → simulación → resultados del cálculo → calculadora → inicio). Ahora (`core/widgets/navegacion.dart`):
  - **Ícono de casa** ("Ir al inicio") en la barra superior de todas las pantallas internas: calculadora, resultados, simulación, resultados de la simulación, historial, detalle y perfil.
  - Botón **"Volver al inicio"** al final de los resultados del cálculo y de la simulación.
  - Si el resultado **no está guardado**, primero pregunta: "Guardar y salir", "Salir sin guardar" o "Cancelar". "Guardar y salir" solo sale si el guardado funcionó; si falla, se queda y muestra el error.
- `HECHO` El recorrido de principio a fin usa ahora "Volver al inicio" en vez de tocar atrás varias veces. 6 pruebas nuevas de navegación (cancelar, salir sin guardar, guardar y salir, ya guardado, simulación, ícono en las pantallas internas). 148 pruebas pasan; el recorrido volvió a pasar en el celular.
- `HECHO` Prueba manual de `PRUEBAS.md` en Android y Chrome, verificada por el autor, incluidos los botones para volver al inicio.
- `HECHO` **Etapa 10 completa.** Subida a GitHub en commits separados por tema.

## 2026-10-03 — Etapa 11: despliegue (Android)

- `DECISIÓN` El autor dejó **en espera la publicación web** y, con ella, la configuración de URLs de Auth en Supabase, que depende de la dirección publicada. Solo **APK**: sin AAB para Google Play.
- `HECHO` **Ícono** diseñado con código (`tool/icono/generar_icono_test.dart`): un sol ámbar `#F59E0B` de 12 rayos con el núcleo en degradado, sobre crema `#FFFBEB`. Se ajustó a rayos del mismo largo porque alternar largos y cortos lo hacía ver desequilibrado. Genera `assets/icono/icono.png` (completo), `icono_frente.png` (frente del ícono adaptable de Android 8+, dentro de la zona segura) y `sol.png` (splash).
- `HECHO` `flutter_launcher_icons` genera los íconos de Android (incluido el adaptable con fondo crema) y de la web; `flutter_native_splash` genera el splash: el sol sobre crema, también con el formato de Android 12+ (al principio tenía versión carbón para el modo oscuro; ver la corrección más abajo). Ambos son dependencias de desarrollo.
- `CORREGIDO` El nombre visible era "solarix" en minúscula (Android, pestaña y manifiesto web); ahora es "Solarix". Se corrigieron las tildes de la descripción web ("degradación de baterías").
- `HECHO` **Firma del APK**: `android/app/build.gradle.kts` lee la llave desde `android/key.properties` (en `.gitignore`, igual que los `.jks`; plantilla `android/key.properties.example`). Sin ese archivo, el APK de publicación se firma con la llave de depuración y Gradle lo avisa. Probado: `flutter build apk --release` compila (55,9 MB, universal).
- `HECHO` Guía [`DESPLIEGUE.md`](DESPLIEGUE.md): regenerar ícono y splash, crear la llave con `keytool` (fuera del proyecto, con copia de respaldo), compilar e instalar el APK, versión web en espera y aviso de pausa de Supabase antes de presentar.
- `HECHO` 148 pruebas pasan; `flutter analyze` sin advertencias.
- `CORREGIDO` Notado por el autor: la app siempre arrancaba en oscuro. Empezaba en el modo "Sistema" (copia el del celular, que estaba en oscuro). Ahora, mientras el usuario no elija, **empieza en claro**; en Perfil → Apariencia puede elegir Oscuro o Sistema y se recuerda.
- `DECISIÓN` El splash queda **siempre crema**, para no mostrar un arranque carbón seguido de la app en claro. Si el usuario elige Oscuro, el splash sigue crema por un instante: es nativo de Android y no puede leer la preferencia guardada en la app.
- `HECHO` El autor creó la llave (`C:/Users/Scast/claves/solarix.jks`, alias `solarix`, fuera del proyecto) y `android/key.properties`; se verificó que git lo ignora y que las contraseñas no son las de ejemplo, sin mostrarlas. Al principio `keytool` falló porque la carpeta `claves` no existía; se creó y se repitió.
- `HECHO` **APK firmado**: `flutter build apk --release` (55,8 MB). `apksigner verify --print-certs` confirma el certificado propio (CN=Santiago Castilla, OU=Ufpso, O=Solarix, L=Ocana, ST=Norte de Santander, C=CO), no el de depuración.
- `HECHO` El autor desinstaló la versión de desarrollo y se instaló el APK firmado por USB (`adb install`). Prueba manual verificada por el autor: ícono, nombre, splash, arranque en claro y la app completa funcionan.
- `HECHO` **Etapa 11 completa para Android.** La publicación web y las URLs de Auth en Supabase quedan **en espera** por decisión del autor. Subida a GitHub en commits separados por tema.

## 2026-10-04 — Etapa 12: arreglos (plan)

- `HECHO` Revisión crítica del proyecto entero en dos rondas (abogado del diablo): la primera sobre los números, la integración y la sustentación; la segunda sobre el backend y la protección de datos.
- `DECISIÓN` Los hallazgos se agregan como **Etapa 12 — Arreglos**. "Documentación y entrega" pasa a ser la **Etapa 13**, para no renumerar el despliegue, que ya tiene commits y bitácora como Etapa 11.
- `DECISIÓN` La más grave: la vida simulada de la batería no tiene envejecimiento calendario y, con la extrapolación lineal y el horizonte de 20 años, casi nunca genera reemplazo, así que la comparación "antes/después" siempre favorece a la simulación. Se corrige con un tope calendario.
- `HECHO` La Etapa 13 suma tres tareas para la sustentación: diapositiva de límites del modelo, hoja de fórmulas con el origen de cada constante y ensayo de la demo 24 horas antes.

## 2026-10-05 — Etapa 12 (arreglos): integración batería ↔ flujo de caja

Primer bloque de la Etapa 12, el más grave de la revisión crítica.

- `CORREGIDO` **El ahorro no bajaba aunque la batería se degradara.** La simulación solo le pasaba al flujo de caja la vida de la batería, que movía el año del reemplazo. La calculadora suponía que la casa aprovechaba siempre el 90 % de la generación (híbrido), aunque la batería ya almacenara menos. Ahora:
  - La simulación registra cada año la energía que paneles y batería entregan a la casa (consumo menos lo comprado a la red).
  - Cada simulación corre además una **referencia**: batería convencional que no se degrada (escala de degradación 0), con el mismo clima. El **aporte** de la batería es la energía de cada política dividida entre la de la referencia, año a año. Así se aísla el efecto de la degradación y de la política del de un año más o menos soleado.
  - El ahorro de cada año usa el aporte según la edad de la batería, que vuelve a 1 con cada reemplazo. Lo que la batería deja de guardar se vende a la red con el factor de excedente; sin red, se pierde. Más allá de los años simulados, el aporte sigue la tendencia lineal de los años simulados y nunca sube.
  - `DECISIÓN` Se toma de la calculadora la escala (HSP del lugar, consumo, generación) y de la simulación solo cuánto cae el aporte, para no arrastrar la diferencia entre las HSP del lugar y el escenario del modelo.
- `CORREGIDO` **La política consciente no pagaba su costo en energía.** No carga por encima de 95 %, así que aporta ≈ 4 % menos desde el primer año, a cambio de degradarse más despacio. Antes solo contaba la ventaja (vida más larga). En la casa de prueba (300 kWh/mes, 5 HSP), contar solo la vida hacía ver la consciente como la mejor inversión (VPN $23,13 M frente a $23,01 M) y sobrestimaba el VPN de ambas en ≈ $600.000. Con el aporte, la ventaja se reduce o se invierte según el caso.
- `HECHO` **Tope calendario**: la vida que usa el flujo de caja es la menor entre la vida por uso (simulación) y la **vida calendario**, porque el modelo no incluye el envejecimiento calendario. Es de 15 años para LiFePO₄ (6 para plomo-ácido), editable en "Supuestos técnicos y financieros" de la calculadora cuando la batería es de litio, y se guarda en `entradas.supuestos.vida_calendario_bateria`.
- `HECHO` **Extrapolación de la vida revisada**: en vez de una recta sobre el SoH, se ajusta la forma del propio modelo, `SoH = 100·e^(−Z)` con `Z = a·tᵇ` (mínimos cuadrados en escala log-log sobre los años simulados, `b` acotado entre 0,3 y 2; con un solo año se usa el exponente del modelo). Hallazgo: en el rango de la app el SoH simulado baja casi en línea recta, así que la curva da prácticamente lo mismo que la recta (13,5 y 14,9 años en la casa de prueba). La recta era una buena aproximación, pero ahora el método queda justificado. Una prueba con una curva conocida verifica que, cuando la degradación se acelera, la recta se pasa y la curva no.
- `DECISIÓN` En la casa de prueba la vida por uso (13,5 y 14,9 años) queda por debajo del tope de 15, así que limita el uso. Con menos sol o menos consumo la vida por uso se alarga y manda el calendario; con una vida calendario de 6 años, una prueba verifica reemplazos en los años 6, 12 y 18.
- `HECHO` **Valor residual lineal**: el último año del horizonte se suma como ingreso la parte de la batería en uso que no se alcanzó a usar (costo × años que le quedan / vida). Aplica también a la calculadora y a la batería original si dura más que el horizonte; con la vida típica (10 años en 20) da 0, así que los cálculos de siempre no cambian. Se guarda en `resultados.flujo[].valor_residual`.
- `HECHO` **Tarjeta "Con el sistema que dimensionaste"** (`impacto_financiero.dart`): columnas Calculadora | Convencional | Consciente con vida por uso, vida calendario, vida que se usa (* si limita el calendario), ahorro y costo total neto en el horizonte, recuperación de la inversión y VPN, y una frase con la política que conviene en plata. Los pesos van abreviados ("$ 22,4 M", `Formato.copCorto`) para que quepa en un celular.
- `HECHO` **El resultado se guarda**: con cálculo de origen, la simulación guarda su impacto en `resultados.financiero` (jsonb ya existente, sin migración) y el detalle del historial muestra la misma tarjeta. Las simulaciones guardadas antes no la tienen.
- `CORREGIDO` La fila "Costo total" incluía la inversión inicial aunque la tarjeta vieja no lo decía; ahora se llama "Costo total (neto)" y la nota lo explica.
- `HECHO` Pruebas nuevas: aporte año a año y referencia sin degradación, tendencia más allá de lo simulado, ahorro que baja y se recupera con el reemplazo, sin efecto en sistemas sin batería, impacto contra "solo la vida", guardado y lectura, extrapolación con curva conocida, tope calendario (corta y larga), valor residual (lineal, solo el último año, 0 si termina justo), la tarjeta en el recorrido de principio a fin y en pantallas de 320 px. 158 pruebas pasan; `flutter analyze` sin advertencias; la versión web compila.
- `HECHO` Revisión en el celular del autor (APK firmado instalado encima, conservando la sesión; manejado por `adb` con capturas): campo de vida calendario, tarjeta de tres columnas, guardado en el Supabase real y lectura en el detalle del historial. Con vida calendario de 6 años, "Vida que se usa" pasa a 6,0 años \* en ambas políticas, el costo total sube de $7,7 M a $9,5 M y la conclusión cambia a la convencional, porque con la misma vida la consciente solo paga su costo en energía.
- `CORREGIDO` Encontrado en esa revisión: en un celular de 360 px los encabezados de las tablas se partían a mitad de palabra ("Calculador / a", "Convencio / nal"), también en la tabla vieja "Convencional frente a consciente". Las pruebas de desborde no lo veían porque no es un desborde. Ahora `EncabezadoTabla` reduce la letra en vez de partir la palabra y deja una separación mínima entre columnas.
- `CORREGIDO` La ayuda del campo "Vida calendario de la batería" se cortaba con "…" (solo caben 2 líneas); se acortó.
- `HECHO` El autor aprobó el bloque y pidió subirlo. Quedaron en su cuenta dos cálculos y una simulación de prueba ("Prueba Etapa 12…"), que puede borrar desde el historial.

## 2026-10-05 — Etapa 12: clima por ciudad (plan)

- `DECISIÓN` El autor notó que la simulación pide por separado la irradiancia (baja, media o alta) y la zona climática (mixta, muy soleada…) y propuso calcular la irradiancia a partir de la zona. Se descartó: el escenario fija la irradiancia máxima de un día despejado y la temperatura media, y la zona solo multiplica la frecuencia de lluvia, nubes y polvo, así que una no se deduce de la otra (Quibdó, lluviosa y caliente, y Bogotá, nublada y fría, quedarían con la misma temperatura). Las dos se sacan de la ciudad.
- `DECISIÓN` **NetLogo no se modifica.** Cambiarlo dejaría desactualizados `GUIA_VARIACION.md`, `VALIDACION.md`, el informe y `VALIDACION_DART.md`, y obligaría a repetir los experimentos y la calibración. Solo cambian las entradas de la app (`integracion.dart`, tabla de ciudades y pantallas); las ecuaciones de `submodelos.dart` y `simulador.dart` quedan iguales.
- `HECHO` El bloque "Coherencia entre cálculo y simulación" de la Etapa 12 pasa de 2 a 8 tareas: criterio medible de zona por ciudad, tabla con HSP, temperatura y zona, irradiancia ajustada por ciudad con tope físico (≈ 1 100 W/m²), temperatura desde la ciudad, selector de ciudad en la simulación, escenarios de NetLogo intactos en "Avanzado", prueba que recorra todas las ciudades (±5 % de HSP) y validación contra NetLogo sin cambios.
- `HECHO` La diapositiva de límites del modelo (Etapa 13) también aclara que las configuraciones por ciudad son interpolaciones que no se validaron una por una.

## 2026-10-05 — Etapa 12: economía de la calculadora

- `CORREGIDO` **Excedentes por tramos según la CREG 174 de 2021** (AGPE ≤ 100 kW, liquidación por periodo de facturación, arts. 23 y 25). Antes todo el excedente valía el 70 % de la tarifa. Ahora, cada mes, el excedente hasta lo que la casa importa de la red se permuta y vale la tarifa menos el costo de comercialización (Cv); lo que pase de ahí se paga a precio de bolsa. Nueva función pura `valorEnergiaMes`; el ahorro con batería degradada (bloque anterior) también la usa: lo que la batería deja de guardar pasa a ser excedente y la casa lo importa.
- `DECISIÓN` Valores por defecto, editables: **Cv = $100/kWh** (en 2026, EMCALI publicó $67,9/kWh y EPM $121,05/kWh) y **precio de bolsa = $300/kWh** (en 2026 el promedio mensual de XM fue de $120/kWh en febrero a $946,6/kWh en agosto, por El Niño). `Supuestos.factorExcedente` se elimina.
- `HECHO` **Incentivos de la Ley 1715 de 2014** (modificada por la Ley 2099 de 2021), apagados por defecto porque necesitan el certificado de la UPME:
  - Exclusión de IVA (19 %) en equipos y servicios: como los precios de referencia son de tienda, con IVA, se descuenta de toda la inversión (y de los reemplazos de batería). `Costos.ivaExcluido` guarda cuánto se ahorra.
  - Deducción de renta: 50 % de la inversión por la tarifa marginal de renta del usuario (0 si no declara). Se toma completa el **primer año** (supone que la renta líquida alcanza; la ley permite repartirla en 15 años sin pasar del 50 % de la renta líquida). Entra al flujo como `beneficioTributario` y baja el costo neto de la comparación con la simulación.
- `HECHO` **Supuestos explicados en la app**: ícono ⓘ en cada campo (nuevo `BotonExplicacion` en `CampoNumero`) con qué es, de dónde sale el valor y cuándo cambiarlo (`explicaciones.dart`). El autoconsumo (60 % red, 90 % híbrido) y el consumo sin sol (50 %, híbrido) ahora se pueden editar; el autoconsumo sigue al tipo de sistema mientras el usuario no lo escriba. Los resultados explican el margen del 25 % del inversor y del controlador (NTC 2050, sección 690, para el controlador).
- `HECHO` Resultados: excedente que se descuenta de la factura, excedente vendido a bolsa, nota del IVA excluido y deducción de renta del año 1.
- `HECHO` Pruebas nuevas: tramos de la CREG (permuta parcial, todo a bolsa, todo permutado, Cv mayor que la tarifa), cálculo completo con los nuevos valores, IVA, deducción de renta (solo el año 1), guardado de los campos nuevos, y en pantalla: explicación del precio de bolsa, incentivos que llegan al cálculo guardado y autoconsumo que sigue al tipo de sistema salvo que se edite. 167 pruebas pasan; `flutter analyze` sin advertencias.
- `HECHO` Prueba manual en Android (`PRUEBAS.md`, paso 20), con el APK firmado instalado encima conservando la sesión: verificada por el autor. Falta repetirla en Chrome.

## 2026-10-05 — Etapa 12 (arreglos): coherencia entre cálculo y simulación (clima por ciudad)

- `CORREGIDO` **Todas las ciudades se simulaban con el mismo sol y la misma temperatura.** La simulación desde un cálculo elegía el escenario de NetLogo más cercano a las HSP del lugar con la zona siempre mixta, y las 28 ciudades caían en el escenario alto (≈ 4,6 HSP y 27 °C): Santa Marta (5,7 HSP) se simulaba con ≈ 19 % menos sol, Pasto (4,0) con ≈ 15 % más, y Bogotá y Tunja con 27 °C.
- `DECISIÓN` Como dice el plan, NetLogo y sus ecuaciones no cambian: solo las **entradas**. Con el visto bueno del autor, `simulador.dart` cambia 2 líneas, que leen la irradiancia máxima y la temperatura media de los parámetros (`p.irradianciaMaxima`, `p.temperaturaMedia`) en vez del escenario fijo. Por defecto valen lo mismo que el escenario. Se descartó un primer intento que multiplicaba la generación dentro del simulador.
- `HECHO` **`dart run tool/validar_motor.dart` da los mismos resultados**: los números de `VALIDACION_DART.md` son idénticos; solo cambian la fecha y el tiempo de una corrida (62 ms frente a 63 ms). El archivo se dejó como estaba. Las 27 pruebas del motor también pasan.
- `HECHO` **Clima de cada ciudad** de NASA POWER, la misma fuente de las HSP, consultado el 2026-10-05 en las mismas coordenadas (las HSP de la consulta coinciden con las del catálogo en las 28): lluvia (`PRECTOTCORR`), nubosidad (`CLOUD_AMT`) y temperatura a 2 m (`T2M`). Va en `catalogos.dart` (`climaDeCiudad`) y no en la tabla `ciudades`, para no cambiar la base de datos.
- `CORREGIDO` **La temperatura de NASA se corrige por altitud.** La celda de ≈ 50 km promedia valle y montaña: sin corregir, Cali daba 16,3 °C, Neiva 20,3, Villavicencio 19,0 y Bogotá 18,8. Corrección: `T = T2M + 0,0065 · (altitud de la celda − altitud de la ciudad)`, con 6,5 °C por cada 1.000 m. NASA devuelve la altitud de su celda. Queda Cali 23,5, Neiva 26,5, Villavicencio 25,0 y Bogotá 13,3 °C, cerca de los valores conocidos. Altitudes aproximadas de las cabeceras: Arauca 125 m, Armenia 1.480 m, Barranquilla 18 m, Bogotá 2.640 m, Bucaramanga 960 m, Cali 1.000 m, Cartagena 2 m, Cúcuta 320 m, Florencia 242 m, Ibagué 1.285 m, Leticia 96 m, Manizales 2.150 m, Medellín 1.495 m, Montería 18 m, Neiva 442 m, Ocaña 1.202 m, Pasto 2.527 m, Pereira 1.411 m, Popayán 1.737 m, Quibdó 43 m, Riohacha 5 m, San Andrés 5 m, Santa Marta 6 m, Sincelejo 213 m, Tunja 2.782 m, Valledupar 169 m, Villavicencio 467 m, Yopal 350 m. En "Mi ubicación" se usa la altitud del GPS cuando el celular la entrega; si no, la de NASA sin corregir.
- `DECISIÓN` **Criterio de la zona** (`zonaParaClima`), según cuánto llueve en cada zona del modelo (≈ 18 días de lluvia al año en la muy soleada, 38 en la polvorienta, 98 en la mixta, 169 en la muy nublada y 255 en la lluviosa), en este orden:
  1. Lluviosa: 2.500 mm/año o más.
  2. Polvorienta: seca (menos de 1.000 mm/año) y despejada (nubosidad menor al 60 %).
  3. Muy soleada: despejada.
  4. Muy nublada: 1.600 mm/año o más, o nubosidad del 80 % o más.
  5. Mixta: el resto.

  Sin datos del clima (HSP escritas a mano), mixta. Los umbrales se fijaron con las zonas del modelo y mirando cómo se reparten las 28 ciudades; no se ajustaron ciudad por ciudad.
- `HECHO` **Irradiancia máxima por ciudad**: la que hace que el modelo, en la zona de la ciudad, produzca sus HSP reales. La irradiancia del modelo es proporcional a la máxima y el azar del clima no depende de ella, así que basta una proporción: `800 W/m² × HSP de la ciudad / HSP del escenario alto en esa zona`. No hace falta buscar con 6–8 corridas. La forma del día, la lluvia, las nubes y el polvo son los del escenario alto con la zona de la ciudad. Tope físico de 1.100 W/m²: ninguna ciudad llega (todas entre 688 y 989).
- `HECHO` Tabla de ciudades (HSP, lluvia en mm/año, nubosidad en %, temperatura corregida en °C, zona e irradiancia máxima en W/m²):

  | Ciudad | HSP | Lluvia | Nubes | Temp. | Zona | Irradiancia |
  |---|---|---|---|---|---|---|
  | Arauca | 5,0 | 1.515 | 67 | 27,5 | mixta | 860 |
  | Armenia | 4,5 | 1.632 | 82 | 20,2 | muyNublada | 883 |
  | Barranquilla | 5,4 | 1.124 | 57 | 27,9 | muySoleada | 803 |
  | Bogotá | 4,6 | 1.624 | 78 | 13,3 | muyNublada | 902 |
  | Bucaramanga | 5,1 | 1.245 | 72 | 24,3 | mixta | 877 |
  | Cali | 4,2 | 1.022 | 84 | 23,5 | muyNublada | 824 |
  | Cartagena | 5,3 | 1.369 | 65 | 28,2 | mixta | 912 |
  | Cúcuta | 4,3 | 909 | 79 | 28,4 | mixta | 740 |
  | Florencia | 4,4 | 1.427 | 81 | 26,0 | muyNublada | 863 |
  | Ibagué | 4,5 | 1.504 | 82 | 21,9 | muyNublada | 883 |
  | Leticia | 4,6 | 2.555 | 80 | 25,8 | lluviosa | 989 |
  | Manizales | 4,8 | 1.986 | 81 | 16,0 | muyNublada | 942 |
  | Medellín | 4,9 | 2.270 | 79 | 20,0 | muyNublada | 961 |
  | Montería | 5,0 | 1.369 | 68 | 28,0 | mixta | 860 |
  | Neiva | 4,2 | 1.314 | 82 | 26,5 | muyNublada | 824 |
  | Ocaña | 5,0 | 1.011 | 71 | 22,1 | mixta | 860 |
  | Pasto | 4,0 | 1.037 | 79 | 13,3 | mixta | 688 |
  | Pereira | 4,5 | 1.986 | 82 | 20,8 | muyNublada | 883 |
  | Popayán | 4,1 | 971 | 82 | 18,3 | muyNublada | 804 |
  | Quibdó | 4,0 | 4.406 | 89 | 25,7 | lluviosa | 860 |
  | Riohacha | 5,5 | 931 | 57 | 27,8 | polvorienta | 891 |
  | San Andrés | 5,3 | 1.533 | 62 | 27,7 | mixta | 912 |
  | Santa Marta | 5,7 | 847 | 55 | 28,8 | polvorienta | 923 |
  | Sincelejo | 5,1 | 1.431 | 68 | 27,0 | mixta | 877 |
  | Tunja | 4,5 | 1.785 | 78 | 11,6 | muyNublada | 883 |
  | Valledupar | 5,3 | 719 | 66 | 28,4 | mixta | 912 |
  | Villavicencio | 4,3 | 2.435 | 83 | 25,0 | muyNublada | 843 |
  | Yopal | 4,5 | 1.964 | 74 | 26,4 | muyNublada | 883 |

- `DECISIÓN` Las HSP del modelo se miden con **10 años** de referencia (lo que se simula) y no con 1 o 3: el modelo varía la lluvia de un año a otro entre × 0,6 y × 1,6, y con 3 años una ciudad quedaba a 7,6 % de sus HSP medida con otra semilla.
- `HECHO` **Pantalla de simulación**: sección "Entorno" con selector de **Lugar** ("Lugar del cálculo" o una de las 28 ciudades; sin cálculo, la ciudad del perfil si está en la lista, o Ocaña) y el resumen de lo que se simula (zona, irradiancia máxima, temperatura y HSP). La irradiancia y la zona de NetLogo pasan a **"Avanzado: configuración de NetLogo"**, con un interruptor que usa los escenarios originales sin cambios. Allí no se pueden elegir combinaciones imposibles: con irradiancia baja (casi sin sol) no hay zona muy soleada ni polvorienta.
- `HECHO` El cálculo guarda el clima del lugar (`entradas.clima`); "Mi ubicación" lo trae en la misma consulta a NASA. La simulación guarda `irradiancia_maxima_lugar` y `temperatura_media_lugar` en `parametros`, y los resultados y el historial describen el entorno ("irradiancia máxima 860 W/m² · 22,1 °C · zona mixta" o "irradiancia alta (NetLogo) · zona mixta"). Los cálculos y simulaciones viejos se leen igual.
- `PENDIENTE` Limitaciones: la celda de NASA de ≈ 50 km también afecta la lluvia y la nubosidad en las montañas (Pasto, con 79,4 % de nubosidad, queda como mixta aunque es nublada). Las configuraciones por ciudad son interpolaciones de las entradas que no se validaron una por una contra NetLogo, como ya dice la diapositiva de límites (Etapa 13).
- `HECHO` Pruebas nuevas:
  - Reglas de la zona y sus límites.
  - Clima, temperatura y zona de las ciudades.
  - La zona cambia el sol del modelo.
  - **Todas las ciudades sin llegar al tope y a ±5 % de sus HSP**, medido con otra semilla en 10 años.
  - El entorno del lugar solo cambia entradas, y la configuración de NetLogo queda intacta.
  - Del cálculo: consumo ajustado a la temperatura del lugar (≈ 10 kWh/día).
  - Lectura de NASA con lluvia, nubosidad, temperatura y corrección por altitud.
  - En pantalla: sin datos del clima con HSP a mano, y la zona muy soleada al elegir Barranquilla en la calculadora.

  175 pruebas pasan; `flutter analyze` sin advertencias; la versión web compila.
- `HECHO` Revisión en el celular del autor (APK firmado instalado encima; manejado por `adb` con capturas):
  - Calculadora con Riohacha → simulación: "Lugar del cálculo", zona polvorienta, 891 W/m², 27,8 °C y 5,5 HSP.
  - Cambio de lugar a Bogotá: zona muy nublada, 902 W/m², 13,3 °C y 4,6 HSP.
  - "Avanzado": con NetLogo y irradiancia baja, la zona solo ofrece mixta, muy nublada y lluviosa, y el resumen dice "Configuración original de NetLogo".
  - Simulación de Bogotá: los resultados y el detalle del historial (Supabase real) dicen "irradiancia máxima 902 W/m² · 13,3 °C · zona muy nublada". Con el frío de Bogotá, en la política consciente limita la vida calendario.
- `CORREGIDO` Encontrado en esa revisión: en el selector de lugar, "Lugar del cálculo · 5,5" no dejaba ver "HSP" en un celular de 360 px. Ahora dice "Del cálculo · 5,5 HSP", y cualquier opción que no quepa termina en "…".
- `HECHO` El autor aprobó el bloque y pidió subirlo. Quedaron en su cuenta un cálculo "Prueba clima Riohacha" y una simulación de Bogotá de prueba.

## 2026-10-05 — Etapa 12 (arreglos): que la demo no dependa de servicios gratuitos

- `HECHO` **"Probar sin cuenta"**: la bienvenida tiene un tercer botón que entra en modo invitado (`modoInvitadoProvider`).
  - La calculadora y la simulación funcionan completas sin sesión; el perfil y el historial siguen pidiendo cuenta (`Rutas.paraInvitados`; `redirigir` recibe `invitado`).
  - El inicio sin sesión no consulta el historial: muestra "Estás probando Solarix sin cuenta" con "Crear cuenta" e "Iniciar sesión".
  - En los resultados, en vez de "Guardar" aparece "Crea una cuenta para guardar", y "Volver al inicio" no pregunta, porque no hay nada que guardar.
  - Al iniciar sesión, el modo invitado se apaga solo.
- `DECISIÓN` **Precios y ciudades solo en Dart** (`Precios.referencia`, `ciudadesBase`): la app ya no lee las tablas `precios_referencia` y `ciudades`. Funciona igual sin internet, sin sesión o con Supabase pausado (antes, sin sesión, la RLS devolvía las tablas vacías y la app caía en el respaldo de Dart). Cambiar un precio o una ciudad requiere una versión nueva de la app. Se quitaron `obtenerPrecios`, `obtenerCiudades`, `preciosProvider`, `ciudadesProvider` y las pruebas que comparaban la migración con Dart. En Supabase no se tocó nada: las tablas quedan sin uso y se pueden quitar en el bloque de seguridad, con el visto bueno del autor.
- `HECHO` **Remitente de los correos**: el autor creó una cuenta con un correo de Hotmail y el código llegó a la bandeja de entrada, no a spam. Se deja el remitente actual.
- `DECISIÓN` **Cuenta de demo**: la cuenta de prueba de la Etapa 10 (credenciales en `prueba.json`, fuera de git), ya verificada. Por decisión del autor arranca vacía.
- `HECHO` El autor probó el modo invitado en el celular.
- `HECHO` Pruebas nuevas: rutas sin cuenta (lo permitido, lo que sigue pidiendo sesión y que sin elegir "Probar sin cuenta" todo pide sesión) y el recorrido sin cuenta: calcular, simular, no guardar, volver sin preguntar y el historial pidiendo cuenta. 177 pruebas pasan; `flutter analyze` sin advertencias; la versión web compila.
- `HECHO` El autor subió la copia de `solarix.jks` y `key.properties` a su Google Drive privado.
- `HECHO` **Bloque completo.** Subido a GitHub en commits separados por tema.
