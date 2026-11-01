import 'package:flutter/material.dart';

import 'features/qr/application/qr_controller.dart';
import 'features/qr/presentation/qr_page.dart';
import 'features/qr/qr_module.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SaludYaApp());
}

class SaludYaApp extends StatelessWidget {
  const SaludYaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'SaludYa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C926B)),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF1F7F4),
        ),
        home: const MainPage(),
      );
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _index = 2; // abre en "Cita"

  // Se crea una sola vez para que la cola no se reinicie al cambiar de pestaña.
  final QrController _qrController = buildQrController(useLocalData: true);

  // Navigator propio para "Cita": así la barra de abajo sigue visible
  // en las pantallas de turno, escáner y llegada confirmada.
  final _citaNavigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // El botón "atrás" de Android primero regresa dentro de la pestaña Cita.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final nav = _citaNavigatorKey.currentState;
        if (_index == 2 && nav != null && nav.canPop()) {
          nav.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: [
            const Center(child: Text('Inicio')),
            const Center(child: Text('Calendario')),
            Navigator(
              key: _citaNavigatorKey,
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => QrPage(controller: _qrController),
              ),
            ),
            const Center(child: Text('Configuración')),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFFE5F5F0),
          selectedIndex: _index,
          onDestinationSelected: (i) {
            // Tocar "Cita" estando en Cita vuelve a la lista de la cola.
            if (i == 2 && _index == 2) {
              _citaNavigatorKey.currentState?.popUntil((r) => r.isFirst);
            }
            setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Inicio'),
            NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendario'),
            NavigationDestination(icon: Icon(Icons.qr_code_2), label: 'Cita'),
            NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Configuración'),
          ],
        ),
      ),
    );
  }
}