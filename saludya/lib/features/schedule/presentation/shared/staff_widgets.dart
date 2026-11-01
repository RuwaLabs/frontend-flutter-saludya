import 'package:flutter/material.dart';

class StaffColors {
  static const text = Color(0xFF1C2B2A);
  static const muted = Color(0xFF56706D);
  static const primary = Color(0xFF0B8F6B);
  static const soft = Color(0xFFE6F5F0);
  static const bg = Color(0xFFF4FAF8);
  static const border = Color(0xFFD8E6E2);
}

class StaffScaffold extends StatelessWidget {
  const StaffScaffold({super.key, required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: StaffColors.bg,
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 21,
          fontWeight: FontWeight.w600,
          color: StaffColors.text,
        ),
      ),
      backgroundColor: StaffColors.bg,
      foregroundColor: StaffColors.primary,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        children: [
          for (final child in children)
            Padding(padding: const EdgeInsets.only(bottom: 14), child: child),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Container(
        height: 72,
        color: Colors.white,
        child: Row(
          children: [
            _navItem(Icons.home_outlined, 'Inicio'),
            _navItem(Icons.calendar_month_outlined, 'Calendario', active: true),
            _navItem(Icons.qr_code_scanner, 'Cita'),
            _navItem(Icons.wb_sunny_outlined, 'Configuración'),
          ],
        ),
      ),
    ),
  );

  Widget _navItem(IconData icon, String label, {bool active = false}) =>
      Expanded(
        child: Container(
          color: active ? StaffColors.soft : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? StaffColors.primary : StaffColors.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: active ? StaffColors.primary : StaffColors.muted,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      );
}

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.title,
    this.lines = const [],
    this.action,
    this.onTap,
    this.leading,
  });
  final String title;
  final List<String> lines;
  final String? action;
  final VoidCallback? onTap;
  final IconData? leading;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: StaffColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: StaffColors.soft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(leading, color: StaffColors.primary),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: StaffColors.text,
                    ),
                  ),
                  for (final line in lines)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        line,
                        style: const TextStyle(
                          fontSize: 13,
                          color: StaffColors.muted,
                        ),
                      ),
                    ),
                  if (action != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        action!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: StaffColors.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.label,
    required this.hint,
    required this.onChanged,
  });
  final String label;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    onChanged: onChanged,
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      prefixIcon: const Icon(Icons.search),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    ),
  );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
  });
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: FilledButton(
      style: FilledButton.styleFrom(
        backgroundColor: StaffColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Text(label),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(message),
      TextButton(onPressed: onRetry, child: const Text('Reintentar')),
    ],
  );
}

String shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';
String shortTime(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
