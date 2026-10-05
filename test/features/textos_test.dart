import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/calculadora/presentation/explicaciones.dart';
import 'package:solarix/features/degradacion/presentation/etiquetas.dart';

void main() {
  group('Comparación de políticas', () {
    String frase(double caida, double energia) => fraseComparacionPoliticas(
      cambioCaida: caida,
      cambioEnergia: energia,
      energia: 'Energía que faltó',
    );

    test('sin diferencia lo dice con palabras, sin "−0,0 %"', () {
      final f = frase(-0.0002, 0);
      expect(f, contains('las dos políticas dan el mismo resultado'));
      expect(f, isNot(contains('-0,0')));
      expect(f, isNot(contains('−0,0')));
    });

    test('con diferencia dice si reduce o aumenta, sin signo', () {
      expect(
        frase(-0.123, 0.045),
        'Con el mismo clima, la política consciente reduce la caída del SoH '
        'en 12,3 % y aumenta la energía que faltó en 4,5 %.',
      );
    });

    test('una sola diferencia nula: "no cambia"', () {
      expect(
        frase(-0.2, 0.0001),
        'Con el mismo clima, la política consciente reduce la caída del SoH '
        'en 20,0 % y no cambia la energía que faltó.',
      );
    });
  });

  test('estrato en el campo cerrado de la lista: corto', () {
    expect(textoEstratoCorto(Estrato.uno), 'Estrato 1');
    expect(textoEstratoCorto(Estrato.cuatro), 'Estrato 4');
    expect(textoEstratoCorto(Estrato.seis), 'Estrato 6 · +20 %');
  });
}
