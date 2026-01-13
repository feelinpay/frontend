import 'package:flutter/material.dart'; // For TimeOfDay
import 'employee_service.dart';

import '../database/local_database.dart';
import 'api_service.dart';

class SMSService {
  // Enviar SMS a empleados sobre nuevo pago
  static Future<Map<String, dynamic>> enviarSMSAPago({
    required String empleadoId,
    required String pagoId,
    required String mensaje,
    required String numeroDestino,
  }) async {
    try {
      // Crear registro de SMS en base de datos local
      final smsId = await LocalDatabase.createSMS({
        'empleadoId': empleadoId,
        'pagoId': pagoId,
        'mensaje': mensaje,
        'numeroDestino': numeroDestino,
        'enviado': false,
      });

      // Intentar envío real de SMS
      final response = await ApiService().post<Map<String, dynamic>>(
        '/sms/enviar',
        data: {
          'numero': numeroDestino,
          'mensaje': mensaje,
          'empleadoId': empleadoId,
          'pagoId': pagoId,
        },
      );

      if (response.isSuccess) {
        final data = response.data!;

        if (data['success'] == true) {
          // Marcar SMS como enviado
          await LocalDatabase.marcarSMSEnviado(smsId);

          return {
            'success': true,
            'message': 'SMS enviado correctamente',
            'smsId': smsId,
          };
        } else {
          // Marcar SMS con error
          await LocalDatabase.marcarSMSEnviado(smsId, error: data['error']);

          return {'success': false, 'error': data['error'], 'smsId': smsId};
        }
      } else {
        // Marcar SMS con error
        await LocalDatabase.marcarSMSEnviado(
          smsId,
          error: 'Error HTTP: ${response.message}',
        );

        return {
          'success': false,
          'error': 'Error HTTP: ${response.message}',
          'smsId': smsId,
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Error de conexión: $e'};
    }
  }

  // Enviar SMS masivo a todos los empleados
  static Future<Map<String, dynamic>> enviarSMSMasivo({
    required String propietarioId,
    required String mensaje,
  }) async {
    try {
      // Obtener empleados del propietario
      final empleados = await LocalDatabase.getEmpleadosByPropietario(
        propietarioId,
      );

      if (empleados.isEmpty) {
        return {'success': false, 'error': 'No hay empleados registrados'};
      }

      int enviados = 0;
      int errores = 0;
      final List<String> erroresDetalle = [];

      final employeeService = EmployeeService();
      final now = DateTime.now();
      final dayName = _getDayName(now.weekday);
      final currentTime = TimeOfDay.fromDateTime(now);

      for (var empleado in empleados) {
        // Verificar restricciones (Activo + Horario)
        final shouldSend = await _shouldSendToEmployee(
          empleado,
          employeeService,
          dayName,
          currentTime,
        );

        if (!shouldSend) continue;

        final numeroCompleto =
            '${empleado['paisCodigo']}${empleado['telefono']}';

        final resultado = await enviarSMSAPago(
          empleadoId: empleado['id'],
          pagoId: '', // No hay pago específico en SMS masivo
          mensaje: mensaje,
          numeroDestino: numeroCompleto,
        );

        if (resultado['success']) {
          enviados++;
        } else {
          errores++;
          erroresDetalle.add('${empleado['telefono']}: ${resultado['error']}');
        }
      }

      return {
        'success': enviados > 0,
        'enviados': enviados,
        'errores': errores,
        'total': empleados.length,
        'erroresDetalle': erroresDetalle,
        'message': 'SMS enviados: $enviados/$empleados.length',
      };
    } catch (e) {
      return {'success': false, 'error': 'Error enviando SMS masivo: $e'};
    }
  }

  // ... (existing helper methods in SMSService if any)

  // Enviar SMS de confirmación de pago
  static Future<Map<String, dynamic>> enviarConfirmacionPago({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
  }) async {
    try {
      // Obtener empleados del propietario
      final empleados = await LocalDatabase.getEmpleadosByPropietario(
        propietarioId,
      );

      if (empleados.isEmpty) {
        return {
          'success': false,
          'error': 'No hay empleados registrados para notificar',
        };
      }

      // Crear mensaje de confirmación
      final mensaje =
          'Nuevo pago recibido: S/ ${monto.toStringAsFixed(2)} de $nombrePagador. Código: $codigoSeguridad';

      int enviados = 0;
      int errores = 0;
      final List<String> erroresDetalle = [];

      final employeeService = EmployeeService();
      final now = DateTime.now();
      final dayName = _getDayName(now.weekday);
      final currentTime = TimeOfDay.fromDateTime(now);

      for (var empleado in empleados) {
        // Verificar si el empleado tiene notificaciones activas
        if (empleado['activo'] != true && empleado['activo'] != 1) {
          // Check for boolean or int (1)
          // Notificaciones desactivadas para este empleado
          continue;
        }

        // Verificar horario laboral
        try {
          // Obtener horarios del empleado
          final schedulesResponse = await employeeService.getWorkSchedules(
            empleado['id'],
          );

          bool canSend = false;

          if (schedulesResponse.isSuccess && schedulesResponse.data != null) {
            final schedules = schedulesResponse.data!;

            // Buscar todos los horarios de hoy (Soporte horario partido)
            final todaySchedules = schedules
                .where((s) => s['diaSemana'] == dayName && s['activo'] == true)
                .toList();

            if (todaySchedules.isNotEmpty) {
              for (var schedule in todaySchedules) {
                final start = _parseTime(schedule['horaInicio']);
                final end = _parseTime(schedule['horaFin']);

                if (_isTimeBetween(currentTime, start, end)) {
                  canSend = true;
                  break; // Ya encontramos un horario válido
                }
              }
            }
          } else {
            // Si no hay horarios definidos o falla, ¿enviamos por defecto?
            // El usuario dijo "Solo en horarios de trabajo pueden estar activo"
            // Asumimos False por defecto si no hay horario explícito.
            canSend = false;
          }

          if (!canSend) {
            // Saltar este empleado
            continue;
          }
        } catch (e) {
          // Log removed
          // Ante error, mejor no enviar para cumplir restricción estricta
          continue;
        }

        final numeroCompleto =
            '${empleado['paisCodigo']}${empleado['telefono']}';

        final resultado = await enviarSMSAPago(
          empleadoId: empleado['id'],
          pagoId: '', // Se generará automáticamente
          mensaje: mensaje,
          numeroDestino: numeroCompleto,
        );

        if (resultado['success']) {
          enviados++;
        } else {
          errores++;
          erroresDetalle.add('${empleado['telefono']}: ${resultado['error']}');
        }
      }

      return {
        'success': enviados > 0,
        'enviados': enviados,
        'errores': errores,
        'total': empleados.length,
        'erroresDetalle': erroresDetalle,
        'message': 'Confirmaciones enviadas: $enviados (Filtrados por horario)',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Error enviando confirmación de pago: $e',
      };
    }
  }

  static String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Lunes';
      case 2:
        return 'Martes';
      case 3:
        return 'Miércoles';
      case 4:
        return 'Jueves';
      case 5:
        return 'Viernes';
      case 6:
        return 'Sábado';
      case 7:
        return 'Domingo';
      default:
        return 'Lunes';
    }
  }

  static TimeOfDay _parseTime(String timeStr) {
    try {
      final parts = timeStr.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (e) {
      return const TimeOfDay(hour: 0, minute: 0);
    }
  }

  static bool _isTimeBetween(
    TimeOfDay current,
    TimeOfDay start,
    TimeOfDay end,
  ) {
    final nowMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    return nowMinutes >= startMinutes && nowMinutes <= endMinutes;
  }

  // Obtener estadísticas de SMS
  static Future<Map<String, dynamic>> getEstadisticasSMS(
    String propietarioId,
  ) async {
    try {
      return await LocalDatabase.getEstadisticasSMS(propietarioId);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo estadísticas de SMS: $e',
      };
    }
  }

  // Procesar SMS pendientes
  static Future<void> procesarSMSPendientes() async {
    try {
      await LocalDatabase.enviarSMSPendientes();
      // Logs removed
    } catch (_) {
      // Error ignored for optimization
    }
  }

  // Verificar estado de SMS
  static Future<Map<String, dynamic>> verificarEstadoSMS(String smsId) async {
    try {
      return await LocalDatabase.verificarEstadoSMS(smsId);
    } catch (e) {
      return {'success': false, 'error': 'Error verificando estado de SMS: $e'};
    }
  }

  // Verificar si se debe enviar SMS al empleado según reglas
  static Future<bool> _shouldSendToEmployee(
    Map<String, dynamic> empleado,
    EmployeeService employeeService,
    String dayName,
    TimeOfDay currentTime,
  ) async {
    // 1. Verificar si está activo (Notificaciones activas)
    if (empleado['activo'] != true && empleado['activo'] != 1) {
      return false;
    }

    // 2. Verificar horario laboral
    try {
      final schedulesResponse = await employeeService.getWorkSchedules(
        empleado['id'],
      );

      if (schedulesResponse.isSuccess && schedulesResponse.data != null) {
        final schedules = schedulesResponse.data!;

        // Filtrar todos los horarios de HOY
        final todaySchedules = schedules
            .where((s) => s['diaSemana'] == dayName && s['activo'] == true)
            .toList();

        // Si no tiene horarios hoy, no trabaja
        if (todaySchedules.isEmpty) return false;

        // Verificar si la hora actual está en CUALQUIERA de los rangos (Horario partido)
        for (var schedule in todaySchedules) {
          final start = _parseTime(schedule['horaInicio']);
          final end = _parseTime(schedule['horaFin']);

          if (_isTimeBetween(currentTime, start, end)) {
            // Encontró un rango válido -> enviar
            return true;
          }
        }
        // Si revisó todos los rangos y ninguno coincide -> no enviar
        return false;
      }
      // Si no hay horarios definidos o falla la llamada -> no enviar
      return false;
    } catch (e) {
      // Log removed for optimization
      return false;
    }
  }
}
