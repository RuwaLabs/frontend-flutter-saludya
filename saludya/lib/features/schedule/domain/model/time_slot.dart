class TimeSlot {
	final int id;
  final int doctorId;
  final DateTime date;
  final DateTime startHour;
  final DateTime endHour;
  final String room;
  final int maxCapacity;
  final int currentBookings;
  final String status;

  const new({
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
}
