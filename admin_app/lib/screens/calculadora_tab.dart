import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculo_precio.dart';
import '../theme/app_theme.dart';
import '../widgets/new_appointment_dialog.dart';

class CalculadoraTab extends StatefulWidget {
  const CalculadoraTab({super.key});

  @override
  State<CalculadoraTab> createState() => _CalculadoraTabState();
}

class _CalculadoraTabState extends State<CalculadoraTab> {
  int _porcionesDecolorante = 2;
  int _tubosTinte = 1;
  int _mezclasPeroxido = 2;
  double _horasTrabajo = 3.0;
  double _costoExtra = 0.0;

  // Precios de insumos (proveedores)
  double _precioDecolorante = 3.50;
  double _precioTinte = 6.00;
  double _precioPeroxido = 1.50;
  double _precioHoraManoObra = 10.00;
  double _multiplicador = 2.5;

  CalculoPrecioResult? _resultado;

  @override
  void initState() {
    super.initState();
    _cargarPreciosLocales();
  }

  Future<void> _cargarPreciosLocales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _precioDecolorante = prefs.getDouble('prec_decol') ?? 3.50;
        _precioTinte = prefs.getDouble('prec_tinte') ?? 6.00;
        _precioPeroxido = prefs.getDouble('prec_perox') ?? 1.50;
        _precioHoraManoObra = prefs.getDouble('prec_hora') ?? 10.00;
        _multiplicador = prefs.getDouble('prec_mult') ?? 2.5;
      });
    } catch (_) {}
    _calcular();
  }

  Future<void> _guardarPreciosLocales() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('prec_decol', _precioDecolorante);
      await prefs.setDouble('prec_tinte', _precioTinte);
      await prefs.setDouble('prec_perox', _precioPeroxido);
      await prefs.setDouble('prec_hora', _precioHoraManoObra);
      await prefs.setDouble('prec_mult', _multiplicador);
    } catch (_) {}
  }

  void _calcular() {
    final costDecol = _porcionesDecolorante * _precioDecolorante;
    final costTinte = _tubosTinte * _precioTinte;
    final costPerox = _mezclasPeroxido * _precioPeroxido;
    final totalMat = costDecol + costTinte + costPerox + _costoExtra;
    final matMargen = totalMat * _multiplicador;
    final manoObra = _horasTrabajo * _precioHoraManoObra;
    final precioFinal = matMargen + manoObra;

    setState(() {
      _resultado = CalculoPrecioResult(
        ok: true,
        precioFinal: precioFinal,
        mensaje: 'Cálculo con precios de tu proveedor',
        desglose: DesgloseCalculadora(
          decolorante: ItemCalculo(
            cantidad: _porcionesDecolorante,
            precioUnitario: _precioDecolorante,
            subtotal: costDecol,
          ),
          tinte: ItemCalculo(
            cantidad: _tubosTinte,
            precioUnitario: _precioTinte,
            subtotal: costTinte,
          ),
          peroxido: ItemCalculo(
            cantidad: _mezclasPeroxido,
            precioUnitario: _precioPeroxido,
            subtotal: costPerox,
          ),
          costoTotalMateriales: totalMat,
          multiplicador: '${_multiplicador.toStringAsFixed(1)}x',
          materialesConMargen: matMargen,
          manoDeObra: ItemCalculo(
            cantidad: _horasTrabajo,
            precioUnitario: _precioHoraManoObra,
            subtotal: manoObra,
          ),
        ),
      );
    });
  }

  void _abrirDialogoAjustarPrecios() {
    final decCtrl = TextEditingController(text: _precioDecolorante.toStringAsFixed(2));
    final tinteCtrl = TextEditingController(text: _precioTinte.toStringAsFixed(2));
    final peroxCtrl = TextEditingController(text: _precioPeroxido.toStringAsFixed(2));
    final horaCtrl = TextEditingController(text: _precioHoraManoObra.toStringAsFixed(2));
    final multCtrl = TextEditingController(text: _multiplicador.toStringAsFixed(1));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajustar Precios de Insumos (Proveedor)'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: decCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Decolorante (porción \$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tinteCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Tinte / Matizador (tubo \$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: peroxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Peróxido (mezcla \$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: horaCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Mano de Obra (hora \$)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: multCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Multiplicador Margen (Ej. 2.5)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _precioDecolorante = double.tryParse(decCtrl.text) ?? _precioDecolorante;
                _precioTinte = double.tryParse(tinteCtrl.text) ?? _precioTinte;
                _precioPeroxido = double.tryParse(peroxCtrl.text) ?? _precioPeroxido;
                _precioHoraManoObra = double.tryParse(horaCtrl.text) ?? _precioHoraManoObra;
                _multiplicador = double.tryParse(multCtrl.text) ?? _multiplicador;
              });
              _guardarPreciosLocales();
              _calcular();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con Botón de Configuración
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'MOTOR QUÍMICO DE COLORIMETRÍA',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _abrirDialogoAjustarPrecios,
                        icon: const Icon(Icons.settings_suggest_rounded, size: 16),
                        label: const Text('Ajustar Precios', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primaryLight),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Calculadora de Precios', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  const Text(
                    'Calcula el costo real de insumos y mano de obra para cobros exactos.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 1. RESUMEN DE COBRO Y DESGLOSE TOTAL (ARRIBA COMO PIDIÓ EL USUARIO)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B1C30), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'PRECIO TOTAL RECOMENDADO A COBRAR',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$${(_resultado?.precioFinal ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD9E4),
                    ),
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),

                  // Desglose
                  if (_resultado?.desglose != null) ...[
                    _buildBreakdownRow(
                      'Decolorante (${_resultado!.desglose!.decolorante.cantidad} porc. x \$$_precioDecolorante)',
                      '\$${_resultado!.desglose!.decolorante.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildBreakdownRow(
                      'Tinte (${_resultado!.desglose!.tinte.cantidad} tubos x \$$_precioTinte)',
                      '\$${_resultado!.desglose!.tinte.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildBreakdownRow(
                      'Peróxido (${_resultado!.desglose!.peroxido.cantidad} mezclas x \$$_precioPeroxido)',
                      '\$${_resultado!.desglose!.peroxido.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildBreakdownRow(
                      'Margen Materiales (${_multiplicador.toStringAsFixed(1)}x)',
                      '\$${_resultado!.desglose!.materialesConMargen.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                    _buildBreakdownRow(
                      'Mano de Obra (${_resultado!.desglose!.manoDeObra.cantidad}h x \$$_precioHoraManoObra/h)',
                      '\$${_resultado!.desglose!.manoDeObra.subtotal.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => const NewAppointmentDialog(),
                        );
                      },
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text('Agendar Cita (\$${(_resultado?.precioFinal ?? 0.0).toStringAsFixed(2)})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. CONTROLES DE INSUMOS Y TIEMPO (ABAJO DEL RESUMEN)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ajustar Insumos para este Servicio', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),

                  // Decolorante Slider
                  _buildSlider(
                    title: 'Porciones de Decolorante',
                    value: _porcionesDecolorante.toDouble(),
                    min: 0,
                    max: 8,
                    divisions: 8,
                    label: '$_porcionesDecolorante porciones',
                    onChanged: (v) {
                      setState(() => _porcionesDecolorante = v.toInt());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 14),

                  // Tubos de Tinte
                  _buildSlider(
                    title: 'Tubos de Tinte / Matizador',
                    value: _tubosTinte.toDouble(),
                    min: 0,
                    max: 6,
                    divisions: 6,
                    label: '$_tubosTinte tubos',
                    onChanged: (v) {
                      setState(() => _tubosTinte = v.toInt());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 14),

                  // Mezclas de Peróxido
                  _buildSlider(
                    title: 'Mezclas de Peróxido / Revelador',
                    value: _mezclasPeroxido.toDouble(),
                    min: 0,
                    max: 8,
                    divisions: 8,
                    label: '$_mezclasPeroxido mezclas',
                    onChanged: (v) {
                      setState(() => _mezclasPeroxido = v.toInt());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 14),

                  // Horas de Trabajo
                  _buildSlider(
                    title: 'Horas Estimadas de Trabajo',
                    value: _horasTrabajo,
                    min: 0.5,
                    max: 8.0,
                    divisions: 15,
                    label: '${_horasTrabajo.toStringAsFixed(1)} horas',
                    onChanged: (v) {
                      setState(() => _horasTrabajo = v);
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 14),

                  // Costo Extra Insumos
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Costo Extra Insumos (\$):', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(
                        width: 100,
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            hintText: '0.0',
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (v) {
                            setState(() => _costoExtra = double.tryParse(v) ?? 0.0);
                            _calcular();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppTheme.primary,
          inactiveColor: const Color(0xFFEFF4FF),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildBreakdownRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isHighlight ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
                fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              color: isHighlight ? const Color(0xFFFFD9E4) : const Color(0xFFCBD5E1),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
