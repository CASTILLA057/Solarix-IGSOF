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
  Future<({double hsp, ClimaLugar? clima})> recursoEnUbicacionActual();
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
  Future<({double hsp, ClimaLugar? clima})> recursoEnUbicacionActual() async {
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
      return (
        hsp: hspDesdeRespuestaNasa(respuesta.body),
        // El GPS da 0 cuando no conoce la altitud: entonces no se corrige.
        clima: climaDesdeRespuestaNasa(
          respuesta.body,
          altitudLugar: posicion.altitude > 0 ? posicion.altitude : null,
        ),
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
