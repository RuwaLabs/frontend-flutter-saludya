import 'package:flutter/material.dart';

import '../../domain/qr_ticket.dart';

/// Tokens tomados del diseño (P11–P22).
abstract class QColors {
  static const primary = Color(0xFF0E8A6A);
  static const primaryDark = Color(0xFF0A6B52);
  static const bg = Color(0xFFF1F7F4);
  static const card = Colors.white;
  static const border = Color(0xFFDDE8E3);
  static const text = Color(0xFF1B2421);
  static const muted = Color(0xFF6B7A75);
  static const danger = Color(0xFFC0392B);
  static const disabled = Color(0xFFDCE5E1);
  static const scannerBg = Color(0xFF1F2A28);
}

String hhmm(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String mmss(Duration d) {
  if (d.isNegative) return '00:00';
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

/// Estructura común: fondo verde claro + encabezado "<  Título".
class QrScaffold extends StatelessWidget {
  const QrScaffold({super.key, required this.title, required this.child, this.onBack});
  final String title;
  final Widget child;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: QColors.primary, size: 28),
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  ),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600, color: QColors.text)),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QCard extends StatelessWidget {
  const QCard({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: QColors.border),
        ),
        child: child,
      );
}

enum QButtonStyle { primary, outline, danger }

class QButton extends StatelessWidget {
  const QButton(this.label,
      {super.key, required this.onPressed, this.style = QButtonStyle.primary, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final QButtonStyle style;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (bg, fg, border) = switch (style) {
      QButtonStyle.primary => (QColors.primary, Colors.white, QColors.primary),
      QButtonStyle.danger => (QColors.danger, Colors.white, QColors.danger),
      QButtonStyle.outline => (Colors.white, QColors.primary, QColors.primary),
    };
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: TextButton(
        onPressed: enabled ? onPressed : null,
        style: TextButton.styleFrom(
          backgroundColor: enabled ? bg : QColors.disabled,
          foregroundColor: enabled ? fg : QColors.muted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: enabled ? border : QColors.disabled),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
            : Text(label),
      ),
    );
  }
}

class Hint extends StatelessWidget {
  const Hint(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text, style: const TextStyle(fontSize: 12, color: QColors.muted, height: 1.4)),
      );
}

class StatusLabel extends StatelessWidget {
  const StatusLabel(this.text, {super.key, this.color = QColors.primary});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color));
}

String statusText(TicketStatus s) => switch (s) {
      TicketStatus.waiting => 'En espera',
      TicketStatus.called => 'Llamado',
      TicketStatus.inAttention => 'En atención',
      TicketStatus.absent => 'Ausente',
      TicketStatus.attended => 'Atendido',
    };

/// Tarjeta de la lista (P11).
class TicketCard extends StatelessWidget {
  const TicketCard({super.key, required this.ticket, this.onTap});
  final QrTicket ticket;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: QCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('N.º ${ticket.position} · ${ticket.code}',
                    style: const TextStyle(fontWeight: FontWeight.w700, color: QColors.text)),
                const SizedBox(height: 6),
                Text('${ticket.patientName} · llegada ${hhmm(ticket.arrivedAt)}',
                    style: const TextStyle(fontSize: 12, color: QColors.muted)),
                const SizedBox(height: 6),
                StatusLabel(statusText(ticket.status)),
              ],
            ),
          ),
        ),
      );
}
