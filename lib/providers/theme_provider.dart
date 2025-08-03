// ARCHIVO MODIFICADO: lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:rapiruta_app/theme/app_theme.dart'; // Asegúrate de importar tus temas
import 'package:shared_preferences/shared_preferences.dart';

// --- CAMBIO 1: Creamos un enum para los 3 estados ---
enum ThemeStyle { light, dark, satellite }

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'theme_style_preference';

  // --- CAMBIO 2: Usamos nuestro nuevo enum en lugar de ThemeMode ---
  ThemeStyle _themeStyle = ThemeStyle.light;

  ThemeStyle get themeStyle => _themeStyle;

  // --- CAMBIO 3: Devolvemos el ThemeData correcto. Para satélite, usamos el tema oscuro para los botones/paneles ---
  ThemeData get activeTheme {
    if (_themeStyle == ThemeStyle.light) {
      return AppTheme.lightTheme;
    } else {
      // Usamos el tema oscuro para los UI elements tanto en modo oscuro como en satélite
      return AppTheme.darkTheme;
    }
  }

  ThemeProvider() {
    _loadThemeFromPrefs();
  }

  Future<void> _loadThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    // Leemos el índice del enum guardado (0, 1, o 2). Por defecto, 0 (light).
    final int themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeStyle = ThemeStyle.values[themeIndex];
    notifyListeners();
  }

  Future<void> _saveThemeToPrefs(ThemeStyle style) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, style.index);
  }

  // --- CAMBIO 4: Creamos un método para rotar entre los 3 temas ---
  void cycleTheme() {
    if (_themeStyle == ThemeStyle.light) {
      _themeStyle = ThemeStyle.dark;
    } else if (_themeStyle == ThemeStyle.dark) {
      _themeStyle = ThemeStyle.satellite;
    } else {
      _themeStyle = ThemeStyle.light;
    }

    _saveThemeToPrefs(_themeStyle);
    notifyListeners();
  }
}
