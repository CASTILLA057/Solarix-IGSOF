import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/navegacion.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
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
  /// escenario de irradiancia.
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
  late EscenarioIrradiancia _escenario = _inicial.escenario;
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
      escenario: _escenario,
      zona: _zona,
      // Con un cálculo de origen, el consumo se ajusta al de la casa
      // (factor medido para el escenario elegido); sin él, perfil de NetLogo.
      factorConsumo: widget.origen == null
          ? 1
          : factorConsumoPara(
              widget.origen!.resultado.energiaDiaKwh,
              _escenario,
            ),
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
                        'Batería y paneles del sistema dimensionado; consumo '
                        'ajustado a ${Formato.numero(origen.resultado.energiaDiaKwh, 1)} '
                        'kWh/día; irradiancia del modelo más cercana a '
                        '${Formato.numero(origen.entradas.hsp, 1)} HSP.',
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
                    Text(
                      'Irradiancia',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    SegmentedButton<EscenarioIrradiancia>(
                      segments: [
                        for (final e in EscenarioIrradiancia.values)
                          ButtonSegment(value: e, label: Text(e.etiqueta)),
                      ],
                      selected: {_escenario},
                      onSelectionChanged: (s) =>
                          setState(() => _escenario = s.first),
                    ),
                    DropdownButtonFormField<ZonaClimatica>(
                      initialValue: _zona,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Zona climática',
                        helperText: 'Cambia la lluvia, las nubes y el polvo.',
                      ),
                      items: [
                        for (final z in ZonaClimatica.values)
                          DropdownMenuItem(value: z, child: Text(z.etiqueta)),
                      ],
                      onChanged: (z) => setState(() => _zona = z!),
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
                          ButtonSegment(value: p, label: Text(p.etiqueta)),
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
