import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/calculo_precio.dart';
import '../models/cita.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class CalculadoraTab extends StatefulWidget {
  final Cita? citaParaCalcular;
  final Function(int tabIndex)? onNavigateToTab;

  const CalculadoraTab({
    super.key,
    this.citaParaCalcular,
    this.onNavigateToTab,
  });

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
  double _multiplicador = 1.5;

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
        final savedMult = prefs.getDouble('prec_mult');
        _multiplicador = (savedMult == null || savedMult == 2.5) ? 1.5 : savedMult;
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
    final provider = Provider.of<AppStateProvider>(context);
    final cita = widget.citaParaCalcular;

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

                  // ═══ Banner de cita pendiente de cobro ═══
                  if (cita != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFDDD6FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person_rounded, size: 16, color: Color(0xFF7C3AED)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Cita de ${cita.clienteNombre}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF4C1D95),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${cita.servicios?.nombre ?? 'Color'} · ${cita.fechaCita} ${cita.horaInicio}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF7C3AED)),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Precio calculado: \$${(_resultado?.precioFinal ?? 0.0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF4C1D95),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final precio = _resultado?.precioFinal ?? 0.0;
                                await provider.updateCitaPrecio(cita.id, precio);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '✅ Precio \$${precio.toStringAsFixed(2)} asignado a la cita de ${cita.clienteNombre}. Ya puedes marcarla como Pagada en Agenda.'),
                                      backgroundColor: const Color(0xFF047857),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                                widget.onNavigateToTab?.call(1);
                              },
                              icon: const Icon(Icons.check_circle_rounded, size: 18),
                              label: Text(
                                  'Aceptar (\$${(_resultado?.precioFinal ?? 0.0).toStringAsFixed(2)})'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: null,
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: const Text('Abre una cita de color desde la Agenda para guardar el precio'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textMuted,
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          textStyle: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ],
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
                  Text('Insumos y Tiempo de Trabajo', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 14),

                  // Decolorante Stepper
                  _buildNumericStepper(
                    title: 'Porciones de Decolorante',
                    subtitle: '\$$_precioDecolorante c/u',
                    value: _porcionesDecolorante,
                    min: 0,
                    max: 20,
                    step: 1,
                    unit: 'porc.',
                    onChanged: (v) {
                      setState(() => _porcionesDecolorante = v.toInt());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tubos de Tinte
                  _buildNumericStepper(
                    title: 'Tubos de Tinte / Matizador',
                    subtitle: '\$$_precioTinte c/u',
                    value: _tubosTinte,
                    min: 0,
                    max: 15,
                    step: 1,
                    unit: 'tubos',
                    onChanged: (v) {
                      setState(() => _tubosTinte = v.toInt());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Mezclas de Peróxido
                  _buildNumericStepper(
                    title: 'Mezclas de Peróxido',
                    subtitle: '\$$_precioPeroxido c/u',
                    value: _mezclasPeroxido,
                    min: 0,
                    max: 20,
                    step: 1,
                    unit: 'mezclas',
                    onChanged: (v) {
                      setState(() => _mezclasPeroxido = v.toInt());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 12),

                  // Horas de Trabajo
                  _buildNumericStepper(
                    title: 'Horas de Trabajo',
                    subtitle: '\$$_precioHoraManoObra / hora',
                    value: _horasTrabajo,
                    min: 0.5,
                    max: 14.0,
                    step: 0.5,
                    unit: 'horas',
                    isDecimal: true,
                    onChanged: (v) {
                      setState(() => _horasTrabajo = v.toDouble());
                      _calcular();
                    },
                  ),
                  const SizedBox(height: 14),

                  // Costo Extra Insumos
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Costo Extra Insumos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('Tratamientos especiales, ampolletas', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                        SizedBox(
                          width: 100,
                          child: TextField(
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              prefixText: '\$ ',
                              hintText: '0.00',
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (v) {
                              setState(() => _costoExtra = double.tryParse(v) ?? 0.0);
                              _calcular();
                            },
                          ),
                        ),
                      ],
                    ),
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

  Widget _buildNumericStepper({
    required String title,
    required String subtitle,
    required num value,
    required num min,
    required num max,
    required num step,
    required String unit,
    bool isDecimal = false,
    required ValueChanged<num> onChanged,
  }) {
    final displayVal = isDecimal ? value.toStringAsFixed(1) : value.toInt().toString();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                const SizedBox(height: 1),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
              ],
            ),
          ),
          Row(
            children: [
              // Botón Menos
              InkWell(
                onTap: value > min
                    ? () => onChanged(isDecimal ? (value - step) : (value - step).round())
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value > min ? Colors.white : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: value > min ? const Color(0xFFCBD5E1) : const Color(0xFFE2E8F0)),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: value > min ? AppTheme.textMain : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              // Caja de número
              Container(
                constraints: const BoxConstraints(minWidth: 54),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.center,
                child: Text(
                  '$displayVal $unit',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primary),
                ),
              ),
              // Botón Más
              InkWell(
                onTap: value < max
                    ? () => onChanged(isDecimal ? (value + step) : (value + step).round())
                    : null,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value < max ? AppTheme.primary : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: value < max ? Colors.white : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
