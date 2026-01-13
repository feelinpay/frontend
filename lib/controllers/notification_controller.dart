import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../database/local_database.dart';

class NotificationController extends ChangeNotifier {
  final List<Map<String, dynamic>> _notificaciones = [];
  List<Map<String, dynamic>> _smsPendientes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get notificaciones => _notificaciones;
  List<Map<String, dynamic>> get smsPendientes => _smsPendientes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Bridge Mode: Las notificaciones ahora se manejan automáticamente via PaymentNotificationService
  // No necesitamos exponer métodos manuales para cargar notificaciones pendientes en el UI

  // Cargar SMS pendientes
  Future<void> loadSMSPendientes() async {
    _setLoading(true);
    _clearError();

    try {
      _smsPendientes = await LocalDatabase.getSMSPendientes();
      notifyListeners();
    } catch (e) {
      _setError('Error cargando SMS pendientes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Enviar SMS de confirmación de pago
  Future<Map<String, dynamic>> enviarConfirmacionPago({
    required String propietarioId,
    required String nombrePagador,
    required double monto,
    required String codigoSeguridad,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final resultado = await SMSService.enviarConfirmacionPago(
        propietarioId: propietarioId,
        nombrePagador: nombrePagador,
        monto: monto,
        codigoSeguridad: codigoSeguridad,
      );

      if (resultado['success']) {
        await loadSMSPendientes();
        return resultado;
      } else {
        _setError(resultado['error'] ?? 'Error enviando confirmación');
        return resultado;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  // Enviar SMS masivo
  Future<Map<String, dynamic>> enviarSMSMasivo({
    required String propietarioId,
    required String mensaje,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final resultado = await SMSService.enviarSMSMasivo(
        propietarioId: propietarioId,
        mensaje: mensaje,
      );

      if (resultado['success']) {
        await loadSMSPendientes();
        return resultado;
      } else {
        _setError(resultado['error'] ?? 'Error enviando SMS masivo');
        return resultado;
      }
    } catch (e) {
      _setError('Error de conexión: ${e.toString()}');
      return {'success': false, 'error': 'Error de conexión: ${e.toString()}'};
    } finally {
      _setLoading(false);
    }
  }

  // Obtener estadísticas de SMS
  Future<Map<String, dynamic>> getEstadisticasSMS(String propietarioId) async {
    try {
      return await SMSService.getEstadisticasSMS(propietarioId);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo estadísticas: ${e.toString()}',
      };
    }
  }

  // Procesar SMS pendientes
  Future<void> procesarSMSPendientes() async {
    _setLoading(true);
    _clearError();

    try {
      await SMSService.procesarSMSPendientes();
      await loadSMSPendientes();
    } catch (e) {
      _setError('Error procesando SMS pendientes: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  // Verificar estado de SMS
  Future<Map<String, dynamic>> verificarEstadoSMS(String smsId) async {
    try {
      return await SMSService.verificarEstadoSMS(smsId);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error verificando estado: ${e.toString()}',
      };
    }
  }

  // Obtener estadísticas de pagos
  Future<Map<String, dynamic>> getEstadisticasPagos(
    String propietarioId,
  ) async {
    try {
      return await LocalDatabase.getEstadisticasPagos(propietarioId);
    } catch (e) {
      return {
        'success': false,
        'error': 'Error obteniendo estadísticas de pagos: ${e.toString()}',
      };
    }
  }

  // Obtener pagos del propietario
  Future<List<Map<String, dynamic>>> getPagosPropietario(
    String propietarioId,
  ) async {
    try {
      return await LocalDatabase.getPagosByPropietario(propietarioId);
    } catch (e) {
      _setError('Error obteniendo pagos: ${e.toString()}');
      return [];
    }
  }

  // Obtener empleados del propietario
  Future<List<Map<String, dynamic>>> getEmpleadosPropietario(
    String propietarioId,
  ) async {
    try {
      return await LocalDatabase.getEmpleadosByPropietario(propietarioId);
    } catch (e) {
      _setError('Error obteniendo empleados: ${e.toString()}');
      return [];
    }
  }

  // Crear empleado
  Future<Map<String, dynamic>> crearEmpleado({
    required String propietarioId,
    required String paisCodigo,
    required String telefono,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final empleadoId = await LocalDatabase.createEmpleado({
        'propietarioId': propietarioId,
        'paisCodigo': paisCodigo,
        'telefono': telefono,
        'activo': true,
      });

      return {
        'success': true,
        'empleadoId': empleadoId,
        'message': 'Empleado creado correctamente',
      };
    } catch (e) {
      _setError('Error creando empleado: ${e.toString()}');
      return {
        'success': false,
        'error': 'Error creando empleado: ${e.toString()}',
      };
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
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
