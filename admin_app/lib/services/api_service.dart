import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cita.dart';
import '../models/servicio.dart';
import '../models/promocion.dart';
import '../models/gasto.dart';
import '../models/venta_producto.dart';
import '../models/calculo_precio.dart';
import '../models/reporte_financiero.dart';
import '../models/galeria_item.dart';
import '../models/curso_item.dart';
import 'storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String _cachedBaseUrl = StorageService.defaultBaseUrl;

  Future<void> init() async {
    _cachedBaseUrl = await StorageService.getBaseUrl();
  }

  void updateBaseUrl(String url) {
    _cachedBaseUrl = url;
  }

  String get currentBaseUrl => _cachedBaseUrl;

  Future<Map<String, dynamic>> _request(
    String endpoint, {
    String method = 'GET',
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_cachedBaseUrl$endpoint');
    final headers = {'Content-Type': 'application/json'};

    http.Response response;
    try {
      if (method == 'POST') {
        response = await http
            .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(const Duration(seconds: 12));
      } else if (method == 'PATCH') {
        response = await http
            .patch(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
            .timeout(const Duration(seconds: 12));
      } else if (method == 'DELETE') {
        response = await http.delete(uri, headers: headers).timeout(const Duration(seconds: 12));
      } else {
        response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 12));
      }
    } catch (e) {
      throw Exception('Error de conexión con el servidor: $e');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('ok') && decoded['ok'] == false) {
            throw Exception(decoded['error'] ?? 'Error en la petición');
          }
          return decoded;
        }
        return {'data': decoded};
      } catch (e) {
        throw Exception('Respuesta inválida del servidor: ${response.body}');
      }
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      try {
        final errorData = jsonDecode(response.body);
        if (errorData is Map && errorData.containsKey('error')) {
          errorMessage = errorData['error'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }

  // --- Health Check ---
  Future<bool> checkHealth() async {
    try {
      final res = await _request('/health');
      return res['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  // --- CITAS ---
  Future<List<Cita>> getCitas({String? fecha, String? estado, int? mes, int? anio}) async {
    final params = <String>[];
    if (fecha != null && fecha.isNotEmpty) params.add('fecha=$fecha');
    if (estado != null && estado.isNotEmpty && estado != 'all') params.add('estado=$estado');
    if (mes != null) params.add('mes=$mes');
    if (anio != null) params.add('anio=$anio');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await _request('/citas$query');
    final rawList = res['citas'] as List? ?? [];
    return rawList.map((item) => Cita.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> createCita({
    required String clienteNombre,
    required String clienteTelefono,
    String? clienteEmail,
    required String servicioId,
    String? promocionId,
    required String fechaCita,
    required String horaInicio,
    int? duracionMinutos,
    String? notas,
  }) async {
    final payload = {
      'cliente_nombre': clienteNombre,
      'cliente_telefono': clienteTelefono,
      'cliente_email': clienteEmail,
      'servicio_id': servicioId,
      'promocion_id': promocionId,
      'fecha_cita': fechaCita,
      'hora_inicio': horaInicio,
      'duracion_minutos': duracionMinutos,
      'notas': notas,
    };
    final res = await _request('/citas', method: 'POST', body: payload);
    return {
      'cita': Cita.fromJson(res['cita'] as Map<String, dynamic>),
      'whatsapp_url': res['whatsapp_url']?.toString() ?? '',
      'mensaje': res['mensaje']?.toString() ?? '',
    };
  }

  Future<Cita> updateCitaEstado(
    String id, {
    String? estado,
    String? estadoPago,
  }) async {
    final payload = <String, dynamic>{};
    if (estado != null) payload['estado'] = estado;
    if (estadoPago != null) payload['estado_pago'] = estadoPago;

    final res = await _request('/citas/$id/estado', method: 'PATCH', body: payload);
    return Cita.fromJson(res['cita'] as Map<String, dynamic>);
  }

  Future<List<Map<String, String>>> getDisponibilidad(String fecha) async {
    final res = await _request('/citas/disponibilidad?fecha=$fecha');
    final raw = res['horas_ocupadas'] as List? ?? [];
    return raw.map((item) => {
      'hora_inicio': item['hora_inicio']?.toString() ?? '',
      'hora_fin': item['hora_fin']?.toString() ?? '',
      'estado': item['estado']?.toString() ?? '',
    }).toList();
  }

  // --- SERVICIOS ---
  Future<List<Servicio>> getServicios({String? categoria, bool? soloActivos}) async {
    final params = <String>[];
    if (categoria != null && categoria.isNotEmpty && categoria != 'all') {
      params.add('categoria=$categoria');
    }
    if (soloActivos != null) params.add('solo_activos=$soloActivos');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await _request('/servicios$query');
    final rawList = res['servicios'] as List? ?? [];
    return rawList.map((item) => Servicio.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Servicio> createServicio({
    required String nombre,
    required String categoria,
    String? descripcion,
    required int duracionMinutos,
    required double precioBase,
    String? imagenUrl,
  }) async {
    final payload = {
      'nombre': nombre,
      'categoria': categoria,
      'descripcion': descripcion,
      'duracion_minutos': duracionMinutos,
      'precio_base': precioBase,
      'imagen_url': imagenUrl,
    };
    final res = await _request('/servicios', method: 'POST', body: payload);
    return Servicio.fromJson(res['servicio'] as Map<String, dynamic>);
  }

  Future<Servicio> updateServicio({
    required String id,
    required String nombre,
    required String categoria,
    String? descripcion,
    required double precioBase,
  }) async {
    final payload = {
      'nombre': nombre,
      'categoria': categoria,
      'descripcion': descripcion,
      'precio_base': precioBase,
    };
    final res = await _request('/servicios/$id', method: 'PUT', body: payload);
    return Servicio.fromJson(res['servicio'] as Map<String, dynamic>);
  }

  Future<void> deleteServicio(String id) async {
    await _request('/servicios/$id', method: 'DELETE');
  }

  // --- PROMOCIONES ---
  Future<List<Promocion>> getPromociones({bool incluirInactivas = true}) async {
    final query = incluirInactivas ? '?incluir_inactivas=true' : '';
    final res = await _request('/promociones$query');
    final rawList = res['promociones'] as List? ?? [];
    return rawList.map((item) => Promocion.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<Promocion> createPromocion({
    required String titulo,
    String? descripcion,
    double? porcentajeDescuento,
    double? montoDescuento,
    String? fechaInicio,
    required String fechaFin,
    String? imagenUrl,
    bool esPublica = true,
    bool activa = true,
    String? codigoQr,
  }) async {
    final payload = {
      'titulo': titulo,
      'descripcion': descripcion,
      'porcentaje_descuento': porcentajeDescuento,
      'monto_descuento': montoDescuento,
      'fecha_inicio': fechaInicio,
      'fecha_fin': fechaFin,
      'imagen_url': imagenUrl,
      'es_publica': esPublica,
      'activa': activa,
      'codigo_qr': codigoQr,
    };
    final res = await _request('/promociones', method: 'POST', body: payload);
    return Promocion.fromJson(res['promocion'] as Map<String, dynamic>);
  }

  Future<Promocion> updatePromocion({
    required String id,
    String? titulo,
    String? descripcion,
    double? porcentajeDescuento,
    double? montoDescuento,
    String? fechaInicio,
    String? fechaFin,
    String? imagenUrl,
    bool? activa,
    bool? esPublica,
    String? codigoQr,
  }) async {
    final payload = <String, dynamic>{};
    if (titulo != null) payload['titulo'] = titulo;
    if (descripcion != null) payload['descripcion'] = descripcion;
    if (porcentajeDescuento != null) payload['porcentaje_descuento'] = porcentajeDescuento;
    if (montoDescuento != null) payload['monto_descuento'] = montoDescuento;
    if (fechaInicio != null) payload['fecha_inicio'] = fechaInicio;
    if (fechaFin != null) payload['fecha_fin'] = fechaFin;
    if (imagenUrl != null) payload['imagen_url'] = imagenUrl;
    if (activa != null) payload['activa'] = activa;
    if (esPublica != null) payload['es_publica'] = esPublica;
    if (codigoQr != null) payload['codigo_qr'] = codigoQr;

    final res = await _request('/promociones/$id', method: 'PUT', body: payload);
    return Promocion.fromJson(res['promocion'] as Map<String, dynamic>);
  }

  Future<void> deletePromocion(String id) async {
    await _request('/promociones/$id', method: 'DELETE');
  }

  Future<Map<String, dynamic>> validarQrPromocion(String codigoQr) async {
    final res = await _request('/promociones/validar-qr', method: 'POST', body: {'codigo_qr': codigoQr});
    return res;
  }


  // --- CALCULADORA DE COLORIMETRÍA ---
  Future<CalculoPrecioResult> calcularPrecio({
    required int porcionesDecolorante,
    required int tubosTinte,
    required int mezclasPeroxido,
    required double horasTrabajo,
    double? extra,
  }) async {
    final payload = {
      'porciones_decolorante': porcionesDecolorante,
      'tubos_tinte': tubosTinte,
      'mezclas_peroxido': mezclasPeroxido,
      'horas_trabajo': horasTrabajo,
      'extra': extra ?? 0,
    };
    final res = await _request('/calcular-precio', method: 'POST', body: payload);
    return CalculoPrecioResult.fromJson(res);
  }

  // --- GASTOS ---
  Future<Map<String, dynamic>> getGastos() async {
    final res = await _request('/gastos');
    final raw = res['gastos'] as List? ?? [];
    final gastos = raw.map((item) => Gasto.fromJson(item as Map<String, dynamic>)).toList();
    final total = (res['total'] is num)
        ? (res['total'] as num).toDouble()
        : double.tryParse(res['total']?.toString() ?? '0') ?? 0.0;
    return {'total': total, 'gastos': gastos};
  }

  Future<Gasto> createGasto({
    required double monto,
    required String categoria,
    String? concepto,
  }) async {
    final payload = {
      'monto': monto,
      'categoria': categoria,
      'concepto': concepto,
    };
    final res = await _request('/gastos', method: 'POST', body: payload);
    final data = res['data'] ?? res['gasto'] ?? res;
    return Gasto.fromJson(data as Map<String, dynamic>);
  }

  // --- VENTAS DE PRODUCTOS ---
  Future<Map<String, dynamic>> getVentasProductos({int? mes, int? anio}) async {
    final params = <String>[];
    if (mes != null) params.add('mes=$mes');
    if (anio != null) params.add('anio=$anio');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await _request('/productos/ventas$query');
    final raw = res['ventas'] as List? ?? [];
    final ventas = raw.map((item) => VentaProducto.fromJson(item as Map<String, dynamic>)).toList();
    return {
      'periodo': res['periodo']?.toString() ?? '',
      'cantidad': res['cantidad'] ?? 0,
      'total_ventas': (res['total_ventas'] is num) ? (res['total_ventas'] as num).toDouble() : 0.0,
      'total_costo': (res['total_costo'] is num) ? (res['total_costo'] as num).toDouble() : 0.0,
      'ganancia_total': (res['ganancia_total'] is num) ? (res['ganancia_total'] as num).toDouble() : 0.0,
      'ventas': ventas,
    };
  }

  Future<VentaProducto> createVentaProducto({
    required String nombre,
    required double costo,
    required double precio,
    int cantidad = 1,
    String? nombreCliente,
  }) async {
    final payload = {
      'nombre': nombre,
      'costo': costo,
      'precio': precio,
      'cantidad': cantidad,
      'nombre_cliente': nombreCliente,
    };
    final res = await _request('/productos/venta', method: 'POST', body: payload);
    final data = res['data'] ?? res['venta'] ?? res;
    return VentaProducto.fromJson(data as Map<String, dynamic>);
  }

  // --- REPORTE FINANCIERO SIMPLE ---
  Future<ReporteFinanciero> getReporteSimple({int? mes, int? anio}) async {
    final params = <String>[];
    if (mes != null) params.add('mes=$mes');
    if (anio != null) params.add('anio=$anio');

    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await _request('/reporte-simple$query');
    return ReporteFinanciero.fromJson(res);
  }

  // --- GALERÍA Y CURSOS ---
  Future<List<GaleriaItem>> getGaleria([String? categoria]) async {
    final query = (categoria != null && categoria.isNotEmpty) ? '?categoria=$categoria' : '';
    final res = await _request('/galeria$query');
    final raw = res['trabajos'] as List? ?? [];
    return raw.map((item) => GaleriaItem.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<List<CursoItem>> getCursos() async {
    final res = await _request('/cursos');
    final raw = res['cursos'] as List? ?? [];
    return raw.map((item) => CursoItem.fromJson(item as Map<String, dynamic>)).toList();
  }
}
