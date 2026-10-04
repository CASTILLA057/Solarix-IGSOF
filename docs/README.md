# Solarix

Calculadora de dimensionamiento y costos de paneles solares + simulador de degradación de baterías de iones de litio (SimDeg-FV), con cuenta de usuario e historial en la nube.

- **Plataformas:** Android y Web
- **Stack:** Flutter · Riverpod · go_router · Supabase · fl_chart
- **Plan de trabajo:** ver [ETAPAS_SOLARIX_APP.md](ETAPAS_SOLARIX_APP.md)

## Requisitos

- Flutter 3.47 (canal stable)
- Un proyecto de [Supabase](https://supabase.com) (plan gratis)

## Configuración

1. Instalar dependencias:
   ```bash
   flutter pub get
   ```
2. Copiar `env.example.json` a `env.json` y poner la URL y la **publishable key** (`sb_publishable_...`) del proyecto de Supabase (Project Settings → API Keys). `env.json` está en `.gitignore`.
3. Crear las tablas: en Supabase → SQL Editor, ejecutar `supabase/migrations/20261001000000_esquema_inicial.sql`.

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
