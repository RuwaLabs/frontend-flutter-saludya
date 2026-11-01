import 'package:flutter/material.dart';
const homeGreen = Color(0xFF08916F);
const homeBackground = Color(0xFFF4FAF8);
const homeMuted = Color(0xFF627F7B);

String homeDate(DateTime d) {
  const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${d.day} ${months[d.month - 1]} ${d.year}';
}

class HomeCard extends StatelessWidget {
  const HomeCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12), elevation: 0, color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFDDEAE7))),
    clipBehavior: Clip.antiAlias,
    child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(16), child: child)));
}

class HomeMessage extends StatelessWidget {
  const HomeMessage({super.key, required this.message, this.onRetry, this.error = false});
  final String message;
  final VoidCallback? onRetry;
  final bool error;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(error ? Icons.cloud_off_outlined : Icons.event_note_outlined, size: 40, color: homeMuted),
      const SizedBox(height: 16), Text(message, textAlign: TextAlign.center),
      if (onRetry != null) ...[const SizedBox(height: 16),
        OutlinedButton(onPressed: onRetry, child: const Text('Reintentar'))],
    ]));
}
