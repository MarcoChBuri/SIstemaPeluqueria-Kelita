import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cliente.dart';
import '../models/promocion_cliente.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/new_appointment_dialog.dart';

class ClientesTab extends StatefulWidget {
  final Function(int tabIndex)? onNavigateToTab;

  const ClientesTab({super.key, this.onNavigateToTab});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _filtro = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _abrirDialogoNuevaClienta(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final notasCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Registrar Clienta',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: nombreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo *',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono / WhatsApp *',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email (Opcional)',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: notasCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notas / Preferencias (Opcional)',
                    prefixIcon: Icon(Icons.note_alt_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final prov = Provider.of<AppStateProvider>(context, listen: false);
                      final nuevaClienta = Cliente(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        nombre: nombreCtrl.text.trim(),
                        telefono: telCtrl.text.trim(),
                        email: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
                        notas: notasCtrl.text.trim().isEmpty ? null : notasCtrl.text.trim(),
                        totalCitas: 0,
                        totalGastado: 0.0,
                      );
                      await prov.addCliente(nuevaClienta);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Clienta guardada con éxito.'),
                            backgroundColor: Color(0xFF047857),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    child: const Text('Guardar Clienta'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DIÁLOGO: Asignar Promoción QR a Clienta
  // ═══════════════════════════════════════════════
  void _abrirDialogoAsignarPromocion(BuildContext context, Cliente cliente) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final promocionesActivas = provider.promociones.where((p) => p.activa).toList();

    if (promocionesActivas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay promociones activas. Crea una primero en la sección Promociones.'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }

    String? selectedPromoId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.card_giftcard_rounded, color: AppTheme.primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Asignar Promoción',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                              ),
                              Text(
                                'Para: ${cliente.nombre}',
                                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close_rounded),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Selecciona la promoción que deseas darle a esta clienta. Se generará un QR único que solo podrá canjearse una vez.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 14),

                    // Lista de promociones activas
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: promocionesActivas.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final promo = promocionesActivas[i];
                          final isSelected = selectedPromoId == promo.id;
                          final descLabel = promo.porcentajeDescuento != null
                              ? '${promo.porcentajeDescuento}% OFF'
                              : '\$${promo.montoDescuento} OFF';

                          return InkWell(
                            onTap: () => setDialogState(() => selectedPromoId = promo.id),
                            borderRadius: BorderRadius.circular(14),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primaryLight : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                    color: isSelected ? AppTheme.primary : AppTheme.textMuted,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          promo.titulo,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSelected ? AppTheme.primary : AppTheme.textMain,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (promo.descripcion != null && promo.descripcion!.isNotEmpty)
                                          Text(
                                            promo.descripcion!,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD1FAE5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      descLabel,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Botón Generar QR
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: selectedPromoId == null
                            ? null
                            : () async {
                                final promo = promocionesActivas.firstWhere((p) => p.id == selectedPromoId);
                                Navigator.pop(ctx);

                                final result = await provider.asignarPromocionACliente(
                                  clienteId: cliente.id,
                                  clienteNombre: cliente.nombre,
                                  clienteTelefono: cliente.telefono,
                                  promocionId: promo.id,
                                  promocionTitulo: promo.titulo,
                                );

                                if (context.mounted) {
                                  _mostrarQrGenerado(context, result, promo);
                                }
                              },
                        icon: const Icon(Icons.qr_code_2_rounded, size: 20),
                        label: const Text('Generar QR Exclusivo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════
  // DIÁLOGO: Mostrar QR Generado + Enviar WhatsApp
  // ═══════════════════════════════════════════════
  void _mostrarQrGenerado(BuildContext context, PromocionCliente promoCliente, dynamic promoOriginal) {
    final descLabel = promoOriginal.porcentajeDescuento != null
        ? '${promoOriginal.porcentajeDescuento}% de descuento'
        : '\$${promoOriginal.montoDescuento} de descuento';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Éxito badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF047857)),
                      SizedBox(width: 6),
                      Text(
                        'QR Generado con Éxito',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Text(
                  promoCliente.promocionTitulo,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Para: ${promoCliente.clienteNombre}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),

                // QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppTheme.border, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: promoCliente.codigoQr,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Código alfanumérico
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: SelectableText(
                    promoCliente.codigoQr,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppTheme.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Este código es de uso único. Al escanearlo se marcará como canjeado.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Botón Enviar por WhatsApp
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final cleanPhone = AppStateProvider.normalizarTelefonoWhatsApp(promoCliente.clienteTelefono);
                      final msg = Uri.encodeComponent(
                        '¡Hola ${promoCliente.clienteNombre}! 🎉\n\n'
                        'Te enviamos un cupón de promoción exclusivo para Peluquería Raquel:\n\n'
                        '✨ *${promoCliente.promocionTitulo}*\n'
                        '🎁 Beneficio: $descLabel\n'
                        '🔑 Tu Código: *${promoCliente.codigoQr}*\n\n'
                        'Presenta este código al momento de tu cita para que sea canjeado. ¡Es de uso único! 💇‍♀️',
                      );
                      final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                    label: const Text('Enviar por WhatsApp'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cerrar', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // DIÁLOGO: Ver QRs asignados a una clienta
  // ═══════════════════════════════════════════════
  void _verQrsDeClienta(BuildContext context, Cliente cliente) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final promos = provider.getPromocionesDeCliente(cliente.id);

    if (promos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${cliente.nombre} no tiene promociones QR asignadas.'),
          backgroundColor: AppTheme.secondary,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'QRs de ${cliente.nombre}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: promos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = promos[i];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: p.canjeado ? const Color(0xFFF3F4F6) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: p.canjeado ? const Color(0xFFE5E7EB) : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            p.canjeado ? Icons.check_circle_rounded : Icons.qr_code_2_rounded,
                            color: p.canjeado ? const Color(0xFF9CA3AF) : AppTheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.promocionTitulo,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: p.canjeado ? const Color(0xFF9CA3AF) : AppTheme.textMain,
                                    decoration: p.canjeado ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  p.canjeado
                                      ? '✅ Canjeado el ${p.fechaCanje}'
                                      : '⏳ Pendiente · ${p.codigoQr}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: p.canjeado ? const Color(0xFF6B7280) : AppTheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: p.canjeado ? const Color(0xFFE5E7EB) : const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.canjeado ? 'USADO' : 'ACTIVO',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: p.canjeado ? const Color(0xFF6B7280) : const Color(0xFF047857),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviarPromocionWhatsApp(Cliente cliente) {
    final promoCtrl = TextEditingController(
      text: '¡Hola ${cliente.nombre}! ✨ Te saludamos de Peluquería Raquel. Queremos consentirte con una promoción especial exclusiva para ti en tu próximo cambio de look o tratamiento. ¿Te gustaría que te agendemos cita para estos días? 💇‍♀️💅',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.campaign_rounded, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Enviar Promoción a ${cliente.nombre}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mensaje a enviar por WhatsApp:',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: promoCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(ctx);
              final cleanPhone = AppStateProvider.normalizarTelefonoWhatsApp(cliente.telefono);
              final uri = Uri.parse(
                'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(promoCtrl.text)}',
              );
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Enviar WhatsApp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final todosClientes = provider.clientes;

    final clientesFiltrados = todosClientes.where((c) {
      if (_filtro.isEmpty) return true;
      final q = _filtro.toLowerCase();
      return c.nombre.toLowerCase().contains(q) || c.telefono.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirDialogoNuevaClienta(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded),
        label: const Text('Nueva Clienta', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
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
                          'DIRECTORIO DE CLIENTAS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Clientas Registradas', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Gestiona tus clientas (${todosClientes.length}), su fidelidad y envíales promociones exclusivas.',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Barra de búsqueda
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _filtro = v.trim()),
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o celular...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
                      suffixIcon: _filtro.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _filtro = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Lista de clientas
          if (clientesFiltrados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 48, color: AppTheme.textMuted),
                      const SizedBox(height: 12),
                      Text(
                        _filtro.isEmpty ? 'No hay clientas registradas aún.' : 'No se encontraron clientas con "$_filtro".',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Se registran automáticamente al agendar citas o puedes agregarlas manualmente con el botón + Nueva Clienta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final cliente = clientesFiltrados[index];
                    final promosCliente = provider.getPromocionesDeCliente(cliente.id);
                    final promosPendientes = promosCliente.where((p) => !p.canjeado).length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Avatar con iniciales
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: AppTheme.primaryLight,
                                child: Text(
                                  cliente.nombre.isNotEmpty ? cliente.nombre.substring(0, 1).toUpperCase() : 'C',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary, fontSize: 16),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      cliente.nombre,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textMuted),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(cliente.telefono, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              // Badges de fidelidad
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F3FF),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFFDDD6FE)),
                                    ),
                                    child: Text(
                                      '${cliente.totalVisitas} ${cliente.totalVisitas == 1 ? 'visita' : 'visitas'}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7C3AED)),
                                    ),
                                  ),
                                  if (cliente.totalGastado > 0) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      '\$${cliente.totalGastado.toStringAsFixed(2)}',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),

                          // Promos QR pendientes badge
                          if (promosPendientes > 0) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => _verQrsDeClienta(context, cliente),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFFDE68A)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF92400E)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$promosPendientes QR ${promosPendientes == 1 ? 'pendiente' : 'pendientes'} · Toca para ver',
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          if (cliente.notas != null && cliente.notas!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Nota: ${cliente.notas}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontStyle: FontStyle.italic),
                              ),
                            ),
                          ],

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          const SizedBox(height: 10),

                          // Botones de acción para clienta (3 botones)
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              // Botón Dar Promoción QR
                              _buildClienteActionBtn(
                                icon: Icons.card_giftcard_rounded,
                                label: 'Dar Promo QR',
                                bgColor: AppTheme.primaryLight,
                                fgColor: AppTheme.primary,
                                borderColor: const Color(0xFFFBCFE8),
                                onTap: () => _abrirDialogoAsignarPromocion(context, cliente),
                              ),
                              // Botón Enviar Promo WhatsApp
                              _buildClienteActionBtn(
                                icon: Icons.campaign_rounded,
                                label: 'WhatsApp',
                                bgColor: const Color(0xFFECFDF5),
                                fgColor: const Color(0xFF059669),
                                borderColor: const Color(0xFFA7F3D0),
                                onTap: () => _enviarPromocionWhatsApp(cliente),
                              ),
                              // Botón Agendar Cita
                              _buildClienteActionBtn(
                                icon: Icons.calendar_month_rounded,
                                label: 'Agendar',
                                bgColor: const Color(0xFFF1F5F9),
                                fgColor: AppTheme.secondary,
                                borderColor: const Color(0xFFE2E8F0),
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => const NewAppointmentDialog(),
                                  );
                                },
                              ),
                              // Botón ver historial QRs
                              if (promosCliente.isNotEmpty)
                                _buildClienteActionBtn(
                                  icon: Icons.history_rounded,
                                  label: 'Ver QRs',
                                  bgColor: const Color(0xFFFEF3C7),
                                  fgColor: const Color(0xFF92400E),
                                  borderColor: const Color(0xFFFDE68A),
                                  onTap: () => _verQrsDeClienta(context, cliente),
                                ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: clientesFiltrados.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClienteActionBtn({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color fgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fgColor),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fgColor),
            ),
          ],
        ),
      ),
    );
  }
}
