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
import '../models/cliente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<Cita> _citas = [];
  List<Servicio> _servicios = [];
  List<Promocion> _promociones = [];
  List<Cliente> _clientes = [];
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
  List<Cliente> get clientes => _clientes;
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

  // Ganancias globales históricas
  double get gananciasCitas {
    double total = 0;
    for (var c in _citas) {
      if (c.estado == 'realizada' || c.estado == 'completada' || c.estadoPago == 'pagado') {
        total += c.precioFinal;
      }
    }
    return total;
  }
  double get totalGananciasCitas => gananciasCitas;
  double get totalIngresos => gananciasCitas + _totalVentas;

  Future<void> init() async {
    await _api.init();
    await _loadEventosNotas();
    await _loadAllCaches();
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

  Future<void> _loadAllCaches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final rawCitas = prefs.getString('raquel_citas_cache');
      if (rawCitas != null && rawCitas.isNotEmpty) {
        final List decoded = jsonDecode(rawCitas);
        _citas = decoded.map((e) => Cita.fromJson(e)).toList();
      }

      final rawServicios = prefs.getString('raquel_servicios_cache');
      if (rawServicios != null && rawServicios.isNotEmpty) {
        final List decoded = jsonDecode(rawServicios);
        _servicios = decoded.map((e) => Servicio.fromJson(e)).toList();
      }

      final rawClientes = prefs.getString('raquel_clientes_cache');
      if (rawClientes != null && rawClientes.isNotEmpty) {
        final List decoded = jsonDecode(rawClientes);
        _clientes = decoded.map((e) => Cliente.fromJson(e)).toList();
      }
      _actualizarClientesDesdeCitas();
    } catch (_) {}
  }

  Future<void> _saveCitasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_citas.map((c) => c.toJson()).toList());
      await prefs.setString('raquel_citas_cache', raw);
      _actualizarClientesDesdeCitas();
    } catch (_) {}
  }

  Future<void> _saveServiciosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_servicios.map((s) => s.toJson()).toList());
      await prefs.setString('raquel_servicios_cache', raw);
    } catch (_) {}
  }

  Future<void> _saveClientesCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_clientes.map((c) => c.toJson()).toList());
      await prefs.setString('raquel_clientes_cache', raw);
    } catch (_) {}
  }

  void _actualizarClientesDesdeCitas() {
    final Map<String, Cliente> mapa = {};
    for (var c in _clientes) {
      final key = c.telefono.trim().isNotEmpty ? c.telefono.trim() : c.nombre.trim().toLowerCase();
      if (key.isNotEmpty) mapa[key] = c;
    }
    for (var cita in _citas) {
      final key = cita.clienteTelefono.trim().isNotEmpty ? cita.clienteTelefono.trim() : cita.clienteNombre.trim().toLowerCase();
      if (key.isEmpty) continue;
      final existing = mapa[key];
      final esPagada = cita.estadoPago == 'pagado' || cita.estado == 'completada' || cita.estado == 'realizada';
      if (existing != null) {
        mapa[key] = Cliente(
          id: existing.id,
          nombre: existing.nombre.isNotEmpty ? existing.nombre : cita.clienteNombre,
          telefono: existing.telefono.isNotEmpty ? existing.telefono : cita.clienteTelefono,
          email: existing.email ?? cita.clienteEmail,
          notas: existing.notas ?? cita.notas,
          totalCitas: existing.totalCitas + 1,
          totalGastado: existing.totalGastado + (esPagada ? cita.precioFinal : 0.0),
          ultimaVisita: cita.fechaCita,
        );
      } else {
        mapa[key] = Cliente(
          id: cita.id,
          nombre: cita.clienteNombre,
          telefono: cita.clienteTelefono,
          email: cita.clienteEmail,
          notas: cita.notas,
          totalCitas: 1,
          totalGastado: esPagada ? cita.precioFinal : 0.0,
          ultimaVisita: cita.fechaCita,
        );
      }
    }
    _clientes = mapa.values.toList();
    _clientes.sort((a, b) => b.totalCitas.compareTo(a.totalCitas));
  }

  Future<void> addCliente(Cliente cliente) async {
    _clientes.removeWhere((c) => c.id == cliente.id || (c.telefono.isNotEmpty && c.telefono == cliente.telefono));
    _clientes.insert(0, cliente);
    await _saveClientesCache();
    notifyListeners();
  }

  Future<void> removeCliente(String id) async {
    _clientes.removeWhere((c) => c.id == id);
    await _saveClientesCache();
    notifyListeners();
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

    // 1. Cargar caché primero de forma inmediata
    await _loadAllCaches();
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

      final apiCitas = results[0] as List<Cita>;
      if (apiCitas.isNotEmpty || _isBackendConnected) {
        _citas = apiCitas;
        _citas.sort((a, b) => (b.fechaCita + b.horaInicio).compareTo(a.fechaCita + a.horaInicio));
        await _saveCitasCache();
      }

      final apiServicios = results[1] as List<Servicio>;
      if (apiServicios.isNotEmpty || _isBackendConnected) {
        _servicios = apiServicios;
        await _saveServiciosCache();
      }

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

      _actualizarClientesDesdeCitas();
      _isBackendConnected = _reporte?.ok == true || apiCitas.isNotEmpty || apiServicios.isNotEmpty;
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
    await _saveCitasCache();
    refreshReporte();
    notifyListeners();
    return result;
  }

  Future<void> updateCitaStatus(String id, {String? estado, String? estadoPago}) async {
    // Auto-mark pagado only when directly set to realizada (not calcular)
    final targetPago = estadoPago ?? ((estado == 'realizada' || estado == 'completada') ? 'pagado' : null);
    try {
      final updated = await _api.updateCitaEstado(id, estado: estado, estadoPago: targetPago);
      final index = _citas.indexWhere((c) => c.id == id);
      if (index != -1) {
        _citas[index] = updated;
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
      }
    }
    await _saveCitasCache();
    refreshReporte();
    notifyListeners();
  }

  Future<void> updateCitaEstado(String id, {String? estado, String? estadoPago, double? precioFinal}) async {
    if (precioFinal != null) {
      await updateCitaPrecio(id, precioFinal);
    }
    if (estado != null || estadoPago != null) {
      await updateCitaStatus(id, estado: estado, estadoPago: estadoPago);
    }
  }

  Future<void> updateCitaPrecio(String id, double precio) async {
    try {
      final updated = await _api.updateCitaEstado(id, precioFinal: precio);
      final index = _citas.indexWhere((c) => c.id == id);
      if (index != -1) {
        _citas[index] = updated;
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
          estado: c.estado,
          estadoPago: c.estadoPago,
          precioOriginal: precio,
          descuentoAplicado: c.descuentoAplicado,
          precioFinal: precio,
          notas: c.notas,
          servicios: c.servicios,
          promociones: c.promociones,
        );
      }
    }
    await _saveCitasCache();
    refreshReporte();
    notifyListeners();
  }

  Future<void> updateCitaCompleta(Cita cita) async {
    final Map<String, dynamic> payload = {
      'cliente_nombre': cita.clienteNombre,
      'cliente_telefono': cita.clienteTelefono,
      if (cita.clienteEmail != null) 'cliente_email': cita.clienteEmail,
      'servicio_id': cita.servicioId,
      'fecha_cita': cita.fechaCita,
      'hora_inicio': cita.horaInicio,
      'hora_fin': cita.horaFin,
      'estado': (cita.estado == 'realizada' || cita.estado == 'pagada' ? 'completada' : cita.estado),
      'estado_pago': cita.estadoPago,
      'precio_final': cita.precioFinal,
      if (cita.notas != null) 'notas': cita.notas,
    };

    try {
      final updated = await _api.updateCita(cita.id, payload);
      final index = _citas.indexWhere((c) => c.id == cita.id);
      if (index != -1) {
        _citas[index] = updated;
      }
    } catch (_) {
      final index = _citas.indexWhere((c) => c.id == cita.id);
      if (index != -1) {
        _citas[index] = cita;
      }
    }
    await _saveCitasCache();
    refreshReporte();
    notifyListeners();
  }

  Future<void> deleteCita(String id) async {
    try {
      await _api.deleteCita(id);
    } catch (_) {}
    _citas.removeWhere((c) => c.id == id);
    await _saveCitasCache();
    refreshReporte();
    notifyListeners();
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
    await _saveServiciosCache();
    notifyListeners();
    return s;
  }

  Future<void> updateServicio({
    required String id,
    required String nombre,
    required String categoria,
    String? descripcion,
    required double precioBase,
    int? duracionMinutos,
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
          duracionMinutos: duracionMinutos ?? existing.duracionMinutos,
          precioBase: precioBase,
        );
      }
    }
    await _saveServiciosCache();
    notifyListeners();
  }

  Future<void> deleteServicio(String id) async {
    try {
      await _api.deleteServicio(id);
    } catch (_) {}
    _servicios.removeWhere((s) => s.id == id);
    await _saveServiciosCache();
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

  Future<void> updateGasto({
    required String id,
    required double monto,
    required String categoria,
    String? concepto,
  }) async {
    final updated = await _api.updateGasto(id, monto: monto, categoria: categoria, concepto: concepto);
    final idx = _gastos.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _totalGastos = _totalGastos - _gastos[idx].monto + updated.monto;
      _gastos[idx] = updated;
    }
    refreshReporte();
    notifyListeners();
  }

  Future<void> deleteGasto(String id) async {
    try {
      await _api.deleteGasto(id);
    } catch (_) {}
    final idx = _gastos.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _totalGastos -= _gastos[idx].monto;
      _gastos.removeAt(idx);
    }
    refreshReporte();
    notifyListeners();
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

  Future<void> updateVentaProducto({
    required String id,
    required String nombre,
    required double costo,
    required double precio,
    int cantidad = 1,
    String? nombreCliente,
  }) async {
    final updated = await _api.updateVentaProducto(
      id,
      nombre: nombre,
      costo: costo,
      precio: precio,
      cantidad: cantidad,
      nombreCliente: nombreCliente,
    );
    final idx = _ventas.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final old = _ventas[idx];
      _totalVentas = _totalVentas - (old.precioVenta * old.cantidad) + (updated.precioVenta * updated.cantidad);
      _gananciaVentas = _gananciaVentas - ((old.precioVenta - old.precioCosto) * old.cantidad) + ((updated.precioVenta - updated.precioCosto) * updated.cantidad);
      _ventas[idx] = updated;
    }
    refreshReporte();
    notifyListeners();
  }

  Future<void> deleteVentaProducto(String id) async {
    try {
      await _api.deleteVentaProducto(id);
    } catch (_) {}
    final idx = _ventas.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final old = _ventas[idx];
      _totalVentas -= (old.precioVenta * old.cantidad);
      _gananciaVentas -= ((old.precioVenta - old.precioCosto) * old.cantidad);
      _ventas.removeAt(idx);
    }
    refreshReporte();
    notifyListeners();
  }

  // Galeria Actions
  Future<GaleriaItem> createFotoGaleria({
    required String titulo,
    required String categoria,
    required String imagenUrl,
    String? descripcion,
    bool destacado = false,
  }) async {
    final item = await _api.createFotoGaleria(
      titulo: titulo,
      categoria: categoria,
      imagenUrl: imagenUrl,
      descripcion: descripcion,
      destacado: destacado,
    );
    _galeria.insert(0, item);
    notifyListeners();
    return item;
  }

  Future<void> deleteFotoGaleria(String id) async {
    try {
      await _api.deleteFotoGaleria(id);
    } catch (_) {}
    _galeria.removeWhere((g) => g.id == id);
    notifyListeners();
  }
}
