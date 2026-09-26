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
      fechaCita: json['fecha_cita']?.toString() ?? '',
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
    String? estado,
    String? estadoPago,
  }) {
    return Cita(
      id: id,
      createdAt: createdAt,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      clienteEmail: clienteEmail,
      servicioId: servicioId,
      promocionId: promocionId,
      fechaCita: fechaCita,
      horaInicio: horaInicio,
      horaFin: horaFin,
      estado: estado ?? this.estado,
      estadoPago: estadoPago ?? this.estadoPago,
      precioOriginal: precioOriginal,
      descuentoAplicado: descuentoAplicado,
      precioFinal: precioFinal,
      notas: notas,
      servicios: servicios,
      promociones: promociones,
    );
  }
}
