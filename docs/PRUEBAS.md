# Pruebas de Solarix

Cómo se prueba la app y cómo correr cada tipo de prueba. Lo que se encuentre y se corrija queda en [`BITACORA.md`](BITACORA.md).

## 1. Pruebas automáticas (`flutter test`)

Corren en el computador, sin celular ni internet, con un Supabase falso. GitHub Actions las corre en cada push, junto con el formato y `flutter analyze`.

```bash
flutter test
```

| Grupo | Archivos | Qué prueba |
|---|---|---|
| Fórmulas | `test/features/calculadora/calculadora_test.dart`, `test/features/degradacion/motor_test.dart`, `test/features/degradacion/integracion_test.dart` | Consumo, dimensionamiento, costos, payback, excedentes (CREG 174) e incentivos (Ley 1715); motor SimDeg-FV contra NetLogo (Etapa 4); vida de la batería, ahorro con la degradación y clima por ciudad (Etapa 12) |
| Pantallas | `test/features/**` | Login, registro, recuperar contraseña, perfil, calculadora, simulación, inicio, historial, gráficas, errores, modo oscuro, tamaños de pantalla, modo sin cuenta, política de datos y "Eliminar mi cuenta", "Avanzado" de NetLogo |
| Límites de la base | `test/core/limites_backend_test.dart` | Lo más grande que guarda la app cabe en los límites de la migración de seguridad; mensajes del tope de 200 y de datos demasiado grandes |
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
| 5 | Perfil: cambiar el nombre y elegir la ciudad de la lista; guardar | "Perfil guardado"; al volver se mantienen | [x] | [x] |
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
| 20 | Calculadora → "Supuestos técnicos y financieros": tocar ⓘ en varios campos; cambiar a híbrido; abrir "Incentivos de la Ley 1715", activar "Comprar sin IVA" y poner una tarifa de renta; calcular | Cada ⓘ abre su explicación con la fuente; el autoconsumo pasa de 60 a 90 % y aparece "Consumo sin sol"; en los resultados, excedente descontado de la factura y vendido a bolsa, la nota "Sin IVA" y la "Deducción de renta (año 1)" | [x] | [x] |
| 21 | Bienvenida → "Probar sin cuenta": calcular, simular y tratar de guardar | Todo funciona sin sesión; en vez de guardar dice "Crea una cuenta para guardar"; el perfil y el historial piden cuenta | [x] | [x] |
| 22 | Registro sin marcar la casilla de autorización; "Leer la política de tratamiento de datos" | "Debes autorizar el tratamiento de tus datos para crear la cuenta"; la política se abre y "atrás" vuelve al registro | [x] | [x] |
| 23 | Perfil → "Eliminar mi cuenta" con una cuenta de prueba | El botón se activa solo al escribir ELIMINAR; borra todo y vuelve a la bienvenida | [x] | — |
| 24 | Perfil: elegir una ciudad; abrir la calculadora y la simulación sin cálculo | Las dos arrancan en esa ciudad | [x] | [x] |
| 25 | Simulación: cambiar "Lugar"; en "Avanzado", usar un escenario de NetLogo con irradiancia baja | El resumen cambia con la ciudad; con NetLogo el lugar se bloquea y la zona no ofrece "Muy soleada" ni "Polvorienta" | [x] | [x] |
| 26 | Calculadora híbrida → guardar → simular → guardar → historial → detalle | Tabla Calculadora / Convencional / Consciente en los resultados y en el detalle del historial | [x] | [x] |
| 27 | Calculadora híbrida → calcular; ver "¿Y sin batería?" | Inversión, ahorro, recuperación y VPN sin batería; "La batería resta $X al VPN… su valor está en cubrir los cortes"; en un sistema conectado a la red la tarjeta no aparece | [x] | [ ] |
| 28 | Calculadora aislada con litio → "Simular la salud de esta batería" → simular → guardar → detalle en el historial | En los resultados y en el detalle dice "Energía que faltó" (no "comprada a la red"), con la nota de cortes, planta o combustible; en un híbrido sigue diciendo "Energía comprada a la red" | [ ] | [ ] |
| 29 | Calculadora conectada a la red con una ciudad de más de 1.000 m (por ejemplo, Bogotá): elegir estrato 2, luego estrato 5; tocar ⓘ de la tarifa, del estrato y del consumo de subsistencia | Con estrato 2 aparece "Consumo de subsistencia"; en los resultados, "Estrato 2 · subsidio hasta 50 % en los primeros 130 kWh/mes", la factura estimada y una recuperación más larga que con estrato 4; con estrato 5, "contribución de 20 %" y recuperación más corta | [x] | [ ] |
| 30 | Calculadora conectada a la red, estrato 1: cambiar "Subsidio de tu factura" a 45; en "Ubicación", "Mi ubicación" (en el celular, con GPS) | El subsidio empieza en 60 y acepta hasta 60; con altitud del GPS no sale aviso y en Bogotá o Medellín los resultados dicen "130 kWh/mes"; sin altitud (o con HSP a mano) sale el aviso de 173 kWh/mes; los resultados dicen "subsidio de 45 %" | [x] | [ ] |

"Eliminar mi cuenta" se prueba en un solo lado porque borra la cuenta: el código es el mismo en Android y en la web.

## 4. Pruebas de seguridad en la base (RLS y límites)

Revisan, en el Supabase real, que cada usuario solo pueda ver y cambiar lo suyo y que los límites de la Etapa 12 funcionen. El script crea dos usuarios de prueba, intenta lo prohibido como uno de ellos y al final lanza un error a propósito que **deshace todo**: no queda nada en la base.

```bash
npx supabase db query --linked -f supabase/pruebas/seguridad_rls.sql
```

El resultado esperado es un error que empieza con `PRUEBAS DE SEGURIDAD: 18 de 18 bien (todo se deshizo)` y una línea por prueba. Cualquier línea con `MAL` es una falla. Revisa:

- Perfiles y cálculos ajenos: no se ven, no se cambian, no se borran y no se crean a nombre de otro.
- Una simulación no se enlaza a un cálculo ajeno, ni al crearla ni al cambiarla.
- Datos demasiado grandes (entradas de 70 KB, serie de 270 KB) se rechazan.
- El cálculo y la simulación número 201 se rechazan (`limite_filas`).
- Sin sesión no se ven datos ni se puede llamar a `eliminar_mi_cuenta`.
- `eliminar_mi_cuenta` borra todo lo del usuario y nada de los demás.
