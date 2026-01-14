import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/payment_notification_service.dart';

class AuthController with ChangeNotifier {
  final AuthService _authService = AuthService();

  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null;

  // Getters adicionales para compatibilidad
  bool get isSuperAdmin => _currentUser?.rol == 'super_admin';
  bool get isVerified => _currentUser != null;

  // ========================================
  // INICIALIZACIÓN
  // ========================================

  /// Inicializar el controlador
  Future<void> initialize() async {
    try {
      // Intentar cargar usuario guardado si existe
      final profile = await _authService.getProfile();
      if (profile.success && profile.data != null) {
        _currentUser = profile.data;
      }
    } catch (e) {
      debugPrint('Error inicializando AuthController: $e');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  // ========================================
  // REGISTRO
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

      if (response.success) {
        _setLoading(false);
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error en registro: $e');
      return false;
    }
  }

  // ========================================
  // LOGIN CON GOOGLE
  // ========================================

  /// Iniciar sesión con Google
  Future<bool> loginWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.signInWithGoogle();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        _setLoading(false);
        debugPrint('✅ Login exitoso. Usuario: ${_currentUser?.email}');
        debugPrint(
          '📂 Drive Folder ID: ${_currentUser?.googleDriveFolderId ?? "NO ASIGNADO"}',
        );
        notifyListeners();
        return true;
      } else {
        _setError(response.message);
        return false;
      }
    } catch (e) {
      _setError('Error en Google Sign-In: $e');
      return false;
    }
  }

  // ========================================
  // LOGIN CON EMAIL
  // ========================================

  /// Iniciar sesión con email y contraseña
  Future<bool> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        if (response.data!.requiresOTP) {
          _setLoading(false);
          return false; // Requiere OTP
        } else if (response.data!.token != null &&
            response.data!.user != null) {
          _currentUser = response.data!.user;
          _setLoading(false);
          notifyListeners();
          return true;
        }
      }

      _setError(response.message);
      return false;
    } catch (e) {
      _setError('Error en login: $e');
      return false;
    }
  }

  // ========================================
  // LOGOUT
  // ========================================

  /// Cerrar sesión
  Future<void> logout() async {
    // 1. Detener escucha de pagos (CRÍTICO: Evitar leak de servicio persistente)
    try {
      await PaymentNotificationService.stopListening();
    } catch (e) {
      debugPrint('Error deteniendo servicio en logout: $e');
    }

    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  // ========================================
  // HELPERS PRIVADOS
  // ========================================

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
