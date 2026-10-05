import 'package:intl/intl.dart';

/// Formatos numéricos para Colombia (separador de miles con punto).
abstract final class Formato {
  static final _cop = NumberFormat.currency(
    locale: 'es_CO',
    symbol: r'$',
    decimalDigits: 0,
  );

  static String cop(num valor) => _cop.format(valor);

  /// Pesos abreviados para tablas angostas: `22.421.823` → `$ 22,4 M`.
  /// Menos de un millón, completo.
  static String copCorto(num valor) => valor.abs() < 1e6
      ? cop(valor)
      : '${valor < 0 ? '-' : ''}\$ ${numero(valor.abs() / 1e6, 1)} M';

  /// Número con [decimales] decimales, p. ej. `numero(4.25, 1)` → `4,3`.
  static String numero(num valor, [int decimales = 0]) =>
      NumberFormat.decimalPatternDigits(
        locale: 'es_CO',
        decimalDigits: decimales,
      ).format(valor);

  /// Número con hasta 3 decimales, sin ceros de sobra: `1` → `1`,
  /// `0.036` → `0,036`, `1500` → `1.500`.
  static String corto(num valor) =>
      NumberFormat('#,##0.###', 'es_CO').format(valor);

  static String porcentaje(num fraccion) => '${numero(fraccion * 100)} %';

  /// Años con un decimal, o "más de N años" si no se recupera.
  static String anios(double? valor, int horizonte) =>
      valor == null ? 'Más de $horizonte años' : '${numero(valor, 1)} años';

  /// Lee un número escrito a la colombiana: `1.500.000`, `4,5` o `4.5`.
  /// Devuelve `null` si no es un número.
  static double? leer(String? texto) {
    var t = (texto ?? '').trim().replaceAll(' ', '').replaceAll(r'$', '');
    if (t.isEmpty) return null;
    if (t.contains(',')) {
      // Coma decimal: los puntos son separadores de miles.
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if ('.'.allMatches(t).length > 1 ||
        RegExp(r'^[1-9]\d{0,2}(\.\d{3})+$').hasMatch(t)) {
      // Varios puntos, o grupos de tres: separadores de miles. Un número que
      // empieza en "0." es decimal (0.036 no son 36).
      t = t.replaceAll('.', '');
    }
    return double.tryParse(t);
  }
}
