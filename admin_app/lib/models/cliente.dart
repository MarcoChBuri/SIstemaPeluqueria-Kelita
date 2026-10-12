class Cliente {
  final String id;
  final String nombre;
  final String telefono;
  final String? email;
  final String? notas;
  final int totalCitas;
  final double totalGastado;
  final String? ultimaVisita;

  int get totalVisitas => totalCitas;

  Cliente({
    required this.id,
    required this.nombre,
    required this.telefono,
    this.email,
    this.notas,
    this.totalCitas = 0,
    this.totalGastado = 0.0,
    this.ultimaVisita,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) {
    return Cliente(
      id: json['id']?.toString() ?? '',
      nombre: json['nombre']?.toString() ?? '',
      telefono: json['telefono']?.toString() ?? '',
      email: json['email']?.toString(),
      notas: json['notas']?.toString(),
      totalCitas: (json['total_citas'] as num?)?.toInt() ?? 0,
      totalGastado: (json['total_gastado'] as num?)?.toDouble() ?? 0.0,
      ultimaVisita: json['ultima_visita']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'notas': notas,
      'total_citas': totalCitas,
      'total_gastado': totalGastado,
      'ultima_visita': ultimaVisita,
    };
  }
}
