import 'dart:convert';

import 'package:http/http.dart' as http;

import '../dtos/appoinment_dto.dart';
import '../dtos/doctor_dto.dart';
import '../dtos/speciality_dto.dart';
import '../dtos/time_slot_dto.dart';

class SaludYaApi {
  SaludYaApi({
    http.Client? client,
    this.baseUrl = 'http://3.129.217.49:8080/api/v1',
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final http.Client _client;
  final bool _ownsClient;
  final String baseUrl;

  void dispose() {
    if (_ownsClient) _client.close();
  }

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  Future<dynamic> _request(
    String method,
    String path, {
    Map<String, String>? query,
    Map<String, dynamic>? body,
  }) async {
    final uri = _uri(path, query);
    final headers = {
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
    };
    final http.Response response;
    try {
      response = await switch (method) {
        'GET' => _client.get(uri, headers: headers),
        'PUT' => _client.put(uri, headers: headers, body: jsonEncode(body)),
        'DELETE' => _client.delete(uri, headers: headers),
        _ => throw ArgumentError.value(method),
      }.timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const SaludYaApiException('No se pudo conectar con el servidor.');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? message;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        if (decoded is Map) message = decoded['message']?.toString();
      } catch (_) {
        /* Error no JSON. */
      }
      throw SaludYaApiException(
        response.statusCode == 401
            ? 'El backend exige autenticación (401) para esta consulta.'
            : message ?? 'Error del servidor (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<SpecialityDto>> getSpecialities() async => [
    for (final item in await _request('GET', '/specialties') as List)
      SpecialityDto.fromJson(item as Map<String, dynamic>),
  ];

  Future<SpecialityDto?> getSpecialityById(int id) async {
    final item = await _request('GET', '/specialties/$id');
    return item == null
        ? null
        : SpecialityDto.fromJson(item as Map<String, dynamic>);
  }

  Future<List<DoctorDto>> getDoctorsBySpecialty(int specialtyId) async => [
    for (final item in await _request(
      'GET',
      '/doctors',
      query: {'specialtyId': '$specialtyId'},
    ) as List)
      DoctorDto.fromJson(item as Map<String, dynamic>),
  ];

  Future<DoctorDto?> getDoctorById(int id) async {
    final item = await _request('GET', '/doctors/$id');
    return item == null
        ? null
        : DoctorDto.fromJson(item as Map<String, dynamic>);
  }

  Future<List<TimeSlotDto>> getTimeSlotsByDoctorAndDate(
    int doctorId,
    DateTime date,
  ) async => [
    for (final item in await _request(
      'GET',
      '/time-slots',
      query: {'doctorId': '$doctorId', 'date': _dateOnly(date)},
    ) as List)
      TimeSlotDto.fromJson(item as Map<String, dynamic>),
  ];

  Future<List<TimeSlotDto>> getAvailableTimeSlots(
    int specialtyId,
    DateTime date,
  ) async => [
    for (final item in await _request(
      'GET',
      '/time-slots/available',
      query: {'specialtyId': '$specialtyId', 'date': _dateOnly(date)},
    ) as List)
      TimeSlotDto.fromJson(item as Map<String, dynamic>),
  ];

  Future<void> updateTimeSlot(TimeSlotDto slot) async {
    await _request(
      'PUT',
      '/time-slots/${slot.id}',
      body: {
        'doctorId': slot.doctorId,
        'startHour': _timeOnly(slot.startHour),
        'endHour': _timeOnly(slot.endHour),
        'status': slot.status,
      },
    );
  }

  Future<List<AppointmentDto>> getAppointments() async {
    final items = await _request('GET', '/appointments') as List;
    return [
      for (final item in items)
        AppointmentDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<AppointmentDto?> getAppointmentById(int id) async {
    final item = await _request('GET', '/appointments/$id');
    return item == null
        ? null
        : AppointmentDto.fromJson(item as Map<String, dynamic>);
  }

  Future<List<AppointmentDto>> getAppointmentsByPatient(int patientId) async {
    final items =
        await _request('GET', '/appointments/patient/$patientId') as List;
    return [
      for (final item in items)
        AppointmentDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  Future<void> cancelAppointment(int id) async {
    await _request('DELETE', '/appointments/$id');
  }

  String _dateOnly(DateTime value) =>
      '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String _timeOnly(DateTime value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';
}

class SaludYaApiException implements Exception {
  const SaludYaApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => message;
}
