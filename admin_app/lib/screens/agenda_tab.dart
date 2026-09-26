import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/new_appointment_dialog.dart';
import '../widgets/status_badge.dart';

class AgendaTab extends StatefulWidget {
  const AgendaTab({super.key});

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  String _selectedEstado = 'all';
  String _selectedFecha = '';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final citas = provider.citas;

    final filteredCitas = citas.where((c) {
      if (_selectedEstado != 'all' && c.estado != _selectedEstado) return false;
      if (_selectedFecha.isNotEmpty && c.fechaCita != _selectedFecha) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const NewAppointmentDialog(),
          );
        },
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Cita', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllData(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                      'GESTIÓN DE AGENDA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Citas y Reservas', style: Theme.of(context).textTheme.headlineMedium),
                    const SizedBox(height: 2),
                    const Text(
                      'Control de horarios, estado de atención y confirmación por WhatsApp.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Filter state chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('all', 'Todas (${citas.length})'),
                    _buildFilterChip('pendiente', 'Pendientes'),
                    _buildFilterChip('confirmada', 'Confirmadas'),
                    _buildFilterChip('completada', 'Completadas'),
                    _buildFilterChip('cancelada', 'Canceladas'),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Date filter bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list_rounded, size: 18, color: AppTheme.textMuted),
                    const SizedBox(width: 8),
                    Text(
                      _selectedFecha.isEmpty
                          ? 'Filtrar por fecha: Todas'
                          : 'Fecha: $_selectedFecha',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    if (_selectedFecha.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: () => setState(() => _selectedFecha = ''),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month_rounded, color: AppTheme.primary, size: 20),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now().subtract(const Duration(days: 90)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedFecha = DateFormat('yyyy-MM-dd').format(picked));
                        }
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // List of appointments
              if (filteredCitas.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.event_busy_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text(
                        'No hay citas con los filtros seleccionados',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredCitas.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cita = filteredCitas[index];
                    return _buildAppointmentCard(context, cita, provider);
                  },
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedEstado == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textMain),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.border)),
        onSelected: (_) => setState(() => _selectedEstado = key),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Cita cita, AppStateProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Date/Time Badge + Status Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      '${cita.fechaCita} | ${cita.horaInicio}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  StatusBadge(status: cita.estado),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      final nuevoPago = cita.estadoPago == 'pagado' ? 'pendiente' : 'pagado';
                      provider.updateCitaStatus(cita.id, estadoPago: nuevoPago);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Pago marcado como $nuevoPago.')),
                      );
                    },
                    child: StatusBadge(status: cita.estadoPago, isPayment: true),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Client and Service
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryLight,
                child: Text(
                  cita.clienteNombre.isNotEmpty ? cita.clienteNombre[0].toUpperCase() : 'C',
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cita.clienteNombre,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    Text(
                      cita.servicios?.nombre ?? 'Servicio Seleccionado',
                      style: const TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w600),
                    ),
                    if (cita.notas != null && cita.notas!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Nota: ${cita.notas}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: AppTheme.textMuted),
                        ),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${cita.precioFinal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  if (cita.descuentoAplicado > 0)
                    Text(
                      'Desc. -\$${cita.descuentoAplicado.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.danger, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
            ],
          ),

          const Divider(height: 24, color: AppTheme.border),

          // Bottom Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Contact actions
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.phone_rounded, size: 18, color: AppTheme.secondary),
                    tooltip: 'Llamar',
                    onPressed: () async {
                      final uri = Uri.parse('tel:${cita.clienteTelefono}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: Color(0xFF25D366)),
                    tooltip: 'WhatsApp',
                    onPressed: () async {
                      final clean = cita.clienteTelefono.replaceAll(RegExp(r'[^0-9]'), '');
                      final msg = 'Hola ${cita.clienteNombre}, te saludamos de Peluquería Raquel con respecto a tu cita del ${cita.fechaCita} a las ${cita.horaInicio}.';
                      final uri = Uri.parse('https://wa.me/$clean?text=${Uri.encodeComponent(msg)}');
                      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                    },
                  ),
                ],
              ),

              // Status Change Dropdown / Buttons
              Wrap(
                spacing: 6,
                children: [
                  if (cita.estado == 'pendiente')
                    OutlinedButton(
                      onPressed: () => provider.updateCitaStatus(cita.id, estado: 'confirmada'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF047857),
                        side: const BorderSide(color: Color(0xFF047857)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Confirmar', style: TextStyle(fontSize: 11)),
                    ),
                  if (cita.estado != 'completada' && cita.estado != 'cancelada')
                    ElevatedButton(
                      onPressed: () => provider.updateCitaStatus(cita.id, estado: 'completada'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1D4ED8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Completar', style: TextStyle(fontSize: 11)),
                    ),
                  if (cita.estado != 'cancelada' && cita.estado != 'completada')
                    TextButton(
                      onPressed: () => provider.updateCitaStatus(cita.id, estado: 'cancelada'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.danger,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        minimumSize: Size.zero,
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontSize: 11)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
