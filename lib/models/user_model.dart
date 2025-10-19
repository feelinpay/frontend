/// User Model - Modelo simple para usuario
class UserModel {
  final String id;
  final String nombre;
  final String telefono;
  final String email;
  final String rolId;
  final String? rol;
  final bool activo;
  final bool enPeriodoPrueba;
  final int diasPruebaRestantes;
  final bool emailVerificado;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.nombre,
    required this.telefono,
    required this.email,
    required this.rolId,
    this.rol,
    required this.activo,
    required this.enPeriodoPrueba,
    required this.diasPruebaRestantes,
    required this.emailVerificado,
    required this.createdAt,
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
      rol: json['rol'],
      activo: json['activo'] ?? false,
      enPeriodoPrueba: json['enPeriodoPrueba'] ?? false,
      diasPruebaRestantes: json['diasPruebaRestantes'] ?? 0,
      emailVerificado: json['emailVerificado'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
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
      'activo': activo,
      'enPeriodoPrueba': enPeriodoPrueba,
      'diasPruebaRestantes': diasPruebaRestantes,
      'emailVerificado': emailVerificado,
      'createdAt': createdAt.toIso8601String(),
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
    bool? activo,
    bool? enPeriodoPrueba,
    int? diasPruebaRestantes,
    bool? emailVerificado,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      rolId: rolId ?? this.rolId,
      rol: rol ?? this.rol,
      activo: activo ?? this.activo,
      enPeriodoPrueba: enPeriodoPrueba ?? this.enPeriodoPrueba,
      diasPruebaRestantes: diasPruebaRestantes ?? this.diasPruebaRestantes,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      createdAt: createdAt ?? this.createdAt,
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
  bool get isSuperAdmin => rol == 'super_admin';
}
