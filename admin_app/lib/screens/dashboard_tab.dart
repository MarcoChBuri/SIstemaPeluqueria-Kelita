import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final hoyStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final citasHoy = citas.where((c) => c.fechaCita == hoyStr).toList();
    final citasConfirmadas =
        citas.where((c) => c.estado == 'confirmada' || c.estado == 'completada').length;

    return RefreshIndicator(
      onRefresh: () => provider.loadAllData(),
      color: AppTheme.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header Masthead Banner ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.white, Color(0xFFFFF0F5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.border),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
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
                          color: provider.isBackendConnected
                              ? const Color(0xFFD5E3FD)
                              : const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: provider.isBackendConnected
                                    ? AppTheme.primary
                                    : AppTheme.danger,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.isBackendConnected ? 'CONECTADO' : 'OFFLINE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: provider.isBackendConnected
                                    ? AppTheme.secondary
                                    : AppTheme.danger,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        reporte?.periodo ?? DateFormat('MMMM yyyy').format(DateTime.now()),
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.displayMedium,
                      children: const [
                        TextSpan(text: 'Peluquería '),
                        TextSpan(
                          text: 'Raquel',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reporte?.mensaje.isNotEmpty == true
                        ? reporte!.mensaje
                        : 'Control financiero, agenda y motor de colorimetría en tiempo real.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigateToTab?.call(4),
                          icon: const Icon(Icons.attach_money_rounded, size: 16),
                          label: const Text('Gastos / Ventas', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.secondary,
                            side: const BorderSide(color: AppTheme.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => const NewAppointmentDialog(),
                            );
                          },
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Nueva Cita', style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- KPIs Grid ---
            Text('Resumen Financiero', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.25,
              children: [
                KpiCard(
                  title: 'Servicios',
                  value: '\$${(reporte?.ingresos.servicios ?? 0).toStringAsFixed(2)}',
                  subtitle: 'Citas y Paquetes',
                  icon: Icons.content_cut_rounded,
                  iconColor: const Color(0xFF059669),
                  iconBgColor: const Color(0xFFD1FAE5),
                ),
                KpiCard(
                  title: 'Total Ingresos',
                  value: '\$${(reporte?.totalIngresos ?? 0).toStringAsFixed(2)}',
                  subtitle: 'Serv + Prod + Cursos',
                  icon: Icons.trending_up_rounded,
                  iconColor: const Color(0xFF2563EB),
                  iconBgColor: const Color(0xFFDBEAFE),
                ),
                KpiCard(
                  title: 'Total Gastos',
                  value: '\$${(reporte?.totalGastos ?? 0).toStringAsFixed(2)}',
                  subtitle: 'Insumos y arriendo',
                  icon: Icons.arrow_downward_rounded,
                  iconColor: AppTheme.danger,
                  iconBgColor: const Color(0xFFFFE4E6),
                  valueColor: AppTheme.danger,
                ),
                KpiCard(
                  title: 'Balance Neto',
                  value: '\$${(reporte?.balanceNeto ?? 0).toStringAsFixed(2)}',
                  subtitle: 'Ganancia real',
                  icon: Icons.account_balance_wallet_rounded,
                  iconColor: AppTheme.primary,
                  iconBgColor: AppTheme.primaryLight,
                  valueColor: (reporte?.balanceNeto ?? 0) >= 0 ? AppTheme.primary : AppTheme.danger,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Activity Indicators ---
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.today_rounded, color: Color(0xFFD97706), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${citasHoy.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const Text('Citas Hoy', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.check_circle_outline_rounded,
                              color: Color(0xFF047857), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$citasConfirmadas',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain,
                              ),
                            ),
                            const Text('Confirmadas', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- Próximas Citas List ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Próximas Citas', style: Theme.of(context).textTheme.titleLarge),
                TextButton(
                  onPressed: () => onNavigateToTab?.call(1),
                  child: const Text('Ver todas', style: TextStyle(color: AppTheme.primary, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (citas.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  children: [
                    Icon(Icons.calendar_month_outlined, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    const Text('No hay citas registradas', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Toca "Nueva Cita" para agendar la primera clienta.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: citas.take(4).length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final cita = citas[index];
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                cita.horaInicio,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppTheme.primary,
                                ),
                              ),
                              Text(
                                cita.fechaCita.split('-').reversed.take(2).join('/'),
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                cita.clienteNombre,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                cita.servicios?.nombre ?? 'Servicio Profesional',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                              ),
                              const SizedBox(height: 4),
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
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded,
                              color: Color(0xFF25D366), size: 20),
                          tooltip: 'Enviar WhatsApp',
                          onPressed: () async {
                            final cleanPhone = cita.clienteTelefono.replaceAll(RegExp(r'[^0-9]'), '');
                            final uri = Uri.parse(
                                'https://wa.me/$cleanPhone?text=${Uri.encodeComponent('Hola ${cita.clienteNombre}, te saludamos de Peluquería Raquel para confirmar tu cita el ${cita.fechaCita} a las ${cita.horaInicio}.')}');
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
