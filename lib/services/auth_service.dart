import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/app_config.dart';
import '../models/api_response.dart' as api_models;
import '../models/user_model.dart';
import 'api_service.dart';
import 'google_drive_service.dart';
import 'unified_background_service.dart';
import 'payment_notification_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal() {
    _initGoogleSignIn();
  }

  final ApiService _apiService = ApiService();

  // Google Sign In v7 Instance
  late GoogleSignIn _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance;

  // Local state management for currentUser (since v7 is stateless)
  GoogleSignInAccount? _currentUser;
  final StreamController<GoogleSignInAccount?> _currentUserController =
      StreamController<GoogleSignInAccount?>.broadcast();

  // Scopes
  final List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  Future<void> _initGoogleSignIn() async {
    try {
      // Inicialización estándar para GoogleSignIn v7
      _googleSignInInstance = GoogleSignIn(
        serverClientId: AppConfig.serverClientId,
        scopes: _scopes, // Pre-define scopes here
      );

      // Listen to auth events to update local state
      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        _currentUser = account;
        _currentUserController.add(_currentUser);
      });

      // Intentar recuperar usuario previo sin lanzar UI (si es posible)
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Error initializing GoogleSignIn: $e');
    }
  }

  /// Restaura la sesión del backend y de Google si es posible
  Future<bool> loadSession() async {
    try {
      // Read token from secure storage (same place where ApiService saves it)
      final token = await _apiService.getAuthToken();

      if (token != null && token.isNotEmpty) {
        // Intentar restaurar sesión de Google silenciosamente
        try {
          // Usamos signInSilently para evitar prompts visuales.
          final account = await _googleSignIn.signInSilently();

          if (account != null) {
            _currentUser = account;
            _currentUserController.add(account);

            // CRÍTICO: Refrescar y guardar el token para el servicio de fondo
            await _refreshBackgroundToken();
          }
        } catch (e) {
          debugPrint('Silent Google Sign-In failed: $e');
        }
        return true;
      }
    } catch (e) {
      debugPrint('Error loading session: $e');
    }
    return false;
  }

  // Getters
  Stream<GoogleSignInAccount?> get authStateChanges =>
      _currentUserController.stream;
  GoogleSignInAccount? get currentUser => _currentUser;

  // ========================================
  // LOGIN CON GOOGLE
  // ========================================
  Future<api_models.ApiResponse<UserModel>> signInWithGoogle() async {
    debugPrint('🔐 [AUTH SERVICE] Iniciando Google Sign In...');

    try {
      // 1. Autenticar con Google (Identity)
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return api_models.ApiResponse<UserModel>(
          success: false,
          message: 'Inicio de sesión cancelado por el usuario',
          statusCode: 400,
        );
      }

      // 2. Verificar/Solicitar Scopes confirmados (Authorization)
      bool isAuthorized = await _googleSignIn.canAccessScopes(_scopes);

      if (!isAuthorized) {
        debugPrint(
          '🔐 [AUTH SERVICE] Solicitando permisos adicionales (Scopes)...',
        );
        try {
          isAuthorized = await _googleSignIn.requestScopes(_scopes);
        } catch (e) {
          debugPrint('⚠️ Error solicitando scopes: $e');
        }
      }

      if (!isAuthorized) {
        return api_models.ApiResponse<UserModel>(
          success: false,
          message: 'Permisos de Google Drive requeridos',
          statusCode: 403,
        );
      }

      // 2. Obtener tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;
      final String? accessToken = auth.accessToken;
      // Nota: auth.accessToken puede ser null en web/algunas versiones, pero en AuthCode flow usamos authorizationClient.
      // Sin embargo, para background token simple, auth.accessToken suele bastar si requestScopes tuvo éxito.

      // Intentamos obtener token fresco
      String? freshAccessToken = accessToken;
      try {
        final authClient = await getAuthenticatedClient();
        if (authClient != null) {
          freshAccessToken = authClient.credentials.accessToken.data;
        }
      } catch (e) {
        debugPrint(
          'Debug: No se pudo refrescar token via authClient, usando el de auth object',
        );
      }

      if (idToken == null) {
        return api_models.ApiResponse<UserModel>(
          success: false,
          message: 'No se pudo obtener el ID Token de Google',
          statusCode: 401,
        );
      }

      // 3. Setup de carpeta de Drive
      String? driveFolderId;
      try {
        final authClient = await getAuthenticatedClient();
        if (authClient != null) {
          final driveService = GoogleDriveService();
          driveFolderId = await driveService.setupReportFolder(authClient);
          debugPrint('✅ [AUTH SERVICE] Folder ID automático: $driveFolderId');
        } else {
          debugPrint(
            '⚠️ [AUTH SERVICE] No se pudo obtener cliente autenticado para Drive',
          );
        }
      } catch (e) {
        debugPrint('⚠️ [AUTH SERVICE] Error configurando Drive: $e');
      }

      // 4. Enviar ID Token al backend para autenticación
      debugPrint('🔐 [AUTH SERVICE] Enviando ID Token al backend...');
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/google',
        data: {'token': idToken, 'googleDriveFolderId': driveFolderId},
        requireAuth: false,
      );

      if (response.isSuccess && response.data != null) {
        debugPrint('✅ [AUTH SERVICE] Login con Google exitoso en el backend.');
        final String? token = response.data!['token'];
        String? userId;

        if (token != null) {
          _apiService.setAuthToken(token);
          if (response.data!.containsKey('id')) {
            userId = response.data!['id'].toString();
          } else if (response.data!['user'] != null &&
              response.data!['user']['id'] != null) {
            userId = response.data!['user']['id'].toString();
          }

          if (userId != null) {
            await _saveAuthDataToPrefs(token, userId);
          }
        }

        if (freshAccessToken != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('bg_google_token', freshAccessToken);
          } catch (e) {
            debugPrint('⚠️ Error cacheando token post-login: $e');
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
      String errorMessage = error.toString();
      return api_models.ApiResponse<UserModel>(
        success: false,
        message: 'Error iniciando sesión con Google: $errorMessage',
        statusCode: 500,
      );
    }
  }

  Future<api_models.ApiResponse<UserModel>> getProfile() async {
    final response = await _apiService.get<Map<String, dynamic>>('/auth/me');

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

  bool get isAuthenticated => _apiService.isAuthenticated;
  String? get currentToken => _apiService.authToken;

  Future<void> logout() async {
    try {
      await UnifiedBackgroundService.stop();
      await PaymentNotificationService.stopListening();
      debugPrint('🛑 Servicio de fondo detenido al cerrar sesión');
    } catch (e) {
      debugPrint('⚠️ Error al detener servicio en logout: $e');
    }

    await _googleSignIn.signOut();
    await _apiService.logout();
  }

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

  Future<void> _saveAuthDataToPrefs(String token, String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_auth_token', token);
      await prefs.setString('bg_user_id', userId);
    } catch (e) {
      debugPrint('Error saving auth data to prefs: $e');
    }
  }

  // Helper to expose authenticated client
  Future<auth.AuthClient?> getAuthenticatedClient() async {
    try {
      // For v7, standard headers approach works if signed in
      final headers = await _googleSignIn.currentUser?.authHeaders;
      if (headers == null) return null;

      final client = http.Client();
      return auth.authenticatedClient(
        client,
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            headers['Authorization']!.split(' ').last,
            DateTime.now().add(const Duration(hours: 1)).toUtc(),
          ),
          null, // refreshToken
          _scopes,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ Error creando cliente autenticado: $e');
      return null;
    }
  }

  Future<String?> getGoogleAccessToken() async {
    try {
      GoogleSignInAccount? user = _currentUser;
      user ??= await _googleSignIn.signInSilently();

      if (user != null) {
        final authClient = await getAuthenticatedClient();
        if (authClient != null) {
          return authClient.credentials.accessToken.data;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error obteniendo Google Access Token: $e');
    }
    return null;
  }

  // Guardar token para el Background Service
  Future<void> _refreshBackgroundToken() async {
    try {
      final authClient = await getAuthenticatedClient();
      if (authClient != null) {
        final credentials = authClient.credentials;
        final accessToken = credentials.accessToken.data;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bg_google_token', accessToken);
        debugPrint('✅ Token de Google refrescado y guardado para background');
      }
    } catch (e) {
      debugPrint('⚠️ Error refrescando background token: $e');
    }
  }
}
