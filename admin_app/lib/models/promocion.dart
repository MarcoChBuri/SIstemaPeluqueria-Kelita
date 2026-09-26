class Promocion {
  final String id;
  final String? createdAt;
  final String titulo;
  final String? descripcion;
  final double? porcentajeDescuento;
  final double? montoDescuento;
  final String fechaInicio;
  final String fechaFin;
  final String? imagenUrl;
  final bool activa;

  Promocion({
    required this.id,
    this.createdAt,
    required this.titulo,
    this.descripcion,
    this.porcentajeDescuento,
    this.montoDescuento,
    required this.fechaInicio,
    required this.fechaFin,
    this.imagenUrl,
    this.activa = true,
  });

  factory Promocion.fromJson(Map<String, dynamic> json) {
    return Promocion(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      porcentajeDescuento: json['porcentaje_descuento'] != null
          ? (json['porcentaje_descuento'] as num).toDouble()
          : null,
      montoDescuento: json['monto_descuento'] != null
          ? (json['monto_descuento'] as num).toDouble()
          : null,
      fechaInicio: json['fecha_inicio']?.toString() ?? '',
      fechaFin: json['fecha_fin']?.toString() ?? '',
      imagenUrl: json['imagen_url']?.toString(),
      activa: json['activa'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'porcentaje_descuento': porcentajeDescuento,
      'monto_descuento': montoDescuento,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'imagen_url': imagenUrl,
      'activa': activa,
    };
  }
}
