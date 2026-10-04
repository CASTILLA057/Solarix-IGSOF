import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/estados.dart';
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
    final calculos = ref.watch(calculosGuardadosProvider);
    final simulaciones = ref.watch(simulacionesGuardadasProvider);
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
                  child: _Resumen(
                    valor: calculos,
                    que: 'tus cálculos',
                    alReintentar: () =>
                        ref.invalidate(calculosGuardadosProvider),
                    contenido: (calculo) => calculo == null
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
                ),
                Card(
                  margin: const EdgeInsets.only(top: 12),
                  child: _Resumen(
                    valor: simulaciones,
                    que: 'tus simulaciones',
                    alReintentar: () =>
                        ref.invalidate(simulacionesGuardadasProvider),
                    contenido: (simulacion) => simulacion == null
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

/// Resumen del elemento más reciente de una lista guardada, con sus estados
/// de carga y error.
class _Resumen<T> extends StatelessWidget {
  const _Resumen({
    required this.valor,
    required this.que,
    required this.alReintentar,
    required this.contenido,
  });

  final AsyncValue<List<T>> valor;

  /// "tus cálculos", "tus simulaciones".
  final String que;
  final VoidCallback alReintentar;

  /// Recibe el más reciente, o `null` si no hay ninguno.
  final Widget Function(T?) contenido;

  @override
  Widget build(BuildContext context) => valor.when(
    // Al recargar se sigue mostrando el dato anterior.
    skipLoadingOnRefresh: true,
    loading: () => ListTile(
      leading: const SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text('Cargando $que…'),
    ),
    error: (e, _) => ListTile(
      leading: Icon(
        Icons.cloud_off_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text('No se pudieron cargar $que'),
      subtitle: Text(mensajeDe(e)),
      trailing: IconButton(
        tooltip: 'Reintentar',
        icon: const Icon(Icons.refresh),
        onPressed: alReintentar,
      ),
    ),
    data: (lista) => contenido(lista.firstOrNull),
  );
}
