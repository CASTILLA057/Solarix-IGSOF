import '../../../core/widgets/etiqueta_segmento.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/navegacion.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../application/calculadora_providers.dart';
import '../domain/calculadora.dart';
import '../domain/catalogos.dart';
import '../domain/modelos.dart';
import 'explicaciones.dart';
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
  Estrato _estrato = Estrato.cuatro;

  /// Subsidio de la factura (%), solo en los estratos 1 a 3; empieza en el
  /// máximo legal del estrato.
  final _subsidio = TextEditingController();

  /// Consumo de subsistencia elegido a mano; `null` = el del lugar.
  double? _subsistenciaElegida;
  final _gastoActual = TextEditingController(text: '0');

  // Paso 3: ubicación
  _FuenteHsp _fuente = _FuenteHsp.ciudad;
  Ciudad? _ciudad;

  /// Cambia cuando llega la ciudad del perfil, para que la lista la muestre.
  int _versionCiudad = 0;
  bool _ciudadElegida = false;
  double? _hspUbicacion;
  ClimaLugar? _climaUbicacion;
  double? _altitudUbicacion;
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
  final _autoconsumo = TextEditingController(
    text: _porcentajeTexto(Supuestos.autoconsumoPorDefecto(TipoSistema.onGrid)),
  );
  bool _autoconsumoEditado = false;
  final _fraccionNocturna = TextEditingController(text: '50');
  final _comercializacion = TextEditingController(text: '100');
  final _precioBolsa = TextEditingController(text: '300');
  final _mantenimiento = TextEditingController(text: '1');
  bool _exclusionIva = false;
  final _tarifaRenta = TextEditingController(text: '0');

  /// Precios de referencia (en Dart, Etapa 12), editables.
  final _precios = <String, TextEditingController>{
    for (final MapEntry(key: clave, value: valor)
        in Precios.referencia.aMapa().entries)
      clave: TextEditingController(
        text: clave == 'instalacion_porcentaje'
            ? Formato.numero((valor as double) * 100)
            : Formato.numero(valor as double),
      ),
  };

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
  void initState() {
    super.initState();
    // Lugar por defecto: la ciudad del perfil, si el usuario aún no eligió.
    if (ref.read(haySesionProvider)) {
      ref.listenManual(perfilProvider, (_, perfil) {
        final ciudad = ciudadPorNombre(perfil.value?.ciudad);
        if (ciudad == null || _ciudadElegida || _ciudad != null) return;
        setState(() {
          _ciudad = ciudad;
          _versionCiudad++;
        });
      }, fireImmediately: true);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nombre,
      _consumoMes,
      _tarifa,
      _subsidio,
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
      _autoconsumo,
      _fraccionNocturna,
      _comercializacion,
      _precioBolsa,
      _mantenimiento,
      _tarifaRenta,
      ..._precios.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? get _hsp => switch (_fuente) {
    _FuenteHsp.ciudad => _ciudad?.hsp,
    _FuenteHsp.ubicacion => _hspUbicacion,
    _FuenteHsp.manual => Formato.leer(_hspManual.text),
  };

  /// Clima del lugar para elegir la zona de la simulación; sin dato con HSP
  /// a mano.
  ClimaLugar? get _clima => switch (_fuente) {
    _FuenteHsp.ciudad =>
      _ciudad == null ? null : climaDeCiudad(_ciudad!.nombre),
    _FuenteHsp.ubicacion => _climaUbicacion,
    _FuenteHsp.manual => null,
  };

  /// Consumo de subsistencia del lugar: el del municipio de la ciudad o el
  /// de la altitud del GPS; `null` sin dato (HSP a mano o GPS sin altitud).
  double? get _subsistenciaLugar => switch (_fuente) {
    _FuenteHsp.ciudad => _ciudad?.consumoSubsistenciaKwh,
    _FuenteHsp.ubicacion =>
      _altitudUbicacion == null
          ? null
          : ConsumoSubsistencia.paraAltitud(_altitudUbicacion!),
    _FuenteHsp.manual => null,
  };

  /// Con subsidio y sin dato del lugar ni elección a mano se usan 173 kWh:
  /// hay que avisarlo.
  bool get _subsistenciaSupuesta =>
      _tipo.usaRed &&
      _estrato.subsidio > 0 &&
      _subsistenciaElegida == null &&
      _subsistenciaLugar == null;

  /// Subsidio de la factura; `null` si es el máximo legal o no aplica.
  double? get _subsidioFactura {
    if (_estrato.subsidio == 0) return null;
    final valor = Formato.leer(_subsidio.text);
    if (valor == null) return null;
    final fraccion = valor / 100;
    return (fraccion - _estrato.subsidio).abs() < 1e-9 ? null : fraccion;
  }

  /// Opciones del consumo de subsistencia: valor, texto de la lista y texto
  /// corto para el campo cerrado.
  static const _opcionesSubsistencia = <(double?, String, String)>[
    (null, 'Según el lugar (ciudad o GPS)', 'Según el lugar'),
    (
      ConsumoSubsistencia.menosDe1000m,
      '173 kWh/mes · menos de 1.000 m',
      '173 kWh/mes',
    ),
    (
      ConsumoSubsistencia.desde1000m,
      '130 kWh/mes · 1.000 m o más',
      '130 kWh/mes',
    ),
  ];

  /// Texto del campo cerrado de una lista: una línea y "…" si no cabe.
  static Widget _enUnaLinea(String texto) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: Text(texto, maxLines: 1, overflow: TextOverflow.ellipsis),
  );

  void _elegirEstrato(Estrato e) => setState(() {
    _estrato = e;
    _subsidio.text = _porcentajeTexto(e.subsidio);
  });

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

  static String _porcentajeTexto(double fraccion) =>
      Formato.numero(fraccion * 100);

  /// Al cambiar el tipo de sistema, el autoconsumo toma el valor típico del
  /// nuevo tipo, salvo que el usuario ya lo haya escrito.
  void _elegirTipo(TipoSistema tipo) => setState(() {
    _tipo = tipo;
    if (!_autoconsumoEditado) {
      _autoconsumo.text = _porcentajeTexto(
        Supuestos.autoconsumoPorDefecto(tipo),
      );
    }
  });

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
      estrato: _tipo.usaRed ? _estrato : Estrato.cuatro,
      subsidioEstrato: _tipo.usaRed ? _subsidioFactura : null,
      consumoSubsistenciaKwh:
          _subsistenciaElegida ??
          _subsistenciaLugar ??
          ConsumoSubsistencia.menosDe1000m,
      gastoActualMensual: Formato.leer(_gastoActual.text) ?? 0,
      hsp: _hsp!,
      ubicacion: _ubicacion,
      clima: _clima,
      potenciaPanelW: Formato.leer(_potenciaPanel.text)!,
      quimica: _quimica,
      supuestos: Supuestos(
        rendimientoSistema: _porcentaje(_rendimiento),
        diasAutonomia: Formato.leer(_diasAutonomia.text)!,
        cobertura: _porcentaje(_cobertura),
        fraccionNocturna: _porcentaje(_fraccionNocturna),
        autoconsumo: _tipo.usaRed ? _porcentaje(_autoconsumo) : null,
        costoComercializacion: Formato.leer(_comercializacion.text)!,
        precioBolsa: Formato.leer(_precioBolsa.text)!,
        incrementoTarifa: _porcentaje(_incrementoTarifa),
        mantenimientoAnual: _porcentaje(_mantenimiento),
        tasaDescuento: _porcentaje(_tasaDescuento),
        anios: Formato.leer(_anios.text)!.round(),
        vidaCalendarioBateria: _simulable
            ? Formato.leer(_vidaCalendario.text)
            : null,
        exclusionIva: _exclusionIva,
        tarifaRenta: _porcentaje(_tarifaRenta),
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
      final recurso = await ref
          .read(recursoSolarProvider)
          .recursoEnUbicacionActual();
      if (mounted) {
        setState(() {
          _hspUbicacion = recurso.hsp;
          _climaUbicacion = recurso.clima;
          _altitudUbicacion = recurso.altitudM;
        });
      }
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _errorUbicacion = e.mensaje);
    } finally {
      if (mounted) setState(() => _buscandoUbicacion = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                content: Form(key: _formularios[3], child: _pasoEquipos()),
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
        onChanged: (t) => _elegirTipo(t!),
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
            label: EtiquetaSegmento('Mis equipos'),
            icon: Icon(Icons.kitchen_outlined),
          ),
          ButtonSegment(
            value: ModoConsumo.factura,
            label: EtiquetaSegmento('Mi factura'),
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
      if (_tipo.usaRed) ...[
        CampoNumero(
          controller: _tarifa,
          etiqueta: 'Tarifa de la energía',
          sufijo: 'COP/kWh',
          ayuda: 'Sin subsidio ni contribución (la del estrato 4).',
          explicacion: Explicacion.tarifa,
          minimo: 1,
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Estrato>(
          initialValue: _estrato,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Estrato de la vivienda',
            suffixIcon: BotonExplicacion(
              titulo: 'Estrato',
              texto: Explicacion.estrato,
            ),
          ),
          items: [
            for (final e in Estrato.values)
              DropdownMenuItem(value: e, child: Text(textoEstrato(e))),
          ],
          // En el campo cerrado va la versión corta: con el ícono ⓘ, la
          // larga se cortaba a mitad de frase en un celular de 360 dp.
          selectedItemBuilder: (_) => [
            for (final e in Estrato.values) _enUnaLinea(textoEstratoCorto(e)),
          ],
          onChanged: (e) => _elegirEstrato(e!),
        ),
        if (_estrato.subsidio > 0) ...[
          const SizedBox(height: 16),
          CampoNumero(
            key: ValueKey('subsidio-${_estrato.numero}'),
            controller: _subsidio,
            etiqueta: 'Subsidio de tu factura',
            sufijo: '%',
            ayuda:
                'Máximo de la ley: ${_porcentajeTexto(_estrato.subsidio)} %. '
                'Escribe el de tu factura si es otro.',
            explicacion: Explicacion.subsidioFactura,
            minimo: 0,
            maximo: _estrato.subsidio * 100,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<double?>(
            initialValue: _subsistenciaElegida,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Consumo de subsistencia',
              suffixIcon: BotonExplicacion(
                titulo: 'Consumo de subsistencia',
                texto: Explicacion.subsistencia,
              ),
            ),
            items: [
              for (final (valor, largo, _) in _opcionesSubsistencia)
                DropdownMenuItem<double?>(value: valor, child: Text(largo)),
            ],
            selectedItemBuilder: (_) => [
              for (final (_, _, corto) in _opcionesSubsistencia)
                _enUnaLinea(corto),
            ],
            onChanged: (v) => setState(() => _subsistenciaElegida = v),
          ),
        ],
      ] else
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
    const ciudades = ciudadesBase;
    final hsp = _hsp;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SegmentedButton<_FuenteHsp>(
          // Sin el ✓: con él, "Mi ubicación" se achicaba hasta casi no
          // leerse en un celular de 360 dp. La opción elegida se sigue viendo
          // por el fondo.
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: _FuenteHsp.ciudad,
              label: EtiquetaSegmento('Ciudad'),
            ),
            ButtonSegment(
              value: _FuenteHsp.ubicacion,
              label: EtiquetaSegmento('Mi ubicación'),
            ),
            ButtonSegment(
              value: _FuenteHsp.manual,
              label: EtiquetaSegmento('Manual'),
            ),
          ],
          selected: {_fuente},
          onSelectionChanged: (s) => setState(() => _fuente = s.first),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: switch (_fuente) {
            _FuenteHsp.ciudad => DropdownButtonFormField<Ciudad>(
              key: ValueKey('ciudad-$_versionCiudad'),
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
              onChanged: (c) => setState(() {
                _ciudad = c;
                _ciudadElegida = true;
              }),
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
          if (_subsistenciaSupuesta) ...[
            const SizedBox(height: 8),
            Text(
              'Sin la altura del lugar se usa un consumo de subsistencia de '
              '173 kWh/mes. Si vives a 1.000 m o más, elige 130 en el paso '
              '"Consumo".',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
          explicacion: Explicacion.diasAutonomia,
          minimo: 0.5,
          maximo: 7,
        ),
      ] else ...[
        const SizedBox(height: 16),
        CampoNumero(
          controller: _cobertura,
          etiqueta: 'Parte del consumo a cubrir con paneles',
          sufijo: '%',
          explicacion: Explicacion.cobertura,
          minimo: 10,
          maximo: 200,
        ),
      ],
      const SizedBox(height: 8),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Supuestos técnicos y financieros'),
        subtitle: const Text('Toca ⓘ para ver de dónde sale cada valor'),
        childrenPadding: const EdgeInsets.only(top: _margenEtiqueta, bottom: 8),
        children: [
          CampoNumero(
            controller: _rendimiento,
            etiqueta: 'Rendimiento del sistema (PR)',
            sufijo: '%',
            ayuda: 'Pérdidas por calor, cableado, suciedad e inversor.',
            explicacion: Explicacion.rendimiento,
            minimo: 50,
            maximo: 95,
          ),
          if (_tipo.usaRed) ...[
            const SizedBox(height: 12),
            CampoNumero(
              controller: _autoconsumo,
              etiqueta: 'Autoconsumo',
              sufijo: '% de la generación',
              ayuda:
                  'Lo que la casa usa en el momento; el resto sale a la red.',
              explicacion: Explicacion.autoconsumo,
              minimo: 0,
              maximo: 100,
              onChanged: (_) => _autoconsumoEditado = true,
            ),
          ],
          if (_tipo == TipoSistema.hibrido) ...[
            const SizedBox(height: 12),
            CampoNumero(
              controller: _fraccionNocturna,
              etiqueta: 'Consumo sin sol',
              sufijo: '% del consumo',
              ayuda: 'Lo que la batería debe cubrir cada noche.',
              explicacion: Explicacion.fraccionNocturna,
              minimo: 0,
              maximo: 100,
            ),
          ],
          if (_tipo.usaRed) ...[
            const SizedBox(height: 12),
            CampoNumero(
              controller: _comercializacion,
              etiqueta: 'Costo de comercialización (Cv)',
              sufijo: 'COP/kWh',
              ayuda: 'Se descuenta del excedente que se permuta.',
              explicacion: Explicacion.comercializacion,
              minimo: 0,
            ),
            const SizedBox(height: 12),
            CampoNumero(
              controller: _precioBolsa,
              etiqueta: 'Precio de bolsa',
              sufijo: 'COP/kWh',
              ayuda: 'Paga el excedente que supera lo que tomas de la red.',
              explicacion: Explicacion.precioBolsa,
              minimo: 0,
            ),
          ],
          const SizedBox(height: 12),
          CampoNumero(
            controller: _incrementoTarifa,
            etiqueta: 'Aumento anual del precio de la energía',
            sufijo: '%',
            explicacion: Explicacion.incrementoTarifa,
            minimo: 0,
            maximo: 30,
          ),
          const SizedBox(height: 12),
          CampoNumero(
            controller: _mantenimiento,
            etiqueta: 'Mantenimiento anual',
            sufijo: '% de la inversión',
            explicacion: Explicacion.mantenimiento,
            minimo: 0,
            maximo: 10,
          ),
          const SizedBox(height: 12),
          CampoNumero(
            controller: _tasaDescuento,
            etiqueta: 'Tasa de descuento',
            sufijo: '%',
            ayuda: 'Rentabilidad que exigirías a tu dinero (para el VPN).',
            explicacion: Explicacion.tasaDescuento,
            minimo: 0,
            maximo: 50,
          ),
          const SizedBox(height: 12),
          CampoNumero(
            controller: _anios,
            etiqueta: 'Horizonte del análisis',
            sufijo: 'años',
            explicacion: Explicacion.horizonte,
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
              explicacion: Explicacion.vidaCalendario,
              minimo: 5,
              maximo: 30,
            ),
          ],
        ],
      ),
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        title: const Text('Incentivos de la Ley 1715'),
        subtitle: const Text('Necesitan el certificado de la UPME'),
        childrenPadding: const EdgeInsets.only(top: _margenEtiqueta, bottom: 8),
        children: [
          Text(
            Explicacion.ley1715,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Comprar sin IVA'),
            subtitle: const Text(
              'Exclusión de IVA (19 %) en equipos y servicios',
            ),
            secondary: const BotonExplicacion(
              titulo: 'Comprar sin IVA',
              texto: Explicacion.exclusionIva,
            ),
            value: _exclusionIva,
            onChanged: (v) => setState(() => _exclusionIva = v),
          ),
          const SizedBox(height: 4),
          CampoNumero(
            controller: _tarifaRenta,
            etiqueta: 'Tu tarifa marginal de renta',
            sufijo: '%',
            ayuda: '0 si no declaras renta.',
            explicacion: Explicacion.tarifaRenta,
            minimo: 0,
            maximo: 39,
          ),
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
