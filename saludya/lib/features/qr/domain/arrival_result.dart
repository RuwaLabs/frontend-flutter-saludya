import 'qr_ticket.dart';

/// Resultado de registrar una llegada (P15 · Llegada confirmada).
/// En la BD: se crea un `check_ins` y un `queue_entries`.
class ArrivalResult {
  const ArrivalResult({
    required this.reservationCode,
    required this.patientName,
    required this.arrivedAt,
    required this.specialty,
    required this.doctor,
    this.room = '',
    required this.ticket,
  });

  final String reservationCode; // bookingCode, ej. SAL-1A2B3C4D5E
  final String patientName;
  final DateTime arrivedAt;
  final String specialty;
  final String doctor;
  final String room; // time_slot.room
  final QrTicket ticket;
}
