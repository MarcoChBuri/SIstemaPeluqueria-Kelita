import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/evento_nota.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class NewEventoDialog extends StatefulWidget {
  final String initialFecha;
  const NewEventoDialog({super.key, required this.initialFecha});

  @override
  State<NewEventoDialog> createState() => _NewEventoDialogState();
}

class _NewEventoDialogState extends State<NewEventoDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _tituloCtrl;
  late TextEditingController _descCtrl;
  late String _fecha;
  late String _horaInicio;
  late String _horaFin;
  String _tipo = 'bloqueo';
  String _colorHex = '#3B82F6';
  bool _conNotificacion = true;
  bool _isSubmitting = false;

  final List<String> _horasSlots = [
    '08:00', '08:30', '09:00', '09:30', '10:00', '10:30', '11:00', '11:30',
    '12:00', '12:30', '13:00', '13:30', '14:00', '14:30', '15:00', '15:30',
    '16:00', '16:30', '17:00', '17:30', '18:00', '18:30', '19:00', '19:30', '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _tituloCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _fecha = widget.initialFecha.isNotEmpty
        ? widget.initialFecha
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    _horaInicio = '12:00';
    _horaFin = '13:00';
  }

  @override
  void dispose() {
    _tituloCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final nuevoEvento = EventoNota(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        titulo: _tituloCtrl.text.trim(),
        descripcion: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        fecha: _fecha,
        horaInicio: _horaInicio,
        horaFin: _horaFin,
        tipo: _tipo,
        colorHex: _colorHex,
        conNotificacion: _conNotificacion,
      );

      await provider.addEventoNota(nuevoEvento);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Evento "${nuevoEvento.titulo}" anotado en la agenda.'),
            backgroundColor: const Color(0xFF059669),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error guardando evento: $e'), backgroundColor: AppTheme.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
                      const Row(
                        children: [
                          Icon(Icons.event_note_rounded, color: AppTheme.primary, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Anotar Evento o Bloqueo',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const Text(
                    'Registra reuniones, asuntos personales o bloqueos para recibir notificaciones.',
                    style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),

                  // Título
                  TextFormField(
                    controller: _tituloCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Título del Evento *',
                      hintText: 'Ej. Almuerzo, Compra de productos...',
                      prefixIcon: Icon(Icons.bookmark_outline_rounded, size: 20),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Ingresa un título' : null,
                  ),
                  const SizedBox(height: 12),

                  // Tipo de Evento / Bloqueo
                  DropdownButtonFormField<String>(
                    value: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                      prefixIcon: Icon(Icons.category_outlined, size: 20),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'bloqueo', child: Text('🔒 Bloqueo de Horario')),
                      DropdownMenuItem(value: 'personal', child: Text('👤 Asunto Personal')),
                      DropdownMenuItem(value: 'evento', child: Text('🎉 Evento Especial')),
                      DropdownMenuItem(value: 'recordatorio', child: Text('🔔 Recordatorio')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _tipo = val;
                          if (val == 'bloqueo') _colorHex = '#EF4444';
                          else if (val == 'personal') _colorHex = '#3B82F6';
                          else if (val == 'evento') _colorHex = '#F59E0B';
                          else _colorHex = '#8B5CF6';
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Fecha Selector
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.tryParse(_fecha) ?? DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => _fecha = DateFormat('yyyy-MM-dd').format(picked));
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 20, color: AppTheme.primary),
                              const SizedBox(width: 8),
                              Text('Fecha: $_fecha', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Icon(Icons.edit_calendar_rounded, size: 18, color: AppTheme.textMuted),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Horas Selector
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _horaInicio,
                          decoration: const InputDecoration(labelText: 'Hora Inicio'),
                          items: _horasSlots.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                          onChanged: (val) => setState(() => _horaInicio = val!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _horaFin,
                          decoration: const InputDecoration(labelText: 'Hora Fin'),
                          items: _horasSlots.map((h) => DropdownMenuItem(value: h, child: Text(h))).toList(),
                          onChanged: (val) => setState(() => _horaFin = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notas opcionales
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas adicionales (Opcional)',
                      hintText: 'Detalles del evento...',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notificación Switch
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppTheme.primary,
                    title: const Text('Activar Notificación / Recordatorio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    subtitle: const Text('Te enviará una alerta en tu celular', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                    value: _conNotificacion,
                    onChanged: (v) => setState(() => _conNotificacion = v),
                  ),

                  const SizedBox(height: 20),

                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Anotar en Agenda', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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
