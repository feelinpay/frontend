import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'google_drive_service.dart';
import '../models/user_model.dart';
import '../models/api_response.dart' as api_models;
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId:
        '607923304959-39h6usdv60jhb446qmrsb05v74t335nc.apps.googleusercontent.com',
    scopes: ['email', 'https://www.googleapis.com/auth/drive.file'],
  );

  // ========================================
  // LOGIN CON GOOGLE
  // ========================================

  /// Iniciar sesión con Google
  Future<api_models.ApiResponse<UserModel>> signInWithGoogle() async {
    debugPrint('🔐 [AUTH SERVICE] Iniciando Google Sign In...');

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

      // 3. Setup de carpeta de Drive (Automático y Escalable)
      String? driveFolderId;
      try {
        final driveService = GoogleDriveService(_googleSignIn);
        driveFolderId = await driveService.setupReportFolder();
        debugPrint('✅ [AUTH SERVICE] Folder ID automático: $driveFolderId');
      } catch (e) {
        debugPrint('⚠️ [AUTH SERVICE] Error configurando Drive: $e');
      }

      // 4. Enviar token al backend para autenticación
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
          'refreshToken': account.serverAuthCode, // ✅ Para refresh automático
          // Información del perfil
          'email': account.email,
          'name': account.displayName,
          'photoUrl': account.photoUrl,
          'id': account.id,

          // Carpeta de Drive automática
          'googleDriveFolderId': driveFolderId,
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

        // CACHEAR TOKEN DE GOOGLE EXPLÍCITAMENTE
        try {
          final auth = await account.authentication;
          final gToken = auth.accessToken;
          if (gToken != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('bg_google_token', gToken);
            debugPrint(
              '✅ [AUTH SERVICE] Token de Google cacheado exitosamente tras login.',
            );
          }
        } catch (e) {
          debugPrint('⚠️ Error cacheando token post-login: $e');
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
      '/auth/profile',
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

  /// Recuperar el Access Token de Google actual
  Future<String?> getGoogleAccessToken() async {
    try {
      // Si no hay usuario logueado en la instancia, intentamos signInSilently
      if (_googleSignIn.currentUser == null) {
        await _googleSignIn.signInSilently();
      }

      final user = _googleSignIn.currentUser;
      if (user != null) {
        final auth = await user.authentication;
        final token = auth.accessToken;

        // Cachear token para uso en background / procesos aislados
        if (token != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('bg_google_token', token);
          } catch (e) {
            debugPrint('⚠️ Error cacheando token de Google: $e');
          }
        }

        return token;
      }
    } catch (e) {
      debugPrint('⚠️ Error obteniendo Google Access Token: $e');
    }
    return null;
  }
}
