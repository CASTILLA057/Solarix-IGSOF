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

  /// Años típicos antes de reemplazarla (hasta tener la simulación, Etapa 6).
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
  /// mismos de la migración; fuentes en docs/BITACORA.md). La instalación
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
  });

  final String nombre;
  final TipoSistema tipo;
  final ModoConsumo modo;
  final List<Equipo> equipos;
  final double consumoFacturaKwhMes;

  /// COP por kWh de la red (sistemas con red).
  final double tarifaKwh;

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
    'gasto_actual_mensual': gastoActualMensual,
    'hsp': hsp,
    'ubicacion': ubicacion,
    'potencia_panel_w': potenciaPanelW,
    'quimica': quimica.name,
    'supuestos': supuestos.aMapa(),
    'precios': precios.aMapa(),
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
