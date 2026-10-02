// Resultados de NetLogo usados como referencia para validar el motor en Dart.
// Copiados de docs/referencia/VALIDACION.md (10 corridas por caso) y
// docs/referencia/GUIA_VARIACION.md (5 corridas por caso, escenario alto,
// política convencional y zona mixta salvo la variable que se cambia).
import 'package:solarix/features/degradacion/domain/parametros.dart';

typedef CasoValidacion = ({
  EscenarioIrradiancia escenario,
  Politica politica,
  double sohFinal,
  double comprada,
  double ciclos,
  double limpiezas,
});

const casosValidacion = <CasoValidacion>[
  (
    escenario: EscenarioIrradiancia.media,
    politica: Politica.convencional,
    sohFinal: 86.09,
    comprada: 23941,
    ciclos: 2606,
    limpiezas: 73,
  ),
  (
    escenario: EscenarioIrradiancia.media,
    politica: Politica.consciente,
    sohFinal: 100 - 12.84,
    comprada: 24964,
    ciclos: 2492,
    limpiezas: 73,
  ),
  (
    escenario: EscenarioIrradiancia.alta,
    politica: Politica.convencional,
    sohFinal: 84.98,
    comprada: 23958,
    ciclos: 2702,
    limpiezas: 71,
  ),
  (
    escenario: EscenarioIrradiancia.alta,
    politica: Politica.consciente,
    sohFinal: 100 - 13.43,
    comprada: 25402,
    ciclos: 2556,
    limpiezas: 79,
  ),
];

/// SoH año a año (años 0 a 10), política convencional.
const sohAnualMediaNetlogo = [
  100.00, 98.75, 97.34, 95.93, 94.49, 93.05, 91.61, 90.20, 88.81, 87.43, //
  86.09,
];
const sohAnualAltaNetlogo = [
  100.00, 98.60, 97.06, 95.48, 93.91, 92.35, 90.81, 89.30, 87.83, 86.39, //
  84.98,
];

/// Cambio de la política consciente frente a la convencional en NetLogo.
const cambiosConscienteNetlogo = {
  EscenarioIrradiancia.media: (energia: 0.043, flujo: -0.044, caidaSoh: -0.077),
  EscenarioIrradiancia.alta: (energia: 0.060, flujo: -0.054, caidaSoh: -0.106),
};

typedef CasoGuia = ({
  String nombre,
  ParametrosSimulacion parametros,
  double soh,
  double? comprada,
  (int, int)? limpiezas,
});

const _base = ParametrosSimulacion();

final casosGuia = <CasoGuia>[
  (
    nombre: 'Referencia',
    parametros: _base,
    soh: 84.99,
    comprada: 23975,
    limpiezas: (40, 110),
  ),
  (
    nombre: 'Escenario bajo',
    parametros: _base.copiarCon(escenario: EscenarioIrradiancia.baja),
    soh: 100.00,
    comprada: 59845,
    limpiezas: null,
  ),
  (
    nombre: 'Escenario medio',
    parametros: _base.copiarCon(escenario: EscenarioIrradiancia.media),
    soh: 86.07,
    comprada: 23842,
    limpiezas: null,
  ),
  (
    nombre: 'Política consciente',
    parametros: _base.copiarCon(politica: Politica.consciente),
    soh: 86.57,
    comprada: 25428,
    limpiezas: null,
  ),
  (
    nombre: 'Batería 5 kWh',
    parametros: _base.copiarCon(capacidadBateriaKwh: 5),
    soh: 84.20,
    comprada: 36875,
    limpiezas: null,
  ),
  (
    nombre: 'Batería 20 kWh',
    parametros: _base.copiarCon(capacidadBateriaKwh: 20),
    soh: 88.76,
    comprada: 5901,
    limpiezas: null,
  ),
  (
    nombre: 'Panel 2 kW',
    parametros: _base.copiarCon(potenciaPanelKw: 2),
    soh: 94.20,
    comprada: 41467,
    limpiezas: null,
  ),
  (
    nombre: 'Panel 10 kW',
    parametros: _base.copiarCon(potenciaPanelKw: 10),
    soh: 84.49,
    comprada: 21577,
    limpiezas: null,
  ),
  (
    nombre: 'Tasa C 0,2',
    parametros: _base.copiarCon(tasaCMaxima: 0.2),
    soh: 85.24,
    comprada: 24021,
    limpiezas: null,
  ),
  (
    nombre: 'Tasa C 1',
    parametros: _base.copiarCon(tasaCMaxima: 1),
    soh: 84.98,
    comprada: 24068,
    limpiezas: null,
  ),
  (
    nombre: 'Carga mínima 10 %',
    parametros: _base.copiarCon(cargaMinima: 10),
    soh: 82.76,
    comprada: 21204,
    limpiezas: null,
  ),
  (
    nombre: 'Carga mínima 40 %',
    parametros: _base.copiarCon(cargaMinima: 40),
    soh: 89.44,
    comprada: 29918,
    limpiezas: null,
  ),
  (
    nombre: 'Carga máxima 60 %',
    parametros: _base.copiarCon(cargaMaxima: 60),
    soh: 93.62,
    comprada: 36149,
    limpiezas: null,
  ),
  (
    nombre: 'Carga máxima 80 %',
    parametros: _base.copiarCon(cargaMaxima: 80),
    soh: 89.44,
    comprada: 29882,
    limpiezas: null,
  ),
  (
    nombre: 'Sin polvo',
    parametros: _base.copiarCon(tasaPolvo: 0),
    soh: 84.95,
    comprada: 23869,
    limpiezas: (0, 0),
  ),
  (
    nombre: 'Polvo 0,1 g/h',
    parametros: _base.copiarCon(tasaPolvo: 0.1),
    soh: 84.99,
    comprada: 23962,
    limpiezas: (230, 293),
  ),
  (
    nombre: 'Umbral de limpieza 2 %',
    parametros: _base.copiarCon(umbralLimpieza: 2),
    soh: 84.95,
    comprada: 23917,
    limpiezas: (343, 458),
  ),
  (
    nombre: 'Umbral de limpieza 40 %',
    parametros: _base.copiarCon(umbralLimpieza: 40),
    soh: 85.06,
    comprada: 24166,
    limpiezas: (1, 7),
  ),
  (
    nombre: 'Zona muy soleada',
    parametros: _base.copiarCon(zona: ZonaClimatica.muySoleada),
    soh: 84.83,
    comprada: 23488,
    limpiezas: (173, 311),
  ),
  (
    nombre: 'Zona muy nublada',
    parametros: _base.copiarCon(zona: ZonaClimatica.muyNublada),
    soh: 85.11,
    comprada: 24295,
    limpiezas: (9, 44),
  ),
  (
    nombre: 'Zona lluviosa',
    parametros: _base.copiarCon(zona: ZonaClimatica.lluviosa),
    soh: 85.18,
    comprada: 24171,
    limpiezas: (0, 5),
  ),
  (
    nombre: 'Zona polvorienta',
    parametros: _base.copiarCon(zona: ZonaClimatica.polvorienta),
    soh: 84.91,
    comprada: 23961,
    limpiezas: (488, 615),
  ),
  (
    nombre: 'Escala de degradación ×0,5',
    parametros: _base.copiarCon(escalaDegradacion: 0.0000039),
    soh: 91.85,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Escala de degradación ×2 (fin de vida)',
    parametros: _base.copiarCon(escalaDegradacion: 0.0000156),
    soh: 80.00,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Exponente 0,9',
    parametros: _base.copiarCon(exponenteDegradacion: 0.9),
    soh: 96.95,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Exponente 1,3 (fin de vida)',
    parametros: _base.copiarCon(exponenteDegradacion: 1.3),
    soh: 80.00,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Peso corriente 0',
    parametros: _base.copiarCon(pesoCorriente: 0),
    soh: 87.32,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Peso corriente 6',
    parametros: _base.copiarCon(pesoCorriente: 6),
    soh: 80.77,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Peso variación de carga 0',
    parametros: _base.copiarCon(pesoVariacionCarga: 0),
    soh: 88.33,
    comprada: null,
    limpiezas: null,
  ),
  (
    nombre: 'Peso variación de carga 5 (fin de vida)',
    parametros: _base.copiarCon(pesoVariacionCarga: 5),
    soh: 80.00,
    comprada: null,
    limpiezas: null,
  ),
];
