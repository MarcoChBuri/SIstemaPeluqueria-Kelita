/// Modelo para una promoción asignada a una clienta específica.
/// Genera un QR único que solo puede usarse (canjearse) una vez.
class PromocionCliente {
  final String id;
  final String clienteId;
  final String clienteNombre;
  final String clienteTelefono;
  final String promocionId;
  final String promocionTitulo;
  final String codigoQr; // Código único generado
  final String fechaAsignacion;
  final bool canjeado; // true = ya fue usado
  final String? fechaCanje;

  PromocionCliente({
    required this.id,
    required this.clienteId,
    required this.clienteNombre,
    required this.clienteTelefono,
    required this.promocionId,
    required this.promocionTitulo,
    required this.codigoQr,
    required this.fechaAsignacion,
    this.canjeado = false,
    this.fechaCanje,
  });

  factory PromocionCliente.fromJson(Map<String, dynamic> json) {
    return PromocionCliente(
      id: json['id']?.toString() ?? '',
      clienteId: json['cliente_id']?.toString() ?? '',
      clienteNombre: json['cliente_nombre']?.toString() ?? '',
      clienteTelefono: json['cliente_telefono']?.toString() ?? '',
      promocionId: json['promocion_id']?.toString() ?? '',
      promocionTitulo: json['promocion_titulo']?.toString() ?? '',
      codigoQr: json['codigo_qr']?.toString() ?? '',
      fechaAsignacion: json['fecha_asignacion']?.toString() ?? '',
      canjeado: json['canjeado'] == true ||
          json['canjeado'] == 1 ||
          json['canjeado']?.toString().toLowerCase() == 'true',
      fechaCanje: json['fecha_canje']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cliente_id': clienteId,
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'promocion_id': promocionId,
      'promocion_titulo': promocionTitulo,
      'codigo_qr': codigoQr,
      'fecha_asignacion': fechaAsignacion,
      'canjeado': canjeado,
      'fecha_canje': fechaCanje,
    };
  }

  PromocionCliente copyWith({bool? canjeado, String? fechaCanje}) {
    return PromocionCliente(
      id: id,
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      promocionId: promocionId,
      promocionTitulo: promocionTitulo,
      codigoQr: codigoQr,
      fechaAsignacion: fechaAsignacion,
      canjeado: canjeado ?? this.canjeado,
      fechaCanje: fechaCanje ?? this.fechaCanje,
    );
  }
}
