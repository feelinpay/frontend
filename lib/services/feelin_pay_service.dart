import 'package:flutter/foundation.dart';
import '../database/local_database.dart';
import 'api_service.dart';

/// Servicio principal de Feelin Pay que integra todas las funcionalidades
class FeelinPayService {
  /// ===== PROCESAMIENTO DE PAGOS =====

  /// Procesar pago completo (validar + Google Sheets + SMS)
  static Future<Map<String, dynamic>> procesarPagoCompleto({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
    required DateTime fechaPago,
    String? telefonoPagador,
    bool notificarEmpleados = true,
  }) async {
    try {
      final response = await ApiService().post<Map<String, dynamic>>(
        '/pago-integrado/procesar-pago',
        data: {
          'propietarioId': propietarioId,
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
          'fechaPago': fechaPago.toIso8601String(),
          'telefonoPagador': telefonoPagador,
          'notificarEmpleados': notificarEmpleados,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // Guardar pago localmente para respaldo
        await _guardarPagoLocalmente({
          'propietarioId': propietarioId,
          'clienteNombre': nombrePagador,
          'monto': monto,
          'fecha': fechaPago.toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
          'notificadoEmpleados': data['data']['sms']['enviados'] > 0,
          'registradoEnSheets': data['data']['googleSheets']['registrado'],
          'sincronizado': true,
        });

        return {
          'success': true,
          'data': data['data'],
          'message': 'Pago procesado exitosamente',
          'online': true,
        };
      } else {
        // Si falla online, procesar offline
        return await _procesarPagoOffline(
          propietarioId: propietarioId,
          nombrePagador: nombrePagador,
          monto: monto,
          codigoSeguridad: codigoSeguridad,
          fechaPago: fechaPago,
          telefonoPagador: telefonoPagador,
        );
      }
    } catch (e) {
      // Si no hay internet, procesar offline
      return await _procesarPagoOffline(
        propietarioId: propietarioId,
        nombrePagador: nombrePagador,
        monto: monto,
        codigoSeguridad: codigoSeguridad,
        fechaPago: fechaPago,
        telefonoPagador: telefonoPagador,
      );
    }
  }

  /// Procesar pago offline
  static Future<Map<String, dynamic>> _procesarPagoOffline({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
    required DateTime fechaPago,
    String? telefonoPagador,
  }) async {
    try {
      // Guardar pago localmente
      await _guardarPagoLocalmente({
        'propietarioId': propietarioId,
        'clienteNombre': nombrePagador,
        'monto': monto,
        'fecha': fechaPago.toIso8601String(),
        'codigoSeguridad': codigoSeguridad,
        'telefonoPagador': telefonoPagador,
        'notificadoEmpleados': false,
        'registradoEnSheets': false,
        'sincronizado': false,
      });

      return {
        'success': true,
        'message':
            'Pago guardado localmente. Se sincronizará cuando haya internet.',
        'offline': true,
      };
    } catch (e) {
      return {'success': false, 'error': 'Error al guardar pago offline: $e'};
    }
  }

  /// Guardar pago localmente
  static Future<void> _guardarPagoLocalmente(
    Map<String, dynamic> pagoData,
  ) async {
    try {
      await LocalDatabase.createPago(pagoData);
    } catch (e) {
      debugPrint('Error al guardar pago localmente: $e');
    }
  }

  /// ===== GOOGLE SHEETS =====

  /// Obtener enlace de compartir para empleados
  /// Obtener enlace de compartir para empleados
  static Future<Map<String, dynamic>> obtenerEnlaceCompartir(
    String propietarioId,
  ) async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/pago-integrado/enlace-compartir/$propietarioId',
      );

      if (response.isSuccess && response.data != null) {
        return {
          'success': true,
          'url': response.data!['url'],
          'message': 'Enlace obtenido exitosamente',
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== ESTADÍSTICAS =====

  /// Obtener estadísticas del propietario
  /// Obtener estadísticas del propietario
  static Future<Map<String, dynamic>> obtenerEstadisticas(
    String propietarioId,
  ) async {
    try {
      // Intentar obtener online primero
      final response = await ApiService().get<Map<String, dynamic>>(
        '/pago-integrado/verificar-saldo-sms/$propietarioId',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return {
          'success': true,
          'saldoDisponible': data['saldoDisponible'],
          'empleadosActivos': data['empleadosActivos'],
          'online': true,
        };
      }
    } catch (e) {
      // Si falla online, obtener offline
    }

    // Obtener estadísticas offline
    try {
      final estadisticas = await LocalDatabase.getEstadisticasPagos(
        propietarioId,
      );
      return {'success': true, 'estadisticas': estadisticas, 'offline': true};
    } catch (e) {
      return {'success': false, 'error': 'Error al obtener estadísticas: $e'};
    }
  }

  /// ===== SINCRONIZACIÓN =====

  /// Sincronizar pagos pendientes
  /// Sincronizar pagos pendientes
  static Future<Map<String, dynamic>> sincronizarPagosPendientes(
    String propietarioId,
  ) async {
    try {
      final response = await ApiService().post<Map<String, dynamic>>(
        '/pago-integrado/sincronizar/$propietarioId',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return {
          'success': true,
          'sincronizados': data['sincronizados'],
          'message': data['message'],
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== BOTÓN DE PRUEBAS =====

  /// Procesar pago de prueba (sin Yape real)
  /// Procesar pago de prueba (sin Yape real)
  static Future<Map<String, dynamic>> procesarPagoPrueba({
    required String propietarioId,
    String nombrePagador = 'Cliente de Prueba',
    double monto = 25.50,
    String codigoSeguridad = 'TEST123',
    String telefonoPagador = '+51987654321',
  }) async {
    try {
      final response = await ApiService().post<Map<String, dynamic>>(
        '/test/procesar-pago-prueba/$propietarioId',
        data: {
          'nombrePagador': nombrePagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
        },
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;

        // Guardar pago localmente para respaldo
        await _guardarPagoLocalmente({
          'propietarioId': propietarioId,
          'clienteNombre': nombrePagador,
          'monto': monto,
          'fecha': DateTime.now().toIso8601String(),
          'codigoSeguridad': codigoSeguridad,
          'telefonoPagador': telefonoPagador,
          'notificadoEmpleados': data['data']['sms']['enviados'] > 0,
          'registradoEnSheets': data['data']['googleSheets']['registrado'],
          'sincronizado': true,
        });

        return {
          'success': true,
          'data': data['data'],
          'message': 'Pago de prueba procesado exitosamente',
          'esPrueba': true,
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Verificar si se puede usar el botón de prueba
  static Future<Map<String, dynamic>> verificarBotonPrueba(
    String propietarioId,
  ) async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/test/verificar-boton-prueba/$propietarioId',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return {
          'success': true,
          'puedeUsar': data['puedeUsar'],
          'ilimitado': data['ilimitado'] ?? false,
          'razon': data['razon'],
          'fechaUso': data['fechaUso'],
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// ===== ACCESO DE EMPLEADOS =====

  /// Obtener enlace de Google Sheets para empleados (público)
  /// Obtener enlace de Google Sheets para empleados (público)
  static Future<Map<String, dynamic>> obtenerEnlaceGoogleSheetsEmpleados(
    String propietarioId,
  ) async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/empleado-access/google-sheets/$propietarioId',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return {
          'success': true,
          'url': data['url'],
          'accessType': data['accessType'],
          'description': data['description'],
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  /// Verificar acceso de empleado
  static Future<Map<String, dynamic>> verificarAccesoEmpleado(
    String empleadoId,
  ) async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/empleado-access/verificar/$empleadoId',
      );

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        return {
          'success': true,
          'acceso': data['acceso'],
          'empleado': data['empleado'],
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Google Sheets
  static Future<Map<String, dynamic>> obtenerConfiguracionSheets() async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/reportes/sheets-config',
      );

      if (response.isSuccess && response.data != null) {
        return {
          'success': true,
          'configuracion': response.data!['configuracion'],
        };
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> abrirGoogleSheets() async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/reportes/abrir-sheets',
      );

      if (response.isSuccess && response.data != null) {
        return {'success': true, 'url': response.data!['url']};
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  static Future<Map<String, dynamic>> compartirGoogleSheets() async {
    try {
      final response = await ApiService().get<Map<String, dynamic>>(
        '/reportes/compartir-sheets',
      );

      if (response.isSuccess && response.data != null) {
        return {'success': true, 'url': response.data!['url']};
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Llenar Google Sheets con datos de prueba
  static Future<Map<String, dynamic>> llenarDatosPrueba() async {
    try {
      final response = await ApiService().post<Map<String, dynamic>>(
        '/reportes/llenar-datos-prueba',
      );

      if (response.isSuccess) {
        final message = response.data?['message'] ?? 'Datos de prueba llenados';
        return {'success': true, 'message': message};
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Crear estructura de Google Sheets
  static Future<Map<String, dynamic>> crearEstructuraSheets() async {
    try {
      final response = await ApiService().post<Map<String, dynamic>>(
        '/reportes/crear-estructura',
      );

      if (response.isSuccess) {
        final message =
            response.data?['message'] ?? 'Estructura creada correctamente';
        return {'success': true, 'message': message};
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Llenar Google Sheets automáticamente con pago de prueba
  static Future<Map<String, dynamic>> llenarAutomaticamente({
    required String pagador,
    required double monto,
    required String codigoSeguridad,
  }) async {
    try {
      final response = await ApiService().post<Map<String, dynamic>>(
        '/reportes/llenar-automatico',
        data: {
          'pagador': pagador,
          'monto': monto,
          'codigoSeguridad': codigoSeguridad,
        },
      );

      if (response.isSuccess) {
        final message =
            response.data?['message'] ?? 'Datos llenados automáticamente';
        return {'success': true, 'message': message};
      } else {
        return {'success': false, 'error': response.message};
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }
}
