import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

/// Auth Controller - Controlador para autenticación con backend real
class AuthController extends ChangeNotifier {
  static final AuthController _instance = AuthController._internal();
  factory AuthController() => _instance;
  AuthController._internal();

  final AuthService _authService = AuthService();
  final ApiService _apiService = ApiService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _requiresOTP = false;
  String? _pendingEmail;
  String? _pendingPassword;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null && _apiService.isAuthenticated;
  bool get isLoggedIn => _currentUser != null;
  bool get isVerified => _currentUser?.emailVerificado ?? false;
  bool get isSuperAdmin => _currentUser?.rol == 'super_admin' || _currentUser?.rolNombre == 'super_admin';
  bool get requiresOTP => _requiresOTP;
  String? get pendingEmail => _pendingEmail;

  /// Inicializar el controlador
  Future<void> initialize() async {
    await _apiService.initialize();
    
    // Verificar si hay un token válido y cargar el usuario
    if (_apiService.isAuthenticated) {
      await _loadCurrentUser();
    }
  }

  /// Cargar usuario actual desde el backend
  Future<void> _loadCurrentUser() async {
    try {
      final response = await _authService.getProfile();
      if (response.isSuccess && response.data != null) {
        print('🔍 [LOAD PROFILE] Perfil cargado del backend');
        print('🔍 [LOAD PROFILE] Email: ${response.data?.email}');
        print('🔍 [LOAD PROFILE] Email verificado: ${response.data?.emailVerificado}');
        print('🔍 [LOAD PROFILE] Email verificado at: ${response.data?.emailVerificadoAt}');
        _currentUser = response.data;
        notifyListeners();
      } else {
        print('🔍 [LOAD PROFILE] Error cargando perfil: ${response.message}');
      }
    } catch (e) {
      print('🔍 [LOAD PROFILE] Excepción cargando perfil: $e');
    }
  }

  /// Solicitar verificación de email
  Future<void> _requestEmailVerification(String email) async {
    try {
      await _authService.resendOtp(
        email: email,
        tipo: 'EMAIL_VERIFICATION',
      );
    } catch (e) {
      print('Error requesting email verification: $e');
    }
  }

  // ========================================
  // REGISTRO DE USUARIO
  // ========================================

  /// Registrar nuevo usuario
  Future<bool> register({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.register(
        nombre: nombre,
        telefono: telefono,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess) {
        _requiresOTP = true;
        _pendingEmail = email;
        _pendingPassword = password; // Guardar contraseña para login posterior
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error durante el registro: ${e.toString()}');
      return false;
    }
  }

  /// Verificar código OTP de registro
  Future<bool> verifyRegistrationOtp({
    required String email,
    required String codigo,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyRegistrationOtp(
        email: email,
        codigo: codigo,
      );

      if (response.isSuccess) {
        // Después de verificar el OTP, hacer login automáticamente
        final loginResponse = await _authService.login(
          email: email,
          password: _pendingPassword ?? '',
        );

        if (loginResponse.isSuccess && loginResponse.data != null && loginResponse.data!.isSuccessful) {
          _currentUser = loginResponse.data!.user;
          _requiresOTP = false;
          _pendingEmail = null;
          _pendingPassword = null;
          // Cargar perfil completo para obtener todos los datos
          await _loadCurrentUser();
          _setLoading(false);
          notifyListeners();
          return true;
        } else {
          _setError('Error al iniciar sesión después de la verificación: ${loginResponse.message}');
          return false;
        }
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error verificando código: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // LOGIN Y AUTENTICACIÓN
  // ========================================

  /// Iniciar sesión
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        
        // Si el backend requiere OTP (usuario no verificado)
        if (data.requiresOTP == true) {
          _requiresOTP = true;
          _pendingEmail = email;
          _setLoading(false);
          notifyListeners();
          return true; // Indica que requiere OTP
        } 
        
        // Si el login es exitoso con token
        else if (data.token != null && data.user != null) {
          // Establecer el usuario y token
          _currentUser = data.user;
          await _apiService.setAuthToken(data.token!);
          
          // Cargar perfil completo para obtener todos los datos
          await _loadCurrentUser();
          
          // Debug: Mostrar estado de verificación
          print('🔍 [LOGIN] Usuario cargado: ${_currentUser?.email}');
          print('🔍 [LOGIN] Email verificado: ${_currentUser?.emailVerificado}');
          print('🔍 [LOGIN] Email verificado at: ${_currentUser?.emailVerificadoAt}');
          
          // Verificar si el email está verificado después de cargar el perfil
          if (_currentUser != null && !_currentUser!.emailVerificado) {
            // Limpiar sesión y solicitar OTP
            await _apiService.logout();
            _currentUser = null;
            await _requestEmailVerification(email);
            _requiresOTP = true;
            _pendingEmail = email;
            _setLoading(false);
            notifyListeners();
            return true; // Indica que requiere OTP
          }
          
          // Si está todo bien, permitir acceso
          _requiresOTP = false;
          _pendingEmail = null;
          _setLoading(false);
          notifyListeners();
          return true;
        }
      }

      _setError(response.message);
      return false;
    } catch (e) {
      _setError('Error durante el login: ${e.toString()}');
      return false;
    }
  }

  /// Verificar código OTP de login
  Future<bool> verifyLoginOtp({
    required String email,
    required String codigo,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyLoginOtp(
        email: email,
        codigo: codigo,
      );

      if (response.isSuccess && response.data != null && response.data!.isSuccessful) {
        // Establecer usuario y token
        _currentUser = response.data!.user;
        await _apiService.setAuthToken(response.data!.token!);
        
        // Cargar perfil completo
        await _loadCurrentUser();
        
        // Marcar como verificado y limpiar estados
        _requiresOTP = false;
        _pendingEmail = null;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error verificando código: ${e.toString()}');
      return false;
    }
  }

  /// Reenviar código OTP
  Future<bool> resendOtp({
    required String email,
    required String tipo,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resendOtp(
        email: email,
        tipo: tipo,
      );

      if (response.isSuccess) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error reenviando código: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // RECUPERACIÓN DE CONTRASEÑA
  // ========================================

  /// Solicitar reset de contraseña
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.forgotPassword(email: email);

      if (response.isSuccess) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error solicitando reset: ${e.toString()}');
      return false;
    }
  }

  /// Resetear contraseña
  Future<bool> resetPassword({
    required String email,
    required String codigo,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.resetPassword(
        email: email,
        codigo: codigo,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error reseteando contraseña: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // GESTIÓN DE PERFIL
  // ========================================

  /// Actualizar perfil
  Future<bool> updateProfile({
    required String nombre,
    required String telefono,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.updateProfile(
        nombre: nombre,
        telefono: telefono,
      );

      if (response.isSuccess && response.data != null) {
        _currentUser = response.data;
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error actualizando perfil: ${e.toString()}');
      return false;
    }
  }

  /// Cambiar contraseña
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );

      if (response.isSuccess) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error cambiando contraseña: ${e.toString()}');
      return false;
    }
  }

  /// Solicitar cambio de email
  Future<bool> requestEmailChange(String newEmail) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.requestEmailChange(newEmail: newEmail);

      if (response.isSuccess) {
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error solicitando cambio de email: ${e.toString()}');
      return false;
    }
  }

  /// Confirmar cambio de email
  Future<bool> confirmEmailChange({
    required String newEmail,
    required String codigo,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.confirmEmailChange(
        newEmail: newEmail,
        codigo: codigo,
      );

      if (response.isSuccess) {
        // Recargar perfil para obtener datos actualizados
        await _loadCurrentUser();
        _setLoading(false);
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error confirmando cambio de email: ${e.toString()}');
      return false;
    }
  }

  // ========================================
  // UTILIDADES
  // ========================================

  /// Cerrar sesión
  Future<void> logout() async {
    _setLoading(true);
    
    try {
      await _authService.logout();
      _currentUser = null;
      _requiresOTP = false;
      _pendingEmail = null;
      _clearError();
    } catch (e) {
      print('Error during logout: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Cambiar rol de usuario (solo para testing)
  void changeUserRole(String newRole) {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        rol: newRole,
        rolNombre: newRole == 'super_admin' ? 'Super Administrador' : 'Propietario',
      );
      notifyListeners();
    }
  }

  /// Limpiar error
  void _clearError() {
    _error = null;
  }

  /// Establecer error
  void _setError(String error) {
    _error = error;
    _setLoading(false);
    notifyListeners();
  }

  /// Establecer estado de carga
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (!loading) {
      notifyListeners();
    }
  }

  /// Refrescar usuario actual
  Future<void> refreshUser() async {
    if (_apiService.isAuthenticated) {
      await _loadCurrentUser();
    }
  }

  /// Verificar si es Super Admin (método público)
  Future<bool> checkIsSuperAdmin() async {
    try {
      return await _authService.isSuperAdmin();
    } catch (e) {
      print('Error checking super admin status: $e');
      return false;
    }
  }
}