import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../application/auth_providers.dart';
import '../domain/validadores.dart';
import 'widgets/auth_widgets.dart';

/// Confirma la cuenta con el código que Supabase envía al correo.
class VerificarCorreoScreen extends ConsumerStatefulWidget {
  const VerificarCorreoScreen({super.key, this.email = ''});

  final String email;

  @override
  ConsumerState<VerificarCorreoScreen> createState() =>
      _VerificarCorreoScreenState();
}

class _VerificarCorreoScreenState extends ConsumerState<VerificarCorreoScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _codigo = TextEditingController();
  bool _cargando = false;
  bool _reenviando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _codigo.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .confirmarRegistro(email: _email.text, codigo: _codigo.text);
      // Al confirmar se abre la sesión y el router redirige al inicio.
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _reenviar() async {
    if (Validadores.email(_email.text) != null) {
      _form.currentState!.validate();
      return;
    }
    setState(() {
      _reenviando = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .reenviarCodigoRegistro(_email.text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Te enviamos un código nuevo.')),
        );
      }
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _reenviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Confirma tu correo',
      subtitulo:
          'Escribe el código que enviamos a tu correo para activar '
          'la cuenta. Revisa también la carpeta de spam.',
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validadores.email,
              decoration: const InputDecoration(
                labelText: 'Correo',
                prefixIcon: Icon(Icons.mail_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codigo,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofillHints: const [AutofillHints.oneTimeCode],
              validator: Validadores.codigo,
              onFieldSubmitted: (_) => _confirmar(),
              decoration: const InputDecoration(
                labelText: 'Código',
                prefixIcon: Icon(Icons.pin_outlined),
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null) ...[
              MensajeError(_error!),
              const SizedBox(height: 16),
            ],
            BotonPrincipal(
              texto: 'Confirmar cuenta',
              cargando: _cargando,
              onPressed: _confirmar,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _reenviando ? null : _reenviar,
              child: Text(_reenviando ? 'Enviando…' : 'Reenviar código'),
            ),
            TextButton(
              onPressed: () => context.go(Rutas.login),
              child: const Text('Volver a iniciar sesión'),
            ),
          ],
        ),
      ),
    );
  }
}
