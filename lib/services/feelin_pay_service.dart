import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../database/local_database.dart';
import '../core/config/app_config.dart';
// StringUtils removed - using built-in string methods

/// Servicio principal de Feelin Pay que integra todas las funcionalidades
class FeelinPayService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // Headers comunes
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Obtener token de autenticación
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Headers con autenticación
  static Future<Map<String, String>> get _authHeaders async {
    final token = await _getToken();
    return {..._headers, if (token != null) 'Authorization': 'Bearer $token'};
  }

  // Obtener datos del usuario actual
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    return userData != null ? jsonDecode(userData) : null;
  }

  // Verificar OTP de registro
  static Future<Map<String, dynamic>> verifyRegistrationOTP(
    String email,
    String codigo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-registration-otp'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'codigo': codigo,
          'tipo': 'EMAIL_VERIFICATION',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error verificando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Verificar OTP genérico (login, password recovery, etc.)
  static Future<Map<String, dynamic>> verifyOTP(
    String email,
    String codigo,
    String tipo,
  ) async {
    try {
      print('🌐 [SERVICE] Verificando OTP - URL: $baseUrl/auth/verify-otp');
      print('🌐 [SERVICE] Datos: email=$email, codigo=$codigo, tipo=$tipo');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'codigo': codigo,
          'tipo': tipo,
        }),
      );

      print('🌐 [SERVICE] Status Code: ${response.statusCode}');
      print('🌐 [SERVICE] Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [SERVICE] OTP verificado exitosamente');
        return {'success': true, 'message': data['message']};
      } else {
        final data = jsonDecode(response.body);
        print('❌ [SERVICE] Error verificando OTP: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Error verificando código',
        };
      }
    } catch (e) {
      print('❌ [SERVICE] Error de conexión: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Solicitar recuperación de contraseña
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error enviando email',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Verificar OTP de login
  static Future<Map<String, dynamic>> verifyLoginOTP(
    String email,
    String codigo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-login-otp'),
        headers: _headers,
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'codigo': codigo,
          'tipo': 'LOGIN_VERIFICATION',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // Guardar token y datos del usuario
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, data['data']['token']);
          await prefs.setString(_userKey, jsonEncode(data['data']['user']));

          return {
            'success': true,
            'message': data['message'],
            'user': data['data']['user'],
            'token': data['data']['token'],
          };
        } else {
          return {
            'success': false,
            'message': data['message'] ?? 'Error verificando código',
          };
        }
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error verificando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Reenviar OTP
  static Future<Map<String, dynamic>> resendOTP(
    String email,
    String tipo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: _headers,
        body: jsonEncode({'email': email.trim().toLowerCase(), 'tipo': tipo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error reenviando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Resetear contraseña
  static Future<Map<String, dynamic>> resetPassword(
    String email,
    String otpCode,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: _headers,
        body: jsonEncode({
          'email': email,
          'otpCode': otpCode,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error al resetear contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener perfil del usuario desde el backend
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {'error': 'Error obteniendo perfil'};
      }
    } catch (e) {
      return {'error': 'Error de conexión: $e'};
    }
  }

  // Verificar si el usuario está logueado
  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // Register
  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String email,
    required String telefono,
    required String password,
    String? codigoPais,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _headers,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'telefono': telefono,
          'password': password,
          'confirmPassword': password, // Confirmar la misma contraseña
          if (codigoPais != null) 'codigoPais': codigoPais,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // Verificar si requiere OTP
        if (data['data']['requiresOTP'] == true) {
          return {
            'success': true,
            'requiresOTP': true,
            'email': data['data']['email'],
            'message': data['message'],
          };
        }

        // Acceder a los datos correctos de la respuesta (solo si no requiere OTP)
        final userData = data['data']['user'];
        final token = data['data']['token'];

        await _saveToken(token);
        await saveUserData(userData);
        return {'success': true, 'user': userData};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['message'] ?? 'Error en el registro',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Guardar datos del usuario
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  // Limpiar datos del usuario
  static Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  /// ===== AUTENTICACIÓN =====

  /// Login híbrido (online/offline)
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('🔐 [FLUTTER] Iniciando login para: $email');
      print('🌐 [FLUTTER] URL: $baseUrl/auth/login');

      // Intentar login online primero
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _headers,
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('📡 [FLUTTER] Respuesta del servidor:');
      print('   Status Code: ${response.statusCode}');
      print('   Headers: ${response.headers}');
      print('   Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ [FLUTTER] Login exitoso, guardando datos...');

        // Verificar si requiere OTP
        if (data['data']['requiresOTP'] == true) {
          return {
            'success': true,
            'requiresOTP': true,
            'email': data['data']['email'],
            'message': data['message'],
          };
        }

        // Acceder a los datos correctos de la respuesta (solo si no requiere OTP)
        final userData = data['data']['user'];
        final token = data['data']['token'];

        // Guardar datos del usuario
        await saveUserData(userData);
        await _saveToken(token);

        // Verificar si el usuario necesita verificación OTP
        final requiresOTP = !(userData['emailVerificado'] ?? false);

        return {
          'success': true,
          'user': userData,
          'token': token,
          'message': 'Login exitoso',
          'online': true,
          'requiresOTP': requiresOTP,
        };
      } else {
        print('❌ [FLUTTER] Error en login, código: ${response.statusCode}');
        print('❌ [FLUTTER] Respuesta: ${response.body}');

        // Manejar errores específicos del backend
        final data = jsonDecode(response.body);
        final errorMessage = data['message'] ?? 'Error al iniciar sesión';

        print('🔍 [FLUTTER] Error message del backend: $errorMessage');
        print('🔍 [FLUTTER] Status code: ${response.statusCode}');

        // Si es error de credenciales, no intentar offline
        if (response.statusCode == 401 || response.statusCode == 400) {
          print(
            '🔍 [FLUTTER] Devolviendo error de credenciales: $errorMessage',
          );
          return {'success': false, 'error': errorMessage};
        }

        print('🔍 [FLUTTER] Intentando login offline...');
        // Solo intentar offline si es error de servidor o conexión
        return await _loginOffline(email, password);
      }
    } catch (e) {
      print('❌ [FLUTTER] Error de conexión: $e');
      // Si no hay internet, intentar offline
      return await _loginOffline(email, password);
    }
  }

  /// Login offline
  static Future<Map<String, dynamic>> _loginOffline(
    String email,
    String password,
  ) async {
    try {
      final user = await LocalDatabase.getUsuarioByEmail(email);

      if (user == null) {
        return {'success': false, 'error': 'Usuario no encontrado'};
      }

      // Verificar contraseña (simplificado para offline)
      if (user['password'] != password) {
        return {'success': false, 'error': 'Contraseña incorrecta'};
      }

      // Generar token offline (simplificado)
      final token = 'offline_${DateTime.now().millisecondsSinceEpoch}';
      await _saveToken(token);

      return {
        'success': true,
        'user': user,
        'token': token,
        'message': 'Login offline exitoso',
        'offline': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error en login offline: $e'};
    }
  }

  /// Guardar token
  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      await clearUserData();
      return {'success': true, 'message': 'Logout exitoso'};
    } catch (e) {
      return {'success': false, 'error': 'Error al hacer logout: $e'};
    }
  }

  /// ===== GESTIÓN DE EMPLEADOS =====

  /// Crear empleado
  static Future<Map<String, dynamic>> crearEmpleado({
    required String propietarioId,
    required String nombre,
    required String telefono,
    String? canal,
  }) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/empleados'),
        headers: headers,
        body: jsonEncode({
          'propietarioId': propietarioId,
          'nombre': nombre,
          'telefono': telefono,
          'canal': canal ?? 'sms',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar empleado localmente
        await LocalDatabase.createEmpleado({
          'propietarioId': propietarioId,
          'nombre': nombre,
          'telefono': telefono,
          'canal': canal ?? 'sms',
          'activo': true,
        });

        return {
          'success': true,
          'empleado': data['empleado'],
          'message': 'Empleado creado exitosamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al crear empleado',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Obtener empleados del propietario
  static Future<Map<String, dynamic>> obtenerEmpleados(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/empleados/propietario/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'empleados': data['empleados'],
          'total': data['total'],
        };
      } else {
        // Si falla online, obtener offline
        return await _obtenerEmpleadosOffline(propietarioId);
      }
    } catch (e) {
      // Si no hay internet, obtener offline
      return await _obtenerEmpleadosOffline(propietarioId);
    }
  }

  /// Obtener empleados offline
  static Future<Map<String, dynamic>> _obtenerEmpleadosOffline(
    String propietarioId,
  ) async {
    try {
      final empleados = await LocalDatabase.getEmpleadosByPropietario(
        propietarioId,
      );
      return {
        'success': true,
        'empleados': empleados,
        'total': empleados.length,
        'offline': true,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error al obtener empleados offline: $e',
      };
    }
  }

  /// ===== PROCESAMIENTO DE PAGOS =====

  /// Procesar pago completo (validar + Google Sheets + SMS)
  static Future<Map<String, dynamic>> procesarPagoCompleto({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
    required DateTime fechaPago,
    String? telefonoPagador,
    bool notificarEmpleados = true,
  }) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/pago-integrado/procesar-pago'),
        headers: headers,
        body: jsonEncode({
          'propietarioId': propietarioId,
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
          'fechaPago': fechaPago.toIso8601String(),
          'telefonoPagador': telefonoPagador,
          'notificarEmpleados': notificarEmpleados,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar pago localmente para respaldo
        await _guardarPagoLocalmente({
          'propietarioId': propietarioId,
          'clienteNombre': nombrePagador,
          'monto': monto,
          'fecha': fechaPago.toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
          'notificadoEmpleados': data['data']['sms']['enviados'] > 0,
          'registradoEnSheets': data['data']['googleSheets']['registrado'],
          'sincronizado': true,
        });

        return {
          'success': true,
          'data': data['data'],
          'message': 'Pago procesado exitosamente',
          'online': true,
        };
      } else {
        // Si falla online, procesar offline
        return await _procesarPagoOffline(
          propietarioId: propietarioId,
          nombrePagador: nombrePagador,
          monto: monto,
          codigoSeguridad: codigoSeguridad,
          fechaPago: fechaPago,
          telefonoPagador: telefonoPagador,
        );
      }
    } catch (e) {
      // Si no hay internet, procesar offline
      return await _procesarPagoOffline(
        propietarioId: propietarioId,
        nombrePagador: nombrePagador,
        monto: monto,
        codigoSeguridad: codigoSeguridad,
        fechaPago: fechaPago,
        telefonoPagador: telefonoPagador,
      );
    }
  }

  /// Procesar pago offline
  static Future<Map<String, dynamic>> _procesarPagoOffline({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
    required DateTime fechaPago,
    String? telefonoPagador,
  }) async {
    try {
      // Guardar pago localmente
      await _guardarPagoLocalmente({
        'propietarioId': propietarioId,
        'clienteNombre': nombrePagador,
        'monto': monto,
        'fecha': fechaPago.toIso8601String(),
        'codigoSeguridad': codigoSeguridad,
        'telefonoPagador': telefonoPagador,
        'notificadoEmpleados': false,
        'registradoEnSheets': false,
        'sincronizado': false,
      });

      return {
        'success': true,
        'message':
            'Pago guardado localmente. Se sincronizará cuando haya internet.',
        'offline': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error al guardar pago offline: $e'};
    }
  }

  /// Guardar pago localmente
  static Future<void> _guardarPagoLocalmente(
    Map<String, dynamic> pagoData,
  ) async {
    try {
      await LocalDatabase.createPago(pagoData);
    } catch (e) {
      print('Error al guardar pago localmente: $e');
    }
  }

  /// ===== GOOGLE SHEETS =====

  /// Obtener enlace de compartir para empleados
  static Future<Map<String, dynamic>> obtenerEnlaceCompartir(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/pago-integrado/enlace-compartir/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
          'message': 'Enlace obtenido exitosamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al obtener enlace',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== ESTADÍSTICAS =====

  /// Obtener estadísticas del propietario
  static Future<Map<String, dynamic>> obtenerEstadisticas(
    String propietarioId,
  ) async {
    try {
      // Intentar obtener online primero
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/pago-integrado/verificar-saldo-sms/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'saldoDisponible': data['saldoDisponible'],
          'empleadosActivos': data['empleadosActivos'],
          'online': true,
        };
      }
    } catch (e) {
      // Si falla online, obtener offline
    }

    // Obtener estadísticas offline
    try {
      final estadisticas = await LocalDatabase.getEstadisticasPagos(
        propietarioId,
      );
      return {'success': true, 'estadisticas': estadisticas, 'offline': true};
    } catch (e) {
      return {'success': false, 'error': 'Error al obtener estadísticas: $e'};
    }
  }

  /// ===== SINCRONIZACIÓN =====

  /// Sincronizar pagos pendientes
  static Future<Map<String, dynamic>> sincronizarPagosPendientes(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/pago-integrado/sincronizar/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'sincronizados': data['sincronizados'],
          'message': data['message'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al sincronizar',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== BOTÓN DE PRUEBAS =====

  /// Procesar pago de prueba (sin Yape real)
  static Future<Map<String, dynamic>> procesarPagoPrueba({
    required String propietarioId,
    String nombrePagador = 'Cliente de Prueba',
    double monto = 25.50,
    String codigoSeguridad = 'TEST123',
    String telefonoPagador = '+51987654321',
  }) async {
    try {
      final headers = await _authHeaders;

      final response = await http.post(
        Uri.parse('$baseUrl/test/procesar-pago-prueba/$propietarioId'),
        headers: headers,
        body: jsonEncode({
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Guardar pago localmente para respaldo
        await _guardarPagoLocalmente({
          'propietarioId': propietarioId,
          'clienteNombre': nombrePagador,
          'monto': monto,
          'fecha': DateTime.now().toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
          'notificadoEmpleados': data['data']['sms']['enviados'] > 0,
          'registradoEnSheets': data['data']['googleSheets']['registrado'],
          'sincronizado': true,
        });

        return {
          'success': true,
          'data': data['data'],
          'message': 'Pago de prueba procesado exitosamente',
          'esPrueba': true,
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al procesar pago de prueba',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Verificar si se puede usar el botón de prueba
  static Future<Map<String, dynamic>> verificarBotonPrueba(
    String propietarioId,
  ) async {
    try {
      final headers = await _authHeaders;

      final response = await http.get(
        Uri.parse('$baseUrl/test/verificar-boton-prueba/$propietarioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'puedeUsar': data['puedeUsar'],
          'ilimitado': data['ilimitado'] ?? false,
          'razon': data['razon'],
          'fechaUso': data['fechaUso'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al verificar botón de prueba',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== ACCESO DE EMPLEADOS =====

  /// Obtener enlace de Google Sheets para empleados (público)
  static Future<Map<String, dynamic>> obtenerEnlaceGoogleSheetsEmpleados(
    String propietarioId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/empleado-access/google-sheets/$propietarioId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'url': data['url'],
          'accessType': data['accessType'],
          'description': data['description'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al obtener enlace',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Verificar acceso de empleado
  static Future<Map<String, dynamic>> verificarAccesoEmpleado(
    String empleadoId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/empleado-access/verificar/$empleadoId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'acceso': data['acceso'],
          'empleado': data['empleado'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error al verificar acceso',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ==================== MÉTODOS OTP ====================

  /// Verificar código OTP
  static Future<Map<String, dynamic>> verificarCodigoOTP(
    String userId,
    String codigo,
  ) async {
    try {
      final headers = await _authHeaders;
      final response = await http.post(
        Uri.parse('$baseUrl/otp/verificar-codigo'),
        headers: headers,
        body: jsonEncode({'usuarioId': userId, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código verificado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message': error['error'] ?? 'Error verificando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Reenviar código OTP
  static Future<Map<String, dynamic>> reenviarCodigoOTP(String email) async {
    try {
      // Limpiar email antes de enviar
      final emailLimpio = email.trim().toLowerCase();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-otp'),
        headers: _headers,
        body: jsonEncode({'email': emailLimpio, 'tipo': 'EMAIL_VERIFICATION'}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código reenviado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Error reenviando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Solicitar recuperación de contraseña
  static Future<Map<String, dynamic>> solicitarRecuperacionPassword(
    String email,
  ) async {
    try {
      // Limpiar email antes de enviar
      final emailLimpio = email.trim().toLowerCase();

      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: _headers,
        body: jsonEncode({'email': emailLimpio}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Código de recuperación enviado',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'message':
              error['message'] ?? error['error'] ?? 'Error enviando código',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  /// Cambiar contraseña con código OTP
  static Future<Map<String, dynamic>> cambiarPasswordConCodigo(
    String email,
    String codigo,
    String nuevaPassword,
  ) async {
    try {
      print('🔍 [FeelinPayService] Iniciando cambiarPasswordConCodigo');
      print('🔍 [FeelinPayService] Email: $email');
      print('🔍 [FeelinPayService] Código: $codigo');
      print('🔍 [FeelinPayService] URL: $baseUrl/auth/reset-password');

      final requestBody = {
        'email': email.trim().toLowerCase(),
        'codigo': codigo,
        'newPassword': nuevaPassword,
        'confirmPassword': nuevaPassword,
      };

      print('🔍 [FeelinPayService] Request body: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: _headers,
        body: jsonEncode(requestBody),
      );

      print('🔍 [FeelinPayService] Response status: ${response.statusCode}');
      print('🔍 [FeelinPayService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña cambiada correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error':
              error['error'] ??
              error['message'] ??
              'Error cambiando contraseña',
        };
      }
    } catch (e) {
      print('🔍 [FeelinPayService] Error en cambiarPasswordConCodigo: $e');
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Gestión de usuarios
  static Future<Map<String, dynamic>> obtenerUsuarios({
    String busqueda = '',
    String rol = '',
    String activo = 'true',
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'busqueda': busqueda,
        'rol': rol,
        'activo': activo,
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/admin/usuarios',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'usuarios': data['usuarios'],
          'paginacion': data['paginacion'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo usuarios',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> crearUsuario(
    String nombre,
    String email,
    String telefono,
    String password,
    String rol,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/usuarios'),
        headers: await _authHeaders,
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'telefono': telefono,
          'password': password,
          'rol': rol,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario creado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error creando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> eliminarUsuario(String usuarioId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/usuarios/$usuarioId'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario eliminado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error eliminando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> reactivarUsuario(String usuarioId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/usuarios/$usuarioId/reactivar'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Usuario reactivado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error reactivando usuario',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Google Sheets
  static Future<Map<String, dynamic>> obtenerConfiguracionSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reportes/sheets-config'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'configuracion': data['configuracion']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo configuración',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> abrirGoogleSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reportes/abrir-sheets'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'url': data['url']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error abriendo Google Sheets',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> compartirGoogleSheets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/reportes/compartir-sheets'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'url': data['url']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo enlace de compartir',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Llenar Google Sheets con datos de prueba
  static Future<Map<String, dynamic>> llenarDatosPrueba() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reportes/llenar-datos-prueba'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error llenando datos de prueba',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Crear estructura de Google Sheets
  static Future<Map<String, dynamic>> crearEstructuraSheets() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reportes/crear-estructura'),
        headers: await _authHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error creando estructura',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Llenar Google Sheets automáticamente con pago de prueba
  static Future<Map<String, dynamic>> llenarAutomaticamente({
    required String pagador,
    required double monto,
    required String codigoSeguridad,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/reportes/llenar-automatico'),
        headers: await _authHeaders,
        body: jsonEncode({
          'pagador': pagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message']};
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error llenando automáticamente',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // ========== MÉTODOS DE CONFIGURACIÓN DE PERFIL ==========

  // Actualizar nombre del usuario
  static Future<Map<String, dynamic>> actualizarNombre(String nombre) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/profile/name'),
        headers: await _authHeaders,
        body: jsonEncode({'nombre': nombre}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Nombre actualizado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error actualizando nombre',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Actualizar teléfono del usuario
  static Future<Map<String, dynamic>> actualizarTelefono(
    String telefono,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/profile/phone'),
        headers: await _authHeaders,
        body: jsonEncode({'telefono': telefono}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Teléfono actualizado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error actualizando teléfono',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Cambiar contraseña del usuario
  static Future<Map<String, dynamic>> cambiarPassword(
    String passwordActual,
    String passwordNueva,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profile/profile/password'),
        headers: await _authHeaders,
        body: jsonEncode({
          'passwordActual': passwordActual,
          'passwordNueva': passwordNueva,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Contraseña actualizada correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error cambiando contraseña',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Solicitar cambio de email
  static Future<Map<String, dynamic>> solicitarCambioEmail(
    String nuevoEmail,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/profile/email/request'),
        headers: await _authHeaders,
        body: jsonEncode({'nuevoEmail': nuevoEmail}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message':
              data['message'] ??
              'Código de verificación enviado al nuevo email',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error solicitando cambio de email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Confirmar cambio de email con OTP
  static Future<Map<String, dynamic>> confirmarCambioEmail(
    String codigo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/profile/profile/email/confirm'),
        headers: await _authHeaders,
        body: jsonEncode({'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'Email actualizado correctamente',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error confirmando cambio de email',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Obtener historial de cambios del perfil
  static Future<Map<String, dynamic>> obtenerHistorialPerfil({
    int pagina = 1,
    int limite = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'pagina': pagina.toString(),
        'limite': limite.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/profile/profile/history',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: await _authHeaders);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'historial': data['historial'],
          'paginacion': data['paginacion'],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Error obteniendo historial',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
