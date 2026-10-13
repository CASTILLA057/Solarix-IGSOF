import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/barra_web.dart';
import '../../../core/widgets/navegacion.dart';
import '../../../core/widgets/solarix_ui.dart';
import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../../dashboard/application/historial_providers.dart';
import '../../degradacion/domain/integracion.dart';
import '../application/calculadora_providers.dart';
import '../domain/calculadora.dart';
import '../domain/modelos.dart';
import 'explicaciones.dart';

/// Resumen del cálculo: consumo, sistema recomendado, costos y retorno.
/// Diseño del mockup (Etapa 13): tarjetas con burbuja y, en web, acciones
/// arriba y tarjetas en dos columnas.
class ResultadosScreen extends ConsumerStatefulWidget {
  const ResultadosScreen({
    super.key,
    required this.entradas,
    required this.resultado,
  });

  final EntradasCalculo entradas;
  final ResultadoCalculo resultado;

  @override
  ConsumerState<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends ConsumerState<ResultadosScreen> {
  bool _guardando = false;
  String? _calculoId;
  String? _error;

  bool get _guardado => _calculoId != null;

  /// La simulación de degradación solo aplica a baterías de litio.
  bool get _puedeSimular =>
      widget.entradas.tipo.usaBateria &&
      widget.entradas.quimica == QuimicaBateria.litio &&
      widget.resultado.bateriaKwh > 0;

  void _simularBateria() {
    // El aviso de "Cálculo guardado" no debe tapar la pantalla siguiente.
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    context.push(
      Rutas.simulacion,
      extra: OrigenCalculo(
        entradas: widget.entradas,
        resultado: widget.resultado,
        calculoId: _calculoId,
      ),
    );
  }

  /// `true` si quedó guardado.
  Future<bool> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final id = await ref
          .read(calculadoraRepositoryProvider)
          .guardarCalculo(widget.entradas, widget.resultado);
      if (!mounted) return true;
      ref.invalidate(calculosGuardadosProvider); // actualiza el dashboard
      setState(() => _calculoId = id);
      final router = GoRouter.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          // Con acción, Flutter lo deja fijo; se cierra solo para no tapar
          // la pantalla siguiente (p. ej., el botón "Simular").
          persist: false,
          duration: const Duration(seconds: 4),
          content: const Text('Cálculo guardado. Lo verás en tu historial.'),
          action: SnackBarAction(
            label: 'VER',
            onPressed: () => router.go(Rutas.historial),
          ),
        ),
      );
      return true;
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
      return false;
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Antes de ir al inicio: si no está guardado, pregunta (sin sesión no
  /// se puede guardar, así que no pregunta).
  Future<bool> _puedeSalir() async =>
      _guardado ||
      !ref.read(haySesionProvider) ||
      await confirmarSalidaSinGuardar(
        context,
        que: 'este cálculo',
        guardar: _guardar,
      );

  Widget _botonGuardar() => ref.watch(haySesionProvider)
      ? BotonPrincipal(
          texto: _guardado ? 'Cálculo guardado' : 'Guardar cálculo',
          cargando: _guardando,
          onPressed: _guardado ? () {} : _guardar,
        )
      : const AvisoSinCuenta(que: 'este cálculo');

  Widget _botonSimular() => OutlinedButton.icon(
    onPressed: _simularBateria,
    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
    icon: const Icon(Icons.battery_charging_full_outlined),
    label: const Text('Simular la salud de esta batería'),
  );

  Widget? _avisoVincular() => !_guardado && ref.watch(haySesionProvider)
      ? Text(
          'Guarda el cálculo antes para que la simulación quede vinculada a '
          'él.',
          style: Theme.of(context).textTheme.bodySmall,
        )
      : null;

  /// Tarjetas del resultado, en el orden del mockup.
  List<Widget> _tarjetas() {
    final e = widget.entradas;
    final r = widget.resultado;
    final anios = e.supuestos.anios;
    final sinBateria = compararSinBateria(e, r);
    return [
      _Seccion(
        titulo: 'Tu consumo',
        icono: Icons.bolt_outlined,
        tono: TonoBurbuja.azul,
        filas: [
          ('Energía diaria', '${Formato.numero(r.energiaDiaKwh, 2)} kWh'),
          ('Energía mensual', '${Formato.numero(r.energiaMesKwh)} kWh'),
          (
            'Horas solares pico',
            '${Formato.numero(e.hsp, 2)} · ${e.ubicacion}',
          ),
          if (e.tipo.usaRed) ...[
            (
              'Estrato',
              e.estrato.subsidio > 0
                  ? '${textoEstratoAplicado(e)} en los primeros '
                        '${Formato.numero(e.consumoSubsistenciaKwh)} kWh/mes'
                  : textoEstrato(e.estrato),
            ),
            (
              'Factura de energía hoy (estimada)',
              Formato.cop(
                facturaEnergia(
                  r.energiaMesKwh,
                  tarifa: e.tarifaKwh,
                  estrato: e.estrato,
                  subsidio: e.subsidioAplicado,
                  consumoSubsistencia: e.consumoSubsistenciaKwh,
                ),
              ),
            ),
          ],
        ],
      ),
      _Seccion(
        titulo: 'Sistema recomendado (${e.tipo.etiqueta.toLowerCase()})',
        icono: Icons.solar_power_outlined,
        filas: [
          (
            'Paneles',
            '${r.numeroPaneles} × ${Formato.numero(e.potenciaPanelW)} W '
                '= ${Formato.numero(r.potenciaInstaladaKw, 2)} kWp',
          ),
          (
            'Generación estimada',
            '${Formato.numero(r.generacionMesKwh)} kWh/mes',
          ),
          if (r.bateriaKwh > 0)
            (
              'Batería (${e.quimica.etiqueta})',
              '${Formato.numero(r.bateriaKwh, 1)} kWh · '
                  '${Formato.numero(r.bateriaAh)} Ah a ${r.voltajeSistema} V',
            ),
          ('Inversor', '${Formato.numero(r.inversorW)} W'),
          if (r.controladorA > 0)
            ('Controlador de carga', '${r.controladorA} A'),
        ],
        nota: Explicacion.margenes,
      ),
      _Seccion(
        titulo: 'Costos estimados',
        icono: Icons.payments_outlined,
        tono: TonoBurbuja.verde,
        filas: [
          ('Paneles', Formato.cop(r.costos.paneles)),
          if (r.costos.baterias > 0)
            ('Baterías', Formato.cop(r.costos.baterias)),
          ('Inversor', Formato.cop(r.costos.inversor)),
          if (r.costos.controlador > 0)
            ('Controlador', Formato.cop(r.costos.controlador)),
          ('Estructura y cableado', Formato.cop(r.costos.estructura)),
          ('Instalación', Formato.cop(r.costos.instalacion)),
        ],
        total: ('Total', Formato.cop(r.costos.total)),
        // En web la nota va a lo ancho, debajo de las tarjetas (mockup).
        aviso: r.costos.ivaExcluido > 0 && !esAncho(context)
            ? 'Sin IVA (Ley 1715): te ahorras '
                  '${Formato.cop(r.costos.ivaExcluido)}, ya descontados de '
                  'cada valor.'
            : null,
      ),
      _Seccion(
        titulo: 'Ahorro y retorno',
        icono: Icons.trending_up,
        tono: TonoBurbuja.verde,
        filas: [
          ('Ahorro el primer mes', Formato.cop(r.ahorroMensual)),
          if (r.excedentePermutadoMesKwh > 0)
            (
              'Excedente que se descuenta de tu factura',
              '${Formato.numero(r.excedentePermutadoMesKwh)} kWh/mes',
            ),
          if (r.excedenteVendidoMesKwh > 0)
            (
              'Excedente vendido a precio de bolsa',
              '${Formato.numero(r.excedenteVendidoMesKwh)} kWh/mes',
            ),
          if (r.beneficioRenta > 0)
            ('Deducción de renta (año 1)', Formato.cop(r.beneficioRenta)),
          (
            'Recuperación de la inversión',
            Formato.anios(r.paybackAnios, anios),
          ),
          (
            'Recuperación descontada',
            Formato.anios(r.paybackDescontadoAnios, anios),
          ),
          ('Valor presente neto (VPN)', Formato.cop(r.vpn)),
          ('Ahorro total en $anios años', Formato.cop(r.ahorroTotal)),
          ('Costo total en $anios años', Formato.cop(r.gastosTotales)),
        ],
        nota: e.tipo.usaBateria
            ? 'Incluye cambiar la batería cada '
                  '${e.quimica.vidaUtilAnios} años (vida típica).'
                  '${_puedeSimular ? ' Con "Simular la salud de esta batería" '
                            'se calcula con su degradación.' : ''}'
            : null,
      ),
      if (sinBateria != null)
        _Seccion(
          titulo: '¿Y sin batería?',
          icono: Icons.compare_arrows,
          tono: TonoBurbuja.azul,
          filas: [
            (
              'Inversión sin batería',
              Formato.cop(sinBateria.sinBateria.costos.total),
            ),
            (
              'Ahorro el primer mes sin batería',
              Formato.cop(sinBateria.sinBateria.ahorroMensual),
            ),
            (
              'Recuperación sin batería',
              Formato.anios(sinBateria.sinBateria.paybackAnios, anios),
            ),
            ('VPN sin batería', Formato.cop(sinBateria.sinBateria.vpn)),
          ],
          nota: _notaSinBateria(sinBateria),
        ),
    ];
  }

  List<Widget> _contenidoCelular() => [
    _Destacado(resultado: widget.resultado),
    ..._tarjetas(),
    const SizedBox(height: 16),
    if (_error != null) ...[MensajeError(_error!), const SizedBox(height: 12)],
    _botonGuardar(),
    if (_puedeSimular) ...[
      const SizedBox(height: 12),
      _botonSimular(),
      if (_avisoVincular() case final aviso?)
        Padding(padding: const EdgeInsets.only(top: 8), child: aviso),
    ],
    const SizedBox(height: 4),
    BotonVolverAlInicio(antesDeSalir: _puedeSalir),
    const SizedBox(height: 24),
  ];

  List<Widget> _contenidoWeb() {
    final tema = Theme.of(context);
    final e = widget.entradas;
    final tarjetas = _tarjetas();
    final r = widget.resultado;
    final titulo = e.nombre.trim().isEmpty
        ? 'Resultados'
        : 'Resultados · ${e.nombre.trim()}';
    final subtitulo = [
      'Sistema ${e.tipo.etiqueta.toLowerCase()}',
      if (e.ubicacion.isNotEmpty) e.ubicacion,
    ].join(' · ');
    return [
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
          label: const Text('Volver a la calculadora'),
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(titulo, style: tema.textTheme.headlineSmall),
                Text(
                  subtitulo,
                  style: tema.textTheme.bodyLarge?.copyWith(
                    color: tema.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (_puedeSimular) ...[
            SizedBox(width: 300, child: _botonSimular()),
            const SizedBox(width: 12),
          ],
          SizedBox(width: 220, child: _botonGuardar()),
        ],
      ),
      if (_puedeSimular && _avisoVincular() != null)
        Align(alignment: Alignment.centerRight, child: _avisoVincular()),
      if (_error != null) ...[
        const SizedBox(height: 12),
        MensajeError(_error!),
      ],
      const SizedBox(height: 16),
      _Destacado(resultado: widget.resultado, conAhorro: true),
      for (var i = 0; i < tarjetas.length; i += 2)
        i + 1 < tarjetas.length
            ? dosColumnas(context, tarjetas[i], tarjetas[i + 1])
            : tarjetas[i],
      if (r.costos.ivaExcluido > 0) ...[
        const SizedBox(height: 16),
        Aviso(
          icono: Icons.info_outline,
          texto:
              'Sin IVA (Ley 1715): te ahorras '
              '${Formato.cop(r.costos.ivaExcluido)}. Necesitas el certificado '
              'de la UPME.',
        ),
      ],
      const SizedBox(height: 16),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => irAlInicio(context, _puedeSalir),
          icon: const Icon(Icons.home_outlined),
          label: const Text('Volver al inicio'),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ancho = esAncho(context);
    return Scaffold(
      appBar: ancho
          ? BarraWeb(antesDeSalir: _puedeSalir)
          : AppBar(
              title: const Text('Resultados'),
              actions: [BotonInicio(antesDeSalir: _puedeSalir)],
            ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: ancho ? anchoMaximoWeb : 640),
          child: ListView(
            padding: ancho
                ? const EdgeInsets.fromLTRB(24, 24, 24, 56)
                : const EdgeInsets.all(16),
            children: ancho ? _contenidoWeb() : _contenidoCelular(),
          ),
        ),
      ),
    );
  }
}

/// Qué aporta la batería del híbrido frente al mismo sistema sin ella.
String _notaSinBateria(ComparacionSinBateria c) {
  final diferencia = Formato.cop(c.diferenciaVpn.abs());
  final autoconsumo = Formato.numero(c.autoconsumoSinBateria * 100);
  final base =
      'Los mismos paneles conectados a la red, sin batería ni controlador y '
      'con $autoconsumo % de autoconsumo (sin batería solo se usa lo que la '
      'casa consume mientras hay sol).';
  return c.diferenciaVpn < 0
      ? 'La batería resta $diferencia al VPN: con la CREG 174 lo que no '
            'guarda se descuenta de tu factura casi al mismo precio, así que '
            'en plata conviene sin batería. Su valor está en cubrir los cortes '
            'de luz. $base'
      : 'La batería suma $diferencia al VPN. Además cubre los cortes de luz. '
            '$base';
}

/// Cifras principales sobre ámbar suave con borde ámbar (mockup). En web
/// se suma el ahorro del primer mes.
class _Destacado extends StatelessWidget {
  const _Destacado({required this.resultado, this.conAhorro = false});

  final ResultadoCalculo resultado;
  final bool conAhorro;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = ColoresSolarix.of(context);
    Widget cifra(String valor, String etiqueta) => Expanded(
      child: Column(
        children: [
          // En una línea: en pantallas angostas la cifra se achica en vez
          // de partirse ("5.031.38" / "3 $").
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              valor,
              maxLines: 1,
              style: tema.textTheme.titleLarge?.copyWith(
                color: tema.colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Text(
            etiqueta,
            style: tema.textTheme.bodySmall?.copyWith(
              color: tema.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    final separador = VerticalDivider(
      color: colores.solar.withValues(alpha: 0.5),
      width: 1,
    );
    final r = resultado;
    final anios = r.paybackAnios == null
        ? '—'
        : Formato.numero(r.paybackAnios!, 1);
    // Como el mockup: en celular, cifras cortas; en web, con su unidad.
    final cifras = conAhorro
        ? [
            cifra(
              Formato.paneles(r.numeroPaneles),
              '${Formato.numero(r.potenciaInstaladaKw, 1)} kWp instalados',
            ),
            cifra(Formato.copCorto(r.costos.total), 'inversión total'),
            cifra(Formato.cop(r.ahorroMensual), 'ahorro el primer mes'),
            cifra(
              r.paybackAnios == null ? '—' : '$anios años',
              'para recuperar la inversión',
            ),
          ]
        : [
            cifra(
              '${r.numeroPaneles}',
              r.numeroPaneles == 1 ? 'panel' : 'paneles',
            ),
            cifra(Formato.copCorto(r.costos.total), 'inversión'),
            cifra(anios, 'años para recuperar'),
          ];
    return Card(
      margin: EdgeInsets.zero,
      color: colores.solarSuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colores.solar),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, c) in cifras.indexed) ...[
                if (i > 0 && conAhorro) separador,
                c,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta de resultados: burbuja + título, filas, total, aviso y nota.
class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.filas,
    this.tono = TonoBurbuja.solar,
    this.total,
    this.aviso,
    this.nota,
  });

  final String titulo;
  final IconData icono;
  final TonoBurbuja tono;
  final List<(String, String)> filas;

  /// Fila de total, separada por una línea.
  final (String, String)? total;

  /// Nota destacada en una banda azul (p. ej., Ley 1715).
  final String? aviso;
  final String? nota;

  @override
  Widget build(BuildContext context) => TarjetaSeccion(
    titulo: titulo,
    icono: icono,
    tono: tono,
    children: [
      for (final (etiqueta, valor) in filas) FilaDato(etiqueta, valor),
      if (total case (final etiqueta, final valor)) ...[
        const Divider(height: 16),
        FilaDato(etiqueta, valor, total: true),
      ],
      if (aviso case final a?) ...[
        const SizedBox(height: 8),
        Aviso(icono: Icons.info_outline, texto: a),
      ],
      if (nota case final n?) ...[
        const SizedBox(height: 8),
        Text(n, style: Theme.of(context).textTheme.bodySmall),
      ],
    ],
  );
}
