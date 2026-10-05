import 'package:solarix/features/calculadora/data/calculadora_repository.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/dashboard/data/historial_repository.dart';
import 'package:solarix/features/dashboard/domain/historial.dart';
import 'package:solarix/features/degradacion/data/simulacion_repository.dart';
import 'package:solarix/features/degradacion/domain/comparacion.dart';
import 'package:solarix/features/degradacion/domain/integracion.dart';

/// Supabase falso en memoria para las pruebas de principio a fin: guarda
/// cálculos y simulaciones como filas con las mismas columnas que las tablas
/// (`calculos_consumo`, `simulaciones_degradacion`) y el historial las lee
/// con los mismos `desdeFila` que en producción.
class BackendEnMemoria
    implements
        CalculadoraRepository,
        SimulacionRepository,
        HistorialRepository {
  final filasCalculos = <Map<String, dynamic>>[];
  final filasSimulaciones = <Map<String, dynamic>>[];
  var _siguienteId = 1;
  var _reloj = DateTime.utc(2026, 10, 1, 12);

  String _id(String prefijo) => '$prefijo-${_siguienteId++}';

  /// Cada fila es un minuto más reciente que la anterior.
  String _ahora() =>
      (_reloj = _reloj.add(const Duration(minutes: 1))).toIso8601String();

  @override
  Future<String> guardarCalculo(
    EntradasCalculo entradas,
    ResultadoCalculo resultado,
  ) async {
    final id = _id('calc');
    filasCalculos.add({
      'id': id,
      'nombre': entradas.nombre.trim().isEmpty ? null : entradas.nombre.trim(),
      'tipo_sistema': entradas.tipo.valorBd,
      'creado_en': _ahora(),
      'entradas': entradas.aMapa(),
      'resultados': resultado.aMapa(),
    });
    return id;
  }

  @override
  Future<void> guardar(
    ComparacionSimulacion simulacion, {
    String? calculoId,
    ImpactoFinanciero? impacto,
  }) async {
    filasSimulaciones.add({
      'id': _id('sim'),
      'creado_en': _ahora(),
      'calculo_id': calculoId,
      ...simulacion.aFila(financiero: impacto?.aMapa()),
    });
  }

  @override
  Future<List<CalculoGuardado>> calculos() async => [
    for (final f in filasCalculos.reversed) CalculoGuardado.desdeFila(f),
  ];

  @override
  Future<List<SimulacionGuardada>> simulaciones() async => [
    for (final f in filasSimulaciones.reversed) SimulacionGuardada.desdeFila(f),
  ];

  @override
  Future<void> eliminarCalculo(String id) async {
    filasCalculos.removeWhere((f) => f['id'] == id);
    // Como en la tabla: `on delete set null`.
    for (final s in filasSimulaciones) {
      if (s['calculo_id'] == id) s['calculo_id'] = null;
    }
  }

  @override
  Future<void> eliminarSimulacion(String id) async =>
      filasSimulaciones.removeWhere((f) => f['id'] == id);
}
