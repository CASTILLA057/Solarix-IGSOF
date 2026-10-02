import '../../calculadora/domain/modelos.dart';
import '../../degradacion/domain/parametros.dart';

/// Cálculos y simulaciones guardados (Etapa 7), leídos de las filas de
/// `calculos_consumo` y `simulaciones_degradacion`.

double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
List<double> _lista(Object? v) => [for (final x in (v as List?) ?? []) _d(x)];

class CalculoGuardado {
  const CalculoGuardado({
    required this.id,
    required this.creadoEn,
    required this.tipo,
    required this.nombre,
    required this.energiaDiaKwh,
    required this.numeroPaneles,
    required this.potenciaKw,
    required this.bateriaKwh,
    required this.costoTotal,
    required this.ahorroMensual,
    required this.paybackAnios,
  });

  factory CalculoGuardado.desdeFila(Map<String, dynamic> f) {
    final r = (f['resultados'] as Map?)?.cast<String, dynamic>() ?? {};
    return CalculoGuardado(
      id: f['id'] as String,
      creadoEn: DateTime.parse(f['creado_en'] as String).toLocal(),
      tipo: TipoSistema.values.firstWhere(
        (t) => t.valorBd == f['tipo_sistema'],
        orElse: () => TipoSistema.onGrid,
      ),
      nombre: f['nombre'] as String?,
      energiaDiaKwh: _d(r['energia_dia_kwh']),
      numeroPaneles: (r['numero_paneles'] as num?)?.toInt() ?? 0,
      potenciaKw: _d(r['potencia_instalada_kw']),
      bateriaKwh: _d(r['bateria_kwh']),
      costoTotal: _d((r['costos'] as Map?)?['total']),
      ahorroMensual: _d(r['ahorro_mensual']),
      paybackAnios: (r['payback_anios'] as num?)?.toDouble(),
    );
  }

  final String id;
  final DateTime creadoEn;
  final TipoSistema tipo;
  final String? nombre;
  final double energiaDiaKwh;
  final int numeroPaneles;
  final double potenciaKw;
  final double bateriaKwh;
  final double costoTotal;
  final double ahorroMensual;
  final double? paybackAnios;

  String get titulo => (nombre?.trim().isNotEmpty ?? false)
      ? nombre!
      : 'Cálculo ${tipo.etiqueta.toLowerCase()}';
}

/// Un mes de la serie guardada.
class MesGuardado {
  const MesGuardado({
    required this.indice,
    required this.soh,
    required this.generacionKwh,
    required this.consumoKwh,
    required this.compradaKwh,
  });

  factory MesGuardado.desdeMapa(Map<String, dynamic> m) => MesGuardado(
    indice:
        ((m['anio'] as num?)?.toInt() ?? 0) * 12 +
        ((m['mes'] as num?)?.toInt() ?? 0),
    soh: _d(m['soh']),
    generacionKwh: _d(m['generacion_kwh']),
    consumoKwh: _d(m['consumo_kwh']),
    compradaKwh: _d(m['comprada_kwh']),
  );

  /// Meses desde el inicio (0 = primer mes).
  final int indice;
  final double soh;
  final double generacionKwh;
  final double consumoKwh;
  final double compradaKwh;
}

class SimulacionGuardada {
  const SimulacionGuardada({
    required this.id,
    required this.creadoEn,
    required this.politica,
    required this.calculoId,
    required this.capacidadKwh,
    required this.potenciaKw,
    required this.escenario,
    required this.zona,
    required this.sohFinal,
    required this.perdidaAnual,
    required this.compradaKwh,
    required this.limpiezas,
    required this.finDeVida,
    required this.sohAnual,
    required this.politicaAlternativa,
    required this.sohFinalAlternativa,
    required this.sohAnualAlternativa,
    required this.serie,
  });

  factory SimulacionGuardada.desdeFila(Map<String, dynamic> f) {
    final p = (f['parametros'] as Map?)?.cast<String, dynamic>() ?? {};
    final r = (f['resultados'] as Map?)?.cast<String, dynamic>() ?? {};
    final c = (r['comparacion'] as Map?)?.cast<String, dynamic>() ?? {};
    T porNombre<T extends Enum>(List<T> valores, Object? nombre, T defecto) =>
        valores.where((v) => v.name == nombre).firstOrNull ?? defecto;
    return SimulacionGuardada(
      id: f['id'] as String,
      creadoEn: DateTime.parse(f['creado_en'] as String).toLocal(),
      politica: porNombre(
        Politica.values,
        f['politica'],
        Politica.convencional,
      ),
      calculoId: f['calculo_id'] as String?,
      capacidadKwh: _d(p['capacidad_bateria_kwh']),
      potenciaKw: _d(p['potencia_panel_kw']),
      escenario: porNombre(
        EscenarioIrradiancia.values,
        p['escenario'],
        EscenarioIrradiancia.alta,
      ),
      zona: porNombre(ZonaClimatica.values, p['zona'], ZonaClimatica.mixta),
      sohFinal: _d(r['soh_final']),
      perdidaAnual: _d(r['perdida_anual']),
      compradaKwh: _d(r['energia_comprada_kwh']),
      limpiezas: (r['limpiezas'] as num?)?.toInt() ?? 0,
      finDeVida: r['fin_de_vida'] == true,
      sohAnual: _lista(r['soh_anual']),
      politicaAlternativa: porNombre(
        Politica.values,
        c['politica'],
        Politica.consciente,
      ),
      sohFinalAlternativa: _d(c['soh_final']),
      sohAnualAlternativa: _lista(c['soh_anual']),
      serie: [
        for (final m in (f['serie'] as List?) ?? [])
          MesGuardado.desdeMapa((m as Map).cast<String, dynamic>()),
      ],
    );
  }

  final String id;
  final DateTime creadoEn;
  final Politica politica;
  final String? calculoId;
  final double capacidadKwh;
  final double potenciaKw;
  final EscenarioIrradiancia escenario;
  final ZonaClimatica zona;
  final double sohFinal;
  final double perdidaAnual;
  final double compradaKwh;
  final int limpiezas;
  final bool finDeVida;
  final List<double> sohAnual;
  final Politica politicaAlternativa;
  final double sohFinalAlternativa;
  final List<double> sohAnualAlternativa;
  final List<MesGuardado> serie;
}

/// Filtro de fecha del historial.
enum FiltroFecha {
  todas('Todas las fechas'),
  semana('Últimos 7 días'),
  mes('Últimos 30 días'),
  anio('Este año');

  const FiltroFecha(this.etiqueta);

  final String etiqueta;

  bool incluye(DateTime fecha, DateTime ahora) => switch (this) {
    FiltroFecha.todas => true,
    FiltroFecha.semana => !fecha.isBefore(
      ahora.subtract(const Duration(days: 7)),
    ),
    FiltroFecha.mes => !fecha.isBefore(
      ahora.subtract(const Duration(days: 30)),
    ),
    FiltroFecha.anio => fecha.year == ahora.year,
  };
}

List<CalculoGuardado> filtrarCalculos(
  List<CalculoGuardado> calculos,
  FiltroFecha fecha,
  DateTime ahora,
) => [
  for (final c in calculos)
    if (fecha.incluye(c.creadoEn, ahora)) c,
];

/// `politica` nula = todas.
List<SimulacionGuardada> filtrarSimulaciones(
  List<SimulacionGuardada> simulaciones,
  FiltroFecha fecha,
  Politica? politica,
  DateTime ahora,
) => [
  for (final s in simulaciones)
    if (fecha.incluye(s.creadoEn, ahora) &&
        (politica == null || s.politica == politica))
      s,
];
