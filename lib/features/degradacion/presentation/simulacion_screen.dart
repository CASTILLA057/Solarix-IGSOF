import '../../../core/widgets/etiqueta_segmento.dart';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/navegacion.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../../auth/application/auth_providers.dart';
import '../../calculadora/domain/catalogos.dart';
import '../../calculadora/domain/modelos.dart';
import '../../calculadora/presentation/widgets/campos.dart';
import '../application/simulacion_providers.dart';
import '../domain/integracion.dart';
import '../domain/parametros.dart';
import 'etiquetas.dart';

/// Formulario de la simulación de degradación (parámetros del modelo SimDeg-FV
/// con los valores por defecto de NetLogo).
class SimulacionScreen extends ConsumerStatefulWidget {
  const SimulacionScreen({super.key, this.origen});

  /// Cálculo del que parte (Etapa 6): precarga batería, paneles, consumo y
  /// el lugar (Etapa 12).
  final OrigenCalculo? origen;

  @override
  ConsumerState<SimulacionScreen> createState() => _SimulacionScreenState();
}

class _SimulacionScreenState extends ConsumerState<SimulacionScreen> {
  static const _d = ParametrosSimulacion();

  late final ParametrosSimulacion _inicial = widget.origen == null
      ? _d
      : parametrosDesdeCalculo(widget.origen!);

  final _form = GlobalKey<FormState>();
  late final _capacidad = TextEditingController(
    text: _texto(_redondear(_inicial.capacidadBateriaKwh)),
  );
  late final _panel = TextEditingController(
    text: _texto(_redondear(_inicial.potenciaPanelKw)),
  );
  final _tasaC = TextEditingController(text: _texto(_d.tasaCMaxima));
  final _socMin = TextEditingController(text: _texto(_d.cargaMinima));
  final _socMax = TextEditingController(text: _texto(_d.cargaMaxima));
  final _anios = TextEditingController(text: '${_d.anios}');
  final _tasaPolvo = TextEditingController(text: _texto(_d.tasaPolvo));
  final _umbral = TextEditingController(text: _texto(_d.umbralLimpieza));
  final _escala = TextEditingController(text: _texto(_d.escalaDegradacion));
  final _exponente = TextEditingController(
    text: _texto(_d.exponenteDegradacion),
  );
  final _pesoCorriente = TextEditingController(text: _texto(_d.pesoCorriente));
  final _pesoVariacion = TextEditingController(
    text: _texto(_d.pesoVariacionCarga),
  );
  Politica _politica = _d.politica;

  /// Lugar que se simula: [_delCalculo] o el nombre de una ciudad. Sin
  /// cálculo, la ciudad del perfil (si está en la lista) o Ocaña.
  late String _lugar = widget.origen != null ? _delCalculo : _ciudadInicial();
  static const _delCalculo = '__calculo__';
  bool _lugarElegido = false;

  /// "Avanzado": usar una configuración de NetLogo (escenario y zona) tal
  /// cual, validada contra el modelo original.
  bool _netLogo = false;
  EscenarioIrradiancia _escenario = _d.escenario;
  ZonaClimatica _zona = _d.zona;
  bool _simulando = false;
  String? _error;

  static double _redondear(double v) => (v * 100).roundToDouble() / 100;

  /// Texto con coma decimal y sin notación científica (0,0000078).
  static String _texto(double v) {
    var t = v.toStringAsFixed(7);
    t = t.replaceFirst(RegExp(r'\.?0+$'), '');
    return t.replaceAll('.', ',');
  }

  @override
  void initState() {
    super.initState();
    // Si el perfil llega después de abrir la pantalla, su ciudad pasa a ser
    // el lugar, mientras el usuario no haya elegido otro.
    if (widget.origen == null && ref.read(haySesionProvider)) {
      ref.listenManual(perfilProvider, (_, perfil) {
        final ciudad = ciudadPorNombre(perfil.value?.ciudad);
        if (ciudad == null || _lugarElegido || ciudad.nombre == _lugar) return;
        setState(() => _lugar = ciudad.nombre);
      });
    }
  }

  @override
  void dispose() {
    for (final c in [
      _capacidad,
      _panel,
      _tasaC,
      _socMin,
      _socMax,
      _anios,
      _tasaPolvo,
      _umbral,
      _escala,
      _exponente,
      _pesoCorriente,
      _pesoVariacion,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _leer(TextEditingController c) => Formato.leer(c.text)!;

  Future<void> _simular() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (_leer(_socMin) >= _leer(_socMax)) {
      setState(() => _error = 'El SOC mínimo debe ser menor que el máximo.');
      return;
    }
    final entorno = _entorno;
    final parametros = ParametrosSimulacion(
      capacidadBateriaKwh: _leer(_capacidad),
      potenciaPanelKw: _leer(_panel),
      tasaCMaxima: _leer(_tasaC),
      cargaMinima: _leer(_socMin),
      cargaMaxima: _leer(_socMax),
      anios: _leer(_anios).round(),
      tasaPolvo: _leer(_tasaPolvo),
      umbralLimpieza: _leer(_umbral),
      escalaDegradacion: _leer(_escala),
      exponenteDegradacion: _leer(_exponente),
      pesoCorriente: _leer(_pesoCorriente),
      pesoVariacionCarga: _leer(_pesoVariacion),
      politica: _politica,
      escenario: entorno.escenario,
      zona: entorno.zona,
      irradianciaMaximaLugar: entorno.irradianciaMaximaLugar,
      temperaturaMediaLugar: entorno.temperaturaMediaLugar,
      // Con un cálculo de origen, el consumo se ajusta al de la casa (medido
      // en el entorno elegido); sin él, el perfil de NetLogo.
      factorConsumo: switch (widget.origen) {
        null => 1,
        final o => factorConsumoPara(o.resultado.energiaDiaKwh, entorno),
      },
    );
    setState(() => _simulando = true);
    try {
      // Deja dibujar el indicador antes de simular (en web corre en este hilo).
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final comparacion = await ref.read(ejecutorSimulacionProvider)((
        parametros: parametros,
        semilla: math.Random().nextInt(1 << 31),
      ));
      if (!mounted) return;
      await context.push(
        Rutas.resultadosSimulacion,
        extra: (comparacion, widget.origen),
      );
    } catch (e, pila) {
      debugPrint('Error al simular: $e');
      debugPrintStack(stackTrace: pila);
      if (mounted) {
        setState(
          () => _error =
              'No se pudo simular con estos parámetros. Revísalos e intenta '
              'de nuevo.',
        );
      }
    } finally {
      if (mounted) setState(() => _simulando = false);
    }
  }

  String _ciudadInicial() {
    final delPerfil = ref.read(haySesionProvider)
        ? ref.read(perfilProvider).value?.ciudad
        : null;
    return ciudadPorNombre(delPerfil)?.nombre ?? 'Ocaña';
  }

  /// HSP y clima del lugar elegido.
  (double, ClimaLugar?) get _hspYClima {
    final origen = widget.origen;
    if (_lugar == _delCalculo && origen != null) {
      return (origen.entradas.hsp, origen.entradas.clima);
    }
    final ciudad = ciudadesBase.firstWhere((c) => c.nombre == _lugar);
    return (ciudad.hsp, climaDeCiudad(ciudad.nombre));
  }

  /// Entorno que se simula: el del lugar o, en "Avanzado", una
  /// configuración de NetLogo sin cambios.
  ParametrosSimulacion get _entorno {
    if (_netLogo) {
      return ParametrosSimulacion(escenario: _escenario, zona: _zona);
    }
    final (hsp, clima) = _hspYClima;
    return entornoDelLugar(hsp: hsp, clima: clima);
  }

  /// Zonas posibles con cada escenario: con irradiancia baja (casi sin sol)
  /// no hay zona muy soleada ni polvorienta (seca y despejada).
  static List<ZonaClimatica> _zonasPara(EscenarioIrradiancia e) => [
    for (final z in ZonaClimatica.values)
      if (e != EscenarioIrradiancia.baja ||
          (z != ZonaClimatica.muySoleada && z != ZonaClimatica.polvorienta))
        z,
  ];

  String _resumenEntorno(ParametrosSimulacion e) {
    final base =
        'Zona ${e.zona.etiqueta.toLowerCase()} · irradiancia máxima '
        '${Formato.numero(e.irradianciaMaxima)} W/m² · '
        '${Formato.numero(e.temperaturaMedia, 1)} °C de media · '
        '${Formato.numero(hspModelo(e), 1)} HSP.';
    if (_netLogo) return '$base Configuración original de NetLogo.';
    final (_, clima) = _hspYClima;
    return clima == null
        ? '$base Sin datos del clima del lugar: zona mixta y temperatura del '
              'escenario de NetLogo.'
        : '$base Zona según la lluvia (${Formato.numero(clima.lluviaMmAnio)} '
              'mm/año) y las nubes (${Formato.numero(clima.nubosidadPct)} %); '
              'irradiancia para dar las HSP del lugar.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simular degradación'),
        actions: const [BotonInicio()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Simula hora a hora la salud (SoH) de una batería de litio '
                  'con el modelo SimDeg-FV, y la compara con la otra política '
                  'de operación bajo el mismo clima.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (widget.origen case final origen?)
                  Card(
                    margin: const EdgeInsets.only(top: 16),
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.link),
                      title: Text(
                        origen.entradas.nombre.isEmpty
                            ? 'Valores de tu cálculo'
                            : 'Valores de "${origen.entradas.nombre}"',
                      ),
                      subtitle: Text(
                        'Batería y paneles del sistema dimensionado y consumo '
                        'ajustado a ${Formato.numero(origen.resultado.energiaDiaKwh, 1)} '
                        'kWh/día. El lugar se elige en "Entorno".',
                      ),
                    ),
                  ),
                _Seccion(
                  titulo: 'Sistema',
                  icono: Icons.solar_power_outlined,
                  hijos: [
                    CampoNumero(
                      controller: _capacidad,
                      etiqueta: 'Capacidad de la batería',
                      sufijo: 'kWh',
                      minimo: 1,
                      maximo: 100,
                    ),
                    CampoNumero(
                      controller: _panel,
                      etiqueta: 'Potencia de los paneles',
                      sufijo: 'kWp',
                      minimo: 0.5,
                      maximo: 50,
                    ),
                    CampoNumero(
                      controller: _tasaC,
                      etiqueta: 'Tasa C máxima de la batería',
                      sufijo: '1/h',
                      ayuda: 'Potencia máxima = tasa C × capacidad.',
                      minimo: 0.1,
                      maximo: 2,
                    ),
                  ],
                ),
                _Seccion(
                  titulo: 'Entorno',
                  icono: Icons.wb_cloudy_outlined,
                  hijos: [
                    DropdownButtonFormField<String>(
                      key: ValueKey(_lugarElegido ? 'lugar' : _lugar),
                      initialValue: _lugar,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lugar',
                        prefixIcon: Icon(Icons.location_city_outlined),
                      ),
                      items: [
                        if (widget.origen case final o?)
                          DropdownMenuItem(
                            value: _delCalculo,
                            child: Text(
                              'Del cálculo · '
                              '${Formato.numero(o.entradas.hsp, 1)} HSP',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        for (final c in ciudadesBase)
                          DropdownMenuItem(
                            value: c.nombre,
                            child: Text(
                              '${c.nombre} · ${Formato.numero(c.hsp, 1)} HSP',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: _netLogo
                          ? null
                          : (l) => setState(() {
                              _lugar = l!;
                              _lugarElegido = true;
                            }),
                    ),
                    Text(
                      _resumenEntorno(_entorno),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Avanzado: configuración de NetLogo'),
                      initiallyExpanded: _netLogo,
                      childrenPadding: const EdgeInsets.only(bottom: 8),
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Usar un escenario de NetLogo'),
                          subtitle: const Text(
                            'Irradiancia y zona originales del modelo, '
                            'validadas contra NetLogo, en lugar del lugar.',
                          ),
                          value: _netLogo,
                          onChanged: (v) => setState(() => _netLogo = v),
                        ),
                        if (_netLogo) ...[
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Irradiancia',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<EscenarioIrradiancia>(
                            segments: [
                              for (final e in EscenarioIrradiancia.values)
                                ButtonSegment(
                                  value: e,
                                  label: EtiquetaSegmento(e.etiqueta),
                                ),
                            ],
                            selected: {_escenario},
                            onSelectionChanged: (s) => setState(() {
                              _escenario = s.first;
                              if (!_zonasPara(_escenario).contains(_zona)) {
                                _zona = ZonaClimatica.mixta;
                              }
                            }),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<ZonaClimatica>(
                            key: ValueKey(_escenario),
                            initialValue: _zona,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Zona climática',
                              helperText:
                                  'Cambia la lluvia, las nubes y el polvo.',
                            ),
                            items: [
                              for (final z in _zonasPara(_escenario))
                                DropdownMenuItem(
                                  value: z,
                                  child: Text(z.etiqueta),
                                ),
                            ],
                            onChanged: (z) => setState(() => _zona = z!),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                _Seccion(
                  titulo: 'Operación',
                  icono: Icons.battery_charging_full_outlined,
                  hijos: [
                    SegmentedButton<Politica>(
                      segments: [
                        for (final p in Politica.values)
                          ButtonSegment(
                            value: p,
                            label: EtiquetaSegmento(p.etiqueta),
                          ),
                      ],
                      selected: {_politica},
                      onSelectionChanged: (s) =>
                          setState(() => _politica = s.first),
                    ),
                    Text(
                      _politica.descripcion,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    CampoNumero(
                      controller: _socMin,
                      etiqueta: 'SOC mínimo',
                      sufijo: '%',
                      ayuda: 'La batería no se descarga por debajo.',
                      minimo: 0,
                      maximo: 90,
                    ),
                    CampoNumero(
                      controller: _socMax,
                      etiqueta: 'SOC máximo (convencional)',
                      sufijo: '%',
                      minimo: 10,
                      maximo: 100,
                    ),
                    CampoNumero(
                      controller: _anios,
                      etiqueta: 'Años a simular',
                      sufijo: 'años',
                      minimo: 1,
                      maximo: 20,
                    ),
                  ],
                ),
                ExpansionTile(
                  tilePadding: EdgeInsets.zero,
                  title: const Text('Polvo y coeficientes de degradación'),
                  subtitle: const Text('Valores calibrados del modelo'),
                  childrenPadding: const EdgeInsets.only(top: 12, bottom: 8),
                  children: [
                    for (final campo in [
                      CampoNumero(
                        controller: _tasaPolvo,
                        etiqueta: 'Polvo que llega a los paneles',
                        sufijo: 'g/h',
                        minimo: 0,
                        maximo: 1,
                      ),
                      CampoNumero(
                        controller: _umbral,
                        etiqueta: 'Pérdida por polvo que activa la limpieza',
                        sufijo: '%',
                        minimo: 1,
                        maximo: 60,
                      ),
                      CampoNumero(
                        controller: _escala,
                        etiqueta: 'α · escala de degradación',
                        minimo: 0,
                        maximo: 0.001,
                      ),
                      CampoNumero(
                        controller: _exponente,
                        etiqueta: 'β · exponente de la energía acumulada',
                        minimo: 0.3,
                        maximo: 2,
                      ),
                      CampoNumero(
                        controller: _pesoCorriente,
                        etiqueta: 'γ · peso de la corriente eficaz',
                        minimo: 0,
                        maximo: 20,
                      ),
                      CampoNumero(
                        controller: _pesoVariacion,
                        etiqueta: 'δ · peso de la variabilidad del SOC',
                        minimo: 0,
                        maximo: 20,
                      ),
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: campo,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_error != null) ...[
                  MensajeError(_error!),
                  const SizedBox(height: 12),
                ],
                BotonPrincipal(
                  texto: 'Simular',
                  cargando: _simulando,
                  onPressed: _simular,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.hijos,
  });

  final String titulo;
  final IconData icono;
  final List<Widget> hijos;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icono, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Text(titulo, style: tema.textTheme.titleMedium),
              ],
            ),
            for (final h in hijos) ...[const SizedBox(height: 16), h],
          ],
        ),
      ),
    );
  }
}
