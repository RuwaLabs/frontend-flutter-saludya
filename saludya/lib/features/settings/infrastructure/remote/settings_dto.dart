import 'package:saludya/features/settings/domain/establishment_settings.dart';

class EstablishmentSettingsDto {
  final int maxCapacityPerSlot;
  final int? intervalDurationMinutes;
  final String bookingOrderScope;
  final int checkInToleranceMinutes;
  final int postCallToleranceMinutes;
  final int reassignmentResponseTimeoutMin;
  final String bookingCutoffTime;
  final int cancellationDeadlineHours;
  final bool attendanceQueueVisible;

  const EstablishmentSettingsDto({
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

  factory EstablishmentSettingsDto.fromJson(Map<String, dynamic> json) {
    return EstablishmentSettingsDto(
      maxCapacityPerSlot: json['maxCapacityPerSlot'] as int,
      intervalDurationMinutes: (json['intervalDurationMinutes'] as num?)
          ?.toInt(),
      bookingOrderScope: json['bookingOrderScope'] as String,
      checkInToleranceMinutes: json['checkInToleranceMinutes'] as int,
      postCallToleranceMinutes: json['postCallToleranceMinutes'] as int,
      reassignmentResponseTimeoutMin:
          json['reassignmentResponseTimeoutMin'] as int,
      bookingCutoffTime: _normalizeTime(json['bookingCutoffTime'] as String),
      cancellationDeadlineHours: json['cancellationDeadlineHours'] as int,
      attendanceQueueVisible: json['attendanceQueueVisible'] as bool,
    );
  }

  factory EstablishmentSettingsDto.fromDomain(EstablishmentSettings settings) {
    return EstablishmentSettingsDto(
      maxCapacityPerSlot: settings.maxCapacityPerSlot,
      intervalDurationMinutes: settings.intervalDurationMinutes,
      bookingOrderScope: _scopeToApi(settings.bookingOrderScope),
      checkInToleranceMinutes: settings.checkInToleranceMinutes,
      postCallToleranceMinutes: settings.postCallToleranceMinutes,
      reassignmentResponseTimeoutMin: settings.reassignmentResponseTimeoutMin,
      bookingCutoffTime: _timeToApi(settings.bookingCutoffTime),
      cancellationDeadlineHours: settings.cancellationDeadlineHours,
      attendanceQueueVisible: settings.attendanceQueueVisible,
    );
  }

  EstablishmentSettings toDomain() {
    return EstablishmentSettings(
      maxCapacityPerSlot: maxCapacityPerSlot,
      intervalDurationMinutes: intervalDurationMinutes,
      bookingOrderScope: _scopeFromApi(bookingOrderScope),
      checkInToleranceMinutes: checkInToleranceMinutes,
      postCallToleranceMinutes: postCallToleranceMinutes,
      reassignmentResponseTimeoutMin: reassignmentResponseTimeoutMin,
      bookingCutoffTime: _normalizeTime(bookingCutoffTime),
      cancellationDeadlineHours: cancellationDeadlineHours,
      attendanceQueueVisible: attendanceQueueVisible,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxCapacityPerSlot': maxCapacityPerSlot,
      if (intervalDurationMinutes != null)
        'intervalDurationMinutes': intervalDurationMinutes,
      'bookingOrderScope': bookingOrderScope,
      'checkInToleranceMinutes': checkInToleranceMinutes,
      'postCallToleranceMinutes': postCallToleranceMinutes,
      'reassignmentResponseTimeoutMin': reassignmentResponseTimeoutMin,
      'bookingCutoffTime': _timeToApi(bookingCutoffTime),
      'cancellationDeadlineHours': cancellationDeadlineHours,
      'attendanceQueueVisible': attendanceQueueVisible,
    };
  }

  static BookingOrderScope _scopeFromApi(String value) {
    switch (value) {
      case 'GLOBAL':
        return BookingOrderScope.global;
      case 'PER_SPECIALTY':
        return BookingOrderScope.perSpecialty;
      default:
        throw FormatException(
          'Valor de bookingOrderScope no reconocido: $value',
        );
    }
  }

  static String _scopeToApi(BookingOrderScope value) {
    switch (value) {
      case BookingOrderScope.global:
        return 'GLOBAL';
      case BookingOrderScope.perSpecialty:
        return 'PER_SPECIALTY';
    }
  }

  static String _normalizeTime(String value) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$')
        .firstMatch(value);

    if (match == null) {
      throw FormatException('Formato de hora no válido: $value');
    }

    return '${match.group(1)}:${match.group(2)}';
  }

  static String _timeToApi(String value) {
    final normalized = _normalizeTime(value);
    return '$normalized:00';
  }
}
