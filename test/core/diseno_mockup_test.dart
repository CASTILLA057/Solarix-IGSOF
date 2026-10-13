import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/router/app_router.dart';
import 'package:solarix/core/router/rutas.dart';
import 'package:solarix/core/widgets/barra_web.dart';
import 'package:solarix/core/widgets/sol_solarix.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/calculadora/application/calculadora_providers.dart';
import 'package:solarix/features/calculadora/data/calculadora_repository.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';

import '../helpers/fakes.dart';

class _Calculos implements CalculadoraRepository {
  var guardados = 0;

  @override
  Future<String> guardarCalculo(EntradasCalculo e, ResultadoCalculo r) async {
    guardados++;
    return 'calc-$guardados';
  }
}

/// Abre la app en una ventana de [ancho] px (900 o más = diseño web).
Future<_Calculos> _abrir(
  WidgetTester tester, {
  required double ancho,
  bool conSesion = true,
}) async {
  tester.view.physicalSize = Size(ancho, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final calculos = _Calculos();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            usuario: conSesion ? FakeAuthRepository.usuarioPrueba : null,
          ),
        ),
        perfilRepositoryProvider.overrideWithValue(
          FakePerfilRepository(
            const Perfil(id: 'u-1', nombre: 'Santiago Castilla'),
          ),
        ),
        calculadoraRepositoryProvider.overrideWithValue(calculos),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  return calculos;
}

void main() {
  test('iniciales del avatar: nombre y primer apellido', () {
    expect(AvatarIniciales.iniciales('Santiago Castilla'), 'SC');
    expect(AvatarIniciales.iniciales('  ana  '), 'A');
    expect(AvatarIniciales.iniciales('María José Pérez'), 'MJ');
    expect(AvatarIniciales.iniciales(''), '?');
  });

  testWidgets('celular: AppBar con el ícono de casa; web: barra superior', (
    tester,
  ) async {
    await _abrir(tester, ancho: 390);
    expect(find.byType(BarraWeb), findsNothing);
    expect(find.byTooltip('Mi perfil'), findsOneWidget);

    await _abrir(tester, ancho: 1280);
    expect(find.byType(BarraWeb), findsOneWidget);
    for (final enlace in ['Inicio', 'Calculadora', 'Simulación', 'Historial']) {
      expect(find.text(enlace), findsOneWidget, reason: enlace);
    }
    // El usuario con su primer nombre e iniciales.
    expect(find.text('Santiago'), findsOneWidget);
    expect(find.text('SC'), findsOneWidget);
    // El sol de la app (el mismo del ícono) en la barra y el saludo.
    expect(find.byType(SolSolarix), findsWidgets);
    expect(find.text('Hola, Santiago'), findsOneWidget);
  });

  testWidgets('bienvenida web: dos columnas y enlace a la política', (
    tester,
  ) async {
    await _abrir(tester, ancho: 1280, conSesion: false);
    expect(find.text('Energía solar a la medida de tu casa'), findsOneWidget);
    expect(find.text('Bienvenido a Solarix'), findsOneWidget);
    // Sin "al continuar aceptas": la autorización está en el registro.
    expect(find.textContaining('Al continuar'), findsNothing);
    await tester.tap(find.text('Política de tratamiento de datos (Ley 1581)'));
    await tester.pumpAndSettle();
    expect(
      find.text('Política de tratamiento de datos personales'),
      findsOneWidget,
    );
  });

  testWidgets('al guardar un cálculo, "VER" lleva al historial', (
    tester,
  ) async {
    final calculos = await _abrir(tester, ancho: 390);
    const e = EntradasCalculo(
      tipo: TipoSistema.onGrid,
      modo: ModoConsumo.factura,
      consumoFacturaKwhMes: 200,
      hsp: 4.5,
    );
    ProviderScope.containerOf(tester.element(find.byType(SolarixApp)))
        .read(routerProvider)
        .go(Rutas.resultados, extra: (e, calcular(e)));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Guardar cálculo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Guardar cálculo'));
    // Que el aviso termine de entrar antes de tocar su acción.
    await tester.pumpAndSettle();
    expect(calculos.guardados, 1);
    expect(
      find.text('Cálculo guardado. Lo verás en tu historial.'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(SnackBarAction, 'VER'));
    await tester.pumpAndSettle();
    expect(find.text('Cálculos'), findsOneWidget);
    expect(find.text('Simulaciones'), findsOneWidget);
  });
}
