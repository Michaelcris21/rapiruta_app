import 'dart:convert';
import 'package:http/http.dart' as http;
//import 'dart:io' show Platform;

class AuthService {
  // Definimos la URL base de nuestro backend.
  // Usamos una lógica para detectar si estamos en Android o en otro sistema.
  // static const String _localNetworkIp = '192.168.18.19';

  // static final String _baseUrl = 'http://$_localNetworkIp:8000';

  static const String _baseUrl = 'https://9372aaf0d059.ngrok-free.app';

  // Función para hacer login
  // Devuelve el token si es exitoso, o null si falla.
  Future<String?> login(String email, String password) async {
    // Construimos la URL completa del endpoint de login.
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      // Hacemos la petición POST a la API.
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        // Codificamos los datos de email y password a formato JSON.
        body: jsonEncode({'email': email, 'password': password}),
      );

      // Verificamos el código de estado de la respuesta.
      if (response.statusCode == 200) {
        // Si es 200 (OK), decodificamos el cuerpo del JSON.
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Extraemos el token de acceso.
        final String? token = responseData['access_token'];
        print('Login exitoso. Token: $token');
        return token;
      } else {
        // Si el código no es 200, algo salió mal (ej. credenciales inválidas).
        print('Error en el login: ${response.statusCode}');
        print('Cuerpo de la respuesta: ${response.body}');
        return null;
      }
    } catch (e) {
      // Si ocurre un error de conexión (ej. el servidor no está corriendo).
      print('Error de conexión: $e');
      return null;
    }
  }

  // Aquí podríamos añadir en el futuro la función de registro:
  // Future<bool> register(String email, String password, String fullName) async { ... }

  Future<String?> register({
    required String fullName,
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final url = Uri.parse(
      '$_baseUrl/auth/register',
    ); // Construye la URL completa -> /auth/register

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: json.encode({
          'full_name': fullName,
          'usuario': username,
          'email': email,
          'telefono': phone,
          'password': password,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return responseData['access_token'];
      } else {
        print('Error en registro: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Excepción en servicio de registro: $e');
      return null;
    }
  }
}
