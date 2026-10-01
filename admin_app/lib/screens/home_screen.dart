import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../theme/app_theme.dart';
import 'agenda_tab.dart';
import 'calculadora_tab.dart';
import 'dashboard_tab.dart';
import 'galeria_cursos_tab.dart';
import 'gastos_ventas_tab.dart';
import 'promociones_tab.dart';
import 'servicios_tab.dart';
import 'settings_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<String> _tabTitles = [
    'Dashboard',
    'Agenda de Citas',
    'Servicios',
    'Calculadora Color',
    'Gastos & Ventas',
    'Promociones',
    'Galería & Cursos',
  ];

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppStateProvider>(context);

    final List<Widget> screens = [
      DashboardTab(onNavigateToTab: (index) => setState(() => _currentIndex = index)),
      const AgendaTab(),
      const ServiciosTab(),
      const CalculadoraTab(),
      const GastosVentasTab(),
      const PromocionesTab(),
      const GaleriaCursosTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                color: AppTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.spa_rounded, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Raquel Admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                ),
                Text(
                  _tabTitles[_currentIndex],
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.normal),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textMain),
            tooltip: 'Sincronizar Datos',
            onPressed: () => provider.loadAllData(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.content_cut_rounded, color: AppTheme.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Peluquería Raquel',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'Panel de Administración Móvil',
                    style: TextStyle(color: Color(0xFFFFD9E4), fontSize: 12),
                  ),
                ],
              ),
            ),
            _buildDrawerItem(0, 'Dashboard', Icons.dashboard_rounded),
            _buildDrawerItem(1, 'Agenda de Citas', Icons.calendar_today_rounded, badgeCount: provider.citas.length),
            _buildDrawerItem(2, 'Servicios & Paquetes', Icons.content_cut_rounded),
            _buildDrawerItem(3, 'Calculadora Colorimetría', Icons.calculate_rounded),
            _buildDrawerItem(4, 'Gastos & Ventas', Icons.account_balance_wallet_rounded),
            _buildDrawerItem(5, 'Promociones', Icons.local_offer_rounded),
            _buildDrawerItem(6, 'Galería & Cursos', Icons.school_rounded),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_rounded, color: AppTheme.textMuted),
              title: const Text('Configuración del Servidor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  builder: (_) => const SettingsDialog(),
                );
              },
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex > 4 ? 4 : _currentIndex,
        onDestinationSelected: (idx) {
          if (idx == 4) {
            // Show more options bottom sheet or open Gastos
            _showMoreMenu(context);
          } else {
            setState(() => _currentIndex = idx);
          }
        },
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: provider.citas.any((c) => c.estado == 'pendiente'),
              child: const Icon(Icons.calendar_today_outlined),
            ),
            selectedIcon: const Icon(Icons.calendar_today_rounded),
            label: 'Agenda',
          ),
          const NavigationDestination(
            icon: Icon(Icons.content_cut_outlined),
            selectedIcon: Icon(Icons.content_cut_rounded),
            label: 'Servicios',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate_rounded),
            label: 'Calculadora',
          ),
          NavigationDestination(
            icon: const Icon(Icons.grid_view_outlined),
            selectedIcon: const Icon(Icons.grid_view_rounded),
            label: _currentIndex >= 4 ? _tabTitles[_currentIndex] : 'Más',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, String title, IconData icon, {int? badgeCount}) {
    final isSelected = _currentIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primary : AppTheme.textMuted),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primary : AppTheme.textMain,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      trailing: badgeCount != null && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : const Color(0xFFEFF4FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.textMain,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      selected: isSelected,
      onTap: () {
        Navigator.of(context).pop();
        setState(() => _currentIndex = index);
      },
    );
  }

  void _showMoreMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Más Opciones Administrativas',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFFFE4E6), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primary, size: 20),
                ),
                title: const Text('Gastos & Venta de Productos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Flujo de caja y auditoría financiera', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _currentIndex = 4);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.local_offer_rounded, color: Color(0xFF047857), size: 20),
                ),
                title: const Text('Promociones del Mes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Descuentos vigentes para clientas', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _currentIndex = 5);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.school_rounded, color: Color(0xFF2563EB), size: 20),
                ),
                title: const Text('Galería & Cursos Hotmart', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Portafolio visual y capacitaciones', style: TextStyle(fontSize: 12)),
                onTap: () {
                  Navigator.of(ctx).pop();
                  setState(() => _currentIndex = 6);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
