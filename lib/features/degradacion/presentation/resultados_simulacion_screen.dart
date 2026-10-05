import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/widgets/navegacion.dart';
import '../../auth/presentation/widgets/auth_widgets.dart';
import '../../dashboard/application/historial_providers.dart';
import '../../dashboard/presentation/widgets/graficas.dart';
import '../application/simulacion_providers.dart';
import '../domain/comparacion.dart';
import '../domain/integracion.dart';
import '../domain/parametros.dart';
import '../domain/simulador.dart';
import 'etiquetas.dart';
import 'impacto_financiero.dart';

/// Resultados de la simulación: SoH de la política elegida y comparación
/// lado a lado con la otra política bajo el mismo clima.
class ResultadosSimulacionScreen extends ConsumerStatefulWidget {
  const ResultadosSimulacionScreen({
    super.key,
    required this.comparacion,
    this.origen,
  });

  final ComparacionSimulacion comparacion;

  /// Cálculo del que partió la simulación (Etapa 6), si lo hay.
  final OrigenCalculo? origen;

  @override
  ConsumerState<ResultadosSimulacionScreen> createState() =>
      _ResultadosSimulacionScreenState();
}

class _ResultadosSimulacionScreenState
    extends ConsumerState<ResultadosSimulacionScreen> {
  bool _guardando = false;
  bool _guardada = false;
  String? _error;

  /// Efecto en la inversión del cálculo de origen (Etapa 12), si lo hay.
  late final ImpactoFinanciero? _impacto = switch (widget.origen) {
    null => null,
    final origen => calcularImpacto(
      origen: origen,
      convencional: widget.comparacion.convencional,
      consciente: widget.comparacion.consciente,
      referencia: widget.comparacion.referencia,
      elegida: widget.comparacion.parametros.politica,
    ),
  };

  /// `true` si quedó guardada.
  Future<bool> _guardar() async {
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(simulacionRepositoryProvider)
          .guardar(
            widget.comparacion,
            calculoId: widget.origen?.calculoId,
            impacto: _impacto,
          );
      if (!mounted) return true;
      ref.invalidate(simulacionesGuardadasProvider); // actualiza el dashboard
      setState(() => _guardada = true);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Simulación guardada.')));
      return true;
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
      return false;
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Antes de ir al inicio: si no está guardada, pregunta.
  Future<bool> _puedeSalir() async =>
      _guardada ||
      await confirmarSalidaSinGuardar(
        context,
        que: 'esta simulación',
        guardar: _guardar,
      );

  @override
  Widget build(BuildContext context) {
    final c = widget.comparacion;
    final p = c.parametros;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resultados de la simulación'),
        actions: [BotonInicio(antesDeSalir: _puedeSalir)],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Destacado(resultado: c.principal),
              _Tarjeta(
                titulo: 'Salud de la batería mes a mes',
                icono: Icons.show_chart,
                child: GraficaSoh(
                  sohMensual: [
                    for (final m in serieMensual(c.principal.dias)) m.soh,
                  ],
                  politica: p.politica,
                  alternativaAnual: c.alternativa.sohAnual,
                  alternativaMensual: [
                    for (final m in serieMensual(c.alternativa.dias)) m.soh,
                  ],
                  politicaAlternativa: c.alternativa.parametros.politica,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${Formato.numero(p.capacidadBateriaKwh, 1)} kWh · '
                '${Formato.numero(p.potenciaPanelKw, 1)} kWp · '
                '${textoEntorno(escenario: p.escenario, zona: p.zona, irradianciaMaximaLugar: p.irradianciaMaximaLugar, temperaturaMediaLugar: p.temperaturaMediaLugar)}'
                ' · política '
                '${p.politica.etiqueta.toLowerCase()}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              if (_impacto case final impacto?)
                _Tarjeta(
                  titulo: 'Con el sistema que dimensionaste',
                  icono: Icons.savings_outlined,
                  child: TablaImpacto(impacto: impacto),
                ),
              _Tarjeta(
                titulo: 'Convencional frente a consciente',
                icono: Icons.compare_arrows,
                child: _TablaComparacion(comparacion: c),
              ),
              _Tarjeta(
                titulo: 'Salud de la batería año a año',
                icono: Icons.battery_std_outlined,
                child: _TablaAnual(comparacion: c),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                MensajeError(_error!),
                const SizedBox(height: 12),
              ],
              BotonPrincipal(
                texto: _guardada ? 'Simulación guardada' : 'Guardar simulación',
                cargando: _guardando,
                onPressed: _guardada ? () {} : _guardar,
              ),
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

class _Destacado extends StatelessWidget {
  const _Destacado({required this.resultado});

  final ResultadoSimulacion resultado;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final estilo = Theme.of(context).textTheme;
    final r = resultado;
    final anios = Formato.numero(r.aniosSimulados, 1);
    return Card(
      color: esquema.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${Formato.numero(r.sohFinal, 1)} %',
              style: estilo.displaySmall?.copyWith(
                color: esquema.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              r.finDeVida
                  ? 'La batería llega al fin de vida (80 %) en $anios años'
                  : 'de salud (SoH) después de $anios años',
              style: estilo.bodyLarge?.copyWith(
                color: esquema.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Pierde ${Formato.numero(r.perdidaAnual, 2)} puntos por año '
              '(literatura: 1,3 a 1,7)',
              style: estilo.bodySmall?.copyWith(
                color: esquema.onPrimaryContainer,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _TablaComparacion extends StatelessWidget {
  const _TablaComparacion({required this.comparacion});

  final ComparacionSimulacion comparacion;

  @override
  Widget build(BuildContext context) {
    final cv = comparacion.convencional;
    final cs = comparacion.consciente;
    final elegida = comparacion.parametros.politica;
    String titulo(Politica p) =>
        p == elegida ? '${p.etiqueta}\n(elegida)' : p.etiqueta;
    final filas = <(String, String, String)>[
      (
        'SoH final',
        '${Formato.numero(cv.sohFinal, 2)} %',
        '${Formato.numero(cs.sohFinal, 2)} %',
      ),
      (
        'Pérdida por año',
        Formato.numero(cv.perdidaAnual, 2),
        Formato.numero(cs.perdidaAnual, 2),
      ),
      (
        'Energía comprada a la red',
        '${Formato.numero(cv.energiaCompradaKwh)} kWh',
        '${Formato.numero(cs.energiaCompradaKwh)} kWh',
      ),
      (
        'Ciclos equivalentes',
        Formato.numero(cv.ciclosEquivalentes),
        Formato.numero(cs.ciclosEquivalentes),
      ),
      ('Limpiezas de paneles', '${cv.limpiezas}', '${cs.limpiezas}'),
    ];
    final estilo = Theme.of(context).textTheme;
    final caidaCv = 100 - cv.sohFinal;
    final cambioCaida = caidaCv <= 0 ? 0.0 : (100 - cs.sohFinal) / caidaCv - 1;
    final cambioEnergia = cv.energiaCompradaKwh <= 0
        ? 0.0
        : cs.energiaCompradaKwh / cv.energiaCompradaKwh - 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Table(
          columnWidths: const {0: FlexColumnWidth(1.4)},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: [
            TableRow(
              children: [
                const SizedBox.shrink(),
                for (final p in Politica.values)
                  EncabezadoTabla(titulo(p), estilo: estilo.labelLarge),
              ],
            ),
            for (final (etiqueta, a, b) in filas)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(etiqueta),
                  ),
                  Text(a, textAlign: TextAlign.end),
                  Text(b, textAlign: TextAlign.end),
                ],
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Con el mismo clima, la política consciente cambia la caída del SoH '
          'en ${Formato.numero(cambioCaida * 100, 1)} % y la energía comprada '
          'en ${Formato.numero(cambioEnergia * 100, 1)} %.',
          style: estilo.bodySmall,
        ),
      ],
    );
  }
}

class _TablaAnual extends StatelessWidget {
  const _TablaAnual({required this.comparacion});

  final ComparacionSimulacion comparacion;

  @override
  Widget build(BuildContext context) {
    final cv = comparacion.convencional.sohAnual;
    final cs = comparacion.consciente.sohAnual;
    final anios = cv.length > cs.length ? cv.length : cs.length;
    String valor(List<double> l, int k) =>
        k < l.length ? '${Formato.numero(l[k], 2)} %' : 'fin de vida';
    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        TableRow(
          children: [
            Text('Año', style: Theme.of(context).textTheme.labelLarge),
            for (final p in Politica.values)
              EncabezadoTabla(
                p.etiqueta,
                estilo: Theme.of(context).textTheme.labelLarge,
              ),
          ],
        ),
        for (var k = 1; k < anios; k++)
          TableRow(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('$k'),
              ),
              Text(valor(cv, k), textAlign: TextAlign.end),
              Text(valor(cs, k), textAlign: TextAlign.end),
            ],
          ),
      ],
    );
  }
}

class _Tarjeta extends StatelessWidget {
  const _Tarjeta({
    required this.titulo,
    required this.icono,
    required this.child,
  });

  final String titulo;
  final IconData icono;
  final Widget child;

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
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
