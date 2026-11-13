class DashboardMetrics {
  final int scheduled;
  final int pending;
  final int cancelled;
  final int attended;
  final int absent;

  const DashboardMetrics({
    required this.scheduled,
    required this.pending,
    required this.cancelled,
    required this.attended,
    required this.absent,
  });
}

class Specialty {
  final int id;
  final String name;
  final String description;

  const Specialty({
    required this.id,
    required this.name,
    required this.description,
  });
}

class Doctor {
  final int id;
  final int specialtyId;
  final String name;
  final String lastname;

  const Doctor({
    required this.id,
    required this.specialtyId,
    required this.name,
    required this.lastname,
  });

  String get fullName => '$name $lastname'.trim();
}

class TimeBlock {
  final int id;
  final int doctorId;
  final DateTime date;
  final String startHour;
  final String endHour;
  final String room;
  final int maxCapacity;
  final int currentBookings;
  final String status;

  const TimeBlock({
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

  int get availableCapacity =>
      (maxCapacity - currentBookings).clamp(0, maxCapacity).toInt();
}

class BlockDraft {
  final int doctorId;
  final DateTime date;
  final String startHour;
  final String endHour;
  final String room;
  final int maxCapacity;

  const BlockDraft({
    required this.doctorId,
    required this.date,
    required this.startHour,
    required this.endHour,
    required this.room,
    required this.maxCapacity,
  });
}

class BlockChanges {
  final int doctorId;
  final String startHour;
  final String endHour;
  final String status;
  final int maxCapacity;

  const BlockChanges({
    required this.doctorId,
    required this.startHour,
    required this.endHour,
    required this.status,
    required this.maxCapacity,
  });
}

class BookedPatient {
  final int appointmentId;
  final int patientId;
  final int timeSlotId;
  final String bookingCode;
  final int bookingOrder;
  final String status;
  final String patientName;
  final String? slotSummary;

  const BookedPatient({
    required this.appointmentId,
    required this.patientId,
    required this.timeSlotId,
    required this.bookingCode,
    required this.bookingOrder,
    required this.status,
    required this.patientName,
    this.slotSummary,
  });
}

class AttendanceQueue {
  final int id;
  final int timeSlotId;
  final DateTime date;
  final String status;

  const AttendanceQueue({
    required this.id,
    required this.timeSlotId,
    required this.date,
    required this.status,
  });
}

class QueueEntry {
  final int id;
  final int attendanceQueueId;
  final int checkInId;
  final int appointmentId;
  final int patientId;
  final String bookingCode;
  final String patientName;
  final int position;
  final String status;
  final DateTime? calledAt;
  final DateTime? attendedAt;

  const QueueEntry({
    required this.id,
    required this.attendanceQueueId,
    required this.checkInId,
    required this.appointmentId,
    required this.patientId,
    required this.bookingCode,
    required this.patientName,
    required this.position,
    required this.status,
    required this.calledAt,
    required this.attendedAt,
  });
}

class ArrivalReceipt {
  final int checkInId;
  final int appointmentId;
  final int queueEntryId;
  final int position;
  final int totalInQueue;

  const ArrivalReceipt({
    required this.checkInId,
    required this.appointmentId,
    required this.queueEntryId,
    required this.position,
    required this.totalInQueue,
  });
}

class ApiFailure implements Exception {
  final int statusCode;
  final String message;

  const ApiFailure(this.statusCode, this.message);

  @override
  String toString() => message;
}
