import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rapiruta_app/providers/theme_provider.dart';

class MapStyles {
  static Future<void> launchUrlHelper(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      throw Exception('No se pudo abrir el enlace');
    }
  }

  static MapStyleConfig getMapStyle(ThemeStyle themeStyle) {
    switch (themeStyle) {
      case ThemeStyle.light:
        return MapStyleConfig(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: [],
          attributionWidget: RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© OpenStreetMap',
                onTap: () =>
                    launchUrlHelper('https://www.openstreetmap.org/copyright'),
              ),
            ],
          ),
          retinaMode: false,
        );
      case ThemeStyle.dark:
        return MapStyleConfig(
          urlTemplate:
              'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png',
          subdomains: ['a', 'b', 'c'],
          attributionWidget: RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                '© CartoDB',
                onTap: () => launchUrlHelper('https://carto.com/attributions'),
              ),
              TextSourceAttribution(
                '© OpenStreetMap',
                onTap: () =>
                    launchUrlHelper('https://www.openstreetmap.org/copyright'),
              ),
            ],
          ),
          retinaMode: true,
        );
      case ThemeStyle.satellite:
        return MapStyleConfig(
          urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
          subdomains: [],
          attributionWidget: RichAttributionWidget(
            attributions: [
              TextSourceAttribution(
                'Esri, i-cubed, USDA, USGS, AEX, GeoEye, Getmapping, Aerogrid, IGN, IGP, UPR-EGP, and the GIS User Community',
              ),
            ],
          ),
          retinaMode: false,
        );
    }
  }
}

class MapStyleConfig {
  final String urlTemplate;
  final List<String> subdomains;
  final Widget attributionWidget;
  final bool retinaMode;

  MapStyleConfig({
    required this.urlTemplate,
    required this.subdomains,
    required this.attributionWidget,
    required this.retinaMode,
  });
}
