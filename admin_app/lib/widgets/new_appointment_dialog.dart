import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/servicio.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class NewAppointmentDialog extends StatefulWidget {
  final DateTime? initialDate;
  final double? initialPrecio;

  const NewAppointmentDialog({super.key, this.initialDate, this.initialPrecio});

  @override
  State<NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<NewAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _notasController = TextEditingController();

  // Categorías y servicio seleccionado
  String? _selectedCategoria;
  String? _selectedServicioId;
  String? _selectedPromocionId;
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  int _selectedDuracionMinutos = 60;

  bool _isSubmitting = false;
  String? _createdWhatsappUrl;
  String? _createdClienteNombre;

  static const int _minHour = 8;
  static const int _maxHour = 19; // 7:00 PM (19:00)

  bool _isHourValid(TimeOfDay t) {
    if (t.hour < _minHour) return false;
    if (t.hour > _maxHour) return false;
    if (t.hour == _maxHour && t.minute > 0) return false;
    return true;
  }

  // Mapa de categorías con icono y color
  static const Map<String, Map<String, dynamic>> _categoryMeta = {
    'corte': {'label': 'Cortes', 'icon': Icons.content_cut_rounded, 'color': Color(0xFFBE185D)},
    'color': {'label': 'Colores', 'icon': Icons.palette_rounded, 'color': Color(0xFF7C3AED)},
    'paquete': {'label': 'Paquetes', 'icon': Icons.card_giftcard_rounded, 'color': Color(0xFF0891B2)},
    'tratamiento': {'label': 'Tratamientos', 'icon': Icons.spa_rounded, 'color': Color(0xFF059669)},
    'peinado': {'label': 'Peinados', 'icon': Icons.face_retouching_natural_rounded, 'color': Color(0xFFD97706)},
    'otro': {'label': 'Otros', 'icon': Icons.category_rounded, 'color': Color(0xFF6B7280)},
  };

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // Normaliza la categoría del servicio a las claves del mapa
  String _normalizarCategoria(String raw) {
    final c = raw.toLowerCase().trim();
    if (c.contains('corte') || c.contains('cut')) return 'corte';
    if (c.contains('color') || c.contains('tinte') || c.contains('decolor') ||
        c.contains('mech') || c.contains('matiz') || c.contains('balan')) return 'color';
    if (c.contains('paquete') || c.contains('combo')) return 'paquete';
    if (c.contains('tratamiento') || c.contains('keratina') || c.contains('botox')) return 'tratamiento';
    if (c.contains('peinado') || c.contains('brushing') || c.contains('alaciado')) return 'peinado';
    return 'otro';
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null) {
      if (!_isHourValid(t)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('⏰ Solo puedes agendar entre 8:00 AM y 7:00 PM'),
            backgroundColor: AppTheme.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        }
        return;
      }
      setState(() => _selectedTime = t);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedServicioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona un servicio.')));
      return;
    }
    if (!_isHourValid(_selectedTime)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('⏰ La hora debe estar entre 8:00 AM y 7:00 PM'),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSubmitting = true);
    final fechaStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final horaStr =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    try {
      final provider = Provider.of<AppStateProvider>(context, listen: false);
      final result = await provider.createCita(
        clienteNombre: _nombreController.text.trim(),
        clienteTelefono: _telefonoController.text.trim(),
        clienteEmail: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        servicioId: _selectedServicioId!,
        promocionId: _selectedPromocionId,
        fechaCita: fechaStr,
        horaInicio: horaStr,
        duracionMinutos: _selectedDuracionMinutos,
        notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      );
      setState(() {
        _isSubmitting = false;
        _createdWhatsappUrl = result['whatsapp_url'] as String?;
        _createdClienteNombre = _nombreController.text.trim();
      });
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger));
      }
    }
  }

  void _abrirSelectorClienta(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context, listen: false);
    final clientes = provider.clientes;

    if (clientes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay clientas registradas todavía.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        String busqueda = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtrados = clientes.where((c) {
              if (busqueda.isEmpty) return true;
              final q = busqueda.toLowerCase();
              return c.nombre.toLowerCase().contains(q) || c.telefono.contains(q);
            }).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) {
                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Text(
                        'Seleccionar Clienta Registrada',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre o teléfono...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onChanged: (v) => setModalState(() => busqueda = v.trim()),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: filtrados.isEmpty
                            ? const Center(child: Text('No se encontraron clientas'))
                            : ListView.separated(
                                controller: scrollController,
                                itemCount: filtrados.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final c = filtrados[index];
                                  return ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: AppTheme.primaryLight,
                                      child: Text(
                                        c.nombre.isNotEmpty ? c.nombre[0].toUpperCase() : 'C',
                                        style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(c.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(c.telefono, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textMuted),
                                    onTap: () {
                                      setState(() {
                                        _nombreController.text = c.nombre;
                                        _telefonoController.text = c.telefono;
                                        if (c.email != null && c.email!.isNotEmpty) {
                                          _emailController.text = c.email!;
                                        }
                                      });
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Datos de ${c.nombre} cargados.'),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);
    final servicios = provider.servicios;
    final promociones = provider.promociones;

    // Agrupar servicios por categoría normalizada
    final Map<String, List<Servicio>> porCategoria = {};
    for (final s in servicios.where((s) => s.activo)) {
      final cat = _normalizarCategoria(s.categoria);
      porCategoria.putIfAbsent(cat, () => []).add(s);
    }
    // Categorías disponibles (en orden fijo)
    final categoriasDisponibles = _categoryMeta.keys
        .where((k) => porCategoria.containsKey(k))
        .toList();

    // Servicios de la categoría seleccionada
    final serviciosDeCategoria =
        _selectedCategoria != null ? (porCategoria[_selectedCategoria] ?? []) : <Servicio>[];

    // — Pantalla de éxito —
    if (_createdWhatsappUrl != null) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64, height: 64,
                decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF047857), size: 40),
              ),
              const SizedBox(height: 16),
              Text('¡Cita Agendada!', style: Theme.of(context).textTheme.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('La cita para $_createdClienteNombre fue guardada.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              if (_createdWhatsappUrl!.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: () async {
                    final uri = Uri.parse(_createdWhatsappUrl!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
                  label: const Text('Enviar Confirmación WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    minimumSize: const Size(double.infinity, 46),
                  ),
                ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar', style: TextStyle(color: AppTheme.textMuted)),
              ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 760),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Nueva Cita',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20)),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Selector de Clienta Registrada
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'DATOS DE LA CLIENTA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _abrirSelectorClienta(context),
                        icon: const Icon(Icons.person_search_rounded, size: 16),
                        label: const Text(
                          'Clienta Registrada',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // ── Nombre ──
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la Clienta *',
                      prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  // ── Teléfono ──
                  TextFormField(
                    controller: _telefonoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono / WhatsApp *',
                      prefixIcon: Icon(Icons.phone_outlined, size: 20),
                      hintText: 'Ej: 0991234567',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 10),

                  // ── Email ──
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo Electrónico (Opcional)',
                      prefixIcon: Icon(Icons.mail_outline_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ════════════════════════════════════════
                  // SELECTOR DE CATEGORÍA (chips)
                  // ════════════════════════════════════════
                  const Text('Categoría de Servicio',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categoriasDisponibles.map((cat) {
                      final meta = _categoryMeta[cat]!;
                      final isSelected = _selectedCategoria == cat;
                      final color = meta['color'] as Color;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoria = cat;
                            _selectedServicioId = null; // reset servicio
                          });
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? color : color.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? color : color.withValues(alpha: 0.25),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                meta['icon'] as IconData,
                                size: 15,
                                color: isSelected ? Colors.white : color,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                meta['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 12),

                  // ════════════════════════════════════════
                  // SERVICIOS DE LA CATEGORÍA SELECCIONADA
                  // ════════════════════════════════════════
                  if (_selectedCategoria == null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.touch_app_rounded, size: 18, color: AppTheme.textMuted),
                          SizedBox(width: 8),
                          Text('Selecciona una categoría arriba',
                              style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                        ],
                      ),
                    )
                  else if (serviciosDeCategoria.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('No hay servicios en esta categoría.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFB45309))),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner especial para color
                        if (_selectedCategoria == 'color')
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                  colors: [Color(0xFF7C3AED), Color(0xFFBE185D)]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.palette_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '💡 Color: el precio se calcula con la Calculadora después del servicio',
                                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Lista de servicios como tarjetas seleccionables
                        ...serviciosDeCategoria.map((s) {
                          final isSelected = _selectedServicioId == s.id;
                          final catColor = (_categoryMeta[_selectedCategoria]?['color'] as Color?) ?? AppTheme.primary;
                          final esColorSvc = _selectedCategoria == 'color';

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedServicioId = s.id;
                                _selectedDuracionMinutos = s.duracionMinutos;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? catColor.withValues(alpha: 0.08) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? catColor : AppTheme.border,
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icono de check / radio
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected ? catColor : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? catColor : AppTheme.textMuted,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, color: Colors.white, size: 13)
                                        : null,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.nombre,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isSelected ? catColor : AppTheme.textMain,
                                          ),
                                        ),
                                        if (s.descripcion != null && s.descripcion!.isNotEmpty)
                                          Text(s.descripcion!,
                                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                              maxLines: 1, overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Precio
                                      Text(
                                        esColorSvc
                                            ? 'Por cotizar'
                                            : '\$${s.precioBase.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: esColorSvc ? const Color(0xFF7C3AED) : catColor,
                                        ),
                                      ),
                                      // Duración
                                      Text(
                                        '${s.duracionMinutos} min',
                                        style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                  const SizedBox(height: 12),

                  // ── Duración (solo si hay servicio seleccionado) ──
                  if (_selectedServicioId != null)
                    Builder(builder: (context) {
                      final presets = [15, 30, 45, 60, 75, 90, 105, 120, 135, 150, 165, 180, 210, 240, 300, 360, 420, 480];
                      final set = Set<int>.from(presets)..add(_selectedDuracionMinutos);
                      final sorted = set.toList()..sort();
                      return DropdownButtonFormField<int>(
                        value: _selectedDuracionMinutos,
                        decoration: const InputDecoration(
                          labelText: 'Tiempo a ocupar *',
                          prefixIcon: Icon(Icons.timer_outlined, size: 20),
                        ),
                        items: sorted.map((mins) {
                          String label;
                          if (mins < 60) {
                            label = '$mins min';
                          } else if (mins % 60 == 0) {
                            final h = mins ~/ 60;
                            label = '$h ${h == 1 ? 'Hora' : 'Horas'} ($mins min)';
                          } else {
                            label = '${(mins / 60).toStringAsFixed(1)} Horas ($mins min)';
                          }
                          return DropdownMenuItem<int>(value: mins, child: Text(label));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDuracionMinutos = val);
                        },
                      );
                    }),

                  if (_selectedServicioId != null) const SizedBox(height: 10),

                  // ── Promoción ──
                  Builder(builder: (context) {
                    final activePromos = promociones.where((p) => p.activa).toList();
                    final validId = activePromos.any((p) => p.id == _selectedPromocionId)
                        ? _selectedPromocionId
                        : null;
                    return DropdownButtonFormField<String?>(
                      value: validId,
                      decoration: const InputDecoration(
                        labelText: 'Promoción (Opcional)',
                        prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Sin Promoción')),
                        ...activePromos.map((p) {
                          final desc = p.porcentajeDescuento != null
                              ? '${p.porcentajeDescuento}% OFF'
                              : '\$${p.montoDescuento} OFF';
                          return DropdownMenuItem<String?>(
                              value: p.id, child: Text('${p.titulo} ($desc)'));
                        }),
                      ],
                      onChanged: (val) => setState(() => _selectedPromocionId = val),
                    );
                  }),
                  const SizedBox(height: 10),

                  // ── Fecha y Hora ──
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final d = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (d != null) setState(() => _selectedDate = d);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _pickTime,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8F9FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_rounded, size: 18, color: AppTheme.primary),
                                const SizedBox(width: 8),
                                Text(_selectedTime.format(context),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4, top: 4),
                    child: Text('⏰ Horario: 8:00 AM — 8:00 PM',
                        style: TextStyle(fontSize: 10, color: AppTheme.textMuted, fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(height: 10),

                  // ── Notas ──
                  TextFormField(
                    controller: _notasController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notas (ej: alergias, tono deseado)',
                      prefixIcon: Icon(Icons.notes_rounded, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Botón Agendar ──
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_isSubmitting || _selectedServicioId == null) ? null : _submit,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Confirmar y Guardar Cita'),
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
