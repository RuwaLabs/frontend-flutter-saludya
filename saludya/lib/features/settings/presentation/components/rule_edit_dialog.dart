import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RuleEditDialog extends StatefulWidget {
  final String ruleName;
  final String currentValue;
  final String initialValue;

  const RuleEditDialog({
    super.key,
    required this.ruleName,
    required this.currentValue,
    this.initialValue = '10',
  });

  static const Color primaryColor = Color(0xFF009B78);
  static const Color textColor = Color(0xFF263634);
  static const Color secondaryTextColor = Color(0xFF607B78);
  static const Color borderColor = Color(0xFFD5E5DF);

  @override
  State<RuleEditDialog> createState() => _RuleEditDialogState();
}

class _RuleEditDialogState extends State<RuleEditDialog> {
  late final TextEditingController _controller;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _controller = TextEditingController(
      text: widget.initialValue,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = int.tryParse(_controller.text);

    if (value == null || value < 0) {
      setState(() {
        _errorMessage =
            'Ingresa un número válido mayor o igual a cero.';
      });
      return;
    }

    Navigator.pop(context, _controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingrese el nuevo valor',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: RuleEditDialog.textColor,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${widget.ruleName}\nValor actual: ${widget.currentValue}',
              style: const TextStyle(
                fontSize: 14,
                height: 1.45,
                color: RuleEditDialog.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nuevo valor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: RuleEditDialog.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (_) {
                if (_errorMessage != null) {
                  setState(() {
                    _errorMessage = null;
                  });
                }
              },
              style: const TextStyle(
                fontSize: 14,
                color: RuleEditDialog.textColor,
              ),
              decoration: InputDecoration(
                errorText: _errorMessage,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 13,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: RuleEditDialog.borderColor,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: RuleEditDialog.borderColor,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(
                    color: RuleEditDialog.primaryColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RuleEditDialog.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Actualizar',
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
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: RuleEditDialog.primaryColor,
                  side: const BorderSide(
                    color: RuleEditDialog.primaryColor,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Cancelar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}