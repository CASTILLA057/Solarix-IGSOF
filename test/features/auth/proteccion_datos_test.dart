import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/router/rutas.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/auth/domain/politica_datos.dart';
import 'package:solarix/features/auth/domain/usuario.dart';

import '../../helpers/fakes.dart';

Future<(FakeAuthRepository, FakePerfilRepository)> _abrir(
  WidgetTester tester, {
  bool conSesion = true,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository(
    usuario: conSesion ? FakeAuthRepository.usuarioPrueba : null,
  );
  final perfiles = FakePerfilRepository(const Perfil(id: 'u-1', nombre: 'Ana'));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        perfilRepositoryProvider.overrideWithValue(perfiles),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  return (auth, perfiles);
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

void main() {
  group('Política de tratamiento de datos', () {
    test('se puede leer con o sin sesión', () {
      expect(
        redirigir(autenticado: false, ubicacion: Rutas.politicaDatos),
        isNull,
      );
      expect(
        redirigir(autenticado: true, ubicacion: Rutas.politicaDatos),
        isNull,
      );
    });

    test('dice lo que exige la Ley 1581', () {
      final texto = PoliticaDatos.secciones
          .map((s) => '${s.$1} ${s.$2}')
          .join(' ');
      expect(texto, contains('Santiago Castilla'));
      expect(texto, contains(PoliticaDatos.correoContacto));
      expect(texto, contains('Supabase'));
      expect(texto, contains('Brevo'));
      // Con "Mi ubicación" las coordenadas van a estos dos servicios.
      expect(texto, contains('NASA POWER'));
      expect(texto, contains('Open-Meteo'));
      expect(texto, contains('Superintendencia de Industria y Comercio'));
      expect(texto, contains('Eliminar mi cuenta'));
      expect(PoliticaDatos.version, matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    testWidgets('con la versión actual aceptada no hay aviso', (tester) async {
      await _abrir(tester);
      expect(find.text('La política de datos cambió'), findsNothing);
    });

    testWidgets('si la política cambió, el inicio avisa y "Entendido" lo '
        'guarda en la cuenta', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      // Cuenta que aceptó una versión anterior.
      final auth = FakeAuthRepository(
        usuario: const Usuario(
          id: 'u-1',
          email: 'ana@correo.com',
          versionPolitica: '2026-10-05',
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(auth),
            perfilRepositoryProvider.overrideWithValue(
              FakePerfilRepository(const Perfil(id: 'u-1', nombre: 'Ana')),
            ),
          ],
          child: const SolarixApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('La política de datos cambió'), findsOneWidget);
      await _tocar(tester, find.widgetWithText(FilledButton, 'Entendido'));

      expect(auth.llamadas, contains('aceptarPolitica'));
      expect(auth.usuarioActual!.versionPolitica, PoliticaDatos.version);
      expect(find.text('La política de datos cambió'), findsNothing);
    });

    testWidgets('el registro enlaza la política', (tester) async {
      await _abrir(tester, conSesion: false);
      await _tocar(tester, find.widgetWithText(OutlinedButton, 'Crear cuenta'));
      await _tocar(
        tester,
        find.text('Leer la política de tratamiento de datos'),
      );
      expect(
        find.text('Política de tratamiento de datos personales'),
        findsOneWidget,
      );
      expect(find.textContaining('Santiago Castilla'), findsOneWidget);
      // "Atrás" vuelve al registro, con lo escrito.
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CheckboxListTile), findsOneWidget);
    });
  });

  group('Eliminar mi cuenta', () {
    Future<(FakeAuthRepository, FakePerfilRepository)> abrirDialogo(
      WidgetTester tester,
    ) async {
      final repos = await _abrir(tester);
      await _tocar(tester, find.byTooltip('Mi perfil'));
      await _tocar(tester, find.text('Eliminar mi cuenta'));
      return repos;
    }

    Finder campoDialogo() => find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );

    Finder confirmar() =>
        find.widgetWithText(FilledButton, 'Eliminar mi cuenta');

    testWidgets('el botón se activa solo al escribir ELIMINAR', (tester) async {
      final (_, perfiles) = await abrirDialogo(tester);
      expect(tester.widget<FilledButton>(confirmar()).onPressed, isNull);
      await tester.enterText(campoDialogo(), 'eliminar cuenta');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirmar()).onPressed, isNull);
      await _tocar(tester, find.text('Cancelar'));
      expect(perfiles.cuentasEliminadas, 0);
      expect(find.text('Mi perfil'), findsOneWidget);
    });

    testWidgets('al confirmar borra la cuenta y vuelve a la bienvenida', (
      tester,
    ) async {
      final (auth, perfiles) = await abrirDialogo(tester);
      await tester.enterText(campoDialogo(), 'ELIMINAR');
      await tester.pump();
      await _tocar(tester, confirmar());
      expect(perfiles.cuentasEliminadas, 1);
      expect(auth.llamadas, contains('cerrarSesion'));
      expect(find.text('Bienvenido a Solarix'), findsOneWidget);
      expect(
        find.text('Tu cuenta y todos tus datos se eliminaron.'),
        findsOneWidget,
      );
    });
  });
}
