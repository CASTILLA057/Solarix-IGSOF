import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../../../core/theme/tema_providers.dart';
import '../../../core/widgets/estados.dart';
import '../../../core/widgets/navegacion.dart';
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
      appBar: AppBar(
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
  late final _ciudad = TextEditingController(text: widget.perfil.ciudad);
  late ZonaIrradiancia? _zona = widget.perfil.zonaIrradiancia;
  bool _guardando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _ciudad.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _guardando = true;
      _error = null;
    });
    try {
      final ciudad = _ciudad.text.trim();
      await ref
          .read(perfilRepositoryProvider)
          .guardar(
            Perfil(
              id: widget.perfil.id,
              nombre: _nombre.text.trim(),
              ciudad: ciudad.isEmpty ? null : ciudad,
              zonaIrradiancia: _zona,
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

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Correo'),
                  subtitle: Text(widget.email),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nombre,
                  textCapitalization: TextCapitalization.words,
                  validator: Validadores.nombre,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _ciudad,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Ciudad (opcional)',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ZonaIrradiancia>(
                  initialValue: _zona,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Irradiancia de tu zona (por defecto)',
                    prefixIcon: Icon(Icons.wb_sunny_outlined),
                  ),
                  items: [
                    for (final zona in ZonaIrradiancia.values)
                      DropdownMenuItem(value: zona, child: Text(zona.etiqueta)),
                  ],
                  onChanged: (zona) => setState(() => _zona = zona),
                ),
                const SizedBox(height: 24),
                if (_error != null) ...[
                  MensajeError(_error!),
                  const SizedBox(height: 16),
                ],
                BotonPrincipal(
                  texto: 'Guardar cambios',
                  cargando: _guardando,
                  onPressed: _guardar,
                ),
                const SizedBox(height: 32),
                Text(
                  'Apariencia',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_outlined),
                      label: Text('Sistema'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      label: Text('Claro'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      label: Text('Oscuro'),
                    ),
                  ],
                  selected: {ref.watch(modoTemaProvider)},
                  onSelectionChanged: (s) =>
                      ref.read(modoTemaProvider.notifier).cambiar(s.first),
                ),
                const SizedBox(height: 32),
                OutlinedButton.icon(
                  onPressed: _cerrarSesion,
                  icon: const Icon(Icons.logout),
                  label: const Text('Cerrar sesión'),
                ),
                const SizedBox(height: 24),
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
              ],
            ),
          ),
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
