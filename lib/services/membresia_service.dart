import '../core/config/app_config.dart';
import '../services/api_service.dart';
import '../models/api_response.dart' as api_models;
import '../models/membresia_model.dart';

class MembresiaService {
  final ApiService _apiService = ApiService();

  /// Obtener todas las membresías
  Future<api_models.ApiResponse<List<MembresiaModel>>>
  getAllMembresias() async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/membresias',
    );

    if (response.isSuccess && response.data != null) {
      final dataMap = response.data!;
      // El backend devuelve { "data": { "membresias": [...] } } pero Dio interceptor puede devolver el data interno
      // Asumiendo que response.data es el payload:
      // Si adminMembresiaController retorna { success:..., data: { membresias: ... } }
      // ApiService usualmente devuelve data.

      List<dynamic> list;
      if (dataMap.containsKey('membresias')) {
        list = dataMap['membresias'];
      } else if (dataMap.containsKey('data') &&
          dataMap['data'] is Map &&
          dataMap['data'].containsKey('membresias')) {
        list = dataMap['data']['membresias'];
      } else {
        list = [];
      }

      final membresias = list
          .map((json) => MembresiaModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return api_models.ApiResponse<List<MembresiaModel>>(
        success: true,
        message: response.message,
        data: membresias,
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<List<MembresiaModel>>(
      success: false,
      message: response.message,
      data: null,
      statusCode: response.statusCode,
    );
  }

  /// Crear nueva membresía
  Future<api_models.ApiResponse<MembresiaModel>> createMembresia({
    required String nombre,
    required int meses,
    required double precio,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/membresias',
      data: {'nombre': nombre, 'meses': meses, 'precio': precio},
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<MembresiaModel>(
        success: true,
        message: response.message,
        data: MembresiaModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<MembresiaModel>(
      success: false,
      message: response.message,
      data: null,
      statusCode: response.statusCode,
    );
  }

  /// Actualizar membresía
  Future<api_models.ApiResponse<MembresiaModel>> updateMembresia(
    String id, {
    String? nombre,
    int? meses,
    double? precio,
    bool? activa,
  }) async {
    final data = <String, dynamic>{};
    if (nombre != null) data['nombre'] = nombre;
    if (meses != null) data['meses'] = meses;
    if (precio != null) data['precio'] = precio;
    if (activa != null) data['activa'] = activa;

    final response = await _apiService.put<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/membresias/$id',
      data: data,
    );

    if (response.isSuccess && response.data != null) {
      return api_models.ApiResponse<MembresiaModel>(
        success: true,
        message: response.message,
        data: MembresiaModel.fromJson(response.data!),
        statusCode: response.statusCode,
      );
    }

    return api_models.ApiResponse<MembresiaModel>(
      success: false,
      message: response.message,
      data: null,
      statusCode: response.statusCode,
    );
  }

  /// Eliminar membresía (soft delete)
  Future<api_models.ApiResponse<void>> deleteMembresia(String id) async {
    final response = await _apiService.delete(
      '${AppConfig.superAdminEndpoint}/membresias/$id',
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      data: null,
      statusCode: response.statusCode,
    );
  }

  /// Toggle estado activo
  Future<api_models.ApiResponse<MembresiaModel>> toggleActiva(
    String id,
    bool activa,
  ) async {
    return updateMembresia(id, activa: activa);
  }

  /// Obtener estado de membresía de un usuario
  Future<api_models.ApiResponse<Map<String, dynamic>>> getUserMembershipStatus(
    String userId,
  ) async {
    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/usuarios/$userId/membresias/status',
    );

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: response.isSuccess,
      message: response.message,
      data: response.data,
      statusCode: response.statusCode,
    );
  }

  /// Asignar o renovar membresía a un usuario
  Future<api_models.ApiResponse<void>> assignMembership({
    required String userId,
    required String membresiaId,
  }) async {
    final response = await _apiService.post<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/usuarios/membresias/assign',
      data: {'usuarioId': userId, 'membresiaId': membresiaId},
    );

    return api_models.ApiResponse<void>(
      success: response.isSuccess,
      message: response.message,
      data: null,
      statusCode: response.statusCode,
    );
  }

  /// Obtener reportes de membresías con filtros
  Future<api_models.ApiResponse<Map<String, dynamic>>> getMembershipReports({
    String filter = 'all',
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'filter': filter,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    final response = await _apiService.get<Map<String, dynamic>>(
      '${AppConfig.superAdminEndpoint}/membership-reports',
      queryParameters: queryParams,
    );

    return api_models.ApiResponse<Map<String, dynamic>>(
      success: response.isSuccess,
      message: response.message,
      data: response.data,
      statusCode: response.statusCode,
    );
  }
}
