import 'package:flutter/material.dart';

import '../../../core/formato.dart';
import '../../degradacion/presentation/etiquetas.dart';
import '../domain/historial.dart';
import 'historial_screen.dart';
import 'widgets/graficas.dart';

/// Detalle de una simulación guardada: cifras y gráficas.
class DetalleSimulacionScreen extends StatelessWidget {
  const DetalleSimulacionScreen({super.key, required this.simulacion});

  final SimulacionGuardada simulacion;

  @override
  Widget build(BuildContext context) {
    final s = simulacion;
    final tema = Theme.of(context);
    final serie = s.serie;
    Widget tarjeta(String titulo, Widget hijo) => Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: tema.textTheme.titleMedium),
            const SizedBox(height: 12),
            hijo,
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Simulación guardada')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '${fechaCorta(s.creadoEn)} · '
                '${Formato.numero(s.capacidadKwh, 1)} kWh · '
                '${Formato.numero(s.potenciaKw, 1)} kWp · irradiancia '
                '${s.escenario.etiqueta.toLowerCase()} · zona '
                '${s.zona.etiqueta.toLowerCase()}',
                style: tema.textTheme.bodySmall,
              ),
              tarjeta(
                'Resumen',
                Column(
                  children: [
                    for (final (etiqueta, valor) in [
                      (
                        'SoH final (${s.politica.etiqueta.toLowerCase()})',
                        '${Formato.numero(s.sohFinal, 2)} %',
                      ),
                      (
                        'SoH final (${s.politicaAlternativa.etiqueta.toLowerCase()})',
                        '${Formato.numero(s.sohFinalAlternativa, 2)} %',
                      ),
                      ('Pérdida por año', Formato.numero(s.perdidaAnual, 2)),
                      (
                        'Energía comprada a la red',
                        '${Formato.numero(s.compradaKwh)} kWh',
                      ),
                      ('Limpiezas de paneles', '${s.limpiezas}'),
                    ])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(etiqueta)),
                            Text(
                              valor,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              tarjeta(
                'Salud de la batería (SoH)',
                GraficaSoh(
                  sohMensual: [for (final m in serie) m.soh],
                  politica: s.politica,
                  alternativaAnual: s.sohAnualAlternativa,
                  politicaAlternativa: s.politicaAlternativa,
                ),
              ),
              if (serie.isNotEmpty) ...[
                tarjeta(
                  'Generación y consumo por mes',
                  GraficaEnergiaMensual(
                    generacion: [for (final m in serie) m.generacionKwh],
                    consumo: [for (final m in serie) m.consumoKwh],
                  ),
                ),
                tarjeta(
                  'Energía comprada a la red (acumulada)',
                  GraficaCompradaAcumulada(
                    compradaMensual: [for (final m in serie) m.compradaKwh],
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
