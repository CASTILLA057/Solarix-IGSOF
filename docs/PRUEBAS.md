# Pruebas de Solarix

Cómo se prueba la app y cómo correr cada tipo de prueba. Lo que se encuentre y se corrija queda en [`BITACORA.md`](BITACORA.md).

## 1. Pruebas automáticas (`flutter test`)

Corren en el computador, sin celular ni internet, con un Supabase falso. GitHub Actions las corre en cada push, junto con el formato y `flutter analyze`.

```bash
flutter test
```

| Grupo | Archivos | Qué prueba |
|---|---|---|
| Fórmulas | `test/features/calculadora/calculadora_test.dart`, `test/features/degradacion/motor_test.dart` | Consumo, dimensionamiento, costos, payback; motor SimDeg-FV contra NetLogo (Etapa 4) |
| Pantallas | `test/features/**` | Login, registro, recuperar contraseña, perfil, calculadora, simulación, inicio, historial, gráficas, errores, modo oscuro, tamaños de pantalla |
| Colores | `test/core/paleta_contraste_test.dart` | Contraste de texto (≥ 4,5:1) y de las líneas de las gráficas (≥ 3:1), en claro y oscuro |
| De principio a fin | `test/flujo_completo_test.dart` | Registro → calculadora → simulación → guardar → inicio, historial y detalle |

## 2. Pruebas de integración en el celular (`integration_test/`)

Abren la app real en el celular y la manejan solas: tocan, escriben y esperan como un usuario. Usan los mismos pasos que la prueba de principio a fin (`test/helpers/flujo_completo.dart`).

Conecta el celular por USB (con depuración USB activa, como para instalar la app) y corre los comandos de abajo.

> **Celulares Honor/Huawei:** si la app se queda en una pantalla negra con el ícono de Flutter, el celular tiene apagados los registros del sistema y Flutter no puede conectarse a la prueba. Actívalos marcando `*#*#2846579#*#*` en la app de Teléfono → Background Settings → LOG Settings → **AP Log**, y reinicia el celular.
>
> Las pruebas de integración instalan una versión de prueba encima de la app. Para volver a la app normal, córrela otra vez con "Solarix (Android)" o `flutter run`.

### a) Con Supabase falso (no necesita internet ni toca la base de datos)

```bash
flutter test integration_test/flujo_completo_test.dart
```

### b) Con el Supabase real (`solarix`)

Necesita una **cuenta de prueba** ya confirmada:

1. En la app, crea una cuenta con un correo que uses solo para pruebas y confírmala con el código que llega.
2. Copia `prueba.example.json` como `prueba.json` (está en `.gitignore`, no se sube) y escribe ese correo y su contraseña.
3. Corre:

```bash
flutter test integration_test/supabase_real_test.dart --dart-define-from-file=env.json --dart-define-from-file=prueba.json
```

La prueba inicia sesión con esa cuenta, calcula, simula y guarda con un nombre único (`Prueba de integración <número>`), revisa el inicio, el historial y la base de datos, y al final **borra lo que guardó** y cierra la sesión, aunque falle a mitad de camino. Al empezar cierra la sesión que hubiera en el celular, así que después tendrás que volver a entrar con tu cuenta. Sin `prueba.json` la prueba se omite.

El **registro** no se automatiza contra el Supabase real porque exige el código que llega al correo; queda cubierto por las pruebas automáticas (con Supabase falso) y por la prueba manual.

## 3. Prueba manual (celular Android y navegador)

Recorrer en el **celular** (`flutter run` con la configuración "Solarix (Android)") y en **Chrome** ("Solarix (Chrome)"). Marcar cada punto y anotar en la bitácora lo que falle.

| # | Paso | Resultado esperado | Android | Chrome |
|---|---|---|---|---|
| 1 | Abrir la app sin sesión | Bienvenida con el sol ámbar, "Iniciar sesión" y "Crear cuenta" | [x] | [x] |
| 2 | Crear cuenta con un correo real | Llega el correo con el código de 8 dígitos; al escribirlo entra al inicio | [x] | [x] |
| 3 | Cerrar sesión y volver a entrar | Entra al inicio; cerrar y abrir la app mantiene la sesión | [x] | [x] |
| 4 | "¿Olvidaste tu contraseña?" | Llega el código; pide el código antes de la contraseña nueva; entra con la nueva | [x] | [x] |
| 5 | Perfil: cambiar nombre, ciudad y zona; guardar | "Perfil guardado"; al volver se mantienen | [x] | [x] |
| 6 | Perfil → Apariencia: Claro, Oscuro, Sistema; cerrar y abrir la app | Cambia al instante y se recuerda | [x] | [x] |
| 7 | Calculadora: conectado a la red, con equipos y una ciudad | Resultados con paneles, costos y recuperación de la inversión | [x] | [x] |
| 8 | Calculadora: "Mi ubicación" | Pide permiso; tras unos segundos usa las HSP de NASA POWER | [x] | [x] |
| 9 | Calculadora: valores fuera de rango (p. ej. 0 paneles, HSP 20) | Mensaje de error en el campo mientras se escribe | [x] | [x] |
| 10 | Calculadora híbrida con litio → guardar → "Simular la salud de esta batería" → simular → guardar | Tarjeta "Con el sistema que dimensionaste"; simulación guardada | [x] | [x] |
| 11 | Simulación sola (desde el inicio), consciente y convencional | Consciente siempre en verde, convencional en ámbar | [x] | [x] |
| 12 | Tocar las gráficas | Valores con máximo 3 decimales y una marca del color de la línea | [x] | [x] |
| 13 | Inicio | Último cálculo y última simulación con su gráfica | [x] | [x] |
| 14 | Historial: filtros de fecha y política; "Quitar filtros"; abrir detalle; eliminar | Filtra, muestra las 3 gráficas y elimina tras confirmar | [x] | [x] |
| 15 | Sin internet (modo avión): abrir inicio e historial; intentar guardar | En máx. 5 s, aviso de sin conexión con "Reintentar"; la calculadora funciona con valores locales | [x] | [x] |
| 16 | Girar el celular / ventana angosta y ancha en Chrome | Nada se corta ni se desborda | [x] | [x] |
| 17 | Teclado del celular en los formularios | El campo activo queda visible sobre el teclado | [x] | — |
| 18 | Botón atrás del celular en cada pantalla | Vuelve a la pantalla anterior; desde el inicio sale de la app | [x] | — |
| 19 | Ícono de casa y "Volver al inicio" en los resultados, sin guardar y guardado | Sin guardar pregunta (Guardar y salir / Salir sin guardar / Cancelar); guardado va directo al inicio | [x] | [x] |
| 20 | Calculadora → "Supuestos técnicos y financieros": tocar ⓘ en varios campos; cambiar a híbrido; abrir "Incentivos de la Ley 1715", activar "Comprar sin IVA" y poner una tarifa de renta; calcular | Cada ⓘ abre su explicación con la fuente; el autoconsumo pasa de 60 a 90 % y aparece "Consumo sin sol"; en los resultados, excedente descontado de la factura y vendido a bolsa, la nota "Sin IVA" y la "Deducción de renta (año 1)" | [x] | [ ] |
