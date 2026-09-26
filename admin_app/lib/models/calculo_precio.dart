class ItemCalculo {
  final num cantidad;
  final double precioUnitario;
  final double subtotal;

  ItemCalculo({
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  factory ItemCalculo.fromJson(Map<String, dynamic> json, String qtyKey) {
    return ItemCalculo(
      cantidad: (json[qtyKey] is num)
          ? (json[qtyKey] as num)
          : num.tryParse(json[qtyKey]?.toString() ?? '0') ?? 0,
      precioUnitario: (json['precio_unitario'] is num)
          ? (json['precio_unitario'] as num).toDouble()
          : (json['precio_hora'] is num)
              ? (json['precio_hora'] as num).toDouble()
              : double.tryParse(json['precio_unitario']?.toString() ?? json['precio_hora']?.toString() ?? '0') ?? 0.0,
      subtotal: (json['subtotal'] is num)
          ? (json['subtotal'] as num).toDouble()
          : double.tryParse(json['subtotal']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class DesgloseCalculadora {
  final ItemCalculo decolorante;
  final ItemCalculo tinte;
  final ItemCalculo peroxido;
  final double costoTotalMateriales;
  final String multiplicador;
  final double materialesConMargen;
  final ItemCalculo manoDeObra;

  DesgloseCalculadora({
    required this.decolorante,
    required this.tinte,
    required this.peroxido,
    required this.costoTotalMateriales,
    required this.multiplicador,
    required this.materialesConMargen,
    required this.manoDeObra,
  });

  factory DesgloseCalculadora.fromJson(Map<String, dynamic> json) {
    return DesgloseCalculadora(
      decolorante: ItemCalculo.fromJson(json['decolorante'] as Map<String, dynamic>? ?? {}, 'porciones'),
      tinte: ItemCalculo.fromJson(json['tinte'] as Map<String, dynamic>? ?? {}, 'tubos'),
      peroxido: ItemCalculo.fromJson(json['peroxido'] as Map<String, dynamic>? ?? {}, 'mezclas'),
      costoTotalMateriales: (json['costo_total_materiales'] is num)
          ? (json['costo_total_materiales'] as num).toDouble()
          : double.tryParse(json['costo_total_materiales']?.toString() ?? '0') ?? 0.0,
      multiplicador: json['multiplicador']?.toString() ?? '2.5x',
      materialesConMargen: (json['materiales_con_margen'] is num)
          ? (json['materiales_con_margen'] as num).toDouble()
          : double.tryParse(json['materiales_con_margen']?.toString() ?? '0') ?? 0.0,
      manoDeObra: ItemCalculo.fromJson(json['mano_de_obra'] as Map<String, dynamic>? ?? {}, 'horas'),
    );
  }
}

class CalculoPrecioResult {
  final bool ok;
  final DesgloseCalculadora? desglose;
  final double precioFinal;
  final String mensaje;

  CalculoPrecioResult({
    required this.ok,
    this.desglose,
    required this.precioFinal,
    required this.mensaje,
  });

  factory CalculoPrecioResult.fromJson(Map<String, dynamic> json) {
    return CalculoPrecioResult(
      ok: json['ok'] ?? true,
      desglose: json['desglose'] != null
          ? DesgloseCalculadora.fromJson(json['desglose'] as Map<String, dynamic>)
          : null,
      precioFinal: (json['PRECIO_FINAL'] is num)
          ? (json['PRECIO_FINAL'] as num).toDouble()
          : (json['precio_final'] is num)
              ? (json['precio_final'] as num).toDouble()
              : double.tryParse(json['PRECIO_FINAL']?.toString() ?? json['precio_final']?.toString() ?? '0') ?? 0.0,
      mensaje: json['mensaje']?.toString() ?? '',
    );
  }
}
