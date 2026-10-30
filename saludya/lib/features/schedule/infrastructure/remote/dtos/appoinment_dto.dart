class AppointmentDto {
  final int id;
  final int timeSlotId;
  final int patientId;
  final int bookingOrder;
  final String bookingCode;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AppointmentDto({
    required this.id,
    required this.timeSlotId,
    required this.patientId,
    required this.bookingOrder,
    required this.bookingCode,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AppointmentDto.fromJson(Map<String, dynamic> json) {
    return AppointmentDto(
      id: json['id'] as int,
      timeSlotId: json['timeSlotId'] as int,
      patientId: json['patientId'] as int,
      bookingOrder: json['bookingOrder'] as int,
      bookingCode: json['bookingCode'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}
