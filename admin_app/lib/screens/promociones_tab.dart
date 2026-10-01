import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/promocion.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class PromocionesTab extends StatefulWidget {
  const PromocionesTab({super.key});

  @override
  State<PromocionesTab> createState() => _PromocionesTabState();
}

class _PromocionesTabState extends State<PromocionesTab> {
  // Modal para Crear o Editar Promoción
  void _openPromoModal(BuildContext context, {Promocion? promoToEdit}) {
    final isEditing = promoToEdit != null;
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController(text: promoToEdit?.titulo ?? '');
    final descCtrl = TextEditingController(text: promoToEdit?.descripcion ?? '');
    
    double valDescuento = 20.0;
    if (promoToEdit != null) {
      valDescuento = promoToEdit.porcentajeDescuento ?? promoToEdit.montoDescuento ?? 20.0;
    }
    final valorCtrl = TextEditingController(text: valDescuento.toString());

    String tipoDescuento = (promoToEdit?.montoDescuento != null) ? 'monto' : 'porcentaje';
    
    DateTime fechaFin = DateTime.now().add(const Duration(days: 30));
    if (promoToEdit != null && promoToEdit.fechaFin.isNotEmpty) {
      try {
        fechaFin = DateTime.parse(promoToEdit.fechaFin);
      } catch (_) {}
    }

    bool esPublica = promoToEdit?.esPublica ?? true;
    bool activa = promoToEdit?.activa ?? true;
    final qrCtrl = TextEditingController(text: promoToEdit?.codigoQr ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isEditing ? 'Editar Promoción' : 'Nueva Promoción',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Título
                        TextFormField(
                          controller: tituloCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título de la Oferta *',
                            hintText: 'Ej: 20% OFF en Alisados Orgánicos',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // Tipo Descuento & Valor
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: tipoDescuento,
                                decoration: const InputDecoration(labelText: 'Tipo Descuento'),
                                items: const [
                                  DropdownMenuItem(value: 'porcentaje', child: Text('Porcentaje (%)')),
                                  DropdownMenuItem(value: 'monto', child: Text('Monto Fijo (\$)')),
                                ],
                                onChanged: (v) => setDialogState(() => tipoDescuento = v ?? 'porcentaje'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                controller: valorCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  labelText: tipoDescuento == 'porcentaje' ? 'Valor (%)' : 'Valor (\$)',
                                ),
                                validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Fecha Fin
                        InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: fechaFin,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setDialogState(() => fechaFin = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.event_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Vence el: ${DateFormat('dd/MM/yyyy').format(fechaFin)}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Descripción
                        TextFormField(
                          controller: descCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Descripción / Términos',
                            hintText: 'Aplica reservando de martes a jueves...',
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Switch: Publicar en la Web Pública vs Exclusiva/Privada QR
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: esPublica ? const Color(0xFFEFF6FF) : const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: esPublica ? const Color(0xFFBFDBFE) : const Color(0xFFFED7AA)),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(
                                  esPublica ? Icons.public_rounded : Icons.qr_code_2_rounded,
                                  size: 18,
                                  color: esPublica ? const Color(0xFF2563EB) : const Color(0xFFEA580C),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    esPublica ? 'Publicar en la Web Pública' : 'Exclusiva por Código QR (Privada)',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              esPublica
                                  ? 'Cualquier cliente podrá verla en la página web.'
                                  : 'Oculta en la web. Solo clientes con el QR o código VIP podrán usarla.',
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                            value: esPublica,
                            onChanged: (val) => setDialogState(() => esPublica = val),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Switch: Activa / Desactivada
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Estado de la Promoción', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            activa ? '🟢 Activa y aplicable' : '🔴 Desactivada (Pausada)',
                            style: TextStyle(
                              fontSize: 11,
                              color: activa ? const Color(0xFF047857) : AppTheme.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          value: activa,
                          onChanged: (val) => setDialogState(() => activa = val),
                        ),
                        const SizedBox(height: 16),

                        // Botón Guardar
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final prov = Provider.of<AppStateProvider>(context, listen: false);
                              try {
                                final val = double.parse(valorCtrl.text);
                                if (isEditing) {
                                  await prov.updatePromocion(
                                    id: promoToEdit.id,
                                    titulo: tituloCtrl.text.trim(),
                                    descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                    porcentajeDescuento: tipoDescuento == 'porcentaje' ? val : null,
                                    montoDescuento: tipoDescuento == 'monto' ? val : null,
                                    fechaFin: DateFormat('yyyy-MM-dd').format(fechaFin),
                                    esPublica: esPublica,
                                    activa: activa,
                                    codigoQr: qrCtrl.text.trim().isEmpty ? null : qrCtrl.text.trim(),
                                  );
                                } else {
                                  await prov.createPromocion(
                                    titulo: tituloCtrl.text.trim(),
                                    descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                    porcentajeDescuento: tipoDescuento == 'porcentaje' ? val : null,
                                    montoDescuento: tipoDescuento == 'monto' ? val : null,
                                    fechaFin: DateFormat('yyyy-MM-dd').format(fechaFin),
                                    esPublica: esPublica,
                                    activa: activa,
                                    codigoQr: qrCtrl.text.trim().isEmpty ? null : qrCtrl.text.trim(),
                                  );
                                }

                                if (ctx.mounted) {
                                  Navigator.of(ctx).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(isEditing ? 'Promoción actualizada.' : 'Promoción creada exitosamente.'),
                                      backgroundColor: AppTheme.success,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (ctx.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
                                  );
                                }
                              }
                            },
                            child: Text(isEditing ? 'Guardar Cambios' : 'Crear Promoción'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Modal para Mostrar el Código QR Exclusivo y Enviar por WhatsApp
  void _showQrModal(BuildContext context, Promocion promo) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: promo.esPublica ? const Color(0xFFDBEAFE) : const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        promo.esPublica ? Icons.public_rounded : Icons.lock_rounded,
                        size: 14,
                        color: promo.esPublica ? const Color(0xFF1D4ED8) : const Color(0xFFC2410C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        promo.esPublica ? 'Promoción Pública Web' : 'Promoción Exclusiva VIP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: promo.esPublica ? const Color(0xFF1D4ED8) : const Color(0xFFC2410C),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  promo.titulo,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Válido hasta: ${promo.fechaFin}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 16),

                // Render QR Code
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
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
                    data: promo.codigoQr,
                    version: QrVersions.auto,
                    size: 180.0,
                    gapless: false,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),

                // Código Alfanumérico
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: SelectableText(
                    'CÓDIGO VIP: ${promo.codigoQr}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppTheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Botón Compartir por WhatsApp
                ElevatedButton.icon(
                  onPressed: () async {
                    final desc = promo.porcentajeDescuento != null
                        ? '${promo.porcentajeDescuento}% de descuento'
                        : '\$${promo.montoDescuento} de descuento';
                    final msg = Uri.encodeComponent(
                      '¡Hola! 🎉 Te enviamos un cupón de promoción exclusivo para Peluquería Raquel:\n\n'
                      '✨ *${promo.titulo}*\n'
                      '🎁 Beneficio: $desc\n'
                      '📅 Válido hasta: ${promo.fechaFin}\n'
                      '🔑 Tu Código de Descuento: *${promo.codigoQr}*\n\n'
                      'Presenta este mensaje o código al agendar tu cita.'
                    );
                    final uri = Uri.parse('https://wa.me/?text=$msg');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                  label: const Text('Enviar QR / Cupón a Cliente (WhatsApp)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
                const SizedBox(height: 8),

                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar', style: TextStyle(color: AppTheme.textMuted)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modal para Escanear / Validar QR
  void _openScannerOrValidateModal(BuildContext context) {
    final codeCtrl = TextEditingController();
    bool isChecking = false;
    String? statusMsg;
    bool? isValid;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Validar Código QR / Cupón', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        IconButton(onPressed: () => Navigator.of(ctx).pop(), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Ingresa o escanea el código del cliente para verificar si está activo y aplicarle el descuento.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: codeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Código QR / Cupón VIP',
                        prefixIcon: Icon(Icons.qr_code_scanner_rounded, size: 20),
                        hintText: 'Ej: RAQUEL-VIP-X8K9L',
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (statusMsg != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isValid == true ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isValid == true ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                              color: isValid == true ? const Color(0xFF047857) : AppTheme.danger,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                statusMsg!,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isValid == true ? const Color(0xFF047857) : AppTheme.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: isChecking
                            ? null
                            : () async {
                                final code = codeCtrl.text.trim();
                                if (code.isEmpty) return;

                                setModalState(() {
                                  isChecking = true;
                                  statusMsg = null;
                                  isValid = null;
                                });

                                try {
                                  final prov = Provider.of<AppStateProvider>(context, listen: false);
                                  final res = await prov.validarQrPromocion(code);
                                  setModalState(() {
                                    isChecking = false;
                                    isValid = res['valida'] == true;
                                    statusMsg = res['mensaje'] ?? 'Código verificado con éxito.';
                                  });
                                } catch (e) {
                                  setModalState(() {
                                    isChecking = false;
                                    isValid = false;
                                    statusMsg = e.toString().replaceAll('Exception: ', '');
                                  });
                                }
                              },
                        icon: isChecking
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.verified_rounded, size: 20),
                        label: Text(isChecking ? 'Verificando...' : 'Verificar y Canjear Código'),
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

  void _confirmDeletePromo(BuildContext context, Promocion promo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar Promoción?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('La promoción "${promo.titulo}" será eliminada de forma permanente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              final prov = Provider.of<AppStateProvider>(context, listen: false);
              await prov.deletePromocion(promo.id);
              if (ctx.mounted) {
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Promoción eliminada.')),
                );
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final promociones = provider.promociones;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openPromoModal(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nueva Promoción', style: TextStyle(fontWeight: FontWeight.bold)),
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
              // Header Card
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'OFERTAS Y BENEFICIOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _openScannerOrValidateModal(context),
                          icon: const Icon(Icons.qr_code_scanner_rounded, size: 16),
                          label: const Text('Validar QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            minimumSize: Size.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Promociones & Cupones QR', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                    const SizedBox(height: 2),
                    const Text(
                      'Gestiona ofertas públicas en la web o promociones exclusivas por código QR para clientas específicas.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              if (promociones.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(36),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: const Center(
                    child: Text('No hay promociones registradas aún.', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: promociones.length,
                  separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final promo = promociones[index];
                    final descLabel = promo.porcentajeDescuento != null
                        ? '${promo.porcentajeDescuento}% OFF'
                        : '\$${promo.montoDescuento} OFF';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: promo.activa ? Colors.white : const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: promo.activa ? AppTheme.border : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: promo.activa ? AppTheme.primaryLight : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  promo.esPublica ? Icons.local_offer_rounded : Icons.qr_code_2_rounded,
                                  color: promo.activa ? AppTheme.primary : const Color(0xFF9CA3AF),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            promo.titulo,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: promo.activa ? AppTheme.textMain : const Color(0xFF6B7280),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFD1FAE5),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            descLabel,
                                            style: const TextStyle(
                                              color: Color(0xFF047857),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (promo.descripcion != null && promo.descripcion!.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 3),
                                        child: Text(
                                          promo.descripcion!,
                                          style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    const SizedBox(height: 6),

                                    // Badges de estado
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        // Web vs VIP
                                        InkWell(
                                          onTap: () {
                                            provider.updatePromocion(id: promo.id, esPublica: !promo.esPublica);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: promo.esPublica ? const Color(0xFFDBEAFE) : const Color(0xFFFFEDD5),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  promo.esPublica ? Icons.public_rounded : Icons.lock_rounded,
                                                  size: 11,
                                                  color: promo.esPublica ? const Color(0xFF1E40AF) : const Color(0xFF9A3412),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  promo.esPublica ? 'Pública en Web' : 'Exclusiva por QR',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: promo.esPublica ? const Color(0xFF1E40AF) : const Color(0xFF9A3412),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        // Activa / Inactiva
                                        InkWell(
                                          onTap: () {
                                            provider.updatePromocion(id: promo.id, activa: !promo.activa);
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: promo.activa ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  promo.activa ? Icons.check_circle_outline_rounded : Icons.pause_circle_outline_rounded,
                                                  size: 11,
                                                  color: promo.activa ? const Color(0xFF166534) : const Color(0xFF4B5563),
                                                ),
                                                const SizedBox(width: 3),
                                                Text(
                                                  promo.activa ? 'Activa' : 'Pausada',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: promo.activa ? const Color(0xFF166534) : const Color(0xFF4B5563),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Vence: ${promo.fechaFin}',
                                          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          const Divider(height: 1, color: Color(0xFFF3F4F6)),
                          const SizedBox(height: 8),

                          // Barra de Acciones
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Botón Generar / Compartir QR
                              InkWell(
                                onTap: () => _showQrModal(context, promo),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFDF2F8),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFFFBCFE8)),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.qr_code_2_rounded, size: 16, color: AppTheme.primary),
                                      SizedBox(width: 4),
                                      Text(
                                        'Ver / Enviar QR VIP',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              Row(
                                children: [
                                  // Botón Editar
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.textMuted),
                                    tooltip: 'Editar Promoción',
                                    onPressed: () => _openPromoModal(context, promoToEdit: promo),
                                  ),
                                  // Botón Eliminar
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppTheme.danger),
                                    tooltip: 'Eliminar Promoción',
                                    onPressed: () => _confirmDeletePromo(context, promo),
                                  ),
                                ],
                              ),
                            ],
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
}
