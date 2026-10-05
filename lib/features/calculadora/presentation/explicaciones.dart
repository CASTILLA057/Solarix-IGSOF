import '../domain/modelos.dart';

/// Qué es cada supuesto de la calculadora, de dónde sale su valor por
/// defecto y cuándo conviene cambiarlo (Etapa 12). Se muestran con el ícono
/// de información de cada campo.
abstract final class Explicacion {
  static const tarifa =
      'Escribe el costo unitario (CU) del kWh: lo que vale el kWh antes del '
      'subsidio o la contribución, el mismo que paga el estrato 4. En la '
      'factura aparece como costo unitario o valor del kWh; en los estratos 1 '
      'a 3 la factura muestra aparte el subsidio, y en el 5 y el 6 la '
      'contribución. El estrato que eliges abajo se encarga del resto.';

  static const estrato =
      'Los estratos 1, 2 y 3 reciben un subsidio sobre los primeros kWh del '
      'mes (el consumo de subsistencia): hasta 60 % el 1 y hasta 50 % el 2 '
      '(Ley 1117 de 2006), y hasta 15 % el 3 (Ley 142 de 1994, art. 99). Los '
      'estratos 5 y 6 pagan una contribución de 20 % sobre todo el consumo '
      '(Ley 142, art. 89). El 4 paga el costo del servicio.\n\n'
      'Con paneles, tu factura se calcula sobre el consumo neto del mes, '
      'después de descontar lo que envías a la red, y el subsidio se aplica '
      'sobre ese neto (concepto CREG 3023 de 2026). Por eso la energía solar '
      'quita primero los kWh de arriba: en los estratos 1 a 3, cada kWh que '
      'generas vale la tarifa completa hasta bajar al consumo de '
      'subsistencia, y desde ahí vale la tarifa con subsidio. Los paneles '
      'ahorran menos en los estratos bajos y más en el 5 y el 6.\n\n'
      'Por defecto se usa el subsidio máximo de la ley; si tu factura muestra '
      'otro, escríbelo en "Subsidio de tu factura".';

  static const subsidioFactura =
      'El operador puede aplicar un subsidio menor que el máximo de la ley: '
      'en los estratos 1 y 2 la tarifa con subsidio se ajusta con su propia '
      'fórmula. En la factura aparece como "subsidio" junto al consumo de '
      'subsistencia. Con menos subsidio, cada kWh que dejas de comprar vale '
      'más y los paneles ahorran más.';

  static const subsistencia =
      'Energía con subsidio en los estratos 1 a 3: 173 kWh/mes en '
      'municipios por debajo de 1.000 m de altura y 130 kWh/mes desde '
      '1.000 m (Resolución UPME 355 de 2004), según la altura de la cabecera '
      'municipal. Con una ciudad de la lista se toma la de su municipio. Con '
      '"Mi ubicación" se usa la altura de tu punto (del GPS o del mapa de '
      'elevación de Open-Meteo), que cerca de 1.000 m puede no coincidir con '
      'la de la cabecera: en Cali, por ejemplo, la cabecera da 173. Si no hay '
      'altura, o con las HSP a mano, se usa 173: elige 130 si vives a 1.000 m '
      'o más.';

  static const rendimiento =
      'Parte de la energía del panel que llega a la casa, después de las '
      'pérdidas por calor, cableado, suciedad e inversor.\n\n'
      'Los sistemas residenciales suelen estar entre 75 y 85 %. Se usa 78 %, '
      'un valor conservador para el calor de Colombia. Súbelo si tu '
      'instalador garantiza un rendimiento mayor.';

  static const cobertura =
      'Parte de tu consumo que quieres producir con los paneles. 100 % '
      'busca generar en el año lo mismo que consumes; menos de 100 % es un '
      'sistema más pequeño y barato que solo reduce la factura.';

  static const diasAutonomia =
      'Días seguidos sin sol que la batería debe cubrir toda la casa. Dos '
      'días es lo usual en viviendas aisladas; más días encarecen mucho la '
      'batería.';

  static const autoconsumo =
      'Parte de lo que generan los paneles que la casa usa en el momento. El '
      'resto sale a la red como excedente.\n\n'
      'Sin batería depende de cuánto consumes de día: de 30 % (casa vacía '
      'de día) a 60 % (alguien en casa, nevera, trabajo en casa). Por '
      'defecto: 60 % conectado a la red y 90 % con batería, que guarda lo '
      'del día para la noche. Es una estimación: si nadie está en casa de '
      'día, bájalo.';

  static const fraccionNocturna =
      'Parte de tu consumo que ocurre sin sol (tarde, noche y madrugada). '
      'Define el tamaño de la batería del sistema híbrido.\n\n'
      'En los hogares colombianos el consumo sube entre las 6 y las 10 de '
      'la noche; 50 % es una estimación. Ajústalo a tus hábitos.';

  static const comercializacion =
      'CREG 174 de 2021: lo que envías a la red, hasta lo que tomas de ella '
      'en el mes, se descuenta de tu factura (permuta), pero el operador '
      'cobra el costo de comercialización (Cv) por cada kWh.\n\n'
      'En 2026 el Cv va de unos \$68/kWh (EMCALI) a \$121/kWh (EPM). Se '
      'usa \$100/kWh; búscalo en tu factura como "comercialización".';

  static const precioBolsa =
      'CREG 174 de 2021: lo que envías a la red por encima de lo que tomas '
      'de ella en el mes se paga a precio de bolsa, mucho menos que la '
      'tarifa.\n\n'
      'El precio de bolsa cambia mucho: en 2026 el promedio mensual fue de '
      '\$120/kWh en febrero y de \$947/kWh en agosto (El Niño), según XM. Se '
      'usa \$300/kWh como promedio de varios años.';

  static const incrementoTarifa =
      'Cuánto sube cada año el precio del kWh. Con él crece el ahorro. 6 % '
      'es una estimación cercana a la inflación más los ajustes de tarifa '
      'recientes; es incierto, prueba con otros valores.';

  static const mantenimiento =
      'Limpieza de paneles, revisión de conexiones y reemplazos menores, '
      'como porcentaje de la inversión cada año. 1 % es un valor usual para '
      'sistemas residenciales.';

  static const tasaDescuento =
      'Rentabilidad que le exigirías a tu dinero en otra inversión (por '
      'ejemplo, un CDT). Se usa para el VPN y la recuperación descontada: un '
      'peso de dentro de diez años vale menos que uno de hoy.';

  static const horizonte =
      'Años que cubre el análisis. Los paneles suelen garantizar 25 años de '
      'producción; 20 es un horizonte prudente.';

  static const vidaCalendario =
      'Años que dura la batería aunque se use poco: con el tiempo se '
      'degrada sola, más rápido con calor. El modelo de degradación no '
      'incluye este efecto, así que es el tope de la vida simulada.\n\n'
      'Para LiFePO₄ se usan 15 años y para plomo-ácido 6. En climas muy '
      'calientes conviene bajarlo.';

  static const ley1715 =
      'La Ley 1715 de 2014 (modificada por la Ley 2099 de 2021) da '
      'incentivos a quien invierte en energía solar. Para usarlos necesitas '
      'el certificado de la UPME, que normalmente tramita el instalador. Por '
      'eso vienen apagados.';

  static const exclusionIva =
      'Los equipos y servicios del sistema solar se compran sin IVA (19 %). '
      'Los precios de referencia son de tienda, con IVA, así que se descuenta '
      'de toda la inversión.';

  static const tarifaRenta =
      'Puedes deducir de tu renta líquida el 50 % de la inversión, en los 15 '
      'años siguientes y sin pasar del 50 % de tu renta líquida de cada año. '
      'El beneficio es esa deducción por tu tarifa marginal de renta.\n\n'
      'Escribe 0 si no declaras renta. La app supone que la tomas completa '
      'el primer año; si tu renta es baja, el beneficio llegará más tarde.';

  static const margenes =
      'El inversor y el controlador llevan un margen del 25 % sobre lo '
      'calculado. En el controlador es el factor de 125 % que pide la NTC '
      '2050 (sección 690) para la corriente de los paneles; en el inversor, '
      'un margen de diseño para el uso simultáneo de equipos.';
}

/// El estrato en una línea: "Estrato 2 · subsidio hasta 50 %".
String textoEstrato(Estrato e) {
  String pct(double f) => '${(f * 100).round()} %';
  if (e.subsidio > 0) {
    return '${e.etiqueta} · subsidio hasta ${pct(e.subsidio)}';
  }
  if (e.contribucion > 0) {
    return '${e.etiqueta} · contribución de ${pct(e.contribucion)}';
  }
  return '${e.etiqueta} · sin subsidio ni contribución';
}

/// El estrato para el campo cerrado de la lista: "Estrato 2" (el subsidio
/// va en su propio campo), "Estrato 5 · +20 %".
String textoEstratoCorto(Estrato e) => e.contribucion > 0
    ? '${e.etiqueta} · +${(e.contribucion * 100).round()} %'
    : e.etiqueta;

/// El estrato con el subsidio que se usó: si es el de la factura,
/// "Estrato 2 · subsidio de 40 %"; si es el máximo, como [textoEstrato].
String textoEstratoAplicado(EntradasCalculo e) =>
    e.subsidioEstrato == null || e.estrato.subsidio == 0
    ? textoEstrato(e.estrato)
    : '${e.estrato.etiqueta} · subsidio de '
          '${(e.subsidioAplicado * 100).round()} %';
