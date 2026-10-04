import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/errors/error_app.dart';
import 'package:solarix/core/errors/mensajes_error.dart';
import 'package:solarix/core/router/app_router.dart';
import 'package:solarix/core/router/rutas.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';

import '../../helpers/fakes.dart';

/// Abre "Confirma tu correo" para [email], sin sesión.
Future<FakeAuthRepository> _abrir(WidgetTester tester, String email) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final auth = FakeAuthRepository();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(auth)],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
  ProviderScope.containerOf(tester.element(find.byType(SolarixApp)))
      .read(routerProvider)
      .go(Rutas.verificarCon(email));
  await tester.pumpAndSettle();
  expect(find.text('Confirma tu correo'), findsOneWidget);
  return auth;
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

final _reenviar = find.text('Reenviar código');

void main() {
  testWidgets('reenvía el código y lo avisa', (tester) async {
    final auth = await _abrir(tester, 'ana@correo.com');
    await _tocar(tester, _reenviar);
    expect(auth.llamadas, ['reenviarCodigoRegistro:ana@correo.com']);
    expect(find.text('Te enviamos un código nuevo.'), findsOneWidget);
  });

  testWidgets('si el envío falla muestra el motivo', (tester) async {
    final auth = await _abrir(tester, 'ana@correo.com');
    auth.errorSiguiente = ErrorApp(
      mensajeErrorAuth('over_email_send_rate_limit'),
    );
    await _tocar(tester, _reenviar);
    expect(
      find.text(mensajeErrorAuth('over_email_send_rate_limit')),
      findsOneWidget,
    );
    expect(find.text('Te enviamos un código nuevo.'), findsNothing);
  });

  testWidgets('con un correo inválido no llama a Supabase', (tester) async {
    final auth = await _abrir(tester, 'no-es-un-correo');
    await _tocar(tester, _reenviar);
    expect(auth.llamadas, isEmpty);
  });

  testWidgets('"Volver a iniciar sesión" abre el login', (tester) async {
    await _abrir(tester, 'ana@correo.com');
    await _tocar(tester, find.text('Volver a iniciar sesión'));
    expect(find.text('Confirma tu correo'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });
}
