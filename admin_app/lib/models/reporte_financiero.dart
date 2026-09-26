class IngresosDetalle {
  final double cursos;
  final double servicios;
  final double productos;

  IngresosDetalle({
    required this.cursos,
    required this.servicios,
    required this.productos,
  });

  factory IngresosDetalle.fromJson(Map<String, dynamic> json) {
    return IngresosDetalle(
      cursos: (json['cursos'] is num)
          ? (json['cursos'] as num).toDouble()
          : double.tryParse(json['cursos']?.toString() ?? '0') ?? 0.0,
      servicios: (json['servicios'] is num)
          ? (json['servicios'] as num).toDouble()
          : double.tryParse(json['servicios']?.toString() ?? '0') ?? 0.0,
      productos: (json['productos'] is num)
          ? (json['productos'] as num).toDouble()
          : double.tryParse(json['productos']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class ReporteFinanciero {
  final bool ok;
  final String periodo;
  final IngresosDetalle ingresos;
  final double totalIngresos;
  final double totalGastos;
  final double gananciaRealProductos;
  final double balanceNeto;
  final String mensaje;

  ReporteFinanciero({
    required this.ok,
    required this.periodo,
    required this.ingresos,
    required this.totalIngresos,
    required this.totalGastos,
    required this.gananciaRealProductos,
    required this.balanceNeto,
    required this.mensaje,
  });

  factory ReporteFinanciero.fromJson(Map<String, dynamic> json) {
    return ReporteFinanciero(
      ok: json['ok'] ?? true,
      periodo: json['periodo']?.toString() ?? 'Mes Actual',
      ingresos: json['ingresos'] != null
          ? IngresosDetalle.fromJson(json['ingresos'] as Map<String, dynamic>)
          : IngresosDetalle(cursos: 0, servicios: 0, productos: 0),
      totalIngresos: (json['total_ingresos'] is num)
          ? (json['total_ingresos'] as num).toDouble()
          : double.tryParse(json['total_ingresos']?.toString() ?? '0') ?? 0.0,
      totalGastos: (json['total_gastos'] is num)
          ? (json['total_gastos'] as num).toDouble()
          : double.tryParse(json['total_gastos']?.toString() ?? '0') ?? 0.0,
      gananciaRealProductos: (json['ganancia_real_productos'] is num)
          ? (json['ganancia_real_productos'] as num).toDouble()
          : double.tryParse(json['ganancia_real_productos']?.toString() ?? '0') ?? 0.0,
      balanceNeto: (json['balance_neto'] is num)
          ? (json['balance_neto'] as num).toDouble()
          : double.tryParse(json['balance_neto']?.toString() ?? '0') ?? 0.0,
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }
}
