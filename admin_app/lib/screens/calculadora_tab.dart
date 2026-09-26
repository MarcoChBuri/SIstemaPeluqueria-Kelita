import 'package:flutter/material.dart';
import '../models/calculo_precio.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/new_appointment_dialog.dart';

class CalculadoraTab extends StatefulWidget {
  const CalculadoraTab({super.key});

  @override
  State<CalculadoraTab> createState() => _CalculadoraTabState();
}

class _CalculadoraTabState extends State<CalculadoraTab> {
  final ApiService _api = ApiService();

  int _porcionesDecolorante = 2;
  int _tubosTinte = 1;
  int _mezclasPeroxido = 2;
  double _horasTrabajo = 3.0;
  final double _costoExtra = 0.0;

  CalculoPrecioResult? _resultado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _calcular();
  }

  Future<void> _calcular() async {
    setState(() => _isLoading = true);
    try {
      final res = await _api.calcularPrecio(
        porcionesDecolorante: _porcionesDecolorante,
        tubosTinte: _tubosTinte,
        mezclasPeroxido: _mezclasPeroxido,
        horasTrabajo: _horasTrabajo,
        extra: _costoExtra,
      );
      if (mounted) {
        setState(() {
          _resultado = res;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Fallback local calculation matching backend formula
      final costDecol = _porcionesDecolorante * 3.50;
      final costTinte = _tubosTinte * 6.00;
      final costPerox = _mezclasPeroxido * 1.50;
      final totalMat = costDecol + costTinte + costPerox + _costoExtra;
      final matMargen = totalMat * 2.5;
      final manoObra = _horasTrabajo * 12.00;
      final precioFinal = matMargen + manoObra;

      if (mounted) {
        setState(() {
          _resultado = CalculoPrecioResult(
            ok: true,
            precioFinal: precioFinal,
            mensaje: 'Cálculo de colorimetría local',
            desglose: DesgloseCalculadora(
              decolorante: ItemCalculo(cantidad: _porcionesDecolorante, precioUnitario: 3.5, subtotal: costDecol),
              tinte: ItemCalculo(cantidad: _tubosTinte, precioUnitario: 6.0, subtotal: costTinte),
              peroxido: ItemCalculo(cantidad: _mezclasPeroxido, precioUnitario: 1.5, subtotal: costPerox),
              costoTotalMateriales: totalMat,
              multiplicador: '2.5x',
              materialesConMargen: matMargen,
              manoDeObra: ItemCalculo(cantidad: _horasTrabajo, precioUnitario: 12.0, subtotal: manoObra),
            ),
          );
          _isLoading = false;
        });
      }
    }
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
            // Header
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
                  const Text(
                    'MOTOR QUÍMICO DE COLORIMETRÍA',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('Calculadora de Precios', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 2),
                  const Text(
                    'Calcula el costo real de químicos, margen de beneficio y mano de obra para Balayage y Tintes.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Controls Card
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
                    min: 1.0,
                    max: 8.0,
                    divisions: 14,
                    label: '${_horasTrabajo.toStringAsFixed(1)} horas',
                    onChanged: (v) {
                      setState(() => _horasTrabajo = v);
                      _calcular();
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Result Card
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRECIO SUGERIDO AL CLIENTE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 1,
                        ),
                      ),
                      if (_isLoading)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(color: AppTheme.primaryLight, strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${(_resultado?.precioFinal ?? 0.0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD9E4),
                    ),
                  ),
                  const Divider(color: Color(0xFF334155), height: 24),

                  // Desglose
                  if (_resultado?.desglose != null) ...[
                    _buildBreakdownRow(
                      'Decolorante (${_resultado!.desglose!.decolorante.cantidad} un.)',
                      '\$${_resultado!.desglose!.decolorante.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildBreakdownRow(
                      'Tinte (${_resultado!.desglose!.tinte.cantidad} un.)',
                      '\$${_resultado!.desglose!.tinte.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildBreakdownRow(
                      'Peróxido (${_resultado!.desglose!.peroxido.cantidad} un.)',
                      '\$${_resultado!.desglose!.peroxido.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildBreakdownRow(
                      'Margen Materiales (2.5x)',
                      '\$${_resultado!.desglose!.materialesConMargen.toStringAsFixed(2)}',
                      isHighlight: true,
                    ),
                    _buildBreakdownRow(
                      'Mano de Obra (${_resultado!.desglose!.manoDeObra.cantidad}h x \$12)',
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
                      label: const Text('Agendar Cita con este Presupuesto'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                      ),
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isHighlight ? const Color(0xFFF1F5F9) : const Color(0xFF94A3B8),
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
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
