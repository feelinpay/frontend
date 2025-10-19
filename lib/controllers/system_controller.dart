import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart'
    as permission_handler;
import 'package:http/http.dart' as http;
import '../services/permission_service.dart';
import '../core/config/app_config.dart';

class SystemController extends ChangeNotifier {
  bool _hasInternetConnection = false;
  bool _hasSMSPermission = false;
  bool _hasNotificationPermission = false;
  bool _isCheckingPermissions = false;
  bool _isCheckingConnectivity = false;
  String _connectionType = 'Unknown';
  String? _errorMessage;

  bool get hasInternetConnection => _hasInternetConnection;
  bool get hasSMSPermission => _hasSMSPermission;
  bool get hasNotificationPermission => _hasNotificationPermission;
  bool get isCheckingPermissions => _isCheckingPermissions;
  bool get isCheckingConnectivity => _isCheckingConnectivity;
  String get connectionType => _connectionType;
  String? get errorMessage => _errorMessage;

  // Verificar conectividad a Internet
  Future<void> checkInternetConnection() async {
    if (_isCheckingConnectivity)
      return; // Evitar múltiples verificaciones simultáneas

    _setCheckingConnectivity(true);
    _clearError();

    try {
      print('🔍 [CONNECTIVITY] Verificando conectividad...');
      // Simple connectivity check - try to reach the backend
      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 3)); // Reducido timeout

      _hasInternetConnection = response.statusCode == 200;
      _connectionType = 'Local Network';
      print(
        '🔍 [CONNECTIVITY] Status: ${response.statusCode}, Connected: $_hasInternetConnection',
      );

      if (!_hasInternetConnection) {
        _setError('Sin conexión a Internet');
      }

      notifyListeners();
    } catch (e) {
      print('⚠️ [CONNECTIVITY] Error: ${e.toString()}');
      _setError('Error verificando conectividad: ${e.toString()}');
      _hasInternetConnection = false;
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

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }
}
