import 'permission_model.dart';

/// User Model - Modelo para usuario compatible con el backend
class UserModel {
  final String id;
  final String nombre;
  final String email;
  final String rolId;
  final String? rol;
  final String? rolNombre; // Nombre del rol desde la relación
  final String? imagen; // NEW: Profile image URL
  final bool activo;
  final bool enPeriodoPrueba;
  final DateTime? fechaInicioPrueba; // NEW
  final DateTime? fechaFinPrueba; // NEW
  final int diasPruebaRestantes;
  final bool emailVerificado;
  final DateTime? emailVerificadoAt;
  final String? googleDriveFolderId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastLoginAt;
  final List<Permission> permissions; // NEW: List of Permission objects

  const UserModel({
    required this.id,
    required this.nombre,
    required this.email,
    required this.rolId,
    this.rol,
    this.rolNombre,
    this.imagen,
    required this.activo,
    required this.enPeriodoPrueba,
    this.fechaInicioPrueba,
    this.fechaFinPrueba,
    required this.diasPruebaRestantes,
    required this.emailVerificado,
    this.emailVerificadoAt,
    this.googleDriveFolderId,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginAt,
    this.permissions = const [], // Default empty
  });

  /// Crear desde JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse Dates first to use in calculation
    final fechaInicio = json['fechaInicioPrueba'] != null
        ? DateTime.parse(json['fechaInicioPrueba'])
        : null;

    final fechaFin = json['fechaFinPrueba'] != null
        ? DateTime.parse(json['fechaFinPrueba'])
        : null;

    // Calculate trial status if not provided
    bool enPrueba = json['enPeriodoPrueba'] ?? false;
    int diasRestantes = json['diasPruebaRestantes'] ?? 0;

    if (fechaFin != null && json['enPeriodoPrueba'] == null) {
      final now = DateTime.now();
      if (fechaFin.isAfter(now)) {
        enPrueba = true;
        diasRestantes = fechaFin.difference(now).inDays;
      } else {
        enPrueba = false; // Expired
        diasRestantes = 0;
      }
    }

    // Parse permissions safely
    List<Permission> parsedPermissions = [];
    if (json['rol'] != null && json['rol']['permisos'] != null) {
      final rolPermisos = json['rol']['permisos'];
      if (rolPermisos is List) {
        for (var rp in rolPermisos) {
          if (rp is Map && rp['permiso'] != null) {
            parsedPermissions.add(Permission.fromJson(rp['permiso']));
          }
        }
      }
    }

    return UserModel(
      id: json['id'] ?? '',
      nombre: json['nombre'] ?? '',
      email: json['email'] ?? '',
      rolId: json['rolId'] ?? '',
      rol: json['rol'] is Map ? json['rol']['nombre'] : json['rol']?.toString(),
      rolNombre: json['rol'] is Map
          ? json['rol']['nombre']
          : json['rolNombre']?.toString(),
      imagen: json['imagen'],
      activo: json['activo'] ?? false,
      enPeriodoPrueba: enPrueba,
      fechaInicioPrueba: fechaInicio,
      fechaFinPrueba: fechaFin,
      diasPruebaRestantes: diasRestantes,
      emailVerificado: json['emailVerificado'] ?? false,
      emailVerificadoAt: json['emailVerificadoAt'] != null
          ? DateTime.parse(json['emailVerificadoAt'])
          : null,
      googleDriveFolderId: json['googleDriveFolderId'], // Parse nullable
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      permissions: parsedPermissions,
    );
  }

  /// Convertir a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'rolId': rolId,
      'rol': rol,
      'rolNombre': rolNombre,
      'imagen': imagen,
      'activo': activo,
      'enPeriodoPrueba': enPeriodoPrueba,
      'fechaInicioPrueba': fechaInicioPrueba?.toIso8601String(),
      'fechaFinPrueba': fechaFinPrueba?.toIso8601String(), // NEW
      'diasPruebaRestantes': diasPruebaRestantes,
      'emailVerificado': emailVerificado,
      'emailVerificadoAt': emailVerificadoAt?.toIso8601String(),
      'googleDriveFolderId': googleDriveFolderId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'permisos': permissions.map((p) => p.toJson()).toList(),
    };
  }

  /// Copiar con cambios
  UserModel copyWith({
    String? id,
    String? nombre,
    String? email,
    String? rolId,
    String? rol,
    String? rolNombre,
    String? imagen,
    bool? activo,
    bool? enPeriodoPrueba,
    DateTime? fechaInicioPrueba,
    DateTime? fechaFinPrueba, // NEW
    int? diasPruebaRestantes,
    bool? emailVerificado,
    DateTime? emailVerificadoAt,
    String? googleDriveFolderId,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    List<Permission>? permissions,
  }) {
    return UserModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      rolId: rolId ?? this.rolId,
      rol: rol ?? this.rol,
      rolNombre: rolNombre ?? this.rolNombre,
      imagen: imagen ?? this.imagen,
      activo: activo ?? this.activo,
      enPeriodoPrueba: enPeriodoPrueba ?? this.enPeriodoPrueba,
      fechaInicioPrueba: fechaInicioPrueba ?? this.fechaInicioPrueba,
      fechaFinPrueba: fechaFinPrueba ?? this.fechaFinPrueba, // NEW
      diasPruebaRestantes: diasPruebaRestantes ?? this.diasPruebaRestantes,
      emailVerificado: emailVerificado ?? this.emailVerificado,
      emailVerificadoAt: emailVerificadoAt ?? this.emailVerificadoAt,
      googleDriveFolderId: googleDriveFolderId ?? this.googleDriveFolderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      permissions: permissions ?? this.permissions,
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

  /// check permission
  bool hasPermission(String permissionName) {
    // Check against display name or legacy slug if needed.
    // Seeder uses Display Names now (e.g., "Gestión de Usuarios")
    return permissions.any((p) => p.nombre == permissionName);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, nombre: $nombre, email: $email, permissions: ${permissions.length})';

  // Getters adicionales
  bool get isSuperAdmin => rol == 'super_admin' || rolNombre == 'super_admin';

  /// Obtener URL de la carpeta de Drive
  String? get googleDriveFolderUrl {
    if (googleDriveFolderId == null || googleDriveFolderId!.isEmpty) {
      return null;
    }
    return 'https://drive.google.com/drive/folders/$googleDriveFolderId';
  }
}
