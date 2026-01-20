import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/config/app_config.dart';
import '../controllers/system_controller.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Token management
  String? _authToken;
  bool _isInitialized = false;

  /// Inicializar el servicio API
  Future<void> initialize() async {
    if (_isInitialized) return;

    // FORCE OVERRIDE DEBUG REMOVED

    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConfig.connectTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _setupInterceptors();
    await _loadStoredToken();
    _isInitialized = true;
  }

  /// Configurar interceptores para manejo automático de tokens y errores
  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Agregar token de autenticación automáticamente
          // Agregar token de autenticación automáticamente (EXCEPTO para rutas públicas)
          // Check both path and uri to be sure
          final isPublic =
              options.path.contains('/public') ||
              options.uri.toString().contains('/public');

          if (_authToken != null && !isPublic) {
            options.headers['Authorization'] = 'Bearer $_authToken';
          } else {
            // Explicitly remove it if it somehow got there for public routes
            options.headers.remove('Authorization');
          }

          // Log de requests en desarrollo
          if (AppConfig.isDevelopment) {
            debugPrint('🚀 API Request: ${options.method} ${options.path}');
            if (options.data != null) {
              debugPrint('📤 Request Data: ${options.data}');
            }
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log de responses en desarrollo
          if (AppConfig.isDevelopment) {
            debugPrint(
              '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
            );
            if (response.data != null) {
              // OPTIMIZATION: Do not print full data body to avoid main thread freeze
              debugPrint('📥 Response Type: ${response.data.runtimeType}');
            }
          }

          // ACTUALIZAR CONECTIVIDAD: Si recibimos una respuesta, tenemos internet
          SystemController().setConnectivityManual(true);

          handler.next(response);
        },
        onError: (error, handler) async {
          // Log de errores en desarrollo
          if (AppConfig.isDevelopment) {
            debugPrint(
              '❌ API Error: ${error.response?.statusCode ?? error.type} ${error.requestOptions.path}',
            );
            if (error.response?.data != null) {
              String errorData = error.response?.data.toString() ?? '';
              if (errorData.length > 500) {
                errorData = '${errorData.substring(0, 500)}... [TRUNCATED]';
              }
              debugPrint('🔍 Error Data: $errorData');
            } else {
              debugPrint('🔍 Error Message: ${error.message}');
            }
          }

          // Manejar token expirado (401) - DISABLED debugging 403/401 loop
          // if (error.response?.statusCode == 401) {
          //   await _handleTokenExpired();
          // }

          // Manejar errores de red
          if (error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout) {
            error = DioException(
              requestOptions: error.requestOptions,
              error: 'Error de conexión. Verifica tu internet.',
              type: DioExceptionType.connectionTimeout,
            );
          }

          handler.next(error);
        },
      ),
    );
  }

  /// Cargar token almacenado
  Future<void> _loadStoredToken() async {
    try {
      _authToken = await _storage.read(key: 'auth_token');
    } catch (e) {
      debugPrint('Error loading stored token: $e');
    }
  }

  /// Establecer token de autenticación
  Future<void> setAuthToken(String token) async {
    _authToken = token;
    await _storage.write(key: 'auth_token', value: token);
  }

  /// Obtener token actual
  String? get authToken => _authToken;

  /// Verificar si está autenticado
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Logout - limpiar token
  Future<void> logout() async {
    _authToken = null;
    await _storage.delete(key: 'auth_token');
  }

  // ========================================
  // MÉTODOS HTTP PRINCIPALES
  // ========================================

  /// GET Request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth && !isAuthenticated) {
        throw ApiException('No autenticado', 401);
      }

      final response = await _dio.get(path, queryParameters: queryParameters);

      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// POST Request
  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic data,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth && !isAuthenticated) {
        throw ApiException('No autenticado', 401);
      }

      final response = await _dio.post(path, data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// PUT Request
  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic data,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth && !isAuthenticated) {
        throw ApiException('No autenticado', 401);
      }

      final response = await _dio.put(path, data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// PATCH Request
  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic data,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth && !isAuthenticated) {
        throw ApiException('No autenticado', 401);
      }

      final response = await _dio.patch(path, data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  /// DELETE Request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic data,
    bool requireAuth = true,
  }) async {
    try {
      if (requireAuth && !isAuthenticated) {
        throw ApiException('No autenticado', 401);
      }

      final response = await _dio.delete(path, data: data);
      return _handleResponse<T>(response);
    } catch (e) {
      return _handleError<T>(e);
    }
  }

  // ========================================
  // MANEJO DE RESPUESTAS Y ERRORES
  // ========================================

  /// Manejar respuesta exitosa
  ApiResponse<T> _handleResponse<T>(Response response) {
    final data = response.data;

    if (data is Map<String, dynamic>) {
      // Si el backend devuelve un objeto con success, message, data
      if (data.containsKey('success') && data.containsKey('data')) {
        return ApiResponse<T>(
          success: data['success'] ?? true,
          message: data['message'] ?? 'Operación exitosa',
          data: data['data'],
          errors: data['errors'],
        );
      }
      // Si el backend devuelve los datos directamente
      else {
        return ApiResponse<T>(
          success: true,
          message: data['message'] ?? 'Operación exitosa',
          data: data as T?,
          errors: data['errors'],
        );
      }
    }

    return ApiResponse<T>(
      success: true,
      message: 'Operación exitosa',
      data: data,
    );
  }

  /// Manejar errores
  ApiResponse<T> _handleError<T>(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 500;
      final message = _getErrorMessage(error);

      dynamic errors;
      if (error.response?.data is Map<String, dynamic>) {
        errors = error.response?.data['errors'];
      }

      return ApiResponse<T>(
        success: false,
        message: message,
        errors: errors,
        statusCode: statusCode,
      );
    }

    return ApiResponse<T>(
      success: false,
      message: 'Error inesperado: ${error.toString()}',
      statusCode: 500,
    );
  }

  /// Obtener mensaje de error apropiado
  String _getErrorMessage(DioException error) {
    final response = error.response;

    if (response?.data is Map<String, dynamic>) {
      final data = response!.data as Map<String, dynamic>;
      return data['message'] ??
          _getDefaultErrorMessage(error.response?.statusCode);
    }

    return _getDefaultErrorMessage(error.response?.statusCode);
  }

  /// Obtener mensaje de error por defecto según código de estado
  String _getDefaultErrorMessage(int? statusCode) {
    switch (statusCode) {
      case 400:
        return 'Solicitud inválida';
      case 401:
        return 'No autorizado. Inicia sesión nuevamente';
      case 403:
        return 'No tienes permisos para realizar esta acción';
      case 404:
        return 'Recurso no encontrado';
      case 409:
        return 'Conflicto con los datos existentes';
      case 422:
        return 'Datos de entrada inválidos';
      case 500:
        return 'Error interno del servidor';
      case 503:
        return 'Servicio no disponible temporalmente';
      default:
        return 'Error de conexión. Intenta nuevamente';
    }
  }
}

// ========================================
// CLASES DE RESPUESTA Y ERROR
// ========================================

/// Clase para manejar respuestas de la API
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final List<dynamic>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.errors,
    this.statusCode,
  });

  /// Verificar si la respuesta es exitosa
  bool get isSuccess => success;

  /// Verificar si hay errores
  bool get hasErrors => errors != null && errors!.isNotEmpty;

  /// Obtener primer error si existe
  String? get firstError {
    if (hasErrors && errors!.isNotEmpty) {
      final error = errors!.first;
      if (error is String) return error;
      if (error is Map<String, dynamic>) {
        return error['message'] ?? error.toString();
      }
    }
    return null;
  }
}

/// Excepción personalizada para la API
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  ApiException(this.message, [this.statusCode, this.originalError]);

  @override
  String toString() => 'ApiException: $message';
}
