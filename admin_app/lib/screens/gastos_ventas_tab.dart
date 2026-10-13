import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/gasto.dart';
import '../models/venta_producto.dart';
import '../models/cita.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class GastosVentasTab extends StatefulWidget {
  const GastosVentasTab({super.key});

  @override
  State<GastosVentasTab> createState() => _GastosVentasTabState();
}

class _GastosVentasTabState extends State<GastosVentasTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _esModoSemanal = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatFecha(String? fechaRaw) {
    if (fechaRaw == null || fechaRaw.trim().isEmpty) return '';
    try {
      final dt = DateTime.parse(fechaRaw.trim()).toLocal();
      return DateFormat("d MMM yyyy, h:mm a", 'es').format(dt);
    } catch (_) {
      try {
        final clean = fechaRaw.split('T')[0].split(' ')[0].trim();
        final dt = DateTime.parse(clean);
        return DateFormat("d MMM yyyy", 'es').format(dt);
      } catch (_) {
        return fechaRaw;
      }
    }
  }

  // =========================================================
  // DIÁLOGOS DE REGISTRO
  // =========================================================

  void _openNewGastoDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final montoCtrl = TextEditingController(text: '15.00');
    final conceptoCtrl = TextEditingController();
    String categoria = 'productos';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Registrar Gasto', style: Theme.of(context).textTheme.headlineMedium),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto del Gasto (\$) *',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0)
                            ? 'Monto inválido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: categoria,
                        decoration: const InputDecoration(labelText: 'Categoría *'),
                        items: const [
                          DropdownMenuItem(value: 'productos', child: Text('Productos / Tintes')),
                          DropdownMenuItem(value: 'arriendo', child: Text('Arriendo')),
                          DropdownMenuItem(value: 'servicios', child: Text('Servicios Básicos')),
                          DropdownMenuItem(value: 'comida', child: Text('Comida / Refrigerio')),
                          DropdownMenuItem(value: 'transporte', child: Text('Transporte')),
                          DropdownMenuItem(value: 'otros', child: Text('Otros')),
                        ],
                        onChanged: (v) => setDialogState(() => categoria = v ?? 'productos'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: conceptoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Concepto / Detalle',
                          hintText: 'Ej: Shampoo Post-Color, Papel aluminio',
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final prov = Provider.of<AppStateProvider>(context, listen: false);
                            try {
                              await prov.createGasto(
                                monto: double.parse(montoCtrl.text),
                                categoria: categoria,
                                concepto: conceptoCtrl.text.trim().isEmpty ? null : conceptoCtrl.text.trim(),
                              );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Gasto guardado con éxito.')),
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
                          child: const Text('Guardar Gasto'),
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

  void _openNewVentaDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController();
    final costoCtrl = TextEditingController(text: '8.00');
    final precioCtrl = TextEditingController(text: '16.00');
    final cantidadCtrl = TextEditingController(text: '1');
    final clienteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
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
                        Text('Venta de Producto', style: Theme.of(context).textTheme.headlineMedium),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        hintText: 'Ej: Mascarilla de Keratina 250ml',
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: costoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Costo (\$) *'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Precio Venta (\$) *'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cantidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Cantidad *'),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: clienteCtrl,
                            decoration: const InputDecoration(labelText: 'Clienta (Opcional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          final prov = Provider.of<AppStateProvider>(context, listen: false);
                          try {
                            await prov.createVentaProducto(
                              nombre: nombreCtrl.text.trim(),
                              costo: double.parse(costoCtrl.text),
                              precio: double.parse(precioCtrl.text),
                              cantidad: int.parse(cantidadCtrl.text),
                              nombreCliente: clienteCtrl.text.trim().isEmpty ? null : clienteCtrl.text.trim(),
                            );
                            if (ctx.mounted) {
                              Navigator.of(ctx).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Venta de producto registrada.')),
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
                        child: const Text('Registrar Venta'),
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
  }

  void _openRegistrarServicioDirectoDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final servicioCtrl = TextEditingController();
    final precioCtrl = TextEditingController(text: '20.00');
    final clienteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Servicio Presencial (Sin Cita)', style: Theme.of(context).textTheme.headlineMedium),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: servicioCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Servicio Realizado *',
                      hintText: 'Ej: Corte + Secado, Manicure, Tinte Express',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: precioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Monto Cobrado (\$) *',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0)
                        ? 'Monto inválido'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: clienteCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre Clienta (Opcional)',
                      hintText: 'Ej: María Gómez',
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final prov = Provider.of<AppStateProvider>(context, listen: false);
                        try {
                          await prov.createServicioSinCita(
                            nombreServicio: servicioCtrl.text.trim(),
                            precio: double.parse(precioCtrl.text),
                            nombreCliente: clienteCtrl.text.trim().isEmpty ? null : clienteCtrl.text.trim(),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Servicio presencial registrado en ganancias.')),
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
                      child: const Text('Registrar en Ganancias'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================================================
  // DIÁLOGOS DE EDICIÓN Y ELIMINACIÓN (CORRECCIÓN DE ERRORES)
  // =========================================================

  void _openEditGastoDialog(BuildContext context, Gasto gasto) {
    final formKey = GlobalKey<FormState>();
    final montoCtrl = TextEditingController(text: gasto.monto.toStringAsFixed(2));
    final conceptoCtrl = TextEditingController(text: gasto.concepto ?? '');
    String categoria = gasto.categoria;

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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Editar Gasto', style: Theme.of(context).textTheme.headlineMedium),
                          IconButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: montoCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Monto del Gasto (\$) *',
                          prefixIcon: Icon(Icons.attach_money_rounded),
                        ),
                        validator: (v) => (v == null || double.tryParse(v) == null || double.parse(v) <= 0)
                            ? 'Monto inválido'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: categoria,
                        decoration: const InputDecoration(labelText: 'Categoría *'),
                        items: const [
                          DropdownMenuItem(value: 'productos', child: Text('Productos / Tintes')),
                          DropdownMenuItem(value: 'arriendo', child: Text('Arriendo')),
                          DropdownMenuItem(value: 'servicios', child: Text('Servicios Básicos')),
                          DropdownMenuItem(value: 'comida', child: Text('Comida / Refrigerio')),
                          DropdownMenuItem(value: 'transporte', child: Text('Transporte')),
                          DropdownMenuItem(value: 'otros', child: Text('Otros')),
                        ],
                        onChanged: (v) => setDialogState(() => categoria = v ?? 'productos'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: conceptoCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Concepto / Detalle',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE4E6),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                _confirmDeleteGasto(context, gasto);
                              },
                              icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                              tooltip: 'Eliminar Gasto',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (!formKey.currentState!.validate()) return;
                                final prov = Provider.of<AppStateProvider>(context, listen: false);
                                try {
                                  await prov.updateGasto(
                                    id: gasto.id,
                                    monto: double.parse(montoCtrl.text),
                                    categoria: categoria,
                                    concepto: conceptoCtrl.text.trim().isEmpty ? null : conceptoCtrl.text.trim(),
                                  );
                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Gasto actualizado correctamente.')),
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
                              child: const Text('Guardar'),
                            ),
                          ),
                        ],
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

  void _confirmDeleteGasto(BuildContext context, Gasto gasto) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar este gasto?'),
        content: Text(
          'Se borrará el gasto de \$${gasto.monto.toStringAsFixed(2)} (${gasto.concepto ?? gasto.categoria}). '
          'Esta acción recalculará tus balances.',
        ),
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
                await prov.deleteGasto(gasto.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gasto eliminado.')),
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

  void _openEditVentaDialog(BuildContext context, VentaProducto venta) {
    final formKey = GlobalKey<FormState>();
    final nombreCtrl = TextEditingController(text: venta.nombreProducto);
    final costoCtrl = TextEditingController(text: venta.precioCosto.toStringAsFixed(2));
    final precioCtrl = TextEditingController(text: venta.precioVenta.toStringAsFixed(2));
    final cantidadCtrl = TextEditingController(text: venta.cantidad.toString());
    final clienteCtrl = TextEditingController(text: venta.nombreCliente ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
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
                        Text('Editar Ingreso / Venta', style: Theme.of(context).textTheme.headlineMedium),
                        IconButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: nombreCtrl,
                      decoration: const InputDecoration(labelText: 'Concepto / Producto *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: costoCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Costo (\$) *'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: precioCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Precio Cobrado (\$) *'),
                            validator: (v) => (v == null || double.tryParse(v) == null) ? 'Inválido' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: cantidadCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Cantidad *'),
                            validator: (v) => (v == null || int.tryParse(v) == null) ? 'Inválido' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: clienteCtrl,
                            decoration: const InputDecoration(labelText: 'Clienta (Opcional)'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFE4E6),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _confirmDeleteVenta(context, venta);
                            },
                            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger),
                            tooltip: 'Eliminar Ingreso',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (!formKey.currentState!.validate()) return;
                              final prov = Provider.of<AppStateProvider>(context, listen: false);
                              try {
                                await prov.updateVentaProducto(
                                  id: venta.id,
                                  nombre: nombreCtrl.text.trim(),
                                  costo: double.parse(costoCtrl.text),
                                  precio: double.parse(precioCtrl.text),
                                  cantidad: int.parse(cantidadCtrl.text),
                                  nombreCliente: clienteCtrl.text.trim().isEmpty ? null : clienteCtrl.text.trim(),
                                );
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Ingreso actualizado correctamente.')),
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
                            child: const Text('Guardar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteVenta(BuildContext context, VentaProducto venta) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar este ingreso?'),
        content: Text(
          'Se borrará la venta/servicio "${venta.nombreProducto}" por valor de \$${(venta.precioVenta * venta.cantidad).toStringAsFixed(2)}. '
          'Se restará de las ganancias.',
        ),
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
                await prov.deleteVentaProducto(venta.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingreso eliminado.')),
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

  void _openEditCitaCobradaDialog(BuildContext context, Cita cita) {
    final precioCtrl = TextEditingController(text: cita.precioFinal.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
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
                  Text('Modificar Cobro', style: Theme.of(context).textTheme.headlineMedium),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE4E6),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _confirmDeleteCita(context, cita);
                          },
                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.danger, size: 20),
                          tooltip: 'Eliminar Cita',
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Clienta: ${cita.clienteNombre}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Servicio: ${cita.servicios?.nombre ?? "Atención en salón"} • ${cita.fechaCita}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: precioCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monto Cobrado Final (\$) *',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final prov = Provider.of<AppStateProvider>(context, listen: false);
                        try {
                          await prov.updateCitaStatus(cita.id, estadoPago: 'pendiente');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Cobro desmarcado (vuelve a pendiente).')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        foregroundColor: const Color(0xFFD97706),
                      ),
                      child: const Text('Desmarcar Cobro'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final nuevo = double.tryParse(precioCtrl.text);
                        if (nuevo == null || nuevo <= 0) return;
                        Navigator.pop(ctx);
                        final prov = Provider.of<AppStateProvider>(context, listen: false);
                        try {
                          await prov.updateCitaPrecio(cita.id, nuevo);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Monto de cita actualizado.')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.danger),
                            );
                          }
                        }
                      },
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteCita(BuildContext context, Cita cita) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Eliminar esta cita?'),
        content: Text(
          'Se eliminará completamente la cita de "${cita.clienteNombre}" del ${cita.fechaCita}. '
          'Se restará de las ganancias y se liberará el espacio de la agenda.',
        ),
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
                await prov.deleteCita(cita.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cita eliminada de la agenda y ganancias.')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error al eliminar cita: $e'), backgroundColor: AppTheme.danger),
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

  void _showRegistrarOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '¿Qué deseas registrar?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.danger),
                  ),
                  title: const Text('Registrar Gasto', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Egreso por tintes, insumos, servicios, etc.'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openNewGastoDialog(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF047857)),
                  ),
                  title: const Text('Registrar Venta de Producto', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Venta de shampoo, keratina o retail'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openNewVentaDialog(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.content_cut_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: const Text('Registrar Servicio Presencial (Sin Cita)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Atención directa a clienta que llegó al salón'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _openRegistrarServicioDirectoDialog(context);
                  },
                ),
              ],
            ),
          ),
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
        onPressed: () => _showRegistrarOptions(context),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Registrar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                            'FLUJO DE CAJA & HISTORIAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Gastos, Ventas & Historial',
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          const Text(
                            'Controla egresos, edita o elimina ingresos mal registrados y revisa el historial.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),
                          const SizedBox(height: 14),

                          // --- RESUMEN SEMANAL / MENSUAL CON BOTONES ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _esModoSemanal ? 'RESUMEN SEMANAL' : 'RESUMEN MENSUAL',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primary,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE2E8F0),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          _buildPeriodoBtn(
                                            label: 'Semanal',
                                            icon: Icons.calendar_view_week_rounded,
                                            selected: _esModoSemanal,
                                            onTap: () => setState(() => _esModoSemanal = true),
                                          ),
                                          const SizedBox(width: 3),
                                          _buildPeriodoBtn(
                                            label: 'Mensual',
                                            icon: Icons.calendar_month_rounded,
                                            selected: !_esModoSemanal,
                                            onTap: () => setState(() => _esModoSemanal = false),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _esModoSemanal ? 'Balance de la Semana' : 'Balance del Mes',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '\$${(_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes).toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold,
                                            color: (_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes) >= 0
                                                ? const Color(0xFF047857)
                                                : AppTheme.danger,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: (_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes) >= 0
                                            ? const Color(0xFFD1FAE5)
                                            : const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            (_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes) >= 0
                                                ? Icons.trending_up_rounded
                                                : Icons.trending_down_rounded,
                                            size: 14,
                                            color: (_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes) >= 0
                                                ? const Color(0xFF047857)
                                                : AppTheme.danger,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            (_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes) >= 0
                                                ? 'Rentable'
                                                : 'Déficit',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: (_esModoSemanal ? provider.balanceNetoEstaSemana : provider.balanceNetoEsteMes) >= 0
                                                  ? const Color(0xFF047857)
                                                  : AppTheme.danger,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: Color(0xFFE2E8F0)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _esModoSemanal ? 'Gastos Semanales' : 'Gastos Mensuales',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '-\$${(_esModoSemanal ? provider.gastosEstaSemana : provider.gastosEsteMes).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.danger),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(width: 1, height: 28, color: AppTheme.border),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _esModoSemanal ? 'Ganancias Semanales' : 'Ganancias Mensuales',
                                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+\$${(_esModoSemanal ? provider.totalGananciasEstaSemana : provider.totalIngresosEsteMes).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
                        tabs: const [
                          Tab(
                            icon: Icon(Icons.arrow_downward_rounded, size: 16),
                            text: 'Gastos',
                          ),
                          Tab(
                            icon: Icon(Icons.trending_up_rounded, size: 16),
                            text: 'Ingresos',
                          ),
                          Tab(
                            icon: Icon(Icons.history_rounded, size: 16),
                            text: 'Historial',
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
            // Tab 1: Gastos
            _buildGastosList(provider),
            // Tab 2: Ganancias (Servicios + Ventas)
            _buildGananciasList(provider),
            // Tab 3: Historial Completo / Auditoría
            _buildHistorialList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosList(AppStateProvider provider) {
    final gastos = provider.gastos;

    if (gastos.isEmpty) {
      return const Center(
        child: Text('No hay gastos registrados.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: gastos.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final g = gastos[index];
        return InkWell(
          onTap: () => _openEditGastoDialog(context, g),
          borderRadius: BorderRadius.circular(16),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.danger, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.concepto ?? 'Gasto en ${g.categoria}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${g.categoria.toUpperCase()} • ${_formatFecha(g.fecha)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
                Text(
                  '-\$${g.monto.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.danger,
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                  onPressed: () => _openEditGastoDialog(context, g),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                  onPressed: () => _confirmDeleteGasto(context, g),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGananciasList(AppStateProvider provider) {
    final citasCobradas = provider.citas.where((c) =>
      c.isPagada ||
      c.estado.toLowerCase() == 'completada' ||
      c.estado.toLowerCase() == 'realizada' ||
      c.estado.toLowerCase() == 'pagada'
    ).toList();
    final ventas = provider.ventas;

    final totalServicios = provider.gananciasCitas;
    final totalProductos = provider.totalVentas;

    if (citasCobradas.isEmpty && ventas.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.monetization_on_outlined, size: 48, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text(
                'Aún no hay ganancias registradas.',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted),
              ),
              SizedBox(height: 4),
              Text(
                'Las citas cobradas y ventas de productos aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // Tarjetas resumen de Ganancias
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.content_cut_rounded, size: 14, color: Color(0xFF059669)),
                        SizedBox(width: 4),
                        Text(
                          'Servicios',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+\$${totalServicios.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF047857)),
                    ),
                    Text(
                      '${citasCobradas.length} servicios cobrados',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF065F46)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          'Retail / Venta',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '+\$${totalProductos.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1D4ED8)),
                    ),
                    Text(
                      '${ventas.length} ventas retail',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF1E40AF)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // SECCIÓN SERVICIOS
        if (citasCobradas.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.content_cut_rounded, size: 15, color: AppTheme.textMuted),
              SizedBox(width: 6),
              Text(
                'SERVICIOS COBRADOS (Toca para editar/anular)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...citasCobradas.map((c) => InkWell(
            onTap: () => _openEditCitaCobradaDialog(context, c),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD1FAE5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF047857), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.servicios?.nombre.isNotEmpty == true ? c.servicios!.nombre : 'Servicio en Salón',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Clienta: ${c.clienteNombre} • ${_formatFecha(c.fechaCita)}',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '+\$${c.precioFinal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF047857),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                    onPressed: () => _openEditCitaCobradaDialog(context, c),
                    tooltip: 'Editar o Desmarcar',
                  ),
                ],
              ),
            ),
          )),
          const SizedBox(height: 10),
        ],

        // SECCIÓN PRODUCTOS RETAIL
        if (ventas.isNotEmpty) ...[
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 15, color: AppTheme.textMuted),
              SizedBox(width: 6),
              Text(
                'VENTAS DE PRODUCTOS (Toca para editar/borrar)',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMuted, letterSpacing: 0.8),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...ventas.map((v) {
            final ganancia = (v.precioVenta - v.precioCosto) * v.cantidad;
            return InkWell(
              onTap: () => _openEditVentaDialog(context, v),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v.nombreProducto,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Cant: ${v.cantidad} ${v.nombreCliente != null ? "• ${v.nombreCliente}" : ""} | Ganancia: +\$${ganancia.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                          ),
                          if (v.fecha.isNotEmpty)
                            Text(
                              _formatFecha(v.fecha),
                              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '+\$${(v.precioVenta * v.cantidad).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textMuted),
                      onPressed: () => _openEditVentaDialog(context, v),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                      onPressed: () => _confirmDeleteVenta(context, v),
                      tooltip: 'Eliminar',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildHistorialList(AppStateProvider provider) {
    // Combinar todos los movimientos en una lista unificada
    final List<Map<String, dynamic>> movimientos = [];

    for (final g in provider.gastos) {
      movimientos.add({
        'id': g.id,
        'tipo': 'gasto',
        'titulo': g.concepto ?? 'Gasto en ${g.categoria}',
        'subtitulo': 'Categoría: ${g.categoria.toUpperCase()}',
        'monto': g.monto,
        'fecha': g.fecha,
        'esIngreso': false,
        'objeto': g,
      });
    }

    for (final v in provider.ventas) {
      movimientos.add({
        'id': v.id,
        'tipo': 'venta',
        'titulo': v.nombreProducto,
        'subtitulo': v.nombreCliente != null ? 'Cliente: ${v.nombreCliente}' : 'Venta directa',
        'monto': v.precioVenta * v.cantidad,
        'fecha': v.fecha,
        'esIngreso': true,
        'objeto': v,
      });
    }

    final citasCobradas = provider.citas.where((c) =>
      c.isPagada ||
      c.estado.toLowerCase() == 'completada' ||
      c.estado.toLowerCase() == 'realizada' ||
      c.estado.toLowerCase() == 'pagada'
    );

    for (final c in citasCobradas) {
      movimientos.add({
        'id': c.id,
        'tipo': 'cita',
        'titulo': c.servicios?.nombre.isNotEmpty == true ? c.servicios!.nombre : 'Servicio en Salón',
        'subtitulo': 'Clienta: ${c.clienteNombre}',
        'monto': c.precioFinal,
        'fecha': c.fechaCita,
        'esIngreso': true,
        'objeto': c,
      });
    }

    // Ordenar de más reciente a más antiguo
    movimientos.sort((a, b) => (b['fecha']?.toString() ?? '').compareTo(a['fecha']?.toString() ?? ''));

    if (movimientos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 48, color: AppTheme.textMuted),
              SizedBox(height: 12),
              Text('No hay movimientos en el historial aún.', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
              SizedBox(height: 4),
              Text('Todos los gastos e ingresos aparecerán aquí con fecha y hora.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: movimientos.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final m = movimientos[index];
        final bool esIngreso = m['esIngreso'] == true;

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: esIngreso ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  esIngreso ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: esIngreso ? const Color(0xFF047857) : AppTheme.danger,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: esIngreso ? const Color(0xFFECFDF5) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: esIngreso ? const Color(0xFFA7F3D0) : const Color(0xFFFECDD3)),
                          ),
                          child: Text(
                            esIngreso ? 'INGRESO' : 'GASTO',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: esIngreso ? const Color(0xFF047857) : AppTheme.danger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _formatFecha(m['fecha']?.toString()),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m['titulo']?.toString() ?? '',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      m['subtitulo']?.toString() ?? '',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${esIngreso ? "+" : "-"}\$${(m['monto'] as num).toDouble().toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: esIngreso ? const Color(0xFF047857) : AppTheme.danger,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Editar',
                        onPressed: () {
                          if (m['tipo'] == 'gasto') {
                            _openEditGastoDialog(context, m['objeto'] as Gasto);
                          } else if (m['tipo'] == 'venta') {
                            _openEditVentaDialog(context, m['objeto'] as VentaProducto);
                          } else if (m['tipo'] == 'cita') {
                            _openEditCitaCobradaDialog(context, m['objeto'] as Cita);
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppTheme.danger),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: 'Eliminar',
                        onPressed: () {
                          if (m['tipo'] == 'gasto') {
                            _confirmDeleteGasto(context, m['objeto'] as Gasto);
                          } else if (m['tipo'] == 'venta') {
                            _confirmDeleteVenta(context, m['objeto'] as VentaProducto);
                          } else if (m['tipo'] == 'cita') {
                            _confirmDeleteCita(context, m['objeto'] as Cita);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPeriodoBtn({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? AppTheme.primary : AppTheme.textMuted,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.bold : FontWeight.w500,
                color: selected ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
