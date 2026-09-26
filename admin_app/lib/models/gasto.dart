class Gasto {
  final String id;
  final String fecha;
  final String? concepto;
  final double monto;
  final String categoria; // 'arriendo' | 'servicios' | 'productos' | 'comida' | 'transporte' | 'otros'

  Gasto({
    required this.id,
    required this.fecha,
    this.concepto,
    required this.monto,
    required this.categoria,
  });

  factory Gasto.fromJson(Map<String, dynamic> json) {
    return Gasto(
      id: json['id']?.toString() ?? '',
      fecha: json['fecha']?.toString() ?? '',
      concepto: json['concepto']?.toString(),
      monto: (json['monto'] is num)
          ? (json['monto'] as num).toDouble()
          : double.tryParse(json['monto']?.toString() ?? '0') ?? 0.0,
      categoria: json['categoria']?.toString() ?? 'otros',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'concepto': concepto,
      'monto': monto,
      'categoria': categoria,
    };
  }
}
