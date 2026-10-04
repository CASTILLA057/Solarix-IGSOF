import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../test/helpers/backend_memoria.dart';
import '../test/helpers/flujo_completo.dart';

/// Recorrido de principio a fin en el celular con el Supabase falso: no
/// necesita internet ni toca la base de datos. Corre con:
///
///     flutter test integration_test/flujo_completo_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'registro → calculadora → simulación → guardar → historial (Supabase falso)',
    (tester) async {
      final backend = BackendEnMemoria();
      await abrirConBackendFalso(tester, backend);

      await registrarse(tester);
      await calcularSimularYRevisar(tester, nombreCalculo: 'Casa de prueba');

      expect(
        backend.filasSimulaciones.single['calculo_id'],
        backend.filasCalculos.single['id'],
      );
    },
  );
}
