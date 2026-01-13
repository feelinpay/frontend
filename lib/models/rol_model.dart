import 'permiso_model.dart';

class RolModel {
  final String id;
  final String nombre;
  final String descripcion;
  final bool activo;
  final List<PermisoModel> permisos;

  RolModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.activo,
    this.permisos = const [],
  });

  factory RolModel.fromJson(Map<String, dynamic> json) {
    return RolModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      activo: json['activo'] ?? true,
      permisos: json['permisos'] != null
          ? (json['permisos'] as List).map((p) {
              // Si viene como objeto anidado rol_permiso -> permiso
              if (p['permiso'] != null) {
                return PermisoModel.fromJson(p['permiso']);
              }
              // Si viene directo
              return PermisoModel.fromJson(p);
            }).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'activo': activo,
      'permisos': permisos.map((p) => p.toJson()).toList(),
    };
  }
}
