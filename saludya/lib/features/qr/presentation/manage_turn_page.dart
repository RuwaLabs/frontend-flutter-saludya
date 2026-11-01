import 'dart:async';

import 'package:flutter/material.dart';

import '../application/qr_controller.dart';
import '../domain/qr_ticket.dart';
import 'components/qr_ui.dart';

/// P12 · Paciente llamado  →  P13 · Plazo de llamada vencido.
/// La misma pantalla cambia sola cuando vence el plazo (cuenta regresiva).
class ManageTurnPage extends StatefulWidget {
  const ManageTurnPage({super.key, required this.controller, required this.ticketId});
  final QrController controller;
  final String ticketId;

  @override
  State<ManageTurnPage> createState() => _ManageTurnPageState();
}

class _ManageTurnPageState extends State<ManageTurnPage> {
  Timer? _timer;
  QrController get c => widget.controller;

  QrTicket? get ticket =>
      c.snapshot?.tickets.where((t) => t.id == widget.ticketId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<QrTicket?> Function() action) async {
    final t = await action();
    if (!mounted) return;
    if (t == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.error ?? 'Error')));
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final t = ticket;
        if (t == null) {
          return const QrScaffold(title: 'Gestionar turno', child: Hint('Turno no encontrado.'));
        }
        final expired = t.deadlineExpired;
        return QrScaffold(
          title: expired ? 'Gestionar ausencia' : 'Gestionar turno',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${t.code} · ${t.patientName}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: QColors.text)),
                    const SizedBox(height: 8),
                    ..._details(t, expired).map((l) => Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(l,
                              style: const TextStyle(fontSize: 12, color: QColors.muted)),
                        )),
                    const SizedBox(height: 6),
                    StatusLabel(expired ? 'Sin ingreso al consultorio' : 'Llamado'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!expired) ...[
                Hint('Quedan ${mmss(t.remaining)} para cumplir el plazo de llegada.'),
                QButton('Iniciar atención',
                    loading: c.busy, onPressed: () => _run(() => c.startAttention(t.id))),
                const SizedBox(height: 10),
                const QButton('Marcar ausente', onPressed: null), // deshabilitado
                const Hint('Disponible al terminar el plazo posterior a la llamada.'),
              ] else ...[
                QButton('Marcar ausente',
                    style: QButtonStyle.danger,
                    loading: c.busy,
                    onPressed: () => _run(() => c.markAbsent(t.id))),
                const SizedBox(height: 10),
                QButton('Iniciar atención',
                    style: QButtonStyle.outline,
                    onPressed: c.busy ? null : () => _run(() => c.startAttention(t.id))),
                const Hint('Si ya se inició la atención, no se puede marcar ausencia.'),
              ],
            ],
          ),
        );
      },
    );
  }

  List<String> _details(QrTicket t, bool expired) {
    final called = t.calledAt != null ? hhmm(t.calledAt!) : '--:--';
    if (expired) {
      return [
        'Llamado: $called',
        'Plazo cumplido: ${t.arrivalDeadline != null ? hhmm(t.arrivalDeadline!) : '--:--'}',
      ];
    }
    return [
      '${t.specialty} · ${t.doctor}',
      'Llamada registrada: $called',
      'Plazo para acudir: ${t.deadlineMinutes} minutos',
    ];
  }
}
