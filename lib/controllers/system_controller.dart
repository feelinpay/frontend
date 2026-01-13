import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/permission_service.dart';
import '../services/api_service.dart';
import 'dart:io'; // NEW: Para Socket ping

class SystemController extends ChangeNotifier {
  static final SystemController _instance = SystemController._internal();
  factory SystemController() => _instance;
  SystemController._internal();

  bool _hasInternetConnection = false;
  bool _isBackendReachable = false;
  bool _hasSMSPermission = false;
  bool _hasNotificationPermission = false;
  bool _isCheckingPermissions = false;
  bool _isCheckingConnectivity = false;
  String _connectionType = 'Unknown';
  String? _error; // Renamed from _errorMessage

  bool get hasInternetConnection => _hasInternetConnection;
  bool get isBackendReachable => _isBackendReachable;
  bool get hasSMSPermission => _hasSMSPermission;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get isCheckingPermissions => _isCheckingPermissions;
  bool get isCheckingConnectivity => _isCheckingConnectivity;
  String get connectionType => _connectionType;
  String? get error => _error; // Renamed from errorMessage

  /// Forzar estado de conexión (útil cuando una llamada API externa tiene éxito)
  void setConnectivityManual(bool hasConnection) {
    if (_hasInternetConnection != hasConnection) {
      _hasInternetConnection = hasConnection;
      _isBackendReachable = hasConnection;
      if (hasConnection) _error = null;
      notifyListeners();
    }
  }

  // ========================================
  // INICIALIZACIÓN
  // ========================================

  // Verificar conectividad a Internet
  Future<void> checkInternetConnection() async {
    if (_isCheckingConnectivity) return;

    _setCheckingConnectivity(true);
    _clearError();

    try {
      // 1. Verificar si el dispositivo tiene red (WiFi/Datos)
      final connectivityResult = await Connectivity().checkConnectivity();
      bool hasDeviceRed = !connectivityResult.contains(ConnectivityResult.none);
      _connectionType = connectivityResult.isNotEmpty
          ? connectivityResult.first.name
          : 'Unknown';

      // 2. Robust internet check (Secondary check)
      // Attempt Socket ping if OS says no network or as verification
      bool canPing = false;
      try {
        final result = await Socket.connect(
          '8.8.8.8',
          53,
          timeout: const Duration(seconds: 2),
        );
        await result.close();
        canPing = true;
      } catch (_) {
        canPing = false;
      }

      _hasInternetConnection = hasDeviceRed || canPing;

      // 3. Intentar alcanzar el backend
      try {
        final response = await ApiService()
            .get('/public/health')
            .timeout(const Duration(seconds: 4));

        _isBackendReachable = response.isSuccess;

        if (_isBackendReachable) {
          _hasInternetConnection = true;
          _clearError();
        } else {
          if (!_hasInternetConnection) {
            _setError('Sin conexión a Internet');
          } else {
            _setError('Servidor no disponible');
          }
        }
      } catch (e) {
        _isBackendReachable = false;
        if (!_hasInternetConnection) _setError('Sin conexión a Internet');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [CONNECTIVITY] Error: $e');
      _hasInternetConnection = false;
      _isBackendReachable = false;
      notifyListeners();
    } finally {
      _setCheckingConnectivity(false);
    }
  }

  // Verificar y solicitar permisos
  Future<void> checkAndRequestPermissions() async {
    _setCheckingPermissions(true);
    _clearError();

    try {
      final permissions = await PermissionService.requestAllPermissions();

      _hasNotificationPermission =
          permissions[permission_handler.Permission.notification]?.isGranted ??
          false;
      _hasSMSPermission =
          permissions[permission_handler.Permission.sms]?.isGranted ?? false;

      if (!_hasNotificationPermission) {
        _setError('Permisos de notificaciones requeridos');
      } else if (!_hasSMSPermission) {
        _setError('Permisos de SMS requeridos');
      }

      notifyListeners();
    } catch (e) {
      _setError('Error verificando permisos: ${e.toString()}');
      notifyListeners();
    } finally {
      _setCheckingPermissions(false);
    }
  }

  // Verificar si el sistema está listo
  Future<bool> isSystemReady() async {
    try {
      await checkInternetConnection();
      await checkAndRequestPermissions();

      return _hasInternetConnection &&
          _hasNotificationPermission &&
          _hasSMSPermission;
    } catch (e) {
      _setError('Error verificando sistema: ${e.toString()}');
      return false;
    }
  }

  // Obtener información del sistema
  Future<Map<String, dynamic>> getSystemInfo() async {
    try {
      return {
        'connectivity': {
          'hasConnection': _hasInternetConnection,
          'connectionType': _connectionType,
          'responseTime': 'N/A',
          'isStable': _hasInternetConnection,
        },
        'permissions': {
          'notifications': _hasNotificationPermission,
          'sms': _hasSMSPermission,
          'allGranted': await PermissionService.areAllPermissionsGranted(),
        },
        'systemReady': await isSystemReady(),
      };
    } catch (e) {
      return {
        'error': 'Error obteniendo información del sistema: ${e.toString()}',
        'systemReady': false,
      };
    }
  }

  // Escuchar cambios de conectividad
  void startConnectivityListener() {
    // Simple connectivity listener - check periodically (reduced frequency)
    Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (!_isCheckingConnectivity) {
        await checkInternetConnection();
      }
    });
  }

  // Verificar permisos específicos
  Future<bool> checkSpecificPermission(String permission) async {
    try {
      switch (permission) {
        case 'notifications':
          final status = await PermissionService.checkPermission(
            permission_handler.Permission.notification,
          );
          return status == permission_handler.PermissionStatus.granted;
        case 'sms':
          final status = await PermissionService.checkPermission(
            permission_handler.Permission.sms,
          );
          return status == permission_handler.PermissionStatus.granted;
        default:
          return false;
      }
    } catch (e) {
      _setError('Error verificando permiso específico: ${e.toString()}');
      return false;
    }
  }

  // Abrir configuración de la aplicación
  Future<void> openAppSettings() async {
    try {
      await PermissionService.openAppSettings();
    } catch (e) {
      _setError('Error abriendo configuración: ${e.toString()}');
    }
  }

  // Obtener mensaje de estado del sistema
  String getSystemStatusMessage() {
    if (_isCheckingConnectivity || _isCheckingPermissions) {
      return 'Verificando sistema...';
    }

    if (!_hasInternetConnection) {
      return 'Sin conexión a Internet';
    }

    if (!_hasNotificationPermission) {
      return 'Permisos de notificaciones requeridos';
    }

    if (!_hasSMSPermission) {
      return 'Permisos de SMS requeridos';
    }

    return 'Sistema listo';
  }

  // Verificar si hay errores críticos
  bool hasCriticalErrors() {
    return !_hasInternetConnection ||
        !_hasNotificationPermission ||
        !_hasSMSPermission;
  }

  // Reiniciar verificación del sistema
  Future<void> restartSystemCheck() async {
    _clearError();
    await checkInternetConnection();
    await checkAndRequestPermissions();
  }

  void _setCheckingConnectivity(bool checking) {
    _isCheckingConnectivity = checking;
    notifyListeners();
  }

  void _setCheckingPermissions(bool checking) {
    _isCheckingPermissions = checking;
    notifyListeners();
  }

  void _setError(String? message) {
    _error = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
