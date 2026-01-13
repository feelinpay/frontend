class MembresiaModel {
  final String id;
  final String nombre;
  final int meses;
  final double precio;
  final bool activa;
  final DateTime createdAt;
  final DateTime updatedAt;

  MembresiaModel({
    required this.id,
    required this.nombre,
    required this.meses,
    required this.precio,
    required this.activa,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MembresiaModel.fromJson(Map<String, dynamic> json) {
    return MembresiaModel(
      id: json['id'],
      nombre: json['nombre'],
      meses: json['meses'],
      precio: (json['precio'] as num).toDouble(),
      activa: json['activa'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'meses': meses,
      'precio': precio,
      'activa': activa,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get duracionTexto {
    if (meses == 1) return '1 mes';
    return '$meses meses';
  }

  String get precioFormateado {
    return 'S/ ${precio.toStringAsFixed(2)}';
  }
}
