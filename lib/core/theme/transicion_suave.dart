import 'package:flutter/material.dart';

/// Transición entre pantallas: la nueva aparece con un fundido y un
/// desplazamiento horizontal leve. Se usa en todas las plataformas (web y
/// Android) a través de `ThemeData.pageTransitionsTheme`.
class TransicionSuave extends PageTransitionsBuilder {
  const TransicionSuave();

  /// Fracción del ancho que recorre la pantalla al entrar.
  static const desplazamiento = 0.04;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curva = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: curva,
      child: SlideTransition(
        position: Tween(
          begin: const Offset(desplazamiento, 0),
          end: Offset.zero,
        ).animate(curva),
        child: child,
      ),
    );
  }
}
