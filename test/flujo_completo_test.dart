import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solarix/features/calculadora/domain/modelos.dart';

import 'helpers/backend_memoria.dart';
import 'helpers/flujo_completo.dart';

/// Recorrido de principio a fin con el Supabase falso, en `flutter test`
/// (corre en CI). La misma secuencia corre en el celular con
/// `integration_test/flujo_completo_test.dart`.
void main() {
  testWidgets(
    'registro → calculadora → simulación → guardar → historial y detalle',
    (tester) async {
      // Celular pequeño (360 × 800), como el de las pruebas manuales: lo de
      // abajo de las listas no está construido hasta desplazarse.
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final backend = BackendEnMemoria();
      final auth = await abrirConBackendFalso(tester, backend, rapido: true);

      await registrarse(tester);
      expect(auth.llamadas, [
        'registrarse:ana@correo.com:Ana',
        'confirmarRegistro:ana@correo.com:12345678',
      ]);

      await calcularSimularYRevisar(tester, nombreCalculo: 'Casa de prueba');

      // Lo guardado quedó vinculado como en Supabase.
      final calculo = backend.filasCalculos.single;
      expect(calculo['nombre'], 'Casa de prueba');
      expect(calculo['tipo_sistema'], TipoSistema.hibrido.valorBd);
      expect(backend.filasSimulaciones.single['calculo_id'], calculo['id']);
    },
  );
}
