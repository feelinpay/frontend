import '../services/api_service.dart';

/// Servicio de datos que centraliza las llamadas al backend MySQL
/// Reemplaza la funcionalidad anterior de SQLite
class LocalDatabase {
  static final ApiService _api = ApiService();

  // ========================================
  // SMS
  // ========================================

  static Future<String> createSMS(Map<String, dynamic> data) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/sms/create',
      data: data,
    );
    return response.data?['id']?.toString() ?? 'error';
  }

  static Future<List<Map<String, dynamic>>> getSMSPendientes() async {
    final response = await _api.get<List<dynamic>>('/sms/pending');
    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data!);
    }
    return [];
  }

  static Future<void> marcarSMSEnviado(String id, {String? error}) async {
    await _api.patch('/sms/$id/mark-sent', data: {'error': error});
  }

  static Future<void> enviarSMSPendientes() async {
    await _api.post('/sms/send-pending');
  }

  static Future<Map<String, dynamic>> getEstadisticasSMS(String propietarioId) async {
    final response = await _api.get<Map<String, dynamic>>('/sms/statistics/$propietarioId');
    return response.data ?? {'smsHoy': 0, 'smsTotal': 0, 'smsPendientes': 0};
  }

  static Future<Map<String, dynamic>> verificarEstadoSMS(String smsId) async {
    final response = await _api.get<Map<String, dynamic>>('/sms/status/$smsId');
    return response.data ?? {'success': false, 'error': 'SMS no encontrado'};
  }

  // ========================================
  // Empleados
  // ========================================

  static Future<String> createEmpleado(Map<String, dynamic> data) async {
    final response = await _api.post<Map<String, dynamic>>(
      '/employees/create',
      data: data,
    );
    return response.data?['id']?.toString() ?? 'error';
  }

  static Future<List<Map<String, dynamic>>> getEmpleadosByPropietario(
    String propietarioId,
  ) async {
    final response = await _api.get<List<dynamic>>(
      '/employees/by-owner/$propietarioId',
    );
    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data!);
    }
    return [];
  }

  // ========================================
  // Pagos
  // ========================================

  static Future<void> createPago(Map<String, dynamic> data) async {
    await _api.post('/payments/create', data: data);
  }

  static Future<List<Map<String, dynamic>>> getPagosByPropietario(
    String propietarioId,
  ) async {
    final response = await _api.get<List<dynamic>>(
      '/payments/by-owner/$propietarioId',
    );
    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data!);
    }
    return [];
  }

  static Future<Map<String, dynamic>> getEstadisticasPagos(
    String propietarioId,
  ) async {
    final response = await _api.get<Map<String, dynamic>>(
      '/payments/statistics/$propietarioId',
    );
    return response.data ??
        {'totalPagado': 0.0, 'cantidadPagos': 0, 'promedioMensual': 0.0};
  }

  // ========================================
  // Notificaciones
  // ========================================

  static Future<List<Map<String, dynamic>>>
  getNotificacionesPendientes() async {
    final response = await _api.get<List<dynamic>>('/notifications/pending');
    if (response.isSuccess && response.data != null) {
      return List<Map<String, dynamic>>.from(response.data!);
    }
    return [];
  }

  static Future<void> procesarNotificacionYape(
    String mensaje,
    String propietarioId,
  ) async {
    await _api.post(
      '/notifications/process-yape',
      data: {'mensaje': mensaje, 'propietarioId': propietarioId},
    );
  }
}
