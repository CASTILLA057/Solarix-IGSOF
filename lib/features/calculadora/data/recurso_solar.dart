import 'dart:async';
import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../../core/errors/error_app.dart';

/// Horas solares pico en la ubicación actual del dispositivo, según la
/// climatología de NASA POWER (promedio anual de radiación global
/// horizontal, `ALLSKY_SFC_SW_DWN`, en kWh/m²/día = HSP).
abstract interface class RecursoSolarService {
  Future<double> hspEnUbicacionActual();
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

Uri uriNasaPower({required double latitud, required double longitud}) =>
    Uri.https('power.larc.nasa.gov', '/api/temporal/climatology/point', {
      'parameters': 'ALLSKY_SFC_SW_DWN',
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
  Future<double> hspEnUbicacionActual() async {
    final posicion = await _ubicacion();
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
      return hspDesdeRespuestaNasa(respuesta.body);
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
