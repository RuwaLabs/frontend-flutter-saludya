import 'package:flutter/material.dart';

import '../application/qr_controller.dart';
import 'components/qr_ui.dart';
import 'register_arrival_page.dart';

/// P21 · Código manual
class ManualCodePage extends StatefulWidget {
  const ManualCodePage({super.key, required this.controller});
  final QrController controller;

  @override
  State<ManualCodePage> createState() => _ManualCodePageState();
}

class _ManualCodePageState extends State<ManualCodePage> {
  final _code = TextEditingController();
  // bookingCode del backend: SAL- + 10 caracteres (ej. SAL-1A2B3C4D5E)
  static final _pattern = RegExp(r'^SAL-[A-Z0-9]{10}$');

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _valid => _pattern.hasMatch(_code.text.trim().toUpperCase());

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return QrScaffold(
      title: 'Registrar por código',
      child: ListenableBuilder(
        listenable: c,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Código de reserva',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: QColors.text)),
            const SizedBox(height: 6),
            TextField(
              controller: _code,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'SAL-1A2B3C4D5E',
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: QColors.border)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: QColors.primary)),
              ),
            ),
            const Hint('Confirma el beneficiario y el horario antes de registrar su llegada.'),
            const SizedBox(height: 4),
            QButton('Validar reserva',
                loading: c.busy,
                onPressed: _valid ? () => submitArrival(context, c, _code.text) : null),
          ],
        ),
      ),
    );
  }
}
