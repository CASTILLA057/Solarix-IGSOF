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
