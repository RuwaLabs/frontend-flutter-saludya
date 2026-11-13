import 'package:flutter/material.dart';

abstract final class SaludYaPalette {
  static const primary = Color(0xFF009B78);
  static const primaryDark = Color(0xFF08745F);
  static const background = Color(0xFFF4F9F7);
  static const surface = Colors.white;
  static const text = Color(0xFF263634);
  static const secondaryText = Color(0xFF607B78);
  static const border = Color(0xFFD5E5DF);
  static const selected = Color(0xFFE5F5F0);
  static const absent = Color(0xFFC43B32);
  static const warning = Color(0xFF9A6500);
}

class SaludYaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SaludYaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: SaludYaPalette.surface,
      border: Border.all(color: SaludYaPalette.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

String formatSpanishDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
