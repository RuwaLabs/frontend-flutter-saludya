import 'arrival_result.dart';
import 'qr_ticket.dart';

/// Una cola de `attendance_queues` (un bloque/time_slot del día) con sus entradas.
class QrSnapshot {
  const QrSnapshot({
    required this.date,
    required this.block,
    required this.tickets,
  });

  final DateTime date;
  final String block; // "08:00–10:00 · Dr. Juan Ramos"
  final List<QrTicket> tickets;
}

abstract class QrRepository {
  Future<QrSnapshot> getQr();
  Future<QrTicket> callNext();
  Future<QrTicket> startAttention(String ticketId);
  Future<QrTicket> markAbsent(String ticketId);
  Future<QrTicket> finishAttention(String ticketId);
  Future<ArrivalResult> registerArrival(String reservationCode);
}

/// Error de negocio (reserva inexistente, plazo no vencido, etc.).
class QrException implements Exception {
  const QrException(this.message, {this.code});
  final String message;
  final String? code;
  @override
  String toString() => message;
}
