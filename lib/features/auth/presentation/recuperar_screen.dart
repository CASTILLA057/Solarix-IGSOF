import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../application/auth_providers.dart';
import '../data/auth_repository.dart';
import '../domain/validadores.dart';
import 'widgets/auth_widgets.dart';

enum _Paso { correo, codigo, contrasena }

/// Recuperación en tres pasos, mostrando solo los campos de cada uno:
/// (1) correo → enviar código, (2) verificar el código,
/// (3) con el código correcto, escribir la contraseña nueva.
class RecuperarScreen extends ConsumerStatefulWidget {
  const RecuperarScreen({super.key});

  @override
  ConsumerState<RecuperarScreen> createState() => _RecuperarScreenState();
}

class _RecuperarScreenState extends ConsumerState<RecuperarScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _codigo = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  late final AuthRepository _auth;
  _Paso _paso = _Paso.correo;
  bool _contrasenaCambiada = false;
  bool _cargando = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Se guarda aquí porque `ref` ya no se puede usar en dispose.
    _auth = ref.read(authRepositoryProvider);
  }

  @override
  void dispose() {
    // Verificar el código abre una sesión temporal: si el usuario se va sin
    // cambiar la contraseña, esa sesión se cierra.
    if (_paso == _Paso.contrasena && !_contrasenaCambiada) {
      _auth.cerrarSesion().ignore();
    }
    _email.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() => _ejecutar(() async {
    await _auth.enviarCodigoRecuperacion(_email.text);
    _irA(_Paso.codigo);
  });

  Future<void> _verificarCodigo() => _ejecutar(() async {
    await _auth.verificarCodigoRecuperacion(
      email: _email.text,
      codigo: _codigo.text,
    );
    _irA(_Paso.contrasena);
  });

  Future<void> _cambiarContrasena() => _ejecutar(() async {
    await _auth.cambiarContrasena(_contrasena.text);
    _contrasenaCambiada = true;
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
    context.go(Rutas.inicio);
  });

  Future<void> _reenviarCodigo() async {
    _codigo.clear();
    await _ejecutar(() async {
      await _auth.enviarCodigoRecuperacion(_email.text);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Te enviamos un código nuevo.')),
      );
    }, validar: false);
  }

  void _irA(_Paso paso) {
    if (mounted) setState(() => _paso = paso);
  }

  Future<void> _ejecutar(
    Future<void> Function() accion, {
    bool validar = true,
  }) async {
    if (validar && !_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await accion();
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String get _subtitulo => switch (_paso) {
    _Paso.correo =>
      'Te enviaremos un código a tu correo para crear una contraseña nueva.',
    _Paso.codigo =>
      'Si existe una cuenta con ${_email.text.trim()}, te enviamos un código. '
          'Revisa también la carpeta de spam.',
    _Paso.contrasena => 'Código correcto. Escribe tu contraseña nueva.',
  };

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Recuperar contraseña',
      subtitulo: _subtitulo,
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animacion) => FadeTransition(
                opacity: animacion,
                child: SizeTransition(sizeFactor: animacion, child: child),
              ),
              child: KeyedSubtree(
                key: ValueKey(_paso),
                child: _camposDelPaso(),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: 16),
            ],
            BotonPrincipal(
              texto: switch (_paso) {
                _Paso.correo => 'Enviar código',
                _Paso.codigo => 'Verificar código',
                _Paso.contrasena => 'Cambiar contraseña',
              },
              cargando: _cargando,
              onPressed: switch (_paso) {
                _Paso.correo => _enviarCodigo,
                _Paso.codigo => _verificarCodigo,
                _Paso.contrasena => _cambiarContrasena,
              },
            ),
            if (_paso == _Paso.codigo) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _cargando ? null : _reenviarCodigo,
                child: const Text('Reenviar código'),
              ),
              TextButton(
                onPressed: _cargando
                    ? null
                    : () => setState(() {
                        _codigo.clear();
                        _error = null;
                        _paso = _Paso.correo;
                      }),
                child: const Text('Usar otro correo'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _camposDelPaso() => switch (_paso) {
    _Paso.correo => TextFormField(
      controller: _email,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      autofillHints: const [AutofillHints.email],
      validator: Validadores.email,
      onFieldSubmitted: (_) => _enviarCodigo(),
      decoration: const InputDecoration(
        labelText: 'Correo',
        prefixIcon: Icon(Icons.mail_outline),
      ),
    ),
    _Paso.codigo => TextFormField(
      controller: _codigo,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      autofillHints: const [AutofillHints.oneTimeCode],
      validator: Validadores.codigo,
      onFieldSubmitted: (_) => _verificarCodigo(),
      decoration: const InputDecoration(
        labelText: 'Código',
        prefixIcon: Icon(Icons.pin_outlined),
      ),
    ),
    _Paso.contrasena => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoContrasena(
          controller: _contrasena,
          etiqueta: 'Contraseña nueva',
          validator: Validadores.contrasena,
          autofillHints: const [AutofillHints.newPassword],
        ),
        const SizedBox(height: 16),
        CampoContrasena(
          controller: _confirmacion,
          etiqueta: 'Repite la contraseña nueva',
          validator: (v) => Validadores.confirmacion(v, _contrasena.text),
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _cambiarContrasena(),
          autofillHints: const [AutofillHints.newPassword],
        ),
      ],
    ),
  };
}
