import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/calculadora/presentation/widgets/equipos_editor.dart';

/// Muestra el editor y guarda la lista que devuelve en [equipos].
/// A 1.080 px se ve la tabla de la web; a 360 px, la lista del celular.
Future<ValueNotifier<List<Equipo>>> _abrir(
  WidgetTester tester, [
  List<Equipo> iniciales = const [],
  Size tamano = const Size(1080, 2400),
]) async {
  tester.view.physicalSize = tamano;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final equipos = ValueNotifier(iniciales);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ValueListenableBuilder(
            valueListenable: equipos,
            builder: (_, lista, _) => EquiposEditor(
              equipos: lista,
              onChanged: (nueva) => equipos.value = nueva,
            ),
          ),
        ),
      ),
    ),
  );
  return equipos;
}

Future<void> _tocar(WidgetTester tester, Finder f) async {
  await tester.ensureVisible(f);
  await tester.tap(f);
  await tester.pumpAndSettle();
}

Future<void> _escribir(WidgetTester tester, String campo, String texto) =>
    tester.enterText(find.widgetWithText(TextFormField, campo), texto);

void main() {
  testWidgets('agrega un equipo de la lista', (tester) async {
    final equipos = await _abrir(tester);
    await _tocar(tester, find.text('Agregar equipo'));
    final primero = equiposBase.first;
    await _tocar(tester, find.text(primero.nombre).last);
    expect(equipos.value.single.nombre, primero.nombre);
    // Tabla de la web: nombre y cantidad en su columna.
    expect(find.text(primero.nombre), findsOneWidget);
    expect(find.text('${primero.cantidad}'), findsOneWidget);
  });

  testWidgets('"Otro equipo…": valida, guarda y suma el consumo', (
    tester,
  ) async {
    final equipos = await _abrir(tester);
    await _tocar(tester, find.text('Agregar equipo'));
    await _tocar(tester, find.text('Otro equipo…'));
    expect(find.text('Nuevo equipo'), findsOneWidget);

    // Vacío: no se guarda y explica qué falta.
    await _tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));
    expect(find.text('Escribe el nombre.'), findsOneWidget);
    expect(find.text('Escribe un número.'), findsWidgets);
    expect(equipos.value, isEmpty);

    await _escribir(tester, 'Nombre', 'Bomba');
    await _escribir(tester, 'Potencia', '750');
    await _escribir(tester, 'Horas de uso al día', '2');
    await _tocar(tester, find.text('Tiene motor'));
    await _tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

    final bomba = equipos.value.single;
    expect(bomba.nombre, 'Bomba');
    expect(bomba.potenciaW, 750);
    expect(bomba.horasDia, 2);
    expect(bomba.factorArranque, greaterThan(1));
    expect(find.text('750 W'), findsOneWidget);
    expect(find.text('2 h'), findsOneWidget);
    expect(find.text('1.500 Wh'), findsOneWidget);
    // Banda verde con el total.
    expect(find.text('Consumo total: 1,50 kWh/día'), findsOneWidget);
    expect(find.text('≈ 45 kWh al mes'), findsOneWidget);
  });

  testWidgets('en el celular: lista con cantidad, potencia, uso y consumo', (
    tester,
  ) async {
    await _abrir(tester, const [
      Equipo(nombre: 'Bombillo LED', potenciaW: 9, horasDia: 5, cantidad: 4),
    ], const Size(360, 800));
    expect(find.text('Bombillo LED'), findsOneWidget);
    expect(find.text('4 × 9 W · 5 h/día'), findsOneWidget);
    expect(find.text('180 Wh'), findsOneWidget);
    expect(find.text('Consumo total: 0,18 kWh/día'), findsOneWidget);
    // Sin la tabla de la web.
    expect(find.text('USO AL DÍA'), findsNothing);
  });

  testWidgets('edita un equipo: cantidad y consumo por ciclos', (tester) async {
    final equipos = await _abrir(tester, const [
      Equipo(nombre: 'Nevera', potenciaW: 150, horasDia: 24),
    ]);
    await _tocar(tester, find.text('Nevera'));
    expect(find.text('Editar equipo'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '150'), findsOneWidget);

    await _escribir(tester, 'Cantidad', '2');
    await _tocar(tester, find.text('Funciona por ciclos'));
    await _escribir(tester, 'Consumo diario por unidad', '1,2');
    await _tocar(tester, find.widgetWithText(FilledButton, 'Guardar'));

    final nevera = equipos.value.single;
    expect(nevera.cantidad, 2);
    expect(nevera.kwhDia, 1.2);
    expect(find.text('1,2 kWh'), findsOneWidget);
    expect(find.text('2.400 Wh'), findsOneWidget);
  });

  testWidgets('cancelar no cambia nada; "Quitar" elimina', (tester) async {
    const tv = Equipo(nombre: 'TV', potenciaW: 80, horasDia: 4);
    final equipos = await _abrir(tester, const [tv]);

    await _tocar(tester, find.text('TV'));
    await _escribir(tester, 'Potencia', '999');
    await _tocar(tester, find.text('Cancelar'));
    expect(equipos.value.single.potenciaW, 80);

    await _tocar(tester, find.byTooltip('Quitar'));
    expect(equipos.value, isEmpty);
    expect(find.text('TV'), findsNothing);
  });
}
