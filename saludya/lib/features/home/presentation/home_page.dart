import 'package:flutter/material.dart';
import '../application/home_controller.dart';
import 'home_details_pages.dart';
import 'home_ui.dart';

enum HomeDestination { calendar, registerArrival, queue, appointments, settings, notifications, login }

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller, required this.onNavigate,
    this.staffName, this.establishmentName = 'Centro de Salud'});
  final HomeController controller;
  final ValueChanged<HomeDestination> onNavigate;
  final String? staffName;
  final String establishmentName;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); widget.controller.load(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.load();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: homeBackground,
    bottomNavigationBar: NavigationBar(selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 0) return;
        widget.onNavigate([HomeDestination.calendar, HomeDestination.appointments, HomeDestination.settings][index - 1]);
      }, destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Inicio'),
        NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Calendario'),
        NavigationDestination(icon: Icon(Icons.qr_code), label: 'Cita'),
        NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'Configuración'),
      ]),
    body: SafeArea(child: AnimatedBuilder(animation: widget.controller, builder: (context, _) {
      final c = widget.controller;
      final summary = c.summary;
      return RefreshIndicator(onRefresh: c.load, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(20), children: [
          Row(children: [Expanded(child: Text(widget.staffName?.trim().isNotEmpty == true ? 'Hola, ${widget.staffName}' : 'Bienvenido',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600))),
            IconButton(tooltip: 'Notificaciones', onPressed: () => widget.onNavigate(HomeDestination.notifications), icon: const Icon(Icons.notifications_none, color: homeGreen))]),
          const SizedBox(height: 24), Text('Admisión · ${widget.establishmentName}', style: const TextStyle(color: homeMuted)),
          const SizedBox(height: 12),
          if (c.loading) const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
          if (!c.loading && c.error != null) ...[
            HomeMessage(message: c.error!.message, error: true, onRetry: c.load),
            if (c.error!.sessionExpired) FilledButton(onPressed: () => widget.onNavigate(HomeDestination.login), child: const Text('Iniciar sesión')),
          ],
          if (!c.loading && c.error == null && summary != null) ...[
            Text(homeDate(summary.date), style: const TextStyle(color: homeMuted)), const SizedBox(height: 12),
            HomeCard(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HomeReservationsPage(summary: summary, repository: c.repository))),
              child: SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Citas pendientes', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                Text('${summary.pending.length} ${summary.pending.length == 1 ? 'reserva para hoy' : 'reservas para hoy'}', style: const TextStyle(color: homeMuted)),
                if (summary.pending.isNotEmpty) Text(summary.pending.map((b) => b.specialty).toSet().join(', '), style: const TextStyle(color: homeMuted)),
                const SizedBox(height: 4), TextButton(onPressed: () => widget.onNavigate(HomeDestination.calendar), child: const Text('Ver calendario →')),
                TextButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => HomeReservationsPage(summary: summary, repository: c.repository))), child: const Text('Ver pacientes con reserva →')),
              ]))),
            HomeCard(onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => CancelledAppointmentsPage(summary: summary))),
              child: SizedBox(width: double.infinity, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Citas canceladas', style: TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 8),
                Text('${summary.cancelled.length} ${summary.cancelled.length == 1 ? 'cancelación de citas de hoy' : 'cancelaciones de citas de hoy'}', style: const TextStyle(color: homeMuted)),
                const SizedBox(height: 8), const Text('Ver detalle →', style: TextStyle(color: homeGreen, fontWeight: FontWeight.w600)),
              ]))),
            const SizedBox(height: 4), FilledButton(onPressed: () => widget.onNavigate(HomeDestination.registerArrival), child: const Text('Registrar llegada')),
            const SizedBox(height: 12), OutlinedButton(onPressed: () => widget.onNavigate(HomeDestination.queue), child: const Text('Ver cola de atención')),
          ],
        ]));
    })));
}
