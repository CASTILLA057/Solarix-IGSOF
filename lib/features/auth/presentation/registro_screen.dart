import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/error_app.dart';
import '../../../core/router/rutas.dart';
import '../application/auth_providers.dart';
import '../domain/validadores.dart';
import 'widgets/auth_widgets.dart';

class RegistroScreen extends ConsumerStatefulWidget {
  const RegistroScreen({super.key});

  @override
  ConsumerState<RegistroScreen> createState() => _RegistroScreenState();
}

class _RegistroScreenState extends ConsumerState<RegistroScreen> {
  final _form = GlobalKey<FormState>();
  final _nombre = TextEditingController();
  final _email = TextEditingController();
  final _contrasena = TextEditingController();
  final _confirmacion = TextEditingController();
  bool _cargando = false;
  String? _error;

  @override
  void dispose() {
    _nombre.dispose();
    _email.dispose();
    _contrasena.dispose();
    _confirmacion.dispose();
    super.dispose();
  }

  Future<void> _registrarse() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final activa = await ref
          .read(authRepositoryProvider)
          .registrarse(
            email: _email.text,
            contrasena: _contrasena.text,
            nombre: _nombre.text,
          );
      // Si la cuenta quedó activa, el router redirige solo al inicio.
      if (!activa && mounted) {
        context.go(Rutas.verificarCon(_email.text.trim()));
      }
    } on ErrorApp catch (e) {
      if (mounted) setState(() => _error = e.mensaje);
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      titulo: 'Crear cuenta',
      subtitulo: 'Guarda tus cálculos y simulaciones en la nube.',
      child: Form(
        key: _form,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombre,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                validator: Validadores.nombre,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),
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
                validator: Validadores.contrasena,
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 4),
              Text(
                'Mínimo ${Validadores.longitudMinimaContrasena} caracteres, '
                'con letras y números.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              CampoContrasena(
                controller: _confirmacion,
                etiqueta: 'Repite la contraseña',
                validator: (v) => Validadores.confirmacion(v, _contrasena.text),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _registrarse(),
                autofillHints: const [AutofillHints.newPassword],
              ),
              const SizedBox(height: 16),
              // Ley 1581 de 2012: autorización previa, expresa e informada.
              FormField<bool>(
                initialValue: false,
                validator: (acepta) => acepta == true
                    ? null
                    : 'Debes autorizar el tratamiento de tus datos para crear '
                          'la cuenta.',
                builder: (campo) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CheckboxListTile(
                      value: campo.value ?? false,
                      onChanged: campo.didChange,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: const Text(
                        'Autorizo el tratamiento de mis datos personales '
                        'según la política de tratamiento de datos.',
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.push(Rutas.politicaDatos),
                        child: const Text(
                          'Leer la política de tratamiento de datos',
                        ),
                      ),
                    ),
                    if (campo.errorText case final error?)
                      Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                MensajeError(_error!),
                const SizedBox(height: 16),
              ],
              BotonPrincipal(
                texto: 'Crear cuenta',
                cargando: _cargando,
                onPressed: _registrarse,
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('¿Ya tienes cuenta?'),
                  TextButton(
                    onPressed: () => context.go(Rutas.login),
                    child: const Text('Inicia sesión'),
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
