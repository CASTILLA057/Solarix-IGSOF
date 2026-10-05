import 'parametros.dart';
import 'simulador.dart';
import 'submodelos.dart';

/// Un mes de la serie que se guarda en Supabase (la serie horaria no se
/// guarda: 87 600 horas no caben razonablemente en el plan gratis).
class MesSimulado {
  const MesSimulado({
    required this.anio,
    required this.mes,
    required this.soh,
    required this.socMedio,
    required this.generacionKwh,
    required this.consumoKwh,
    required this.compradaKwh,
    required this.limpiezas,
  });

  /// Año de la simulación (0 = el primero) y mes del año (0–11).
  final int anio;
  final int mes;

  /// SoH al final del mes.
  final double soh;
  final double socMedio;
  final double generacionKwh;
  final double consumoKwh;
  final double compradaKwh;
  final int limpiezas;

  Map<String, dynamic> aMapa() => {
    'anio': anio,
    'mes': mes,
    'soh': soh,
    'soc_medio': socMedio,
    'generacion_kwh': generacionKwh,
    'consumo_kwh': consumoKwh,
    'comprada_kwh': compradaKwh,
    'limpiezas': limpiezas,
  };
}

/// Agrupa la serie diaria en meses (mismo calendario del modelo: años de
/// 365 días y meses de 30,42 días).
List<MesSimulado> serieMensual(List<DiaSimulado> dias) {
  final meses = <MesSimulado>[];
  var i = 0;
  while (i < dias.length) {
    final anio = dias[i].dia ~/ 365;
    final mes = mesDelDia(dias[i].dia % 365 + 1);
    var generacion = 0.0, consumo = 0.0, comprada = 0.0, soc = 0.0;
    var limpiezas = 0, n = 0;
    late DiaSimulado ultimo;
    while (i < dias.length &&
        dias[i].dia ~/ 365 == anio &&
        mesDelDia(dias[i].dia % 365 + 1) == mes) {
      final d = dias[i];
      generacion += d.generacionKwh;
      consumo += d.consumoKwh;
      comprada += d.compradaKwh;
      soc += d.socMedio;
      if (d.limpieza) limpiezas++;
      n++;
      ultimo = d;
      i++;
    }
    meses.add(
      MesSimulado(
        anio: anio,
        mes: mes,
        soh: ultimo.soh,
        socMedio: soc / n,
        generacionKwh: generacion,
        consumoKwh: consumo,
        compradaKwh: comprada,
        limpiezas: limpiezas,
      ),
    );
  }
  return meses;
}

/// Cifras principales de una corrida, listas para guardar.
Map<String, dynamic> resumenSimulacion(ResultadoSimulacion r) => {
  'soh_final': r.sohFinal,
  'perdida_anual': r.perdidaAnual,
  'energia_comprada_kwh': r.energiaCompradaKwh,
  'energia_generada_kwh': r.energiaGeneradaKwh,
  'consumo_kwh': r.consumoKwh,
  'limpiezas': r.limpiezas,
  'ciclos_equivalentes': r.ciclosEquivalentes,
  'horas_simuladas': r.horasSimuladas,
  'fin_de_vida': r.finDeVida,
  'soh_anual': r.sohAnual,
};

/// Simulación con la política elegida y, para comparar, con la otra política
/// usando la misma semilla (el mismo clima): las diferencias se deben solo a
/// la política.
class ComparacionSimulacion {
  const ComparacionSimulacion({
    required this.principal,
    required this.alternativa,
    this.referencia,
  });

  final ResultadoSimulacion principal;
  final ResultadoSimulacion alternativa;

  /// Batería convencional que no se degrada, con el mismo clima: la base
  /// para medir cuánta energía deja de aportar la batería que sí se
  /// degrada (Etapa 12).
  final ResultadoSimulacion? referencia;

  ParametrosSimulacion get parametros => principal.parametros;
  int get semilla => principal.semilla;

  ResultadoSimulacion get convencional =>
      parametros.politica == Politica.convencional ? principal : alternativa;
  ResultadoSimulacion get consciente =>
      parametros.politica == Politica.consciente ? principal : alternativa;

  /// Fila de `simulaciones_degradacion` (sin usuario ni cálculo de origen).
  /// [financiero]: impacto en la inversión del cálculo de origen, si lo hay.
  Map<String, dynamic> aFila({Map<String, dynamic>? financiero}) => {
    'politica': parametros.politica.name,
    'parametros': {...parametros.aMapa(), 'semilla': semilla},
    'resultados': {
      ...resumenSimulacion(principal),
      'comparacion': {
        'politica': alternativa.parametros.politica.name,
        ...resumenSimulacion(alternativa),
      },
      'financiero': ?financiero,
    },
    'serie': [for (final m in serieMensual(principal.dias)) m.aMapa()],
  };
}

/// Lo que se envía al isolate: parámetros y semilla.
typedef SolicitudSimulacion = ({ParametrosSimulacion parametros, int semilla});

/// Función de nivel superior para `compute()`: corre las dos políticas y la
/// referencia sin degradación (las tres con el mismo clima).
ComparacionSimulacion simularComparacion(SolicitudSimulacion s) {
  final otra = s.parametros.politica == Politica.convencional
      ? Politica.consciente
      : Politica.convencional;
  return ComparacionSimulacion(
    principal: simular(s.parametros, semilla: s.semilla),
    alternativa: simular(
      s.parametros.copiarCon(politica: otra),
      semilla: s.semilla,
      registrarDias: false,
    ),
    referencia: simular(
      s.parametros.copiarCon(
        politica: Politica.convencional,
        escalaDegradacion: 0,
      ),
      semilla: s.semilla,
      registrarDias: false,
    ),
  );
}
