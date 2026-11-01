import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:saludya/features/schedule/infrastructure/remote/api/saludya_api.dart';
import 'package:saludya/main.dart';

void main() {
  testWidgets('main abre schedule y permite entrar al calendario', (
    tester,
  ) async {
    final client = MockClient((request) async {
      if (request.url.path.endsWith('/specialties')) {
        expect(request.headers.containsKey('Authorization'), isFalse);
        return http.Response(
          '[{"id":1,"name":"Medicina general","description":"Atencion"}]',
          200,
        );
      }
      if (request.url.path.endsWith('/doctors')) {
        return http.Response('[]', 200);
      }
      throw StateError('Ruta inesperada: ${request.url}');
    });
    final api = SaludYaApi(client: client);
    await tester.pumpWidget(MainApp(api: api));
    await tester.pumpAndSettle();

    expect(find.text('Elige especialidad'), findsOneWidget);
    expect(find.text('Medicina general'), findsOneWidget);
    await tester.tap(find.text('Ver disponibilidad →').first);
    await tester.pumpAndSettle();

    expect(find.text('Calendario'), findsWidgets);
    expect(find.text('Ver bloques del día'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    client.close();
  });
}
