import 'package:flutter/material.dart';

import '../application/qr_controller.dart';
import '../domain/qr_ticket.dart';
import 'components/qr_ui.dart';
import 'manage_turn_page.dart';
import 'register_arrival_page.dart';

const _months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];

/// P11 · Cola presencial  /  P22 · Cola vacía
class QrPage extends StatefulWidget {
  const QrPage({super.key, required this.controller});
  final QrController controller;

  @override
  State<QrPage> createState() => _QrPageState();
}

class _QrPageState extends State<QrPage> {
  QrController get c => widget.controller;

  @override
  void initState() {
    super.initState();
    c.load();
  }

  void _showError() {
    if (c.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(c.error!)));
    }
  }

  Future<void> _openTurn(QrTicket t) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (_) => ManageTurnPage(controller: c, ticketId: t.id)));
    c.load();
  }

  Future<void> _callNext() async {
    final t = await c.callNext();
    if (!mounted) return;
    t == null ? _showError() : _openTurn(t);
  }

  Future<void> _finish(QrTicket t) async {
    await c.finishAttention(t.id);
    if (mounted) _showError();
  }

  void _registerArrival() => Navigator.push(
      context, MaterialPageRoute(builder: (_) => RegisterArrivalPage(controller: c)));

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) {
        final snap = c.snapshot;
        if (c.loading && snap == null) {
          return const QrScaffold(
              title: 'Cola de atención',
              child: Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator(color: QColors.primary))));
        }
        if (snap == null) {
          return QrScaffold(
            title: 'Cola de atención',
            child: Column(children: [
              Hint(c.error ?? 'No se pudo cargar la cola.'),
              QButton('Reintentar', onPressed: c.load),
            ]),
          );
        }

        final tickets = c.activeTickets..sort((a, b) => a.position.compareTo(b.position));
        if (tickets.isEmpty) return _empty();

        final current = c.inAttention;
        final called = c.called;
        return QrScaffold(
          title: 'Cola de atención',
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hoy · ${snap.date.day} ${_months[snap.date.month - 1]} · ${snap.block}',
                    style: const TextStyle(fontSize: 12, color: QColors.muted)),
                const SizedBox(height: 12),
                for (final t in tickets)
                  TicketCard(
                    ticket: t,
                    onTap: t.status == TicketStatus.called ? () => _openTurn(t) : null,
                  ),
                const SizedBox(height: 4),
                if (current != null) ...[
                  QButton('Terminar atención de N.º ${current.position}',
                      loading: c.busy, onPressed: () => _finish(current)),
                  const SizedBox(height: 10),
                ],
                if (called != null)
                  QButton('Gestionar turno de N.º ${called.position}',
                      style: QButtonStyle.outline, onPressed: () => _openTurn(called))
                else
                  QButton('Llamar al siguiente',
                      style: current != null ? QButtonStyle.outline : QButtonStyle.primary,
                      // Se puede llamar mientras otro está en atención (como en P11),
                      // pero solo si hay alguien esperando.
                      onPressed: c.hasWaiting && !c.busy ? _callNext : null),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _registerArrival,
                  icon: const Icon(Icons.qr_code_scanner, color: QColors.primary, size: 18),
                  label: const Text('Registrar llegada',
                      style: TextStyle(color: QColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
        );
      },
    );
  }

  Widget _empty() => QrScaffold(
        title: 'Cola de atención',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Icon(Icons.local_hospital_outlined, color: QColors.primary, size: 36),
            const SizedBox(height: 14),
            const Text('Sin pacientes en espera',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: QColors.text)),
            const Hint('Aún no hay llegadas registradas para este bloque.'),
            const SizedBox(height: 4),
            QButton('Registrar llegada', onPressed: _registerArrival),
          ],
        ),
      );
}
