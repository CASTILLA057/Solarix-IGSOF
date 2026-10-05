import '../../auth/domain/perfil.dart';
import 'modelos.dart';

/// Equipos comunes para agregar con un toque. Potencias típicas; el usuario
/// puede editarlas.
const equiposBase = <Equipo>[
  Equipo(nombre: 'Bombillo LED', potenciaW: 9, horasDia: 5, cantidad: 4),
  Equipo(nombre: 'Televisor', potenciaW: 80, horasDia: 4),
  Equipo(nombre: 'Nevera', potenciaW: 150, kwhDia: 1.2, factorArranque: 4),
  Equipo(
    nombre: 'Cargador de celular',
    potenciaW: 10,
    horasDia: 3,
    cantidad: 2,
  ),
  Equipo(nombre: 'Router wifi', potenciaW: 10, horasDia: 24),
  Equipo(nombre: 'Computador portátil', potenciaW: 65, horasDia: 4),
  Equipo(nombre: 'Ventilador', potenciaW: 55, horasDia: 6),
  Equipo(nombre: 'Lavadora', potenciaW: 500, horasDia: 1, factorArranque: 3),
  Equipo(
    nombre: 'Bomba de agua',
    potenciaW: 750,
    horasDia: 1,
    factorArranque: 4,
  ),
  Equipo(
    nombre: 'Aire acondicionado 12 000 BTU',
    potenciaW: 1100,
    horasDia: 6,
    factorArranque: 3,
  ),
  Equipo(nombre: 'Licuadora', potenciaW: 400, horasDia: 0.2),
  Equipo(nombre: 'Plancha', potenciaW: 1000, horasDia: 0.5),
];

/// Ciudad con su recurso solar (tabla `ciudades`).
class Ciudad {
  const Ciudad(this.nombre, this.departamento, this.hsp);

  factory Ciudad.desdeMapa(Map<String, dynamic> m) => Ciudad(
    m['nombre'] as String,
    m['departamento'] as String,
    (m['hsp'] as num).toDouble(),
  );

  final String nombre;
  final String departamento;

  /// Horas solares pico promedio anual (kWh/m²/día).
  final double hsp;

  ZonaIrradiancia get zona => zonaParaHsp(hsp);

  String get etiqueta => '$nombre ($departamento)';
}

/// Clasifica las HSP en las tres zonas del modelo de NetLogo.
ZonaIrradiancia zonaParaHsp(double hsp) {
  if (hsp >= 5) return ZonaIrradiancia.alta;
  if (hsp >= 4) return ZonaIrradiancia.media;
  return ZonaIrradiancia.baja;
}

/// HSP representativa de cada zona (las del Proyecto Integrador I).
double hspParaZona(ZonaIrradiancia zona) => switch (zona) {
  ZonaIrradiancia.alta => 5.5,
  ZonaIrradiancia.media => 4.5,
  ZonaIrradiancia.baja => 3.5,
};

/// Respaldo sin internet: los mismos valores de la migración `ciudades`.
/// HSP = promedio anual de radiación global horizontal de NASA POWER
/// (`ALLSKY_SFC_SW_DWN`), consultado el 2026-10-01 en las coordenadas de
/// cada ciudad y redondeado a un decimal. Resolución de unos 50 km: ciudades
/// cercanas pueden compartir valor (Armenia, Ibagué y Pereira).
const ciudadesBase = <Ciudad>[
  Ciudad('Arauca', 'Arauca', 5.0),
  Ciudad('Armenia', 'Quindío', 4.5),
  Ciudad('Barranquilla', 'Atlántico', 5.4),
  Ciudad('Bogotá', 'Bogotá D. C.', 4.6),
  Ciudad('Bucaramanga', 'Santander', 5.1),
  Ciudad('Cali', 'Valle del Cauca', 4.2),
  Ciudad('Cartagena', 'Bolívar', 5.3),
  Ciudad('Cúcuta', 'Norte de Santander', 4.3),
  Ciudad('Florencia', 'Caquetá', 4.4),
  Ciudad('Ibagué', 'Tolima', 4.5),
  Ciudad('Leticia', 'Amazonas', 4.6),
  Ciudad('Manizales', 'Caldas', 4.8),
  Ciudad('Medellín', 'Antioquia', 4.9),
  Ciudad('Montería', 'Córdoba', 5.0),
  Ciudad('Neiva', 'Huila', 4.2),
  Ciudad('Ocaña', 'Norte de Santander', 5.0),
  Ciudad('Pasto', 'Nariño', 4.0),
  Ciudad('Pereira', 'Risaralda', 4.5),
  Ciudad('Popayán', 'Cauca', 4.1),
  Ciudad('Quibdó', 'Chocó', 4.0),
  Ciudad('Riohacha', 'La Guajira', 5.5),
  Ciudad('San Andrés', 'San Andrés y Providencia', 5.3),
  Ciudad('Santa Marta', 'Magdalena', 5.7),
  Ciudad('Sincelejo', 'Sucre', 5.1),
  Ciudad('Tunja', 'Boyacá', 4.5),
  Ciudad('Valledupar', 'Cesar', 5.3),
  Ciudad('Villavicencio', 'Meta', 4.3),
  Ciudad('Yopal', 'Casanare', 4.5),
];

/// Clima de cada ciudad de la lista (Etapa 12), de la misma fuente que las
/// HSP: climatología anual de NASA POWER consultada el 2026-10-05 en las
/// mismas coordenadas de las HSP (las HSP de la consulta coinciden con las de
/// [ciudadesBase]): lluvia (`PRECTOTCORR`, mm/día), nubosidad
/// (`CLOUD_AMT`, %) y temperatura media a 2 m (`T2M`, °C).
///
/// La temperatura se corrige por altitud, porque la celda de NASA (≈ 50 km)
/// promedia valle y montaña: `T = T2M + 0,0065 · (altitud de la celda −
/// altitud de la ciudad)` (6,5 °C por cada 1.000 m). Sin corregir, Cali
/// daba 16 °C y Bogotá 19 °C. Altitudes en `BITACORA.md`. Va en Dart y no
/// en la tabla `ciudades` para no cambiar la base de datos.
const _climaCiudades = <String, ClimaLugar>{
  'Arauca': ClimaLugar(
    lluviaMmDia: 4.15,
    nubosidadPct: 66.7,
    temperaturaC: 27.5,
  ),
  'Armenia': ClimaLugar(
    lluviaMmDia: 4.47,
    nubosidadPct: 81.6,
    temperaturaC: 20.2,
  ),
  'Barranquilla': ClimaLugar(
    lluviaMmDia: 3.08,
    nubosidadPct: 56.9,
    temperaturaC: 27.9,
  ),
  'Bogotá': ClimaLugar(
    lluviaMmDia: 4.45,
    nubosidadPct: 78.4,
    temperaturaC: 13.3,
  ),
  'Bucaramanga': ClimaLugar(
    lluviaMmDia: 3.41,
    nubosidadPct: 71.5,
    temperaturaC: 24.3,
  ),
  'Cali': ClimaLugar(lluviaMmDia: 2.80, nubosidadPct: 83.8, temperaturaC: 23.5),
  'Cartagena': ClimaLugar(
    lluviaMmDia: 3.75,
    nubosidadPct: 65.4,
    temperaturaC: 28.2,
  ),
  'Cúcuta': ClimaLugar(
    lluviaMmDia: 2.49,
    nubosidadPct: 79.0,
    temperaturaC: 28.4,
  ),
  'Florencia': ClimaLugar(
    lluviaMmDia: 3.91,
    nubosidadPct: 81.3,
    temperaturaC: 26.0,
  ),
  'Ibagué': ClimaLugar(
    lluviaMmDia: 4.12,
    nubosidadPct: 81.6,
    temperaturaC: 21.9,
  ),
  'Leticia': ClimaLugar(
    lluviaMmDia: 7.00,
    nubosidadPct: 79.7,
    temperaturaC: 25.8,
  ),
  'Manizales': ClimaLugar(
    lluviaMmDia: 5.44,
    nubosidadPct: 80.7,
    temperaturaC: 16.0,
  ),
  'Medellín': ClimaLugar(
    lluviaMmDia: 6.22,
    nubosidadPct: 79.2,
    temperaturaC: 20.0,
  ),
  'Montería': ClimaLugar(
    lluviaMmDia: 3.75,
    nubosidadPct: 68.0,
    temperaturaC: 28.0,
  ),
  'Neiva': ClimaLugar(
    lluviaMmDia: 3.60,
    nubosidadPct: 82.2,
    temperaturaC: 26.5,
  ),
  'Ocaña': ClimaLugar(
    lluviaMmDia: 2.77,
    nubosidadPct: 71.2,
    temperaturaC: 22.1,
  ),
  'Pasto': ClimaLugar(
    lluviaMmDia: 2.84,
    nubosidadPct: 79.4,
    temperaturaC: 13.3,
  ),
  'Pereira': ClimaLugar(
    lluviaMmDia: 5.44,
    nubosidadPct: 81.6,
    temperaturaC: 20.8,
  ),
  'Popayán': ClimaLugar(
    lluviaMmDia: 2.66,
    nubosidadPct: 81.7,
    temperaturaC: 18.3,
  ),
  'Quibdó': ClimaLugar(
    lluviaMmDia: 12.07,
    nubosidadPct: 89.3,
    temperaturaC: 25.7,
  ),
  'Riohacha': ClimaLugar(
    lluviaMmDia: 2.55,
    nubosidadPct: 56.7,
    temperaturaC: 27.8,
  ),
  'San Andrés': ClimaLugar(
    lluviaMmDia: 4.20,
    nubosidadPct: 62.2,
    temperaturaC: 27.7,
  ),
  'Santa Marta': ClimaLugar(
    lluviaMmDia: 2.32,
    nubosidadPct: 55.3,
    temperaturaC: 28.8,
  ),
  'Sincelejo': ClimaLugar(
    lluviaMmDia: 3.92,
    nubosidadPct: 67.7,
    temperaturaC: 27.0,
  ),
  'Tunja': ClimaLugar(
    lluviaMmDia: 4.89,
    nubosidadPct: 77.9,
    temperaturaC: 11.6,
  ),
  'Valledupar': ClimaLugar(
    lluviaMmDia: 1.97,
    nubosidadPct: 66.0,
    temperaturaC: 28.4,
  ),
  'Villavicencio': ClimaLugar(
    lluviaMmDia: 6.67,
    nubosidadPct: 82.9,
    temperaturaC: 25.0,
  ),
  'Yopal': ClimaLugar(
    lluviaMmDia: 5.38,
    nubosidadPct: 74.2,
    temperaturaC: 26.4,
  ),
};

/// Clima de una ciudad de la lista, o `null` si no está.
ClimaLugar? climaDeCiudad(String nombre) => _climaCiudades[nombre];
