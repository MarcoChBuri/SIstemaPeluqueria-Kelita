import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cita.dart';
import '../models/servicio.dart';
import '../models/promocion.dart';
import '../models/promocion_cliente.dart';
import '../models/gasto.dart';
import '../models/venta_producto.dart';
import '../models/reporte_financiero.dart';
import '../models/galeria_item.dart';
import '../models/curso_item.dart';
import '../models/evento_nota.dart';
import '../models/cliente.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/phone_utils.dart';

class AppStateProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  static final List<Servicio> defaultServicios = [
    Servicio(
      id: '1b1e42e8-81e1-4d01-91a6-ba0978e209ed',
      nombre: 'Corte de Cabello Caballeros',
      categoria: 'corte',
      duracionMinutos: 30,
      precioBase: 8.0,
      descripcion: 'Degradado / clásico con lavado y perfilado.',
      activo: true,
    ),
    Servicio(
      id: '314abaf4-14a7-44cf-9802-fbb43866e1b1',
      nombre: 'Corte de Cabello & Peinado Damas',
      categoria: 'corte',
      duracionMinutos: 45,
      precioBase: 15.0,
      descripcion: 'Lavado especial, asesoría de visagismo, corte y secado con ondas.',
      activo: true,
    ),
    Servicio(
      id: '62e18ce9-892f-4c67-a72a-dabab20d0529',
      nombre: 'Balayage & Colorimetría Premium',
      categoria: 'colorimetria',
      duracionMinutos: 180,
      precioBase: 85.0,
      descripcion: 'Diseño de color personalizado, decoloración y matiz con tratamiento hidratante.',
      activo: true,
    ),
    Servicio(
      id: '8df466a9-66be-4f86-b545-4d6ae5d829c4',
      nombre: 'Alisado Orgánico Pro',
      categoria: 'tratamiento',
      duracionMinutos: 150,
      precioBase: 70.0,
      descripcion: 'Tratamiento sin formol que reestructura y alisa el cabello hasta por 4 meses.',
      activo: true,
    ),
    Servicio(
      id: '69bcf344-eb28-4a8a-84e1-a7cef32946be',
      nombre: 'Lifting de Pestañas & Perfilado Cejas',
      categoria: 'pestanas_cejas',
      duracionMinutos: 60,
      precioBase: 25.0,
      descripcion: 'Curvatura natural de pestañas con keratina y diseño de cejas con tinte henna.',
      activo: true,
    ),
    Servicio(
      id: '6c24b788-c666-4924-8ac2-c2f683ff65ea',
      nombre: 'Paquete Novia Radiante (Boda)',
      categoria: 'paquete_bodas',
      duracionMinutos: 240,
      precioBase: 150.0,
      descripcion: 'Prueba de peinado + peinado día del evento + maquillaje blindado con fijación 24h + colocación de velo.',
      activo: true,
    ),
    Servicio(
      id: '1732bee4-4e03-4f50-b6ca-2f89681e2ae2',
      nombre: 'Paquete Quinceañera Encantada',
      categoria: 'paquete_quinceanera',
      duracionMinutos: 180,
      precioBase: 95.0,
      descripcion: 'Maquillaje profesional HD + peinado con corona/tocado + pestañas punto a punto.',
      activo: true,
    ),
  ];

  List<Cita> _citas = [];
  List<Servicio> _servicios = List.from(defaultServicios);
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
  List<PromocionCliente> _promocionesCliente = [];

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
  List<PromocionCliente> get promocionesCliente => _promocionesCliente;
  bool get isLoading => _isLoading;
  bool get isBackendConnected => _isBackendConnected;
  String? get errorMessage => _errorMessage;
  String get currentBaseUrl => _api.currentBaseUrl;

  /// Normaliza un número telefónico para WhatsApp (código Ecuador 593)
  static String normalizarTelefonoWhatsApp(String telefono) {
    String clean = telefono.replaceAll(RegExp(r'[^0-9+]'), '');
    // Si empieza con + ya tiene código de país
    if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }
    // Si empieza con 0 → quitar y poner 593 (Ecuador)
    if (clean.startsWith('0')) {
      clean = '593${clean.substring(1)}';
    }
    // Si tiene 9-10 dígitos sin código de país → asumir Ecuador
    if (clean.length <= 10 && !clean.startsWith('593')) {
      clean = '593$clean';
    }
    return clean;
  }

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
    await _loadPromocionesCliente();
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
        final loaded = decoded.map((e) => Servicio.fromJson(e)).toList();
        if (loaded.isNotEmpty) {
          _servicios = loaded;
        } else {
          _servicios = List.from(defaultServicios);
        }
      } else if (_servicios.isEmpty) {
        _servicios = List.from(defaultServicios);
      }

      final rawClientes = prefs.getString('raquel_clientes_cache');
      if (rawClientes != null && rawClientes.isNotEmpty) {
        final List decoded = jsonDecode(rawClientes);
        _clientes = decoded.map((e) => Cliente.fromJson(e)).toList();
      }

      final rawVentas = prefs.getString('raquel_ventas_cache');
      if (rawVentas != null && rawVentas.isNotEmpty) {
        final List decoded = jsonDecode(rawVentas);
        _ventas = decoded.map((e) => VentaProducto.fromJson(e)).toList();
        _totalVentas = _ventas.fold(0.0, (sum, v) => sum + (v.precioVenta * v.cantidad));
        _gananciaVentas = _ventas.fold(0.0, (sum, v) => sum + ((v.precioVenta - v.precioCosto) * v.cantidad));
      }

      final rawGastos = prefs.getString('raquel_gastos_cache');
      if (rawGastos != null && rawGastos.isNotEmpty) {
        final List decoded = jsonDecode(rawGastos);
        _gastos = decoded.map((e) => Gasto.fromJson(e)).toList();
        _totalGastos = _gastos.fold(0.0, (sum, g) => sum + g.monto);
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

  Future<void> _saveVentasCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_ventas.map((v) => v.toJson()).toList());
      await prefs.setString('raquel_ventas_cache', raw);
    } catch (_) {}
  }

  Future<void> _saveGastosCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(_gastos.map((g) => g.toJson()).toList());
      await prefs.setString('raquel_gastos_cache', raw);
    } catch (_) {}
  }

  String _clienteKey(String telefono, String nombre) {
    final cleanPhone = formatEcuadorPhone(telefono);
    if (cleanPhone.isNotEmpty) return cleanPhone;
    return nombre.trim().toLowerCase();
  }

  void _actualizarClientesDesdeCitas([List<Cliente>? apiList]) {
    final Map<String, Cliente> mapa = {};

    // 1. Clientes locales
    for (var c in _clientes) {
      final key = _clienteKey(c.telefono, c.nombre);
      if (key.isNotEmpty) mapa[key] = c;
    }

    // 2. Si vienen de la BD / API (centralizados y autoritativos)
    if (apiList != null) {
      for (var inc in apiList) {
        final key = _clienteKey(inc.telefono, inc.nombre);
        if (key.isEmpty) continue;
        final existing = mapa[key];
        if (existing == null) {
          mapa[key] = inc;
        } else {
          mapa[key] = Cliente(
            id: inc.id.isNotEmpty ? inc.id : existing.id,
            nombre: inc.nombre.isNotEmpty ? inc.nombre : existing.nombre,
            telefono: inc.telefono.isNotEmpty ? inc.telefono : existing.telefono,
            email: inc.email ?? existing.email,
            notas: (inc.notas != null && inc.notas!.isNotEmpty) ? inc.notas : existing.notas,
            totalCitas: max(inc.totalCitas, existing.totalCitas),
            totalGastado: max(inc.totalGastado, existing.totalGastado),
            ultimaVisita: inc.ultimaVisita ?? existing.ultimaVisita,
          );
        }
      }
    }

    // 3. Revisar el historial de citas para complementar citas de clientes existentes o nuevos
    for (var cita in _citas) {
      final key = _clienteKey(cita.clienteTelefono, cita.clienteNombre);
      if (key.isEmpty) continue;
      final existing = mapa[key];
      final esPagada = cita.estadoPago == 'pagado' || cita.estado == 'completada' || cita.estado == 'realizada';
      if (existing == null) {
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
    final key = _clienteKey(cliente.telefono, cliente.nombre);
    _clientes.removeWhere((c) => _clienteKey(c.telefono, c.nombre) == key);
    _clientes.insert(0, cliente);
    await _saveClientesCache();
    notifyListeners();

    try {
      final saved = await _api.saveCliente(cliente);
      final idx = _clientes.indexWhere((c) => _clienteKey(c.telefono, c.nombre) == key);
      if (idx != -1) {
        _clientes[idx] = saved;
        await _saveClientesCache();
        notifyListeners();
      }
    } catch (_) {
      // Offline fallback: permanece en caché local
    }
  }

  Future<void> removeCliente(String id) async {
    _clientes.removeWhere((c) => c.id == id);
    await _saveClientesCache();
    notifyListeners();

    try {
      await _api.deleteCliente(id);
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
        _api.getClientes().catchError((_) => <Cliente>[]),
      ]);

      final apiCitas = results[0] as List<Cita>;
      if (apiCitas.isNotEmpty || _isBackendConnected) {
        _citas = apiCitas;
        _citas.sort((a, b) => (b.fechaCita + b.horaInicio).compareTo(a.fechaCita + a.horaInicio));
        await _saveCitasCache();
      }

      final apiServicios = results[1] as List<Servicio>;
      if (apiServicios.isNotEmpty) {
        _servicios = apiServicios;
        await _saveServiciosCache();
      } else if (_servicios.isEmpty) {
        _servicios = List.from(defaultServicios);
        await _saveServiciosCache();
      }

      _promociones = results[2] as List<Promocion>;
      _reporte = results[3] as ReporteFinanciero;

      final gastosMap = results[4] as Map<String, dynamic>;
      _gastos = gastosMap['gastos'] as List<Gasto>;
      _totalGastos = gastosMap['total'] as double;
      await _saveGastosCache();

      final ventasMap = results[5] as Map<String, dynamic>;
      _ventas = ventasMap['ventas'] as List<VentaProducto>;
      _totalVentas = ventasMap['total_ventas'] as double;
      _gananciaVentas = ventasMap['ganancia_total'] as double;
      await _saveVentasCache();

      _galeria = results[6] as List<GaleriaItem>;
      _cursos = results[7] as List<CursoItem>;
      final apiClientes = results[8] as List<Cliente>;

      _actualizarClientesDesdeCitas(apiClientes);
      await _saveClientesCache();
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

  Future<void> restaurarServiciosPredeterminados() async {
    _servicios = List.from(defaultServicios);
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
    } catch (e) {
      debugPrint('[AppStateProvider] Error al actualizar promocion: $e');
      rethrow;
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
    // 1. Revisar primero en cupones asignados a clientas específicas
    final localResult = canjearQrPromocionCliente(codigoQr);
    if (localResult['valida'] == true ||
        (localResult['mensaje']?.toString().contains('ya fue canjeado') ?? false)) {
      return localResult;
    }
    // 2. Si no es un QR asignado localmente, consultar con el backend
    try {
      return await _api.validarQrPromocion(codigoQr);
    } catch (_) {
      return localResult;
    }
  }


  // Gastos Actions
  Future<Gasto> createGasto({
    required double monto,
    required String categoria,
    String? concepto,
  }) async {
    Gasto g;
    try {
      g = await _api.createGasto(monto: monto, categoria: categoria, concepto: concepto);
    } catch (_) {
      g = Gasto(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        fecha: DateTime.now().toIso8601String(),
        monto: monto,
        categoria: categoria,
        concepto: concepto,
      );
    }
    _gastos.insert(0, g);
    _totalGastos += g.monto;
    await _saveGastosCache();
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
    Gasto updated;
    try {
      updated = await _api.updateGasto(id, monto: monto, categoria: categoria, concepto: concepto);
    } catch (_) {
      updated = Gasto(
        id: id,
        fecha: DateTime.now().toIso8601String(),
        monto: monto,
        categoria: categoria,
        concepto: concepto,
      );
    }
    final idx = _gastos.indexWhere((g) => g.id == id);
    if (idx != -1) {
      _totalGastos = _totalGastos - _gastos[idx].monto + updated.monto;
      _gastos[idx] = updated;
    }
    await _saveGastosCache();
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
    await _saveGastosCache();
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
    VentaProducto v;
    try {
      v = await _api.createVentaProducto(
        nombre: nombre,
        costo: costo,
        precio: precio,
        cantidad: cantidad,
        nombreCliente: nombreCliente,
      );
    } catch (_) {
      v = VentaProducto(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        fecha: DateTime.now().toIso8601String(),
        nombreProducto: nombre,
        nombreCliente: nombreCliente,
        precioCosto: costo,
        precioVenta: precio,
        cantidad: cantidad,
        ganancia: (precio - costo) * cantidad,
      );
    }
    _ventas.insert(0, v);
    _totalVentas += (v.precioVenta * v.cantidad);
    _gananciaVentas += ((v.precioVenta - v.precioCosto) * v.cantidad);
    await _saveVentasCache();
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
    VentaProducto updated;
    try {
      updated = await _api.updateVentaProducto(
        id,
        nombre: nombre,
        costo: costo,
        precio: precio,
        cantidad: cantidad,
        nombreCliente: nombreCliente,
      );
    } catch (_) {
      updated = VentaProducto(
        id: id,
        fecha: DateTime.now().toIso8601String(),
        nombreProducto: nombre,
        nombreCliente: nombreCliente,
        precioCosto: costo,
        precioVenta: precio,
        cantidad: cantidad,
        ganancia: (precio - costo) * cantidad,
      );
    }
    final idx = _ventas.indexWhere((v) => v.id == id);
    if (idx != -1) {
      final old = _ventas[idx];
      _totalVentas = _totalVentas - (old.precioVenta * old.cantidad) + (updated.precioVenta * updated.cantidad);
      _gananciaVentas = _gananciaVentas - ((old.precioVenta - old.precioCosto) * old.cantidad) + ((updated.precioVenta - updated.precioCosto) * updated.cantidad);
      _ventas[idx] = updated;
    }
    await _saveVentasCache();
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
    await _saveVentasCache();
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

  // ═══════════════════════════════════════════════════════════
  // PROMOCIONES POR CLIENTA (QR único asignado)
  // ═══════════════════════════════════════════════════════════

  Future<void> _loadPromocionesCliente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = prefs.getString('raquel_promociones_cliente');
      if (rawJson != null && rawJson.isNotEmpty) {
        final List decoded = jsonDecode(rawJson);
        _promocionesCliente = decoded.map((e) => PromocionCliente.fromJson(e)).toList();
      }
    } catch (_) {}
  }

  Future<void> _savePromocionesCliente() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawJson = jsonEncode(_promocionesCliente.map((e) => e.toJson()).toList());
      await prefs.setString('raquel_promociones_cliente', rawJson);
    } catch (_) {}
  }

  /// Genera un código QR único tipo "RAQUEL-XXXX-YYYY"
  String _generarCodigoQrUnico() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    final part1 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    final part2 = List.generate(4, (_) => chars[rand.nextInt(chars.length)]).join();
    return 'RAQUEL-$part1-$part2';
  }

  /// Asigna una promoción existente a una clienta → genera QR único
  Future<PromocionCliente> asignarPromocionACliente({
    required String clienteId,
    required String clienteNombre,
    required String clienteTelefono,
    required String promocionId,
    required String promocionTitulo,
  }) async {
    final codigo = _generarCodigoQrUnico();
    final nueva = PromocionCliente(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      clienteId: clienteId,
      clienteNombre: clienteNombre,
      clienteTelefono: clienteTelefono,
      promocionId: promocionId,
      promocionTitulo: promocionTitulo,
      codigoQr: codigo,
      fechaAsignacion: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    _promocionesCliente.insert(0, nueva);
    await _savePromocionesCliente();
    notifyListeners();
    return nueva;
  }

  /// Canjea / Gasta un QR de promoción por código
  /// Retorna info del resultado
  Map<String, dynamic> canjearQrPromocionCliente(String codigoQr) {
    final idx = _promocionesCliente.indexWhere(
      (p) => p.codigoQr.toUpperCase() == codigoQr.toUpperCase(),
    );
    if (idx == -1) {
      return {'valida': false, 'mensaje': 'Código QR no encontrado en el sistema.'};
    }
    final promo = _promocionesCliente[idx];
    if (promo.canjeado) {
      return {
        'valida': false,
        'mensaje': 'Este QR ya fue canjeado el ${promo.fechaCanje}. No se puede reutilizar.',
      };
    }
    // Marcar como canjeado
    _promocionesCliente[idx] = promo.copyWith(
      canjeado: true,
      fechaCanje: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
    );
    _savePromocionesCliente();
    notifyListeners();
    return {
      'valida': true,
      'mensaje': '✅ Promoción "${promo.promocionTitulo}" canjeada exitosamente para ${promo.clienteNombre}.',
      'promocion': _promocionesCliente[idx],
    };
  }

  /// Obtener todas las promos asignadas a una clienta por su ID
  List<PromocionCliente> getPromocionesDeCliente(String clienteId) {
    return _promocionesCliente.where((p) => p.clienteId == clienteId).toList();
  }
}
