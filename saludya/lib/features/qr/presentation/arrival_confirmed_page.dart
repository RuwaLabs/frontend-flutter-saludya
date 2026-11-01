import 'package:flutter/material.dart';

import '../application/qr_controller.dart';
import '../domain/arrival_result.dart';
import 'components/qr_ui.dart';
import 'register_arrival_page.dart';

/// P15 · Llegada registrada
class ArrivalConfirmedPage extends StatelessWidget {
  const ArrivalConfirmedPage({super.key, required this.controller, required this.result});
  final QrController controller;
  final ArrivalResult result;

  void _backToQr(BuildContext context) =>
      Navigator.popUntil(context, (r) => r.isFirst);

  @override
  Widget build(BuildContext context) {
    final r = result;
    return QrScaffold(
      title: 'Llegada confirmada',
      onBack: () => _backToQr(context),
      child: Column(
        children: [
          QCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.patientName,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: QColors.text)),
                const SizedBox(height: 8),
                for (final l in [
                  'Reserva ${r.reservationCode}',
                  'Llegada: ${hhmm(r.arrivedAt)}',
                  '${r.specialty} · ${r.room.isNotEmpty ? r.room : r.doctor}',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(l, style: const TextStyle(fontSize: 12, color: QColors.muted)),
                  ),
                const SizedBox(height: 6),
                StatusLabel('Ticket ${r.ticket.code} generado'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          QButton('Ver cola', onPressed: () => _backToQr(context)),
          const SizedBox(height: 10),
          QButton('Registrar otra llegada',
              style: QButtonStyle.outline,
              onPressed: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => RegisterArrivalPage(controller: controller)))),
        ],
      ),
    );
  }
}
