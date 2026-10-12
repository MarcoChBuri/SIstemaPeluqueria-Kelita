import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cita.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class EditAppointmentDialog extends StatefulWidget {
  final Cita cita;

  const EditAppointmentDialog({super.key, required this.cita});

  @override
  State<EditAppointmentDialog> createState() => _EditAppointmentDialogState();
}

class _EditAppointmentDialogState extends State<EditAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _telefonoCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _notasCtrl;

  late String _servicioId;
  late DateTime _fecha;
  late TimeOfDay _horaInicio;
  late String _estado;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.cita.clienteNombre);
    _telefonoCtrl = TextEditingController(text: widget.cita.clienteTelefono);
    _precioCtrl = TextEditingController(text: widget.cita.precioFinal.toStringAsFixed(2));
    _notasCtrl = TextEditingController(text: widget.cita.notas ?? '');

    _servicioId = widget.cita.servicioId;
    _estado = widget.cita.estado;

    // Parsear fecha
    try {
      _fecha = DateTime.parse(widget.cita.fechaCita);
    } catch (_) {
      _fecha = DateTime.now();
    }

    // Parsear hora de inicio
    try {
      final parts = widget.cita.horaInicio.split(':');
      _horaInicio = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      _horaInicio = const TimeOfDay(hour: 9, minute: 0);
    }
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _telefonoCtrl.dispose();
    _precioCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final h = tod.hour.toString().padLeft(2, '0');
    final m = tod.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final servicios = provider.servicios;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(22),
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.edit_calendar_rounded, color: AppTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Editar Cita',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Nombre Clienta
                  TextFormField(
                    controller: _nombreCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Clienta *',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                  ),
                  const SizedBox(height: 12),

                  // Teléfono
                  TextFormField(
                    controller: _telefonoCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono / WhatsApp *',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el teléfono' : null,
                  ),
                  const SizedBox(height: 12),

                  // Servicio Selector
                  DropdownButtonFormField<String>(
                    initialValue: servicios.any((s) => s.id == _servicioId)
                        ? _servicioId
                        : (servicios.isNotEmpty ? servicios.first.id : null),
                    decoration: const InputDecoration(
                      labelText: 'Servicio *',
                      prefixIcon: Icon(Icons.content_cut_rounded),
                    ),
                    items: servicios.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.nombre} (\$${s.precioBase.toStringAsFixed(2)})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _servicioId = val);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Fecha y Hora
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _fecha,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _fecha = picked);
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Fecha *',
                              prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                            ),
                            child: Text(
                              '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _horaInicio,
                            );
                            if (picked != null) {
                              // Validar horario entre 8am y 7pm
                              if (picked.hour < 8 || picked.hour >= 19) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('El salón atiende de 8:00 AM a 7:00 PM.'),
                                    backgroundColor: AppTheme.danger,
                                  ),
                                );
                                return;
                              }
                              setState(() => _horaInicio = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Hora *',
                              prefixIcon: Icon(Icons.access_time_rounded, size: 18),
                            ),
                            child: Text(
                              _horaInicio.format(context),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Estado y Precio
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: ['pendiente', 'confirmada', 'completada', 'pagada', 'cancelada'].contains(_estado.toLowerCase())
                              ? _estado.toLowerCase()
                              : 'pendiente',
                          decoration: const InputDecoration(
                            labelText: 'Estado *',
                            prefixIcon: Icon(Icons.flag_outlined, size: 18),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                            DropdownMenuItem(value: 'confirmada', child: Text('Confirmada')),
                            DropdownMenuItem(value: 'pagada', child: Text('Pagada')),
                            DropdownMenuItem(value: 'completada', child: Text('Completada')),
                            DropdownMenuItem(value: 'cancelada', child: Text('Cancelada')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _estado = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _precioCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Precio (\$) *',
                            prefixIcon: Icon(Icons.attach_money_rounded, size: 18),
                          ),
                          validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Notas
                  TextFormField(
                    controller: _notasCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas adicionales',
                      hintText: 'Detalles del color, fórmula, etc.',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Botón Guardar
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : () async {
                        if (!_formKey.currentState!.validate()) return;
                        setState(() => _isLoading = true);

                        final dateStr = '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}';
                        final timeStr = _formatTimeOfDay(_horaInicio);

                        // Buscar info del servicio
                        final servObj = servicios.firstWhere(
                          (s) => s.id == _servicioId,
                          orElse: () => servicios.first,
                        );

                        final estadoNorm = _estado == 'pagada' ? 'completada' : _estado;
                        final estadoPago = (_estado == 'pagada' || _estado == 'completada') ? 'pagado' : widget.cita.estadoPago;

                        final citaEditada = widget.cita.copyWith(
                          clienteNombre: _nombreCtrl.text.trim(),
                          clienteTelefono: _telefonoCtrl.text.trim(),
                          servicioId: _servicioId,
                          fechaCita: dateStr,
                          horaInicio: timeStr,
                          precioFinal: double.tryParse(_precioCtrl.text) ?? widget.cita.precioFinal,
                          estado: estadoNorm,
                          estadoPago: estadoPago,
                          notas: _notasCtrl.text.trim().isEmpty ? null : _notasCtrl.text.trim(),
                          servicios: CitaServicioInfo(
                            nombre: servObj.nombre,
                            duracionMinutos: servObj.duracionMinutos,
                            categoria: servObj.categoria,
                          ),
                        );

                        try {
                          await provider.updateCitaCompleta(citaEditada);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Cita actualizada y guardada con éxito.'),
                                backgroundColor: Color(0xFF047857),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            setState(() => _isLoading = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error al guardar: $e'),
                                backgroundColor: AppTheme.danger,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Guardar Cambios'),
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
