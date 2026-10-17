import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/phone_utils.dart';
import '../widgets/edit_appointment_dialog.dart';
import '../widgets/kpi_card.dart';
import '../widgets/new_appointment_dialog.dart';
import '../widgets/status_badge.dart';

class DashboardTab extends StatelessWidget {
  final Function(int tabIndex, {Cita? citaParaCalcular})? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final citas = provider.citas;

    final now = DateTime.now();
    final hoyStr = DateFormat('yyyy-MM-dd').format(now);
    final mananaStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    final citasHoy = citas.where((c) => c.fechaCita == hoyStr && c.estado.toLowerCase() != 'cancelada').toList();
    final citasManana = citas.where((c) => c.fechaCita == mananaStr && c.estado.toLowerCase() != 'cancelada').toList();

    final pendientesHoy = citasHoy.where((c) => c.estado == 'pendiente' || c.estado == 'confirmada').toList();
    final pendientesManana = citasManana.where((c) => c.estado == 'pendiente' || c.estado == 'confirmada').toList();

    return RefreshIndicator(
      onRefresh: () => provider.loadAllData(),
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Welcome Header Banner ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryDark, AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.25),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.spa_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            const Text(
                              'KELITA BURI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('EEEE d MMMM', 'es').format(now).toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¡Hola Kelita! 💇‍♀️',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Builder(
                    builder: (context) {
                      final nHoy = pendientesHoy.length;
                      final nManana = pendientesManana.length;
                      String texto;
                      if (nHoy == 0 && nManana == 0) {
                        texto = 'No tienes citas agendadas para hoy ni mañana.';
                      } else if (nHoy > 0 && nManana == 0) {
                        texto = 'Tienes $nHoy ${nHoy == 1 ? "cita" : "citas"} para hoy.';
                      } else if (nHoy == 0 && nManana > 0) {
                        texto = 'Tienes $nManana ${nManana == 1 ? "cita" : "citas"} para mañana.';
                      } else {
                        texto = 'Tienes $nHoy ${nHoy == 1 ? "cita" : "citas"} para hoy y $nManana para mañana.';
                      }
                      return Text(
                        texto,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final result = await showDialog<String>(
                              context: context,
                              builder: (_) => const NewAppointmentDialog(),
                            );
                            if (result == 'open_calculadora') {
                              onNavigateToTab?.call(4);
                            }
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Nueva Cita', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigateToTab?.call(1),
                          icon: const Icon(Icons.calendar_month_rounded, size: 16),
                          label: const Text('Ver Agenda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ═════════════════════════════════════════════════════════
            // 1. SECCIÓN CITAS PENDIENTES DE HOY
            // ═════════════════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Citas de HOY (${citasHoy.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd/MM').format(now),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (citasHoy.isEmpty)
              _buildEmptyDayCard('No tienes citas agendadas para hoy.', Icons.wb_sunny_outlined)
            else
              Column(
                children: citasHoy.map((cita) => _buildCitaCard(context, provider, cita, isHoy: true)).toList(),
              ),

            const SizedBox(height: 24),

            // ═════════════════════════════════════════════════════════
            // 2. SECCIÓN CITAS DEL DÍA SIGUIENTE (MAÑANA)
            // ═════════════════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Citas de MAÑANA (${citasManana.length})',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  DateFormat('dd/MM').format(now.add(const Duration(days: 1))),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (citasManana.isEmpty)
              _buildEmptyDayCard('No tienes citas agendadas para mañana.', Icons.calendar_today_outlined)
            else
              Column(
                children: citasManana.map((cita) => _buildCitaCard(context, provider, cita, isHoy: false)).toList(),
              ),

            const SizedBox(height: 24),

            // ═════════════════════════════════════════════════════════
            // 3. RESUMEN MENSUAL DE FINANZAS
            // ═════════════════════════════════════════════════════════
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Resumen Mensual de Finanzas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    DateFormat('MMMM yyyy', 'es').format(now).toUpperCase(),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.35,
              children: [
                KpiCard(
                  title: 'Servicios Citas',
                  value: '\$${provider.gananciasCitasEsteMes.toStringAsFixed(2)}',
                  subtitle: 'Citas realizadas del mes',
                  icon: Icons.content_cut_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFD1FAE5),
                ),
                KpiCard(
                  title: 'Total Ingresos',
                  value: '\$${provider.totalIngresosEsteMes.toStringAsFixed(2)}',
                  subtitle: 'Citas + Ventas',
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFDBEAFE),
                ),
                KpiCard(
                  title: 'Gastos Registrados',
                  value: '\$${provider.gastosEsteMes.toStringAsFixed(2)}',
                  subtitle: 'Egresos del mes',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppTheme.danger,
                  iconBgColor: const Color(0xFFFFE4E6),
                  valueColor: AppTheme.danger,
                ),
                KpiCard(
                  title: 'Balance Neto',
                  value: '\$${provider.balanceNetoEsteMes.toStringAsFixed(2)}',
                  subtitle: 'Ganancia real del mes',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppTheme.primary,
                  iconBgColor: AppTheme.primaryLight,
                  valueColor: provider.balanceNetoEsteMes >= 0 ? AppTheme.primary : AppTheme.danger,
                ),
              ],
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyDayCard(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textMuted, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  bool _esServicioColor(Cita cita) {
    final nom = (cita.servicios?.nombre ?? '').toLowerCase();
    final cat = (cita.servicios?.categoria ?? '').toLowerCase();
    return cat.contains('color') ||
        cat.contains('tinte') ||
        nom.contains('color') ||
        nom.contains('tinte') ||
        nom.contains('balayage') ||
        nom.contains('mechas') ||
        nom.contains('decolor') ||
        nom.contains('matiz');
  }

  Widget _buildCitaCard(BuildContext context, AppStateProvider provider, Cita cita, {required bool isHoy}) {
    final esPagado = cita.estadoPago == 'pagado' || cita.estado == 'realizada';
    final esColor = _esServicioColor(cita);

    final Color accentColor = esPagado
        ? const Color(0xFF64748B)
        : (esColor ? AppTheme.primaryDark : AppTheme.primary);
    final Color accentBg = esPagado
        ? const Color(0xFFE2E8F0)
        : (isHoy ? const Color(0xFFFDF2F8) : const Color(0xFFEFF4FF));
    final Color accentBorder = esPagado
        ? const Color(0xFFCBD5E1)
        : (isHoy ? const Color(0xFFFBCFE8) : const Color(0xFFDCE9FF));

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
          // Banner de color si aplica
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
                            cita.horaFin,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Info
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
                onNavigateToTab?.call(4, citaParaCalcular: cita);
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
                onTap: () => onNavigateToTab?.call(4, citaParaCalcular: cita),
              ),
          ],
        ] else if (cita.estado == 'calcular')
          _buildActionBtn(
            icon: Icons.calculate_rounded,
            label: 'Ir a Calcular',
            bgColor: const Color(0xFFFFEDD5),
            fgColor: const Color(0xFFEA580C),
            onTap: () => onNavigateToTab?.call(4, citaParaCalcular: cita),
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
}
