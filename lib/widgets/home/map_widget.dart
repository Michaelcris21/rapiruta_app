import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:rapiruta_app/providers/theme_provider.dart';
import 'package:rapiruta_app/models/route_model.dart';
import 'package:rapiruta_app/utils/map_styles.dart';

class MapWidget extends StatelessWidget {
  final MapController mapController;
  final LatLng currentCenter;
  final RouteSolution? foundSolution;
  final LatLng? originPoint;
  final LatLng? destinationPoint;
  final Function(MapPosition, bool) onPositionChanged;

  const MapWidget({
    super.key,
    required this.mapController,
    required this.currentCenter,
    required this.foundSolution,
    required this.originPoint,
    required this.destinationPoint,
    required this.onPositionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final mapStyle = MapStyles.getMapStyle(themeProvider.themeStyle);

    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: currentCenter,
        initialZoom: 14.0,
        onPositionChanged: onPositionChanged,
      ),
      children: [
        TileLayer(
          urlTemplate: mapStyle.urlTemplate,
          subdomains: mapStyle.subdomains,
          userAgentPackageName: 'com.example.rapiruta_app',
          retinaMode: mapStyle.retinaMode,
        ),
        mapStyle.attributionWidget,
        if (foundSolution != null)
          PolylineLayer(
            polylines: foundSolution!.steps.map((step) {
              return Polyline(
                points: step.path,
                color: step.type == StepType.walk
                    ? Colors.orange.withOpacity(0.9)
                    : step.busColor ?? Colors.blue,
                strokeWidth: step.type == StepType.walk ? 4.0 : 6.0,
                // Usar borderStrokeWidth para simular líneas punteadas
                isDotted: step.type == StepType.walk,
              );
            }).toList(),
          ),
        MarkerLayer(
          markers: [
            if (originPoint != null)
              Marker(
                point: originPoint!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.my_location,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            if (destinationPoint != null)
              Marker(
                point: destinationPoint!,
                width: 40,
                height: 40,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.place, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
