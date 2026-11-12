class Appointment {
  final int id;
  final int timeSlotId;
  final int patientId;
  final int bookingOrder;
  final String bookingCode;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Appointment({
    required this.id,
    required this.timeSlotId,
    required this.patientId,
    required this.bookingOrder,
    required this.bookingCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });
}
