import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../degradacion/presentation/etiquetas.dart';
import '../application/historial_providers.dart';
import 'historial_screen.dart';
import 'widgets/graficas.dart';

/// Dashboard: accesos a la calculadora y la simulación, y resumen del último
/// cálculo y la última simulación guardados.
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final calculo = ref.watch(calculosGuardadosProvider).value?.firstOrNull;
    final simulacion = ref
        .watch(simulacionesGuardadasProvider)
        .value
        ?.firstOrNull;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Solarix'),
        actions: [
          IconButton(
            tooltip: 'Historial',
            icon: const Icon(Icons.history),
            onPressed: () => context.go(Rutas.historial),
          ),
          IconButton(
            tooltip: 'Mi perfil',
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () => context.go(Rutas.perfil),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref
            ..invalidate(calculosGuardadosProvider)
            ..invalidate(simulacionesGuardadasProvider);
        },
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.wb_sunny_rounded,
                      size: 40,
                      color: tema.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Calculadora solar y simulador de degradación de '
                        'baterías',
                        style: tema.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: () => context.go(Rutas.calculadora),
                      icon: const Icon(Icons.calculate_outlined),
                      label: const Text('Calcular mi sistema solar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => context.go(Rutas.simulacion),
                      icon: const Icon(Icons.battery_charging_full_outlined),
                      label: const Text('Simular degradación de batería'),
                    ),
                  ],
                ),
                Card(
                  margin: const EdgeInsets.only(top: 16),
                  child: calculo == null
                      ? const ListTile(
                          leading: Icon(Icons.calculate_outlined),
                          title: Text('Aún no tienes cálculos guardados'),
                          subtitle: Text(
                            'Calcula tu sistema y guárdalo para verlo aquí.',
                          ),
                        )
                      : ListTile(
                          leading: const Icon(Icons.calculate_outlined),
                          title: Text('Último cálculo: ${calculo.titulo}'),
                          subtitle: Text(
                            '${fechaCorta(calculo.creadoEn)} · '
                            '${calculo.numeroPaneles} paneles '
                            '(${Formato.numero(calculo.potenciaKw, 2)} kWp) · '
                            '${Formato.cop(calculo.costoTotal)} · recupera en '
                            '${Formato.anios(calculo.paybackAnios, 20).toLowerCase()}',
                          ),
                          onTap: () => context.go(Rutas.historial),
                        ),
                ),
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  child: simulacion == null
                      ? const ListTile(
                          leading: Icon(Icons.battery_charging_full_outlined),
                          title: Text('Aún no tienes simulaciones guardadas'),
                          subtitle: Text(
                            'Simula la batería y guárdala para ver su salud '
                            'aquí.',
                          ),
                        )
                      : InkWell(
                          onTap: () => context.push(
                            Rutas.detalleSimulacion,
                            extra: simulacion,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'Última simulación: SoH '
                                  '${Formato.numero(simulacion.sohFinal, 1)} % '
                                  '(${simulacion.politica.etiqueta.toLowerCase()})',
                                  style: tema.textTheme.titleSmall,
                                ),
                                Text(
                                  fechaCorta(simulacion.creadoEn),
                                  style: tema.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 12),
                                GraficaSoh(
                                  sohMensual: [
                                    for (final m in simulacion.serie) m.soh,
                                  ],
                                  etiqueta: simulacion.politica.etiqueta,
                                  alternativaAnual:
                                      simulacion.sohAnualAlternativa,
                                  etiquetaAlternativa:
                                      simulacion.politicaAlternativa.etiqueta,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.go(Rutas.historial),
                  icon: const Icon(Icons.history),
                  label: const Text('Ver todo el historial'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
