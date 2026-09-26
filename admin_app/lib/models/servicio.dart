class Servicio {
  final String id;
  final String? createdAt;
  final String nombre;
  final String categoria;
  final String? descripcion;
  final int duracionMinutos;
  final double precioBase;
  final String? imagenUrl;
  final bool activo;

  Servicio({
    required this.id,
    this.createdAt,
    required this.nombre,
    required this.categoria,
    this.descripcion,
    required this.duracionMinutos,
    required this.precioBase,
    this.imagenUrl,
    this.activo = true,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      nombre: json['nombre']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'otro',
      descripcion: json['descripcion']?.toString(),
      duracionMinutos: (json['duracion_minutos'] is num)
          ? (json['duracion_minutos'] as num).toInt()
          : int.tryParse(json['duracion_minutos']?.toString() ?? '60') ?? 60,
      precioBase: (json['precio_base'] is num)
          ? (json['precio_base'] as num).toDouble()
          : double.tryParse(json['precio_base']?.toString() ?? '0') ?? 0.0,
      imagenUrl: json['imagen_url']?.toString(),
      activo: json['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'categoria': categoria,
      'descripcion': descripcion,
      'duracion_minutos': duracionMinutos,
      'precio_base': precioBase,
      'imagen_url': imagenUrl,
      'activo': activo,
    };
  }
}
