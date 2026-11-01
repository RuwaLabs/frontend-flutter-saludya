import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../application/qr_controller.dart';
import 'arrival_confirmed_page.dart';
import 'components/qr_ui.dart';
import 'manual_code_page.dart';

/// P14 · Registrar llegada (escáner QR)
class RegisterArrivalPage extends StatefulWidget {
  const RegisterArrivalPage({super.key, required this.controller});
  final QrController controller;

  @override
  State<RegisterArrivalPage> createState() => _RegisterArrivalPageState();
}

class _RegisterArrivalPageState extends State<RegisterArrivalPage> {
  final _scanner = MobileScannerController(formats: const [BarcodeFormat.qrCode]);
  bool _processing = false;

  @override
  void dispose() {
    _scanner.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (_processing || code == null || code.isEmpty) return;
    setState(() => _processing = true);
    await _scanner.stop();
    if (!mounted) return;
    await submitArrival(context, widget.controller, code, replace: true);
    if (mounted) {
      setState(() => _processing = false);
      await _scanner.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return QrScaffold(
      title: 'Registrar llegada',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Hint('Escanea el código QR de la reserva del paciente.'),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              height: 260,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: QColors.scannerBg),
                  MobileScanner(controller: _scanner, onDetect: _onDetect),
                  Center(
                    child: Container(
                      width: 190,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .92),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.qr_code_2, color: QColors.primary, size: 30),
                          const SizedBox(height: 8),
                          Text(_processing ? 'Validando...' : 'Centra el código en la cámara',
                              style: const TextStyle(fontSize: 11, color: QColors.text)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          QButton('Ingresar código manualmente',
              style: QButtonStyle.outline,
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ManualCodePage(controller: widget.controller)))),
          const Hint('La llegada se confirma después de validar la reserva y su horario.'),
        ],
      ),
    );
  }
}

/// Lógica compartida entre QR y código manual.
Future<void> submitArrival(BuildContext context, QrController c, String code,
    {bool replace = false}) async {
  final result = await c.registerArrival(code);
  if (!context.mounted) return;
  if (result == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(c.error ?? 'Reserva no válida.')));
    return;
  }
  final route = MaterialPageRoute(
      builder: (_) => ArrivalConfirmedPage(controller: c, result: result));
  replace ? Navigator.pushReplacement(context, route) : Navigator.push(context, route);
}
