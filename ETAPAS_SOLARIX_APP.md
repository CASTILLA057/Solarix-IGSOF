# Solarix — App Flutter: etapas del proyecto

> Une en una sola app los dos proyectos: la calculadora de consumo, dimensionamiento y costos de paneles solares (Proyecto Integrador I) y el modelo de degradación de baterías de iones de litio en sistemas fotovoltaicos (Modelado y Simulación de Sistemas, SimDeg-FV). Alcance generalizado: ya no es solo para zonas rurales, sino para cualquier instalación solar residencial.

**Cómo usar este archivo:** marca cada tarea con `[x]` cuando la termines. Las etapas están pensadas para completarse en orden, aunque la 3 y la 4 se pueden avanzar en paralelo si trabajas en pareja o con tiempo dividido.

**Flujo de trabajo con git:** al terminar cada etapa se revisa, se verifica que `flutter analyze` y `flutter test` pasen, y se sube con un commit y push (`Etapa N: <resumen>`). GitHub Actions vuelve a correr el análisis y las pruebas en cada push.

**Regla de pruebas:** toda fórmula (consumo, costos, payback, degradación) se prueba en la misma etapa en que se escribe, no al final.

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

## Etapa 0 — Preparación
- [x] Definir el alcance en una frase: "Solarix: calculadora de dimensionamiento/costos de paneles solares + simulador de degradación de batería, con cuenta de usuario e historial en la nube."
- [x] Decidir si el módulo de consumo/costos se reescribe desde cero o se reutiliza algo del Proyecto Integrador I → **desde cero** (la versión anterior estaba hecha en HTML, no en Flutter; sirve como referencia de qué cálculos mostrar, no como código a portar)
- [x] Confirmar plataformas objetivo → **Android + Web**
- [x] Crear el repositorio privado `Solarix` en GitHub
- [ ] Crear el proyecto en Supabase (gratis) y guardar la URL y la `anon key` en `env.json`
- [ ] Copiar a la carpeta del proyecto (`docs/referencia/`) el modelo de NetLogo (`.nlogo`) y el HTML del Proyecto Integrador I, como fuente de las fórmulas

## Etapa 1 — Configuración del proyecto Flutter y del backend
- [ ] `flutter create` y estructura de carpetas por funcionalidad (`lib/core`, `lib/features/auth`, `lib/features/calculadora`, `lib/features/degradacion`, `lib/features/dashboard`)
- [ ] `.gitignore` de Flutter (incluyendo `env.json`) y README inicial
- [ ] Agregar dependencias: `supabase_flutter`, `flutter_riverpod`, `go_router`, `fl_chart`, `intl`
- [ ] Credenciales de Supabase con `--dart-define-from-file=env.json` y plantilla `env.example.json`
- [ ] Tema base (paleta solar, modo claro/oscuro) definido desde ya para no rehacer pantallas después
- [ ] Migración SQL inicial con las tablas `perfiles`, `calculos_consumo`, `simulaciones_degradacion`
- [ ] Row Level Security (RLS) activado desde el inicio: cada usuario solo ve sus propias filas
- [ ] Ejecutar la migración en el proyecto de Supabase (SQL Editor o Supabase CLI)
- [ ] GitHub Actions: `flutter analyze` + `flutter test` en cada push
- [ ] La app arranca en Android y Web mostrando una pantalla inicial

## Etapa 2 — Autenticación de usuarios
- [ ] Pantallas: registro, inicio de sesión, recuperar contraseña
- [ ] Integrar Supabase Auth (correo/contraseña; Google opcional más adelante)
- [ ] Persistir la sesión para que no pida login cada vez que se abre la app
- [ ] Rutas protegidas con go_router (sin sesión → login)
- [ ] Pantalla de perfil (nombre, ciudad/zona por defecto)
- [ ] Cerrar sesión

## Etapa 3 — Módulo de calculadora solar (consumo, dimensionamiento y costos)
*Evolución del proyecto de Proyecto Integrador I, ahora para cualquier zona, no solo rural.*
- [ ] Tipo de sistema: **conectado a red (on-grid), aislado (off-grid) o híbrido**; cambia el dimensionamiento de batería y el cálculo de ahorro
- [ ] Formulario de consumo: lista de electrodomésticos (potencia + horas de uso) o, alternativamente, el valor mensual de la factura
- [ ] Cálculo de energía diaria y mensual requerida (kWh)
- [ ] Recurso solar: horas solares pico (HSP) por ciudad, con las tres categorías baja/media/alta del modelo de NetLogo como valor por defecto
- [ ] Dimensionamiento del sistema: número de paneles, capacidad de batería e inversor recomendados
- [ ] Cálculo de costos: equipo (paneles + batería + inversor) + instalación, con valores editables por el usuario
- [ ] Cálculo de ahorro mensual frente a la factura actual (incluyendo venta de excedentes en on-grid), periodo de recuperación de la inversión (payback) y costo total a N años
- [ ] Pruebas unitarias de todas las fórmulas de esta etapa
- [ ] Guardar cada cálculo en Supabase (tabla `calculos_consumo`)
- [ ] Pantalla de resultados con el resumen (energía, paneles/batería recomendados, costos, payback)

## Etapa 4 — Motor SimDeg-FV en Dart puro (sin interfaz)
*Trae la lógica del modelo de NetLogo de Modelado y Simulación de Sistemas como una librería Dart independiente de Flutter, fácil de probar.*
- [ ] Modelo de datos para los parámetros de entrada: capacidad de batería, potencia del panel, tasa C máxima, SOC mínimo/máximo, política (convencional/consciente), zona climática, escenario de irradiancia, y los cuatro coeficientes de degradación (α, β, γ, δ)
- [ ] Generador de números aleatorios con semilla, para que una corrida sea reproducible
- [ ] Generador de entorno hora a hora: irradiancia (campana solar + variación estacional), temperatura, consumo de la casa (picos de mañana y noche), clima diario con cadena de Markov y las cinco zonas climáticas (mixta, muy soleada, muy nublada, lluviosa, polvorienta)
- [ ] Motor de reparto de energía por hora: panel → casa, excedente → batería, déficit → batería o red, respetando los límites de SOC y de potencia de carga/descarga
- [ ] Polvo y limpieza: acumulación de polvo por hora, lavado con lluvia, orden de limpieza del EMS al superar el umbral
- [ ] Fórmulas de degradación: energía acumulada normalizada (x), estrés por corriente eficaz (c-rms), variabilidad del SOC (sigma-soc), `Z` y `SoH = 100·e^(−Z)`
- [ ] Pruebas unitarias de cada componente (entorno, reparto, polvo, degradación)
- [ ] **Validación contra NetLogo:** correr los mismos escenarios en NetLogo y en Dart y comparar SoH final, energía comprada a la red y número de limpiezas (dentro de una tolerancia aceptable); documentar la comparación

## Etapa 5 — Simulación de degradación dentro de la app
- [ ] Formulario de parámetros con valores por defecto razonables
- [ ] Ejecución de la simulación (hasta 10 años / 87 600 horas) sin congelar la interfaz: *isolate* (`compute()`) en Android; en Web, ejecución por bloques cediendo el control al navegador, con barra de progreso
- [ ] Resultados: SoH final, energía comprada a la red, número de limpiezas, ciclos equivalentes, y comparación lado a lado de política convencional vs. consciente
- [ ] Reducir la serie horaria a una serie diaria/mensual antes de guardar (no guardar las 87 600 horas; el plan gratis tiene 500 MB)
- [ ] Guardar cada corrida en Supabase (tabla `simulaciones_degradacion`): parámetros + resultados + serie reducida

## Etapa 6 — Conectar los dos módulos
*Le da sentido a unir ambos proyectos en una sola app.*
- [ ] Pasar automáticamente la capacidad de batería y la potencia de panel dimensionadas en la Etapa 3 como valores iniciales de la simulación
- [ ] Vincular la simulación con el cálculo que la originó (llave foránea)
- [ ] Pantalla de cierre: "con el sistema que dimensionaste, así se vería la salud de tu batería en 10 años"

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
