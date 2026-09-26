class VentaProducto {
  final String id;
  final String fecha;
  final String nombreProducto;
  final String? nombreCliente;
  final double precioCosto;
  final double precioVenta;
  final int cantidad;
  final double? ganancia;

  VentaProducto({
    required this.id,
    required this.fecha,
    required this.nombreProducto,
    this.nombreCliente,
    required this.precioCosto,
    required this.precioVenta,
    this.cantidad = 1,
    this.ganancia,
  });

  factory VentaProducto.fromJson(Map<String, dynamic> json) {
    return VentaProducto(
      id: json['id']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      nombreProducto: json['nombre_producto']?.toString() ?? json['nombre']?.toString() ?? '',
      nombreCliente: json['nombre_cliente']?.toString(),
      precioCosto: (json['precio_costo'] is num)
          ? (json['precio_costo'] as num).toDouble()
          : (json['costo'] is num)
              ? (json['costo'] as num).toDouble()
              : double.tryParse(json['precio_costo']?.toString() ?? json['costo']?.toString() ?? '0') ?? 0.0,
      precioVenta: (json['precio_venta'] is num)
          ? (json['precio_venta'] as num).toDouble()
          : (json['precio'] is num)
              ? (json['precio'] as num).toDouble()
              : double.tryParse(json['precio_venta']?.toString() ?? json['precio']?.toString() ?? '0') ?? 0.0,
      cantidad: (json['cantidad'] is num)
          ? (json['cantidad'] as num).toInt()
          : int.tryParse(json['cantidad']?.toString() ?? '1') ?? 1,
      ganancia: json['ganancia'] != null
          ? (json['ganancia'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'nombre_producto': nombreProducto,
      'nombre_cliente': nombreCliente,
      'precio_costo': precioCosto,
      'precio_venta': precioVenta,
      'cantidad': cantidad,
      'ganancia': ganancia,
    };
  }
}
