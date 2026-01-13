class PermisoModel {
  final String id;
  final String nombre;
  final String? descripcion;
  final String modulo;
  final String? accion;
  final String? ruta;
  final bool activo;

  PermisoModel({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.modulo,
    this.accion,
    this.ruta,
    required this.activo,
  });

  factory PermisoModel.fromJson(Map<String, dynamic> json) {
    return PermisoModel(
      id: json['id'],
      nombre: json['nombre'],
      descripcion: json['descripcion'],
      modulo: json['modulo'],
      accion: json['accion'] ?? 'read',
      ruta: json['ruta'],
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'modulo': modulo,
      'accion': accion,
      'ruta': ruta,
      'activo': activo,
    };
  }
}
