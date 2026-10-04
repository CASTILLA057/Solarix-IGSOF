import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/estados.dart';
import '../../degradacion/domain/parametros.dart';
import '../../degradacion/presentation/etiquetas.dart';
import '../application/historial_providers.dart';
import '../domain/historial.dart';

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun', //
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Fecha corta en español, p. ej. "2 oct 2026".
String fechaCorta(DateTime f) => '${f.day} ${_meses[f.month - 1]} ${f.year}';

/// Historial de cálculos y simulaciones, con filtros y eliminación.
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  FiltroFecha _fecha = FiltroFecha.todas;
  Politica? _politica;

  Future<void> _eliminar(String que, Future<void> Function() accion) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar $que'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await accion();
      ref
        ..invalidate(calculosGuardadosProvider)
        ..invalidate(simulacionesGuardadasProvider);
    } on ErrorApp catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.mensaje)));
      }
    }
  }

  Widget get _quitarFiltros => EstadoVacio(
    icono: Icons.filter_alt_off_outlined,
    titulo: 'No hay resultados con estos filtros',
    textoAccion: 'Quitar filtros',
    alPresionar: () => setState(() {
      _fecha = FiltroFecha.todas;
      _politica = null;
    }),
  );

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(historialRepositoryProvider);
    final ahora = DateTime.now();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Historial'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cálculos'),
              Tab(text: 'Simulaciones'),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: DropdownButtonFormField<FiltroFecha>(
                    initialValue: _fecha,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Fecha',
                      prefixIcon: Icon(Icons.date_range_outlined),
                    ),
                    items: [
                      for (final f in FiltroFecha.values)
                        DropdownMenuItem(value: f, child: Text(f.etiqueta)),
                    ],
                    onChanged: (f) => setState(() => _fecha = f!),
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _Lista<CalculoGuardado>(
                        valor: ref.watch(calculosGuardadosProvider),
                        filtrar: (l) => filtrarCalculos(l, _fecha, ahora),
                        vacio: EstadoVacio(
                          icono: Icons.calculate_outlined,
                          titulo: 'Aún no tienes cálculos guardados',
                          mensaje:
                              'Calcula tu sistema solar y guárdalo para '
                              'verlo aquí.',
                          textoAccion: 'Calcular mi sistema solar',
                          alPresionar: () => context.go(Rutas.calculadora),
                        ),
                        filtrado: _quitarFiltros,
                        alRecargar: () =>
                            ref.invalidate(calculosGuardadosProvider),
                        elemento: (c) => ListTile(
                          leading: const Icon(Icons.calculate_outlined),
                          title: Text(c.titulo),
                          subtitle: Text(
                            '${fechaCorta(c.creadoEn)} · ${c.numeroPaneles} paneles · '
                            '${Formato.cop(c.costoTotal)} · recupera en '
                            '${Formato.anios(c.paybackAnios, 20).toLowerCase()}',
                          ),
                          trailing: IconButton(
                            tooltip: 'Eliminar cálculo',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _eliminar(
                              'cálculo',
                              () => repo.eliminarCalculo(c.id),
                            ),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                            child: SegmentedButton<Politica?>(
                              segments: [
                                const ButtonSegment(
                                  value: null,
                                  label: Text('Todas'),
                                ),
                                for (final p in Politica.values)
                                  ButtonSegment(
                                    value: p,
                                    label: Text(p.etiqueta),
                                  ),
                              ],
                              selected: {_politica},
                              onSelectionChanged: (s) =>
                                  setState(() => _politica = s.first),
                            ),
                          ),
                          Expanded(
                            child: _Lista<SimulacionGuardada>(
                              valor: ref.watch(simulacionesGuardadasProvider),
                              filtrar: (l) => filtrarSimulaciones(
                                l,
                                _fecha,
                                _politica,
                                ahora,
                              ),
                              vacio: EstadoVacio(
                                icono: Icons.battery_charging_full_outlined,
                                titulo: 'Aún no tienes simulaciones guardadas',
                                mensaje:
                                    'Simula la salud de una batería y '
                                    'guárdala para verla aquí.',
                                textoAccion: 'Simular una batería',
                                alPresionar: () => context.go(Rutas.simulacion),
                              ),
                              filtrado: _quitarFiltros,
                              alRecargar: () =>
                                  ref.invalidate(simulacionesGuardadasProvider),
                              elemento: (s) => ListTile(
                                leading: const Icon(
                                  Icons.battery_charging_full_outlined,
                                ),
                                title: Text(
                                  'SoH ${Formato.numero(s.sohFinal, 1)} % · '
                                  '${s.politica.etiqueta}',
                                ),
                                subtitle: Text(
                                  '${fechaCorta(s.creadoEn)} · '
                                  '${Formato.numero(s.capacidadKwh, 1)} kWh · '
                                  '${Formato.numero(s.potenciaKw, 1)} kWp'
                                  '${s.calculoId != null ? ' · de un cálculo' : ''}',
                                ),
                                onTap: () => context.push(
                                  Rutas.detalleSimulacion,
                                  extra: s,
                                ),
                                trailing: IconButton(
                                  tooltip: 'Eliminar simulación',
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _eliminar(
                                    'simulación',
                                    () => repo.eliminarSimulacion(s.id),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Lista con estados de carga, error y vacío.
class _Lista<T> extends StatelessWidget {
  const _Lista({
    required this.valor,
    required this.filtrar,
    required this.vacio,
    required this.filtrado,
    required this.alRecargar,
    required this.elemento,
  });

  final AsyncValue<List<T>> valor;
  final List<T> Function(List<T>) filtrar;

  /// Se muestra si no hay nada guardado.
  final Widget vacio;

  /// Se muestra si hay datos pero los filtros los ocultan todos.
  final Widget filtrado;
  final VoidCallback alRecargar;
  final Widget Function(T) elemento;

  @override
  Widget build(BuildContext context) => valor.when(
    loading: () => const Cargando(),
    error: (e, _) => EstadoError(error: e, alReintentar: alRecargar),
    data: (todos) {
      final lista = filtrar(todos);
      if (lista.isEmpty) return todos.isEmpty ? vacio : filtrado;
      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: lista.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => elemento(lista[i]),
      );
    },
  );
}
