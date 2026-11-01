import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'features/auth/presentation/auth_page.dart';
import 'features/home/presentation/home_ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  setupDependencies();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(title: 'SaludYa',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: homeBackground,
      colorScheme: ColorScheme.fromSeed(seedColor: homeGreen, primary: homeGreen),
      appBarTheme: const AppBarTheme(backgroundColor: homeBackground, foregroundColor: Color(0xFF203230), elevation: 0),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      outlinedButtonTheme: OutlinedButtonThemeData(style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48), side: const BorderSide(color: homeGreen), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
      navigationBarTheme: const NavigationBarThemeData(backgroundColor: Colors.white, indicatorColor: Color(0xFFE0F3ED))),
    home: const AuthPage());
}
