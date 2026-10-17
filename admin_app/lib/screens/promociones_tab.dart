import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/cliente.dart';
import '../models/promocion.dart';
import '../models/promocion_cliente.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/phone_utils.dart';

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

                        // Switch Único: Publicar en la Web (Activa / Visible)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: activa ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: activa ? const Color(0xFFBBF7D0) : const Color(0xFFFECACA)),
                          ),
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Row(
                              children: [
                                Icon(
                                  activa ? Icons.public_rounded : Icons.public_off_rounded,
                                  size: 20,
                                  color: activa ? const Color(0xFF16A34A) : AppTheme.danger,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activa ? 'Publicada en la Página Web' : 'Desactivada (Oculta de la Web)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: activa ? const Color(0xFF15803D) : AppTheme.danger,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              activa
                                  ? '🟢 Visible en la página web para todas las clientas que reserven.'
                                  : '🔴 Oculta de la web. Ninguna clienta podrá verla en la página.',
                              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            ),
                            value: activa,
                            onChanged: (val) => setDialogState(() => activa = val),
                          ),
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
                                    esPublica: activa,
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
                                    esPublica: activa,
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
                                    SnackBar(content: const Text('No se pudo guardar la promoción. Revisa los datos e inténtalo de nuevo.'), backgroundColor: AppTheme.danger),
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
  // Modal para Asignar Promoción a una Clienta Específica (Genera QR único)
  void _openAsignarQrModal(BuildContext context, Promocion promo) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final telCtrl = TextEditingController();
    Cliente? selectedCliente;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final provider = Provider.of<AppStateProvider>(context, listen: false);
            final clientes = provider.clientes;

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
                            const Expanded(
                              child: Text(
                                'Asignar QR a Clienta',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_offer_rounded, size: 14, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${promo.titulo} · ${promo.porcentajeDescuento != null ? "${promo.porcentajeDescuento}% OFF" : "\$${promo.montoDescuento} OFF"}',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Dropdown Selector de Clienta Registrada (opcional para autocompletar)
                        if (clientes.isNotEmpty) ...[
                          DropdownButtonFormField<Cliente>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Elegir Clienta Registrada',
                              prefixIcon: Icon(Icons.person_search_rounded, size: 20),
                            ),
                            initialValue: selectedCliente,
                            items: clientes.map((c) {
                              return DropdownMenuItem<Cliente>(
                                value: c,
                                child: Text(
                                  '${c.nombre} (${c.telefono})',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            }).toList(),
                            onChanged: (c) {
                              if (c != null) {
                                setModalState(() {
                                  selectedCliente = c;
                                  nombreCtrl.text = c.nombre;
                                  telCtrl.text = c.telefono;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          const Row(
                            children: [
                              Expanded(child: Divider()),
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text('O INGRESAR MANUALMENTE', style: TextStyle(fontSize: 9, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                              ),
                              Expanded(child: Divider()),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],

                        TextFormField(
                          controller: nombreCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la Clienta *',
                            prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre' : null,
                        ),
                        const SizedBox(height: 12),

                        TextFormField(
                          controller: telCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono / WhatsApp *',
                            prefixIcon: Icon(Icons.phone_outlined, size: 20),
                            hintText: '0991234567',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el teléfono' : null,
                        ),
                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final cId = selectedCliente?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
                              final nombre = nombreCtrl.text.trim();
                              final telefono = telCtrl.text.trim();

                              final promoCliente = await provider.asignarPromocionACliente(
                                clienteId: cId,
                                clienteNombre: nombre,
                                clienteTelefono: telefono,
                                promocionId: promo.id,
                                promocionTitulo: promo.titulo,
                              );

                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                _showQrClienteModal(context, promo, promoCliente);
                              }
                            },
                            icon: const Icon(Icons.qr_code_rounded, size: 20),
                            label: const Text('Generar QR y Asignar'),
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

  // Modal para Mostrar el Código QR Único Asignado y Enviar por WhatsApp
  void _showQrClienteModal(BuildContext context, Promocion promo, PromocionCliente promoCliente) {
    showDialog(
      context: context,
      builder: (ctx) {
        final desc = promo.porcentajeDescuento != null
            ? '${promo.porcentajeDescuento}% de descuento'
            : '\$${promo.montoDescuento} de descuento';
        final cleanPhone = formatEcuadorPhone(promoCliente.clienteTelefono);

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2F8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 14, color: AppTheme.primary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Cupón para ${promoCliente.clienteNombre}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    promo.titulo,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Beneficio: $desc · Vence: ${promo.fechaFin}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),

                  // Render QR Code con el código único de la clienta
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
                      data: promoCliente.codigoQr,
                      version: QrVersions.auto,
                      size: 180.0,
                      gapless: false,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Código Alfanumérico Único
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
                        fontSize: 15,
                        color: AppTheme.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Botón Enviar a la Clienta por WhatsApp
                  ElevatedButton.icon(
                    onPressed: () async {
                      final msg = Uri.encodeComponent(
                        '¡Hola ${promoCliente.clienteNombre}! 🎉 Te enviamos tu cupón exclusivo para Peluquería Raquel:\n\n'
                        '✨ *${promo.titulo}*\n'
                        '🎁 Beneficio: $desc\n'
                        '📅 Válido hasta: ${promo.fechaFin}\n'
                        '🔑 Tu Código Único: *${promoCliente.codigoQr}*\n\n'
                        'Muestra este código o QR al visitarnos para canjear tu promoción.'
                      );
                      final uri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 18),
                    label: Text(
                      'Enviar por WhatsApp a ${promoCliente.clienteNombre}',
                      overflow: TextOverflow.ellipsis,
                    ),
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
          ),
        );
      },
    );
  }

  // Modal para Ver Todos los Cupones QR Asignados
  void _openVerCuponesModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final provider = Provider.of<AppStateProvider>(context);
            final cupones = provider.promocionesCliente;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Cupones QR Asignados',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total emitidos: ${cupones.length}',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),

                      if (cupones.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          alignment: Alignment.center,
                          child: const Text(
                            'No se han asignado cupones a clientas todavía.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        )
                      else
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 380),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: cupones.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 8),
                            itemBuilder: (context, idx) {
                              final c = cupones[idx];
                              return Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: c.canjeado ? const Color(0xFFF9FAFB) : Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: c.canjeado ? const Color(0xFFE5E7EB) : AppTheme.border,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: c.canjeado ? const Color(0xFFF3F4F6) : AppTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        c.canjeado ? Icons.check_circle_rounded : Icons.qr_code_rounded,
                                        color: c.canjeado ? const Color(0xFF9CA3AF) : AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            c.clienteNombre,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          Text(
                                            c.promocionTitulo,
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Código: ${c.codigoQr}',
                                            style: const TextStyle(fontFamily: 'monospace', fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: c.canjeado ? const Color(0xFFF3F4F6) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        c.canjeado ? 'CANJEADO' : 'ACTIVO',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: c.canjeado ? const Color(0xFF6B7280) : const Color(0xFF166534),
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
          },
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
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
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
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _openVerCuponesModal(context),
                              icon: const Icon(Icons.confirmation_number_outlined, size: 15),
                              label: Text('Cupones (${provider.promocionesCliente.length})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => _openScannerOrValidateModal(context),
                              icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                              label: const Text('Validar QR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                              ),
                            ),
                          ],
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

                                    // Estado en Web (Activa / Desactivada)
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 4,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        InkWell(
                                          borderRadius: BorderRadius.circular(20),
                                          onTap: () async {
                                            final nuevoEstado = !promo.activa;
                                            try {
                                              await provider.updatePromocion(
                                                id: promo.id,
                                                activa: nuevoEstado,
                                                esPublica: nuevoEstado,
                                              );
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      nuevoEstado
                                                          ? '🟢 Promoción "${promo.titulo}" activada y publicada en la web.'
                                                          : '🔴 Promoción "${promo.titulo}" desactivada y retirada de la web.',
                                                    ),
                                                    backgroundColor: nuevoEstado ? const Color(0xFF15803D) : const Color(0xFF374151),
                                                    duration: const Duration(seconds: 2),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Error al cambiar estado: $e'),
                                                    backgroundColor: AppTheme.danger,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: promo.activa ? const Color(0xFFDCFCE7) : const Color(0xFFF3F4F6),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: promo.activa ? const Color(0xFF86EFAC) : const Color(0xFFE5E7EB),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  promo.activa ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
                                                  size: 13,
                                                  color: promo.activa ? const Color(0xFF166534) : const Color(0xFF6B7280),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  promo.activa ? 'Publicada en Web' : 'Desactivada (Oculta)',
                                                  style: TextStyle(
                                                    fontSize: 11,
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
                              // Botón Generar / Asignar QR
                              InkWell(
                                onTap: () => _openAsignarQrModal(context, promo),
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
                                        'Asignar QR a Clienta',
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
