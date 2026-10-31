import 'package:flutter/material.dart';
import 'package:saludya/core/service_locator.dart';
import 'package:saludya/features/settings/presentation/components/rule_validation_dialog.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/application/update_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/domain/establishment_settings.dart';
import 'package:saludya/features/settings/presentation/components/rule_edit_dialog.dart';

class MoreRulesPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onOpenIntervals;

  const MoreRulesPage({
    super.key,
    required this.onBack,
    required this.onOpenIntervals,
  });

  static const Color backgroundColor = Color(0xFFF4F9F7);
  static const Color primaryColor = Color(0xFF009B78);
  static const Color textColor = Color(0xFF263634);
  static const Color secondaryTextColor = Color(0xFF607B78);
  static const Color borderColor = Color(0xFFD5E5DF);

  @override
  State<MoreRulesPage> createState() => _MoreRulesPageState();
}

class _MoreRulesPageState extends State<MoreRulesPage> {
  EstablishmentSettings? _settings;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final settings = await getIt<GetEstablishmentSettingsUseCase>().execute();

      if (!mounted) return;

      setState(() {
        _settings = settings;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings(EstablishmentSettings updatedSettings) async {
    if (_isSaving) return;

    final errors = updatedSettings.validate();

    if (errors.isNotEmpty) {
      await showDialog<bool>(
        context: context,
        builder: (context) => RuleValidationDialog(message: errors.join('\n')),
      );

      return;
    }

    final previousSettings = _settings;

    // Actualización visual inmediata.
    setState(() {
      _settings = updatedSettings;
      _isSaving = true;
    });

    try {
      await getIt<UpdateEstablishmentSettingsUseCase>().execute(
        updatedSettings,
      );

      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('Regla actualizada correctamente.');
    } catch (error) {
      if (!mounted) return;

      // Restaurar el valor anterior si falla el guardado.
      setState(() {
        _settings = previousSettings;
        _isSaving = false;
      });

      _showMessage('No se pudo guardar el cambio: $error');
    }
  }

  Future<void> _editCancellationDeadline() async {
    final settings = _settings;
    if (settings == null || _isSaving) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => RuleEditDialog(
        ruleName: 'Anticipación para cancelar',
        currentValue: '${settings.cancellationDeadlineHours} horas',
        initialValue: settings.cancellationDeadlineHours.toString(),
      ),
    );

    if (result == null || !mounted) return;

    final value = int.tryParse(result);

    if (value == null || value < 0) {
      _showMessage('Ingresa un número válido mayor o igual a cero.');
      return;
    }

    await _saveSettings(settings.copyWith(cancellationDeadlineHours: value));
  }

  Future<void> _editBookingCutoffTime() async {
    final settings = _settings;
    if (settings == null || _isSaving) return;

    final parts = settings.bookingCutoffTime.split(':');

    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
      helpText: 'Hora límite para reservar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme
                .copyWith(primary: MoreRulesPage.primaryColor),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null || !mounted) return;

    final formattedTime =
        '${selectedTime.hour.toString().padLeft(2, '0')}:'
        '${selectedTime.minute.toString().padLeft(2, '0')}';

    await _saveSettings(settings.copyWith(bookingCutoffTime: formattedTime));
  }

  Future<void> _editBookingOrderScope() async {
    final settings = _settings;
    if (settings == null || _isSaving) return;

    final selectedScope = await showDialog<BookingOrderScope>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Prioridad de reasignación'),
        children: [
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, BookingOrderScope.global);
            },
            child: const Text('Orden global'),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(context, BookingOrderScope.perSpecialty);
            },
            child: const Text('Por especialidad'),
          ),
        ],
      ),
    );

    if (selectedScope == null || !mounted) return;

    await _saveSettings(settings.copyWith(bookingOrderScope: selectedScope));
  }

  Future<void> _editAttendanceQueueVisibility() async {
    final settings = _settings;
    if (settings == null || _isSaving) return;

    final selectedValue = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Posición de cola visible'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sí'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
        ],
      ),
    );

    if (selectedValue == null || !mounted) return;

    await _saveSettings(
      settings.copyWith(attendanceQueueVisible: selectedValue),
    );
  }

  String _scopeLabel(BookingOrderScope scope) {
    switch (scope) {
      case BookingOrderScope.global:
        return 'Global';
      case BookingOrderScope.perSpecialty:
        return 'Por especialidad';
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: MoreRulesPage.backgroundColor,
      child: SafeArea(child: _buildContent()),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: MoreRulesPage.primaryColor),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_outlined,
                size: 48,
                color: MoreRulesPage.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudieron cargar las reglas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: MoreRulesPage.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: MoreRulesPage.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadSettings,
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final settings = _settings!;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
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
                  color: MoreRulesPage.primaryColor,
                ),
              ),
              const SizedBox(width: 17),
              const Text(
                'Más reglas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: MoreRulesPage.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          _buildRuleCard(
            title: 'Hora límite para reservar',
            value: settings.bookingCutoffTime,
            onEdit: _editBookingCutoffTime,
          ),

          const SizedBox(height: 14),

          _buildRuleCard(
            title: 'Anticipación para cancelar',
            value: '${settings.cancellationDeadlineHours} horas',
            onEdit: _editCancellationDeadline,
          ),

          const SizedBox(height: 14),

          _buildRuleCard(
            title: 'Prioridad de reasignación',
            value: _scopeLabel(settings.bookingOrderScope),
            onEdit: _editBookingOrderScope,
          ),

          const SizedBox(height: 14),

          _buildRuleCard(
            title: 'Posición de cola visible',
            value: settings.attendanceQueueVisible ? 'Sí' : 'No',
            onEdit: _editAttendanceQueueVisibility,
          ),

          const SizedBox(height: 14),

          const Text(
            'La prioridad de reasignación sigue el orden de reserva. '
            'La atención sigue el orden de llegada.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: MoreRulesPage.secondaryTextColor,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : widget.onOpenIntervals,
              style: OutlinedButton.styleFrom(
                foregroundColor: MoreRulesPage.primaryColor,
                side: const BorderSide(
                  color: MoreRulesPage.primaryColor,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Intervalos de atención',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleCard({
    required String title,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: MoreRulesPage.borderColor, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: MoreRulesPage.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: MoreRulesPage.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _isSaving ? null : onEdit,
            child: const Text(
              'Editar →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: MoreRulesPage.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
