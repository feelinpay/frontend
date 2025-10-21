import '../models/api_response.dart';

/// Helper para procesar y mostrar errores de manera más específica
class ErrorHelper {
  /// Procesa errores de validación y devuelve un mensaje más específico
  static String processValidationError(ApiResponse response) {
    // Si hay errores específicos de validación, los procesamos
    if (response.errors != null && response.errors!.isNotEmpty) {
      final errors = response.errors!;
      
      // Buscar errores de validación específicos
      for (final error in errors) {
        if (error is Map<String, dynamic>) {
          final field = error['field']?.toString() ?? '';
          final message = error['message']?.toString() ?? '';
          
          // Traducir campos al español y mostrar mensaje específico
          switch (field.toLowerCase()) {
            case 'nombre':
              if (message.contains('exceder') || message.contains('longitud')) {
                return 'El nombre no puede tener más de 50 caracteres';
              } else if (message.contains('requerido') || message.contains('obligatorio')) {
                return 'El nombre es obligatorio';
              }
              break;
            case 'telefono':
              if (message.contains('formato') || message.contains('inválido')) {
                return 'El formato del teléfono no es válido';
              } else if (message.contains('requerido') || message.contains('obligatorio')) {
                return 'El teléfono es obligatorio';
              }
              break;
            case 'email':
              if (message.contains('formato') || message.contains('inválido')) {
                return 'El formato del email no es válido';
              } else if (message.contains('requerido') || message.contains('obligatorio')) {
                return 'El email es obligatorio';
              } else if (message.contains('existir') || message.contains('duplicado')) {
                return 'Este email ya está registrado';
              }
              break;
            case 'password':
              if (message.contains('débil') || message.contains('fuerte')) {
                return 'La contraseña debe ser más segura';
              } else if (message.contains('longitud')) {
                return 'La contraseña debe tener al menos 8 caracteres';
              }
              break;
            default:
              // Si no reconocemos el campo, usar el mensaje original
              if (message.isNotEmpty) {
                return message;
              }
          }
        }
      }
      
      // Si hay errores pero no pudimos procesarlos específicamente
      final firstError = errors.first;
      if (firstError is Map<String, dynamic>) {
        final message = firstError['message']?.toString() ?? '';
        if (message.isNotEmpty) {
          return message;
        }
      }
    }
    
    // Si no hay errores específicos, usar el mensaje general
    return response.message;
  }

  /// Procesa errores de API y devuelve un mensaje más amigable
  static String processApiError(ApiResponse response) {
    // Procesar errores de validación primero
    final validationError = processValidationError(response);
    if (validationError != response.message) {
      return validationError;
    }

    // Procesar otros tipos de errores
    switch (response.statusCode) {
      case 400:
        return 'Datos incorrectos. Verifica la información ingresada.';
      case 401:
        return 'No tienes permisos para realizar esta acción.';
      case 403:
        return 'Acceso denegado.';
      case 404:
        return 'No se encontró el recurso solicitado.';
      case 409:
        return 'Conflicto: El recurso ya existe.';
      case 422:
        return 'Los datos enviados no son válidos.';
      case 500:
        return 'Error interno del servidor. Intenta nuevamente.';
      default:
        return response.message;
    }
  }

  /// Obtiene el primer error de validación específico
  static String? getFirstValidationError(ApiResponse response) {
    if (response.errors != null && response.errors!.isNotEmpty) {
      final firstError = response.errors!.first;
      if (firstError is Map<String, dynamic>) {
        return firstError['message']?.toString();
      }
    }
    return null;
  }
}
