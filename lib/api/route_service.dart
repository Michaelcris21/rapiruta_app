// ARCHIVO MODIFICADO: lib/api/route_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rapiruta_app/models/route_model.dart';
import 'package:latlong2/latlong.dart';

class RouteService {
  // static const String _localNetworkIp = '192.168.18.19';
  // static final String _baseUrl = 'http://$_localNetworkIp:8000';

  static const String _baseUrl = 'https://d37e7dc70da1.ngrok-free.app';

  Future<RouteSolution?> findRoute(LatLng origin, LatLng destination) async {
    final url = Uri.parse('$_baseUrl/routes/find-solution');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'origin_lat': origin.latitude,
          'origin_lon': origin.longitude,
          'dest_lat': destination.latitude,
          'dest_lon': destination.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        // --- TODA LA LÓGICA COMPLEJA SE REEMPLAZA CON ESTA LÍNEA ---
        return RouteSolution.fromJson(data);
      } else {
        print('Error en findSolution: ${response.statusCode}');
        // Aquí podrías parsear un mensaje de error del backend si lo hubiera
        return null;
      }
    } catch (e) {
      print('Error de conexión en findSolution: $e');
      return null;
    }
  }
}
