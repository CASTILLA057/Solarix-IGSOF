import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/app.dart';
import 'package:solarix/core/errors/error_app.dart';
import 'package:solarix/features/auth/application/auth_providers.dart';
import 'package:solarix/core/errors/mensajes_error.dart';
import 'package:solarix/features/auth/domain/perfil.dart';

import '../../helpers/fakes.dart';

/// Abre la app completa (router incluido) con repositorios falsos.
Future<void> abrirApp(
  WidgetTester tester,
  FakeAuthRepository auth, {
  FakePerfilRepository? perfiles,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        perfilRepositoryProvider.overrideWithValue(
          perfiles ?? FakePerfilRepository(const Perfil(id: 'u-1')),
        ),
      ],
      child: const SolarixApp(),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> escribir(WidgetTester tester, String campo, String texto) =>
    tester.enterText(find.widgetWithText(TextFormField, campo), texto);

Future<void> tocar(WidgetTester tester, Finder boton) async {
  await tester.ensureVisible(boton);
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

Finder boton(String texto) => find.widgetWithText(FilledButton, texto);

final enBienvenida = find.text('Bienvenido a Solarix');
final enInicio = find.byTooltip('Mi perfil');

/// Desde la bienvenida, abre el login.
Future<void> irALogin(WidgetTester tester) =>
    tocar(tester, boton('Iniciar sesión'));

/// Desde la bienvenida, abre "¿Olvidaste tu contraseña?" pasando por el login.
Future<void> irARecuperar(WidgetTester tester) async {
  await irALogin(tester);
  await tocar(
    tester,
    find.widgetWithText(TextButton, '¿Olvidaste tu contraseña?'),
  );
}

void main() {
  group('Bienvenida', () {
    testWidgets('sin sesión la app abre en la bienvenida', (tester) async {
      await abrirApp(tester, FakeAuthRepository());
      expect(enBienvenida, findsOneWidget);
      expect(boton('Iniciar sesión'), findsOneWidget);
      expect(
        find.widgetWithText(OutlinedButton, 'Crear cuenta'),
        findsOneWidget,
      );
      expect(enInicio, findsNothing);
    });

    testWidgets('con sesión guardada abre directo en el inicio', (
      tester,
    ) async {
      await abrirApp(
        tester,
        FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba),
      );
      expect(enInicio, findsOneWidget);
      expect(enBienvenida, findsNothing);
    });

    testWidgets('el botón atrás del login vuelve a la bienvenida', (
      tester,
    ) async {
      await abrirApp(tester, FakeAuthRepository());
      await irALogin(tester);
      expect(enBienvenida, findsNothing);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(enBienvenida, findsOneWidget);
    });
  });

  group('Inicio de sesión', () {
    testWidgets('valida los campos antes de llamar a Supabase', (tester) async {
      final auth = FakeAuthRepository();
      await abrirApp(tester, auth);
      await irALogin(tester);
      await tocar(tester, boton('Iniciar sesión'));
      expect(find.text('Escribe tu correo.'), findsOneWidget);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);
      expect(auth.llamadas, isEmpty);
    });

    testWidgets('con datos correctos entra al inicio', (tester) async {
      final auth = FakeAuthRepository();
      await abrirApp(tester, auth);
      await irALogin(tester);
      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'solar2026');
      await tocar(tester, boton('Iniciar sesión'));
      expect(auth.llamadas, ['iniciarSesion:ana@correo.com']);
      expect(enInicio, findsOneWidget);
    });

    testWidgets('muestra el mensaje si las credenciales son incorrectas', (
      tester,
    ) async {
      final auth = FakeAuthRepository()
        ..errorSiguiente = ErrorApp(
          mensajeErrorAuth('invalid_credentials'),
          codigo: 'invalid_credentials',
        );
      await abrirApp(tester, auth);
      await irALogin(tester);
      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'mala1234');
      await tocar(tester, boton('Iniciar sesión'));
      expect(find.text('Correo o contraseña incorrectos.'), findsOneWidget);
      expect(enInicio, findsNothing);
    });

    testWidgets('si el correo no está confirmado pide el código', (
      tester,
    ) async {
      final auth = FakeAuthRepository()
        ..errorSiguiente = const ErrorApp(
          'sin confirmar',
          codigo: CodigosError.correoSinConfirmar,
        );
      await abrirApp(tester, auth);
      await irALogin(tester);
      await escribir(tester, 'Correo', 'ana@correo.com');
      await escribir(tester, 'Contraseña', 'solar2026');
      await tocar(tester, boton('Iniciar sesión'));
      expect(find.text('Confirma tu correo'), findsOneWidget);
      expect(find.text('ana@correo.com'), findsOneWidget);
    });
  });

  testWidgets('registro desde la bienvenida con confirmación por código', (
    tester,
  ) async {
    final auth = FakeAuthRepository();
    await abrirApp(tester, auth);
    await tocar(tester, find.widgetWithText(OutlinedButton, 'Crear cuenta'));

    await escribir(tester, 'Nombre', 'Ana');
    await escribir(tester, 'Correo', 'ana@correo.com');
    await escribir(tester, 'Contraseña', 'solar2026');
    await escribir(tester, 'Repite la contraseña', 'solar2027');
    await tocar(tester, boton('Crear cuenta'));
    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

    await escribir(tester, 'Repite la contraseña', 'solar2026');
    await tocar(tester, boton('Crear cuenta'));
    expect(auth.llamadas, ['registrarse:ana@correo.com:Ana']);
    expect(find.text('Confirma tu correo'), findsOneWidget);

    await escribir(tester, 'Código', '12345678');
    await tocar(tester, boton('Confirmar cuenta'));
    expect(auth.llamadas.last, 'confirmarRegistro:ana@correo.com:12345678');
    expect(enInicio, findsOneWidget);
  });

  group('Recuperar contraseña en tres pasos', () {
    final campoContrasenaNueva = find.widgetWithText(
      TextFormField,
      'Contraseña nueva',
    );

    Future<void> hastaPasoCodigo(
      WidgetTester tester,
      FakeAuthRepository auth,
    ) async {
      await abrirApp(tester, auth);
      await irARecuperar(tester);
      // Paso 1: solo el correo.
      expect(find.widgetWithText(TextFormField, 'Código'), findsNothing);
      expect(campoContrasenaNueva, findsNothing);
      await escribir(tester, 'Correo', 'ana@correo.com');
      await tocar(tester, boton('Enviar código'));
    }

    testWidgets('pide el código antes que la contraseña nueva', (tester) async {
      final auth = FakeAuthRepository();
      await hastaPasoCodigo(tester, auth);

      // Paso 2: solo el código.
      expect(find.widgetWithText(TextFormField, 'Código'), findsOneWidget);
      expect(campoContrasenaNueva, findsNothing);
      await escribir(tester, 'Código', '87654321');
      await tocar(tester, boton('Verificar código'));

      // Paso 3: con el código correcto, la contraseña nueva.
      expect(find.widgetWithText(TextFormField, 'Código'), findsNothing);
      expect(campoContrasenaNueva, findsOneWidget);
      await escribir(tester, 'Contraseña nueva', 'nueva2026');
      await escribir(tester, 'Repite la contraseña nueva', 'nueva2026');
      await tocar(tester, boton('Cambiar contraseña'));

      expect(auth.llamadas, [
        'enviarCodigoRecuperacion:ana@correo.com',
        'verificarCodigoRecuperacion:ana@correo.com:87654321',
        'cambiarContrasena',
      ]);
      expect(enInicio, findsOneWidget);
    });

    testWidgets('con un código incorrecto se queda en el paso del código', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await hastaPasoCodigo(tester, auth);

      auth.errorSiguiente = ErrorApp(
        mensajeErrorAuth('otp_expired'),
        codigo: 'otp_expired',
      );
      await escribir(tester, 'Código', '11111111');
      await tocar(tester, boton('Verificar código'));

      expect(find.text(mensajeErrorAuth('otp_expired')), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Código'), findsOneWidget);
      expect(campoContrasenaNueva, findsNothing);
    });

    testWidgets('si sale sin cambiar la contraseña se cierra la sesión', (
      tester,
    ) async {
      final auth = FakeAuthRepository();
      await hastaPasoCodigo(tester, auth);
      await escribir(tester, 'Código', '87654321');
      await tocar(tester, boton('Verificar código'));
      expect(campoContrasenaNueva, findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(auth.llamadas.last, 'cerrarSesion');
      expect(auth.usuarioActual, isNull);
      expect(enInicio, findsNothing);
    });
  });

  testWidgets('perfil: editar, guardar y cerrar sesión', (tester) async {
    final auth = FakeAuthRepository(usuario: FakeAuthRepository.usuarioPrueba);
    final perfiles = FakePerfilRepository(
      const Perfil(id: 'u-1', nombre: 'Ana'),
    );
    await abrirApp(tester, auth, perfiles: perfiles);
    await tocar(tester, enInicio);

    expect(find.text('Mi perfil'), findsOneWidget);
    expect(find.text('ana@correo.com'), findsOneWidget);
    expect(find.text('Ana'), findsOneWidget);

    await escribir(tester, 'Nombre', 'Ana Pérez');
    await escribir(tester, 'Ciudad (opcional)', 'Ocaña');
    await tocar(tester, find.byType(DropdownButtonFormField<ZonaIrradiancia>));
    await tocar(tester, find.text(ZonaIrradiancia.media.etiqueta).last);
    await tocar(tester, boton('Guardar cambios'));

    final guardado = perfiles.guardados.single;
    expect(guardado.nombre, 'Ana Pérez');
    expect(guardado.ciudad, 'Ocaña');
    expect(guardado.zonaIrradiancia, ZonaIrradiancia.media);

    await tocar(tester, find.widgetWithText(OutlinedButton, 'Cerrar sesión'));
    await tocar(tester, boton('Cerrar sesión'));
    expect(auth.llamadas, ['cerrarSesion']);
    expect(enBienvenida, findsOneWidget);
  });
}
