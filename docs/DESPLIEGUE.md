# Despliegue de Solarix

Cómo generar el ícono y el splash, firmar el APK de Android y (más adelante) publicar la versión web. Lo hecho queda en [`BITACORA.md`](BITACORA.md).

## 1. Ícono y pantalla de arranque (splash)

Las imágenes se dibujan con código (el sol de la paleta de la Etapa 9), así que se pueden regenerar si cambia el diseño:

```bash
flutter test tool/icono/generar_icono_test.dart
```

```bash
dart run flutter_launcher_icons
```

```bash
dart run flutter_native_splash:create
```

| Archivo | Uso |
|---|---|
| `assets/icono/icono.png` | Ícono completo (1024 × 1024, sol sobre crema `#FFFBEB`): Android antiguo y web |
| `assets/icono/icono_frente.png` | Frente del ícono adaptable de Android 8+ (fondo transparente; el fondo crema va aparte) |
| `assets/icono/sol.png` | Splash (1152 × 1152): el sol sobre crema, siempre (la app empieza en claro), también en Android 12+ |

La configuración está en `pubspec.yaml` (`flutter_launcher_icons` y `flutter_native_splash`).

## 2. APK de Android firmado

Android exige que el APK esté firmado con una llave que identifica al autor. Las actualizaciones de la app tienen que firmarse **con la misma llave**: si se pierde, no se puede actualizar una app ya instalada (habría que desinstalarla primero).

### Una sola vez: crear la llave

1. Crea una carpeta **fuera del proyecto** para la llave, por ejemplo `C:\Users\Scast\claves`.
2. En una terminal, corre (pide una contraseña y unos datos: nombre, organización, ciudad, país `CO`):

```bash
keytool -genkeypair -v -keystore C:/Users/Scast/claves/solarix.jks -keyalg RSA -keysize 2048 -validity 10000 -alias solarix
```

3. Copia `android/key.properties.example` como `android/key.properties` y escribe la ruta de la llave y las contraseñas. `key.properties` y los `.jks` están en `.gitignore`: no se suben al repositorio.
4. **Guarda una copia** de `solarix.jks` y de las contraseñas en un lugar seguro (por ejemplo, Google Drive privado o un gestor de contraseñas).

Sin `android/key.properties`, el APK de publicación se firma con la llave de depuración (sirve para probar, no para entregar) y Gradle avisa al compilar.

### Cada versión: compilar el APK

```bash
flutter build apk --release --dart-define-from-file=env.json
```

El archivo queda en `build/app/outputs/flutter-apk/app-release.apk` (≈ 56 MB; sirve para cualquier celular). Para archivos más livianos, uno por tipo de procesador (≈ 20 MB cada uno; casi todos los celulares actuales usan `arm64-v8a`):

```bash
flutter build apk --release --split-per-abi --dart-define-from-file=env.json
```

Antes de cada versión nueva, sube el número en `pubspec.yaml` (`version: 1.0.0+1` → `1.0.1+2`): el número después del `+` debe crecer para que Android acepte la actualización.

### Instalar el APK

- **En un celular conectado por USB:** `flutter install --release` o arrastrar el APK.
- **Compartido (WhatsApp, Drive):** al abrirlo, Android pide permitir "instalar apps de origen desconocido" para esa app.
- Si el celular tiene instalada la versión de desarrollo (firmada con la llave de depuración), hay que **desinstalarla primero**: Android no deja reemplazar una app por otra firmada con una llave distinta.

## 3. Versión web (en espera)

Pendiente por decisión del autor. Cuando se retome:

1. Elegir el servicio (Netlify o Firebase Hosting funcionan con repositorios privados y son gratis; GitHub Pages requiere plan de pago con repositorio privado).
2. Compilar con `flutter build web --release --dart-define-from-file=env.json` y subir `build/web`.
3. En Supabase (Authentication → URL Configuration), poner la dirección publicada como **Site URL** y agregarla a **Redirect URLs**.

La clave `SUPABASE_PUBLISHABLE_KEY` queda visible dentro de la versión web: es normal (es pública por diseño) y los datos los protegen las reglas RLS de cada tabla.

## 4. Antes de una presentación

El plan gratuito de Supabase **pausa el proyecto tras unos 7 días sin uso**. Entra a la app o al panel de Supabase unos días antes para que esté activo. Si está pausado, la app muestra "El servidor de Solarix está en pausa por inactividad".

## 5. Límites y alertas del backend (Etapa 12)

Lo que va en la base y en Auth ya está versionado y aplicado:

- **Migración `20261005000100_seguridad.sql`**:
  - Máximo 200 cálculos y 200 simulaciones por usuario.
  - Tamaño máximo de los datos guardados.
  - Una simulación solo se enlaza a cálculos propios.
- **`supabase/config.toml`**: inicios de sesión, registros y verificación de códigos, 15 por IP cada 5 minutos. Para cambiarlos, edita el archivo y ejecuta primero `npx supabase config diff --project-ref byopepmwxjdwdyhyrwch` y después `config push`.

Esto se configura a mano en los paneles, porque el CLI no lo maneja:

1. **Correos por hora** (Supabase → Authentication → Rate Limits → envío de correos). Brevo gratis permite 300 correos al día; con **12 por hora** (288 al día) no se agota.
2. **Avisos de uso de Supabase.** El plan gratuito avisa por correo a los dueños de la organización cuando el uso se acerca al límite (base de datos de 500 MB, usuarios activos y tráfico). En Organization → Settings, revisa que el correo de la organización sea uno que leas. El consumo actual está en Organization → Usage.
3. **Avisos de Brevo.** En la cuenta de Brevo, revisa que el correo de la cuenta sea uno que leas y activa las notificaciones de la cuenta (créditos o límite de envío) si el panel las ofrece. El consumo diario está en las estadísticas de correos transaccionales.

Los nombres de los menús pueden cambiar con el tiempo; lo importante es que los avisos lleguen a un correo que se revise.
