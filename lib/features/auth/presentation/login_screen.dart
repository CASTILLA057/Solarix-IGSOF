import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../application/auth_providers.dart';
import '../domain/mensajes_error.dart';
import '../domain/validadores.dart';
import 'widgets/auth_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _iniciarSesion() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .iniciarSesion(email: _email.text, contrasena: _contrasena.text);
      // Al abrir sesión, el router redirige solo al inicio.
    } on ErrorApp catch (e) {
      if (!mounted) return;
      if (e.codigo == CodigosError.correoSinConfirmar) {
        context.go(Rutas.verificarCon(_email.text.trim()));
        return;
      }
      setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Iniciar sesión',
      subtitulo: 'Calculadora solar y simulador de degradación de baterías',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                validator: Validadores.email,
                decoration: const InputDecoration(
                  labelText: 'Correo',
                  prefixIcon: Icon(Icons.mail_outline),
                ),
              ),
              const SizedBox(height: 16),
              CampoContrasena(
                controller: _contrasena,
                etiqueta: 'Contraseña',
                validator: Validadores.contrasenaRequerida,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _iniciarSesion(),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push(Rutas.recuperar),
                  child: const Text('¿Olvidaste tu contraseña?'),
                ),
              ),
              if (_error != null) ...[
                MensajeError(_error!),
                const SizedBox(height: 16),
              ],
              BotonPrincipal(
                texto: 'Iniciar sesión',
                cargando: _cargando,
                onPressed: _iniciarSesion,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('¿No tienes cuenta?'),
                  TextButton(
                    onPressed: () => context.push(Rutas.registro),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
