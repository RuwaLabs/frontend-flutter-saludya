import 'package:flutter/material.dart';
import 'package:saludya/features/settings/presentation/settings_page.dart';

class MainPage extends StatefulWidget {
  final Future<void> Function() onLogout;

  const MainPage({super.key, required this.onLogout});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 3;

  final List<Widget> pages = [
    const Center(child: Text('Inicio: módulo pendiente de implementar')),
    const Center(child: Text('Calendario: módulo pendiente de implementar')),
    const Center(child: Text('Citas: módulo pendiente de implementar')),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SaludYa',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sesión',
                    onPressed: widget.onLogout,
                    icon: const Icon(Icons.logout),
                  ),
                ],
              ),
            ),
          ),
          Expanded(child: pages[selectedIndex]),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE5F5F0),
        selectedIndex: selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            selectedIndex = value;
          });
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_outlined),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_outlined),
            label: 'Calendario',
          ),
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_outlined),
            label: 'Cita',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny_outlined),
            selectedIcon: Icon(Icons.wb_sunny_outlined),
            label: 'Configuración',
          ),
        ],
      ),
    );
  }
}
