class Permission {
  final String nombre;
  final String modulo;
  final String? ruta;

  const Permission({required this.nombre, required this.modulo, this.ruta});

  factory Permission.fromJson(Map<String, dynamic> json) {
    return Permission(
      nombre: json['nombre'] ?? '',
      modulo: json['modulo'] ?? '',
      ruta: json['ruta'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'nombre': nombre, 'modulo': modulo, 'ruta': ruta};
  }
}
