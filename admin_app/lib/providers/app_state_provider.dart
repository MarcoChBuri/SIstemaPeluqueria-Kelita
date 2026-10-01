import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cita.dart';
import '../models/servicio.dart';
import '../models/promocion.dart';
import '../models/gasto.dart';
import '../models/venta_producto.dart';
import '../models/reporte_financiero.dart';
import '../models/galeria_item.dart';
import '../models/curso_item.dart';
import '../models/evento_nota.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Cita> _citas = [];
  List<Servicio> _servicios = [];
  List<Promocion> _promociones = [];
  ReporteFinanciero? _reporte;
  List<Gasto> _gastos = [];
  double _totalGastos = 0.0;
  List<VentaProducto> _ventas = [];
  double _totalVentas = 0.0;
  double _gananciaVentas = 0.0;
  List<GaleriaItem> _galeria = [];
  List<CursoItem> _cursos = [];
  List<EventoNota> _eventosNotas = [];

  bool _isLoading = false;
  bool _isBackendConnected = false;
  String? _errorMessage;

  // Getters
  List<Cita> get citas => _citas;
  List<Servicio> get servicios => _servicios;
  List<Promocion> get promociones => _promociones;
  ReporteFinanciero? get reporte => _reporte;
  List<Gasto> get gastos => _gastos;
  double get totalGastos => _totalGastos;
  List<VentaProducto> get ventas => _ventas;
  double get totalVentas => _totalVentas;
  double get gananciaVentas => _gananciaVentas;
  List<GaleriaItem> get galeria => _galeria;
  List<CursoItem> get cursos => _cursos;
  List<EventoNota> get eventosNotas => _eventosNotas;
  bool get isLoading => _isLoading;
  bool get isBackendConnected => _isBackendConnected;
  String? get errorMessage => _errorMessage;
  String get currentBaseUrl => _api.currentBaseUrl;

  DateTime? _parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  // --- CÁLCULOS SEMANALES Y MENSUALES ---
  double get gastosEstaSemana {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 7));

    double total = 0;
    for (var g in _gastos) {
      final d = _parseDate(g.fecha);
      if (d != null && d.isAfter(monday.subtract(const Duration(seconds: 1))) && d.isBefore(sunday)) {
        total += g.monto;
      }
    }
    return total;
  }

  double get gananciasCitasEstaSemana {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 7));

    double total = 0;
    for (var c in _citas) {
      if (c.estado == 'realizada' || c.estado == 'completada') {
        final d = _parseDate(c.fechaCita);
        if (d != null && d.isAfter(monday.subtract(const Duration(seconds: 1))) && d.isBefore(sunday)) {
          total += c.precioFinal;
        }
      }
    }
    return total;
  }

  double get gananciasVentasEstaSemana {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    final sunday = monday.add(const Duration(days: 7));

    double total = 0;
    for (var v in _ventas) {
      final d = _parseDate(v.fecha);
      if (d != null && d.isAfter(monday.subtract(const Duration(seconds: 1))) && d.isBefore(sunday)) {
        total += (v.precioVenta * v.cantidad);
      }
    }
    return total;
  }

  double get totalGananciasEstaSemana => gananciasCitasEstaSemana + gananciasVentasEstaSemana;
  double get balanceNetoEstaSemana => totalGananciasEstaSemana - gastosEstaSemana;

  // Resumen Mensual
  double get gastosEsteMes {
    final now = DateTime.now();
    double total = 0;
    for (var g in _gastos) {
      final d = _parseDate(g.fecha);
      if (d != null && d.year == now.year && d.month == now.month) {
        total += g.monto;
      }
    }
    if (total > 0) return total;
    return _reporte?.totalGastos ?? _totalGastos;
  }

  double get gananciasCitasEsteMes {
    final now = DateTime.now();
    double total = 0;
    for (var c in _citas) {
      if (c.estado == 'realizada' || c.estado == 'completada') {
        final d = _parseDate(c.fechaCita);
        if (d != null && d.year == now.year && d.month == now.month) {
          total += c.precioFinal;
        }
      }
    }
    if (total > 0) return total;
    return _reporte?.ingresos.servicios ?? 0;
  }

  double get totalIngresosEsteMes {
    final now = DateTime.now();
    double totalVentasMes = 0;
    for (var v in _ventas) {
      final d = _parseDate(v.fecha);
      if (d != null && d.year == now.year && d.month == now.month) {
        totalVentasMes += (v.precioVenta * v.cantidad);
      }
    }
    final totalCalc = gananciasCitasEsteMes + totalVentasMes;
    if (totalCalc > 0) return totalCalc;
    return _reporte?.totalIngresos ?? 0;
  }

  double get balanceNetoEsteMes => totalIngresosEsteMes - gastosEsteMes;

  Future<void> init() async {
    await _api.init();
    await _loadEventosNotas();
    await loadAllData();
  }

  Future<void> _loadEventosNotas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('raquel_eventos_notas');
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        _eventosNotas = decoded.map((e) => EventoNota.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _saveEventosNotas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(_eventosNotas.map((e) => e.toJson()).toList());
      await prefs.setString('raquel_eventos_notas', rawJson);
    } catch (_) {}
  }

  Future<void> addEventoNota(EventoNota evento) async {
    _eventosNotas.add(evento);
    await _saveEventosNotas();
    notifyListeners();
  }

  Future<void> removeEventoNota(String id) async {
    _eventosNotas.removeWhere((e) => e.id == id);
    await _saveEventosNotas();
    notifyListeners();
  }

  Future<void> updateServerUrl(String newUrl) async {
    await StorageService.setBaseUrl(newUrl);
    _api.updateBaseUrl(await StorageService.getBaseUrl());
    notifyListeners();
    await loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _api.getCitas().catchError((_) => <Cita>[]),
        _api.getServicios().catchError((_) => <Servicio>[]),
        _api.getPromociones().catchError((_) => <Promocion>[]),
        _api.getReporteSimple().catchError((_) => ReporteFinanciero(
          ok: false,
          periodo: 'Mes Actual',
          ingresos: IngresosDetalle(cursos: 0, servicios: 0, productos: 0),
          totalIngresos: 0,
          totalGastos: 0,
          gananciaRealProductos: 0,
          balanceNeto: 0,
          mensaje: 'Servidor desconectado o en modo offline.',
        )),
        _api.getGastos().catchError((_) => {'total': 0.0, 'gastos': <Gasto>[]}),
        _api.getVentasProductos().catchError((_) => {'total_ventas': 0.0, 'ganancia_total': 0.0, 'ventas': <VentaProducto>[]}),
        _api.getGaleria().catchError((_) => <GaleriaItem>[]),
        _api.getCursos().catchError((_) => <CursoItem>[]),
      ]);

      _citas = results[0] as List<Cita>;
      _servicios = results[1] as List<Servicio>;
      _promociones = results[2] as List<Promocion>;
      _reporte = results[3] as ReporteFinanciero;

      final gastosMap = results[4] as Map<String, dynamic>;
      _gastos = gastosMap['gastos'] as List<Gasto>;
      _totalGastos = gastosMap['total'] as double;

      final ventasMap = results[5] as Map<String, dynamic>;
      _ventas = ventasMap['ventas'] as List<VentaProducto>;
      _totalVentas = ventasMap['total_ventas'] as double;
      _gananciaVentas = ventasMap['ganancia_total'] as double;

      _galeria = results[6] as List<GaleriaItem>;
      _cursos = results[7] as List<CursoItem>;

      _isBackendConnected = _reporte?.ok == true || _citas.isNotEmpty || _servicios.isNotEmpty;
    } catch (e) {
      _errorMessage = e.toString();
      _isBackendConnected = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshReporte() async {
    try {
      final rep = await _api.getReporteSimple();
      _reporte = rep;
      notifyListeners();
    } catch (_) {}
  }

  // Citas Actions
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
    final result = await _api.createCita(
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      clienteEmail: clienteEmail,
      servicioId: servicioId,
      promocionId: promocionId,
      fechaCita: fechaCita,
      horaInicio: horaInicio,
      duracionMinutos: duracionMinutos,
      notas: notas,
    );

    final newCita = result['cita'] as Cita;
    _citas.insert(0, newCita);
    refreshReporte();
    notifyListeners();
    return result;
  }

  Future<void> updateCitaStatus(String id, {String? estado, String? estadoPago}) async {
    // If status changes to realizada or completada, default payment status to pagado
    final targetPago = estadoPago ?? ((estado == 'realizada' || estado == 'completada') ? 'pagado' : null);
    try {
      final updated = await _api.updateCitaEstado(id, estado: estado, estadoPago: targetPago);
      final index = _citas.indexWhere((c) => c.id == id);
      if (index != -1) {
        _citas[index] = updated;
        notifyListeners();
        refreshReporte();
      }
    } catch (_) {
      final index = _citas.indexWhere((c) => c.id == id);
      if (index != -1) {
        final c = _citas[index];
        _citas[index] = Cita(
          id: c.id,
          createdAt: c.createdAt,
          clienteNombre: c.clienteNombre,
          clienteTelefono: c.clienteTelefono,
          clienteEmail: c.clienteEmail,
          servicioId: c.servicioId,
          promocionId: c.promocionId,
          fechaCita: c.fechaCita,
          horaInicio: c.horaInicio,
          horaFin: c.horaFin,
          estado: estado ?? c.estado,
          estadoPago: targetPago ?? c.estadoPago,
          precioOriginal: c.precioOriginal,
          descuentoAplicado: c.descuentoAplicado,
          precioFinal: c.precioFinal,
          notas: c.notas,
          servicios: c.servicios,
          promociones: c.promociones,
        );
        notifyListeners();
        refreshReporte();
      }
    }
  }

  Future<void> createServicioSinCita({
    required String nombreServicio,
    required double precio,
    String? nombreCliente,
  }) async {
    await createVentaProducto(
      nombre: 'Servicio Presencial: $nombreServicio',
      costo: 0,
      precio: precio,
      cantidad: 1,
      nombreCliente: nombreCliente ?? 'Cliente Presencial (Sin Cita)',
    );
  }

  // Servicios Actions
  Future<Servicio> createServicio({
    required String nombre,
    required String categoria,
    String? descripcion,
    required int duracionMinutos,
    required double precioBase,
    String? imagenUrl,
  }) async {
    final s = await _api.createServicio(
      nombre: nombre,
      categoria: categoria,
      descripcion: descripcion,
      duracionMinutos: duracionMinutos,
      precioBase: precioBase,
      imagenUrl: imagenUrl,
    );
    _servicios.add(s);
    notifyListeners();
    return s;
  }

  Future<void> updateServicio({
    required String id,
    required String nombre,
    required String categoria,
    String? descripcion,
    required double precioBase,
  }) async {
    try {
      final updated = await _api.updateServicio(
        id: id,
        nombre: nombre,
        categoria: categoria,
        descripcion: descripcion,
        precioBase: precioBase,
      );
      final idx = _servicios.indexWhere((s) => s.id == id);
      if (idx != -1) {
        _servicios[idx] = updated;
        notifyListeners();
      }
    } catch (_) {
      final idx = _servicios.indexWhere((s) => s.id == id);
      if (idx != -1) {
        final existing = _servicios[idx];
        _servicios[idx] = Servicio(
          id: id,
          nombre: nombre,
          categoria: categoria,
          descripcion: descripcion,
          duracionMinutos: existing.duracionMinutos,
          precioBase: precioBase,
        );
        notifyListeners();
      }
    }
  }

  Future<void> deleteServicio(String id) async {
    try {
      await _api.deleteServicio(id);
    } catch (_) {}
    _servicios.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // Promociones Actions
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
    final p = await _api.createPromocion(
      titulo: titulo,
      descripcion: descripcion,
      porcentajeDescuento: porcentajeDescuento,
      montoDescuento: montoDescuento,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      imagenUrl: imagenUrl,
      esPublica: esPublica,
      activa: activa,
      codigoQr: codigoQr,
    );
    _promociones.insert(0, p);
    notifyListeners();
    return p;
  }

  Future<void> updatePromocion({
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
    try {
      final updated = await _api.updatePromocion(
        id: id,
        titulo: titulo,
        descripcion: descripcion,
        porcentajeDescuento: porcentajeDescuento,
        montoDescuento: montoDescuento,
        fechaInicio: fechaInicio,
        fechaFin: fechaFin,
        imagenUrl: imagenUrl,
        activa: activa,
        esPublica: esPublica,
        codigoQr: codigoQr,
      );
      final idx = _promociones.indexWhere((p) => p.id == id);
      if (idx != -1) {
        _promociones[idx] = updated;
        notifyListeners();
      }
    } catch (_) {
      final idx = _promociones.indexWhere((p) => p.id == id);
      if (idx != -1) {
        final ex = _promociones[idx];
        _promociones[idx] = Promocion(
          id: id,
          createdAt: ex.createdAt,
          titulo: titulo ?? ex.titulo,
          descripcion: descripcion ?? ex.descripcion,
          porcentajeDescuento: porcentajeDescuento ?? ex.porcentajeDescuento,
          montoDescuento: montoDescuento ?? ex.montoDescuento,
          fechaInicio: fechaInicio ?? ex.fechaInicio,
          fechaFin: fechaFin ?? ex.fechaFin,
          imagenUrl: imagenUrl ?? ex.imagenUrl,
          activa: activa ?? ex.activa,
          esPublica: esPublica ?? ex.esPublica,
          codigoQr: codigoQr ?? ex.codigoQr,
        );
        notifyListeners();
      }
    }
  }

  Future<void> deletePromocion(String id) async {
    try {
      await _api.deletePromocion(id);
    } catch (_) {}
    _promociones.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Future<Map<String, dynamic>> validarQrPromocion(String codigoQr) async {
    return _api.validarQrPromocion(codigoQr);
  }


  // Gastos Actions
  Future<Gasto> createGasto({
    required double monto,
    required String categoria,
    String? concepto,
  }) async {
    final g = await _api.createGasto(monto: monto, categoria: categoria, concepto: concepto);
    _gastos.insert(0, g);
    _totalGastos += g.monto;
    refreshReporte();
    notifyListeners();
    return g;
  }

  // Ventas Actions
  Future<VentaProducto> createVentaProducto({
    required String nombre,
    required double costo,
    required double precio,
    int cantidad = 1,
    String? nombreCliente,
  }) async {
    final v = await _api.createVentaProducto(
      nombre: nombre,
      costo: costo,
      precio: precio,
      cantidad: cantidad,
      nombreCliente: nombreCliente,
    );
    _ventas.insert(0, v);
    _totalVentas += (v.precioVenta * v.cantidad);
    _gananciaVentas += ((v.precioVenta - v.precioCosto) * v.cantidad);
    refreshReporte();
    notifyListeners();
    return v;
  }
}
