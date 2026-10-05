import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/navegacion.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../application/calculadora_providers.dart';
import '../domain/calculadora.dart';
import '../domain/catalogos.dart';
import '../domain/modelos.dart';
import 'widgets/campos.dart';
import 'widgets/equipos_editor.dart';

enum _FuenteHsp { ciudad, ubicacion, manual }

/// Separación sobre el primer campo de un bloque que recorta su contenido
/// (paso del Stepper, sección desplegable), para no cortar la etiqueta.
const _margenEtiqueta = 12.0;

/// Asistente de 4 pasos: tipo de sistema, consumo, ubicación y equipos.
class CalculadoraScreen extends ConsumerStatefulWidget {
  const CalculadoraScreen({super.key});

  @override
  ConsumerState<CalculadoraScreen> createState() => _CalculadoraScreenState();
}

class _CalculadoraScreenState extends ConsumerState<CalculadoraScreen> {
  final _formularios = List.generate(4, (_) => GlobalKey<FormState>());
  int _paso = 0;
  String? _error;

  // Paso 1: sistema
  TipoSistema _tipo = TipoSistema.onGrid;
  final _nombre = TextEditingController();

  // Paso 2: consumo
  ModoConsumo _modo = ModoConsumo.equipos;
  List<Equipo> _equipos = equiposBase.take(5).toList();
  final _consumoMes = TextEditingController();
  final _tarifa = TextEditingController(text: '890');
  final _gastoActual = TextEditingController(text: '0');

  // Paso 3: ubicación
  _FuenteHsp _fuente = _FuenteHsp.ciudad;
  Ciudad? _ciudad;
  double? _hspUbicacion;
  bool _buscandoUbicacion = false;
  String? _errorUbicacion;
  final _hspManual = TextEditingController(text: '4.5');

  // Paso 4: equipos y supuestos
  final _potenciaPanel = TextEditingController(text: '550');
  QuimicaBateria _quimica = QuimicaBateria.litio;
  final _diasAutonomia = TextEditingController(text: '2');
  final _cobertura = TextEditingController(text: '100');
  final _rendimiento = TextEditingController(text: '78');
  final _incrementoTarifa = TextEditingController(text: '6');
  final _tasaDescuento = TextEditingController(text: '10');
  final _anios = TextEditingController(text: '20');
  final _vidaCalendario = TextEditingController(
    text: '${QuimicaBateria.litio.vidaCalendarioAnios}',
  );
  final _factorExcedente = TextEditingController(text: '70');
  final _mantenimiento = TextEditingController(text: '1');
  final _precios = <String, TextEditingController>{};
  bool _preciosCargados = false;

  static const _etiquetasPrecios = {
    'panel_por_wp': ('Panel', 'COP/Wp'),
    'inversor_red_por_w': ('Inversor de red', 'COP/W'),
    'inversor_aislado_por_w': ('Inversor aislado o híbrido', 'COP/W'),
    'bateria_litio_por_kwh': ('Batería de litio', 'COP/kWh'),
    'bateria_plomo_por_kwh': ('Batería de plomo-ácido', 'COP/kWh'),
    'controlador_por_a': ('Controlador de carga', 'COP/A'),
    'estructura_por_panel': (
      'Estructura, cableado y protecciones por panel',
      'COP',
    ),
    'instalacion_porcentaje': ('Instalación, RETIE y trámites', '% de equipos'),
    'instalacion_minima': ('Instalación mínima', 'COP'),
  };

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _consumoMes,
      _tarifa,
      _gastoActual,
      _hspManual,
      _potenciaPanel,
      _diasAutonomia,
      _cobertura,
      _rendimiento,
      _incrementoTarifa,
      _tasaDescuento,
      _anios,
      _vidaCalendario,
      _factorExcedente,
      _mantenimiento,
      ..._precios.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _cargarPrecios(Precios p) {
    if (_preciosCargados) return;
    _preciosCargados = true;
    p.aMapa().forEach((clave, valor) {
      final v = valor as double;
      _precios[clave] = TextEditingController(
        text: clave == 'instalacion_porcentaje'
            ? Formato.numero(v * 100)
            : Formato.numero(v),
      );
    });
  }

  double? get _hsp => switch (_fuente) {
    _FuenteHsp.ciudad => _ciudad?.hsp,
    _FuenteHsp.ubicacion => _hspUbicacion,
    _FuenteHsp.manual => Formato.leer(_hspManual.text),
  };

  String get _ubicacion => switch (_fuente) {
    _FuenteHsp.ciudad => _ciudad?.etiqueta ?? '',
    _FuenteHsp.ubicacion => 'Mi ubicación (NASA POWER)',
    _FuenteHsp.manual => 'HSP ingresadas a mano',
  };

  String? _validarPaso(int paso) {
    if (!(_formularios[paso].currentState?.validate() ?? true)) {
      return 'Revisa los campos marcados.';
    }
    if (paso == 1 && _modo == ModoConsumo.equipos && _equipos.isEmpty) {
      return 'Agrega al menos un equipo.';
    }
    if (paso == 2 && (_hsp == null || _hsp! <= 0)) {
      return _fuente == _FuenteHsp.ubicacion
          ? 'Obtén las horas solares de tu ubicación o elige otra opción.'
          : 'Elige una ciudad o escribe las horas solares pico.';
    }
    return null;
  }

  void _continuar() {
    final error = _validarPaso(_paso);
    setState(() => _error = error);
    if (error != null) return;
    if (_paso < 3) {
      setState(() => _paso++);
    } else {
      _calcular();
    }
  }

  double _porcentaje(TextEditingController c) => Formato.leer(c.text)! / 100;

  /// Batería de litio: la que se puede simular (y lleva vida calendario).
  bool get _simulable => _tipo.usaBateria && _quimica == QuimicaBateria.litio;

  EntradasCalculo _entradas() {
    final p = <String, double>{
      for (final MapEntry(:key, :value) in _precios.entries)
        key: Formato.leer(value.text)!,
    };
    if (p.containsKey('instalacion_porcentaje')) {
      p['instalacion_porcentaje'] = p['instalacion_porcentaje']! / 100;
    }
    return EntradasCalculo(
      nombre: _nombre.text.trim(),
      tipo: _tipo,
      modo: _modo,
      equipos: _equipos,
      consumoFacturaKwhMes: Formato.leer(_consumoMes.text) ?? 0,
      tarifaKwh: Formato.leer(_tarifa.text) ?? 0,
      gastoActualMensual: Formato.leer(_gastoActual.text) ?? 0,
      hsp: _hsp!,
      ubicacion: _ubicacion,
      potenciaPanelW: Formato.leer(_potenciaPanel.text)!,
      quimica: _quimica,
      supuestos: Supuestos(
        rendimientoSistema: _porcentaje(_rendimiento),
        diasAutonomia: Formato.leer(_diasAutonomia.text)!,
        cobertura: _porcentaje(_cobertura),
        factorExcedente: _porcentaje(_factorExcedente),
        incrementoTarifa: _porcentaje(_incrementoTarifa),
        mantenimientoAnual: _porcentaje(_mantenimiento),
        tasaDescuento: _porcentaje(_tasaDescuento),
        anios: Formato.leer(_anios.text)!.round(),
        vidaCalendarioBateria: _simulable
            ? Formato.leer(_vidaCalendario.text)
            : null,
      ),
      precios: Precios.desdeFilas(p),
    );
  }

  void _calcular() {
    final entradas = _entradas();
    final resultado = calcular(entradas);
    context.push(Rutas.resultados, extra: (entradas, resultado));
  }

  Future<void> _buscarUbicacion() async {
    setState(() {
      _buscandoUbicacion = true;
      _errorUbicacion = null;
    });
    try {
      final hsp = await ref.read(recursoSolarProvider).hspEnUbicacionActual();
      if (mounted) setState(() => _hspUbicacion = hsp);
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _errorUbicacion = e.mensaje);
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final precios = ref.watch(preciosProvider);
    precios.whenData(_cargarPrecios);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora solar'),
        actions: const [BotonInicio()],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Stepper(
            currentStep: _paso,
            onStepContinue: _continuar,
            onStepCancel: _paso == 0
                ? null
                : () => setState(() {
                    _error = null;
                    _paso--;
                  }),
            onStepTapped: (paso) {
              if (paso < _paso) {
                setState(() {
                  _error = null;
                  _paso = paso;
                });
              }
            },
            // El Stepper construye los controles de todos los pasos (los
            // ocultos con altura cero): solo se dibujan los del paso actual.
            controlsBuilder: (context, detalles) =>
                detalles.stepIndex != detalles.currentStep
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          MensajeError(_error!),
                          const SizedBox(height: 12),
                        ],
                        // Wrap: en celulares angostos el "Atrás" baja de
                        // línea en vez de desbordarse.
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton(
                              onPressed: detalles.onStepContinue,
                              child: Text(
                                _paso == 3 ? 'Calcular' : 'Siguiente',
                              ),
                            ),
                            if (detalles.onStepCancel != null)
                              TextButton(
                                onPressed: detalles.onStepCancel,
                                child: const Text('Atrás'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
            steps: [
              Step(
                title: const Text('Tipo de sistema'),
                isActive: _paso >= 0,
                state: _paso > 0 ? StepState.complete : StepState.indexed,
                content: Form(key: _formularios[0], child: _pasoSistema()),
              ),
              Step(
                title: const Text('Consumo'),
                isActive: _paso >= 1,
                state: _paso > 1 ? StepState.complete : StepState.indexed,
                content: Form(key: _formularios[1], child: _pasoConsumo()),
              ),
              Step(
                title: const Text('Ubicación'),
                isActive: _paso >= 2,
                state: _paso > 2 ? StepState.complete : StepState.indexed,
                content: Form(key: _formularios[2], child: _pasoUbicacion()),
              ),
              Step(
                title: const Text('Equipos y costos'),
                isActive: _paso >= 3,
                content: Form(
                  key: _formularios[3],
                  child: precios.isLoading && !_preciosCargados
                      ? const Center(child: CircularProgressIndicator())
                      : _pasoEquipos(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pasoSistema() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RadioGroup<TipoSistema>(
        groupValue: _tipo,
        onChanged: (t) => setState(() => _tipo = t!),
        child: Column(
          children: [
            for (final tipo in TipoSistema.values)
              RadioListTile<TipoSistema>(
                value: tipo,
                contentPadding: EdgeInsets.zero,
                title: Text(tipo.etiqueta),
                subtitle: Text(tipo.descripcion),
              ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: _nombre,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Nombre del cálculo (opcional)',
          hintText: 'Ej.: Casa de la finca',
        ),
      ),
    ],
  );

  Widget _pasoConsumo() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SegmentedButton<ModoConsumo>(
        segments: const [
          ButtonSegment(
            value: ModoConsumo.equipos,
            label: Text('Mis equipos'),
            icon: Icon(Icons.kitchen_outlined),
          ),
          ButtonSegment(
            value: ModoConsumo.factura,
            label: Text('Mi factura'),
            icon: Icon(Icons.receipt_long_outlined),
          ),
        ],
        selected: {_modo},
        onSelectionChanged: (s) => setState(() => _modo = s.first),
      ),
      const SizedBox(height: 16),
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _modo == ModoConsumo.equipos
            ? EquiposEditor(
                key: const ValueKey('equipos'),
                equipos: _equipos,
                onChanged: (lista) => setState(() => _equipos = lista),
              )
            : CampoNumero(
                key: const ValueKey('factura'),
                controller: _consumoMes,
                etiqueta: 'Consumo mensual de la factura',
                sufijo: 'kWh/mes',
                minimo: 1,
              ),
      ),
      const SizedBox(height: 16),
      if (_tipo.usaRed)
        CampoNumero(
          controller: _tarifa,
          etiqueta: 'Tarifa de la energía',
          sufijo: 'COP/kWh',
          ayuda: 'Aparece en tu factura como valor del kWh.',
          minimo: 1,
        )
      else
        CampoNumero(
          controller: _gastoActual,
          etiqueta: 'Gasto mensual actual en energía',
          sufijo: 'COP/mes',
          ayuda: 'Combustible, pilas, velas… Es lo que dejarías de gastar.',
          minimo: 0,
        ),
    ],
  );

  Widget _pasoUbicacion() {
    final ciudades = ref.watch(ciudadesProvider).value ?? ciudadesBase;
    final hsp = _hsp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_FuenteHsp>(
          segments: const [
            ButtonSegment(value: _FuenteHsp.ciudad, label: Text('Ciudad')),
            ButtonSegment(
              value: _FuenteHsp.ubicacion,
              label: Text('Mi ubicación'),
            ),
            ButtonSegment(value: _FuenteHsp.manual, label: Text('Manual')),
          ],
          selected: {_fuente},
          onSelectionChanged: (s) => setState(() => _fuente = s.first),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_fuente) {
            _FuenteHsp.ciudad => DropdownButtonFormField<Ciudad>(
              key: const ValueKey('ciudad'),
              initialValue: _ciudad,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
              items: [
                for (final c in ciudades)
                  DropdownMenuItem(value: c, child: Text(c.etiqueta)),
              ],
              onChanged: (c) => setState(() => _ciudad = c),
            ),
            _FuenteHsp.ubicacion => Column(
              key: const ValueKey('ubicacion'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _buscandoUbicacion ? null : _buscarUbicacion,
                  icon: _buscandoUbicacion
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                  label: Text(
                    _buscandoUbicacion
                        ? 'Consultando NASA POWER…'
                        : 'Usar mi ubicación',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _buscandoUbicacion
                      ? 'La consulta puede tardar hasta un minuto.'
                      : 'Usa el promedio anual de radiación solar de NASA '
                            'POWER para tu ubicación exacta.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_errorUbicacion != null) ...[
                  const SizedBox(height: 8),
                  MensajeError(_errorUbicacion!),
                ],
              ],
            ),
            _FuenteHsp.manual => CampoNumero(
              key: const ValueKey('manual'),
              controller: _hspManual,
              etiqueta: 'Horas solares pico',
              sufijo: 'kWh/m²/día',
              minimo: 1,
              maximo: 8,
              onChanged: (_) => setState(() {}),
            ),
          },
        ),
        if (hsp != null && hsp > 0) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text('${Formato.numero(hsp, 2)} horas solares pico'),
              subtitle: Text(
                'Irradiancia ${zonaParaHsp(hsp).etiqueta.toLowerCase()}',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pasoEquipos() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      // Espacio para la etiqueta flotante del primer campo: el contenido del
      // Stepper recorta lo que sobresale por arriba.
      const SizedBox(height: _margenEtiqueta),
      CampoNumero(
        controller: _potenciaPanel,
        etiqueta: 'Potencia de cada panel',
        sufijo: 'W',
        ayuda: 'Los paneles comerciales actuales son de 450 a 600 W.',
        minimo: 50,
        maximo: 1000,
      ),
      if (_tipo.usaBateria) ...[
        const SizedBox(height: 16),
        DropdownButtonFormField<QuimicaBateria>(
          initialValue: _quimica,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Tipo de batería'),
          items: [
            for (final q in QuimicaBateria.values)
              DropdownMenuItem(
                value: q,
                child: Text(
                  '${q.etiqueta} · usable '
                  '${Formato.porcentaje(q.profundidadDescarga)}',
                ),
              ),
          ],
          onChanged: (q) => setState(() => _quimica = q!),
        ),
        if (_quimica == QuimicaBateria.plomo)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'La simulación de degradación (siguiente módulo) solo aplica '
              'a baterías de litio.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
      if (_tipo == TipoSistema.offGrid) ...[
        const SizedBox(height: 16),
        CampoNumero(
          controller: _diasAutonomia,
          etiqueta: 'Días de autonomía',
          sufijo: 'días',
          ayuda: 'Días que la batería cubre la casa sin sol.',
          minimo: 0.5,
          maximo: 7,
        ),
      ] else ...[
        const SizedBox(height: 16),
        CampoNumero(
          controller: _cobertura,
          etiqueta: 'Parte del consumo a cubrir con paneles',
          sufijo: '%',
          minimo: 10,
          maximo: 200,
        ),
      ],
      const SizedBox(height: 8),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Supuestos técnicos y financieros'),
        childrenPadding: const EdgeInsets.only(top: _margenEtiqueta, bottom: 8),
        children: [
          CampoNumero(
            controller: _rendimiento,
            etiqueta: 'Rendimiento del sistema (PR)',
            sufijo: '%',
            ayuda: 'Pérdidas por calor, cableado, suciedad e inversor.',
            minimo: 50,
            maximo: 95,
          ),
          if (_tipo.usaRed) ...[
            const SizedBox(height: 12),
            CampoNumero(
              controller: _factorExcedente,
              etiqueta: 'Pago por energía vendida a la red',
              sufijo: '% de la tarifa',
              minimo: 0,
              maximo: 100,
            ),
          ],
          const SizedBox(height: 12),
          CampoNumero(
            controller: _incrementoTarifa,
            etiqueta: 'Aumento anual del precio de la energía',
            sufijo: '%',
            minimo: 0,
            maximo: 30,
          ),
          const SizedBox(height: 12),
          CampoNumero(
            controller: _mantenimiento,
            etiqueta: 'Mantenimiento anual',
            sufijo: '% de la inversión',
            minimo: 0,
            maximo: 10,
          ),
          const SizedBox(height: 12),
          CampoNumero(
            controller: _tasaDescuento,
            etiqueta: 'Tasa de descuento',
            sufijo: '%',
            ayuda: 'Rentabilidad que exigirías a tu dinero (para el VPN).',
            minimo: 0,
            maximo: 50,
          ),
          const SizedBox(height: 12),
          CampoNumero(
            controller: _anios,
            etiqueta: 'Horizonte del análisis',
            sufijo: 'años',
            minimo: 1,
            maximo: 30,
          ),
          if (_simulable) ...[
            const SizedBox(height: 12),
            CampoNumero(
              controller: _vidaCalendario,
              etiqueta: 'Vida calendario de la batería',
              sufijo: 'años',
              ayuda:
                  'Lo que dura aunque se use poco: es el tope de la vida '
                  'simulada.',
              minimo: 5,
              maximo: 30,
            ),
          ],
        ],
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Precios de referencia'),
        subtitle: const Text('Ajústalos con tus cotizaciones'),
        childrenPadding: const EdgeInsets.only(top: _margenEtiqueta, bottom: 8),
        children: [
          for (final MapEntry(key: clave, value: (etiqueta, unidad))
              in _etiquetasPrecios.entries)
            if (_precios[clave] case final controlador?)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: CampoNumero(
                  controller: controlador,
                  etiqueta: etiqueta,
                  sufijo: unidad,
                  minimo: 0,
                  maximo: clave == 'instalacion_porcentaje' ? 100 : null,
                ),
              ),
        ],
      ),
    ],
  );
}
