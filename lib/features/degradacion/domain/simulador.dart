import 'dart:math' as math;

import 'aleatorio.dart';
import 'parametros.dart';
import 'submodelos.dart';

/// Un día simulado (la misma fila que exporta el dashboard de NetLogo).
class DiaSimulado {
  const DiaSimulado({
    required this.dia,
    required this.soh,
    required this.socMedio,
    required this.generacionKwh,
    required this.consumoKwh,
    required this.compradaKwh,
    required this.polvoG,
    required this.limpieza,
    required this.clima,
    required this.irradianciaMedia,
    required this.temperaturaMedia,
  });

  final int dia;
  final double soh;
  final double socMedio;
  final double generacionKwh;
  final double consumoKwh;
  final double compradaKwh;
  final double polvoG;
  final bool limpieza;

  /// `soleado`, `nublado`, `lluvia` o `tormenta` (de polvo).
  final String clima;
  final double irradianciaMedia;
  final double temperaturaMedia;
}

class ResultadoSimulacion {
  const ResultadoSimulacion({
    required this.parametros,
    required this.semilla,
    required this.horasSimuladas,
    required this.sohFinal,
    required this.energiaCompradaKwh,
    required this.energiaGeneradaKwh,
    required this.consumoKwh,
    required this.limpiezas,
    required this.ciclosEquivalentes,
    required this.sohAnual,
    required this.dias,
    this.autoabastecidoAnual = const [],
  });

  final ParametrosSimulacion parametros;
  final int semilla;
  final int horasSimuladas;
  final double sohFinal;
  final double energiaCompradaKwh;
  final double energiaGeneradaKwh;
  final double consumoKwh;
  final int limpiezas;
  final double ciclosEquivalentes;

  /// SoH al final de cada año completo; el índice 0 es el inicio (100 %).
  final List<double> sohAnual;
  final List<DiaSimulado> dias;

  /// Energía que los paneles y la batería entregaron a la casa (consumo
  /// menos lo comprado a la red, kWh) en cada año completo. Se registra
  /// aunque no se guarden los días; un año a medias (fin de vida) no cuenta.
  final List<double> autoabastecidoAnual;

  /// La corrida se detuvo porque el SoH bajó del 80 % (fin de vida).
  bool get finDeVida => sohFinal < Constantes.sohUmbral;

  double get aniosSimulados => horasSimuladas / Constantes.horasPorAnio;

  /// Pérdida media de SoH por año (puntos %/año).
  double get perdidaAnual => (100 - sohFinal) / aniosSimulados;
}

/// Motor SimDeg-FV: reproduce hora a hora el modelo de NetLogo.
///
/// Orden de cada hora (procedimiento `paso` de NetLogo): entorno → el EMS
/// decide la limpieza → panel → el EMS despacha la energía → batería.
class SimuladorSimDeg {
  SimuladorSimDeg(this.p, {this.semilla = 1, this.registrarDias = true})
    : _azar = Aleatorio(semilla);

  final ParametrosSimulacion p;
  final int semilla;
  final bool registrarDias;
  final Aleatorio _azar;

  // Entorno y clima
  int _hora = 0;
  ClimaDia _clima = ClimaDia.soleado;
  int _diasTormenta = 0;
  bool _llueve = false;
  double _desfaseTempDia = 0;
  double _factorConsumoDia = 1;
  double _factorLluviaAnio = 1;
  double _factorPolvoAnio = 1;
  double _nubosidad = Constantes.nubosidadInicial;
  double _irradiancia = 0;
  double _temperatura = 0;
  double _consumo = 0;

  // Panel, EMS, batería y red
  double _polvo = 0;
  double _generacion = 0;
  int _limpiezas = 0;
  bool _limpiaHoy = false;
  double _soc = Constantes.socInicial;
  double _soh = 100;
  final _estres = EstresBateria();
  double _compradaHora = 0;
  double _comprada = 0;
  double _generada = 0;
  double _consumida = 0;
  double _autoabastecidoAnio = 0;
  final _autoabastecidoAnual = <double>[];

  // Registro diario
  final _dias = <DiaSimulado>[];
  double _genDia = 0, _consDia = 0, _compDia = 0, _socDia = 0;
  double _irrDia = 0, _tempDia = 0;

  bool get _tormenta => _diasTormenta > 0;
  double get _fLluviaTotal => p.zona.factorLluvia * _factorLluviaAnio;
  double get _fPolvoTotal => p.zona.factorPolvo * _factorPolvoAnio;

  /// Corre hasta el horizonte o hasta que el SoH baje del 80 %.
  ResultadoSimulacion ejecutar() {
    final sohAnual = <double>[_soh];
    var horas = 0;
    while (horas < p.horizonteHoras && _soh >= Constantes.sohUmbral) {
      _paso(horas);
      horas++;
      if (horas % Constantes.horasPorAnio == 0) {
        sohAnual.add(_soh);
        _autoabastecidoAnual.add(_autoabastecidoAnio);
        _autoabastecidoAnio = 0;
      }
    }
    return ResultadoSimulacion(
      parametros: p,
      semilla: semilla,
      horasSimuladas: horas,
      sohFinal: _soh,
      energiaCompradaKwh: _comprada,
      energiaGeneradaKwh: _generada,
      consumoKwh: _consumida,
      limpiezas: _limpiezas,
      ciclosEquivalentes: _estres.ciclosEquivalentes,
      sohAnual: sohAnual,
      dias: List.unmodifiable(_dias),
      autoabastecidoAnual: List.unmodifiable(_autoabastecidoAnual),
    );
  }

  void _paso(int tick) {
    _actualizarEntorno(tick);
    final limpiar = _decidirLimpieza();
    _actualizarPanel(limpiar);
    final d = despachar(
      generacion: _generacion,
      consumo: _consumo,
      soc: _soc,
      sohPorcentaje: _soh,
      p: p,
    );
    _compradaHora = d.red;
    _comprada += d.red;
    _autoabastecidoAnio += _consumo - d.red;
    _actualizarBateria(d);
    _registrarHora(tick, limpiar);
  }

  void _actualizarEntorno(int tick) {
    _hora = tick % 24;
    final diaAnio = (tick ~/ 24) % 365 + 1;
    final mes = mesDelDia(diaAnio);
    if (_hora == 0) _nuevoDia(diaAnio);

    final nMedio = nubosidadMedia(_clima, p.zona.factorNubes, _tormenta);
    _nubosidad = (0.6 * _nubosidad + 0.4 * (nMedio + _azar.normal(0, 0.1)))
        .clamp(0, 1)
        .toDouble();
    _llueve = _clima == ClimaDia.lluvia && !_tormenta && _azar.uniforme() < 0.6;
    _irradiancia = irradiancia(
      maxima: p.escenario.irradianciaMaxima,
      hora: _hora,
      mes: mes,
      nubosidad: _nubosidad,
    );
    _temperatura =
        temperaturaBase(
          media: p.escenario.temperaturaMedia,
          desfaseDia: _desfaseTempDia,
          hora: _hora,
          llueve: _llueve,
        ) +
        _azar.normal(0, 0.5);
    _consumo = consumoHora(
      hora: _hora,
      temperatura: _temperatura,
      factorDia: _factorConsumoDia,
      ruido: _azar.normal(1, 0.15),
      factorConsumo: p.factorConsumo,
    );
  }

  /// Procedimiento `nuevo-dia`: anomalías del año, tormentas de polvo,
  /// clima del día (cadena de Markov) y variación diaria.
  void _nuevoDia(int diaAnio) {
    if (diaAnio == 1) {
      _factorLluviaAnio = 0.6 + _azar.uniforme(1);
      _factorPolvoAnio = math.exp(_azar.normal(0, 0.4));
    }
    if (_diasTormenta > 0) {
      _diasTormenta--;
    } else if (_azar.uniforme() < 0.012 * math.min(3, _fPolvoTotal)) {
      _diasTormenta = 1 + _azar.entero(3);
    }
    _clima = siguienteClima(_clima, _fLluviaTotal, _azar.uniforme());
    _desfaseTempDia = _azar.normal(0, 2);
    _factorConsumoDia = math.max(0.6, _azar.normal(1, 0.1));
  }

  /// Procedimiento `decidir-limpieza`: una vez al día (hora 0), limpia si la
  /// pérdida por polvo supera el umbral.
  bool _decidirLimpieza() {
    final limpiar = _hora == 0 && perdidaPorPolvo(_polvo) > p.umbralLimpieza;
    if (limpiar) _limpiezas++;
    return limpiar;
  }

  void _actualizarPanel(bool limpiar) {
    if (limpiar) _polvo = 0;
    _polvo +=
        p.tasaPolvo *
        factorClimaPolvo(tormenta: _tormenta, llueve: _llueve, clima: _clima) *
        _fPolvoTotal;
    if (_llueve) _polvo *= 0.985; // la lluvia lava parte del polvo
    _generacion = potenciaPanel(
      potenciaPicoKw: p.potenciaPanelKw,
      irradiancia: _irradiancia,
      temperaturaAmbiente: _temperatura,
      polvoG: _polvo,
    );
    _generada += _generacion;
    _consumida += _consumo;
  }

  void _actualizarBateria(Despacho d) {
    final capacidadEfectiva = p.capacidadBateriaKwh * _soh / 100;
    _soc = nuevoSoc(
      soc: _soc,
      carga: d.carga,
      descarga: d.descarga,
      capacidadEfectiva: capacidadEfectiva,
    );
    _estres.agregar(
      potenciaKw: d.carga + d.descarga,
      soc: _soc,
      capacidadNominalKwh: p.capacidadBateriaKwh,
    );
    // El SoH nunca sube.
    _soh = math.min(_soh, sohDesdeSeveridad(severidad(_estres, p)));
  }

  void _registrarHora(int tick, bool limpiar) {
    if (!registrarDias) return;
    _genDia += _generacion;
    _consDia += _consumo;
    _compDia += _compradaHora;
    _socDia += _soc;
    _irrDia += _irradiancia;
    _tempDia += _temperatura;
    if (limpiar) _limpiaHoy = true;
    if (_hora == 23) {
      _dias.add(
        DiaSimulado(
          dia: tick ~/ 24,
          soh: _soh,
          socMedio: _socDia / 24,
          generacionKwh: _genDia,
          consumoKwh: _consDia,
          compradaKwh: _compDia,
          polvoG: _polvo,
          limpieza: _limpiaHoy,
          clima: _tormenta ? 'tormenta' : _clima.name,
          irradianciaMedia: _irrDia / 24,
          temperaturaMedia: _tempDia / 24,
        ),
      );
      _genDia = _consDia = _compDia = _socDia = _irrDia = _tempDia = 0;
      _limpiaHoy = false;
    }
  }
}

/// Corre una simulación con la semilla indicada.
ResultadoSimulacion simular(
  ParametrosSimulacion p, {
  int semilla = 1,
  bool registrarDias = true,
}) => SimuladorSimDeg(
  p,
  semilla: semilla,
  registrarDias: registrarDias,
).ejecutar();
