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
  final instalacion = equipos <= 0
      ? 0.0
      : math.max(equipos * p.instalacionPorcentaje, p.instalacionMinima);
  // Ley 1715, art. 12: equipos y servicios sin IVA. Los precios de
  // referencia son de tienda (con IVA), así que se descuenta de todos.
  final f = entradas.supuestos.exclusionIva ? 1 / (1 + Supuestos.iva) : 1.0;
  return Costos(
    paneles: costoPaneles * f,
    baterias: costoBaterias * f,
    inversor: costoInversor * f,
    controlador: costoControlador * f,
    estructura: costoEstructura * f,
    instalacion: instalacion * f,
    ivaExcluido: (equipos + instalacion) * (1 - f),
  );
}

/// Lo que paga la vivienda por [kwh] de la red en un mes según su estrato
/// (Etapa 12): los estratos 1 a 3 tienen descuento en los primeros
/// [consumoSubsistencia] kWh y los 5 y 6 pagan la contribución sobre todo.
/// [subsidio] es el que muestra la factura; sin él, el máximo legal.
double facturaEnergia(
  double kwh, {
  required double tarifa,
  Estrato estrato = Estrato.cuatro,
  double? subsidio,
  double consumoSubsistencia = ConsumoSubsistencia.menosDe1000m,
}) {
  final consumo = math.max(0.0, kwh);
  final subsidiado = math.min(consumo, consumoSubsistencia);
  final descuento = estrato.subsidio == 0 ? 0.0 : subsidio ?? estrato.subsidio;
  return (consumo - subsidiado * descuento) *
      tarifa *
      (1 + estrato.contribucion);
}

/// Valor de la energía de un mes para un autogenerador a pequeña escala
/// (≤ 100 kW) según la CREG 174 de 2021, que liquida por periodo de
/// facturación:
///
/// - el autoconsumo vale lo que baja la factura;
/// - el excedente hasta lo importado en el mes se permuta: vale lo que baja
///   la factura menos el costo de comercialización (Cv);
/// - el excedente que supera lo importado se vende a precio de bolsa.
///
/// La factura sigue al [estrato] ([facturaEnergia]). Según el concepto CREG
/// 3023 de 2026, el consumo facturable del autogenerador es el neto del
/// periodo después de la permuta y el subsidio se aplica sobre ese neto. Por
/// eso la energía solar quita primero los kWh de arriba: en los estratos 1
/// a 3 solo el consumo por debajo del de subsistencia se ahorra al precio
/// con subsidio.
({double ahorro, double permutado, double vendido}) valorEnergiaMes({
  required double autoconsumo,
  required double excedente,
  required double consumo,
  required double tarifa,
  required Supuestos supuestos,
  Estrato estrato = Estrato.cuatro,
  double? subsidio,
  double consumoSubsistencia = ConsumoSubsistencia.menosDe1000m,
}) {
  double factura(double kwh) => facturaEnergia(
    kwh,
    tarifa: tarifa,
    estrato: estrato,
    subsidio: subsidio,
    consumoSubsistencia: consumoSubsistencia,
  );
  final importado = math.max(0.0, consumo - autoconsumo);
  final permutado = math.min(excedente, importado);
  final vendido = excedente - permutado;
  final valorPermuta = math.max(
    0.0,
    factura(importado) -
        factura(importado - permutado) -
        permutado * supuestos.costoComercializacion,
  );
  return (
    ahorro:
        factura(consumo) -
        factura(importado) +
        valorPermuta +
        vendido * supuestos.precioBolsa,
    permutado: permutado,
    vendido: vendido,
  );
}

/// Ahorro del primer mes y reparto de la generación (kWh/mes).
({
  double ahorro,
  double autoconsumo,
  double excedente,
  double permutado,
  double vendido,
})
ahorroMensual({
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
      permutado: 0,
      vendido: 0,
    );
  }
  final fraccion =
      entradas.supuestos.autoconsumo ??
      Supuestos.autoconsumoPorDefecto(entradas.tipo);
  final autoconsumo = math.min(generacionMesKwh * fraccion, consumoMesKwh);
  final excedente = generacionMesKwh - autoconsumo;
  final valor = valorEnergiaMes(
    autoconsumo: autoconsumo,
    excedente: excedente,
    consumo: consumoMesKwh,
    tarifa: entradas.tarifaKwh,
    supuestos: entradas.supuestos,
    estrato: entradas.estrato,
    subsidio: entradas.subsidioAplicado,
    consumoSubsistencia: entradas.consumoSubsistenciaKwh,
  );
  return (
    ahorro: valor.ahorro,
    autoconsumo: autoconsumo,
    excedente: excedente,
    permutado: valor.permutado,
    vendido: valor.vendido,
  );
}

/// Flujo de caja anual: el ahorro crece con la tarifa y cae con la pérdida
/// de rendimiento de los paneles; se restan el mantenimiento y los
/// reemplazos de batería (cada `vidaBateria` años, sin contar el último).
/// El último año se suma el valor residual de la batería en uso: la parte
/// de su vida que queda sin usar (lineal, Etapa 12).
///
/// [ahorroBasePorAnio] (año 1, 2, …), a precios del primer año, reemplaza a
/// [ahorroAnualInicial] cuando el ahorro cambia de un año a otro (Etapa 12:
/// la batería degradada aporta menos).
///
/// [beneficioRenta] es el impuesto que se deja de pagar por la deducción de
/// la Ley 1715; se suma el primer año.
List<AnioFlujo> flujoDeCaja({
  required double inversion,
  required double ahorroAnualInicial,
  required double costoBaterias,
  required int vidaBateriaAnios,
  required Supuestos supuestos,
  double Function(int anio)? ahorroBasePorAnio,
  double beneficioRenta = 0,
}) {
  final flujo = <AnioFlujo>[];
  var acumulado = -inversion;
  var acumuladoDescontado = -inversion;
  for (var t = 1; t <= supuestos.anios; t++) {
    final ahorro =
        (ahorroBasePorAnio?.call(t) ?? ahorroAnualInicial) *
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
    final residual =
        t == supuestos.anios && costoBaterias > 0 && vidaBateriaAnios > 0
        ? costoBaterias *
              math.max(0, vidaBateriaAnios - ((t - 1) % vidaBateriaAnios + 1)) /
              vidaBateriaAnios
        : 0.0;
    final beneficio = t == 1 ? beneficioRenta : 0.0;
    final neto = ahorro - mantenimiento - reemplazo + residual + beneficio;
    acumulado += neto;
    acumuladoDescontado += neto / math.pow(1 + supuestos.tasaDescuento, t);
    flujo.add(
      AnioFlujo(
        anio: t,
        ahorro: ahorro,
        mantenimiento: mantenimiento,
        reemplazoBateria: reemplazo,
        valorResidual: residual,
        beneficioTributario: beneficio,
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

/// Ahorro anual (precios del año 1) cuando la batería entrega [aporte] de lo
/// que entregaría nueva: lo que deja de guardar pasa a ser excedente (y se
/// liquida por tramos, [valorEnergiaMes]) y la casa lo importa de la red.
double _ahorroConBateria({
  required EntradasCalculo entradas,
  required double ahorroMes,
  required double autoconsumoMes,
  required double excedenteMes,
  required double consumoMes,
  required double aporte,
}) {
  final f = aporte.clamp(0.0, 1.0);
  if (entradas.tipo == TipoSistema.offGrid) return ahorroMes * 12 * f;
  return valorEnergiaMes(
        autoconsumo: autoconsumoMes * f,
        excedente: excedenteMes + autoconsumoMes * (1 - f),
        consumo: consumoMes,
        tarifa: entradas.tarifaKwh,
        supuestos: entradas.supuestos,
        estrato: entradas.estrato,
        subsidio: entradas.subsidioAplicado,
        consumoSubsistencia: entradas.consumoSubsistenciaKwh,
      ).ahorro *
      12;
}

/// Ejecuta el cálculo completo.
///
/// `vidaBateriaAnios` reemplaza la vida típica de la química en el flujo de
/// caja; en la Etapa 6 viene de la simulación de degradación (años hasta que
/// el SoH llega al 80 %).
///
/// `aporteBateria(edad)` (Etapa 12) es la energía que entrega a la casa una
/// batería de esa edad (1 = primer año) como fracción de la de una batería
/// nueva: con él, el ahorro baja a medida que la batería se degrada y se
/// recupera con cada reemplazo. Lo que la batería deja de guardar se vende
/// a la red (por tramos, CREG 174) o, sin red, se pierde.
ResultadoCalculo calcular(
  EntradasCalculo e, {
  int? vidaBateriaAnios,
  double Function(int edadBateria)? aporteBateria,
}) {
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
  final consumoMesKwh = energiaDiaWh / 1000 * 30;
  final ahorro = ahorroMensual(
    entradas: e,
    generacionMesKwh: generacionMesKwh,
    consumoMesKwh: consumoMesKwh,
  );
  final vida = vidaBateriaAnios ?? e.quimica.vidaUtilAnios;
  final flujo = flujoDeCaja(
    inversion: costos.total,
    ahorroAnualInicial: ahorro.ahorro * 12,
    costoBaterias: costos.baterias,
    vidaBateriaAnios: vida,
    supuestos: s,
    beneficioRenta:
        costos.total * Supuestos.fraccionDeduccionRenta * s.tarifaRenta,
    ahorroBasePorAnio: aporteBateria == null || !e.tipo.usaBateria
        ? null
        : (t) => _ahorroConBateria(
            entradas: e,
            ahorroMes: ahorro.ahorro,
            autoconsumoMes: ahorro.autoconsumo,
            excedenteMes: ahorro.excedente,
            consumoMes: consumoMesKwh,
            aporte: aporteBateria(vida > 0 ? (t - 1) % vida + 1 : t),
          ),
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
    excedentePermutadoMesKwh: ahorro.permutado,
    excedenteVendidoMesKwh: ahorro.vendido,
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

/// El híbrido frente al mismo sistema sin batería (Etapa 12, revisión
/// crítica 3): [diferenciaVpn] es el VPN con batería menos el VPN sin ella.
typedef ComparacionSinBateria = ({
  ResultadoCalculo sinBateria,
  double autoconsumoSinBateria,
  double diferenciaVpn,
});

/// Calcula el mismo sistema híbrido sin batería: los mismos paneles,
/// conectados a la red con un inversor de red y sin controlador. Sin
/// batería la casa solo usa lo que consume mientras hay sol, así que el
/// autoconsumo vuelve al típico de un sistema conectado a la red (60 %), o al
/// del usuario si lo bajó más. Con la CREG 174 lo que no se guarda se
/// descuenta de la factura (tarifa menos Cv), por eso la batería casi no
/// ahorra dinero: su valor está en cubrir los cortes.
///
/// `null` si el sistema no es híbrido.
ComparacionSinBateria? compararSinBateria(
  EntradasCalculo e,
  ResultadoCalculo conBateria,
) {
  if (e.tipo != TipoSistema.hibrido) return null;
  final propio =
      e.supuestos.autoconsumo ??
      Supuestos.autoconsumoPorDefecto(TipoSistema.hibrido);
  final fraccion = math.min(
    propio,
    Supuestos.autoconsumoPorDefecto(TipoSistema.onGrid),
  );
  final sin = calcular(
    e.copiarCon(
      tipo: TipoSistema.onGrid,
      supuestos: e.supuestos.copiarCon(autoconsumo: fraccion),
    ),
  );
  return (
    sinBateria: sin,
    autoconsumoSinBateria: fraccion,
    diferenciaVpn: conBateria.vpn - sin.vpn,
  );
}
