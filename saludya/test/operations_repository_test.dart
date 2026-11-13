import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:saludya/features/operations/infrastructure/operations_repository_impl.dart';
import 'package:saludya/features/operations/infrastructure/remote/operations_api.dart';

void main() {
  test('dashboard metrics are mapped from the real API response', () async {
    late http.BaseRequest request;
    final api = OperationsApi(
      baseUrl: 'http://localhost:8080/api/v1',
      tokenProvider: () async => 'staff-token',
      client: _FakeClient((value) async {
        request = value;
        return http.Response(
          jsonEncode({
            'metrics': [
              {'name': 'scheduledToday', 'value': 12},
              {'name': 'pendingToday', 'value': 5},
              {'name': 'cancelledToday', 'value': 2},
              {'name': 'attendedToday', 'value': 4},
              {'name': 'absentToday', 'value': 1},
            ],
          }),
          200,
        );
      }),
    );
    final repository = OperationsRepositoryImpl(api: api);

    final dashboard = await repository.getDashboard(DateTime(2026, 11, 12));

    expect(dashboard.scheduled, 12);
    expect(dashboard.pending, 5);
    expect(dashboard.cancelled, 2);
    expect(request.url.path, '/api/v1/config/dashboard');
    expect(request.url.queryParameters['date'], '2026-11-12');
    expect(request.headers['Authorization'], 'Bearer staff-token');
  });

  test(
    'calendar returns all block fields for a specialty and date range',
    () async {
      late http.BaseRequest request;
      final api = OperationsApi(
        baseUrl: 'https://api.example.test/api/v1',
        tokenProvider: () async => 'admin-token',
        client: _FakeClient((value) async {
          request = value;
          return http.Response(
            jsonEncode([
              {
                'id': 7,
                'doctorId': 3,
                'date': '2026-11-12',
                'startHour': '09:00:00',
                'endHour': '09:30:00',
                'room': 'Consultorio 02',
                'maxCapacity': 8,
                'currentBookings': 5,
                'status': 'AVAILABLE',
              },
            ]),
            200,
          );
        }),
      );
      final repository = OperationsRepositoryImpl(api: api);

      final blocks = await repository.getCalendarBlocks(
        2,
        DateTime(2026, 11, 1),
        DateTime(2026, 11, 30),
      );

      expect(request.url.path, '/api/v1/time-slots/calendar');
      expect(request.url.queryParameters, {
        'specialtyId': '2',
        'from': '2026-11-01',
        'to': '2026-11-30',
      });
      expect(blocks.single.startHour, '09:00');
      expect(blocks.single.availableCapacity, 3);
    },
  );

  test(
    'manual arrival submits the entered booking code and maps the receipt',
    () async {
      late http.BaseRequest request;
      final api = OperationsApi(
        baseUrl: 'https://api.example.test/api/v1',
        tokenProvider: () async => 'admin-token',
        client: _FakeClient((value) async {
          request = value;
          return http.Response(
            jsonEncode({
              'checkInId': 17,
              'appointmentId': 28,
              'queueEntryId': 31,
              'position': 2,
              'totalInQueue': 4,
              'status': 'VALID',
            }),
            201,
          );
        }),
      );
      final repository = OperationsRepositoryImpl(api: api);

      final receipt = await repository.registerArrival(' SAL-AB12CD34EF ');

      expect(request.url.path, '/api/v1/check-ins/code');
      expect(jsonDecode((request as http.Request).body), {
        'bookingCode': 'SAL-AB12CD34EF',
      });
      expect(receipt.position, 2);
      expect(receipt.queueEntryId, 31);
    },
  );

  test('calendar falls back to the deployed doctor/date endpoints', () async {
    final api = OperationsApi(
      baseUrl: 'https://api.example.test/api/v1',
      tokenProvider: () async => 'admin-token',
      client: _FakeClient((request) async {
        if (request.url.path.endsWith('/time-slots/calendar')) {
          return http.Response('{"message":"Not found"}', 404);
        }
        if (request.url.path.endsWith('/doctors')) {
          return http.Response(
            jsonEncode([
              {'id': 3, 'specialtyId': 1, 'name': 'Ana', 'lastname': 'Rojas'},
            ]),
            200,
          );
        }
        if (request.url.path.endsWith('/time-slots')) {
          return http.Response(
            jsonEncode([
              {
                'id': 8,
                'doctorId': 3,
                'date': '2026-11-12',
                'startHour': '09:00',
                'endHour': '09:30',
                'room': 'Consultorio 01',
                'maxCapacity': 8,
                'currentBookings': 8,
                'status': 'FULL',
              },
            ]),
            200,
          );
        }
        return http.Response('{}', 404);
      }),
    );
    final repository = OperationsRepositoryImpl(api: api);

    final blocks = await repository.getCalendarBlocks(
      1,
      DateTime(2026, 11, 12),
      DateTime(2026, 11, 12),
    );

    expect(blocks.single.id, 8);
    expect(blocks.single.status, 'FULL');
  });

  test(
    'queue falls back to deployed entries, check-ins and patient endpoints',
    () async {
      final api = OperationsApi(
        baseUrl: 'https://api.example.test/api/v1',
        tokenProvider: () async => 'admin-token',
        client: _FakeClient((request) async {
          if (request.url.path.endsWith('/entries/administrative')) {
            return http.Response('{"message":"Not found"}', 404);
          }
          if (request.url.path.endsWith('/entries')) {
            return http.Response(
              jsonEncode([
                {
                  'id': 5,
                  'attendanceQueueId': 4,
                  'checkInId': 6,
                  'position': 1,
                  'status': 'WAITING',
                },
              ]),
              200,
            );
          }
          if (request.url.path.endsWith('/check-ins/6')) {
            return http.Response(
              jsonEncode({'appointmentId': 7, 'bookingCode': 'SAL-AB12CD34EF'}),
              200,
            );
          }
          if (request.url.path.endsWith('/appointments/7')) {
            return http.Response(jsonEncode({'patientId': 2}), 200);
          }
          if (request.url.path.endsWith('/patients/2')) {
            return http.Response(
              jsonEncode({'name': 'Maria', 'lastname': 'Perez'}),
              200,
            );
          }
          return http.Response('{}', 404);
        }),
      );
      final repository = OperationsRepositoryImpl(api: api);

      final entries = await repository.getQueueEntries(4);

      expect(entries.single.patientName, 'Maria Perez');
      expect(entries.single.bookingCode, 'SAL-AB12CD34EF');
      expect(entries.single.status, 'WAITING');
    },
  );
}

class _FakeClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  _FakeClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
    );
  }
}
