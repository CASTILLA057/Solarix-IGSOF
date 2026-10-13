import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/formato.dart';
import '../../../core/router/rutas.dart';
import '../../../core/widgets/barra_web.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/sol_solarix.dart';
import '../../../core/widgets/solarix_ui.dart';
import '../../auth/application/auth_providers.dart';
import '../../degradacion/presentation/etiquetas.dart';
import '../application/historial_providers.dart';
import '../domain/historial.dart';
import 'historial_screen.dart';
import 'widgets/graficas.dart';

/// Dashboard: saludo, accesos a la calculadora y la simulación, y resumen
/// del último cálculo y la última simulación (diseño del mockup, Etapa 13).
class InicioScreen extends ConsumerWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tema = Theme.of(context);
    final ancho = esAncho(context);
    // Sin sesión (probando sin cuenta) no hay historial que consultar.
    final haySesion = ref.watch(haySesionProvider);
    final calculos = haySesion ? ref.watch(calculosGuardadosProvider) : null;
    final simulaciones = haySesion
        ? ref.watch(simulacionesGuardadasProvider)
        : null;
    final nombre = haySesion ? ref.watch(perfilProvider).value?.nombre : null;
    final primerNombre = nombre?.trim().split(' ').first ?? '';

    final saludo = Row(
      children: [
        const SolSolarix(tamano: 40),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primerNombre.isEmpty ? 'Hola' : 'Hola, $primerNombre',
                style: tema.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Calculadora solar y simulador de degradación de baterías',
                style: tema.textTheme.bodyMedium?.copyWith(
                  color: tema.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
    final calcular = FilledButton.icon(
      onPressed: () => context.go(Rutas.calculadora),
      icon: const Icon(Icons.calculate_outlined),
      label: const Text('Calcular mi sistema solar'),
    );
    final simular = OutlinedButton.icon(
      onPressed: () => context.go(Rutas.simulacion),
      icon: const Icon(Icons.battery_charging_full_outlined),
      label: const Text('Simular degradación de batería'),
    );

    final List<Widget> contenido;
    if (!haySesion) {
      contenido = [const _InvitacionCuenta()];
    } else {
      final tarjetaCalculo = _Resumen<CalculoGuardado>(
        valor: calculos!,
        que: 'tus cálculos',
        alReintentar: () => ref.invalidate(calculosGuardadosProvider),
        contenido: (c) => _TarjetaCalculo(calculo: c, detalle: ancho),
      );
      final tarjetaSimulacion = _Resumen<SimulacionGuardada>(
        valor: simulaciones!,
        que: 'tus simulaciones',
        alReintentar: () => ref.invalidate(simulacionesGuardadasProvider),
        contenido: (s) => _TarjetaSimulacion(simulacion: s, web: ancho),
      );
      contenido = [
        dosColumnas(context, tarjetaCalculo, tarjetaSimulacion),
        if (ancho)
          _HistorialReciente(
            calculos: calculos.value ?? const [],
            simulaciones: simulaciones.value ?? const [],
          )
        else ...[
          const SizedBox(height: 12),
          Center(
            child: TextButton.icon(
              onPressed: () => context.go(Rutas.historial),
              icon: const Icon(Icons.history),
              label: const Text('Ver todo el historial'),
            ),
          ),
        ],
      ];
    }

    return Scaffold(
      appBar: ancho
          ? const BarraWeb()
          : AppBar(
              title: const Text('Solarix'),
              actions: [
                if (!haySesion)
                  TextButton(
                    onPressed: () => context.go(Rutas.login),
                    child: const Text('Iniciar sesión'),
                  )
                else ...[
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
            constraints: BoxConstraints(maxWidth: ancho ? anchoMaximoWeb : 720),
            child: ListView(
              padding: ancho
                  ? const EdgeInsets.fromLTRB(24, 32, 24, 56)
                  : const EdgeInsets.all(16),
              children: [
                if (ancho)
                  // Los botones van a la derecha del saludo y bajan si la
                  // ventana es justa (900 px).
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(width: 460, child: saludo),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [simular, calcular],
                      ),
                    ],
                  )
                else ...[
                  saludo,
                  const SizedBox(height: 16),
                  calcular,
                  const SizedBox(height: 12),
                  simular,
                ],
                const SizedBox(height: 4),
                ...contenido,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// El más reciente de una lista guardada, con sus estados de carga y error.
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
    loading: () => Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
        leading: const SizedBox.square(
          dimension: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Cargando $que…'),
      ),
    ),
    error: (e, _) => Card(
      margin: const EdgeInsets.only(top: 12),
      child: ListTile(
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
    ),
    data: (lista) => contenido(lista.firstOrNull),
  );
}

/// Último cálculo: cifras en mosaicos; en web, también sus datos.
class _TarjetaCalculo extends StatelessWidget {
  const _TarjetaCalculo({required this.calculo, required this.detalle});

  final CalculoGuardado? calculo;
  final bool detalle;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final c = calculo;
    if (c == null) {
      return const TarjetaSeccion(
        icono: Icons.calculate_outlined,
        subtitulo: 'Último cálculo',
        titulo: 'Aún no tienes cálculos guardados',
        children: [Text('Calcula tu sistema y guárdalo para verlo aquí.')],
      );
    }
    return TarjetaSeccion(
      icono: Icons.calculate_outlined,
      // En web el título lleva el nombre y debajo el tipo y la fecha.
      subtitulo: detalle ? null : 'Último cálculo',
      titulo: detalle
          ? 'Último cálculo · ${c.titulo}'
          // Sin nombre, el título ya dice el tipo ("Cálculo híbrido").
          : (c.nombre?.trim().isNotEmpty ?? false)
          ? '${c.titulo} · ${c.tipo.etiqueta}'
          : c.titulo,
      detalle: detalle
          ? 'Sistema ${c.tipo.etiqueta.toLowerCase()} · '
                '${fechaCorta(c.creadoEn)}'
          : null,
      alTocar: () => context.go(Rutas.historial),
      children: [
        Row(
          children: [
            Expanded(
              child: MosaicoCifra(
                '${Formato.numero(c.potenciaKw, 2)} kWp',
                Formato.paneles(c.numeroPaneles),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MosaicoCifra(Formato.copCorto(c.costoTotal), 'inversión'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: MosaicoCifra(
                c.paybackAnios == null
                    ? '—'
                    : '${Formato.numero(c.paybackAnios!, 1)} años',
                'recuperación',
              ),
            ),
          ],
        ),
        if (detalle) ...[
          const SizedBox(height: 8),
          FilaDato('Consumo', '${Formato.numero(c.energiaDiaKwh, 2)} kWh/día'),
          if (c.bateriaKwh > 0)
            FilaDato('Batería', '${Formato.numero(c.bateriaKwh, 1)} kWh'),
          FilaDato('Ahorro el primer mes', Formato.cop(c.ahorroMensual)),
          if (c.vpn case final vpn?)
            FilaDato('Valor presente neto (VPN)', Formato.cop(vpn)),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            fechaCorta(c.creadoEn),
            style: tema.textTheme.labelMedium?.copyWith(
              color: tema.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

/// Última simulación: su salud final y la gráfica (con leyenda).
class _TarjetaSimulacion extends StatelessWidget {
  const _TarjetaSimulacion({required this.simulacion, this.web = false});

  final SimulacionGuardada? simulacion;
  final bool web;

  @override
  Widget build(BuildContext context) {
    final s = simulacion;
    if (s == null) {
      return const TarjetaSeccion(
        icono: Icons.battery_charging_full_outlined,
        tono: TonoBurbuja.verde,
        subtitulo: 'Última simulación',
        titulo: 'Aún no tienes simulaciones guardadas',
        children: [
          Text('Simula la batería y guárdala para ver su salud aquí.'),
        ],
      );
    }
    return TarjetaSeccion(
      icono: Icons.battery_charging_full_outlined,
      tono: TonoBurbuja.verde,
      subtitulo: web ? null : 'Última simulación · ${fechaCorta(s.creadoEn)}',
      titulo: web
          ? 'Última simulación · SoH ${Formato.numero(s.sohFinal, 1)} %'
          : 'SoH ${Formato.numero(s.sohFinal, 1)} % '
                '(política ${s.politica.etiqueta.toLowerCase()})',
      detalle: web
          ? 'Política ${s.politica.etiqueta.toLowerCase()} · '
                '${s.sohAnual.length} años · ${fechaCorta(s.creadoEn)}'
          : null,
      alTocar: () => context.push(Rutas.detalleSimulacion, extra: s),
      children: [
        GraficaSoh(
          sohMensual: [for (final m in s.serie) m.soh],
          politica: s.politica,
          alternativaAnual: s.sohAnualAlternativa,
          politicaAlternativa: s.politicaAlternativa,
        ),
      ],
    );
  }
}

/// Web: los 3 elementos más nuevos, mezclando cálculos y simulaciones.
class _HistorialReciente extends StatelessWidget {
  const _HistorialReciente({
    required this.calculos,
    required this.simulaciones,
  });

  final List<CalculoGuardado> calculos;
  final List<SimulacionGuardada> simulaciones;

  @override
  Widget build(BuildContext context) {
    final recientes = <(DateTime, Object)>[
      for (final c in calculos) (c.creadoEn, c),
      for (final s in simulaciones) (s.creadoEn, s),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (recientes.isEmpty) return const SizedBox.shrink();
    return TarjetaSeccion(
      titulo: 'Historial reciente',
      margen: const EdgeInsets.only(top: 24),
      accion: TextButton.icon(
        onPressed: () => context.go(Rutas.historial),
        icon: const Icon(Icons.chevron_right),
        label: const Text('Ver todo el historial'),
      ),
      children: [
        for (final (fecha, elemento) in recientes.take(3))
          switch (elemento) {
            CalculoGuardado c => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const BurbujaIcono(Icons.calculate_outlined),
              title: Text(c.titulo),
              subtitle: Text(
                'Cálculo · ${c.tipo.etiqueta.toLowerCase()} · '
                '${fechaCorta(fecha)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Formato.copCorto(c.costoTotal),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => context.go(Rutas.historial),
            ),
            SimulacionGuardada s => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const BurbujaIcono(
                Icons.battery_charging_full_outlined,
                tono: TonoBurbuja.verde,
              ),
              title: const Text('Simulación de batería'),
              subtitle: Text(
                'Simulación · ${s.politica.etiqueta.toLowerCase()} · '
                '${fechaCorta(fecha)}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'SoH ${Formato.numero(s.sohFinal, 1)} %',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              onTap: () => context.push(Rutas.detalleSimulacion, extra: s),
            ),
            _ => const SizedBox.shrink(),
          },
      ],
    );
  }
}

/// Inicio sin sesión (Etapa 12): todo se puede calcular y simular; la cuenta
/// solo hace falta para guardar.
class _InvitacionCuenta extends StatelessWidget {
  const _InvitacionCuenta();

  @override
  Widget build(BuildContext context) => TarjetaSeccion(
    icono: Icons.person_outline,
    tono: TonoBurbuja.azul,
    titulo: 'Estás probando Solarix sin cuenta',
    margen: const EdgeInsets.only(top: 16),
    children: [
      Text(
        'Calcula y simula todo lo que quieras. Para guardar tus cálculos y '
        'simulaciones y verlos en el historial, crea una cuenta.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          FilledButton(
            onPressed: () => context.go(Rutas.registro),
            child: const Text('Crear cuenta'),
          ),
          TextButton(
            onPressed: () => context.go(Rutas.login),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    ],
  );
}
