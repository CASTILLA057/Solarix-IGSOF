# Solarix

Calculadora de dimensionamiento y costos de paneles solares + simulador de degradación de baterías de iones de litio (SimDeg-FV), con cuenta de usuario e historial en la nube.

- **Plataformas:** Android y Web
- **Stack:** Flutter · Riverpod · go_router · Supabase · fl_chart
- **Versión:** 1.1.0 (build 2)
- **Plan de trabajo:** ver [ETAPAS_SOLARIX_APP.md](ETAPAS_SOLARIX_APP.md)
- **Despliegue (ícono, APK firmado, web):** ver [DESPLIEGUE.md](DESPLIEGUE.md)
- **Fuentes de datos y normas:** [FUENTES.md](FUENTES.md) · **Defensa (fórmulas, límites y guion):** [DEFENSA.md](DEFENSA.md) · **¿Para qué simular la batería?:** [BARRIDO_BATERIA.md](BARRIDO_BATERIA.md) · **Validación contra NetLogo:** [VALIDACION_DART.md](VALIDACION_DART.md)

## Qué hace la app

- **Calculadora solar:** sistema conectado a la red, híbrido o aislado; consumo por equipos o por factura; paneles, batería, inversor, costos, recuperación y VPN a 20 años.
- **Ciudad y clima:** 28 ciudades con radiación (NASA POWER), lluvia, nubosidad y temperatura; también "Mi ubicación".
- **Tarifa real:** estrato 1 a 6 (subsidios y contribución), consumo de subsistencia según la altura, y excedentes por tramos (CREG 174 de 2021).
- **Ley 1715:** exclusión de IVA y deducción de renta (opcionales).
- **Comparación sin batería:** en el híbrido, cuánto vale la batería frente al mismo sistema sin ella; en el aislado, la energía que faltó.
- **Simulador de degradación (SimDeg-FV):** 10 años de salud (SoH) de la batería con política convencional o consciente, y su efecto en la inversión.
- **Probar sin cuenta:** se puede calcular y simular sin registrarse; la cuenta solo hace falta para guardar el historial en la nube.
- **Instalar el APK (Android):** `entregas/Solarix-1.1.0.apk` (firmado; la carpeta `entregas/` no está en git: se comparte aparte). Hay que permitir la instalación de orígenes desconocidos.

## Requisitos

- Flutter 3.47 (canal stable)
- Un proyecto de [Supabase](https://supabase.com) (plan gratis)

## Configuración

1. Instalar dependencias:
   ```bash
   flutter pub get
   ```
2. Copiar `env.example.json` a `env.json` y poner la URL y la **publishable key** (`sb_publishable_...`) del proyecto de Supabase (Project Settings → API Keys). `env.json` está en `.gitignore`.
3. Crear las tablas y las reglas de seguridad aplicando **las cuatro migraciones, en orden**, desde `supabase/migrations/`. Con la CLI de Supabase (proyecto vinculado con `supabase link`):
   ```bash
   supabase db push
   ```
   Sin la CLI, en Supabase → SQL Editor, ejecutar uno tras otro:
   1. `20261001000000_esquema_inicial.sql`: perfiles, cálculos y simulaciones con RLS.
   2. `20261001000100_calculadora.sql`: tablas de la calculadora.
   3. `20261005000000_eliminar_cuenta.sql`: función `eliminar_mi_cuenta` (sin ella, "Eliminar mi cuenta" falla).
   4. `20261005000100_seguridad.sql`: límites de tamaño, tope de 200 filas por usuario y políticas finales.

   Las pruebas de seguridad (RLS) están en `supabase/pruebas/seguridad_rls.sql`, y los límites de uso y alertas en [DESPLIEGUE.md](DESPLIEGUE.md).

## Ejecutar

```bash
flutter run -d chrome --dart-define-from-file=env.json
```

En Android, cambia `-d chrome` por el id del dispositivo o emulador (`flutter devices`). Sin `env.json` la app arranca igual, pero sin backend.

## Calidad

```bash
flutter analyze
flutter test
```

GitHub Actions corre formato, análisis y pruebas en cada push a `main`. Las pruebas de integración en el celular (con Supabase falso y con el real) y la lista de prueba manual están en [PRUEBAS.md](PRUEBAS.md).

## Estructura

```
lib/
  core/        configuración, tema y rutas compartidas
  features/
    auth/          registro, login, perfil (Etapa 2)
    calculadora/   consumo, dimensionamiento y costos (Etapa 3)
    degradacion/   motor SimDeg-FV y simulación (Etapas 4–5)
    dashboard/     inicio, gráficas e historial (Etapa 7)
test/                  pruebas automáticas (flutter test)
integration_test/      pruebas de principio a fin en el celular
supabase/migrations/   esquema SQL versionado
docs/referencia/       modelo NetLogo y proyecto HTML originales
```
