enum ArrivalStatus { pending, registered, inService, attended, absent, expired }

class HomeBooking {
  const HomeBooking({required this.id, required this.timeSlotId,
    required this.patientName, required this.specialty, required this.code,
    required this.date, required this.startHour, required this.endHour,
    required this.status, required this.updatedAt, this.isMinor = false,
    this.arrival = ArrivalStatus.pending});
  final int id;
  final int timeSlotId;
  final String patientName;
  final String specialty;
  final String code;
  final DateTime date;
  final String startHour;
  final String endHour;
  final String status;
  final DateTime updatedAt;
  final bool isMinor;
  final ArrivalStatus arrival;
  bool get isCancelled => status == 'CANCELLED';
  bool get isPending => status == 'RESERVED' || status == 'CONFIRMED';
  HomeBooking withArrival(ArrivalStatus value) => HomeBooking(
    id: id, timeSlotId: timeSlotId, patientName: patientName,
    specialty: specialty, code: code, date: date, startHour: startHour,
    endHour: endHour, status: status, updatedAt: updatedAt,
    isMinor: isMinor, arrival: value);
}

class HomeSummary {
  HomeSummary({required this.date, required List<HomeBooking> bookings})
      : bookings = List.unmodifiable(bookings);
  final DateTime date;
  final List<HomeBooking> bookings;
  List<HomeBooking> get pending => bookings.where((b) => b.isPending).toList();
  List<HomeBooking> get cancelled => bookings.where((b) => b.isCancelled).toList();
  List<HomeSlot> get slots {
    final groups = <int, List<HomeBooking>>{};
    for (final booking in bookings.where((b) => !b.isCancelled && b.status != 'EXPIRED')) {
      groups.putIfAbsent(booking.timeSlotId, () => []).add(booking);
    }
    return groups.entries.map((e) => HomeSlot(e.key, e.value.first, e.value.length)).toList()
      ..sort((a, b) => a.booking.startHour.compareTo(b.booking.startHour));
  }
}

class HomeSlot {
  const HomeSlot(this.id, this.booking, this.patientCount);
  final int id;
  final HomeBooking booking;
  final int patientCount;
}

class HomeFailure implements Exception {
  const HomeFailure(this.message, {this.sessionExpired = false});
  final String message;
  final bool sessionExpired;
  @override
  String toString() => message;
}
