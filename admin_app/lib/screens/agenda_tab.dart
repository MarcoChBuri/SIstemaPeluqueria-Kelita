import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import '../models/evento_nota.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/phone_utils.dart';
import '../widgets/edit_appointment_dialog.dart';
import '../widgets/new_appointment_dialog.dart';
import '../widgets/new_evento_dialog.dart';
import '../widgets/status_badge.dart';

class AgendaTab extends StatefulWidget {
  final Function(int tabIndex, {Cita? citaParaCalcular})? onNavigateToTab;

  const AgendaTab({super.key, this.onNavigateToTab});

  @override
  State<AgendaTab> createState() => _AgendaTabState();
}

class _AgendaTabState extends State<AgendaTab> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _weekStart;

  // 8 AM to 8 PM slots
  final List<String> _timeSlots = [
    '08:00', '09:00', '10:00', '11:00', '12:00', '13:00',
    '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
  ];

  @override
  void initState() {
    super.initState();
    _weekStart = _calculateWeekStart(_selectedDate);
  }

  DateTime _calculateWeekStart(DateTime date) {
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

  int _timeToMinutes(String timeStr) {
    if (timeStr.trim().isEmpty) return -1;
    final clean = timeStr.trim();
    final upper = clean.toUpperCase();
    final isPM = upper.contains('PM');
    final isAM = upper.contains('AM');
    final numbersOnly = clean.replaceAll(RegExp(r'[^0-9:]'), '');
    final parts = numbersOnly.split(':');
    if (parts.isEmpty || parts[0].isEmpty) return -1;
    int h = int.tryParse(parts[0]) ?? -1;
    if (h < 0) return -1;
    int m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPM && h < 12) h += 12;
    if (isAM && h == 12) h = 0;
    return h * 60 + m;
  }

  String _minutesToTime(int totalMins) {
    final h = (totalMins ~/ 60).toString().padLeft(2, '0');
    final m = (totalMins % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool _esServicioColor(Cita cita) {
    final cat = cita.servicios?.categoria.toLowerCase() ?? '';
    final nom = cita.servicios?.nombre.toLowerCase() ?? '';
    return cat.contains('color') ||
        nom.contains('color') ||
        nom.contains('tinte') ||
        nom.contains('decolor') ||
        nom.contains('mech') ||
        nom.contains('matiz') ||
        nom.contains('balan');
  }

  void _openNewCitaDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => NewAppointmentDialog(initialDate: _selectedDate),
    );
    if (result == 'open_calculadora') {
      widget.onNavigateToTab?.call(4);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final citas = provider.citas;
    final eventosNotas = provider.eventosNotas;
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    final citasDelDia = citas.where((c) {
      if (c.fechaCita.trim().isEmpty) return false;
      final cleanDate = c.fechaCita.split('T')[0].split(' ')[0].trim();
      return cleanDate == selectedDateStr && c.estado.toLowerCase() != 'cancelada';
    }).toList()
      ..sort((a, b) => _timeToMinutes(a.horaInicio).compareTo(_timeToMinutes(b.horaInicio)));

    final eventosDelDia = eventosNotas.where((e) {
      if (e.fecha.trim().isEmpty) return false;
      final cleanDate = e.fecha.split('T')[0].split(' ')[0].trim();
      return cleanDate == selectedDateStr;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_cita',
        onPressed: _openNewCitaDialog,
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ══════════════════════════════════════════
              // 1. CABECERA SEMANAL
              // ══════════════════════════════════════════
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
                            child: const Text('HOY',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Strip semanal
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (index) {
                        final dayDate = _weekStart.add(Duration(days: index));
                        final dayStr = DateFormat('yyyy-MM-dd').format(dayDate);
                        final isSelected = DateFormat('yyyy-MM-dd').format(_selectedDate) == dayStr;
                        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dayStr;
                        final hasCitas = citas.any((c) => c.fechaCita == dayStr && c.estado != 'cancelada');
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

              const SizedBox(height: 12),

              // Leyenda + botón evento
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Citas', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF3B82F6), shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('Eventos', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('Color', style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    InkWell(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => NewEventoDialog(initialFecha: selectedDateStr),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_alert_rounded, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text('Anotar Evento',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Cabecera fecha seleccionada
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
                      DateFormat("EEEE d 'de' MMMM", 'es').format(_selectedDate),
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    Text(
                      '${citasDelDia.length} citas · ${eventosDelDia.length} eventos',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ══════════════════════════════════════════
              // 2. TIMELINE DEL DÍA (8 AM – 8 PM)
              //    Las tarjetas completas con botones van
              //    DENTRO del slot de inicio de la cita.
              // ══════════════════════════════════════════
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _timeSlots.length,
                itemBuilder: (context, slotIndex) {
                  final slotTime = _timeSlots[slotIndex];
                  final slotStartMins = _timeToMinutes(slotTime);
                  final slotEndMins = slotStartMins + 60;

                  // Citas que EMPIEZAN en este slot
                  final citasQueEmpiezanAqui = citasDelDia.where((c) {
                    final ini = _timeToMinutes(c.horaInicio);
                    return ini >= slotStartMins && ini < slotEndMins;
                  }).toList();

                  // Citas que se EXTIENDEN a este slot (no empiezan aquí)
                  final citasEnCurso = citasDelDia.where((c) {
                    final ini = _timeToMinutes(c.horaInicio);
                    int fin = _timeToMinutes(c.horaFin);
                    if (fin <= ini) fin = ini + (c.servicios?.duracionMinutos ?? 60);
                    return ini < slotStartMins && fin > slotStartMins;
                  }).toList();

                  // Eventos que abarcan este slot
                  final eventosEnSlot = eventosDelDia.where((e) {
                    final ini = _timeToMinutes(e.horaInicio);
                    int fin = _timeToMinutes(e.horaFin);
                    if (fin <= ini) fin = ini + 60;
                    return ini < slotEndMins && fin > slotStartMins;
                  }).toList();

                  final hasContent = citasQueEmpiezanAqui.isNotEmpty ||
                      citasEnCurso.isNotEmpty ||
                      eventosEnSlot.isNotEmpty;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hora
                        SizedBox(
                          width: 48,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              slotTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: hasContent ? AppTheme.primary : const Color(0xFFD1D5DB),
                              ),
                            ),
                          ),
                        ),
                        // Línea de tiempo
                        Column(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(top: 11),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasContent ? AppTheme.primary : const Color(0xFFE5E7EB),
                                border: Border.all(
                                  color: hasContent ? AppTheme.primary : const Color(0xFFD1D5DB),
                                  width: 2,
                                ),
                              ),
                            ),
                            Container(
                              width: 2,
                              height: hasContent ? null : 32,
                              constraints: hasContent ? const BoxConstraints(minHeight: 32) : null,
                              color: hasContent ? AppTheme.primary.withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
                            ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Contenido
                        Expanded(
                          child: Column(
                            children: [
                              // Citas que empiezan en este slot → tarjeta COMPLETA con botones
                              ...citasQueEmpiezanAqui.map((c) => _buildCitaCardCompleta(context, provider, c)),

                              // Citas en curso → barra de continuación compacta
                              ...citasEnCurso.map((c) {
                                int fin = _timeToMinutes(c.horaFin);
                                if (fin <= 0) fin = _timeToMinutes(c.horaInicio) + (c.servicios?.duracionMinutos ?? 60);
                                return _buildCitaEnCursoBar(c, _minutesToTime(fin));
                              }),

                              // Eventos
                              ...eventosEnSlot.map((e) {
                                final ini = _timeToMinutes(e.horaInicio);
                                final isStart = ini >= slotStartMins && ini < slotEndMins;
                                return _buildEventoBar(context, provider, e, isStart: isStart);
                              }),

                              // Slot vacío
                              if (!hasContent)
                                InkWell(
                                  onTap: _openNewCitaDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    height: 32,
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFF3F4F6)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Disponible',
                                            style: TextStyle(fontSize: 10, color: Color(0xFFD1D5DB))),
                                        Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFFD1D5DB)),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════
  // TARJETA COMPLETA DE CITA (aparece en el slot de inicio)
  // Con todos los botones de acción estilo dashboard
  // ════════════════════════════════════════════════════════════════
  Widget _buildCitaCardCompleta(BuildContext context, AppStateProvider provider, Cita cita) {
    String horaFinStr = cita.horaFin;
    if (horaFinStr.isEmpty) {
      final ini = _timeToMinutes(cita.horaInicio);
      final dur = cita.servicios?.duracionMinutos ?? 60;
      horaFinStr = _minutesToTime(ini + dur);
    }

    final esPagado = cita.estadoPago == 'pagado' || cita.estado == 'realizada';
    final esColor = _esServicioColor(cita);

    final Color accentColor = esPagado
        ? const Color(0xFF64748B)
        : (esColor ? AppTheme.primaryDark : AppTheme.primary);
    final Color accentBg = esPagado
        ? const Color(0xFFE2E8F0)
        : const Color(0xFFFDF2F8);
    final Color accentBorder = esPagado
        ? const Color(0xFFCBD5E1)
        : const Color(0xFFFBCFE8);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: esPagado
            ? const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: esPagado ? null : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: esPagado ? const Color(0xFFCBD5E1) : accentColor.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: esPagado ? Colors.black.withValues(alpha: 0.03) : accentColor.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Si es servicio de color → banner de color
          if (esColor)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                gradient: esPagado
                    ? const LinearGradient(
                        colors: [Color(0xFF64748B), Color(0xFF475569)],
                      )
                    : const LinearGradient(
                        colors: [AppTheme.primaryDark, AppTheme.primary],
                      ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  Icon(
                    esPagado ? Icons.check_circle_rounded : Icons.palette_rounded,
                    color: Colors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    esPagado ? 'SERVICIO DE COLOR · PAGADO' : 'SERVICIO DE COLOR / COLORIMETRÍA',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge de hora
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: accentBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: accentBorder),
                      ),
                      child: Column(
                        children: [
                          Text(
                            cita.horaInicio,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: accentColor,
                            ),
                          ),
                          Text(
                            horaFinStr,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info principal
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cita.clienteNombre,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: esPagado ? const Color(0xFF334155) : AppTheme.textMain,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '\$${cita.precioFinal.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: accentColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cita.servicios?.nombre ?? 'Servicio General',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              StatusBadge(status: cita.estado),
                              StatusBadge(status: cita.estadoPago, isPayment: true),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),
                Divider(
                  height: 1,
                  color: esPagado ? const Color(0xFFCBD5E1).withValues(alpha: 0.5) : const Color(0xFFF3F4F6),
                ),
                const SizedBox(height: 8),

                // ═══ BOTONES DE ACCIÓN ═══
                _buildActionButtons(context, provider, cita, esColor, esPagado),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, AppStateProvider provider, Cita cita, bool esColor, bool esPagado) {
    if (esPagado) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF94A3B8).withValues(alpha: 0.5)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF334155), size: 15),
                SizedBox(width: 6),
                Text(
                  'Pagado y Finalizado',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
          _buildActionBtn(
            icon: Icons.chat_bubble_outline_rounded,
            label: 'WhatsApp',
            bgColor: const Color(0xFFECFDF5),
            fgColor: const Color(0xFF059669),
            onTap: () async {
              final cleanPhone = formatEcuadorPhone(cita.clienteTelefono);
              final uri = Uri.parse('https://wa.me/$cleanPhone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          _buildIconActionBtn(
            icon: Icons.edit_outlined,
            color: AppTheme.textMain,
            bgColor: const Color(0xFFF1F5F9),
            borderColor: const Color(0xFFE2E8F0),
            tooltip: 'Editar Cita',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => EditAppointmentDialog(cita: cita),
            ),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // WhatsApp
        _buildActionBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'WhatsApp',
          bgColor: const Color(0xFFECFDF5),
          fgColor: const Color(0xFF059669),
          onTap: () async {
            final cleanPhone = formatEcuadorPhone(cita.clienteTelefono);
            final uri = Uri.parse(
                'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('¡Hola ${cita.clienteNombre}! Te saludamos de Peluquería Raquel para confirmar tu cita el ${cita.fechaCita} a las ${cita.horaInicio}. 🙏')}');
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        ),

        // Botón central según estado
        if (cita.estado == 'pendiente')
          _buildActionBtn(
            icon: Icons.check_circle_outline_rounded,
            label: 'Confirmar',
            bgColor: AppTheme.primaryLight,
            fgColor: AppTheme.primary,
            onTap: () => provider.updateCitaStatus(cita.id, estado: 'confirmada'),
          )
        else if (cita.estado == 'confirmada') ...[
          if (esColor && (cita.precioFinal == 0 || cita.precioFinal <= 0.0))
            _buildActionBtn(
              icon: Icons.calculate_rounded,
              label: 'Calcular Precio',
              bgColor: const Color(0xFFFFEDD5),
              fgColor: const Color(0xFFEA580C),
              onTap: () {
                widget.onNavigateToTab?.call(4, citaParaCalcular: cita);
              },
            )
          else ...[
            _buildActionBtn(
              icon: Icons.payments_rounded,
              label: 'Pagado',
              bgColor: const Color(0xFFD1FAE5),
              fgColor: const Color(0xFF047857),
              onTap: () => provider.updateCitaStatus(
                cita.id,
                estado: 'realizada',
                estadoPago: 'pagado',
              ),
            ),
            if (esColor)
              _buildIconActionBtn(
                icon: Icons.calculate_outlined,
                color: AppTheme.primary,
                bgColor: AppTheme.primaryLight,
                borderColor: AppTheme.primaryLight,
                tooltip: 'Recalcular fórmula',
                onTap: () => widget.onNavigateToTab?.call(4, citaParaCalcular: cita),
              ),
          ],
        ] else if (cita.estado == 'calcular')
          _buildActionBtn(
            icon: Icons.calculate_rounded,
            label: 'Ir a Calcular',
            bgColor: const Color(0xFFFFEDD5),
            fgColor: const Color(0xFFEA580C),
            onTap: () => widget.onNavigateToTab?.call(4, citaParaCalcular: cita),
          ),

        // Botón cancelar / borrar
        if (cita.estado == 'pendiente' || cita.estado == 'confirmada')
          _buildIconActionBtn(
            icon: Icons.cancel_outlined,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFFE4E6),
            tooltip: 'Gestionar Cita',
            onTap: () => showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Text('¿Gestionar Cita?'),
                content: Text('¿Qué deseas hacer con la cita de ${cita.clienteNombre}?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Volver', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                  OutlinedButton(
                    onPressed: () {
                      provider.updateCitaStatus(cita.id, estado: 'cancelada');
                      Navigator.pop(ctx);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE11D48),
                    ),
                    child: const Text('Marcar Cancelada'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await provider.deleteCita(cita.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🗑️ Cita eliminada del sistema.')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.danger,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Borrar Definitivamente'),
                  ),
                ],
              ),
            ),
          ),

        // Botón editar cita (disponible siempre)
        _buildIconActionBtn(
          icon: Icons.edit_outlined,
          color: AppTheme.textMain,
          bgColor: const Color(0xFFF1F5F9),
          borderColor: const Color(0xFFE2E8F0),
          tooltip: 'Editar Cita',
          onTap: () => showDialog(
            context: context,
            builder: (ctx) => EditAppointmentDialog(cita: cita),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fgColor, size: 15),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fgColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildIconActionBtn({
    required IconData icon,
    required Color color,
    required Color bgColor,
    Color? borderColor,
    String? tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ),
    );
  }

  // ════════════════════════════════════════════════
  // BARRA DE CITA EN CURSO (slots de continuación)
  // ════════════════════════════════════════════════
  Widget _buildCitaEnCursoBar(Cita cita, String horaFinStr) {
    final esPagado = cita.estadoPago == 'pagado' || cita.estado == 'realizada';
    final esColor = _esServicioColor(cita);
    final Color barColor = esPagado
        ? const Color(0xFF64748B)
        : (esColor ? AppTheme.primaryDark : AppTheme.primary);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: esPagado
            ? const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
              )
            : null,
        color: esPagado
            ? null
            : (esColor ? const Color(0xFFF5F3FF) : const Color(0xFFFFF1F2)),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: barColor, width: 4)),
      ),
      child: Row(
        children: [
          Icon(
            esPagado ? Icons.check_circle_outline_rounded : Icons.schedule_rounded,
            size: 12,
            color: barColor,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${cita.clienteNombre} · hasta $horaFinStr ${esPagado ? "(Pagado)" : ""}',
              style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.bold, color: barColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  // BARRA DE EVENTO
  // ════════════════════════════════════════════════
  Widget _buildEventoBar(BuildContext context, AppStateProvider provider, EventoNota evento,
      {required bool isStart}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: isStart ? 10 : 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: const BorderSide(color: Color(0xFF2563EB), width: 4)),
      ),
      child: isStart
          ? Row(
              children: [
                const Icon(Icons.event_note_rounded, color: Color(0xFF2563EB), size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(evento.titulo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E3A8A))),
                      Text('${evento.horaInicio} - ${evento.horaFin}',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF2563EB))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Color(0xFF93C5FD)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => provider.removeEventoNota(evento.id),
                ),
              ],
            )
          : Row(
              children: [
                const Icon(Icons.lock_clock_outlined, size: 12, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Text('${evento.titulo} · hasta ${evento.horaFin}',
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
              ],
            ),
    );
  }
}
