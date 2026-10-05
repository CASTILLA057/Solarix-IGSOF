import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/core/errors/mensajes_error.dart';
import 'package:solarix/core/errors/traducir_error.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/integracion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Límites de tamaño de la migración de seguridad (Etapa 12), leídos del SQL
/// para que la prueba siga al archivo.
Map<String, int> _limitesDeLaMigracion() {
  final sql = File('supabase/migrations/20261005000100_seguridad.sql')
      .readAsStringSync();
  return {
    for (final m in RegExp(
      r'add constraint (\w+)\s+check \((?:serie is null or )?pg_column_size\(\w+\) <= (\d+)\)',
    ).allMatches(sql))
      m.group(1)!: int.parse(m.group(2)!),
  };
}

/// Bytes del JSON: aproxima `pg_column_size` de un jsonb.
int _bytes(Object? valor) => utf8.encode(jsonEncode(valor)).length;

void main() {
  test('lo más grande que guarda la app cabe con margen en los límites', () {
    final limites = _limitesDeLaMigracion();
    expect(limites, hasLength(5));

    // Peor caso de un cálculo: 50 equipos con nombre largo, horizonte de
    // 30 años, clima y precios.
    final entradas = EntradasCalculo(
      tipo: TipoSistema.hibrido,
      hsp: 5,
      nombre: 'Casa de campo con taller y bodega en la vereda',
      equipos: [
        for (var i = 0; i < 50; i++)
          Equipo(
            nombre: 'Equipo número $i con un nombre bastante largo',
            potenciaW: 1234.5,
            horasDia: 7.25,
            cantidad: 3,
            factorArranque: 3,
          ),
      ],
      ubicacion: 'Ocaña (Norte de Santander)',
      supuestos: const Supuestos(anios: 30),
      clima: climaDeCiudad('Ocaña'),
    );
    final resultado = calcular(entradas);

    // Peor caso de una simulación: 20 años, con el impacto financiero.
    final origen = OrigenCalculo(entradas: entradas, resultado: resultado);
    final c = simularComparacion((
      parametros: parametrosDesdeCalculo(origen).copiarCon(anios: 20),
      semilla: 1,
    ));
    final impacto = calcularImpacto(
      origen: origen,
      convencional: c.convencional,
      consciente: c.consciente,
      referencia: c.referencia,
      elegida: Politica.consciente,
    );
    final fila = c.aFila(financiero: impacto.aMapa());

    final tamanos = {
      'calculos_entradas_tamano': _bytes(entradas.aMapa()),
      'calculos_resultados_tamano': _bytes(resultado.aMapa()),
      'simulaciones_parametros_tamano': _bytes(fila['parametros']),
      'simulaciones_resultados_tamano': _bytes(fila['resultados']),
      'simulaciones_serie_tamano': _bytes(fila['serie']),
    };
    for (final MapEntry(key: restriccion, value: bytes) in tamanos.entries) {
      // Al menos 4 veces de margen.
      expect(
        bytes * 4,
        lessThanOrEqualTo(limites[restriccion]!),
        reason: '$restriccion: $bytes bytes',
      );
    }
  }, timeout: const Timeout(Duration(minutes: 2)));

  group('Errores de los límites', () {
    test('el tope de 200 filas se explica', () {
      final e = errorDesde(
        const PostgrestException(
          message: 'limite_filas: calculos_consumo',
          code: 'P0001',
        ),
      );
      expect(e.codigo, CodigosError.limiteFilas);
      expect(e.mensaje, contains('200'));
      expect(e.mensaje, contains('historial'));
    });

    test('los datos demasiado grandes se explican', () {
      final e = errorDesde(
        const PostgrestException(
          message:
              'new row for relation "calculos_consumo" violates check '
              'constraint "calculos_entradas_tamano"',
          code: '23514',
        ),
      );
      expect(e.codigo, CodigosError.datosMuyGrandes);
    });

    test('otra restricción sigue con el mensaje genérico', () {
      final e = errorDesde(
        const PostgrestException(message: 'otra cosa', code: '23514'),
        accion: 'guardar el cálculo',
      );
      expect(e.codigo, isNull);
      expect(e.mensaje, 'No se pudo guardar el cálculo. Intenta de nuevo.');
    });
  });

  group('Ciudad del perfil', () {
    test('se busca en la lista, también con texto libre de antes', () {
      expect(ciudadPorNombre('Ocaña')?.departamento, 'Norte de Santander');
      expect(ciudadPorNombre(' ocaña, norte de santander')?.nombre, 'Ocaña');
      expect(ciudadPorNombre('Atlantis'), isNull);
      expect(ciudadPorNombre(''), isNull);
      expect(ciudadPorNombre(null), isNull);
    });
  });
}
