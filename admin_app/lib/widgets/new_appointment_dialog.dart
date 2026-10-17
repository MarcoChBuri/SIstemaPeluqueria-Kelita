import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/servicio.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import '../utils/top_toast.dart';

class NewAppointmentDialog extends StatefulWidget {
  final DateTime? initialDate;
  final double? initialPrecio;

  const NewAppointmentDialog({super.key, this.initialDate, this.initialPrecio});

  @override
  State<NewAppointmentDialog> createState() => _NewAppointmentDialogState();
}

class _NewAppointmentDialogState extends State<NewAppointmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _notasController = TextEditingController();

  // Categoría seleccionada: null al inicio para mostrar solo las categorías primero
  String? _selectedCategoria;
  String? _selectedServicioId;
  String? _selectedPromocionId;
  String? _errorMessage;
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

  // Categorías del salón (sin 'todos') para selección directa
  static const List<Map<String, dynamic>> _categoriasFiltro = [
    {'id': 'corte', 'label': 'Cortes', 'icon': Icons.content_cut_rounded},
    {'id': 'color', 'label': 'Colorimetría', 'icon': Icons.palette_outlined},
    {'id': 'tratamiento', 'label': 'Tratamientos', 'icon': Icons.spa_outlined},
    {'id': 'pestanas', 'label': 'Pestañas & Cejas', 'icon': Icons.visibility_outlined},
    {'id': 'peinado', 'label': 'Peinados & MakeUp', 'icon': Icons.face_retouching_natural_rounded},
    {'id': 'paquete', 'label': 'Paquetes & Bodas', 'icon': Icons.card_giftcard_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nombreController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // Comprueba si un servicio coincide con la categoría seleccionada
  bool _servicioEnCategoria(Servicio s, String catId) {
    final svcCat = s.categoria.toLowerCase().trim();
    final svcNom = s.nombre.toLowerCase().trim();
    final combined = '$svcCat $svcNom';

    if (catId == 'corte') {
      return svcCat == 'corte' || combined.contains('corte') || combined.contains('cut');
    }
    if (catId == 'color' || catId == 'colorimetria') {
      return svcCat.contains('color') || combined.contains('color') || combined.contains('tinte') || combined.contains('balayage') || combined.contains('decolor') || combined.contains('matiz');
    }
    if (catId == 'tratamiento') {
      return svcCat.contains('tratam') || combined.contains('tratam') || combined.contains('alisad') || combined.contains('keratina') || combined.contains('botox');
    }
    if (catId == 'pestanas' || catId == 'pestanas_cejas') {
      return svcCat.contains('pesta') || svcCat.contains('ceja') || combined.contains('pesta') || combined.contains('ceja') || combined.contains('lash');
    }
    if (catId == 'paquete' || catId == 'paquete_bodas' || catId == 'paquete_quinceanera') {
      return svcCat.contains('paquete') || combined.contains('paquete') || combined.contains('boda') || combined.contains('novia') || combined.contains('quince') || combined.contains('15');
    }
    if (catId == 'peinado' || catId == 'peinado_maquillaje') {
      return svcCat.contains('peinado') || svcCat.contains('maquillaje') || combined.contains('peinado') || combined.contains('maquillaje') || combined.contains('makeup') || combined.contains('brushing');
    }
    return svcCat == catId;
  }

  String _getCategoriaLabel(String catId) {
    final cat = _categoriasFiltro.firstWhere(
      (c) => c['id'] == catId,
      orElse: () => {'label': 'Servicio'},
    );
    return cat['label'] as String;
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _selectedTime);
    if (t != null) {
      if (!_isHourValid(t)) {
        if (mounted) {
          setState(() {
            _errorMessage = '⏰ Horario fuera de rango: solo puedes agendar entre 8:00 AM y 7:00 PM.';
          });
          TopToast.show(context, message: '⏰ Horario fuera de rango (8:00 AM - 7:00 PM)', isError: true);
        }
        return;
      }
      setState(() {
        _selectedTime = t;
        _errorMessage = null;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      setState(() {
        _errorMessage = 'Por favor completa todos los campos requeridos marcados con * (Nombre y Teléfono).';
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      TopToast.show(context, message: 'Faltan campos obligatorios (*)', isError: true);
      return;
    }
    if (_selectedCategoria == null) {
      setState(() {
        _errorMessage = 'Por favor selecciona primero una categoría de servicio.';
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      TopToast.show(context, message: 'Selecciona una categoría de servicio', isError: true);
      return;
    }
    if (_selectedServicioId == null) {
      setState(() {
        _errorMessage = 'Debes seleccionar un servicio para continuar con la cita.';
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      TopToast.show(context, message: 'Selecciona un servicio para la cita', isError: true);
      return;
    }
    if (!_isHourValid(_selectedTime)) {
      setState(() {
        _errorMessage = '⏰ La hora debe estar entre 8:00 AM y 7:00 PM.';
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      TopToast.show(context, message: 'Horario permitido: 8:00 AM a 7:00 PM', isError: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
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
      if (mounted) {
        TopToast.show(context, message: '✅ Cita creada exitosamente', isSuccess: true, isError: false);
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'No se pudo agendar la cita. Por favor, revisa los datos e inténtalo de nuevo.';
      });
      if (_scrollController.hasClients) {
        _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      if (mounted) {
        TopToast.show(context, message: 'No se pudo guardar la cita. Por favor, revisa los datos e inténtalo de nuevo.', isError: true);
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

    // Servicios visibles: SOLO se muestran cuando hay una categoría seleccionada
    final serviciosVisibles = _selectedCategoria == null
        ? <Servicio>[]
        : servicios
            .where((s) => s.activo && _servicioEnCategoria(s, _selectedCategoria!))
            .toList();

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
              controller: _scrollController,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Nueva Cita',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── AVISO DE ERROR DESTACADO ARRIBA ──
                  if (_errorMessage != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF991B1B),
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() => _errorMessage = null),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(Icons.close_rounded, size: 16, color: Color(0xFF991B1B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

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
                  // SELECTOR DE CATEGORÍA
                  // ════════════════════════════════════════
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '1. Elige una Categoría *',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      if (_selectedCategoria != null)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _selectedCategoria = null;
                              _selectedServicioId = null;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Text(
                              'Cambiar categoría',
                              style: TextStyle(fontSize: 11, color: AppTheme.primary, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _categoriasFiltro.map((cat) {
                      final isSelected = _selectedCategoria == cat['id'];
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (_selectedCategoria == cat['id']) {
                              _selectedCategoria = null;
                              _selectedServicioId = null;
                            } else {
                              _selectedCategoria = cat['id'] as String;
                              // Si el servicio actual no pertenece a la nueva categoría, deseleccionarlo
                              if (_selectedServicioId != null) {
                                final stillValid = servicios.any((s) =>
                                    s.id == _selectedServicioId &&
                                    _servicioEnCategoria(s, _selectedCategoria!));
                                if (!stillValid) {
                                  _selectedServicioId = null;
                                }
                              }
                            }
                            _errorMessage = null;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected ? AppTheme.primary : AppTheme.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.primary.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                cat['icon'] as IconData,
                                size: 15,
                                color: isSelected ? Colors.white : AppTheme.secondary,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppTheme.textMain,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 14),

                  // ════════════════════════════════════════
                  // SERVICIOS DISPONIBLES (Solo al elegir categoría)
                  // ════════════════════════════════════════
                  if (_selectedCategoria == null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border.withOpacity(0.7)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_outlined, size: 18, color: AppTheme.primary),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Toca una categoría arriba para ver sus servicios disponibles.',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (serviciosVisibles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: const Center(
                        child: Text(
                          'No hay servicios registrados en esta categoría.',
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline_rounded, size: 15, color: AppTheme.primary),
                              const SizedBox(width: 6),
                              Text(
                                '2. Servicios de ${_getCategoriaLabel(_selectedCategoria!)} *',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                              ),
                            ],
                          ),
                        ),
                        // Banner informativo para colorimetría (en paleta magenta de marca)
                        if (_selectedCategoria == 'color')
                          Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDF2F8),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryLight),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.palette_rounded, color: AppTheme.primary, size: 14),
                                SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    '💡 Colorimetría: el valor final se calcula con la Calculadora según los gramos aplicados.',
                                    style: TextStyle(fontSize: 10, color: AppTheme.primaryDark, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Lista de servicios como tarjetas seleccionables
                        ...serviciosVisibles.map((s) {
                          final isSelected = _selectedServicioId == s.id;

                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedServicioId = s.id;
                                _selectedDuracionMinutos = s.duracionMinutos;
                                _errorMessage = null;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFDF2F8) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : AppTheme.border,
                                  width: isSelected ? 1.5 : 1,
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
                                      color: isSelected ? AppTheme.primary : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected ? AppTheme.primary : AppTheme.textMuted,
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
                                            color: isSelected ? AppTheme.primaryDark : AppTheme.textMain,
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
                                        '\$${s.precioBase.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.primary,
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
