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

  /// Crear respuesta exitosa
  factory ApiResponse.success({
    required String message,
    T? data,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
    );
  }

  /// Crear respuesta de error
  factory ApiResponse.error({
    required String message,
    List<dynamic>? errors,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'errors': errors,
      'statusCode': statusCode,
    };
  }

  /// Crear desde JSON
  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    return ApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'],
      errors: json['errors'],
      statusCode: json['statusCode'],
    );
  }
}

