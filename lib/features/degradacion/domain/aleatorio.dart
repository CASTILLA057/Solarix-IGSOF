import 'dart:math' as math;

/// Generador aleatorio con semilla: con la misma semilla, la misma corrida.
///
/// NetLogo usa `random-seed new-seed` (una semilla distinta en cada corrida)
/// y su propio generador, así que Dart y NetLogo no dan series idénticas: la
/// comparación entre ambos es estadística (promedios de varias semillas).
class Aleatorio {
  Aleatorio(int semilla) : _r = math.Random(semilla);

  final math.Random _r;
  double? _normalGuardada;

  /// `random-float x`: uniforme en [0, x).
  double uniforme([double x = 1]) => _r.nextDouble() * x;

  /// `random n`: entero uniforme en [0, n).
  int entero(int n) => _r.nextInt(n);

  /// `random-normal media desviacion` (Box–Muller).
  double normal(double media, double desviacion) {
    final guardada = _normalGuardada;
    if (guardada != null) {
      _normalGuardada = null;
      return media + desviacion * guardada;
    }
    double u1;
    do {
      u1 = _r.nextDouble();
    } while (u1 <= 0);
    final u2 = _r.nextDouble();
    final radio = math.sqrt(-2 * math.log(u1));
    _normalGuardada = radio * math.sin(2 * math.pi * u2);
    return media + desviacion * radio * math.cos(2 * math.pi * u2);
  }
}
