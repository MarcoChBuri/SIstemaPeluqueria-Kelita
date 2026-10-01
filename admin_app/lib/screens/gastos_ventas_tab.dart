import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';

class GastosVentasTab extends StatefulWidget {
  const GastosVentasTab({super.key});

  @override
  State<GastosVentasTab> createState() => _GastosVentasTabState();
}

class _GastosVentasTabState extends State<GastosVentasTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
                            'FLUJO DE CAJA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primary,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Gastos & Ventas del Salón',
                              style: Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 2),
                          const Text(
                            'Control de egresos, ventas retail y atención presencial sin cita.',
                            style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                          ),

                          const SizedBox(height: 14),

                          // --- RESUMEN SEMANAL BANNER ---
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAF9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'RESUMEN DE ESTA SEMANA',
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primary, letterSpacing: 0.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: provider.balanceNetoEstaSemana >= 0 ? const Color(0xFFD1FAE5) : const Color(0xFFFFE4E6),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        'Balance: \$${provider.balanceNetoEstaSemana.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: provider.balanceNetoEstaSemana >= 0 ? const Color(0xFF047857) : AppTheme.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('Gastos Semanales', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '-\$${provider.gastosEstaSemana.toStringAsFixed(2)}',
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
                                          const Text('Ganancias Semanales', style: TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '+\$${provider.totalGananciasEstaSemana.toStringAsFixed(2)}',
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
                        tabs: [
                          Tab(
                            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                            text: 'Gastos (\$${provider.totalGastos.toStringAsFixed(2)})',
                          ),
                          Tab(
                            icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                            text: 'Ventas (\$${provider.totalVentas.toStringAsFixed(2)})',
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
            // Tab 2: Ventas
            _buildVentasList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildGastosList(AppStateProvider provider) {
    final gastos = provider.gastos;

    if (gastos.isEmpty) {
      return const Center(
        child: Text('No hay gastos registrados en este período.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: gastos.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final g = gastos[index];
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
                      g.concepto ?? 'Gasto de ${g.categoria}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '${g.categoria.toUpperCase()} | ${g.fecha}',
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildVentasList(AppStateProvider provider) {
    final ventas = provider.ventas;

    if (ventas.isEmpty) {
      return const Center(
        child: Text('No hay ventas de productos registradas.'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: ventas.length,
      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final v = ventas[index];
        final ganancia = (v.precioVenta - v.precioCosto) * v.cantidad;

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
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Color(0xFF047857), size: 20),
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
                    Text(
                      'Cant: ${v.cantidad} | Ganancia: +\$${ganancia.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF047857), fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                '\$${(v.precioVenta * v.cantidad).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
