import 'package:flutter/foundation.dart';
import '../models/cita.dart';
import '../models/servicio.dart';
import '../models/promocion.dart';
import '../models/gasto.dart';
import '../models/venta_producto.dart';
import '../models/reporte_financiero.dart';
import '../models/galeria_item.dart';
import '../models/curso_item.dart';
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
  bool get isLoading => _isLoading;
  bool get isBackendConnected => _isBackendConnected;
  String? get errorMessage => _errorMessage;
  String get currentBaseUrl => _api.currentBaseUrl;

  Future<void> init() async {
    await _api.init();
    await loadAllData();
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
      notas: notas,
    );

    final newCita = result['cita'] as Cita;
    _citas.insert(0, newCita);
    refreshReporte();
    notifyListeners();
    return result;
  }

  Future<void> updateCitaStatus(String id, {String? estado, String? estadoPago}) async {
    final updated = await _api.updateCitaEstado(id, estado: estado, estadoPago: estadoPago);
    final index = _citas.indexWhere((c) => c.id == id);
    if (index != -1) {
      _citas[index] = updated;
      notifyListeners();
      refreshReporte();
    }
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

  // Promociones Actions
  Future<Promocion> createPromocion({
    required String titulo,
    String? descripcion,
    double? porcentajeDescuento,
    double? montoDescuento,
    String? fechaInicio,
    required String fechaFin,
    String? imagenUrl,
  }) async {
    final p = await _api.createPromocion(
      titulo: titulo,
      descripcion: descripcion,
      porcentajeDescuento: porcentajeDescuento,
      montoDescuento: montoDescuento,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      imagenUrl: imagenUrl,
    );
    _promociones.add(p);
    notifyListeners();
    return p;
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
