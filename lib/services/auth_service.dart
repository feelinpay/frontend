import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart'; // NEW
import '../models/user_model.dart';
import '../models/api_response.dart' as api_models;
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Client ID web para obtener el idToken para el backend
    // Este debe coincidir con el client_id de tipo 3 en google-services.json
    serverClientId:
        '136817731846-smurvc37qgut87sco3k4lv7ggfdi4fcu.apps.googleusercontent.com',
  );

  // ========================================
  // REGISTRO DE USUARIO
  // ========================================

  /// Registrar nuevo usuario
  Future<api_models.ApiResponse<UserModel>> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/register',
      data: {
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'password': password,
        'confirmPassword': confirmPassword,
      },
      requireAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Verificar código OTP de registro
  Future<api_models.ApiResponse<void>> verifyRegistrationOtp({
    required String email,
    required String codigo,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/verify-otp',
      data: {'email': email, 'codigo': codigo, 'tipo': 'EMAIL_VERIFICATION'},
      requireAuth: false,
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // LOGIN CON GOOGLE
  // ========================================

  /// Iniciar sesión con Google
  Future<api_models.ApiResponse<UserModel>> signInWithGoogle() async {
    try {
      // 0. Forzar cierre de sesión previo para permitir selección de cuenta (Debug)
      await _googleSignIn.signOut();

      // 1. Autenticar con Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return api_models.ApiResponse<UserModel>(
          success: false,
          message: 'Inicio de sesión cancelado',
          statusCode: 400,
        );
      }

      // 2. Obtener token de autenticación
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;

      if (idToken == null) {
        return api_models.ApiResponse<UserModel>(
          success: false,
          message: 'No se pudo obtener el token de Google',
          statusCode: 500,
        );
      }

      // 3. Enviar token al backend para autenticación
      // Enviamos múltiples variantes del nombre del campo y datos extra
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          // Tokens
          'idToken': idToken,
          'token': idToken,
          'id_token': idToken,
          'googleToken': idToken,
          'accessToken': accessToken,
          'access_token': accessToken,

          // Información del perfil (por si el backend la necesita)
          'email': account.email,
          'name': account.displayName,
          'photoUrl': account.photoUrl,
          'id': account.id,
        },
        requireAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        // Save token if present
        if (response.data!['token'] != null) {
          final token = response.data!['token'];
          await _apiService.setAuthToken(token);

          String? userId;
          if (response.data!['user'] != null &&
              response.data!['user']['id'] != null) {
            userId = response.data!['user']['id'].toString();
          } else if (response.data!['id'] != null) {
            userId = response.data!['id'].toString();
          }

          if (userId != null) {
            await _saveAuthDataToPrefs(token, userId);
          }
        }

        return api_models.ApiResponse<UserModel>(
          success: true,
          message: 'Login exitoso',
          data: UserModel.fromJson(response.data!['user'] ?? response.data!),
          statusCode: response.statusCode,
        );
      }

      return api_models.ApiResponse<UserModel>(
        success: false,
        message: response.message,
        errors: response.errors,
        statusCode: response.statusCode,
      );
    } catch (error) {
      debugPrint('❌ [AUTH SERVICE] Error detallado Google Sign In: $error');
      if (error is PlatformException) {
        debugPrint('❌ [AUTH SERVICE] PlatformException Code: ${error.code}');
        debugPrint(
          '❌ [AUTH SERVICE] PlatformException Message: ${error.message}',
        );
        debugPrint(
          '❌ [AUTH SERVICE] PlatformException Details: ${error.details}',
        );
      }
      return api_models.ApiResponse<UserModel>(
        success: false,
        message: 'Error iniciando sesión con Google: $error',
        statusCode: 500,
      );
    }
  }

  // ========================================
  // LOGIN Y AUTENTICACIÓN
  // ========================================

  /// Iniciar sesión
  Future<api_models.ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/login',
      data: {'email': email, 'password': password},
      requireAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;

      // Verificar si requiere OTP
      if (data['requiresOTP'] == true) {
        return api_models.ApiResponse<LoginResponse>(
          success: true,
          message: response.message,
          data: LoginResponse(
            requiresOTP: true,
            email: data['email'],
            token: null,
            user: null,
          ),
        );
      }

      // Login exitoso con token
      if (data['token'] != null) {
        await _apiService.setAuthToken(data['token']);

        // Persist for background service
        if (data['user'] != null && data['user']['id'] != null) {
          await _saveAuthDataToPrefs(
            data['token'],
            data['user']['id'].toString(),
          );
        }

        return api_models.ApiResponse<LoginResponse>(
          success: true,
          message: response.message,
          data: LoginResponse(
            requiresOTP: false,
            email: data['email'],
            token: data['token'],
            user: data['user'] != null
                ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
                : null,
          ),
        );
      }
    }

    return api_models.ApiResponse<LoginResponse>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Verificar código OTP de login
  Future<api_models.ApiResponse<LoginResponse>> verifyLoginOtp({
    required String email,
    required String codigo,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/verify-otp',
      data: {'email': email, 'codigo': codigo, 'tipo': 'LOGIN_VERIFICATION'},
      requireAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;

      if (data['token'] != null) {
        await _apiService.setAuthToken(data['token']);

        // Persist for background service
        if (data['user'] != null && data['user']['id'] != null) {
          await _saveAuthDataToPrefs(
            data['token'],
            data['user']['id'].toString(),
          );
        }

        return api_models.ApiResponse<LoginResponse>(
          success: true,
          message: response.message,
          data: LoginResponse(
            requiresOTP: false,
            email: data['email'],
            token: data['token'],
            user: data['user'] != null
                ? UserModel.fromJson(data['user'] as Map<String, dynamic>)
                : null,
          ),
        );
      }
    }

    return api_models.ApiResponse<LoginResponse>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Reenviar código OTP
  Future<api_models.ApiResponse<void>> resendOtp({
    required String email,
    required String tipo, // 'EMAIL_VERIFICATION', 'LOGIN_VERIFICATION'
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/resend-otp',
      data: {'email': email, 'tipo': tipo},
      requireAuth: false,
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ========================================

  /// Solicitar reset de contraseña
  Future<api_models.ApiResponse<void>> forgotPassword({
    required String email,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/forgot-password',
      data: {'email': email},
      requireAuth: false,
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Resetear contraseña
  Future<api_models.ApiResponse<void>> resetPassword({
    required String email,
    required String codigo,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/reset-password',
      data: {
        'email': email,
        'codigo': codigo,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
      requireAuth: false,
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // GESTIÓN DE PERFIL
  // ========================================

  /// Obtener perfil del usuario actual
  Future<api_models.ApiResponse<UserModel>> getProfile() async {
    final response = await _apiService.get<Map<String, dynamic>>('/auth/me');

    if (response.isSuccess && response.data != null) {
      debugPrint('🔍 [AUTH SERVICE] Datos del perfil recibidos del backend:');
      debugPrint('🔍 [AUTH SERVICE] ${response.data}');

      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar perfil completo
  Future<api_models.ApiResponse<UserModel>> updateProfile({
    required String nombre,
    required String telefono,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/auth/profile', // Standardizing to /auth/profile
      data: {'nombre': nombre, 'telefono': telefono},
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Cambiar contraseña
  Future<api_models.ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '/auth/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      },
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Solicitar cambio de email
  Future<api_models.ApiResponse<void>> requestEmailChange({
    required String newEmail,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/owner/profile/email/request',
      data: {'newEmail': newEmail},
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Confirmar cambio de email
  Future<api_models.ApiResponse<void>> confirmEmailChange({
    required String newEmail,
    required String codigo,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/owner/profile/profile/email/confirm',
      data: {'newEmail': newEmail, 'codigo': codigo},
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Verificar cambio de email
  Future<api_models.ApiResponse<void>> verifyEmailChange({
    required String newEmail,
    required String codigo,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/owner/profile/verify-email',
      data: {'newEmail': newEmail, 'codigo': codigo},
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Verificar si está autenticado
  bool get isAuthenticated => _apiService.isAuthenticated;

  /// Obtener token actual
  String? get currentToken => _apiService.authToken;

  /// Cerrar sesión
  Future<void> logout() async {
    await _apiService.logout();
  }

  /// Verificar si el usuario es Super Admin
  Future<bool> isSuperAdmin() async {
    try {
      final profileResponse = await getProfile();
      if (profileResponse.isSuccess && profileResponse.data != null) {
        final user = profileResponse.data!;
        return user.rol == 'super_admin';
      }
    } catch (e) {
      debugPrint('Error checking super admin status: $e');
    }
    return false;
  }

  // Helper to save auth data for Background Service (SharedPreferences)
  Future<void> _saveAuthDataToPrefs(String token, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_auth_token', token);
      await prefs.setString('bg_user_id', userId);
      debugPrint('Auth data saved to SharedPreferences for Background Service');
    } catch (e) {
      debugPrint('Error saving auth data to prefs: $e');
    }
  }
}

// ========================================
// MODELOS DE RESPUESTA
// ========================================

/// Respuesta de login que puede requerir OTP
class LoginResponse {
  final bool requiresOTP;
  final String? email;
  final String? token;
  final UserModel? user;

  LoginResponse({required this.requiresOTP, this.email, this.token, this.user});

  /// Verificar si el login fue exitoso
  bool get isSuccessful => !requiresOTP && token != null;
}
