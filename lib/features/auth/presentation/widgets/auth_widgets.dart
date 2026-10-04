import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Estructura común de las pantallas de autenticación: centrada, con ancho
/// máximo para que se vea bien en el navegador de escritorio.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.titulo,
    required this.child,
    this.subtitulo,
  });

  final String titulo;
  final String? subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 56,
                    color: ColoresSolarix.of(context).solar,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    titulo,
                    style: tema.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (subtitulo != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitulo!,
                      style: tema.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 24),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Caja de error visible dentro del formulario.
class MensajeError extends StatelessWidget {
  const MensajeError(this.texto, {super.key});

  final String texto;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esquema.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: esquema.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: esquema.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}

/// Botón principal que muestra un indicador mientras la acción está en curso.
class BotonPrincipal extends StatelessWidget {
  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.onPressed,
    this.cargando = false,
  });

  final String texto;
  final VoidCallback onPressed;
  final bool cargando;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: cargando ? null : onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: cargando
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(texto),
    );
  }
}

/// Campo de contraseña con botón para mostrarla u ocultarla.
class CampoContrasena extends StatefulWidget {
  const CampoContrasena({
    super.key,
    required this.controller,
    required this.etiqueta,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.autofillHints = const [AutofillHints.password],
  });

  final TextEditingController controller;
  final String etiqueta;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String> autofillHints;

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _oculta,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(_oculta ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
    );
  }
}
