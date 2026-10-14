import 'package:solarix/core/errors/error_app.dart';
import 'package:solarix/features/calculadora/domain/calculadora.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/dashboard/data/historial_repository.dart';
import 'package:solarix/features/dashboard/domain/historial.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/parametros.dart';

/// Fila como la devuelve Supabase, a partir de un cálculo real.
Map<String, dynamic> filaCalculo(String id, DateTime fecha) {
  const e = EntradasCalculo(
    tipo: TipoSistema.hibrido,
    modo: ModoConsumo.factura,
    consumoFacturaKwhMes: 300,
    hsp: 5,
    nombre: 'Casa',
  );
  return {
    'id': id,
    'nombre': e.nombre,
    'tipo_sistema': e.tipo.valorBd,
    'creado_en': fecha.toUtc().toIso8601String(),
    'entradas': e.aMapa(),
    'resultados': calcular(e).aMapa(),
  };
}

/// Fila como la devuelve Supabase, a partir de una simulación real.
Map<String, dynamic> filaSimulacion(String id, DateTime fecha, Politica p) => {
  'id': id,
  'creado_en': fecha.toUtc().toIso8601String(),
  'calculo_id': null,
  ...simularComparacion((
    parametros: ParametrosSimulacion(anios: 2, politica: p),
    semilla: 2,
  )).aFila(),
};

class FakeHistorial implements HistorialRepository {
  FakeHistorial(this._calculos, this._simulaciones, {this.error});

  final List<CalculoGuardado> _calculos;
  final List<SimulacionGuardada> _simulaciones;
  final eliminadas = <String>[];

  /// Si no es nulo, las consultas fallan con este error.
  ErrorApp? error;

  @override
  Future<List<CalculoGuardado>> calculos() async {
    if (error != null) throw error!;
    return [
      for (final c in _calculos)
        if (!eliminadas.contains(c.id)) c,
    ];
  }

  @override
  Future<List<SimulacionGuardada>> simulaciones() async {
    if (error != null) throw error!;
    return [
      for (final s in _simulaciones)
        if (!eliminadas.contains(s.id)) s,
    ];
  }

  @override
  Future<void> eliminarCalculo(String id) async => eliminadas.add(id);

  @override
  Future<void> eliminarSimulacion(String id) async => eliminadas.add(id);
}
