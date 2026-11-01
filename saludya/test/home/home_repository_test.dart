import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saludya/features/home/domain/home_models.dart';
import 'package:saludya/features/home/infrastructure/home_api_repository.dart';

Map<String, dynamic> booking(int id, {String status = 'CONFIRMED'}) => {
  'id': id,
  'timeSlotId': 10,
  'patientId': 20,
  'bookingCode': 'SY-$id',
  'status': status,
  'updatedAt': '2026-10-30T12:00:00Z',
};
Object fixture(String path) => switch (path) {
  '/api/v1/time-slots/10' => {
    'id': 10,
    'doctorId': 30,
    'date': '2026-10-31',
    'startHour': '09:00:00',
    'endHour': '09:30:00',
  },
  '/api/v1/doctors/30' => {'id': 30, 'specialtyId': 40},
  '/api/v1/specialties/40' => {'id': 40, 'name': 'Medicina general'},
  '/api/v1/patients/20' => {
    'id': 20,
    'name': 'Paciente',
    'lastname': 'Prueba',
    'birthDate': '2015-01-01',
  },
  _ => throw StateError('Unexpected path: $path'),
};

void main() {
  final date = DateTime(2026, 10, 31);
  test(
    'queries today with bearer token, joins data and caches shared resources',
    () async {
      final requests = <Uri>[];
      final repo = HomeApiRepository(
        tokenProvider: () async => 'staff-session',
        client: homeClient((request) async {
          requests.add(request.url);
          expect(request.headers['Authorization'], 'Bearer staff-session');
          if (request.url.path.endsWith('/appointments')) {
            expect(request.url.queryParameters['date'], '2026-10-31');
            return http.Response(
              jsonEncode([booking(1), booking(2, status: 'CANCELLED')]),
              200,
            );
          }
          return http.Response(jsonEncode(fixture(request.url.path)), 200);
        }),
      );
      final summary = await repo.getSummary(date);
      expect(summary.pending.length, 1);
      expect(summary.cancelled.length, 1);
      expect(summary.slots.single.patientCount, 1);
      expect(summary.pending.single.patientName, 'Paciente Prueba');
      expect(summary.pending.single.isMinor, isTrue);
      expect(requests.where((u) => u.path.endsWith('/patients/20')).length, 1);
    },
  );

  test('missing session does not send any request', () async {
    var sent = false;
    final repo = HomeApiRepository(
      tokenProvider: () async => null,
      client: homeClient((_) async {
        sent = true;
        return http.Response('[]', 200);
      }),
    );
    await expectLater(
      repo.getSummary(date),
      throwsA(
        isA<HomeFailure>().having((e) => e.sessionExpired, 'session', true),
      ),
    );
    expect(sent, isFalse);
  });

  for (final status in [401, 403, 500]) {
    test(
      'handles HTTP $status without turning failure into an empty summary',
      () async {
        final repo = HomeApiRepository(
          tokenProvider: () async => 'token',
          client: homeClient((_) async => http.Response('{}', status)),
        );
        await expectLater(
          repo.getSummary(date),
          throwsA(
            isA<HomeFailure>().having(
              (e) => e.sessionExpired,
              'session',
              status == 401,
            ),
          ),
        );
      },
    );
  }
  test('malformed response becomes a readable failure', () async {
    final repo = HomeApiRepository(
      tokenProvider: () async => 'token',
      client: homeClient((_) async => http.Response('not json', 200)),
    );
    await expectLater(repo.getSummary(date), throwsA(isA<HomeFailure>()));
  });
  test('empty backend result stays empty', () async {
    final repo = HomeApiRepository(
      tokenProvider: () async => 'token',
      client: homeClient((_) async => http.Response('[]', 200)),
    );
    expect((await repo.getSummary(date)).bookings, isEmpty);
  });
  test(
    'a different date is excluded even if backend ignores the filter',
    () async {
      final repo = HomeApiRepository(
        tokenProvider: () async => 'token',
        client: homeClient((request) async {
          if (request.url.path.endsWith('/appointments')) {
            return http.Response(jsonEncode([booking(1)]), 200);
          }
          final slot = Map<String, dynamic>.from(
            fixture(request.url.path) as Map,
          )..['date'] = '2026-11-01';
          return http.Response(jsonEncode(slot), 200);
        }),
      );
      expect((await repo.getSummary(date)).bookings, isEmpty);
    },
  );
  for (final state in ['IN_ATTENTION', 'WAITING', 'NO_CHECK_IN']) {
    test('maps $state using queue entries and check-in contracts', () async {
      final repo = HomeApiRepository(
        tokenProvider: () async => 'token',
        client: homeClient((request) async {
          final path = request.url.path;
          if (path.endsWith('/appointments')) {
            expect(request.url.queryParameters['timeSlotId'], '10');
            return http.Response(jsonEncode([booking(1)]), 200);
          }
          if (path.endsWith('/attendance-queues')) {
            return http.Response('{"id":7}', 200);
          }
          if (path.endsWith('/7/entries')) {
            return http.Response(
              jsonEncode([
                {'checkInId': 9, 'status': state},
              ]),
              200,
            );
          }
          if (path.contains('/check-ins/')) {
            return state == 'NO_CHECK_IN'
                ? http.Response('', 404)
                : http.Response('{"id":9,"status":"VALID"}', 200);
          }
          return http.Response(jsonEncode(fixture(path)), 200);
        }),
      );
      expect(
        (await repo.getPatients(date, 10)).single.arrival,
        state == 'IN_ATTENTION'
            ? ArrivalStatus.inService
            : state == 'WAITING'
            ? ArrivalStatus.registered
            : ArrivalStatus.pending,
      );
    });
  }
}

MockClient homeClient(Future<http.Response> Function(http.Request) handler) =>
    MockClient((request) async {
      if (request.url.path.endsWith('/user-accounts/me')) {
        return http.Response(
          jsonEncode({'role': 'ADMISSION_STAFF', 'name': 'Personal'}),
          200,
        );
      }
      return handler(request);
    });
