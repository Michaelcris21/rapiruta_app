// NUEVO ARCHIVO: lib/theme/app_theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Tema Claro (básicamente tu diseño actual)
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.blue,
    scaffoldBackgroundColor:
        Colors.grey[200], // Fondo ligeramente gris para el mapa
    cardColor: Colors.white.withOpacity(0.95), // Color para paneles y botones
    iconTheme: const IconThemeData(color: Colors.black87),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
    ),
    // Define colores específicos que puedas necesitar
    colorScheme: const ColorScheme.light(
      primary: Colors.blue,
      secondary: Colors.green,
      surface: Colors.white, // Color de superficie para paneles
      onSurface: Colors.black87, // Color de texto sobre las superficies
    ),
  );

  // Tema Oscuro
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: Colors.grey[900],
    cardColor: Colors.grey[850]!.withOpacity(
      0.95,
    ), // Paneles ligeramente más claros que el fondo
    iconTheme: const IconThemeData(color: Colors.white70),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white70),
      bodyMedium: TextStyle(color: Colors.white70),
    ),
    // Define los colores correspondientes para el modo oscuro
    colorScheme: ColorScheme.dark(
      primary: Colors.teal,
      secondary: Colors.lightGreen,
      surface: Colors.grey[850]!,
      onSurface: Colors.white70,
    ),
  );
}
