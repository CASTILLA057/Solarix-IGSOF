import '../../../core/formato.dart';
import '../domain/parametros.dart';

/// Lo que el modelo de NetLogo cuenta como energía comprada a la red. En un
/// sistema aislado no hay red (Etapa 12): es energía que faltó. Solo cambian
/// la etiqueta y la nota; las ecuaciones son las mismas.
String etiquetaEnergiaRed({required bool sinRed}) =>
    sinRed ? 'Energía que faltó' : 'Energía comprada a la red';

/// Nota para los sistemas aislados.
const notaEnergiaQueFalto =
    'Sistema aislado: no hay red. Lo que el modelo cuenta como energía '
    'comprada a la red es energía que faltó: horas de corte, o que se cubren '
    'con una planta o con combustible.';

/// Frase que compara la política consciente con la convencional con el
/// mismo clima. [cambioCaida] y [cambioEnergia] son cambios relativos
/// (−0,12 = 12 % menos). Diferencias por debajo de 0,05 % cuentan como cero:
/// así nunca se muestra "−0,0 %".
String fraseComparacionPoliticas({
  required double cambioCaida,
  required double cambioEnergia,
  required String energia,
}) {
  bool nulo(double x) => (x * 100).abs() < 0.05;
  if (nulo(cambioCaida) && nulo(cambioEnergia)) {
    return 'Con el mismo clima, las dos políticas dan el mismo resultado: '
        'con este sistema la batería casi nunca llega a los límites de la '
        'política consciente (95 % de carga y 0,16 C).';
  }
  String cambio(double x, String que) => nulo(x)
      ? 'no cambia $que'
      : '${x < 0 ? 'reduce' : 'aumenta'} $que en '
            '${Formato.numero((x * 100).abs(), 1)} %';
  return 'Con el mismo clima, la política consciente '
      '${cambio(cambioCaida, 'la caída del SoH')} y '
      '${cambio(cambioEnergia, 'la ${energia.toLowerCase()}')}.';
}

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

/// Entorno simulado en una línea: el de un lugar (irradiancia y temperatura
/// propias, Etapa 12) o una configuración de NetLogo.
String textoEntorno({
  required EscenarioIrradiancia escenario,
  required ZonaClimatica zona,
  double? irradianciaMaximaLugar,
  double? temperaturaMediaLugar,
}) {
  final lugar = irradianciaMaximaLugar != null
      ? 'irradiancia máxima ${Formato.numero(irradianciaMaximaLugar)} W/m²'
            '${temperaturaMediaLugar != null ? ' · ${Formato.numero(temperaturaMediaLugar, 1)} °C' : ''}'
      : 'irradiancia ${escenario.etiqueta.toLowerCase()} (NetLogo)';
  return '$lugar · zona ${zona.etiqueta.toLowerCase()}';
}
