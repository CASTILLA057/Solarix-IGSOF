/// Tipos y datos de entrada/salida de la calculadora solar.
library;

enum TipoSistema {
  onGrid(
    'Conectado a la red',
    'Ahorras en la factura y vendes los excedentes. Sin batería.',
    'on_grid',
  ),
  offGrid(
    'Aislado',
    'Sin red eléctrica: los paneles y la batería cubren todo el consumo.',
    'off_grid',
  ),
  hibrido(
    'Híbrido',
    'Conectado a la red, con batería para la noche y los cortes.',
    'hibrido',
  );

  const TipoSistema(this.etiqueta, this.descripcion, this.valorBd);

  final String etiqueta;
  final String descripcion;

  /// Valor de la columna `tipo_sistema` en Supabase.
  final String valorBd;

  bool get usaBateria => this != onGrid;
  bool get usaRed => this != offGrid;
}

enum QuimicaBateria {
  litio(
    'Litio (LiFePO₄)',
    profundidadDescarga: 0.9,
    vidaUtilAnios: 10,
    vidaCalendarioAnios: 15,
  ),
  plomo(
    'Plomo-ácido',
    profundidadDescarga: 0.5,
    vidaUtilAnios: 4,
    vidaCalendarioAnios: 6,
  );

  const QuimicaBateria(
    this.etiqueta, {
    required this.profundidadDescarga,
    required this.vidaUtilAnios,
    required this.vidaCalendarioAnios,
  });

  final String etiqueta;

  /// Fracción de la capacidad que se puede usar sin dañar la batería (DoD).
  final double profundidadDescarga;

  /// Vida típica: la que usa una cotización sin simular (garantía habitual
  /// del litio). La calculadora reemplaza la batería con ella; con la
  /// simulación, la reemplaza la vida por uso con el tope de
  /// [vidaCalendarioAnios] (Etapa 14).
  final int vidaUtilAnios;

  /// Años que dura aunque casi no se use (envejecimiento calendario). El
  /// modelo de degradación no lo incluye: es el tope de la vida simulada
  /// (Etapa 12).
  final int vidaCalendarioAnios;
}

enum ModoConsumo { equipos, factura }

/// Electrodoméstico del hogar.
class Equipo {
  const Equipo({
    required this.nombre,
    required this.potenciaW,
    this.horasDia = 0,
    this.cantidad = 1,
    this.kwhDia,
    this.factorArranque = 1,
  });

  factory Equipo.desdeMapa(Map<String, dynamic> m) => Equipo(
    nombre: m['nombre'] as String,
    potenciaW: (m['potencia_w'] as num).toDouble(),
    horasDia: (m['horas_dia'] as num?)?.toDouble() ?? 0,
    cantidad: m['cantidad'] as int? ?? 1,
    kwhDia: (m['kwh_dia'] as num?)?.toDouble(),
    factorArranque: (m['factor_arranque'] as num?)?.toDouble() ?? 1,
  );

  final String nombre;
  final double potenciaW;
  final double horasDia;
  final int cantidad;

  /// Consumo diario por unidad para equipos que funcionan por ciclos
  /// (nevera). Si se indica, reemplaza a `potenciaW × horasDia`.
  final double? kwhDia;

  /// Cuántas veces su potencia pide al arrancar (motores: 3 a 5).
  final double factorArranque;

  double get whDia => kwhDia != null
      ? kwhDia! * 1000 * cantidad
      : potenciaW * horasDia * cantidad;

  double get potenciaTotalW => potenciaW * cantidad;

  /// Potencia extra que pide una unidad al arrancar.
  double get extraArranqueW => potenciaW * (factorArranque - 1);

  Map<String, dynamic> aMapa() => {
    'nombre': nombre,
    'potencia_w': potenciaW,
    'horas_dia': horasDia,
    'cantidad': cantidad,
    'kwh_dia': kwhDia,
    'factor_arranque': factorArranque,
  };
}

/// Precios de referencia en COP (tabla `precios_referencia`), editables.
class Precios {
  const Precios({
    this.panelPorWp = 1050,
    this.inversorRedPorW = 900,
    this.inversorAisladoPorW = 1000,
    this.bateriaLitioPorKwh = 820000,
    this.bateriaPlomoPorKwh = 650000,
    this.controladorPorA = 12000,
    this.estructuraPorPanel = 300000,
    this.instalacionPorcentaje = 0.30,
    this.instalacionMinima = 1500000,
  });

  /// Valores de referencia de tiendas colombianas, octubre de 2026 (los
  /// mismos de la migración; fuentes en docs/FUENTES.md). La instalación
  /// incluye mano de obra, certificación RETIE y trámites con el operador.
  static const referencia = Precios();

  /// Construye desde las filas `clave → valor`; lo que falte usa la referencia.
  factory Precios.desdeFilas(Map<String, double> f) {
    const r = referencia;
    return Precios(
      panelPorWp: f['panel_por_wp'] ?? r.panelPorWp,
      inversorRedPorW: f['inversor_red_por_w'] ?? r.inversorRedPorW,
      inversorAisladoPorW: f['inversor_aislado_por_w'] ?? r.inversorAisladoPorW,
      bateriaLitioPorKwh: f['bateria_litio_por_kwh'] ?? r.bateriaLitioPorKwh,
      bateriaPlomoPorKwh: f['bateria_plomo_por_kwh'] ?? r.bateriaPlomoPorKwh,
      controladorPorA: f['controlador_por_a'] ?? r.controladorPorA,
      estructuraPorPanel: f['estructura_por_panel'] ?? r.estructuraPorPanel,
      instalacionPorcentaje:
          f['instalacion_porcentaje'] ?? r.instalacionPorcentaje,
      instalacionMinima: f['instalacion_minima'] ?? r.instalacionMinima,
    );
  }

  final double panelPorWp;
  final double inversorRedPorW;
  final double inversorAisladoPorW;
  final double bateriaLitioPorKwh;
  final double bateriaPlomoPorKwh;
  final double controladorPorA;
  final double estructuraPorPanel;

  /// Instalación como fracción del costo de equipos, con un mínimo.
  final double instalacionPorcentaje;
  final double instalacionMinima;

  double bateriaPorKwh(QuimicaBateria q) =>
      q == QuimicaBateria.litio ? bateriaLitioPorKwh : bateriaPlomoPorKwh;

  Map<String, dynamic> aMapa() => {
    'panel_por_wp': panelPorWp,
    'inversor_red_por_w': inversorRedPorW,
    'inversor_aislado_por_w': inversorAisladoPorW,
    'bateria_litio_por_kwh': bateriaLitioPorKwh,
    'bateria_plomo_por_kwh': bateriaPlomoPorKwh,
    'controlador_por_a': controladorPorA,
    'estructura_por_panel': estructuraPorPanel,
    'instalacion_porcentaje': instalacionPorcentaje,
    'instalacion_minima': instalacionMinima,
  };
}

/// Supuestos técnicos y financieros, todos editables.
class Supuestos {
  const Supuestos({
    this.rendimientoSistema = 0.78,
    this.eficienciaInversor = 0.9,
    this.diasAutonomia = 2,
    this.fraccionNocturna = 0.5,
    this.cobertura = 1,
    this.autoconsumo,
    this.costoComercializacion = 100,
    this.precioBolsa = 300,
    this.incrementoTarifa = 0.06,
    this.degradacionPaneles = 0.005,
    this.mantenimientoAnual = 0.01,
    this.tasaDescuento = 0.10,
    this.anios = 20,
    this.vidaCalendarioBateria,
    this.exclusionIva = false,
    this.tarifaRenta = 0,
  });

  /// Lee los supuestos guardados (`aMapa`); lo que falte en un cálculo
  /// viejo toma el valor por defecto.
  factory Supuestos.desdeMapa(Map<String, dynamic> m) {
    const d = Supuestos();
    return Supuestos(
      rendimientoSistema: _numeroOpc(
        m,
        'rendimiento_sistema',
        d.rendimientoSistema,
      ),
      eficienciaInversor: _numeroOpc(
        m,
        'eficiencia_inversor',
        d.eficienciaInversor,
      ),
      diasAutonomia: _numeroOpc(m, 'dias_autonomia', d.diasAutonomia),
      fraccionNocturna: _numeroOpc(m, 'fraccion_nocturna', d.fraccionNocturna),
      cobertura: _numeroOpc(m, 'cobertura', d.cobertura),
      autoconsumo: m['autoconsumo'] == null
          ? null
          : _numeroOpc(m, 'autoconsumo', 0),
      costoComercializacion: _numeroOpc(
        m,
        'costo_comercializacion',
        d.costoComercializacion,
      ),
      precioBolsa: _numeroOpc(m, 'precio_bolsa', d.precioBolsa),
      incrementoTarifa: _numeroOpc(m, 'incremento_tarifa', d.incrementoTarifa),
      degradacionPaneles: _numeroOpc(
        m,
        'degradacion_paneles',
        d.degradacionPaneles,
      ),
      mantenimientoAnual: _numeroOpc(
        m,
        'mantenimiento_anual',
        d.mantenimientoAnual,
      ),
      tasaDescuento: _numeroOpc(m, 'tasa_descuento', d.tasaDescuento),
      anios: _numeroOpc(m, 'anios', d.anios.toDouble()).round(),
      vidaCalendarioBateria: m['vida_calendario_bateria'] == null
          ? null
          : _numeroOpc(m, 'vida_calendario_bateria', 0),
      exclusionIva: m['exclusion_iva'] == true,
      tarifaRenta: _numeroOpc(m, 'tarifa_renta', 0),
    );
  }

  /// IVA general en Colombia.
  static const iva = 0.19;

  /// Parte de la inversión que se deduce de la renta (Ley 1715, art. 11).
  static const fraccionDeduccionRenta = 0.5;

  /// PR: pérdidas por temperatura, cableado, suciedad e inversor.
  final double rendimientoSistema;
  final double eficienciaInversor;

  /// Días que la batería cubre sin sol (solo sistema aislado).
  final double diasAutonomia;

  /// Parte del consumo que ocurre sin sol (sistema híbrido).
  final double fraccionNocturna;

  /// Parte del consumo que se quiere cubrir con paneles (red/híbrido).
  final double cobertura;

  /// Parte de la generación que se consume en la casa; si es `null` se usa
  /// el valor típico del tipo de sistema ([autoconsumoPorDefecto]).
  final double? autoconsumo;

  /// Componente de comercialización (Cv, COP/kWh) que el operador cobra por
  /// cada kWh de excedente permutado (CREG 174 de 2021, AGPE ≤ 100 kW).
  final double costoComercializacion;

  /// Precio (COP/kWh) del excedente que supera lo importado en el mes: se
  /// liquida a precio de bolsa (CREG 174 de 2021, art. 25).
  final double precioBolsa;
  final double incrementoTarifa;
  final double degradacionPaneles;

  /// Mantenimiento anual como fracción de la inversión.
  final double mantenimientoAnual;
  final double tasaDescuento;
  final int anios;

  /// Vida calendario de la batería (años); si es `null` se usa la típica de
  /// la química ([QuimicaBateria.vidaCalendarioAnios]).
  final double? vidaCalendarioBateria;

  /// Ley 1715 de 2014: compra de equipos y servicios sin IVA (requiere el
  /// certificado de la UPME).
  final bool exclusionIva;

  /// Tarifa marginal del impuesto de renta del usuario (0 si no declara).
  /// Con ella, la deducción de la Ley 1715 (50 % de la inversión) se toma el
  /// primer año: supone que la renta líquida alcanza.
  final double tarifaRenta;

  /// Los mismos supuestos con otro autoconsumo.
  Supuestos copiarCon({required double autoconsumo}) => Supuestos(
    rendimientoSistema: rendimientoSistema,
    eficienciaInversor: eficienciaInversor,
    diasAutonomia: diasAutonomia,
    fraccionNocturna: fraccionNocturna,
    cobertura: cobertura,
    autoconsumo: autoconsumo,
    costoComercializacion: costoComercializacion,
    precioBolsa: precioBolsa,
    incrementoTarifa: incrementoTarifa,
    degradacionPaneles: degradacionPaneles,
    mantenimientoAnual: mantenimientoAnual,
    tasaDescuento: tasaDescuento,
    anios: anios,
    vidaCalendarioBateria: vidaCalendarioBateria,
    exclusionIva: exclusionIva,
    tarifaRenta: tarifaRenta,
  );

  static double autoconsumoPorDefecto(TipoSistema tipo) => switch (tipo) {
    TipoSistema.onGrid => 0.6,
    TipoSistema.hibrido => 0.9,
    TipoSistema.offGrid => 1,
  };

  Map<String, dynamic> aMapa() => {
    'rendimiento_sistema': rendimientoSistema,
    'eficiencia_inversor': eficienciaInversor,
    'dias_autonomia': diasAutonomia,
    'fraccion_nocturna': fraccionNocturna,
    'cobertura': cobertura,
    'autoconsumo': autoconsumo,
    'costo_comercializacion': costoComercializacion,
    'precio_bolsa': precioBolsa,
    'incremento_tarifa': incrementoTarifa,
    'degradacion_paneles': degradacionPaneles,
    'mantenimiento_anual': mantenimientoAnual,
    'tasa_descuento': tasaDescuento,
    'anios': anios,
    'vida_calendario_bateria': vidaCalendarioBateria,
    'exclusion_iva': exclusionIva,
    'tarifa_renta': tarifaRenta,
  };
}

/// Clima del lugar según NASA POWER (climatología anual): lluvia
/// (`PRECTOTCORR`, mm/día), nubosidad (`CLOUD_AMT`, %) y temperatura media
/// a 2 m (`T2M`, °C). Sirve para ajustar la simulación al lugar (Etapa 12).
class ClimaLugar {
  const ClimaLugar({
    required this.lluviaMmDia,
    required this.nubosidadPct,
    required this.temperaturaC,
  });

  static ClimaLugar? desdeMapa(Object? m) => switch (m) {
    {
      'lluvia_mm_dia': final num l,
      'nubosidad_pct': final num n,
      'temperatura_c': final num t,
    } =>
      ClimaLugar(
        lluviaMmDia: l.toDouble(),
        nubosidadPct: n.toDouble(),
        temperaturaC: t.toDouble(),
      ),
    _ => null,
  };

  final double lluviaMmDia;
  final double nubosidadPct;
  final double temperaturaC;

  double get lluviaMmAnio => lluviaMmDia * 365;

  Map<String, dynamic> aMapa() => {
    'lluvia_mm_dia': lluviaMmDia,
    'nubosidad_pct': nubosidadPct,
    'temperatura_c': temperaturaC,
  };
}

/// Estrato socioeconómico de la vivienda (Etapa 12). Los estratos 1 a 3
/// reciben un subsidio sobre el consumo de subsistencia y los 5 y 6 pagan
/// una contribución de solidaridad sobre todo el consumo; el 4 paga el costo
/// del servicio. Porcentajes máximos de la ley (la factura muestra el que
/// aplica el operador): estrato 1 hasta 60 % y estrato 2 hasta 50 % (Ley
/// 1117 de 2006), estrato 3 hasta 15 % (Ley 142 de 1994, art. 99.6) y
/// contribución de 20 % (Ley 142, art. 89).
enum Estrato {
  uno(1, subsidio: 0.6),
  dos(2, subsidio: 0.5),
  tres(3, subsidio: 0.15),
  cuatro(4),
  cinco(5, contribucion: 0.2),
  seis(6, contribucion: 0.2);

  const Estrato(this.numero, {this.subsidio = 0, this.contribucion = 0});

  final int numero;

  /// Descuento sobre la tarifa en el consumo de subsistencia.
  final double subsidio;

  /// Recargo sobre la tarifa en todo el consumo.
  final double contribucion;

  String get etiqueta => 'Estrato $numero';
}

/// Consumo de subsistencia (kWh/mes): hasta ahí llega el subsidio de los
/// estratos 1 a 3. Resolución UPME 355 de 2004: 173 kWh/mes en municipios
/// por debajo de 1.000 m y 130 kWh/mes desde 1.000 m (altura de la cabecera
/// municipal según el IGAC).
abstract final class ConsumoSubsistencia {
  static const menosDe1000m = 173.0;
  static const desde1000m = 130.0;

  static double paraAltitud(double metros) =>
      metros >= 1000 ? desde1000m : menosDe1000m;
}

/// Todo lo que el usuario ingresa en la calculadora.
class EntradasCalculo {
  const EntradasCalculo({
    required this.tipo,
    required this.hsp,
    this.nombre = '',
    this.modo = ModoConsumo.equipos,
    this.equipos = const [],
    this.consumoFacturaKwhMes = 0,
    this.tarifaKwh = 890,
    this.gastoActualMensual = 0,
    this.ubicacion = '',
    this.potenciaPanelW = 550,
    this.quimica = QuimicaBateria.litio,
    this.supuestos = const Supuestos(),
    this.precios = Precios.referencia,
    this.clima,
    this.estrato = Estrato.cuatro,
    this.subsidioEstrato,
    this.consumoSubsistenciaKwh = ConsumoSubsistencia.menosDe1000m,
  });

  /// Lee las entradas guardadas (`aMapa`) para volver a abrir un cálculo del
  /// historial. Lo que falte en un cálculo viejo toma el valor por defecto;
  /// el tipo de sistema y las HSP son obligatorios. Lanza [FormatException]
  /// si los datos no se pueden leer.
  factory EntradasCalculo.desdeMapa(Map<String, dynamic> m) {
    try {
      const d = EntradasCalculo(tipo: TipoSistema.onGrid, hsp: 0);
      final tipo = TipoSistema.values.where((t) => t.valorBd == m['tipo']);
      if (tipo.isEmpty) throw const FormatException('Falta el tipo de sistema');
      final supuestos = m['supuestos'];
      final precios = m['precios'];
      return EntradasCalculo(
        tipo: tipo.first,
        hsp: _numero(m, 'hsp'),
        nombre: m['nombre'] as String? ?? '',
        modo: ModoConsumo.values.firstWhere(
          (x) => x.name == m['modo'],
          orElse: () => ModoConsumo.equipos,
        ),
        equipos: [
          for (final e in (m['equipos'] as List?) ?? const [])
            Equipo.desdeMapa((e as Map).cast<String, dynamic>()),
        ],
        consumoFacturaKwhMes: _numeroOpc(m, 'consumo_factura_kwh_mes', 0),
        tarifaKwh: _numeroOpc(m, 'tarifa_kwh', d.tarifaKwh),
        gastoActualMensual: _numeroOpc(m, 'gasto_actual_mensual', 0),
        ubicacion: m['ubicacion'] as String? ?? '',
        potenciaPanelW: _numeroOpc(m, 'potencia_panel_w', d.potenciaPanelW),
        quimica: QuimicaBateria.values.firstWhere(
          (q) => q.name == m['quimica'],
          orElse: () => QuimicaBateria.litio,
        ),
        supuestos: supuestos is Map
            ? Supuestos.desdeMapa(supuestos.cast<String, dynamic>())
            : const Supuestos(),
        precios: precios is Map
            ? Precios.desdeFilas({
                for (final e in precios.entries)
                  if (e.value is num)
                    e.key as String: (e.value as num).toDouble(),
              })
            : Precios.referencia,
        clima: ClimaLugar.desdeMapa(m['clima']),
        estrato: Estrato.values.firstWhere(
          (e) => e.numero == m['estrato'],
          orElse: () => Estrato.cuatro,
        ),
        subsidioEstrato: m['subsidio_estrato'] == null
            ? null
            : _numeroOpc(m, 'subsidio_estrato', 0),
        consumoSubsistenciaKwh: _numeroOpc(
          m,
          'consumo_subsistencia_kwh',
          d.consumoSubsistenciaKwh,
        ),
      );
    } on TypeError catch (e) {
      throw FormatException('Entradas guardadas ilegibles: $e');
    }
  }

  final String nombre;
  final TipoSistema tipo;
  final ModoConsumo modo;
  final List<Equipo> equipos;
  final double consumoFacturaKwhMes;

  /// COP por kWh de la red (sistemas con red): el costo del servicio, sin
  /// subsidio ni contribución (lo que paga el estrato 4).
  final double tarifaKwh;

  /// Estrato de la vivienda: subsidio o contribución sobre [tarifaKwh].
  final Estrato estrato;

  /// Subsidio que muestra la factura (fracción); `null` = el máximo legal
  /// del estrato. El operador puede aplicar uno menor.
  final double? subsidioEstrato;

  /// Subsidio con el que se calcula: el de la factura o el máximo legal; 0
  /// en los estratos sin subsidio.
  double get subsidioAplicado =>
      estrato.subsidio == 0 ? 0 : subsidioEstrato ?? estrato.subsidio;

  /// Consumo de subsistencia del municipio (kWh/mes, [ConsumoSubsistencia]).
  final double consumoSubsistenciaKwh;

  /// Gasto mensual actual en energía sin red (combustible, velas…), en COP.
  final double gastoActualMensual;

  /// Horas solares pico del lugar (kWh/m²/día).
  final double hsp;

  /// Ciudad o "Mi ubicación", solo informativo.
  final String ubicacion;
  final double potenciaPanelW;
  final QuimicaBateria quimica;
  final Supuestos supuestos;
  final Precios precios;

  /// Clima del lugar (ciudad de la lista o "Mi ubicación"); `null` con HSP
  /// escritas a mano.
  final ClimaLugar? clima;

  /// Las mismas entradas con otro tipo de sistema y otros supuestos.
  EntradasCalculo copiarCon({
    required TipoSistema tipo,
    required Supuestos supuestos,
  }) => EntradasCalculo(
    tipo: tipo,
    hsp: hsp,
    nombre: nombre,
    modo: modo,
    equipos: equipos,
    consumoFacturaKwhMes: consumoFacturaKwhMes,
    tarifaKwh: tarifaKwh,
    gastoActualMensual: gastoActualMensual,
    ubicacion: ubicacion,
    potenciaPanelW: potenciaPanelW,
    quimica: quimica,
    supuestos: supuestos,
    precios: precios,
    clima: clima,
    estrato: estrato,
    subsidioEstrato: subsidioEstrato,
    consumoSubsistenciaKwh: consumoSubsistenciaKwh,
  );

  /// Vida calendario de la batería: la editada o la típica de la química.
  double get vidaCalendarioBateria =>
      supuestos.vidaCalendarioBateria ?? quimica.vidaCalendarioAnios.toDouble();

  Map<String, dynamic> aMapa() => {
    'nombre': nombre,
    'tipo': tipo.valorBd,
    'modo': modo.name,
    'equipos': [for (final e in equipos) e.aMapa()],
    'consumo_factura_kwh_mes': consumoFacturaKwhMes,
    'tarifa_kwh': tarifaKwh,
    'estrato': estrato.numero,
    'subsidio_estrato': subsidioEstrato,
    'consumo_subsistencia_kwh': consumoSubsistenciaKwh,
    'gasto_actual_mensual': gastoActualMensual,
    'hsp': hsp,
    'ubicacion': ubicacion,
    'potencia_panel_w': potenciaPanelW,
    'quimica': quimica.name,
    'supuestos': supuestos.aMapa(),
    'precios': precios.aMapa(),
    'clima': clima?.aMapa(),
  };
}

/// Un año del flujo de caja.
class AnioFlujo {
  const AnioFlujo({
    required this.anio,
    required this.ahorro,
    required this.mantenimiento,
    required this.reemplazoBateria,
    required this.neto,
    required this.acumulado,
    required this.acumuladoDescontado,
    this.valorResidual = 0,
    this.beneficioTributario = 0,
  });

  factory AnioFlujo.desdeMapa(Map<String, dynamic> m) => AnioFlujo(
    anio: _numero(m, 'anio').round(),
    ahorro: _numero(m, 'ahorro'),
    mantenimiento: _numero(m, 'mantenimiento'),
    reemplazoBateria: _numero(m, 'reemplazo_bateria'),
    valorResidual: _numeroOpc(m, 'valor_residual', 0),
    beneficioTributario: _numeroOpc(m, 'beneficio_tributario', 0),
    neto: _numero(m, 'neto'),
    acumulado: _numero(m, 'acumulado'),
    acumuladoDescontado: _numero(m, 'acumulado_descontado'),
  );

  final int anio;
  final double ahorro;
  final double mantenimiento;
  final double reemplazoBateria;

  /// Solo el último año: parte de la batería en uso que no se alcanzó a
  /// usar dentro del horizonte (se suma como ingreso, Etapa 12).
  final double valorResidual;

  /// Solo el primer año: impuesto de renta que se deja de pagar por la
  /// deducción de la Ley 1715.
  final double beneficioTributario;
  final double neto;
  final double acumulado;
  final double acumuladoDescontado;

  Map<String, dynamic> aMapa() => {
    'anio': anio,
    'ahorro': ahorro,
    'mantenimiento': mantenimiento,
    'reemplazo_bateria': reemplazoBateria,
    'valor_residual': valorResidual,
    'beneficio_tributario': beneficioTributario,
    'neto': neto,
    'acumulado': acumulado,
    'acumulado_descontado': acumuladoDescontado,
  };
}

class Costos {
  const Costos({
    required this.paneles,
    required this.baterias,
    required this.inversor,
    required this.controlador,
    required this.estructura,
    required this.instalacion,
    this.ivaExcluido = 0,
  });

  factory Costos.desdeMapa(Map<String, dynamic> m) => Costos(
    paneles: _numero(m, 'paneles'),
    baterias: _numero(m, 'baterias'),
    inversor: _numero(m, 'inversor'),
    controlador: _numero(m, 'controlador'),
    estructura: _numero(m, 'estructura'),
    instalacion: _numero(m, 'instalacion'),
    ivaExcluido: _numeroOpc(m, 'iva_excluido', 0),
  );

  final double paneles;
  final double baterias;
  final double inversor;
  final double controlador;
  final double estructura;
  final double instalacion;

  /// IVA que no se paga con la exclusión de la Ley 1715 (los demás valores
  /// ya lo descuentan).
  final double ivaExcluido;

  double get equipos =>
      paneles + baterias + inversor + controlador + estructura;
  double get total => equipos + instalacion;

  Map<String, dynamic> aMapa() => {
    'paneles': paneles,
    'baterias': baterias,
    'inversor': inversor,
    'controlador': controlador,
    'estructura': estructura,
    'instalacion': instalacion,
    'iva_excluido': ivaExcluido,
    'total': total,
  };
}

/// Resultado completo de la calculadora.
class ResultadoCalculo {
  const ResultadoCalculo({
    required this.energiaDiaKwh,
    required this.numeroPaneles,
    required this.potenciaInstaladaKw,
    required this.generacionMesKwh,
    required this.bateriaKwh,
    required this.voltajeSistema,
    required this.inversorW,
    required this.controladorA,
    required this.costos,
    required this.autoconsumoMesKwh,
    required this.excedenteMesKwh,
    this.excedentePermutadoMesKwh = 0,
    this.excedenteVendidoMesKwh = 0,
    required this.ahorroMensual,
    required this.flujo,
    required this.vpn,
    required this.paybackAnios,
    required this.paybackDescontadoAnios,
  });

  /// Lee los resultados guardados (`aMapa`) para volver a abrir un cálculo
  /// del historial. Los campos que se agregaron después de la Etapa 3
  /// (excedentes, IVA, beneficio tributario) valen 0 en un cálculo viejo.
  /// Lanza [FormatException] si los datos no se pueden leer.
  factory ResultadoCalculo.desdeMapa(Map<String, dynamic> m) {
    try {
      return ResultadoCalculo(
        energiaDiaKwh: _numero(m, 'energia_dia_kwh'),
        numeroPaneles: _numero(m, 'numero_paneles').round(),
        potenciaInstaladaKw: _numero(m, 'potencia_instalada_kw'),
        generacionMesKwh: _numero(m, 'generacion_mes_kwh'),
        bateriaKwh: _numero(m, 'bateria_kwh'),
        voltajeSistema: _numero(m, 'voltaje_sistema').round(),
        inversorW: _numero(m, 'inversor_w').round(),
        controladorA: _numero(m, 'controlador_a').round(),
        costos: Costos.desdeMapa((m['costos'] as Map).cast<String, dynamic>()),
        autoconsumoMesKwh: _numero(m, 'autoconsumo_mes_kwh'),
        excedenteMesKwh: _numero(m, 'excedente_mes_kwh'),
        excedentePermutadoMesKwh: _numeroOpc(
          m,
          'excedente_permutado_mes_kwh',
          0,
        ),
        excedenteVendidoMesKwh: _numeroOpc(m, 'excedente_vendido_mes_kwh', 0),
        ahorroMensual: _numero(m, 'ahorro_mensual'),
        flujo: [
          for (final a in m['flujo'] as List)
            AnioFlujo.desdeMapa((a as Map).cast<String, dynamic>()),
        ],
        vpn: _numero(m, 'vpn'),
        paybackAnios: (m['payback_anios'] as num?)?.toDouble(),
        paybackDescontadoAnios: (m['payback_descontado_anios'] as num?)
            ?.toDouble(),
      );
    } on TypeError catch (e) {
      throw FormatException('Resultados guardados ilegibles: $e');
    }
  }

  final double energiaDiaKwh;
  final int numeroPaneles;
  final double potenciaInstaladaKw;
  final double generacionMesKwh;
  final double bateriaKwh;
  final int voltajeSistema;
  final int inversorW;

  /// 0 si el sistema no lleva controlador (conectado a la red).
  final int controladorA;
  final Costos costos;
  final double autoconsumoMesKwh;
  final double excedenteMesKwh;

  /// Parte del excedente que se permuta contra lo importado en el mes y la
  /// que se vende a precio de bolsa (CREG 174 de 2021).
  final double excedentePermutadoMesKwh;
  final double excedenteVendidoMesKwh;

  /// Ahorro del primer año, por mes.
  final double ahorroMensual;
  final List<AnioFlujo> flujo;
  final double vpn;

  /// `null` si la inversión no se recupera dentro del horizonte.
  final double? paybackAnios;
  final double? paybackDescontadoAnios;

  double get energiaMesKwh => energiaDiaKwh * 30;
  double get bateriaAh =>
      voltajeSistema == 0 ? 0 : bateriaKwh * 1000 / voltajeSistema;
  double get ahorroTotal => flujo.fold(0, (s, a) => s + a.ahorro);
  double get gastosTotales =>
      costos.total +
      flujo.fold<double>(0, (s, a) => s + a.mantenimiento + a.reemplazoBateria);

  /// Valor de la batería que sigue útil al final del horizonte.
  double get valorResidual => flujo.fold(0, (s, a) => s + a.valorResidual);

  /// Impuesto de renta que se deja de pagar (Ley 1715).
  double get beneficioRenta =>
      flujo.fold(0, (s, a) => s + a.beneficioTributario);

  Map<String, dynamic> aMapa() => {
    'energia_dia_kwh': energiaDiaKwh,
    'numero_paneles': numeroPaneles,
    'potencia_instalada_kw': potenciaInstaladaKw,
    'generacion_mes_kwh': generacionMesKwh,
    'bateria_kwh': bateriaKwh,
    'voltaje_sistema': voltajeSistema,
    'inversor_w': inversorW,
    'controlador_a': controladorA,
    'costos': costos.aMapa(),
    'autoconsumo_mes_kwh': autoconsumoMesKwh,
    'excedente_mes_kwh': excedenteMesKwh,
    'excedente_permutado_mes_kwh': excedentePermutadoMesKwh,
    'excedente_vendido_mes_kwh': excedenteVendidoMesKwh,
    'ahorro_mensual': ahorroMensual,
    'beneficio_renta': beneficioRenta,
    'vpn': vpn,
    'payback_anios': paybackAnios,
    'payback_descontado_anios': paybackDescontadoAnios,
    'flujo': [for (final a in flujo) a.aMapa()],
  };
}

/// Número obligatorio de un mapa guardado; [FormatException] si falta o no es
/// un número.
double _numero(Map<String, dynamic> m, String clave) {
  final v = m[clave];
  if (v is num) return v.toDouble();
  throw FormatException('Dato guardado ilegible: "$clave" = $v');
}

/// Número opcional de un mapa guardado: [defecto] si falta (cálculo viejo);
/// [FormatException] si está y no es un número.
double _numeroOpc(Map<String, dynamic> m, String clave, double defecto) {
  final v = m[clave];
  if (v == null) return defecto;
  if (v is num) return v.toDouble();
  throw FormatException('Dato guardado ilegible: "$clave" = $v');
}
