import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/error_app.dart';
import '../domain/modelos.dart';

/// Recurso solar y clima de la ubicación actual del dispositivo, según la
/// climatología de NASA POWER: promedio anual de radiación global horizontal
/// (`ALLSKY_SFC_SW_DWN`, kWh/m²/día = HSP), de lluvia (`PRECTOTCORR`), de
/// nubosidad (`CLOUD_AMT`) y de temperatura (`T2M`).
abstract interface class RecursoSolarService {
  /// [altitudM]: la del GPS o, si no la da, la del terreno según las
  /// coordenadas; `null` si ninguna está disponible.
  Future<({double hsp, ClimaLugar? clima, double? altitudM})>
  recursoEnUbicacionActual();
}

/// Extrae el promedio anual de la respuesta JSON de NASA POWER.
double hspDesdeRespuestaNasa(String cuerpo) {
  final json = jsonDecode(cuerpo) as Map<String, dynamic>;
  final valor =
      (((json['properties'] as Map)['parameter'] as Map)['ALLSKY_SFC_SW_DWN']
          as Map)['ANN'];
  if (valor is! num || valor <= 0) {
    throw const FormatException('Respuesta de NASA POWER sin dato anual.');
  }
  return valor.toDouble();
}

/// Lluvia, nubosidad y temperatura anuales de la respuesta; `null` si falta
/// alguna (la HSP sigue sirviendo). Con [altitudLugar] (m), la temperatura
/// se corrige por la diferencia con la altitud de la celda de NASA
/// (6,5 °C por cada 1.000 m), como en el catálogo de ciudades.
ClimaLugar? climaDesdeRespuestaNasa(String cuerpo, {double? altitudLugar}) {
  final json = jsonDecode(cuerpo) as Map;
  final parametros = (json['properties'] as Map)['parameter'] as Map;
  final lluvia = (parametros['PRECTOTCORR'] as Map?)?['ANN'];
  final nubes = (parametros['CLOUD_AMT'] as Map?)?['ANN'];
  final temperatura = (parametros['T2M'] as Map?)?['ANN'];
  if (lluvia is! num ||
      nubes is! num ||
      temperatura is! num ||
      lluvia < 0 ||
      nubes < 0 ||
      temperatura < -50) {
    return null;
  }
  final coordenadas = (json['geometry'] as Map?)?['coordinates'] as List?;
  final altitudCelda = coordenadas != null && coordenadas.length > 2
      ? coordenadas[2]
      : null;
  final correccion = altitudLugar != null && altitudCelda is num
      ? gradienteTermico * (altitudCelda - altitudLugar)
      : 0.0;
  return ClimaLugar(
    lluviaMmDia: lluvia.toDouble(),
    nubosidadPct: nubes.toDouble(),
    temperaturaC: temperatura + correccion,
  );
}

/// Altitud del terreno (m) en unas coordenadas, del servicio gratuito de
/// Open-Meteo (modelo de elevación Copernicus de 90 m). Hace falta porque la
/// app pide la ubicación aproximada, que sale de las redes y no trae altitud.
Uri uriElevacion({required double latitud, required double longitud}) =>
    Uri.https('api.open-meteo.com', '/v1/elevation', {
      'latitude': latitud.toStringAsFixed(3),
      'longitude': longitud.toStringAsFixed(3),
    });

/// Altitud de la respuesta de Open-Meteo; `null` si no viene. A diferencia
/// del GPS, 0 m es un dato (el nivel del mar).
double? elevacionDesdeRespuesta(String cuerpo) {
  try {
    final lista = (jsonDecode(cuerpo) as Map)['elevation'];
    if (lista is List && lista.isNotEmpty && lista.first is num) {
      return (lista.first as num).toDouble();
    }
  } catch (_) {
    // Respuesta que no es JSON: sin altitud.
  }
  return null;
}

/// °C que baja la temperatura por metro de altura.
const gradienteTermico = 0.0065;

Uri uriNasaPower({required double latitud, required double longitud}) =>
    Uri.https('power.larc.nasa.gov', '/api/temporal/climatology/point', {
      'parameters': 'ALLSKY_SFC_SW_DWN,PRECTOTCORR,CLOUD_AMT,T2M',
      'community': 'RE',
      'latitude': latitud.toStringAsFixed(3),
      'longitude': longitud.toStringAsFixed(3),
      'format': 'JSON',
    });

class NasaPowerRecursoSolar implements RecursoSolarService {
  NasaPowerRecursoSolar({http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  final http.Client _cliente;

  /// La API de climatología de NASA puede tardar más de un minuto.
  static const tiempoMaximo = Duration(seconds: 90);

  @override
  Future<({double hsp, ClimaLugar? clima, double? altitudM})>
  recursoEnUbicacionActual() async {
    final posicion = await _ubicacion();
    // El GPS da 0 cuando no conoce la altitud (siempre, con la ubicación
    // aproximada): entonces se pide por las coordenadas.
    final altitud = posicion.altitude > 0
        ? posicion.altitude
        : await _altitudPorCoordenadas(posicion);
    try {
      final respuesta = await _cliente
          .get(
            uriNasaPower(
              latitud: posicion.latitude,
              longitud: posicion.longitude,
            ),
          )
          .timeout(tiempoMaximo);
      if (respuesta.statusCode != 200) {
        throw const ErrorApp(
          'NASA POWER no respondió bien. Elige una ciudad de la lista.',
        );
      }
      return (
        hsp: hspDesdeRespuestaNasa(respuesta.body),
        // Sin altitud, la temperatura no se corrige.
        clima: climaDesdeRespuestaNasa(respuesta.body, altitudLugar: altitud),
        altitudM: altitud,
      );
    } on ErrorApp {
      rethrow;
    } on TimeoutException {
      throw const ErrorApp(
        'NASA POWER tardó demasiado. Intenta de nuevo o elige una ciudad.',
      );
    } catch (_) {
      throw const ErrorApp(
        'No se pudo consultar NASA POWER. Revisa tu conexión o elige una ciudad.',
      );
    }
  }

  /// Altitud de Open-Meteo; `null` si falla: no impide el cálculo, solo
  /// deja la temperatura sin corregir y el aviso de subsistencia.
  Future<double?> _altitudPorCoordenadas(Position p) async {
    try {
      final respuesta = await _cliente
          .get(uriElevacion(latitud: p.latitude, longitud: p.longitude))
          .timeout(const Duration(seconds: 15));
      return respuesta.statusCode == 200
          ? elevacionDesdeRespuesta(respuesta.body)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<Position> _ubicacion() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const ErrorApp('Activa la ubicación del dispositivo.');
    }
    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied ||
        permiso == LocationPermission.deniedForever) {
      throw const ErrorApp(
        'Sin permiso de ubicación. Elige una ciudad de la lista.',
      );
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } catch (_) {
      throw const ErrorApp('No se pudo obtener tu ubicación.');
    }
  }
}
