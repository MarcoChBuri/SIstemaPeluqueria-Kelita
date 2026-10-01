import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class NewAppointmentDialog extends StatefulWidget {
  const NewAppointmentDialog({super.key});

  @override
  State<NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<NewAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _notasController = TextEditingController();

  String? _selectedServicioId;
  String? _selectedPromocionId;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);

  int _selectedDuracionMinutos = 60;
  bool _isSubmitting = false;
  String? _createdWhatsappUrl;
  String? _createdClienteNombre;

  @override
  void initState() {
    super.initState();
    final prov = Provider.of<AppStateProvider>(context, listen: false);
    if (prov.servicios.isNotEmpty) {
      _selectedServicioId = prov.servicios.first.id;
      _selectedDuracionMinutos = prov.servicios.first.duracionMinutos;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServicioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un servicio.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final fechaStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final horaStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final result = await provider.createCita(
        clienteNombre: _nombreController.text.trim(),
        clienteTelefono: _telefonoController.text.trim(),
        clienteEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        servicioId: _selectedServicioId!,
        promocionId: _selectedPromocionId,
        fechaCita: fechaStr,
        horaInicio: horaStr,
        duracionMinutos: _selectedDuracionMinutos,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );


      setState(() {
        _isSubmitting = false;
        _createdWhatsappUrl = result['whatsapp_url'] as String?;
        _createdClienteNombre = _nombreController.text.trim();
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final servicios = provider.servicios;
    final promociones = provider.promociones;

    if (_createdWhatsappUrl != null) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 40),
              ),
              const SizedBox(height: 16),
              Text(
                '¡Cita Agendada con Éxito!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'La cita para $_createdClienteNombre ha sido guardada en la base de datos.',
                style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              if (_createdWhatsappUrl!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_createdWhatsappUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                  label: const Text('Enviar Confirmación por WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar Ventana', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nueva Cita',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 22),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nombre Cliente
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Clienta *',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // Teléfono
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono / WhatsApp *',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      hintText: 'Ej: 0991234567',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),

                  // Email
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico (Opcional)',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Servicio
                  DropdownButtonFormField<String>(
                    initialValue: _selectedServicioId,
                    decoration: const InputDecoration(
                      labelText: 'Servicio Principal *',
                      prefixIcon: Icon(Icons.content_cut_rounded, size: 20),
                    ),
                    items: servicios.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.nombre} (\$${s.precioBase.toStringAsFixed(2)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() {
                        _selectedServicioId = val;
                        final found = servicios.firstWhere((s) => s.id == val, orElse: () => servicios.first);
                        _selectedDuracionMinutos = found.duracionMinutos;
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Duración / Tiempo a ocupar
                  DropdownButtonFormField<int>(
                    value: _selectedDuracionMinutos,
                    decoration: const InputDecoration(
                      labelText: 'Tiempo a ocupar (Horas / Minutos) *',
                      prefixIcon: Icon(Icons.timer_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 30, child: Text('30 Minutos (0.5 hora)')),
                      DropdownMenuItem(value: 60, child: Text('1 Hora (60 min)')),
                      DropdownMenuItem(value: 90, child: Text('1.5 Horas (90 min)')),
                      DropdownMenuItem(value: 120, child: Text('2 Horas (120 min)')),
                      DropdownMenuItem(value: 150, child: Text('2.5 Horas (150 min)')),
                      DropdownMenuItem(value: 180, child: Text('3 Horas (180 min)')),
                      DropdownMenuItem(value: 210, child: Text('3.5 Horas (210 min)')),
                      DropdownMenuItem(value: 240, child: Text('4 Horas (240 min)')),
                      DropdownMenuItem(value: 300, child: Text('5 Horas (300 min)')),
                      DropdownMenuItem(value: 360, child: Text('6 Horas (360 min)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDuracionMinutos = val);
                    },
                  ),
                  const SizedBox(height: 12),


                  // Promoción (Opcional)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedPromocionId,
                    decoration: const InputDecoration(
                      labelText: 'Promoción / Descuento (Opcional)',
                      prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin Promoción')),
                      ...promociones.map((p) {
                        final desc = p.porcentajeDescuento != null
                            ? '${p.porcentajeDescuento}% OFF'
                            : '\$${p.montoDescuento} OFF';
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text('${p.titulo} ($desc)'),
                        );
                      }),
                    ],
                    onChanged: (val) => setState(() => _selectedPromocionId = val),
                  ),
                  const SizedBox(height: 12),

                  // Fecha y Hora
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _selectedDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final t = await showTimePicker(
                              context: context,
                              initialTime: _selectedTime,
                            );
                            if (t != null) setState(() => _selectedTime = t);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notas
                  TextFormField(
                    controller: _notasController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas adicionales (ej: Alergias, tono deseado)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Botón Agendar
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Confirmar y Guardar Cita'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
