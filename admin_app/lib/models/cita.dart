class CitaServicioInfo {
  final String nombre;
  final int duracionMinutos;
  final String categoria;

  CitaServicioInfo({
    required this.nombre,
    required this.duracionMinutos,
    required this.categoria,
  });

  factory CitaServicioInfo.fromJson(Map<String, dynamic> json) {
    return CitaServicioInfo(
      nombre: json['nombre']?.toString() ?? '',
      duracionMinutos: (json['duracion_minutos'] is num)
          ? (json['duracion_minutos'] as num).toInt()
          : int.tryParse(json['duracion_minutos']?.toString() ?? '60') ?? 60,
      categoria: json['categoria']?.toString() ?? '',
    );
  }
}

class CitaPromocionInfo {
  final String titulo;
  final double? porcentajeDescuento;

  CitaPromocionInfo({
    required this.titulo,
    this.porcentajeDescuento,
  });

  factory CitaPromocionInfo.fromJson(Map<String, dynamic> json) {
    return CitaPromocionInfo(
      titulo: json['titulo']?.toString() ?? '',
      porcentajeDescuento: json['porcentaje_descuento'] != null
          ? (json['porcentaje_descuento'] as num).toDouble()
          : null,
    );
  }
}

class Cita {
  final String id;
  final String? createdAt;
  final String clienteNombre;
  final String clienteTelefono;
  final String? clienteEmail;
  final String servicioId;
  final String? promocionId;
  final String fechaCita;
  final String horaInicio;
  final String horaFin;
  final String estado; // 'pendiente' | 'confirmada' | 'completada' | 'cancelada'
  final String estadoPago; // 'pendiente' | 'pagado'
  final double precioOriginal;
  final double descuentoAplicado;
  final double precioFinal;
  final String? notas;
  final CitaServicioInfo? servicios;
  final CitaPromocionInfo? promociones;

  bool get isPagada => estadoPago == 'pagado' || estado == 'realizada' || estado == 'completada';

  Cita({
    required this.id,
    this.createdAt,
    required this.clienteNombre,
    required this.clienteTelefono,
    this.clienteEmail,
    required this.servicioId,
    this.promocionId,
    required this.fechaCita,
    required this.horaInicio,
    required this.horaFin,
    required this.estado,
    required this.estadoPago,
    required this.precioOriginal,
    required this.descuentoAplicado,
    required this.precioFinal,
    this.notas,
    this.servicios,
    this.promociones,
  });

  factory Cita.fromJson(Map<String, dynamic> json) {
    return Cita(
      id: json['id']?.toString() ?? '',
      createdAt: json['created_at']?.toString(),
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      clienteTelefono: json['cliente_telefono']?.toString() ?? '',
      clienteEmail: json['cliente_email']?.toString(),
      servicioId: json['servicio_id']?.toString() ?? '',
      promocionId: json['promocion_id']?.toString(),
      fechaCita: json['fecha_cita']?.toString().split('T')[0].split(' ')[0] ?? '',
      horaInicio: json['hora_inicio']?.toString() ?? '',
      horaFin: json['hora_fin']?.toString() ?? '',
      estado: json['estado']?.toString() ?? 'pendiente',
      estadoPago: json['estado_pago']?.toString() ?? 'pendiente',
      precioOriginal: (json['precio_original'] is num)
          ? (json['precio_original'] as num).toDouble()
          : double.tryParse(json['precio_original']?.toString() ?? '0') ?? 0.0,
      descuentoAplicado: (json['descuento_aplicado'] is num)
          ? (json['descuento_aplicado'] as num).toDouble()
          : double.tryParse(json['descuento_aplicado']?.toString() ?? '0') ?? 0.0,
      precioFinal: (json['precio_final'] is num)
          ? (json['precio_final'] as num).toDouble()
          : double.tryParse(json['precio_final']?.toString() ?? '0') ?? 0.0,
      notas: json['notas']?.toString(),
      servicios: json['servicios'] != null
          ? CitaServicioInfo.fromJson(json['servicios'] as Map<String, dynamic>)
          : null,
      promociones: json['promociones'] != null
          ? CitaPromocionInfo.fromJson(json['promociones'] as Map<String, dynamic>)
          : null,
    );
  }

  Cita copyWith({
    String? clienteNombre,
    String? clienteTelefono,
    String? clienteEmail,
    String? servicioId,
    String? promocionId,
    String? fechaCita,
    String? horaInicio,
    String? horaFin,
    String? estado,
    String? estadoPago,
    double? precioOriginal,
    double? descuentoAplicado,
    double? precioFinal,
    String? notas,
    CitaServicioInfo? servicios,
    CitaPromocionInfo? promociones,
  }) {
    return Cita(
      id: id,
      createdAt: createdAt,
      clienteNombre: clienteNombre ?? this.clienteNombre,
      clienteTelefono: clienteTelefono ?? this.clienteTelefono,
      clienteEmail: clienteEmail ?? this.clienteEmail,
      servicioId: servicioId ?? this.servicioId,
      promocionId: promocionId ?? this.promocionId,
      fechaCita: fechaCita ?? this.fechaCita,
      horaInicio: horaInicio ?? this.horaInicio,
      horaFin: horaFin ?? this.horaFin,
      estado: estado ?? this.estado,
      estadoPago: estadoPago ?? this.estadoPago,
      precioOriginal: precioOriginal ?? this.precioOriginal,
      descuentoAplicado: descuentoAplicado ?? this.descuentoAplicado,
      precioFinal: precioFinal ?? this.precioFinal,
      notas: notas ?? this.notas,
      servicios: servicios ?? this.servicios,
      promociones: promociones ?? this.promociones,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt,
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cliente_email': clienteEmail,
      'servicio_id': servicioId,
      'promocion_id': promocionId,
      'fecha_cita': fechaCita,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'estado': estado,
      'estado_pago': estadoPago,
      'precio_original': precioOriginal,
      'descuento_aplicado': descuentoAplicado,
      'precio_final': precioFinal,
      'notas': notas,
      if (servicios != null)
        'servicios': {
          'nombre': servicios!.nombre,
          'duracion_minutos': servicios!.duracionMinutos,
          'categoria': servicios!.categoria,
        },
      if (promociones != null)
        'promociones': {
          'titulo': promociones!.titulo,
          'porcentaje_descuento': promociones!.porcentajeDescuento,
        },
    };
  }
}
