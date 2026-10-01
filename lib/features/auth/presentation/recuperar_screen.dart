import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../application/auth_providers.dart';
import '../domain/validadores.dart';
import 'widgets/auth_widgets.dart';

/// Recuperación en dos pasos: (1) pedir el código al correo,
/// (2) escribir el código y la contraseña nueva.
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
  bool _codigoEnviado = false;
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _enviarCodigo() async {
    if (!_form.currentState!.validate()) return;
    await _ejecutar(() async {
      await ref
          .read(authRepositoryProvider)
          .enviarCodigoRecuperacion(_email.text);
      if (mounted) setState(() => _codigoEnviado = true);
    });
  }

  Future<void> _restablecer() async {
    if (!_form.currentState!.validate()) return;
    await _ejecutar(() async {
      await ref
          .read(authRepositoryProvider)
          .restablecerContrasena(
            email: _email.text,
            codigo: _codigo.text,
            nuevaContrasena: _contrasena.text,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada.')));
      context.go(Rutas.inicio);
    });
  }

  Future<void> _ejecutar(Future<void> Function() accion) async {
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

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Recuperar contraseña',
      subtitulo: _codigoEnviado
          ? 'Si existe una cuenta con ese correo, te enviamos un código. '
                'Escríbelo junto con tu contraseña nueva.'
          : 'Te enviaremos un código a tu correo para crear una contraseña '
                'nueva.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              enabled: !_codigoEnviado,
              keyboardType: TextInputType.emailAddress,
              textInputAction: _codigoEnviado
                  ? TextInputAction.next
                  : TextInputAction.done,
              autofillHints: const [AutofillHints.email],
              validator: Validadores.email,
              onFieldSubmitted: _codigoEnviado ? null : (_) => _enviarCodigo(),
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            if (_codigoEnviado) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _codigo,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofillHints: const [AutofillHints.oneTimeCode],
                validator: Validadores.codigo,
                decoration: const InputDecoration(
                  labelText: 'Código',
                  prefixIcon: Icon(Icons.pin_outlined),
                ),
              ),
              const SizedBox(height: 16),
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
                onFieldSubmitted: (_) => _restablecer(),
                autofillHints: const [AutofillHints.newPassword],
              ),
            ],
            const SizedBox(height: 24),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: 16),
            ],
            BotonPrincipal(
              texto: _codigoEnviado ? 'Cambiar contraseña' : 'Enviar código',
              cargando: _cargando,
              onPressed: _codigoEnviado ? _restablecer : _enviarCodigo,
            ),
            if (_codigoEnviado)
              TextButton(
                onPressed: _cargando
                    ? null
                    : () => setState(() {
                        _codigoEnviado = false;
                        _error = null;
                      }),
                child: const Text('Usar otro correo o pedir otro código'),
              ),
          ],
        ),
      ),
    );
  }
}
