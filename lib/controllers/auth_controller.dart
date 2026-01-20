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
      // 1. Restaurar sesión (Backend Token + Google)
      await _authService.loadSession();

      // 2. Intentar cargar perfil de usuario si el token es válido
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

  /// Refrescar token silenciosamente (sin loading UI)
  Future<bool> silentRefreshToken() async {
    try {
      debugPrint('🔄 Refrescando datos del usuario desde el servidor...');

      // En lugar de re-autenticar con Google (que muestra popup),
      // simplemente llamamos a /auth/me para obtener los datos actualizados del usuario
      // El token JWT sigue siendo válido, solo necesitamos refrescar el objeto user
      final response = await _authService.getProfile();

      if (response.success && response.data != null) {
        _currentUser = response.data;
        debugPrint(
          '✅ Datos de usuario refrescados. Rol actual: ${_currentUser?.rol}',
        );
        notifyListeners();
        return true;
      } else {
        debugPrint('⚠️ No se pudo refrescar perfil: ${response.message}');
      }
    } catch (e) {
      debugPrint('⚠️ Error refrescando datos: $e');
    }
    return false;
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
