import 'package:flutter/material.dart';

import 'core/di/service_locator.dart';
import 'features/auth/presentation/auth_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const SaludYaApp());
}

class SaludYaApp extends StatelessWidget {
  const SaludYaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'SaludYa',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0C926B)),
      useMaterial3: true,
      scaffoldBackgroundColor: const Color(0xFFF6FAF9),
    ),
    home: const AuthPage(),
  );
}
