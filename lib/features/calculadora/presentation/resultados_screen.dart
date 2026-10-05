import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/navegacion.dart';
import '../../dashboard/application/historial_providers.dart';
import '../../degradacion/domain/integracion.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../application/calculadora_providers.dart';
import '../domain/modelos.dart';
import 'explicaciones.dart';

/// Resumen del cálculo: consumo, sistema recomendado, costos y retorno.
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

  void _simularBateria() => context.push(
    Rutas.simulacion,
    extra: OrigenCalculo(
      entradas: widget.entradas,
      resultado: widget.resultado,
      calculoId: _calculoId,
    ),
  );

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
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cálculo guardado.')));
      return true;
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
      return false;
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Antes de ir al inicio: si no está guardado, pregunta.
  Future<bool> _puedeSalir() async =>
      _guardado ||
      await confirmarSalidaSinGuardar(
        context,
        que: 'este cálculo',
        guardar: _guardar,
      );

  @override
  Widget build(BuildContext context) {
    final e = widget.entradas;
    final r = widget.resultado;
    final anios = e.supuestos.anios;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados'),
        actions: [BotonInicio(antesDeSalir: _puedeSalir)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Destacado(resultado: r, entradas: e),
              _Seccion(
                titulo: 'Tu consumo',
                icono: Icons.bolt_outlined,
                filas: [
                  (
                    'Energía diaria',
                    '${Formato.numero(r.energiaDiaKwh, 2)} kWh',
                  ),
                  ('Energía mensual', '${Formato.numero(r.energiaMesKwh)} kWh'),
                  (
                    'Horas solares pico',
                    '${Formato.numero(e.hsp, 2)} · ${e.ubicacion}',
                  ),
                ],
              ),
              _Seccion(
                titulo:
                    'Sistema recomendado (${e.tipo.etiqueta.toLowerCase()})',
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
                filas: [
                  ('Paneles', Formato.cop(r.costos.paneles)),
                  if (r.costos.baterias > 0)
                    ('Baterías', Formato.cop(r.costos.baterias)),
                  ('Inversor', Formato.cop(r.costos.inversor)),
                  if (r.costos.controlador > 0)
                    ('Controlador', Formato.cop(r.costos.controlador)),
                  ('Estructura y cableado', Formato.cop(r.costos.estructura)),
                  ('Instalación', Formato.cop(r.costos.instalacion)),
                  ('Total', Formato.cop(r.costos.total)),
                ],
                nota: r.costos.ivaExcluido > 0
                    ? 'Sin IVA (Ley 1715): te ahorras '
                          '${Formato.cop(r.costos.ivaExcluido)}, ya descontados '
                          'de cada valor.'
                    : null,
              ),
              _Seccion(
                titulo: 'Ahorro y retorno',
                icono: Icons.trending_up,
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
                    (
                      'Deducción de renta (año 1)',
                      Formato.cop(r.beneficioRenta),
                    ),
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
                          '${e.quimica.vidaUtilAnios} años (vida típica). En el '
                          'siguiente módulo se calculará con la simulación de '
                          'degradación.'
                    : null,
              ),
              const SizedBox(height: 8),
              if (_error != null) ...[
                MensajeError(_error!),
                const SizedBox(height: 12),
              ],
              BotonPrincipal(
                texto: _guardado ? 'Cálculo guardado' : 'Guardar cálculo',
                cargando: _guardando,
                onPressed: _guardado ? () {} : _guardar,
              ),
              if (_puedeSimular) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _simularBateria,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(Icons.battery_charging_full_outlined),
                  label: const Text('Simular la salud de esta batería'),
                ),
                if (!_guardado)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Guarda el cálculo antes para que la simulación quede '
                      'vinculada a él.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
              const SizedBox(height: 4),
              BotonVolverAlInicio(antesDeSalir: _puedeSalir),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tarjeta con las cifras principales.
class _Destacado extends StatelessWidget {
  const _Destacado({required this.resultado, required this.entradas});

  final ResultadoCalculo resultado;
  final EntradasCalculo entradas;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme;
    Widget cifra(String valor, String etiqueta) => Expanded(
      child: Column(
        children: [
          Text(
            valor,
            style: estilo.titleLarge?.copyWith(
              color: esquema.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            etiqueta,
            style: estilo.bodySmall?.copyWith(
              color: esquema.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
    return Card(
      color: esquema.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            cifra('${resultado.numeroPaneles}', 'paneles'),
            cifra(Formato.cop(resultado.costos.total), 'inversión'),
            cifra(
              resultado.paybackAnios == null
                  ? '—'
                  : Formato.numero(resultado.paybackAnios!, 1),
              'años para recuperarla',
            ),
          ],
        ),
      ),
    );
  }
}

class _Seccion extends StatelessWidget {
  const _Seccion({
    required this.titulo,
    required this.icono,
    required this.filas,
    this.nota,
  });

  final String titulo;
  final IconData icono;
  final List<(String, String)> filas;
  final String? nota;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icono, color: tema.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titulo, style: tema.textTheme.titleMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final (etiqueta, valor) in filas)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(etiqueta)),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        valor,
                        textAlign: TextAlign.end,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            if (nota != null) ...[
              const SizedBox(height: 8),
              Text(nota!, style: tema.textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
