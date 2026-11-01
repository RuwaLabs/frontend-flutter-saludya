import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../domain/home_models.dart';
import '../domain/home_repository.dart';

class HomeApiRepository implements HomeRepository {
  HomeApiRepository({
    required this.client,
    required this.tokenProvider,
    String baseUrl = const String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://3.129.217.49:8080/api/v1',
    ),
  }) : baseUri = Uri.parse('${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/');
  final http.Client client;
  final Future<String?> Function() tokenProvider;
  final Uri baseUri;

  Future<Object?> _get(
    String path, {
    Map<String, String>? query,
    bool allowMissing = false,
  }) async {
    final token = await tokenProvider();
    if (token == null || token.trim().isEmpty) {
      throw const HomeFailure(
        'Inicia sesión con tu cuenta de personal para continuar.',
        sessionExpired: true,
      );
    }
    try {
      final response = await client
          .get(
            baseUri.resolve(path).replace(queryParameters: query),
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 401) {
        throw const HomeFailure(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
          sessionExpired: true,
        );
      }
      if (response.statusCode == 403) {
        throw const HomeFailure(
          'Tu cuenta no tiene permiso para consultar esta información.',
        );
      }
      if (allowMissing && response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw const HomeFailure(
          'No pudimos cargar la información. Inténtalo nuevamente.',
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on TimeoutException {
      throw const HomeFailure(
        'La conexión está tardando demasiado. Vuelve a intentar.',
      );
    } on http.ClientException {
      throw const HomeFailure(
        'No pudimos conectarnos. Revisa tu conexión a internet.',
      );
    } on FormatException {
      throw const HomeFailure(
        'La información recibida no tiene el formato esperado.',
      );
    }
  }

  String _date(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<HomeBooking>> _bookings(DateTime date, {int? slotId}) async {
    final raw = await _get(
      'appointments',
      query: {'date': _date(date), if (slotId != null) 'timeSlotId': '$slotId'},
    );
    if (raw is! List) {
      throw const HomeFailure('No pudimos interpretar las reservas.');
    }
    final cache = <String, Future<Map<String, dynamic>>>{};
    Future<Map<String, dynamic>> resource(String path) =>
        cache.putIfAbsent(path, () async {
          final value = await _get(path);
          if (value is! Map<String, dynamic>) {
            throw const HomeFailure(
              'No pudimos interpretar los datos de la reserva.',
            );
          }
          return value;
        });
    final result = <HomeBooking>[];
    // Keep requests bounded; shared patients, slots and specialties are fetched once.
    try {
      for (final item in raw.cast<Map<String, dynamic>>()) {
        final slot = await resource('time-slots/${item['timeSlotId']}');
        final slotDate = DateTime.parse(slot['date'] as String);
        if (_date(slotDate) != _date(date) ||
            (slotId != null && slot['id'] != slotId)) {
          continue;
        }
        final doctor = await resource('doctors/${slot['doctorId']}');
        final specialty = await resource(
          'specialties/${doctor['specialtyId']}',
        );
        final patient = await resource('patients/${item['patientId']}');
        final birth = DateTime.tryParse(patient['birthDate']?.toString() ?? '');
        final adultDate = birth == null
            ? null
            : DateTime(birth.year + 18, birth.month, birth.day);
        result.add(
          HomeBooking(
            id: (item['id'] as num).toInt(),
            timeSlotId: (slot['id'] as num).toInt(),
            patientName: '${patient['name'] ?? ''} ${patient['lastname'] ?? ''}'
                .trim(),
            specialty: specialty['name'] as String,
            code: item['bookingCode'] as String,
            date: slotDate,
            startHour: (slot['startHour'] as String).substring(0, 5),
            endHour: (slot['endHour'] as String).substring(0, 5),
            status: item['status'] as String,
            updatedAt: DateTime.parse(item['updatedAt'] as String).toLocal(),
            isMinor: adultDate != null && date.isBefore(adultDate),
          ),
        );
      }
    } on FormatException {
      throw const HomeFailure(
        'No pudimos interpretar las fechas de las reservas.',
      );
    } on TypeError {
      throw const HomeFailure(
        'La información de las reservas está incompleta.',
      );
    } on RangeError {
      throw const HomeFailure(
        'No pudimos interpretar los horarios de las reservas.',
      );
    }
    result.sort((a, b) => a.startHour.compareTo(b.startHour));
    return result;
  }

  @override
  Future<HomeSummary> getSummary(DateTime date) async {
    final profile = await _get('user-accounts/me');
    if (profile is! Map<String, dynamic>) {
      throw const HomeFailure('No pudimos consultar tu perfil.');
    }
    if (!{'ADMISSION_STAFF', 'SUPER_ADMIN'}.contains(profile['role'])) {
      throw const HomeFailure(
        'Esta sección está disponible para el personal de admisión.',
      );
    }
    return HomeSummary(
      date: date,
      bookings: await _bookings(date),
      staffName: profile['name'] as String?,
    );
  }

  @override
  Future<List<HomeBooking>> getPatients(DateTime date, int timeSlotId) async {
    final bookings = await _bookings(date, slotId: timeSlotId);
    final queue = await _get(
      'attendance-queues',
      query: {'timeSlotId': '$timeSlotId', 'date': _date(date)},
      allowMissing: true,
    );
    final entries = queue is Map
        ? await _get('attendance-queues/${queue['id']}/entries')
        : null;
    if (entries != null && entries is! List) {
      throw const HomeFailure(
        'No pudimos interpretar los estados de atención.',
      );
    }
    final statuses = <Object?, Object?>{
      if (entries is List)
        for (final entry in entries.cast<Map<String, dynamic>>())
          entry['checkInId']: entry['status'],
    };
    final result = <HomeBooking>[];
    for (final booking in bookings.where(
      (b) => !b.isCancelled && b.status != 'EXPIRED',
    )) {
      final ticket = await _get(
        'check-ins/appointment/${booking.id}',
        allowMissing: true,
      );
      final status = ticket is Map ? statuses[ticket['id']] : null;
      final arrival = switch (status) {
        'IN_SERVICE' || 'IN_ATTENTION' => ArrivalStatus.inService,
        'ATTENDED' || 'COMPLETED' => ArrivalStatus.attended,
        'ABSENT' => ArrivalStatus.absent,
        'EXPIRED' => ArrivalStatus.expired,
        null => switch (booking.status) {
          'ATTENDED' => ArrivalStatus.attended,
          'ABSENT' => ArrivalStatus.absent,
          _ =>
            ticket is Map && ticket['status'] == 'VALID'
                ? ArrivalStatus.registered
                : ticket is Map && ticket['status'] == 'EXPIRED'
                ? ArrivalStatus.expired
                : ArrivalStatus.pending,
        },
        _ => ArrivalStatus.registered,
      };
      result.add(booking.withArrival(arrival));
    }
    return result;
  }
}
