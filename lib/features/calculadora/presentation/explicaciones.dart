/// Qué es cada supuesto de la calculadora, de dónde sale su valor por
/// defecto y cuándo conviene cambiarlo (Etapa 12). Se muestran con el ícono
/// de información de cada campo.
abstract final class Explicacion {
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
