import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solarix/app.dart';

void main() {
  testWidgets('Sin env.json la app arranca en el login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SolarixApp()));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(FilledButton, 'Iniciar sesión'), findsOneWidget);
  });
}
