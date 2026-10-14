import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/barra_web.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/etiqueta_segmento.dart';
import '../../../core/widgets/navegacion.dart';
import '../../../core/widgets/solarix_ui.dart';
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

const _pestanas = [Tab(text: 'Cálculos'), Tab(text: 'Simulaciones')];

/// Historial de cálculos y simulaciones, con filtros y eliminación.
class HistorialScreen extends ConsumerStatefulWidget {
  const HistorialScreen({super.key});

  @override
  ConsumerState<HistorialScreen> createState() => _HistorialScreenState();
}

class _HistorialScreenState extends ConsumerState<HistorialScreen> {
  FiltroFecha _fecha = FiltroFecha.todas;
  Politica? _politica;

  /// Abre los resultados guardados del cálculo; si los datos guardados no se
  /// pueden leer, lo avisa en vez de no hacer nada.
  void _abrirCalculo(CalculoGuardado c) {
    final completo = c.completo();
    if (completo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pueden abrir los datos de este cálculo.'),
        ),
      );
      return;
    }
    context.push(
      Rutas.detalleCalculo,
      extra: (c.id, completo.entradas, completo.resultado),
    );
  }

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
        appBar: esAncho(context)
            ? const BarraWeb()
            : AppBar(
                title: const Text('Historial'),
                actions: const [BotonInicio()],
                bottom: const TabBar(tabs: _pestanas),
              ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              children: [
                if (esAncho(context)) ...[
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 32, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TituloPagina('Historial'),
                    ),
                  ),
                  const TabBar(tabs: _pestanas),
                ],
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
                          onTap: () => _abrirCalculo(c),
                          leading: const BurbujaIcono(Icons.calculate_outlined),
                          title: Text(c.titulo),
                          subtitle: Text(
                            '${fechaCorta(c.creadoEn)} · ${Formato.paneles(c.numeroPaneles)} · '
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
                                  label: EtiquetaSegmento('Todas'),
                                ),
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
                                leading: const BurbujaIcono(
                                  Icons.battery_charging_full_outlined,
                                  tono: TonoBurbuja.verde,
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
