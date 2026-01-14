/// Modelo para empleado compatible con el backend
class EmployeeModel {
  final String id;
  final String usuarioId;
  final String nombre;
  final String telefono;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? notificacionesActivas; // From ConfiguracionNotificacion

  const EmployeeModel({
    required this.id,
    required this.usuarioId,
    required this.nombre,
    required this.telefono,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
    this.notificacionesActivas,
  });

  /// Crear desde JSON
  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    return EmployeeModel(
      id: json['id'] ?? '',
      usuarioId: json['usuarioId'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      activo: json['activo'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      notificacionesActivas: json['activo'] ?? false,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'usuarioId': usuarioId,
      'nombre': nombre,
      'telefono': telefono,
      'activo': activo,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'configuracionNotificacion': notificacionesActivas != null
          ? {'notificacionesActivas': notificacionesActivas}
          : null,
    };
  }

  /// Copiar con cambios
  EmployeeModel copyWith({
    String? id,
    String? usuarioId,
    String? nombre,
    String? telefono,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? notificacionesActivas,
  }) {
    return EmployeeModel(
      id: id ?? this.id,
      usuarioId: usuarioId ?? this.usuarioId,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notificacionesActivas:
          notificacionesActivas ?? this.notificacionesActivas,
    );
  }

  /// Obtener iniciales del nombre
  String get initials {
    final names = nombre.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'E';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmployeeModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EmployeeModel(id: $id, nombre: $nombre, telefono: $telefono)';
}
