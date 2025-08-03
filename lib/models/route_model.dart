// ARCHIVO MODIFICADO: lib/models/route_model.dart

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart'; // <-- AÑADE ESTE IMPORT

enum StepType { walk, bus }

class RouteStep {
  final StepType type;
  final String instructions;
  final List<LatLng> path;

  // --- AÑADIMOS LOS NUEVOS CAMPOS ---
  final String? companyName;
  final String? vehicleIdentifier;
  final Color? busColor;

  RouteStep({
    required this.type,
    required this.instructions,
    required this.path,
    this.companyName,
    this.vehicleIdentifier,
    this.busColor,
  });

  // --- AÑADIMOS TODA ESTA LÓGICA DE PARSEO ---
  factory RouteStep.fromJson(Map<String, dynamic> json) {
    // Determina el tipo de paso
    final type = json['type'] == 'WALK' ? StepType.walk : StepType.bus;

    // Decodifica la ruta (path) según el tipo
    List<LatLng> path;
    if (type == StepType.walk) {
      path = PolylinePoints()
          .decodePolyline(json['geometry'])
          .map((p) => LatLng(p.latitude, p.longitude))
          .toList();
    } else {
      path = (json['geometry'] as List).map((p) => LatLng(p[1], p[0])).toList();
    }

    // Parsea la información del bus solo si es un paso de tipo 'bus'
    String? companyName;
    String? vehicleIdentifier;
    Color? busColor;
    if (type == StepType.bus && json.containsKey('route_info')) {
      companyName = json['route_info']['company_name'];
      vehicleIdentifier = json['route_info']['identifier'];
      busColor = _colorFromHex(json['route_info']['color']);
    }

    return RouteStep(
      type: type,
      instructions: json['instructions'],
      path: path,
      companyName: companyName,
      vehicleIdentifier: vehicleIdentifier,
      busColor: busColor,
    );
  }
}

class RouteSolution {
  final double totalWalkingDistance;
  final List<RouteStep> steps;

  RouteSolution({required this.totalWalkingDistance, required this.steps});

  // --- AÑADIMOS UN FACTORY AQUÍ TAMBIÉN PARA SIMPLIFICAR EL SERVICIO ---
  factory RouteSolution.fromJson(Map<String, dynamic> json) {
    var stepsList = (json['steps'] as List)
        .map((stepJson) => RouteStep.fromJson(stepJson))
        .toList();

    return RouteSolution(
      totalWalkingDistance: (json['total_walking_distance'] as num).toDouble(),
      steps: stepsList,
    );
  }
}

// Función helper para convertir Hex a Color
Color _colorFromHex(String hexColor) {
  hexColor = hexColor.toUpperCase().replaceAll("#", "");
  if (hexColor.length == 6) {
    hexColor = "FF" + hexColor;
  }
  return Color(int.parse(hexColor, radix: 16));
}
