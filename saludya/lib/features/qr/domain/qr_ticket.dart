/// Estados de `queue_entries.status` en la BD.
enum TicketStatus { waiting, called, inAttention, attended, absent }

/// Una fila de `queue_entries` con los datos que muestra la app.
class QrTicket {
  const QrTicket({
    required this.id,
    required this.position,
    required this.code,
    required this.patientName,
    required this.arrivedAt,
    required this.status,
    required this.specialty,
    required this.doctor,
    this.calledAt,
    this.arrivalDeadline,
  });

  final String id; // queue_entries.id
  final int position; // queue_entries.position -> N.º 1, N.º 2...
  final String code; // T-001 (mismo formato que el backend)
  final String patientName; // patients.name + lastname
  final DateTime arrivedAt; // check_ins.checked_in_at
  final TicketStatus status; // queue_entries.status
  final String specialty; // specialties.name
  final String doctor; // doctors.name + lastname
  final DateTime? calledAt; // queue_entries.called_at
  final DateTime? arrivalDeadline; // called_at + post_call_tolerance_minutes

  bool get isActive =>
      status == TicketStatus.waiting ||
      status == TicketStatus.called ||
      status == TicketStatus.inAttention;

  /// El plazo para acudir ya venció (habilita "Marcar ausente").
  bool get deadlineExpired =>
      arrivalDeadline != null && DateTime.now().isAfter(arrivalDeadline!);

  Duration get remaining => arrivalDeadline == null
      ? Duration.zero
      : arrivalDeadline!.difference(DateTime.now());

  int get deadlineMinutes => (calledAt == null || arrivalDeadline == null)
      ? 0
      : arrivalDeadline!.difference(calledAt!).inMinutes;
}
