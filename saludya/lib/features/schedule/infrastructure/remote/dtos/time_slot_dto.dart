class TimeSlotDto {
  final int id;
  final int doctorId;
  final DateTime date;
  final DateTime startHour;
  final DateTime endHour;
  final String room;
  final int maxCapacity;
  final int currentBookings;
  final String status;

  const TimeSlotDto({
    required this.id,
    required this.doctorId,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.room,
    required this.maxCapacity,
    required this.currentBookings,
    required this.status,
  });

  factory TimeSlotDto.fromJson(Map<String, dynamic> json) {
    final dateString = json['date'] as String;
    final startHourString = json['startHour'] as String;
    final endHourString = json['endHour'] as String;

    return TimeSlotDto(
      id: json['id'] as int,
      doctorId: json['doctorId'] as int,
      date: DateTime.parse(dateString),
      startHour: DateTime.parse('$dateString $startHourString'),
      endHour: DateTime.parse('$dateString $endHourString'),
      room: json['room'] as String? ?? '',
      maxCapacity: json['maxCapacity'] as int,
      currentBookings: json['currentBookings'] as int,
      status: json['status'] as String,
    );
  }
}
