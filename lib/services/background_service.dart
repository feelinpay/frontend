import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../database/local_database.dart';
import '../services/session_service.dart';

class BackgroundService {
  static Timer? _connectivityTimer;
  static Timer? _sessionTimer;
  static bool _isRunning = false;

  // Iniciar servicio en segundo plano
  static Future<void> start() async {
    if (_isRunning) return;

    _isRunning = true;
    debugPrint('🔄 Iniciando servicio en segundo plano');

    // OPTIMIZATION: Removed periodic connectivity check to prevent ANR.
    // We rely on reactive checks during user actions.

    // Mantener sesión activa cada 5 minutos
    _sessionTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _keepSessionAlive();
    });

    // Verificación inicial
    await _checkConnectivity();
    await _keepSessionAlive();
  }

  // Detener servicio en segundo plano
  static Future<void> stop() async {
    _isRunning = false;
    _sessionTimer?.cancel();
    debugPrint('⏹️ Deteniendo servicio en segundo plano');
  }

  // Verificar conectividad
  static Future<void> _checkConnectivity() async {
    try {
      // 1. Check Internet (Google)
      /* 
      // NOTE: Skipping Google check for now as it might be blocked in some emulator envs
      // focusing on backend connectivity which is what matters for the app.
      */

      // 2. Check Backend
      final response = await ApiService()
          .get('/public/health')
          .timeout(const Duration(seconds: 15)); // Extended timeout

      if (response.isSuccess) {
        // Log removed
      }
    } catch (e) {
      // Error silenced
    }
  }

  // Mantener sesión activa
  static Future<void> _keepSessionAlive() async {
    try {
      final hasSession = await SessionService.isLoggedIn();
      if (hasSession) {
        await SessionService.keepSessionAlive();
        // debugPrint('✅ Sesión mantenida activa');
      } else {
        // debugPrint('⚠️ No hay sesión activa');
      }
    } catch (e) {
      // Error silenced
    }
  }

  // Procesar notificaciones pendientes
  static Future<void> processPendingNotifications() async {
    try {
      final notifications = await LocalDatabase.getNotificacionesPendientes();
      if (notifications.isNotEmpty) {
        // debugPrint('📱 Procesando ${notifications.length} notificaciones pendientes');

        for (var notification in notifications) {
          await LocalDatabase.procesarNotificacionYape(
            notification['mensajeOriginal'],
            notification['propietarioId'],
          );
        }
      }
    } catch (e) {
      // Error silenced
    }
  }

  // Procesar SMS pendientes
  static Future<void> processPendingSMS() async {
    try {
      await LocalDatabase.enviarSMSPendientes();
    } catch (e) {
      // Error silenced
    }
  }

  // Verificar si el servicio está corriendo
  static bool get isRunning => _isRunning;

  // Obtener estado del servicio
  static Map<String, dynamic> getServiceStatus() {
    return {
      'isRunning': _isRunning,
      'connectivityTimer': _connectivityTimer?.isActive ?? false,
      'sessionTimer': _sessionTimer?.isActive ?? false,
    };
  }
}
