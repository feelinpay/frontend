import '../models/user_model.dart';
import '../models/api_response.dart' as api_models;
import 'api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();

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
      data: {
        'email': email,
        'codigo': codigo,
        'tipo': 'EMAIL_VERIFICATION',
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
  // LOGIN Y AUTENTICACIÓN
  // ========================================

  /// Iniciar sesión
  Future<api_models.ApiResponse<LoginResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/login',
      data: {
        'email': email,
        'password': password,
      },
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
        
        return api_models.ApiResponse<LoginResponse>(
          success: true,
          message: response.message,
          data: LoginResponse(
            requiresOTP: false,
            email: data['email'],
            token: data['token'],
            user: data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null,
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
      data: {
        'email': email,
        'codigo': codigo,
        'tipo': 'LOGIN_VERIFICATION',
      },
      requireAuth: false,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      
      if (data['token'] != null) {
        await _apiService.setAuthToken(data['token']);
        
        return api_models.ApiResponse<LoginResponse>(
          success: true,
          message: response.message,
          data: LoginResponse(
            requiresOTP: false,
            email: data['email'],
            token: data['token'],
            user: data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null,
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
      data: {
        'email': email,
        'tipo': tipo,
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
  // RECUPERACIÓN DE CONTRASEÑA
  // ========================================

  /// Solicitar reset de contraseña
  Future<api_models.ApiResponse<void>> forgotPassword({
    required String email,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '/public/auth/forgot-password',
      data: {
        'email': email,
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
    final response = await _apiService.get<Map<String, dynamic>>(
      '/owner/profile',
    );

    if (response.isSuccess && response.data != null) {
      print('🔍 [AUTH SERVICE] Datos del perfil recibidos del backend:');
      print('🔍 [AUTH SERVICE] ${response.data}');
      
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
      '/owner/profile',
      data: {
        'nombre': nombre,
        'telefono': telefono,
      },
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
      '/owner/profile/password',
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
      '/owner/profile/profile/email/request',
      data: {
        'newEmail': newEmail,
      },
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
      data: {
        'newEmail': newEmail,
        'codigo': codigo,
      },
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
      data: {
        'newEmail': newEmail,
        'codigo': codigo,
      },
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
      print('Error checking super admin status: $e');
    }
    return false;
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

  LoginResponse({
    required this.requiresOTP,
    this.email,
    this.token,
    this.user,
  });

  /// Verificar si el login fue exitoso
  bool get isSuccessful => !requiresOTP && token != null;
}
