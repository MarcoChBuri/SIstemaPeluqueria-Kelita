import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/galeria_item.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class GaleriaCursosTab extends StatefulWidget {
  const GaleriaCursosTab({super.key});

  @override
  State<GaleriaCursosTab> createState() => _GaleriaCursosTabState();
}

class _GaleriaCursosTabState extends State<GaleriaCursosTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String url) {
    if (url.isEmpty) {
      return Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.grey)),
      );
    }

    if (url.startsWith('data:image')) {
      try {
        final commaIdx = url.indexOf(',');
        final base64Data = commaIdx != -1 ? url.substring(commaIdx + 1) : url;
        final bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (c, err, stack) => Container(
            color: const Color(0xFFF1F5F9),
            child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
          ),
        );
      } catch (_) {}
    }

    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (c, err, stack) => Container(
        color: const Color(0xFFF1F5F9),
        child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
      ),
    );
  }

  void _showImagePreviewDialog(BuildContext context, GaleriaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _buildImageWidget(item.imagenUrl),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.titulo,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          item.categoria,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  if (item.descripcion != null && item.descripcion!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(item.descripcion!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDeleteFoto(context, item);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                          tooltip: 'Eliminar Foto',
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cerrar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteFoto(BuildContext context, GaleriaItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar foto?'),
        content: Text('¿Deseas eliminar "${item.titulo}" de la galería? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final prov = Provider.of<AppStateProvider>(context, listen: false);
                await prov.deleteFotoGaleria(item.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Foto eliminada de la galería.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              }
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _openUploadFotoDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final tituloCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String categoria = 'Colorimetría';
    bool destacado = true;
    String? localBase64;
    String? localPreviewPath;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickImage(ImageSource source) async {
              try {
                final XFile? file = await _picker.pickImage(
                  source: source,
                  maxWidth: 1200,
                  maxHeight: 1200,
                  imageQuality: 85,
                );
                if (file != null) {
                  final bytes = await file.readAsBytes();
                  final mime = file.mimeType ?? 'image/jpeg';
                  final b64 = 'data:$mime;base64,${base64Encode(bytes)}';
                  setDialogState(() {
                    localBase64 = b64;
                    localPreviewPath = file.path;
                    urlCtrl.text = b64;
                  });
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo cargar la imagen: $e'), backgroundColor: AppTheme.danger),
                  );
                }
              }
            }

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
                              'Subir Foto al Portafolio',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Selector de Imagen: Galería / Cámara
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAF9),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Column(
                            children: [
                              if (localBase64 != null || urlCtrl.text.isNotEmpty)
                                Container(
                                  height: 150,
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: _buildImageWidget(urlCtrl.text),
                                ),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => pickImage(ImageSource.gallery),
                                      icon: const Icon(Icons.photo_library_rounded, size: 18),
                                      label: const Text('Galería', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: AppTheme.primary),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => pickImage(ImageSource.camera),
                                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                                      label: const Text('Cámara', style: TextStyle(fontSize: 12)),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 10),
                                        side: const BorderSide(color: AppTheme.primary),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // O ingresar URL manualmente
                        TextFormField(
                          controller: urlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'O Enlace de Imagen (URL)',
                            hintText: 'https://...',
                            prefixIcon: Icon(Icons.link_rounded),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Selecciona una foto o escribe una URL' : null,
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 12),

                        // Título
                        TextFormField(
                          controller: tituloCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Título del Trabajo *',
                            hintText: 'Ej: Balayage Rubio Vainilla',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 12),

                        // Categoría
                        DropdownButtonFormField<String>(
                          initialValue: categoria,
                          decoration: const InputDecoration(labelText: 'Categoría'),
                          items: const [
                            DropdownMenuItem(value: 'Colorimetría', child: Text('Colorimetría')),
                            DropdownMenuItem(value: 'Novias', child: Text('Novias & Bodas')),
                            DropdownMenuItem(value: 'Tratamientos', child: Text('Alisados & Tratamientos')),
                            DropdownMenuItem(value: 'Cortes', child: Text('Cortes de Cabello')),
                            DropdownMenuItem(value: 'Peinados', child: Text('Peinados & Maquillaje')),
                            DropdownMenuItem(value: 'General', child: Text('General')),
                          ],
                          onChanged: (v) => setDialogState(() => categoria = v ?? 'General'),
                        ),
                        const SizedBox(height: 12),

                        // Descripción
                        TextFormField(
                          controller: descCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Descripción (Opcional)',
                            hintText: 'Técnica utilizada, matiz o productos aplicados',
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Destacado
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Destacar en Portada Web', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Aparecerá en los primeros trabajos del sitio web.', style: TextStyle(fontSize: 11)),
                          value: destacado,
                          onChanged: (v) => setDialogState(() => destacado = v),
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final prov = Provider.of<AppStateProvider>(context, listen: false);
                              try {
                                await prov.createFotoGaleria(
                                  titulo: tituloCtrl.text.trim(),
                                  categoria: categoria,
                                  imagenUrl: urlCtrl.text.trim(),
                                  descripcion: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                  destacado: destacado,
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Foto agregada a la galería con éxito.')),
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
                            child: const Text('Guardar Foto en Galería'),
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

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openUploadFotoDialog(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Subir Foto', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
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
                            'PORTAFOLIO & FORMACIÓN',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Galería & Cursos Online',
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          const Text(
                            'Sube fotos de tus transformaciones desde tu teléfono y gestiona cursos.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primary,
                        unselectedLabelColor: AppTheme.textMuted,
                        indicatorColor: AppTheme.primary,
                        indicatorWeight: 3,
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.photo_library_outlined, size: 18),
                            text: 'Galería (${provider.galeria.length})',
                          ),
                          Tab(
                            icon: const Icon(Icons.school_outlined, size: 18),
                            text: 'Cursos Hotmart (${provider.cursos.length})',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Galería
            _buildGaleriaGrid(provider),
            // Cursos
            _buildCursosList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildGaleriaGrid(AppStateProvider provider) {
    final galeria = provider.galeria;

    if (galeria.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.photo_library_outlined, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text('No hay fotos en la galería aún.', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _openUploadFotoDialog(context),
              icon: const Icon(Icons.add_a_photo_rounded, size: 16),
              label: const Text('Subir Primera Foto'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: galeria.length,
      itemBuilder: (context, index) {
        final item = galeria[index];
        return InkWell(
          onTap: () => _showImagePreviewDialog(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildImageWidget(item.imagenUrl),
                      if (item.destacado)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, size: 12, color: Colors.white),
                                SizedBox(width: 2),
                                Text('Top', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(),
                            onPressed: () => _confirmDeleteFoto(context, item),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.categoria.toUpperCase(),
                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primary),
                          ),
                          const Icon(Icons.chevron_right_rounded, size: 14, color: AppTheme.textMuted),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCursosList(AppStateProvider provider) {
    final cursos = provider.cursos;

    if (cursos.isEmpty) {
      return const Center(child: Text('No hay cursos configurados.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cursos.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final c = cursos[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppTheme.border),
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
                      color: AppTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'HOTMART ONLINE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Text(
                    '\$${c.precioReferencia.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.titulo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                c.descripcion,
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    if (c.linkHotmart.isNotEmpty) {
                      final uri = Uri.parse(c.linkHotmart);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: const Text('Ver Curso en Hotmart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
