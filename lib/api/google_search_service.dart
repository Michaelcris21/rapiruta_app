// lib/api/google_search_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:rapiruta_app/models/place_model.dart'; // Reutilizaremos un modelo similar

class GoogleSearchService {
  // PEGA TU CLAVE DE API AQUÍ
  final String _apiKey = 'AIzaSyAcP4Bd6m_JLyFYB9FU7c9mVz1k5-tCQPY';

  // La búsqueda con Google es un proceso de 2 pasos:
  // 1. Obtener predicciones (autocomplete)
  // 2. Obtener los detalles (coordenadas) de una predicción seleccionada

  // Paso 1: Obtener Predicciones
  Future<List<PlacePrediction>> getAutocomplete(String input) async {
    if (input.isEmpty) return [];

    // 'components=country:pe' limita la búsqueda a Perú. ¡Cámbialo si es necesario!
    // Basado en tus coordenadas de Trujillo, asumo que es Perú.
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$_apiKey&language=es&components=country:pe';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final List predictions = data['predictions'];
          return predictions.map((p) => PlacePrediction.fromJson(p)).toList();
        }
      }
      return [];
    } catch (e) {
      print("Error en getAutocomplete: $e");
      return [];
    }
  }

  // Paso 2: Obtener Detalles del Lugar (incluyendo coordenadas)
  Future<LatLng?> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_apiKey&fields=geometry';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
      return null;
    } catch (e) {
      print("Error en getPlaceDetails: $e");
      return null;
    }
  }
}

// --- NUEVO MODELO PARA LAS PREDICCIONES DE GOOGLE ---
class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'],
      placeId: json['place_id'],
    );
  }
}
