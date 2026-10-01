import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import '../models/evento_nota.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/new_appointment_dialog.dart';
import '../widgets/new_evento_dialog.dart';
import '../widgets/status_badge.dart';

class AgendaTab extends StatefulWidget {
  const AgendaTab({super.key});

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _weekStart;

  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00'
  ];

  @override
  void initState() {
    super.initState();
    _weekStart = _calculateWeekStart(_selectedDate);
  }

  DateTime _calculateWeekStart(DateTime date) {
    // Find Monday of the current week
    return date.subtract(Duration(days: date.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _weekStart = _weekStart.subtract(const Duration(days: 7));
      _selectedDate = _weekStart;
    });
  }

  void _nextWeek() {
    setState(() {
      _weekStart = _weekStart.add(const Duration(days: 7));
      _selectedDate = _weekStart;
    });
  }

  void _selectToday() {
    setState(() {
      _selectedDate = DateTime.now();
      _weekStart = _calculateWeekStart(_selectedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final citas = provider.citas;
    final eventosNotas = provider.eventosNotas;

    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Filter appointments and events for selected date
    final citasDelDia = citas.where((c) => c.fechaCita == selectedDateStr).toList();
    final eventosDelDia = eventosNotas.where((e) => e.fecha == selectedDateStr).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'fab_evento',
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => NewEventoDialog(initialFecha: selectedDateStr),
              );
            },
            backgroundColor: const Color(0xFF3B82F6),
            foregroundColor: Colors.white,
            tooltip: 'Anotar Evento / Bloqueo',
            child: const Icon(Icons.event_note_rounded),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'fab_cita',
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
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.loadAllData(),
        color: AppTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═════════════════════════════════════════════════════════
              // 1. CABECERA & CONTROLES DE SEMANA
              // ═════════════════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: _previousWeek,
                              icon: const Icon(Icons.chevron_left_rounded, color: AppTheme.textMain),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM yyyy', 'es').format(_weekStart).toUpperCase(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _nextWeek,
                              icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textMain),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: _selectToday,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text('HOY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // ═════════════════════════════════════════════════════════
                    // 2. STRIP SEMANAL (LUNES A DOMINGO CON INDICADORES DE COLOR)
                    // ═════════════════════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final dayDate = _weekStart.add(Duration(days: index));
                        final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);
                        final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dayStr;
                        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dayStr;

                        // Check if day has appointments or events
                        final hasCitas = citas.any((c) => c.fechaCita == dayStr);
                        final hasEventos = eventosNotas.any((e) => e.fecha == dayStr);

                        return Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _selectedDate = dayDate),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : isToday
                                        ? const Color(0xFFFDF2F8)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.primary
                                      : isToday
                                          ? AppTheme.primary.withValues(alpha: 0.5)
                                          : AppTheme.border,
                                  width: isSelected || isToday ? 1.5 : 1,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    DateFormat('EEE', 'es').format(dayDate).substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white70 : AppTheme.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dayDate.day}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : AppTheme.textMain,
                                    ),
                                  ),
                                  const SizedBox(height: 6),

                                  // Indicator Dots (Color Badges)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (hasCitas)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected ? Colors.white : const Color(0xFFEF4444),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      if (hasEventos)
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.symmetric(horizontal: 1),
                                          decoration: BoxDecoration(
                                            color: isSelected ? const Color(0xFFFDE047) : const Color(0xFF3B82F6),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Leyenda de colores
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Citas Clientes', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 14),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Eventos / Bloqueos', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => NewEventoDialog(initialFecha: selectedDateStr),
                        );
                      },
                      child: const Row(
                        children: [
                          Icon(Icons.add_alert_rounded, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text('Anotar Evento', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Selected Date Banner Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('EEEE d de MMMM', 'es').format(_selectedDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    Text(
                      '${citasDelDia.length} citas | ${eventosDelDia.length} eventos',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ═════════════════════════════════════════════════════════
              // 3. DESGLOSE POR HORAS DEL DÍA (TIMELINE DE 08:00 A 20:00)
              // ═════════════════════════════════════════════════════════
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timeSlots.length,
                itemBuilder: (context, slotIndex) {
                  final slotTime = _timeSlots[slotIndex];

                  // Match appointments that fall in this hour slot
                  final citasInSlot = citasDelDia.where((c) {
                    final ini = c.horaInicio.length >= 5 ? c.horaInicio.substring(0, 5) : c.horaInicio;
                    return ini == slotTime;
                  }).toList();

                  // Match personal events that fall in this hour slot
                  final eventosInSlot = eventosDelDia.where((e) {
                    final ini = e.horaInicio.length >= 5 ? e.horaInicio.substring(0, 5) : e.horaInicio;
                    return ini == slotTime;
                  }).toList();

                  final hasItems = citasInSlot.isNotEmpty || eventosInSlot.isNotEmpty;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hour Label Column
                        SizedBox(
                          width: 50,
                          child: Text(
                            slotTime,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: hasItems ? AppTheme.primary : AppTheme.textMuted,
                            ),
                          ),
                        ),

                        // Timeline Line
                        Container(
                          width: 2,
                          height: hasItems ? 90 : 36,
                          color: hasItems ? AppTheme.primary : const Color(0xFFE5E7EB),
                          margin: const EdgeInsets.only(right: 12),
                        ),

                        // Content Cards for this hour
                        Expanded(
                          child: !hasItems
                              ? InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => const NewAppointmentDialog(),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    height: 36,
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFF3F4F6)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Disponible', style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
                                        Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF9CA3AF)),
                                      ],
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    ...eventosInSlot.map((e) => _buildEventoCard(context, provider, e)),
                                    ...citasInSlot.map((c) => _buildCitaCard(context, provider, c)),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventoCard(BuildContext context, AppStateProvider provider, EventoNota evento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.event_note_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      evento.titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A8A)),
                    ),
                    Text(
                      '${evento.horaInicio} - ${evento.horaFin}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                if (evento.descripcion != null && evento.descripcion!.isNotEmpty)
                  Text(
                    evento.descripcion!,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFF93C5FD)),
            onPressed: () => provider.removeEventoNota(evento.id),
          ),
        ],
      ),
    );
  }

  Widget _buildCitaCard(BuildContext context, AppStateProvider provider, Cita cita) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  cita.clienteNombre,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textMain),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(status: cita.estado),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${cita.servicios?.nombre ?? 'Servicio General'} (${cita.horaInicio} - ${cita.horaFin})',
                  style: const TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$${cita.precioFinal.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textMain),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () async {
                  final cleanPhone = cita.clienteTelefono.replaceAll(RegExp(r'[^0-9]'), '');
                  final uri = Uri.parse(
                      'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hola ${cita.clienteNombre}, te saludamos de Peluquería Raquel para confirmar tu cita el ${cita.fechaCita} a las ${cita.horaInicio}.')}');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Row(
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF059669), size: 14),
                    SizedBox(width: 4),
                    Text('WhatsApp', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ],
                ),
              ),
              if (cita.estado == 'pendiente')
                InkWell(
                  onTap: () => provider.updateCitaStatus(cita.id, estado: 'confirmada'),
                  child: const Text('Confirmar ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                )
              else if (cita.estado == 'confirmada')
                InkWell(
                  onTap: () => provider.updateCitaStatus(cita.id, estado: 'realizada'),
                  child: const Text('Realizada ✓', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
