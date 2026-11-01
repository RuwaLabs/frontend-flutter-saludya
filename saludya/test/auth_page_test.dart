import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saludya/core/di/service_locator.dart';
import 'package:saludya/features/auth/presentation/auth_page.dart';

void main() {
  setUp(() async {
    await sl.reset();
    setupDependencies();
  });

  testWidgets('login is available without public registration', (tester) async {
    await tester.pumpWidget(const AuthTestApp());
    await tester.pump();

    expect(find.text('Iniciar sesión'), findsOneWidget);
    expect(find.text('Continuar'), findsOneWidget);
    expect(find.text('Crear cuenta'), findsNothing);
    expect(find.text('Registrarse'), findsNothing);
  });

  testWidgets('forgot password opens the email request screen', (tester) async {
    await tester.pumpWidget(const AuthTestApp());
    await tester.pump();
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.text('Recuperar acceso'), findsOneWidget);
    expect(find.text('Enviar código al correo'), findsOneWidget);
  });
}

class AuthTestApp extends StatelessWidget {
  const AuthTestApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(home: AuthPage());
}
