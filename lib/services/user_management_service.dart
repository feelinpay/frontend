import '../models/user_model.dart';
import '../models/employee_model.dart';
import '../models/api_response.dart' as api_models;
import '../core/config/app_config.dart';
import 'api_service.dart';

class UserManagementService {
  static final UserManagementService _instance = UserManagementService._internal();
  factory UserManagementService() => _instance;
  UserManagementService._internal();

  final ApiService _apiService = ApiService();

  // ========================================
  // GESTIÓN DE USUARIOS (SUPER ADMIN)
  // ========================================

  /// Obtener todos los usuarios (solo Super Admin)
  Future<api_models.ApiResponse<List<UserModel>>> getAllUsers({
    int page = 1,
    int limit = 20,
    String? search,
    String? rol,
    bool? activo,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (rol != null && rol.isNotEmpty) {
      queryParams['role'] = rol;
    }

    if (activo != null) {
      queryParams['activo'] = activo;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users',
      queryParameters: queryParams,
    );

    print('🔍 [UserManagementService] getAllUsers response:');
    print('  Success: ${response.isSuccess}');
    print('  Message: ${response.message}');
    print('  Status Code: ${response.statusCode}');
    print('  Data: ${response.data}');

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      // El backend devuelve los datos en data.usuarios
      final usersList = data['usuarios'] as List<dynamic>? ?? [];
      
      print('🔍 [UserManagementService] Users list length: ${usersList.length}');
      
      final users = usersList
          .map((json) => UserModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<UserModel>>(
        success: true,
        message: response.message,
        data: users,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<List<UserModel>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Obtener usuario por ID (solo Super Admin)
  Future<api_models.ApiResponse<UserModel>> getUserById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$id',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Crear nuevo usuario (solo Super Admin)
  Future<api_models.ApiResponse<UserModel>> createUser({
    required String nombre,
    required String telefono,
    required String email,
    required String password,
    required String rolId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users',
      data: {
        'nombre': nombre,
        'telefono': telefono,
        'email': email,
        'password': password,
        'rolId': rolId,
      },
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar usuario (solo Super Admin)
  Future<api_models.ApiResponse<UserModel>> updateUser(
    String id, {
    String? nombre,
    String? telefono,
    String? email,
    String? rolId,
    bool? activo,
  }) async {
    final data = <String, dynamic>{};
    
    if (nombre != null) data['nombre'] = nombre;
    if (telefono != null) data['telefono'] = telefono;
    if (email != null) data['email'] = email;
    if (rolId != null) data['rolId'] = rolId;
    if (activo != null) data['activo'] = activo;

    final response = await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$id',
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Eliminar usuario (solo Super Admin)
  Future<api_models.ApiResponse<Map<String, dynamic>>> deleteUser(String id) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$id',
    );

    if (response.isSuccess) {
      return api_models.ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: {'deleted': true},
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Activar/Desactivar usuario (solo Super Admin)
  Future<api_models.ApiResponse<UserModel>> toggleUserStatus(String id) async {
    final response = await _apiService.patch<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$id/toggle',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<UserModel>(
        success: true,
        message: response.message,
        data: UserModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<UserModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // GESTIÓN DE EMPLEADOS POR PROPIETARIO
  // ========================================

  /// Obtener empleados de un propietario específico (solo Super Admin)
  Future<api_models.ApiResponse<List<EmployeeModel>>> getEmployeesByOwner(
    String ownerId, {
    int page = 1,
    int limit = 20,
    String? search,
    bool? activo,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (activo != null) {
      queryParams['activo'] = activo;
    }

    print('🔍 [UserManagementService] getEmployeesByOwner - Owner ID: $ownerId');
    print('🔍 [UserManagementService] Query params: $queryParams');
    
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$ownerId/employees',
      queryParameters: queryParams,
    );

    print('🔍 [UserManagementService] getEmployeesByOwner response:');
    print('  Success: ${response.isSuccess}');
    print('  Message: ${response.message}');
    print('  Status Code: ${response.statusCode}');
    print('  Data: ${response.data}');

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      // El backend puede devolver los empleados directamente o en data.employees
      List<dynamic> employeesList = [];
      if (data is List) {
        employeesList = data as List<dynamic>;
      } else {
        if (data.containsKey('employees')) {
          final employeesData = data['employees'];
          if (employeesData is List) {
            employeesList = employeesData;
          }
        } else if (data.containsKey('empleados')) {
          // Backend devuelve 'empleados' en español
          final employeesData = data['empleados'];
          if (employeesData is List) {
            employeesList = employeesData;
          }
        } else if (data.containsKey('data')) {
          final innerData = data['data'];
          if (innerData is Map && innerData.containsKey('employees')) {
            final employeesData = innerData['employees'];
            if (employeesData is List) {
              employeesList = employeesData;
            }
          } else if (innerData is Map && innerData.containsKey('empleados')) {
            // Backend devuelve 'empleados' en español
            final employeesData = innerData['empleados'];
            if (employeesData is List) {
              employeesList = employeesData;
            }
          } else if (innerData is List) {
            employeesList = innerData;
          }
        }
      }
      
      print('🔍 [UserManagementService] Employees list length: ${employeesList.length}');
      
      final employees = employeesList
          .map((json) => EmployeeModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<EmployeeModel>>(
        success: true,
        message: response.message,
        data: employees,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<List<EmployeeModel>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Crear empleado para un propietario específico (solo Super Admin)
  Future<api_models.ApiResponse<EmployeeModel>> createEmployeeForOwner(
    String ownerId, {
    required String nombre,
    required String telefono,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$ownerId/employees',
      data: {
        'nombre': nombre,
        'telefono': telefono,
      },
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      // El backend devuelve los datos en data.empleado
      final empleadoData = data['empleado'] as Map<String, dynamic>?;
      
      if (empleadoData != null) {
        return api_models.ApiResponse<EmployeeModel>(
          success: true,
          message: response.message,
          data: EmployeeModel.fromJson(empleadoData),
          statusCode: response.statusCode,
        );
      }
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar empleado de un propietario específico (solo Super Admin)
  Future<api_models.ApiResponse<EmployeeModel>> updateEmployeeForOwner(
    String ownerId,
    String employeeId, {
    String? nombre,
    String? telefono,
    bool? activo,
  }) async {
    final data = <String, dynamic>{};
    
    if (nombre != null) data['nombre'] = nombre;
    if (telefono != null) data['telefono'] = telefono;
    if (activo != null) data['activo'] = activo;

    final response = await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId',
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Activar/Desactivar empleado de un propietario específico (solo Super Admin)
  Future<api_models.ApiResponse<EmployeeModel>> toggleEmployeeForOwner(
    String ownerId,
    String employeeId,
    bool newState,
  ) async {
    final response = await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId',
      data: {
        'activo': newState,
      },
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<EmployeeModel>(
        success: true,
        message: response.message,
        data: EmployeeModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<EmployeeModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Eliminar empleado de un propietario específico (solo Super Admin)
  Future<api_models.ApiResponse<Map<String, dynamic>>> deleteEmployeeForOwner(
    String ownerId,
    String employeeId,
  ) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/$employeeId',
    );

    if (response.isSuccess) {
      return api_models.ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: {'deleted': true},
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Obtener estadísticas de empleados de un propietario específico (solo Super Admin)
  Future<api_models.ApiResponse<Map<String, dynamic>>> getEmployeeStatsForOwner(
    String ownerId,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/users/$ownerId/employees/stats',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: response.data!,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // GESTIÓN DE ROLES
  // ========================================

  /// Obtener todos los roles disponibles
  Future<api_models.ApiResponse<List<Map<String, dynamic>>>> getRoles() async {
    final response = await _apiService.get<List<dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles',
    );

    if (response.isSuccess && response.data != null) {
      final roles = response.data!
          .map((json) => json as Map<String, dynamic>)
          .toList();

      return api_models.ApiResponse<List<Map<String, dynamic>>>(
        success: true,
        message: response.message,
        data: roles,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<List<Map<String, dynamic>>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // ESTADÍSTICAS Y REPORTES
  // ========================================

  /// Obtener estadísticas generales (solo Super Admin)
  Future<api_models.ApiResponse<Map<String, dynamic>>> getStatistics() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/estadisticas-generales',
    );

    print('🔍 [UserManagementService] getStatistics response:');
    print('  Success: ${response.isSuccess}');
    print('  Message: ${response.message}');
    print('  Status Code: ${response.statusCode}');
    print('  Data: ${response.data}');

    if (response.isSuccess && response.data != null) {
      // El backend devuelve las estadísticas directamente en response.data
      return api_models.ApiResponse<Map<String, dynamic>>(
        success: true,
        message: response.message,
        data: response.data!,
        statusCode: response.statusCode,
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
