import '../../domain/qr_ticket.dart';

/// DTOs con los nombres exactos de los Resource de backend-saludya.

DateTime? parseInstant(dynamic v) {
  if (v == null) return null;
  if (v is num) return DateTime.fromMillisecondsSinceEpoch((v * 1000).round(), isUtc: true).toLocal();
  return DateTime.parse(v as String).toLocal();
}

String hhmmFromLocalTime(dynamic v) {
  if (v is String) return v.length >= 5 ? v.substring(0, 5) : v;
  if (v is List && v.length >= 2) {
    return '${v[0].toString().padLeft(2, '0')}:${v[1].toString().padLeft(2, '0')}';
  }
  return '--:--';
}

/// QueueEntryResource { id, attendanceQueueId, checkInId, position, status, calledAt, attendedAt }
class QueueEntryDto {
  QueueEntryDto.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(),
        attendanceQueueId = (j['attendanceQueueId'] as num).toInt(),
        checkInId = (j['checkInId'] as num).toInt(),
        position = (j['position'] as num).toInt(),
        status = j['status'] as String,
        calledAt = parseInstant(j['calledAt']);

  final int id;
  final int attendanceQueueId;
  final int checkInId;
  final int position;
  final String status; // WAITING | CALLED | IN_ATTENTION | ATTENDED | ABSENT
  final DateTime? calledAt;

  TicketStatus get ticketStatus => switch (status) {
        'CALLED' => TicketStatus.called,
        'IN_ATTENTION' => TicketStatus.inAttention,
        'ATTENDED' => TicketStatus.attended,
        'ABSENT' => TicketStatus.absent,
        _ => TicketStatus.waiting,
      };
}

/// CheckInResource { id, appointmentId, bookingCode, turnCode, specialtyName,
///                   doctorName, room, scheduledAt, status, checkedInAt }
class CheckInDto {
  CheckInDto.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(),
        appointmentId = (j['appointmentId'] as num).toInt(),
        bookingCode = j['bookingCode'] as String? ?? '',
        specialtyName = j['specialtyName'] as String? ?? '',
        doctorName = j['doctorName'] as String? ?? '',
        room = j['room'] as String? ?? '',
        checkedInAt = parseInstant(j['checkedInAt']) ?? DateTime.now();

  final int id;
  final int appointmentId;
  final String bookingCode;
  final String specialtyName;
  final String doctorName;
  final String room;
  final DateTime checkedInAt;
}

/// CheckInResultResource { checkInId, appointmentId, queueEntryId, position, totalInQueue, status }
class CheckInResultDto {
  CheckInResultDto.fromJson(Map<String, dynamic> j)
      : checkInId = (j['checkInId'] as num).toInt(),
        appointmentId = (j['appointmentId'] as num).toInt(),
        queueEntryId = (j['queueEntryId'] as num).toInt();

  final int checkInId;
  final int appointmentId;
  final int queueEntryId;
}

/// AppointmentResource { id, timeSlotId, patientId, bookingOrder, bookingCode, status, ... }
class AppointmentDto {
  AppointmentDto.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(),
        timeSlotId = (j['timeSlotId'] as num).toInt(),
        patientId = (j['patientId'] as num).toInt(),
        status = j['status'] as String? ?? '';

  final int id;
  final int timeSlotId;
  final int patientId;
  final String status;
}

/// TimeSlotResource { id, doctorId, date, startHour, endHour, room, ... }
class TimeSlotDto {
  TimeSlotDto.fromJson(Map<String, dynamic> j)
      : id = (j['id'] as num).toInt(),
        start = hhmmFromLocalTime(j['startHour']),
        end = hhmmFromLocalTime(j['endHour']),
        room = j['room'] as String? ?? '',
        status = j['status'] as String? ?? '';

  final int id;
  final String start; // HH:mm
  final String end;
  final String room;
  final String status;
}

/// PatientResource { id, userId, dni, name, lastname, ... }
String patientFullName(Map<String, dynamic> j) =>
    '${j['name'] ?? ''} ${j['lastname'] ?? ''}'.trim();

/// Código de turno igual al del backend: T-001.
String turnCode(int position) => 'T-${position.toString().padLeft(3, '0')}';
