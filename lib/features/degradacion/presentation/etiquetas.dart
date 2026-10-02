import '../domain/parametros.dart';

/// Textos en español de las opciones del modelo.
extension EtiquetaPolitica on Politica {
  String get etiqueta => switch (this) {
    Politica.convencional => 'Convencional',
    Politica.consciente => 'Consciente',
  };

  String get descripcion => switch (this) {
    Politica.convencional =>
      'Usa la batería sin restricciones, hasta el SOC máximo.',
    Politica.consciente =>
      'No carga por encima de 95 % y limita la corriente a 0,16 C para '
          'cuidar la batería.',
  };
}

extension EtiquetaEscenario on EscenarioIrradiancia {
  String get etiqueta => switch (this) {
    EscenarioIrradiancia.baja => 'Baja',
    EscenarioIrradiancia.media => 'Media',
    EscenarioIrradiancia.alta => 'Alta',
  };
}

extension EtiquetaZona on ZonaClimatica {
  String get etiqueta => switch (this) {
    ZonaClimatica.mixta => 'Mixta',
    ZonaClimatica.muySoleada => 'Muy soleada',
    ZonaClimatica.muyNublada => 'Muy nublada',
    ZonaClimatica.lluviosa => 'Lluviosa',
    ZonaClimatica.polvorienta => 'Polvorienta',
  };
}
