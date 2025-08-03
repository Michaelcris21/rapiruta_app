// ARCHIVO MODIFICADO: lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rapiruta_app/providers/auth_provider.dart';
import 'package:rapiruta_app/providers/theme_provider.dart'; // <-- 1. IMPORTA EL THEME PROVIDER
import 'package:rapiruta_app/screens/home_screen.dart';
import 'package:rapiruta_app/screens/login_screen.dart';
import 'package:rapiruta_app/screens/splash_screen.dart';
//import 'package:rapiruta_app/theme/app_theme.dart'; // <-- 2. IMPORTA LOS TEMAS

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'RapiRuta',
            debugShowCheckedModeBanner: false,

            // --- CAMBIO CLAVE: Usamos la nueva propiedad del provider ---
            // Ya no necesitamos 'darkTheme' ni 'themeMode'
            theme: themeProvider.activeTheme,

            home: Consumer<AuthProvider>(
              builder: (ctx, auth, _) {
                if (auth.isLoading) {
                  return const SplashScreen();
                } else if (auth.isAuthenticated) {
                  return const HomeScreen();
                } else {
                  return const LoginScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}
