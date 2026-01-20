import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart'; // Keep this import as it's used by _saveAuthDataToPrefs
import '../core/config/app_config.dart';
import '../models/api_response.dart' as api_models;
import '../models/user_model.dart';
import 'api_service.dart';
import 'google_drive_service.dart'; // Keep this import as it's used by setupReportFolder
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
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

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
      await _googleSignIn.initialize(
        serverClientId: AppConfig.serverClientId,
        // No scopes here in v7
      );

      // Listen to auth events to update local state
      _googleSignIn.authenticationEvents.listen((event) {
        if (event is GoogleSignInAuthenticationEventSignIn) {
          _currentUser = event.user;
          _currentUserController.add(_currentUser);
        } else if (event is GoogleSignInAuthenticationEventSignOut) {
          _currentUser = null;
          _currentUserController.add(null);
        }
      });
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
        // Token is already set in ApiService, no need to call setAuthToken again

        // Intentar restaurar sesión de Google silenciosamente
        // UPDATE: Commented out to prevent intrusive UI prompts on splash screen.
        // User must explicitly click "Continue with Google" to trigger any Google auth flow.
        /*
        try {
          final account = await _googleSignIn
              .attemptLightweightAuthentication();
          if (account != null) {
            _currentUser = account;
            _currentUserController.add(account);
          }
        } catch (e) {
          // Google sign-in failure shouldn't block app start if backend token works
          debugPrint('Silent Google Sign-In failed: $e');
        }
        */
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
      // authenticate() in v7 returns a non-nullable Future<GoogleSignInAccount>
      // and throws an exception if the sign in process is canceled or fails.
      final GoogleSignInAccount account = await _googleSignIn.authenticate();

      // 2. Verificar/Solicitar Scopes (Authorization)
      // En v7, usamos authorizationClient
      // 1.5. Request specific scopes if not granted (v7 incremental authorization)
      // Use authorizationClient to check permissions
      bool isAuthorized =
          await _googleSignIn.authorizationClient.authorizationForScopes(
            _scopes,
          ) !=
          null;

      if (!isAuthorized) {
        debugPrint(
          '🔐 [AUTH SERVICE] Solicitando permisos adicionales (Scopes)...',
        );
        try {
          // authorizeScopes returns the auth object with accessToken
          await _googleSignIn.authorizationClient.authorizeScopes(_scopes);
          isAuthorized = true;
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
      // Identity Token (for backend login)
      // Note: In v7, authentication is a getter, not a Future
      final GoogleSignInAuthentication auth = account.authentication;
      final String? idToken = auth.idToken;

      // Access Token (for Google Drive API)
      String? accessToken;
      try {
        if (isAuthorized) {
          // We already authorized earlier, but we need the token string explicitly
          final authClient = await _googleSignIn.authorizationClient
              .authorizeScopes(_scopes);
          accessToken = authClient.accessToken;
        }
      } catch (e) {
        debugPrint('⚠️ No se pudo obtener AccessToken para Drive: $e');
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

        if (accessToken != null) {
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('bg_google_token', accessToken);
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
      // Fix strict type check for error.message
      String errorMessage = error.toString();
      /* if (error is PlatformException) { // Requires 'flutter/services.dart' which is not imported
         errorMessage = error.message ?? errorMessage;
      } */

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
    // 1. Detener servicio de fondo y notificaciones
    try {
      await UnifiedBackgroundService.stop();
      // Asegurar que el listener nativo también se detenga
      await PaymentNotificationService.stopListening();
      debugPrint('🛑 Servicio de fondo detenido al cerrar sesión');
    } catch (e) {
      debugPrint('⚠️ Error al detener servicio en logout: $e');
    }

    // 2. Cerrar sesión
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

  // Helper to expose authenticated client (Manual implementation for v7 compatibility)
  Future<auth.AuthClient?> getAuthenticatedClient() async {
    try {
      final headers = await _googleSignIn.authorizationClient
          .authorizationHeaders(_scopes);
      if (headers == null) return null;

      final client = http.Client();
      return auth.authenticatedClient(
        client,
        auth.AccessCredentials(
          auth.AccessToken(
            'Bearer',
            headers['Authorization']!.split(' ').last,
            // Expiry is not provided by authorizationHeaders, assume valid for short duration
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
      user ??= await _googleSignIn.attemptLightweightAuthentication();

      if (user != null) {
        // In v7, access token must be retrieved via authorizationClient
        if (await _googleSignIn.authorizationClient.authorizationForScopes(
              _scopes,
            ) !=
            null) {
          final client = await _googleSignIn.authorizationClient
              .authorizeScopes(_scopes);
          return client.accessToken;
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error obteniendo Google Access Token: $e');
    }
    return null;
  }
}
