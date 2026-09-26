class GaleriaItem {
  final String id;
  final String createdAt;
  final String titulo;
  final String categoria;
  final String imagenUrl;
  final String? descripcion;
  final bool destacado;

  GaleriaItem({
    required this.id,
    required this.createdAt,
    required this.titulo,
    required this.categoria,
    required this.imagenUrl,
    this.descripcion,
    this.destacado = false,
  });

  factory GaleriaItem.fromJson(Map<String, dynamic> json) {
    return GaleriaItem(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      titulo: json['titulo']?.toString() ?? '',
      categoria: json['categoria']?.toString() ?? 'General',
      imagenUrl: json['imagen_url']?.toString() ?? '',
      descripcion: json['descripcion']?.toString(),
      destacado: json['destacado'] ?? false,
    );
  }
}
