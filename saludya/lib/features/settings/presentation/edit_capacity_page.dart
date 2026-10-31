import 'package:saludya/features/settings/presentation/components/rule_validation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditCapacityPage extends StatefulWidget {
  final int currentCapacity;
  final Future<void> Function(int capacity) onSave;
  final VoidCallback onBack;

  const EditCapacityPage({
    super.key,
    required this.currentCapacity,
    required this.onSave,
    required this.onBack,
  });

  static const Color backgroundColor = Color(0xFFF4F9F7);
  static const Color primaryColor = Color(0xFF009B78);
  static const Color textColor = Color(0xFF263634);
  static const Color secondaryTextColor = Color(0xFF607B78);
  static const Color borderColor = Color(0xFFD5E5DF);

  @override
  State<EditCapacityPage> createState() => _EditCapacityPageState();
}

class _EditCapacityPageState extends State<EditCapacityPage> {
  late final TextEditingController _capacityController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _capacityController = TextEditingController(
      text: widget.currentCapacity.toString(),
    );
  }

  @override
  void dispose() {
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_isSaving) return;

    final capacity = int.tryParse(_capacityController.text);

    if (capacity == null || capacity <= 0) {
      await showDialog<bool>(
        context: context,
        builder: (context) => const RuleValidationDialog(
          message:
              'La capacidad máxima por bloque debe ser mayor que cero. '
              'Revisa el valor ingresado antes de continuar.',
        ),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(capacity);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo guardar la capacidad: $error'),
          behavior: SnackBarBehavior.floating,
        ),
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
      color: EditCapacityPage.backgroundColor,
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
                      color: EditCapacityPage.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 17),
                  const Text(
                    'Editar capacidad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: EditCapacityPage.textColor,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 43),

              const Text(
                'Capacidad máxima por bloque',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: EditCapacityPage.textColor,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Número de pacientes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: EditCapacityPage.secondaryTextColor,
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _capacityController,
                enabled: !_isSaving,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(
                  fontSize: 14,
                  color: EditCapacityPage.textColor,
                ),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 13,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: EditCapacityPage.borderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: EditCapacityPage.borderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: const BorderSide(
                      color: EditCapacityPage.primaryColor,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              const Text(
                'Debe ser un número mayor que cero. Los '
                'cambios se aplican según la configuración '
                'operativa y no eliminan reservas confirmadas.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: EditCapacityPage.secondaryTextColor,
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: EditCapacityPage.primaryColor,
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
                          'Guardar cambios',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isSaving ? null : widget.onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: EditCapacityPage.primaryColor,
                    side: const BorderSide(
                      color: EditCapacityPage.primaryColor,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
