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
- `PENDIENTE` Completar la prueba manual del resto del flujo: perfil, cerrar sesión y recuperar contraseña.
