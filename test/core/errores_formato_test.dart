import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:solarix/core/errors/error_app.dart';
import 'package:solarix/core/errors/mensajes_error.dart';
import 'package:solarix/core/errors/traducir_error.dart';
import 'package:solarix/core/formato.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('errorDesde', () {
    String? codigo(Object e) => errorDesde(e).codigo;

    test('proyecto de Supabase pausado (HTTP 540)', () {
      expect(
        codigo(
          const PostgrestException(message: 'Project paused', code: '540'),
        ),
        CodigosError.pausado,
      );
      expect(
        codigo(AuthException('Project paused', statusCode: '540')),
        CodigosError.pausado,
      );
      expect(
        errorDesde(const PostgrestException(message: '', code: '540')).mensaje,
        contains('en pausa'),
      );
    });

    test('sin conexión', () {
      expect(
        codigo(ClientException('Failed host lookup')),
        CodigosError.sinConexion,
      );
      expect(codigo(AuthRetryableFetchException()), CodigosError.sinConexion);
      expect(codigo(TimeoutException('lento')), CodigosError.sinConexion);
    });

    test('sesión expirada', () {
      expect(
        codigo(
          const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
        ),
        CodigosError.sesionExpirada,
      );
    });

    test('errores de Auth conservan su código', () {
      final e = errorDesde(
        AuthException('x', code: CodigosError.correoSinConfirmar),
      );
      expect(e.codigo, CodigosError.correoSinConfirmar);
      expect(e.mensaje, mensajeErrorAuth(CodigosError.correoSinConfirmar));
    });

    test('otros errores usan la acción, y ErrorApp pasa igual', () {
      expect(
        errorDesde(
          const PostgrestException(message: 'violates', code: '23505'),
          accion: 'guardar el cálculo',
        ).mensaje,
        'No se pudo guardar el cálculo. Intenta de nuevo.',
      );
      expect(errorDesde(const FormatException('x')).codigo, isNull);
      const propio = ErrorApp('Mío');
      expect(errorDesde(propio), same(propio));
    });
  });

  group('ejecutarRemoto', () {
    test('una consulta que nunca responde termina en "sin conexión"', () {
      final colgada = Completer<int>().future;
      expect(
        ejecutarRemoto(() => colgada, limite: const Duration(milliseconds: 20)),
        throwsA(
          isA<ErrorApp>().having(
            (e) => e.codigo,
            'codigo',
            CodigosError.sinConexion,
          ),
        ),
      );
    });

    test('devuelve el resultado y traduce los errores', () async {
      expect(await ejecutarRemoto(() async => 7), 7);
      expect(
        ejecutarRemoto(
          () async => throw const PostgrestException(message: 'x', code: '540'),
        ),
        throwsA(
          isA<ErrorApp>().having(
            (e) => e.codigo,
            'codigo',
            CodigosError.pausado,
          ),
        ),
      );
    });

    test('límites: 5 s por consulta, 15 s si se envía un correo', () {
      expect(limiteConsulta, const Duration(seconds: 5));
      expect(limiteEnvioCorreo, const Duration(seconds: 15));
    });
  });

  test('Formato.corto quita los decimales de sobra', () {
    expect(Formato.corto(1), '1');
    expect(Formato.corto(0.036), '0,036');
    expect(Formato.corto(1500), '1.500');
    expect(Formato.corto(4.25), '4,25');
  });
}
