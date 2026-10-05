import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/router/rutas.dart';
import 'package:solarix/core/theme/app_theme.dart';
import 'package:solarix/core/theme/transicion_suave.dart';
import 'package:solarix/core/errors/mensajes_error.dart';
import 'package:solarix/features/auth/domain/perfil.dart';
import 'package:solarix/features/auth/domain/validadores.dart';

void main() {
  group('Validadores.email', () {
    test('acepta correos válidos (con espacios alrededor)', () {
      expect(Validadores.email('ana@correo.com'), isNull);
      expect(Validadores.email('  ana.perez@ufps.edu.co '), isNull);
    });
    test('rechaza vacío y formatos inválidos', () {
      expect(Validadores.email(''), isNotNull);
      expect(Validadores.email(null), isNotNull);
      expect(Validadores.email('ana@correo'), isNotNull);
      expect(Validadores.email('ana correo.com'), isNotNull);
    });
  });

  group('Validadores.contrasena', () {
    test('exige 8 caracteres con letras y números', () {
      expect(Validadores.contrasena('solar2026'), isNull);
      expect(Validadores.contrasena('Ñandú123'), isNull);
      expect(Validadores.contrasena('abc12'), contains('8'));
      expect(Validadores.contrasena('solamente'), isNotNull);
      expect(Validadores.contrasena('12345678'), isNotNull);
      expect(Validadores.contrasena(''), isNotNull);
    });
    test('para iniciar sesión solo exige que no esté vacía', () {
      expect(Validadores.contrasenaRequerida('x'), isNull);
      expect(Validadores.contrasenaRequerida(''), isNotNull);
    });
    test('la confirmación debe coincidir', () {
      expect(Validadores.confirmacion('solar2026', 'solar2026'), isNull);
      expect(Validadores.confirmacion('solar2027', 'solar2026'), isNotNull);
      expect(Validadores.confirmacion('', 'solar2026'), isNotNull);
    });
  });

  test('Validadores.codigo acepta solo de 6 a 10 dígitos', () {
    expect(Validadores.codigo('123456'), isNull);
    expect(Validadores.codigo(' 12345678 '), isNull);
    expect(Validadores.codigo('12345'), isNotNull);
    expect(Validadores.codigo('12a456'), isNotNull);
    expect(Validadores.codigo(''), isNotNull);
  });

  test('Validadores.nombre exige texto y máximo 80 caracteres', () {
    expect(Validadores.nombre('Ana'), isNull);
    expect(Validadores.nombre('   '), isNotNull);
    expect(Validadores.nombre('a' * 81), isNotNull);
  });

  group('mensajeErrorAuth', () {
    test('traduce los códigos conocidos de Supabase', () {
      expect(
        mensajeErrorAuth('invalid_credentials'),
        'Correo o contraseña incorrectos.',
      );
      expect(
        mensajeErrorAuth('email_exists'),
        mensajeErrorAuth(CodigosError.usuarioExistente),
      );
      expect(mensajeErrorAuth('otp_expired'), contains('código'));
      expect(mensajeErrorAuth(CodigosError.sinConexion), contains('internet'));
    });
    test('usa un mensaje genérico para códigos desconocidos o nulos', () {
      const generico = 'Ocurrió un error inesperado. Intenta de nuevo.';
      expect(mensajeErrorAuth(null), generico);
      expect(mensajeErrorAuth('algo_nuevo'), generico);
    });
  });

  group('redirigir', () {
    test('sin sesión manda a la bienvenida desde rutas privadas', () {
      expect(
        redirigir(autenticado: false, ubicacion: Rutas.inicio),
        Rutas.bienvenida,
      );
      expect(
        redirigir(autenticado: false, ubicacion: Rutas.perfil),
        Rutas.bienvenida,
      );
    });
    test('sin sesión deja ver las pantallas públicas', () {
      for (final ruta in Rutas.publicas) {
        expect(redirigir(autenticado: false, ubicacion: ruta), isNull);
      }
    });
    test('con sesión saca de bienvenida, login, registro y verificación', () {
      for (final ruta in Rutas.soloSinSesion) {
        expect(redirigir(autenticado: true, ubicacion: ruta), Rutas.inicio);
      }
    });
    test('con sesión permite recuperar (el código abre la sesión)', () {
      expect(redirigir(autenticado: true, ubicacion: Rutas.recuperar), isNull);
      expect(redirigir(autenticado: true, ubicacion: Rutas.perfil), isNull);
    });
  });

  test('Rutas.verificarCon codifica el correo en la URL', () {
    expect(
      Rutas.verificarCon('ana+solar@correo.com'),
      '/bienvenida/verificar?email=ana%2Bsolar%40correo.com',
    );
  });

  test('las pantallas de acceso son hijas de la bienvenida', () {
    for (final ruta in [
      Rutas.login,
      Rutas.registro,
      Rutas.verificar,
      Rutas.recuperar,
    ]) {
      expect(ruta, startsWith('${Rutas.bienvenida}/'));
    }
  });

  test('el tema usa la transición suave en todas las plataformas', () {
    for (final tema in [AppTheme.claro, AppTheme.oscuro]) {
      final constructores = tema.pageTransitionsTheme.builders;
      for (final plataforma in TargetPlatform.values) {
        expect(constructores[plataforma], isA<TransicionSuave>());
      }
    }
  });

  test('Perfil se lee y escribe con los nombres de columna de Supabase', () {
    final perfil = Perfil.desdeMapa({
      'id': 'u-1',
      'nombre': 'Ana',
      'ciudad': 'Ocaña',
    });
    expect(perfil.ciudad, 'Ocaña');
    // Sin zona_irradiancia: la columna se quitó en la Etapa 12.
    expect(perfil.aMapaEditable(), {'nombre': 'Ana', 'ciudad': 'Ocaña'});
  });
}
