import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/feelin_pay_service.dart';

/// Auth Controller - Controlador simple para autenticación
class AuthController extends ChangeNotifier {
  // Usar FeelinPayService directamente

  UserModel? _currentUser;
  
  // Getter público para acceso desde fuera
  UserModel? get currentUserPublic => _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  UserModel? get currentUser {
    print('🔍 [AUTH CONTROLLER] Accediendo a currentUser: $_currentUser');
    print('🔍 [AUTH CONTROLLER] ID del AuthController: ${this.hashCode}');
    return _currentUser;
  }
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoggedIn => _currentUser != null;
  bool get isVerified => _currentUser?.emailVerificado ?? false;
  bool get isSuperAdmin => _currentUser?.rol == 'super_admin';

  /// Login
  Future<bool> login(String email, String password) async {
    _setLoading(true);
    _clearError();

    try {
      // Simular login exitoso para testing
      // TODO: Reemplazar con llamada real al backend
      await Future.delayed(const Duration(milliseconds: 1000));
      
      // Crear usuario de prueba
      final isSuperAdmin = email.toLowerCase().contains('admin') || 
                          email.toLowerCase().contains('super') ||
                          email == 'admin@test.com' ||
                          email == 'superadmin@test.com';
      
      _currentUser = UserModel(
        id: '1',
        nombre: isSuperAdmin ? 'Super Admin' : 'Usuario Demo',
        telefono: '+51 987654321',
        email: email,
        rolId: isSuperAdmin ? 'super_admin' : 'propietario',
        rol: isSuperAdmin ? 'super_admin' : 'propietario',
        activo: true,
        enPeriodoPrueba: true,
        diasPruebaRestantes: 30,
        emailVerificado: true,
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
      );
      
      print('🔍 [AUTH CONTROLLER] Usuario creado: $_currentUser');
      print('🔍 [AUTH CONTROLLER] Rol: ${_currentUser?.rol}');
      print('🔍 [AUTH CONTROLLER] ¿Es Super Admin?: ${_currentUser?.isSuperAdmin}');
      print('🔍 [AUTH CONTROLLER] ID del AuthController: ${this.hashCode}');
      notifyListeners();
      return true;
      
      // Código original para cuando el backend esté listo:
      /*
      final response = await FeelinPayService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _currentUser = UserModel.fromJson(response['data']['user']);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Error en el login');
        return false;
      }
      */
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register
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
      final response = await FeelinPayService.register(
        nombre: nombre,
        telefono: telefono,
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        _currentUser = UserModel.fromJson(response['data']['user']);
        notifyListeners();
        return true;
      } else {
        _setError(response['message'] ?? 'Error en el registro');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Logout
  Future<void> logout() async {
    _setLoading(true);

    try {
      await FeelinPayService.logout();
    } catch (e) {
      print('Error en logout: $e');
    } finally {
      _currentUser = null;
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Cambiar rol del usuario (solo para testing)
  void changeUserRole(String newRole) {
    if (_currentUser != null) {
      print('🔍 [AUTH CONTROLLER] Cambiando rol de ${_currentUser!.rol} a $newRole');
      _currentUser = _currentUser!.copyWith(
        rol: newRole,
        rolId: newRole,
        nombre: newRole == 'super_admin' ? 'Super Admin' : 'Usuario Demo',
      );
      print('🔍 [AUTH CONTROLLER] Nuevo rol: ${_currentUser!.rol}');
      print('🔍 [AUTH CONTROLLER] ¿Es Super Admin?: ${_currentUser!.isSuperAdmin}');
      notifyListeners();
    }
  }

  /// Send OTP - Método no implementado
  Future<bool> sendOTP(String email, String tipo) async {
    _setLoading(true);
    _clearError();
    _setError('Método no implementado');
    _setLoading(false);
    return false;
  }

  /// Forgot Password - Método no implementado
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();
    _setError('Método no implementado');
    _setLoading(false);
    return false;
  }

  /// Reset Password
  Future<bool> resetPassword({
    required String email,
    required String codigo,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await FeelinPayService.cambiarPasswordConCodigo(
        email,
        codigo,
        newPassword,
      );

      if (response['success'] == true) {
        return true;
      } else {
        _setError(response['message'] ?? 'Error reseteando contraseña');
        return false;
      }
    } catch (e) {
      _setError('Error de conexión: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verify OTP - Método no implementado
  Future<bool> verifyOTP(String email, String codigo, String tipo) async {
    _setLoading(true);
    _clearError();
    _setError('Método no implementado');
    _setLoading(false);
    return false;
  }

  /// Get current user
  Future<void> getCurrentUser() async {
    if (_currentUser != null) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await FeelinPayService.getCurrentUser();

      if (response != null) {
        _currentUser = UserModel.fromJson(response);
        notifyListeners();
      }
    } catch (e) {
      _setError('Error obteniendo usuario: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Verificar estado de autenticación
  Future<void> checkAuthStatus() async {
    _setLoading(true);
    try {
      // Verificar si hay usuario actual
      final user = await FeelinPayService.getCurrentUser();
      if (user != null) {
        _currentUser = UserModel.fromJson(user);
      }
    } catch (e) {
      _setError('Error verificando autenticación: $e');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  /// Verificar OTP después del login
  Future<bool> verifyOTPAfterLogin(String email, String code) async {
    _setLoading(true);
    _clearError();

    try {
      // Método no implementado
      _setError('Método no implementado');
      return false;
    } catch (e) {
      _setError('Error verificando OTP: $e');
      return false;
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
