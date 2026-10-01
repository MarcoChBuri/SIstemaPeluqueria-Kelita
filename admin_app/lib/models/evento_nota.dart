class EventoNota {
  final String id;
  final String titulo;
  final String? descripcion;
  final String fecha; // YYYY-MM-DD
  final String horaInicio; // HH:mm
  final String horaFin; // HH:mm
  final String tipo; // 'evento', 'bloqueo', 'personal', 'recordatorio'
  final String colorHex;
  final bool conNotificacion;

  EventoNota({
    required this.id,
    required this.titulo,
    this.descripcion,
    required this.fecha,
    required this.horaInicio,
    required this.horaFin,
    this.tipo = 'evento',
    this.colorHex = '#B10E6B',
    this.conNotificacion = true,
  });

  factory EventoNota.fromJson(Map<String, dynamic> json) {
    return EventoNota(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      titulo: json['titulo']?.toString() ?? 'Evento',
      descripcion: json['descripcion']?.toString(),
      fecha: json['fecha']?.toString() ?? '',
      horaInicio: json['hora_inicio']?.toString() ?? '09:00',
      horaFin: json['hora_fin']?.toString() ?? '10:00',
      tipo: json['tipo']?.toString() ?? 'evento',
      colorHex: json['color_hex']?.toString() ?? '#B10E6B',
      conNotificacion: json['con_notificacion'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'fecha': fecha,
      'hora_inicio': horaInicio,
      'hora_fin': horaFin,
      'tipo': tipo,
      'color_hex': colorHex,
      'con_notificacion': conNotificacion,
    };
  }
}
