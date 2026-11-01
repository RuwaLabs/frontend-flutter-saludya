import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saludya/features/schedule/infrastructure/remote/api/saludya_api.dart';
import 'package:saludya/features/schedule/infrastructure/remote/dtos/time_slot_dto.dart';

void main() {
  test('solicita doctores y bloques filtrados sin autenticación', () async {
    final client = MockClient((request) async {
      expect(request.headers.containsKey('Authorization'), isFalse);
      if (request.url.path.endsWith('/doctors')) {
        expect(request.url.queryParameters['specialtyId'], '2');
        return http.Response(
          '[{"id":7,"specialtyId":2,"name":"Ana","lastname":"Ríos"}]',
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
      expect(request.url.path, '/api/v1/time-slots');
      expect(request.url.queryParameters, {
        'doctorId': '7',
        'date': '2026-11-03',
      });
      return http.Response(
        jsonEncode([
          {
            'id': 9,
            'doctorId': 7,
            'date': '2026-11-03',
            'startHour': '08:00:00',
            'endHour': '09:00:00',
            'room': '02',
            'maxCapacity': 8,
            'currentBookings': 2,
            'status': 'AVAILABLE',
          },
        ]),
        200,
      );
    });
    final api = SaludYaApi(client: client);
    expect((await api.getDoctorsBySpecialty(2)).single.specialityId, 2);
    final slots = await api.getTimeSlotsByDoctorAndDate(
      7,
      DateTime(2026, 11, 3),
    );
    expect(slots.single.startHour.hour, 8);
    client.close();
  });

  test('actualiza estado por PUT sin enviar consultorio no editable', () async {
    final client = MockClient((request) async {
      expect(request.method, 'PUT');
      expect(request.url.path, '/api/v1/time-slots/9');
      expect(jsonDecode(request.body), {
        'doctorId': 7,
        'startHour': '08:00:00',
        'endHour': '09:00:00',
        'status': 'CANCELLED',
      });
      return http.Response('{}', 200);
    });
    final api = SaludYaApi(client: client);
    await api.updateTimeSlot(
      TimeSlotDto(
        id: 9,
        doctorId: 7,
        date: DateTime(2026, 11, 3),
        startHour: DateTime(2026, 11, 3, 8),
        endHour: DateTime(2026, 11, 3, 9),
        room: '02',
        maxCapacity: 8,
        currentBookings: 2,
        status: 'CANCELLED',
      ),
    );
    client.close();
  });
}
