import 'package:flutter/material.dart';

class IntervalsPage extends StatelessWidget {
  final VoidCallback onBack;

  const IntervalsPage({super.key, required this.onBack});

  static const Color backgroundColor = Color(0xFFF4F9F7);
  static const Color primaryColor = Color(0xFF009B78);
  static const Color textColor = Color(0xFF263634);
  static const Color secondaryTextColor = Color(0xFF607B78);

  @override
  Widget build(BuildContext context) => Container(
    color: backgroundColor,
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 19),
                  color: primaryColor,
                  tooltip: 'Volver',
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Intervalos de atención',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No se puede editar todavía: el backend no incluye una duración de intervalo en la configuración ni ofrece una operación para consultarla o guardarla. Esta opción queda pendiente hasta que exista soporte en la API.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: secondaryTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
