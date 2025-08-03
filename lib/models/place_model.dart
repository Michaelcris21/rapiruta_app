// lib/models/place_model.dart

import 'package:latlong2/latlong.dart';

class Place {
  final String displayName;
  final double lat;
  final double lon;

  Place({required this.displayName, required this.lat, required this.lon});

  LatLng get latLng => LatLng(lat, lon);

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      // El nombre completo y formateado del lugar
      displayName: json['display_name'] ?? 'Nombre no disponible',
      // Nominatim devuelve las coordenadas como Strings, hay que convertirlas
      lat: double.parse(json['lat']),
      lon: double.parse(json['lon']),
    );
  }
}
