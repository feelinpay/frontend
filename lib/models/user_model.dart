/// User Model - Modelo para usuario compatible con el backend
class UserModel {
  final String id;
  final String nombre;
  final String telefono;
  final String email;
  final String rolId;
  final String? rol;
  final String? rolNombre; // Nombre del rol desde la relación
  final bool activo;
  final bool enPeriodoPrueba;
  final DateTime? fechaInicioPrueba;
  final int diasPruebaRestantes;
  final bool emailVerificado;
  final DateTime? emailVerificadoAt;
  final String googleSpreadsheetId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.rolId,
    this.rol,
    this.rolNombre,
    required this.activo,
    required this.enPeriodoPrueba,
    this.fechaInicioPrueba,
    required this.diasPruebaRestantes,
    required this.emailVerificado,
    this.emailVerificadoAt,
    required this.googleSpreadsheetId,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
  });

  /// Crear desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      rolId: json['rolId'] ?? '',
      rol: json['rol'] is Map ? json['rol']['nombre'] : json['rol'],
      rolNombre: json['rol'] is Map ? json['rol']['nombre'] : json['rolNombre'],
      activo: json['activo'] ?? false,
      enPeriodoPrueba: json['enPeriodoPrueba'] ?? false,
      fechaInicioPrueba: json['fechaInicioPrueba'] != null
          ? DateTime.parse(json['fechaInicioPrueba'])
          : null,
      diasPruebaRestantes: json['diasPruebaRestantes'] ?? 0,
      emailVerificado: json['emailVerificado'] ?? false,
      emailVerificadoAt: json['emailVerificadoAt'] != null
          ? DateTime.parse(json['emailVerificadoAt'])
          : null,
      googleSpreadsheetId: json['googleSpreadsheetId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'rolId': rolId,
      'rol': rol,
      'rolNombre': rolNombre,
      'activo': activo,
      'enPeriodoPrueba': enPeriodoPrueba,
      'fechaInicioPrueba': fechaInicioPrueba?.toIso8601String(),
      'diasPruebaRestantes': diasPruebaRestantes,
      'emailVerificado': emailVerificado,
      'emailVerificadoAt': emailVerificadoAt?.toIso8601String(),
      'googleSpreadsheetId': googleSpreadsheetId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
    };
  }

  /// Copiar con cambios
  UserModel copyWith({
    String? id,
    String? nombre,
    String? telefono,
    String? email,
    String? rolId,
    String? rol,
    String? rolNombre,
    bool? activo,
    bool? enPeriodoPrueba,
    DateTime? fechaInicioPrueba,
    int? diasPruebaRestantes,
    bool? emailVerificado,
    DateTime? emailVerificadoAt,
    String? googleSpreadsheetId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      rolId: rolId ?? this.rolId,
      rol: rol ?? this.rol,
      rolNombre: rolNombre ?? this.rolNombre,
      activo: activo ?? this.activo,
      enPeriodoPrueba: enPeriodoPrueba ?? this.enPeriodoPrueba,
      fechaInicioPrueba: fechaInicioPrueba ?? this.fechaInicioPrueba,
      diasPruebaRestantes: diasPruebaRestantes ?? this.diasPruebaRestantes,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      emailVerificadoAt: emailVerificadoAt ?? this.emailVerificadoAt,
      googleSpreadsheetId: googleSpreadsheetId ?? this.googleSpreadsheetId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Obtener iniciales del nombre
  String get initials {
    final names = nombre.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return nombre.isNotEmpty ? nombre[0].toUpperCase() : 'U';
  }

  /// Verificar si está en período de prueba
  bool get isInTrial => enPeriodoPrueba && diasPruebaRestantes > 0;

  /// Verificar si la licencia está activa (ahora basado en membresía)
  bool get hasActiveLicense => !enPeriodoPrueba;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'UserModel(id: $id, nombre: $nombre, email: $email)';

  // Getters adicionales
  bool get isSuperAdmin => rol == 'super_admin' || rolNombre == 'super_admin';
}
