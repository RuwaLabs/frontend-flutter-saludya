import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IntervalsPage extends StatefulWidget {
  final VoidCallback onBack;
  final int? currentDuration;
  final Future<void> Function(int duration) onSave;
  final bool canEdit;

  const IntervalsPage({
    super.key,
    required this.onBack,
    required this.currentDuration,
    required this.onSave,
    this.canEdit = true,
  });

  static const Color backgroundColor = Color(0xFFF4FAF8);
  static const Color primaryColor = Color(0xFF0B8F6B);
  static const Color textColor = Color(0xFF1C2B2A);
  static const Color secondaryTextColor = Color(0xFF56706D);
  static const Color borderColor = Color(0xFFD8E6E2);

  @override
  State<IntervalsPage> createState() => _IntervalsPageState();
}

class _IntervalsPageState extends State<IntervalsPage> {
  late final TextEditingController _durationController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(
      text: widget.currentDuration?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final duration = int.tryParse(_durationController.text);
    if (duration == null || duration <= 0 || _saving) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un intervalo mayor que cero.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onSave(duration);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar el intervalo: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    color: IntervalsPage.backgroundColor,
    child: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: _saving ? null : widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new, size: 19),
                  color: IntervalsPage.primaryColor,
                  tooltip: 'Volver',
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Intervalos de atención',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: IntervalsPage.textColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 36),
            const Text(
              'Duración de cada intervalo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: IntervalsPage.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _durationController,
              enabled:
                  !_saving && widget.canEdit && widget.currentDuration != null,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                suffixText: 'minutos',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: IntervalsPage.borderColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.currentDuration == null
                  ? 'El backend conectado todavía no expone la duración del intervalo. Actualiza el backend para habilitar esta opción.'
                  : widget.canEdit
                  ? 'La duración se aplica a los nuevos bloques; no cambia las reservas confirmadas.'
                  : 'Solo Super Admin puede cambiar la duración de los intervalos.',
              style: TextStyle(color: IntervalsPage.secondaryTextColor),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed:
                    _saving || !widget.canEdit || widget.currentDuration == null
                    ? null
                    : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: IntervalsPage.primaryColor,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Guardar intervalo'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
