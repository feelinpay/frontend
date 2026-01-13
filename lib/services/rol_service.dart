import '../models/rol_model.dart';
import '../models/permiso_model.dart';
import '../models/api_response.dart' as api_models;
import '../core/config/app_config.dart';
import 'api_service.dart';

class RolService {
  final ApiService _apiService = ApiService();

  // ========================================
  // GESTIÓN DE ROLES
  // ========================================

  /// Obtener todos los roles
  Future<api_models.ApiResponse<List<RolModel>>> getRoles({
    int page = 1,
    int limit = 50,
    String? search,
    bool? activo,
  }) async {
    final queryParams = <String, dynamic>{'page': page, 'limit': limit};

    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    if (activo != null) {
      queryParams['activo'] = activo;
    }

    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles',
      queryParameters: queryParams,
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      List<dynamic> rolesList = [];

      if (data.containsKey('roles')) {
        rolesList = data['roles'] as List<dynamic>;
      } else if (data.containsKey('data')) {
        final innerData = data['data'];
        if (innerData is Map && innerData.containsKey('roles')) {
          rolesList = innerData['roles'] as List<dynamic>;
        } else if (innerData is List) {
          rolesList = innerData;
        }
      } else if (data is List) {
        // This case is unlikely if data is Map<String, dynamic> but good for safety
        rolesList = data as List<dynamic>;
      }

      final roles = rolesList
          .map((json) => RolModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<RolModel>>(
        success: true,
        message: response.message,
        data: roles,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<List<RolModel>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Obtener rol por ID
  Future<api_models.ApiResponse<RolModel>> getRoleById(String id) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles/$id',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<RolModel>(
        success: true,
        message: response.message,
        data: RolModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<RolModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Crear nuevo rol
  Future<api_models.ApiResponse<RolModel>> createRole({
    required String nombre,
    required String descripcion,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles',
      data: {'nombre': nombre, 'descripcion': descripcion},
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<RolModel>(
        success: true,
        message: response.message,
        data: RolModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<RolModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar rol
  Future<api_models.ApiResponse<RolModel>> updateRole(
    String id, {
    String? nombre,
    String? descripcion,
    bool? activo,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (descripcion != null) data['descripcion'] = descripcion;
    if (activo != null) data['activo'] = activo;

    final response = await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles/$id',
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<RolModel>(
        success: true,
        message: response.message,
        data: RolModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<RolModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Eliminar rol
  Future<api_models.ApiResponse<void>> deleteRole(String id) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles/$id',
    );

    if (response.isSuccess) {
      return api_models.ApiResponse<void>(
        success: true,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<void>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  // ========================================
  // ASIGNACIÓN DE PERMISOS
  // ========================================

  /// Obtener todos los permisos disponibles (para mostrarlos en la UI de asignación)
  Future<api_models.ApiResponse<List<PermisoModel>>> getAllPermissions() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/permisos',
      queryParameters: {'limit': 1000}, // Obtener todos
    );

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      List<dynamic> list = [];

      if (data.containsKey('permisos')) {
        list = data['permisos'] as List<dynamic>;
      } else if (data.containsKey('data')) {
        final innerData = data['data'];
        if (innerData is Map && innerData.containsKey('permisos')) {
          list = innerData['permisos'] as List<dynamic>;
        } else if (innerData is List) {
          list = innerData;
        }
      } else if (data is List) {
        list = data as List<dynamic>;
      }

      final permisos = list
          .map((json) => PermisoModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<PermisoModel>>(
        success: true,
        message: response.message,
        data: permisos,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<List<PermisoModel>>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Obtener rol CON permisos
  Future<api_models.ApiResponse<RolModel>> getRoleWithPermissions(
    String id,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles/$id/permisos',
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<RolModel>(
        success: true,
        message: response.message,
        data: RolModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<RolModel>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Asignar permiso a rol
  Future<api_models.ApiResponse<void>> assignPermission(
    String roleId,
    String permissionId,
  ) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles/$roleId/permisos',
      data: {'permisoId': permissionId},
    );

    if (response.isSuccess) {
      return api_models.ApiResponse<void>(
        success: true,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<void>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }

  /// Desasignar permiso de rol
  Future<api_models.ApiResponse<void>> removePermission(
    String roleId,
    String permissionId,
  ) async {
    final response = await _apiService.delete<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/roles/$roleId/permisos',
      data: {'permisoId': permissionId},
    );

    if (response.isSuccess) {
      return api_models.ApiResponse<void>(
        success: true,
        message: response.message,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<void>(
      success: false,
      message: response.message,
      errors: response.errors,
      statusCode: response.statusCode,
    );
  }
}
