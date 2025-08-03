// lib/api/search_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rapiruta_app/models/place_model.dart';

class SearchService {
  Future<List<Place>> searchPlaces(String query) async {
    // Si la búsqueda está vacía, devolvemos una lista vacía para no llamar a la API innecesariamente
    if (query.isEmpty) {
      return [];
    }

    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=jsonv2&addressdetails=1&limit=7',
    );

    try {
      final response = await http.get(
        url,
        // ¡IMPORTANTE! La política de Nominatim requiere un User-Agent único.
        // Usa el identificador de tu paquete de la app.
        headers: {'User-Agent': 'com.example.rapiruta_app'},
      );

      if (response.statusCode == 200) {
        // La respuesta es una lista de objetos JSON
        final List data = json.decode(utf8.decode(response.bodyBytes));
        return data.map((json) => Place.fromJson(json)).toList();
      } else {
        throw Exception('Fallo al cargar los lugares');
      }
    } catch (e) {
      print("Error en SearchService: $e");
      // Devolvemos una lista vacía en caso de error de conexión
      return [];
    }
  }
}
