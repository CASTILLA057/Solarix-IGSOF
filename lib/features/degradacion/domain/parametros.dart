/// Parámetros del modelo SimDeg-FV, portado del modelo de NetLogo
/// `docs/referencia/DegradacionBateriasSistemasFotovoltaicos.nlogox`.
/// Los nombres en los comentarios son los del código de NetLogo.
library;

/// `politica`: convencional usa la batería hasta `carga-maxima`; consciente
/// no carga por encima de 95 % y limita la corriente a 0,16 C.
enum Politica { convencional, consciente }

/// `escenario-irradiancia`: irradiancia máxima (W/m²) y temperatura media (°C).
enum EscenarioIrradiancia {
  baja(50, 22),
  media(560, 24),
  alta(800, 27);

  const EscenarioIrradiancia(this.irradianciaMaxima, this.temperaturaMedia);

  final double irradianciaMaxima;
  final double temperaturaMedia;
}

/// `zona`: multiplica la lluvia, la nubosidad y el polvo.
enum ZonaClimatica {
  mixta(1, 1, 1),
  muySoleada(0.3, 0.6, 1.5),
  muyNublada(1.3, 1.35, 0.7),
  lluviosa(2, 1.2, 0.4),
  polvorienta(0.6, 0.9, 4);

  const ZonaClimatica(this.factorLluvia, this.factorNubes, this.factorPolvo);

  final double factorLluvia;
  final double factorNubes;
  final double factorPolvo;
}

/// Constantes fijadas en el `setup` del modelo.
abstract final class Constantes {
  static const horasPorAnio = 8760;
  static const sohUmbral = 80.0;
  static const eficiencia = 0.95; // eta
  static const kPolvo = 0.003; // pérdida de potencia por gramo de polvo
  static const coefTemp = 0.004; // pérdida de potencia por °C sobre 25
  static const socMaxConsciente = 95.0;
  static const cMaxConsciente = 0.16;
  static const nubosidadInicial = 0.3;
  static const socInicial = 50.0;
}

class ParametrosSimulacion {
  const ParametrosSimulacion({
    this.capacidadBateriaKwh = 10,
    this.potenciaPanelKw = 5,
    this.tasaCMaxima = 0.5,
    this.cargaMinima = 20,
    this.cargaMaxima = 100,
    this.tasaPolvo = 0.036,
    this.umbralLimpieza = 10,
    this.politica = Politica.convencional,
    this.escenario = EscenarioIrradiancia.alta,
    this.zona = ZonaClimatica.mixta,
    this.escalaDegradacion = 0.0000078,
    this.exponenteDegradacion = 1.1,
    this.pesoCorriente = 2,
    this.pesoVariacionCarga = 1,
    this.factorConsumo = 1,
    this.irradianciaMaximaLugar,
    this.temperaturaMediaLugar,
    this.anios = 10,
  });

  /// `capacidad-bateria` (kWh nominales).
  final double capacidadBateriaKwh;

  /// `potencia-panel` (kW pico).
  final double potenciaPanelKw;

  /// `tasa-c-maxima` (1/h).
  final double tasaCMaxima;

  /// `carga-minima` y `carga-maxima` (% de SOC).
  final double cargaMinima;
  final double cargaMaxima;

  /// `tasa-polvo` (g/h).
  final double tasaPolvo;

  /// `umbral-limpieza` (% de pérdida de potencia por polvo).
  final double umbralLimpieza;
  final Politica politica;
  final EscenarioIrradiancia escenario;
  final ZonaClimatica zona;

  /// Ecuación 5: `escala-degradacion` (α), `exponente-degradacion` (β),
  /// `peso-corriente` (γ) y `peso-variacion-carga` (δ), calibrados en la
  /// etapa 14 del modelo.
  final double escalaDegradacion;
  final double exponenteDegradacion;
  final double pesoCorriente;
  final double pesoVariacionCarga;

  /// Multiplica el consumo de la casa. 1 = perfil de NetLogo (≈ 20 kWh/día);
  /// en la Etapa 6 se ajusta al consumo calculado en la calculadora.
  final double factorConsumo;

  /// Irradiancia máxima (W/m²) y temperatura media (°C) de un lugar
  /// concreto (Etapa 12). Si son `null` se usan las del escenario de
  /// NetLogo. Solo cambian las entradas del modelo, no sus ecuaciones.
  final double? irradianciaMaximaLugar;
  final double? temperaturaMediaLugar;

  double get irradianciaMaxima =>
      irradianciaMaximaLugar ?? escenario.irradianciaMaxima;
  double get temperaturaMedia =>
      temperaturaMediaLugar ?? escenario.temperaturaMedia;

  /// Es una configuración de NetLogo (sin ajustes de lugar).
  bool get esDeNetLogo =>
      irradianciaMaximaLugar == null && temperaturaMediaLugar == null;

  /// Horizonte en años (NetLogo: 10 años = 87 600 horas).
  final int anios;

  int get horizonteHoras => anios * Constantes.horasPorAnio;

  ParametrosSimulacion copiarCon({
    double? capacidadBateriaKwh,
    double? potenciaPanelKw,
    double? tasaCMaxima,
    double? cargaMinima,
    double? cargaMaxima,
    double? tasaPolvo,
    double? umbralLimpieza,
    Politica? politica,
    EscenarioIrradiancia? escenario,
    ZonaClimatica? zona,
    double? escalaDegradacion,
    double? exponenteDegradacion,
    double? pesoCorriente,
    double? pesoVariacionCarga,
    double? factorConsumo,
    int? anios,
  }) => ParametrosSimulacion(
    capacidadBateriaKwh: capacidadBateriaKwh ?? this.capacidadBateriaKwh,
    potenciaPanelKw: potenciaPanelKw ?? this.potenciaPanelKw,
    tasaCMaxima: tasaCMaxima ?? this.tasaCMaxima,
    cargaMinima: cargaMinima ?? this.cargaMinima,
    cargaMaxima: cargaMaxima ?? this.cargaMaxima,
    tasaPolvo: tasaPolvo ?? this.tasaPolvo,
    umbralLimpieza: umbralLimpieza ?? this.umbralLimpieza,
    politica: politica ?? this.politica,
    escenario: escenario ?? this.escenario,
    zona: zona ?? this.zona,
    escalaDegradacion: escalaDegradacion ?? this.escalaDegradacion,
    exponenteDegradacion: exponenteDegradacion ?? this.exponenteDegradacion,
    pesoCorriente: pesoCorriente ?? this.pesoCorriente,
    pesoVariacionCarga: pesoVariacionCarga ?? this.pesoVariacionCarga,
    factorConsumo: factorConsumo ?? this.factorConsumo,
    irradianciaMaximaLugar: irradianciaMaximaLugar,
    temperaturaMediaLugar: temperaturaMediaLugar,
    anios: anios ?? this.anios,
  );

  Map<String, dynamic> aMapa() => {
    'capacidad_bateria_kwh': capacidadBateriaKwh,
    'potencia_panel_kw': potenciaPanelKw,
    'tasa_c_maxima': tasaCMaxima,
    'carga_minima': cargaMinima,
    'carga_maxima': cargaMaxima,
    'tasa_polvo': tasaPolvo,
    'umbral_limpieza': umbralLimpieza,
    'politica': politica.name,
    'escenario': escenario.name,
    'zona': zona.name,
    'escala_degradacion': escalaDegradacion,
    'exponente_degradacion': exponenteDegradacion,
    'peso_corriente': pesoCorriente,
    'peso_variacion_carga': pesoVariacionCarga,
    'factor_consumo': factorConsumo,
    'irradiancia_maxima_lugar': irradianciaMaximaLugar,
    'temperatura_media_lugar': temperaturaMediaLugar,
    'anios': anios,
  };
}
