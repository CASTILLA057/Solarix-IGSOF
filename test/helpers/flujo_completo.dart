import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/calculadora/application/calculadora_providers.dart';
import 'package:solarix/features/dashboard/application/historial_providers.dart';
import 'package:solarix/features/degradacion/application/simulacion_providers.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';

import 'backend_memoria.dart';
import 'fakes.dart';

/// Pasos del recorrido de principio a fin (Etapa 10), compartidos por la
/// prueba de CI (`test/flujo_completo_test.dart`) y las pruebas de
/// integración en el celular (`integration_test/`).

Finder boton(String texto) => find.widgetWithText(FilledButton, texto);

/// En pantallas pequeñas, lo que está más abajo en una lista aún no está
/// construido: se desplaza la lista hasta encontrarlo.
Future<void> buscar(WidgetTester tester, Finder objetivo) async {
  if (objetivo.evaluate().isNotEmpty) return;
  await tester.scrollUntilVisible(
    objetivo,
    300,
    scrollable: find
        .byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        )
        .first,
  );
}

Future<void> tocar(WidgetTester tester, Finder objetivo) async {
  await buscar(tester, objetivo);
  await tester.ensureVisible(objetivo);
  await tester.pumpAndSettle();
  await tester.tap(objetivo);
  await tester.pumpAndSettle();
}

Future<void> escribir(WidgetTester tester, String campo, String texto) async {
  final f = find.widgetWithText(TextFormField, campo);
  await buscar(tester, f);
  await tester.ensureVisible(f);
  await tester.enterText(f, texto);
  await tester.pumpAndSettle();
}

/// Espera a que aparezca [objetivo] (consultas a Supabase, simulación). En
/// el celular el tiempo es real; en `flutter test` casi siempre ya está.
Future<void> esperar(
  WidgetTester tester,
  Finder objetivo, {
  Duration limite = const Duration(seconds: 30),
}) async {
  const paso = Duration(milliseconds: 250);
  for (var i = 0; i < limite.inMilliseconds ~/ paso.inMilliseconds; i++) {
    await tester.pump(paso);
    if (objetivo.evaluate().isNotEmpty) {
      await tester.pumpAndSettle();
      return;
    }
    await tester.runAsync(() => Future<void>.delayed(paso));
  }
  expect(objetivo, findsWidgets, reason: 'No apareció a tiempo');
}

/// Abre la app sin sesión con el Supabase falso de [backend].
/// [rapido]: simulación de 2 años sin isolate (para `flutter test`).
Future<FakeAuthRepository> abrirConBackendFalso(
  WidgetTester tester,
  BackendEnMemoria backend, {
  bool rapido = false,
}) async {
  final auth = FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        perfilRepositoryProvider.overrideWithValue(
          FakePerfilRepository(const Perfil(id: 'u-1', nombre: 'Ana')),
        ),
        calculadoraRepositoryProvider.overrideWithValue(backend),
        simulacionRepositoryProvider.overrideWithValue(backend),
        historialRepositoryProvider.overrideWithValue(backend),
        if (rapido)
          ejecutorSimulacionProvider.overrideWithValue(
            (s) async => simularComparacion((
              parametros: s.parametros.copiarCon(anios: 2),
              semilla: 1,
            )),
          ),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

/// Bienvenida → crear cuenta → código de confirmación → inicio.
Future<void> registrarse(WidgetTester tester) async {
  await esperar(tester, find.text('Bienvenido a Solarix'));
  await tocar(tester, find.widgetWithText(OutlinedButton, 'Crear cuenta'));
  await escribir(tester, 'Nombre', 'Ana');
  await escribir(tester, 'Correo', 'ana@correo.com');
  await escribir(tester, 'Contraseña', 'solar2026');
  await escribir(tester, 'Repite la contraseña', 'solar2026');
  await tocar(tester, boton('Crear cuenta'));
  await esperar(tester, find.text('Confirma tu correo'));
  await escribir(tester, 'Código', '12345678');
  await tocar(tester, boton('Confirmar cuenta'));
  await esperar(tester, find.byTooltip('Historial'));
}

/// Bienvenida → iniciar sesión → inicio.
Future<void> iniciarSesion(
  WidgetTester tester, {
  required String email,
  required String contrasena,
}) async {
  await esperar(tester, find.text('Bienvenido a Solarix'));
  await tocar(tester, boton('Iniciar sesión'));
  await escribir(tester, 'Correo', email);
  await escribir(tester, 'Contraseña', contrasena);
  await tocar(tester, boton('Iniciar sesión'));
  await esperar(tester, find.byTooltip('Historial'));
}

/// Desde el inicio: calcula un sistema híbrido con litio, lo guarda,
/// simula su batería, guarda la simulación vinculada y revisa el inicio, el
/// historial y el detalle con sus gráficas.
Future<void> calcularSimularYRevisar(
  WidgetTester tester, {
  required String nombreCalculo,
}) async {
  // Calculadora.
  await tocar(tester, find.text('Calcular mi sistema solar'));
  await esperar(tester, find.text('Híbrido'));
  await tocar(tester, find.text('Híbrido'));
  await escribir(tester, 'Nombre del cálculo (opcional)', nombreCalculo);
  await tocar(tester, boton('Siguiente'));
  await tocar(tester, boton('Siguiente'));
  await tocar(tester, find.text('Manual'));
  await tocar(tester, boton('Siguiente'));
  await tocar(tester, boton('Calcular'));
  await esperar(tester, find.text('Resultados'));
  await tocar(tester, boton('Guardar cálculo'));
  await esperar(tester, boton('Cálculo guardado'));

  // Simulación de la batería del cálculo.
  await tocar(tester, find.text('Simular la salud de esta batería'));
  // La tarjeta del cálculo de origen muestra su nombre.
  await esperar(tester, find.text('Valores de "$nombreCalculo"'));
  await tocar(tester, boton('Simular'));
  await esperar(
    tester,
    find.text('Con el sistema que dimensionaste'),
    limite: const Duration(seconds: 90),
  );
  await tocar(tester, boton('Guardar simulación'));
  await esperar(tester, boton('Simulación guardada'));

  // De vuelta al inicio con el botón (ya guardada: no pregunta).
  await tocar(tester, find.text('Volver al inicio'));
  await esperar(tester, find.text('Último cálculo: $nombreCalculo'));
  expect(find.textContaining('Última simulación: SoH'), findsOneWidget);

  // Historial: el cálculo y la simulación vinculada, y su detalle.
  await tocar(tester, find.byTooltip('Historial'));
  await esperar(tester, find.text(nombreCalculo));
  await tocar(tester, find.text('Simulaciones'));
  final vinculada = find.textContaining('de un cálculo');
  await esperar(tester, vinculada);
  await tocar(tester, vinculada.first);
  expect(find.text('Simulación guardada'), findsOneWidget);
  // El impacto en la inversión (Etapa 12) y las tres gráficas (en pantalla
  // pequeña se desplaza hasta cada una).
  for (final titulo in [
    'Salud de la batería (SoH)',
    'Con el sistema que dimensionaste',
    'Generación y consumo por mes',
    'Energía comprada a la red (acumulada)',
  ]) {
    await buscar(tester, find.text(titulo));
    await tester.ensureVisible(find.text(titulo));
    await tester.pumpAndSettle();
    if (titulo.startsWith('Con el sistema')) {
      expect(find.textContaining('En plata conviene'), findsOneWidget);
    } else {
      expect(find.byType(LineChart), findsWidgets, reason: titulo);
    }
  }
}
