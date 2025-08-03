import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:rapiruta_app/api/auth_service.dart'; // Asegúrate que la ruta sea correcta

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  bool _isLoading =
      true; // Empezamos en "cargando" mientras verificamos el token guardado

  // Getters para que la UI pueda leer el estado de forma segura
  bool get isAuthenticated => _token != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    // Al iniciar la app, intentamos hacer login automáticamente
    _tryAutoLogin();
  }

  /// Intenta cargar el token desde el almacenamiento seguro para mantener la sesión iniciada.
  Future<void> _tryAutoLogin() async {
    final token = await _storage.read(key: 'token');
    if (token != null && token.isNotEmpty) {
      _token = token;
      print('AuthProvider: Token encontrado, auto-login exitoso.');
    } else {
      print('AuthProvider: No se encontró token, se requiere login manual.');
    }
    // Sea cual sea el resultado, la carga inicial ha terminado.
    _isLoading = false;
    notifyListeners(); // Notificamos a los widgets para que reconstruyan (ej. ir de SplashScreen a Login/Home)
  }

  /// Maneja el inicio de sesión del usuario.
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final token = await _authService.login(email, password);

    if (token != null) {
      _token = token;
      // Guardamos el token para futuras sesiones
      await _storage.write(key: 'token', value: token);
      _isLoading = false;
      notifyListeners();
      return true; // Login exitoso
    } else {
      _isLoading = false;
      notifyListeners();
      return false; // Login fallido
    }
  }

  /// Maneja el registro de un nuevo usuario.
  Future<bool> register({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    // Llama al método register del servicio, que ahora devuelve un token si tiene éxito
    final token = await _authService.register(
      fullName: fullName,
      username: username,
      email: email,
      phone: phone,
      password: password,
    );

    if (token != null) {
      _token = token;
      // Si el registro fue exitoso, también guardamos el token para iniciar sesión
      await _storage.write(key: 'token', value: token);
      _isLoading = false;
      notifyListeners();
      return true; // Registro y login automático exitosos
    } else {
      _isLoading = false;
      notifyListeners();
      return false; // Registro fallido
    }
  }

  /// Cierra la sesión del usuario.
  Future<void> logout() async {
    _token = null;
    // Borramos el token del almacenamiento seguro
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}
