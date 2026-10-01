import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cita.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/kpi_card.dart';
import '../widgets/new_appointment_dialog.dart';
import '../widgets/status_badge.dart';

class DashboardTab extends StatelessWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const DashboardTab({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final reporte = provider.reporte;
    final citas = provider.citas;

    final now = DateTime.now();
    final hoyStr = DateFormat('yyyy-MM-dd').format(now);
    final mananaStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    final citasHoy = citas.where((c) => c.fechaCita == hoyStr).toList();
    final citasManana = citas.where((c) => c.fechaCita == mananaStr).toList();

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
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: provider.isBackendConnected
                                    ? const Color(0xFF34D399)
                                    : const Color(0xFFF87171),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.isBackendConnected ? 'WEB CONECTADA' : 'MODO LOCAL',
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
                      Text(
                        DateFormat('EEEE d MMMM', 'es').format(now).toUpperCase(),
                        style: const TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¡Hola Raquel! 💇‍♀️',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tienes ${pendientesHoy.length} citas para HOY y ${pendientesManana.length} para MAÑANA.',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const NewAppointmentDialog(),
                            );
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

  Widget _buildCitaCard(BuildContext context, AppStateProvider provider, Cita cita, {required bool isHoy}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHoy ? AppTheme.primary.withValues(alpha: 0.3) : AppTheme.border,
          width: isHoy ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: isHoy ? const Color(0xFFFDF2F8) : const Color(0xFFEFF4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isHoy ? const Color(0xFFFBCFE8) : const Color(0xFFDCE9FF),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      cita.horaInicio,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isHoy ? AppTheme.primary : AppTheme.secondary,
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '\$${cita.precioFinal.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primary),
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
                    Row(
                      children: [
                        StatusBadge(status: cita.estado),
                        const SizedBox(width: 6),
                        StatusBadge(status: cita.estadoPago, isPayment: true),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 8),

          // Action Buttons: WhatsApp + Quick Confirm
          Row(
            children: [
              // WhatsApp Button
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final cleanPhone = cita.clienteTelefono.replaceAll(RegExp(r'[^0-9]'), '');
                    final uri = Uri.parse(
                        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('¡Hola ${cita.clienteNombre}! Te saludamos de Peluquería Raquel para confirmar tu cita el ${cita.fechaCita} a las ${cita.horaInicio}. 🙏')}');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF059669), size: 16),
                        SizedBox(width: 6),
                        Text('WhatsApp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status Change Dropdown / Toggle
              if (cita.estado == 'pendiente')
                Expanded(
                  child: InkWell(
                    onTap: () => provider.updateCitaStatus(cita.id, estado: 'confirmada'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: AppTheme.primary, size: 16),
                          SizedBox(width: 6),
                          Text('Confirmar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                )
              else if (cita.estado == 'confirmada')
                Expanded(
                  child: InkWell(
                    onTap: () => provider.updateCitaStatus(cita.id, estado: 'realizada'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all_rounded, color: Color(0xFF047857), size: 16),
                          SizedBox(width: 6),
                          Text('Marcar Realizada', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
