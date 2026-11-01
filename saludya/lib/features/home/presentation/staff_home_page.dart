import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../auth/application/auth_service.dart';
import '../application/home_controller.dart';
import '../home_module.dart';
import '../../qr/application/qr_controller.dart';
import '../../qr/qr_module.dart';
import '../../qr/presentation/qr_page.dart';
import '../../qr/presentation/register_arrival_page.dart';
import 'home_details_pages.dart';
import 'home_page.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({
    super.key,
    required this.auth,
    required this.onSignedOut,
    this.onNavigate,
    this.staffName,
    this.establishmentName = 'Centro de Salud',
  });
  final AuthService auth;
  final VoidCallback onSignedOut;
  final ValueChanged<HomeDestination>? onNavigate;
  final String? staffName;
  final String establishmentName;
  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  final _client = http.Client();
  late final HomeController _controller = buildHomeController(
    client: _client,
    tokenProvider: () async => (await widget.auth.restoreSession())?.token,
  );
  late final QrController _qr = buildQrController(
    baseUrl: const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://3.129.217.49:8080/api/v1',
    ),
    tokenProvider: () async => (await widget.auth.restoreSession())?.token,
  );
  @override
  void dispose() {
    _controller.dispose();
    _qr.dispose();
    _client.close();
    super.dispose();
  }

  Future<void> _navigate(HomeDestination destination) async {
    if (destination == HomeDestination.login) {
      try {
        await widget.auth.logout();
      } catch (_) {
        /* An expired session may already be invalid. */
      }
      if (mounted) widget.onSignedOut();
      return;
    }
    if (widget.onNavigate != null) {
      widget.onNavigate!(destination);
      return;
    }
    Widget? page;
    if (destination == HomeDestination.registerArrival) {
      page = RegisterArrivalPage(controller: _qr);
    }
    if (destination == HomeDestination.queue ||
        destination == HomeDestination.appointments) {
      page = QrPage(controller: _qr);
    }
    if (destination == HomeDestination.calendar &&
        _controller.summary != null) {
      page = HomeReservationsPage(
        summary: _controller.summary!,
        repository: _controller.repository,
      );
    }
    if (page != null) {
      await Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => page!));
      if (mounted) await _controller.load();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Esta opción no está disponible por el momento.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => HomePage(
    controller: _controller,
    onNavigate: _navigate,
    staffName: widget.staffName,
    establishmentName: widget.establishmentName,
  );
}
