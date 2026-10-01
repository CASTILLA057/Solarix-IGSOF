import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:solarix/app.dart';

void main() {
  testWidgets('La app arranca en la pantalla de inicio', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: SolarixApp()));
    await tester.pumpAndSettle();

    expect(find.text('Solarix'), findsWidgets);
    expect(find.textContaining('Supabase'), findsOneWidget);
  });
}
