import 'dart:math' as math;

import 'modelos.dart';

/// Fórmulas de la calculadora solar (Etapa 3). Funciones puras: no dependen
/// de Flutter ni de Supabase, así se prueban de forma aislada.

/// Tamaños comerciales de inversor (W) y de controlador de carga (A).
const tamanosInversorW = [
  300, 500, 1000, 1500, 2000, 3000, 4000, 5000, 6000, 8000, 10000, 12000, //
  15000, 20000,
];
const tamanosControladorA = [10, 20, 30, 40, 50, 60, 80, 100];

/// Consumo diario en Wh, desde los equipos o desde la factura.
double energiaDiariaWh(EntradasCalculo e) => switch (e.modo) {
  ModoConsumo.equipos => e.equipos.fold(0, (s, eq) => s + eq.whDia),
  ModoConsumo.factura => e.consumoFacturaKwhMes * 1000 / 30,
};

/// Número de paneles: `ceil(E_cubrir / (HSP · PR) / W_panel)`, mínimo 1.
int numeroPaneles({
  required double energiaWh,
  required double hsp,
  required double rendimiento,
  required double potenciaPanelW,
}) {
  if (energiaWh <= 0) return 0;
  final potenciaNecesariaW = energiaWh / (hsp * rendimiento);
  return math.max(1, (potenciaNecesariaW / potenciaPanelW).ceil());
}

/// Voltaje del banco según el consumo diario: 12 V hasta 1,5 kWh/día,
/// 24 V hasta 4 kWh/día y 48 V por encima.
int voltajeSistema(double energiaDiaWh) {
  if (energiaDiaWh < 1500) return 12;
  if (energiaDiaWh < 4000) return 24;
  return 48;
}

/// Capacidad nominal de batería en Wh: `E_cubrir · días / (DoD · η_inv)`.
///
/// Aislado: cubre todo el consumo durante los días de autonomía. Híbrido:
/// cubre la parte nocturna de un día. Conectado a la red: sin batería.
double capacidadBateriaWh({
  required TipoSistema tipo,
  required double energiaDiaWh,
  required QuimicaBateria quimica,
  required Supuestos supuestos,
}) {
  final (energiaCubrir, dias) = switch (tipo) {
    TipoSistema.onGrid => (0.0, 0.0),
    TipoSistema.offGrid => (energiaDiaWh, supuestos.diasAutonomia),
    TipoSistema.hibrido => (energiaDiaWh * supuestos.fraccionNocturna, 1.0),
  };
  return energiaCubrir *
      dias /
      (quimica.profundidadDescarga * supuestos.eficienciaInversor);
}

/// Primer tamaño comercial mayor o igual al requerido.
int tamanoComercial(double requerido, List<int> tamanos) {
  for (final t in tamanos) {
    if (t >= requerido) return t;
  }
  final paso = tamanos.last;
  return (requerido / paso).ceil() * paso;
}

/// Potencia del inversor (W).
///
/// - Conectado a la red: igual a la potencia de los paneles.
/// - Con batería y lista de equipos: el mayor entre todo encendido · 1,25 y
///   todo encendido más el arranque del motor más exigente.
/// - Con batería y consumo de factura: pico estimado de 3 veces el consumo
///   medio por hora, · 1,25.
int potenciaInversorW({
  required EntradasCalculo entradas,
  required double potenciaPanelesW,
  required double energiaDiaWh,
}) {
  if (entradas.tipo == TipoSistema.onGrid) {
    return tamanoComercial(potenciaPanelesW, tamanosInversorW);
  }
  final double requerido;
  if (entradas.modo == ModoConsumo.equipos && entradas.equipos.isNotEmpty) {
    final continuo = entradas.equipos.fold<double>(
      0,
      (s, e) => s + e.potenciaTotalW,
    );
    final mayorArranque = entradas.equipos
        .map((e) => e.extraArranqueW)
        .reduce(math.max);
    requerido = math.max(continuo * 1.25, continuo + mayorArranque);
  } else {
    requerido = energiaDiaWh / 24 * 3 * 1.25;
  }
  return tamanoComercial(requerido, tamanosInversorW);
}

/// Corriente del controlador de carga (A): `P_paneles / V · 1,25`.
/// Los sistemas conectados a la red no lo llevan (el inversor de red trae
/// su propio seguidor del punto de máxima potencia).
int corrienteControladorA({
  required TipoSistema tipo,
  required double potenciaPanelesW,
  required int voltaje,
}) {
  if (!tipo.usaBateria || potenciaPanelesW <= 0) return 0;
  return tamanoComercial(
    potenciaPanelesW / voltaje * 1.25,
    tamanosControladorA,
  );
}

Costos calcularCostos({
  required EntradasCalculo entradas,
  required int paneles,
  required double bateriaKwh,
  required int inversorW,
  required int controladorA,
}) {
  final p = entradas.precios;
  final costoPaneles = paneles * entradas.potenciaPanelW * p.panelPorWp;
  final costoBaterias = bateriaKwh * p.bateriaPorKwh(entradas.quimica);
  final costoInversor =
      inversorW *
      (entradas.tipo == TipoSistema.onGrid
          ? p.inversorRedPorW
          : p.inversorAisladoPorW);
  final costoControlador = controladorA * p.controladorPorA;
  final costoEstructura = paneles * p.estructuraPorPanel;
  final equipos =
      costoPaneles +
      costoBaterias +
      costoInversor +
      costoControlador +
      costoEstructura;
  return Costos(
    paneles: costoPaneles,
    baterias: costoBaterias,
    inversor: costoInversor,
    controlador: costoControlador,
    estructura: costoEstructura,
    instalacion: equipos <= 0
        ? 0
        : math.max(equipos * p.instalacionPorcentaje, p.instalacionMinima),
  );
}

/// Ahorro del primer mes y reparto de la generación (kWh/mes).
({double ahorro, double autoconsumo, double excedente}) ahorroMensual({
  required EntradasCalculo entradas,
  required double generacionMesKwh,
  required double consumoMesKwh,
}) {
  if (entradas.tipo == TipoSistema.offGrid) {
    // Sin red: se ahorra lo que hoy se gasta en energía (combustible, etc.).
    return (
      ahorro: entradas.gastoActualMensual,
      autoconsumo: math.min(generacionMesKwh, consumoMesKwh),
      excedente: 0,
    );
  }
  final fraccion =
      entradas.supuestos.autoconsumo ??
      Supuestos.autoconsumoPorDefecto(entradas.tipo);
  final autoconsumo = math.min(generacionMesKwh * fraccion, consumoMesKwh);
  final excedente = generacionMesKwh - autoconsumo;
  final tarifa = entradas.tarifaKwh;
  return (
    ahorro:
        autoconsumo * tarifa +
        excedente * tarifa * entradas.supuestos.factorExcedente,
    autoconsumo: autoconsumo,
    excedente: excedente,
  );
}

/// Flujo de caja anual: el ahorro crece con la tarifa y cae con la pérdida
/// de rendimiento de los paneles; se restan el mantenimiento y los
/// reemplazos de batería (cada `vidaBateria` años, sin contar el último).
List<AnioFlujo> flujoDeCaja({
  required double inversion,
  required double ahorroAnualInicial,
  required double costoBaterias,
  required int vidaBateriaAnios,
  required Supuestos supuestos,
}) {
  final flujo = <AnioFlujo>[];
  var acumulado = -inversion;
  var acumuladoDescontado = -inversion;
  for (var t = 1; t <= supuestos.anios; t++) {
    final ahorro =
        ahorroAnualInicial *
        math.pow(1 + supuestos.incrementoTarifa, t - 1) *
        math.pow(1 - supuestos.degradacionPaneles, t - 1);
    final mantenimiento = inversion * supuestos.mantenimientoAnual;
    final reemplazo =
        costoBaterias > 0 &&
            vidaBateriaAnios > 0 &&
            t % vidaBateriaAnios == 0 &&
            t < supuestos.anios
        ? costoBaterias
        : 0.0;
    final neto = ahorro - mantenimiento - reemplazo;
    acumulado += neto;
    acumuladoDescontado += neto / math.pow(1 + supuestos.tasaDescuento, t);
    flujo.add(
      AnioFlujo(
        anio: t,
        ahorro: ahorro,
        mantenimiento: mantenimiento,
        reemplazoBateria: reemplazo,
        neto: neto,
        acumulado: acumulado,
        acumuladoDescontado: acumuladoDescontado,
      ),
    );
  }
  return flujo;
}

/// Años (con fracción) hasta que el acumulado deja de ser negativo, o `null`
/// si no se recupera. Interpola linealmente dentro del año en que cruza.
double? recuperacionAnios(double inversion, List<double> acumulados) {
  var previo = -inversion;
  for (var i = 0; i < acumulados.length; i++) {
    final actual = acumulados[i];
    if (actual >= 0) {
      final paso = actual - previo;
      return paso <= 0 ? i + 1.0 : i + (-previo / paso);
    }
    previo = actual;
  }
  return null;
}

/// Ejecuta el cálculo completo.
///
/// `vidaBateriaAnios` reemplaza la vida típica de la química en el flujo de
/// caja; en la Etapa 6 viene de la simulación de degradación (años hasta que
/// el SoH llega al 80 %).
ResultadoCalculo calcular(EntradasCalculo e, {int? vidaBateriaAnios}) {
  final s = e.supuestos;
  final energiaDiaWh = energiaDiariaWh(e);
  final cobertura = e.tipo == TipoSistema.offGrid ? 1.0 : s.cobertura;
  final paneles = numeroPaneles(
    energiaWh: energiaDiaWh * cobertura,
    hsp: e.hsp,
    rendimiento: s.rendimientoSistema,
    potenciaPanelW: e.potenciaPanelW,
  );
  final potenciaPanelesW = paneles * e.potenciaPanelW;
  final generacionMesKwh =
      potenciaPanelesW / 1000 * e.hsp * s.rendimientoSistema * 30;
  final bateriaKwh =
      capacidadBateriaWh(
        tipo: e.tipo,
        energiaDiaWh: energiaDiaWh,
        quimica: e.quimica,
        supuestos: s,
      ) /
      1000;
  final voltaje = e.tipo.usaBateria ? voltajeSistema(energiaDiaWh) : 0;
  final inversorW = energiaDiaWh <= 0
      ? 0
      : potenciaInversorW(
          entradas: e,
          potenciaPanelesW: potenciaPanelesW,
          energiaDiaWh: energiaDiaWh,
        );
  final controladorA = corrienteControladorA(
    tipo: e.tipo,
    potenciaPanelesW: potenciaPanelesW,
    voltaje: voltaje,
  );
  final costos = calcularCostos(
    entradas: e,
    paneles: paneles,
    bateriaKwh: bateriaKwh,
    inversorW: inversorW,
    controladorA: controladorA,
  );
  final ahorro = ahorroMensual(
    entradas: e,
    generacionMesKwh: generacionMesKwh,
    consumoMesKwh: energiaDiaWh / 1000 * 30,
  );
  final flujo = flujoDeCaja(
    inversion: costos.total,
    ahorroAnualInicial: ahorro.ahorro * 12,
    costoBaterias: costos.baterias,
    vidaBateriaAnios: vidaBateriaAnios ?? e.quimica.vidaUtilAnios,
    supuestos: s,
  );
  return ResultadoCalculo(
    energiaDiaKwh: energiaDiaWh / 1000,
    numeroPaneles: paneles,
    potenciaInstaladaKw: potenciaPanelesW / 1000,
    generacionMesKwh: generacionMesKwh,
    bateriaKwh: bateriaKwh,
    voltajeSistema: voltaje,
    inversorW: inversorW,
    controladorA: controladorA,
    costos: costos,
    autoconsumoMesKwh: ahorro.autoconsumo,
    excedenteMesKwh: ahorro.excedente,
    ahorroMensual: ahorro.ahorro,
    flujo: flujo,
    vpn: flujo.isEmpty ? -costos.total : flujo.last.acumuladoDescontado,
    paybackAnios: recuperacionAnios(costos.total, [
      for (final a in flujo) a.acumulado,
    ]),
    paybackDescontadoAnios: recuperacionAnios(costos.total, [
      for (final a in flujo) a.acumuladoDescontado,
    ]),
  );
}
