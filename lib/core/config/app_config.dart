import 'package:flutter/foundation.dart';

/// Configuración de la aplicación
class AppConfig {
  // Configuración del servidor backend
  static const String apiBaseUrl = 'http://10.0.2.2:3001/api';

  // Configuración de CORS (para desarrollo)
  static const String corsOrigin = 'http://10.0.2.2:3001';

  // Configuración de timeout
  static const Duration requestTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 10);

  // Configuración de reintentos
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // Configuración de validación
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 100;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPhoneLength = 9;
  static const int maxPhoneLength = 15;

  // Configuración de OTP
  static const int otpLength = 6;
  static const Duration otpExpirationMinutes = Duration(minutes: 10);
  static const int maxOtpAttemptsPerDay = 5;
  static const int maxOtpVerificationAttempts = 3;

  // Configuración de membresías
  static const int trialDays = 3;
  static const double monthlyMembershipPrice = 29.90;

  // Configuración de paginación
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Configuración de logs
  static const bool enableDebugLogs = true;
  static const bool enableNetworkLogs = true;

  // Configuración de desarrollo
  static const bool isDevelopment = true;
  static const bool enableCrashReporting = false;

  // URLs de endpoints específicos
  static const String authEndpoint = '/auth';
  static const String userManagementEndpoint = '/user-management';
  static const String systemEndpoint = '/system';
  static const String profileEndpoint = '/profile';
  static const String ownerEndpoint = '/owner';
  static const String superAdminEndpoint = '/super-admin';
  static const String dashboardEndpoint = '/dashboard';
  static const String otpEndpoint = '/otp';
  static const String paymentsEndpoint = '/payments';
  static const String membresiasEndpoint = '/membresias';

  // Headers por defecto
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Configuración de almacenamiento local
  static const String tokenKey = 'auth_token';
  static const String userKey = 'current_user';
  static const String settingsKey = 'app_settings';

  // Configuración de notificaciones
  static const String notificationChannelId = 'feelin_pay_notifications';
  static const String notificationChannelName = 'Feelin Pay Notifications';
  static const String notificationChannelDescription =
      'Notificaciones de Feelin Pay';

  // Configuración de animaciones
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Configuración de UI
  static const double defaultPadding = 16.0;
  static const double defaultMargin = 8.0;
  static const double defaultBorderRadius = 8.0;
  static const double defaultElevation = 2.0;

  // Configuración de validación de email
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phoneRegex = r'^[0-9+\-\s()]+$';
  static const String nameRegex = r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$';
  static const String passwordRegex = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).+$';

  // Configuración de red
  static const Map<String, String> networkHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'FeelinPay-Mobile/1.0.0',
  };

  // Configuración de seguridad
  static const bool enableCertificatePinning = false;
  static const bool enableSSLVerification = true;
  static const bool enableNetworkSecurity = true;

  // Configuración de caché
  static const Duration cacheTimeout = Duration(minutes: 5);
  static const int maxCacheSize = 100; // MB
  static const bool enableCache = true;

  // Configuración de analytics
  static const bool enableAnalytics = false;
  static const bool enableCrashlytics = false;

  // Configuración de testing
  static const bool isTesting = false;
  static const String testApiUrl = 'http://10.0.2.2:3001/api';

  // Métodos de utilidad
  static String getFullUrl(String endpoint) {
    return '$apiBaseUrl$endpoint';
  }

  static Map<String, String> getHeaders({String? token}) {
    final headers = Map<String, String>.from(networkHeaders);
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static bool get isDebugMode => kDebugMode && enableDebugLogs;
  static bool get isProduction => !isDevelopment;
  static bool get isTestMode => isTesting;
}
