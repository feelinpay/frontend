import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
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

  late GoogleSignIn _googleSignInInstance;
  GoogleSignIn get _googleSignIn => _googleSignInInstance;

  GoogleSignInAccount? _currentUser;
  final StreamController<GoogleSignInAccount?> _currentUserController =
      StreamController<GoogleSignInAccount?>.broadcast();

  // Scopes are requested on initialization in v6
  final List<String> _scopes = [
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  Future<void> _initGoogleSignIn() async {
    try {
      _googleSignInInstance = GoogleSignIn(
        serverClientId: AppConfig.serverClientId,
        scopes: _scopes,
      );

      _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
        _currentUser = account;
        _currentUserController.add(_currentUser);

        if (account != null) {
          _refreshBackgroundToken();
        }
      });

      // v6 supports explicit silent sign-in
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Error initializing GoogleSignIn: $e');
    }
  }

  Future<bool> loadSession() async {
    try {
      final token = await _apiService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        // v6: Silent sign-in ensures user is populated
        try {
          if (_currentUser == null) {
            await _googleSignIn.signInSilently();
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

  Stream<GoogleSignInAccount?> get authStateChanges =>
      _currentUserController.stream;
  GoogleSignInAccount? get currentUser => _currentUser;

  Future<api_models.ApiResponse<UserModel>> signInWithGoogle() async {
    debugPrint(
        '🔐 [AUTH SERVICE] Iniciando Google Sign In (v6 compatibility)...');

    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();

      if (account == null) {
        return api_models.ApiResponse<UserModel>(
          success: false,
          message: 'Inicio de sesión cancelado por el usuario',
          statusCode: 400,
        );
      }

      // v6: Scopes are granted via init/signIn.
      // We assume if signIn succeeded, scopes are granted (or will be prompted).
      // We do NOT use canAccessScopes/requestScopes as they are v7 APIs.

      // 2. Obtener tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      // In v6, auth.accessToken Exists!
      final String? accessToken = auth.accessToken;

      String? freshAccessToken = accessToken;
      try {
        // We can still use the extension for a fresh client if needed
        final authClient = await _googleSignIn.authenticatedClient();
        if (authClient != null) {
          freshAccessToken = authClient.credentials.accessToken.data;
        }
      } catch (e) {
        debugPrint(
            'Debug: Extension client creation failed, using auth object token');
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
        }
      } catch (e) {
        debugPrint('⚠️ [AUTH SERVICE] Error configurando Drive: $e');
      }

      // 4. Enviar ID Token al backend
      debugPrint('🔐 [AUTH SERVICE] Enviando ID Token al backend...');
      final response = await _apiService.post<Map<String, dynamic>>(
        '/auth/google',
        data: {
          'token': idToken,
          'googleDriveFolderId': driveFolderId,
          'accessToken': freshAccessToken ??
              accessToken, // Send Access Token for Backend Drive Ops
        },
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
          await _saveBackgroundToken(freshAccessToken);
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
      return api_models.ApiResponse<UserModel>(
        success: false,
        message: 'Error iniciando sesión con Google: $error',
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

  // ... (Other methods remain largely same or simplified)
  Future<api_models.ApiResponse<UserModel>> updateProfile({
    required String nombre,
    required String telefono,
  }) async {
    // (Implementation same as before)
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
        return profileResponse.data!.rol == 'super_admin';
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

  Future<void> _saveBackgroundToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('bg_google_token', token);
      debugPrint('✅ Token de Google refrescado y guardado para background');
    } catch (e) {
      debugPrint('⚠️ Error cacheando token post-login: $e');
    }
  }

  Future<auth.AuthClient?> getAuthenticatedClient() async {
    try {
      // Use extension method (v2/v3 compatible)
      return await _googleSignIn.authenticatedClient();
    } catch (e) {
      debugPrint('⚠️ Error creando cliente autenticado: $e');
      return null;
    }
  }

  Future<String?> getGoogleAccessToken() async {
    try {
      // v6: we can check currentUser
      if (_currentUser == null) {
        await _googleSignIn.signInSilently();
      }

      if (_currentUser != null) {
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

  Future<void> _refreshBackgroundToken() async {
    try {
      final authClient = await getAuthenticatedClient();
      if (authClient != null) {
        final accessToken = authClient.credentials.accessToken.data;
        await _saveBackgroundToken(accessToken);
      }
    } catch (e) {
      debugPrint('⚠️ Error refrescando background token: $e');
    }
  }
}
