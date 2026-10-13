import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/tema_providers.dart';
import '../../../core/widgets/barra_web.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/etiqueta_segmento.dart';
import '../../../core/widgets/navegacion.dart';
import '../../../core/widgets/solarix_ui.dart';
import '../../calculadora/domain/catalogos.dart';
import '../../dashboard/application/historial_providers.dart';
import '../application/auth_providers.dart';
import '../domain/perfil.dart';
import '../domain/validadores.dart';
import 'widgets/auth_widgets.dart';

class PerfilScreen extends ConsumerWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perfil = ref.watch(perfilProvider);
    final email = ref.watch(sesionProvider).value?.email ?? '';
    return Scaffold(
      appBar: esAncho(context)
          ? const BarraWeb()
          : AppBar(
              title: const Text('Mi perfil'),
              actions: const [BotonInicio()],
            ),
      body: perfil.when(
        loading: () => const Cargando(),
        error: (e, _) => EstadoError(
          error: e,
          alReintentar: () => ref.invalidate(perfilProvider),
        ),
        data: (p) => _FormularioPerfil(perfil: p, email: email),
      ),
    );
  }
}

class _FormularioPerfil extends ConsumerStatefulWidget {
  const _FormularioPerfil({required this.perfil, required this.email});

  final Perfil perfil;
  final String email;

  @override
  ConsumerState<_FormularioPerfil> createState() => _FormularioPerfilState();
}

class _FormularioPerfilState extends ConsumerState<_FormularioPerfil> {
  final _form = GlobalKey<FormState>();
  late final _nombre = TextEditingController(text: widget.perfil.nombre);

  /// Ciudad de la lista: lugar por defecto de la calculadora y de la
  /// simulación.
  late Ciudad? _ciudad = ciudadPorNombre(widget.perfil.ciudad);
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref
          .read(perfilRepositoryProvider)
          .guardar(
            Perfil(
              id: widget.perfil.id,
              nombre: _nombre.text.trim(),
              ciudad: _ciudad?.nombre,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Perfil guardado.')));
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _cerrarSesion() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Quieres cerrar tu sesión en este dispositivo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(authRepositoryProvider).cerrarSesion();
      // Sin sesión, el router redirige solo al login.
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    }
  }

  /// Ley 1581: el titular puede pedir que se borren sus datos. Se confirma
  /// escribiendo ELIMINAR, porque no se puede deshacer.
  Future<void> _eliminarCuenta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => const _DialogoEliminarCuenta(),
    );
    if (confirmar != true || !mounted) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      await ref.read(perfilRepositoryProvider).eliminarCuenta();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tu cuenta y todos tus datos se eliminaron.'),
          ),
        );
      }
      // El usuario ya no existe: se cierra la sesión local y el router lleva
      // a la bienvenida.
      try {
        await ref.read(authRepositoryProvider).cerrarSesion();
      } on ErrorApp {
        // La sesión ya no vale en el servidor; no importa.
      }
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  /// Avatar, nombre, correo y cuántos cálculos y simulaciones tiene.
  Widget _encabezado() {
    final tema = Theme.of(context);
    final nombre = _nombre.text.trim();
    int? cuantos<T>(AsyncValue<List<T>> v) => v.value?.length;
    return Column(
      children: [
        AvatarIniciales(nombre: nombre),
        const SizedBox(height: 8),
        if (nombre.isNotEmpty)
          Text(
            nombre,
            style: tema.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        Text(
          widget.email,
          style: tema.textTheme.bodyMedium?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _Actividad(
                icono: Icons.calculate_outlined,
                cantidad: cuantos(ref.watch(calculosGuardadosProvider)),
                etiqueta: 'cálculos guardados',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _Actividad(
                icono: Icons.battery_charging_full_outlined,
                cantidad: cuantos(ref.watch(simulacionesGuardadasProvider)),
                etiqueta: 'simulaciones',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _datosPersonales(bool ancho) {
    final nombre = TextFormField(
      controller: _nombre,
      textCapitalization: TextCapitalization.words,
      validator: Validadores.nombre,
      onChanged: (_) => setState(() {}),
      decoration: const InputDecoration(
        labelText: 'Nombre',
        prefixIcon: Icon(Icons.person_outline),
      ),
    );
    final ciudad = DropdownButtonFormField<Ciudad?>(
      initialValue: _ciudad,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Ciudad (opcional)',
        prefixIcon: Icon(Icons.location_city_outlined),
      ),
      items: [
        const DropdownMenuItem(child: Text('Sin ciudad')),
        for (final c in ciudadesBase)
          DropdownMenuItem(value: c, child: Text(c.etiqueta)),
      ],
      // En el campo cerrado, con "…" si no cabe ("Cúcuta (Norte de…").
      selectedItemBuilder: (_) => [
        for (final etiqueta in [
          'Sin ciudad',
          for (final c in ciudadesBase) c.etiqueta,
        ])
          Text(etiqueta, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
      onChanged: (c) => setState(() => _ciudad = c),
    );
    final tema = Theme.of(context);
    return TarjetaSeccion(
      titulo: 'Datos personales',
      children: [
        const SizedBox(height: 4),
        if (ancho) ...[
          // En web el correo va como campo de solo lectura (mockup).
          TextFormField(
            initialValue: widget.email,
            readOnly: true,
            decoration: const InputDecoration(
              labelText: 'Correo',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (ancho)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: nombre),
              const SizedBox(width: 16),
              Expanded(child: ciudad),
            ],
          )
        else ...[
          nombre,
          const SizedBox(height: 16),
          ciudad,
        ],
        const SizedBox(height: 8),
        Text(
          'La ciudad es el lugar por defecto en la calculadora y la '
          'simulación.',
          style: tema.textTheme.bodySmall?.copyWith(
            color: tema.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        if (_error != null) ...[
          MensajeError(_error!),
          const SizedBox(height: 16),
        ],
        Align(
          alignment: ancho ? Alignment.centerRight : Alignment.center,
          child: SizedBox(
            width: ancho ? 220 : double.infinity,
            child: BotonPrincipal(
              texto: 'Guardar cambios',
              cargando: _guardando,
              onPressed: _guardar,
            ),
          ),
        ),
      ],
    );
  }

  Widget _apariencia() => TarjetaSeccion(
    titulo: 'Apariencia',
    detalle: 'Elige cómo se ve Solarix en este dispositivo.',
    children: [
      SegmentedButton<ThemeMode>(
        segments: const [
          ButtonSegment(
            value: ThemeMode.system,
            icon: Icon(Icons.brightness_auto_outlined),
            label: EtiquetaSegmento('Sistema'),
          ),
          ButtonSegment(
            value: ThemeMode.light,
            icon: Icon(Icons.light_mode_outlined),
            label: EtiquetaSegmento('Claro'),
          ),
          ButtonSegment(
            value: ThemeMode.dark,
            icon: Icon(Icons.dark_mode_outlined),
            label: EtiquetaSegmento('Oscuro'),
          ),
        ],
        selected: {ref.watch(modoTemaProvider)},
        onSelectionChanged: (s) =>
            ref.read(modoTemaProvider.notifier).cambiar(s.first),
      ),
    ],
  );

  List<Widget> _accionesCuenta() => [
    OutlinedButton.icon(
      onPressed: _cerrarSesion,
      icon: const Icon(Icons.logout),
      label: const Text('Cerrar sesión'),
    ),
    const SizedBox(height: 16),
    const Divider(),
    TextButton.icon(
      onPressed: () => context.push(Rutas.politicaDatos),
      icon: const Icon(Icons.privacy_tip_outlined),
      label: const Text('Política de tratamiento de datos'),
    ),
    TextButton.icon(
      onPressed: _guardando ? null : _eliminarCuenta,
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.error,
      ),
      icon: const Icon(Icons.delete_forever_outlined),
      label: const Text('Eliminar mi cuenta'),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (esAncho(context)) {
      return Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 56),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: anchoMaximoWeb),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const TituloPagina(
                      'Mi perfil',
                      subtitulo: 'Tus datos, preferencias y la cuenta.',
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 340,
                          child: Card(
                            margin: const EdgeInsets.only(top: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _encabezado(),
                                  const SizedBox(height: 24),
                                  ..._accionesCuenta(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [_datosPersonales(true), _apariencia()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _encabezado(),
                _datosPersonales(false),
                _apariencia(),
                const SizedBox(height: 24),
                ..._accionesCuenta(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mosaico de actividad: cuántos cálculos o simulaciones hay guardados.
class _Actividad extends StatelessWidget {
  const _Actividad({
    required this.icono,
    required this.cantidad,
    required this.etiqueta,
  });

  final IconData icono;

  /// `null` mientras carga o si no se pudo leer.
  final int? cantidad;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icono, color: tema.colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              cantidad?.toString() ?? '—',
              style: tema.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              etiqueta,
              textAlign: TextAlign.center,
              style: tema.textTheme.labelMedium?.copyWith(
                color: tema.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confirmación de "Eliminar mi cuenta": el botón se activa solo al escribir
/// ELIMINAR.
class _DialogoEliminarCuenta extends StatefulWidget {
  const _DialogoEliminarCuenta();

  @override
  State<_DialogoEliminarCuenta> createState() => _DialogoEliminarCuentaState();
}

class _DialogoEliminarCuentaState extends State<_DialogoEliminarCuenta> {
  static const _palabra = 'ELIMINAR';
  final _texto = TextEditingController();

  @override
  void dispose() {
    _texto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listo = _texto.text.trim().toUpperCase() == _palabra;
    return AlertDialog(
      title: const Text('Eliminar mi cuenta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Se borran tu cuenta, tu perfil y todos tus cálculos y '
            'simulaciones. No se puede deshacer.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _texto,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Escribe $_palabra para confirmar',
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: listo ? () => Navigator.pop(context, true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: const Text('Eliminar mi cuenta'),
        ),
      ],
    );
  }
}
