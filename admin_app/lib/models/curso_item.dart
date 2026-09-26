class CursoItem {
  final String id;
  final String createdAt;
  final String titulo;
  final String descripcion;
  final double precioReferencia;
  final String? imagenUrl;
  final String linkHotmart;
  final bool activo;

  CursoItem({
    required this.id,
    required this.createdAt,
    required this.titulo,
    required this.descripcion,
    required this.precioReferencia,
    this.imagenUrl,
    required this.linkHotmart,
    this.activo = true,
  });

  factory CursoItem.fromJson(Map<String, dynamic> json) {
    return CursoItem(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      descripcion: json['descripcion']?.toString() ?? '',
      precioReferencia: (json['precio_referencia'] is num)
          ? (json['precio_referencia'] as num).toDouble()
          : double.tryParse(json['precio_referencia']?.toString() ?? '0') ?? 0.0,
      imagenUrl: json['imagen_url']?.toString(),
      linkHotmart: json['link_hotmart']?.toString() ?? '',
      activo: json['activo'] ?? true,
    );
  }
}
