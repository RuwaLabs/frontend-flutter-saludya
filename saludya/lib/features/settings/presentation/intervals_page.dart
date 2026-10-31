import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saludya/features/settings/presentation/components/rule_validation_dialog.dart';

class IntervalsPage extends StatefulWidget {
  final VoidCallback onBack;
  final int currentDuration;
  final Future<void> Function(int duration) onSave;

  const IntervalsPage({
    super.key,
    required this.onBack,
    required this.currentDuration,
    required this.onSave,
  });

  @override
  State<IntervalsPage> createState() => _IntervalsPageState();
}

class _IntervalsPageState extends State<IntervalsPage> {
  static const Color backgroundColor = Color(0xFFF4F9F7);
  static const Color primaryColor = Color(0xFF009B78);
  static const Color textColor = Color(0xFF263634);
  static const Color secondaryTextColor = Color(0xFF607B78);
  static const Color borderColor = Color(0xFFD5E5DF);

  late final TextEditingController _durationController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _durationController = TextEditingController(
      text: widget.currentDuration.toString(),
    );
  }

  @override
  void dispose() {
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _saveInterval() async {
    if (_isSaving) return;

    final duration = int.tryParse(_durationController.text);

    if (duration == null || duration <= 0) {
      await showDialog<bool>(
        context: context,
        builder: (context) => const RuleValidationDialog(
          message:
              'La duración del intervalo debe ser un número entero '
              'mayor que cero.',
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(duration);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Intervalo actualizado temporalmente. '
            'No se ha guardado en el servidor.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo guardar el intervalo: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: _isSaving ? null : widget.onBack,
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 19,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(width: 17),
                  const Text(
                    'Intervalos de atención',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 43),
              const Text(
                'Duración de cada intervalo',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _durationController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 14, color: textColor),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'La relación entre la duración del intervalo y la tolerancia '
                'de llegada queda pendiente de definir.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveInterval,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Guardar intervalo',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Este valor se conserva temporalmente durante la sesión. '
                'No se guarda en el servidor y se perderá al cerrar o '
                'recargar la aplicación.',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.5,
                  color: secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
