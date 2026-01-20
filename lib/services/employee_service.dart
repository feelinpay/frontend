import '../models/employee_model.dart';
import '../models/api_response.dart' as api_models;
import '../core/config/app_config.dart';
import 'api_service.dart';

class EmployeeService {
  static final EmployeeService _instance = EmployeeService._internal();
  factory EmployeeService() => _instance;
  EmployeeService._internal();

  final ApiService _apiService = ApiService();

  // ========================================
  // GESTIÓN DE EMPLEADOS
  // ========================================

  // ========================================
  // GESTIÓN DE EMPLEADOS
  // ========================================

  /// Obtener lista de empleados
  /// [ownerId] es opcional. Si se proporciona, usa el endpoint de Super Admin para ver los empleados de ese usuario.
  Future<api_models.ApiResponse<List<EmployeeModel>>> getEmployees({
    int page = 1,
    int limit = 20,
    String? search,
    bool? activo,
    String? ownerId,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (activo != null) {
      queryParams['activo'] = activo;
    }

    String endpoint;
    if (ownerId != null && ownerId.isNotEmpty) {
      endpoint = '${AppConfig.superAdminEndpoint}/users/$ownerId/employees';
    } else {
      endpoint = '${AppConfig.ownerEndpoint}/employees';
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;

      // El backend devuelve: { "empleados": [...], "pagination": {...} }
      List<dynamic> employeesList;
      if (data['empleados'] != null) {
        employeesList = data['empleados'] as List<dynamic>;
      } else if (data['employees'] != null) {
        employeesList = data['employees'] as List<dynamic>;
      } else if (data['data'] != null && data['data'] is List) {
        employeesList = data['data'] as List<dynamic>;
      } else if (data.containsKey('id')) {
        employeesList = [data];
      } else {
        employeesList = [];
      }

      final employees = employeesList
          .map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<EmployeeModel>>(
        success: true,
        message: response.message,
        data: employees,
      );
    }

    return api_models.ApiResponse<List<EmployeeModel>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Obtener empleado específico por ID
  Future<api_models.ApiResponse<EmployeeModel>> getEmployee(
    String employeeId, {
    String? ownerId,
  }) async {
    // Note: Admin get single employee endpoint might be slightly different or not implemented individually
    // Assuming structure: /users/:userId/employees/:employeeId
    String endpoint;
    if (ownerId != null && ownerId.isNotEmpty) {
      endpoint =
          '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId';
    } else {
      endpoint = '${AppConfig.ownerEndpoint}/employees/$employeeId';
    }

    final response = await _apiService.get<Map<String, dynamic>>(endpoint);

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Crear nuevo empleado
  Future<api_models.ApiResponse<EmployeeModel>> createEmployee({
    required String nombre,
    required String telefono,
    String? ownerId,
  }) async {
    final Map<String, dynamic> data = {
      'nombre': nombre,
      'telefono': telefono,
      'activo': true,
    };

    String endpoint;
    if (ownerId != null && ownerId.isNotEmpty) {
      // Admin Endpoint: POST /users/:userId/employees
      endpoint = '${AppConfig.superAdminEndpoint}/users/$ownerId/employees';
      // data['ownerId'] is not needed in body because it's in URL, but harmless if present
    } else {
      endpoint = '${AppConfig.ownerEndpoint}/employees';
      if (ownerId != null) data['ownerId'] = ownerId; // Legacy handling
    }

    final response = await _apiService.post<Map<String, dynamic>>(
      endpoint,
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar empleado
  Future<api_models.ApiResponse<EmployeeModel>> updateEmployee({
    required String employeeId,
    required String nombre,
    required String telefono,
    String? ownerId,
  }) async {
    String endpoint;
    if (ownerId != null && ownerId.isNotEmpty) {
      endpoint =
          '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId';
    } else {
      endpoint = '${AppConfig.ownerEndpoint}/employees/$employeeId';
    }

    final response = await _apiService.put<Map<String, dynamic>>(
      endpoint,
      data: {'nombre': nombre, 'telefono': telefono},
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Activar/Desactivar empleado
  Future<api_models.ApiResponse<EmployeeModel>> toggleEmployeeStatus(
    String employeeId, {
    String? ownerId,
  }) async {
    String endpoint;
    if (ownerId != null && ownerId.isNotEmpty) {
      endpoint =
          '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId/toggle';
    } else {
      endpoint = '${AppConfig.ownerEndpoint}/employees/$employeeId/toggle';
    }

    final response = await _apiService.patch<Map<String, dynamic>>(endpoint);

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Eliminar empleado
  Future<api_models.ApiResponse<void>> deleteEmployee(
    String employeeId, {
    String? ownerId,
  }) async {
    String endpoint;
    if (ownerId != null && ownerId.isNotEmpty) {
      endpoint =
          '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId';
    } else {
      endpoint = '${AppConfig.ownerEndpoint}/employees/$employeeId';
    }

    final response = await _apiService.delete<Map<String, dynamic>>(endpoint);

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Buscar empleados
  Future<api_models.ApiResponse<List<EmployeeModel>>> searchEmployees({
    required String query,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.ownerEndpoint}/employees/search',
      queryParameters: {'q': query, 'page': page, 'limit': limit},
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;

      // El backend puede devolver los empleados en diferentes formatos
      List<dynamic> employeesList;
      if (data['employees'] != null) {
        employeesList = data['employees'] as List<dynamic>;
      } else if (data['data'] != null) {
        employeesList = data['data'] as List<dynamic>;
      } else {
        employeesList = [];
      }

      final employees = employeesList
          .map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<EmployeeModel>>(
        success: true,
        message: response.message,
        data: employees,
      );
    }

    return api_models.ApiResponse<List<EmployeeModel>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Obtener estadísticas de empleados
  Future<api_models.ApiResponse<EmployeeStats>> getEmployeeStats() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.ownerEndpoint}/employees/stats',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeStats>(
        success: true,
        message: response.message,
        data: EmployeeStats.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<EmployeeStats>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // CONFIGURACIÓN DE NOTIFICACIONES
  // ========================================

  /// Obtener configuración de notificaciones de empleados
  /// Las notificaciones se manejan a través del campo 'activo' de cada empleado
  Future<api_models.ApiResponse<List<EmployeeModel>>>
      getNotificationConfigs() async {
    // Simplemente devolver los empleados ya que las notificaciones están en el campo 'activo'
    return await getEmployees();
  }

  /// Actualizar configuración de notificaciones de un empleado
  Future<api_models.ApiResponse<EmployeeModel>> updateNotificationConfig({
    required String employeeId,
    required bool notificacionesActivas,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '/owner/employees/$employeeId',
      data: {'activo': notificacionesActivas},
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Activar/Desactivar notificaciones para todos los empleados
  Future<api_models.ApiResponse<void>> toggleAllNotifications(
    bool activar,
  ) async {
    try {
      // Obtener todos los empleados
      final employeesResponse = await getEmployees();

      if (!employeesResponse.isSuccess || employeesResponse.data == null) {
        return api_models.ApiResponse<void>(
          success: false,
          message: 'Error obteniendo empleados: ${employeesResponse.message}',
        );
      }

      final employees = employeesResponse.data!;

      // Crear lista de futuros para ejecutar en paralelo
      final futures = employees
          .map(
            (employee) => updateNotificationConfig(
              employeeId: employee.id,
              notificacionesActivas: activar,
            ),
          )
          .toList();

      // Ejecutar todas las actualizaciones en paralelo
      final results = await Future.wait(futures);

      // Verificar si alguna falló
      final failedUpdates =
          results.where((result) => !result.isSuccess).toList();

      if (failedUpdates.isNotEmpty) {
        final failedNames = employees
            .where((emp) => results[employees.indexOf(emp)].isSuccess == false)
            .map((emp) => emp.nombre)
            .join(', ');

        return api_models.ApiResponse<void>(
          success: false,
          message: 'Error actualizando empleados: $failedNames',
        );
      }

      return api_models.ApiResponse<void>(
        success: true,
        message: activar
            ? 'Notificaciones activadas para todos los empleados'
            : 'Notificaciones desactivadas para todos los empleados',
      );
    } catch (e) {
      return api_models.ApiResponse<void>(
        success: false,
        message: 'Error actualizando notificaciones: ${e.toString()}',
      );
    }
  }
  // ========================================
  // GESTIÓN DE HORARIOS LABORALES
  // ========================================

  /// Obtener horarios laborales de un empleado
  Future<api_models.ApiResponse<Map<String, dynamic>>> getWorkSchedules(
    String employeeId,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.ownerEndpoint}/employees/$employeeId/horarios-laborales',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: response.data!,
      );
    }

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar horario laboral completo
  Future<api_models.ApiResponse<Map<String, dynamic>>> updateWorkSchedule({
    required String employeeId,
    required Map<String, dynamic> horarioLaboral,
  }) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.ownerEndpoint}/employees/$employeeId/horarios-laborales',
      data: {'horarioLaboral': horarioLaboral},
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: response.data!,
      );
    }

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }
}

// ========================================
// MODELOS ADICIONALES
// ========================================

/// Modelo para estadísticas de empleados
class EmployeeStats {
  final int totalEmpleados;
  final int empleadosActivos;
  final int empleadosInactivos;
  final int notificacionesActivas;
  final int notificacionesInactivas;

  const EmployeeStats({
    required this.totalEmpleados,
    required this.empleadosActivos,
    required this.empleadosInactivos,
    required this.notificacionesActivas,
    required this.notificacionesInactivas,
  });

  factory EmployeeStats.fromJson(Map<String, dynamic> json) {
    return EmployeeStats(
      totalEmpleados: json['totalEmpleados'] ?? 0,
      empleadosActivos: json['empleadosActivos'] ?? 0,
      empleadosInactivos: json['empleadosInactivos'] ?? 0,
      notificacionesActivas: json['notificacionesActivas'] ?? 0,
      notificacionesInactivas: json['notificacionesInactivas'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEmpleados': totalEmpleados,
      'empleadosActivos': empleadosActivos,
      'empleadosInactivos': empleadosInactivos,
      'notificacionesActivas': notificacionesActivas,
      'notificacionesInactivas': notificacionesInactivas,
    };
  }
}

/// Modelo para configuración de notificaciones
class NotificationConfig {
  final String id;
  final String empleadoId;
  final String empleadoNombre;
  final bool notificacionesActivas;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationConfig({
    required this.id,
    required this.empleadoId,
    required this.empleadoNombre,
    required this.notificacionesActivas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory NotificationConfig.fromJson(Map<String, dynamic> json) {
    return NotificationConfig(
      id: json['id'] ?? '',
      empleadoId: json['empleadoId'] ?? '',
      empleadoNombre:
          json['empleadoNombre'] ?? json['empleado']?['nombre'] ?? '',
      notificacionesActivas: json['notificacionesActivas'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'empleadoId': empleadoId,
      'empleadoNombre': empleadoNombre,
      'notificacionesActivas': notificacionesActivas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
