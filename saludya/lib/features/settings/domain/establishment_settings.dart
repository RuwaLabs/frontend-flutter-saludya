enum BookingOrderScope { global, perSpecialty }

class EstablishmentSettings {
  final int maxCapacityPerSlot;
  final int? intervalDurationMinutes;
  final BookingOrderScope bookingOrderScope;
  final int checkInToleranceMinutes;
  final int postCallToleranceMinutes;
  final int reassignmentResponseTimeoutMin;
  final String bookingCutoffTime;
  final int cancellationDeadlineHours;
  final bool attendanceQueueVisible;

  const EstablishmentSettings({
    required this.maxCapacityPerSlot,
    this.intervalDurationMinutes,
    required this.bookingOrderScope,
    required this.checkInToleranceMinutes,
    required this.postCallToleranceMinutes,
    required this.reassignmentResponseTimeoutMin,
    required this.bookingCutoffTime,
    required this.cancellationDeadlineHours,
    required this.attendanceQueueVisible,
  });

  List<String> validate() {
    final errors = <String>[];

    if (maxCapacityPerSlot <= 0) {
      errors.add('La capacidad máxima debe ser mayor que cero.');
    }

    if (intervalDurationMinutes != null && intervalDurationMinutes! <= 0) {
      errors.add('La duración del intervalo debe ser mayor que cero.');
    }

    if (checkInToleranceMinutes < 0) {
      errors.add('La tolerancia de llegada no puede ser negativa.');
    }

    if (postCallToleranceMinutes < 0) {
      errors.add('La tolerancia posterior a la llamada no puede ser negativa.');
    }

    if (reassignmentResponseTimeoutMin < 0) {
      errors.add(
        'El tiempo de respuesta de reasignación no puede ser negativo.',
      );
    }

    if (cancellationDeadlineHours < 0) {
      errors.add('El plazo de cancelación no puede ser negativo.');
    }

    final validTime = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

    if (!validTime.hasMatch(bookingCutoffTime)) {
      errors.add('La hora límite debe tener el formato HH:mm.');
    }

    return errors;
  }

  EstablishmentSettings copyWith({
    int? maxCapacityPerSlot,
    int? intervalDurationMinutes,
    BookingOrderScope? bookingOrderScope,
    int? checkInToleranceMinutes,
    int? postCallToleranceMinutes,
    int? reassignmentResponseTimeoutMin,
    String? bookingCutoffTime,
    int? cancellationDeadlineHours,
    bool? attendanceQueueVisible,
  }) {
    return EstablishmentSettings(
      maxCapacityPerSlot: maxCapacityPerSlot ?? this.maxCapacityPerSlot,
      intervalDurationMinutes:
          intervalDurationMinutes ?? this.intervalDurationMinutes,
      bookingOrderScope: bookingOrderScope ?? this.bookingOrderScope,
      checkInToleranceMinutes:
          checkInToleranceMinutes ?? this.checkInToleranceMinutes,
      postCallToleranceMinutes:
          postCallToleranceMinutes ?? this.postCallToleranceMinutes,
      reassignmentResponseTimeoutMin:
          reassignmentResponseTimeoutMin ?? this.reassignmentResponseTimeoutMin,
      bookingCutoffTime: bookingCutoffTime ?? this.bookingCutoffTime,
      cancellationDeadlineHours:
          cancellationDeadlineHours ?? this.cancellationDeadlineHours,
      attendanceQueueVisible:
          attendanceQueueVisible ?? this.attendanceQueueVisible,
    );
  }
}
