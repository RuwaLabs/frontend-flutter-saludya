import 'dart:convert';

import 'package:http/http.dart' as http;

/// Error HTTP del backend SaludYa ({ code, message, details }).
class QrApiException implements Exception {
  const QrApiException({required this.statusCode, this.code, required this.message});
  final int statusCode;
  final String? code;
  final String message;
  @override
  String toString() => message;
}

/// Cliente del bounded context "Arrival & QR Check-in" (+ las lecturas que
/// necesita de Appointments, IAM y Configuration). Mismo estilo que SettingsApi.
///
/// Endpoints (backend-saludya, /api/v1):
///   GET  /appointments?date=            GET  /time-slots/{id}
///   GET  /attendance-queues?timeSlotId=&date=
///   GET  /attendance-queues/{id}/entries
///   POST /attendance-queues/{id}/call-next
///   GET  /queue-entries/{id}            POST /queue-entries/{id}/start|absent|finish
///   POST /check-ins/qr {qrToken}        POST /check-ins/code {bookingCode}
///   GET  /check-ins/{id}                GET  /appointments/{id}
///   GET  /patients/{id}                 GET  /config
class QrApi {
  QrApi({required this.baseUrl, http.Client? client, this.tokenProvider})
      : client = client ?? http.Client();

  static const Duration requestTimeout = Duration(seconds: 15);

  final http.Client client;
  final String baseUrl; // ej. http://3.129.217.49:8080
  final Future<String?> Function()? tokenProvider;

  Uri _uri(String path, [Map<String, String>? query]) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final prefix = base.endsWith('/api/v1') ? base : '$base/api/v1';
    return Uri.parse('$prefix$path').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers({bool json = false}) async {
    final headers = <String, String>{'Accept': 'application/json'};
    if (json) headers['Content-Type'] = 'application/json';
    final token = await tokenProvider?.call();
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token.trim()}';
    }
    return headers;
  }

  Future<dynamic> _get(String path, [Map<String, String>? query]) async {
    final res = await client.get(_uri(path, query), headers: await _headers()).timeout(requestTimeout);
    return _decode(res);
  }

  Future<dynamic> _post(String path, [Map<String, dynamic>? body]) async {
    final res = await client
        .post(_uri(path), headers: await _headers(json: true), body: jsonEncode(body ?? {}))
        .timeout(requestTimeout);
    return _decode(res);
  }

  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(utf8.decode(res.bodyBytes));
    }
    String? code;
    String? message;
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      if (body is Map<String, dynamic>) {
        code = body['code'] as String?;
        message = body['message'] as String?;
      }
    } catch (_) {}
    throw QrApiException(statusCode: res.statusCode, code: code, message: message ?? 'Error ${res.statusCode}');
  }

  // ---------- Appointments & Booking ----------
  Future<List<dynamic>> getAppointmentsByDate(String date) async =>
      (await _get('/appointments', {'date': date})) as List<dynamic>;

  Future<Map<String, dynamic>> getAppointment(int id) async =>
      (await _get('/appointments/$id')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getTimeSlot(int id) async =>
      (await _get('/time-slots/$id')) as Map<String, dynamic>;

  // ---------- IAM ----------
  Future<Map<String, dynamic>> getPatient(int id) async =>
      (await _get('/patients/$id')) as Map<String, dynamic>;

  // ---------- Configuration ----------
  Future<Map<String, dynamic>> getConfig() async => (await _get('/config')) as Map<String, dynamic>;

  // ---------- Arrival & QR Check-in ----------
  /// null si el bloque aún no tiene cola (nadie ha llegado).
  Future<Map<String, dynamic>?> findAttendanceQueue(int timeSlotId, String date) async {
    try {
      return (await _get('/attendance-queues', {'timeSlotId': '$timeSlotId', 'date': date}))
          as Map<String, dynamic>;
    } on QrApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<List<dynamic>> getQueueEntries(int queueId) async =>
      (await _get('/attendance-queues/$queueId/entries')) as List<dynamic>;

  Future<Map<String, dynamic>> callNext(int queueId) async =>
      (await _post('/attendance-queues/$queueId/call-next')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getQueueEntry(int id) async =>
      (await _get('/queue-entries/$id')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> startAttention(int id) async =>
      (await _post('/queue-entries/$id/start')) as Map<String, dynamic>;

  /// Responde 204 sin cuerpo.
  Future<void> markAbsent(int id) => _post('/queue-entries/$id/absent');

  Future<Map<String, dynamic>> finishAttention(int id) async =>
      (await _post('/queue-entries/$id/finish')) as Map<String, dynamic>;

  Future<Map<String, dynamic>> checkInByQr(String qrToken) async =>
      (await _post('/check-ins/qr', {'qrToken': qrToken})) as Map<String, dynamic>;

  Future<Map<String, dynamic>> checkInByCode(String bookingCode) async =>
      (await _post('/check-ins/code', {'bookingCode': bookingCode})) as Map<String, dynamic>;

  Future<Map<String, dynamic>> getCheckIn(int id) async =>
      (await _get('/check-ins/$id')) as Map<String, dynamic>;

  void dispose() => client.close();
}
