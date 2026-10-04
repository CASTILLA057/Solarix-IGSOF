import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/features/calculadora/domain/catalogos.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';
import 'package:solarix/features/calculadora/presentation/widgets/equipos_editor.dart';

/// Muestra el editor y guarda la lista que devuelve en [equipos].
Future<ValueNotifier<List<Equipo>>> _abrir(
  WidgetTester tester, [
  List<Equipo> iniciales = const [],
]) async {
  tester.view.physicalSize = const Size(1080, 2400);
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
    expect(
      find.text('${primero.nombre} × ${primero.cantidad}'),
      findsOneWidget,
    );
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
    expect(find.text('750 W · 2,0 h/día → 1.500 Wh/día'), findsOneWidget);
    expect(
      find.text('Consumo total: 1,50 kWh/día (45 kWh/mes)'),
      findsOneWidget,
    );
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
    expect(find.text('Nevera × 2'), findsOneWidget);
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
