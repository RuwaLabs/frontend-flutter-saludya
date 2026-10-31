import 'package:flutter/material.dart';
import 'package:saludya/core/service_locator.dart';
import 'package:saludya/features/settings/presentation/components/rule_validation_dialog.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/application/update_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/domain/establishment_settings.dart';
import 'package:saludya/features/settings/presentation/components/rule_edit_dialog.dart';
import 'package:saludya/features/settings/presentation/more_rules_page.dart';
import 'package:saludya/features/settings/presentation/intervals_page.dart';
import 'package:saludya/features/settings/presentation/edit_capacity_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const Color backgroundColor = Color(0xFFF4F9F7);
  static const Color primaryColor = Color(0xFF009B78);
  static const Color textColor = Color(0xFF263634);
  static const Color secondaryTextColor = Color(0xFF607B78);
  static const Color borderColor = Color(0xFFD5E5DF);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _currentView = 0;
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
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _editNumericRule({
    required String title,
    required String currentValue,
    required int initialValue,
    required EstablishmentSettings Function(int value) updateSettings,
  }) async {
    if (_settings == null || _isSaving) return;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => RuleEditDialog(
        ruleName: title,
        currentValue: currentValue,
        initialValue: initialValue.toString(),
      ),
    );

    if (result == null || !mounted) return;

    final value = int.tryParse(result);

    if (value == null) return;

    final updatedSettings = updateSettings(value);
    final errors = updatedSettings.validate();

    if (errors.isNotEmpty) {
      await showDialog<bool>(
        context: context,
        builder: (context) => RuleValidationDialog(message: errors.join('\n')),
      );

      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await getIt<UpdateEstablishmentSettingsUseCase>().execute(
        updatedSettings,
      );

      if (!mounted) return;

      setState(() {
        _settings = updatedSettings;
        _isSaving = false;
      });

      _showMessage('Configuración actualizada correctamente.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage('No se pudo actualizar la configuración: $error');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _openMoreRules() {
    setState(() {
      _currentView = 1;
    });
  }

  void _openEditCapacity() {
    setState(() {
      _currentView = 3;
    });
  }

  void _openIntervals() {
    setState(() {
      _currentView = 2;
    });
  }

  Future<void> _openGeneralSettings() async {
    setState(() {
      _currentView = 0;
    });

    await _loadSettings();
  }

  Future<void> _saveCapacity(int capacity) async {
    final settings = _settings;
    if (settings == null) return;

    final updatedSettings = settings.copyWith(maxCapacityPerSlot: capacity);

    setState(() {
      _isSaving = true;
    });

    try {
      await getIt<UpdateEstablishmentSettingsUseCase>().execute(
        updatedSettings,
      );

      if (!mounted) return;

      setState(() {
        _settings = updatedSettings;
        _isSaving = false;
        _currentView = 0;
      });

      _showMessage('Capacidad actualizada correctamente.');
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }

      rethrow;
    }
  }

  Future<void> _saveInterval(int duration) async {
    final settings = _settings;
    if (settings == null || _isSaving) return;

    final updatedSettings = settings.copyWith(
      intervalDurationMinutes: duration,
    );

    final errors = updatedSettings.validate();

    if (errors.isNotEmpty) {
      throw Exception(errors.join('\n'));
    }

    setState(() {
      _settings = updatedSettings;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SettingsPage.backgroundColor,
      body: SafeArea(child: _buildCurrentView()),
    );
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case 0:
        return _buildContent();

      case 1:
        return MoreRulesPage(
          onBack: _openGeneralSettings,
          onOpenIntervals: _openIntervals,
        );

      case 2:
        final settings = _settings;

        if (settings == null) {
          return _buildContent();
        }

        return IntervalsPage(
          currentDuration: settings.intervalDurationMinutes,
          onSave: _saveInterval,
          onBack: _openMoreRules,
        );

      case 3:
        final settings = _settings;

        if (settings == null) {
          return _buildContent();
        }

        return EditCapacityPage(
          currentCapacity: settings.maxCapacityPerSlot,
          onSave: _saveCapacity,
          onBack: _openGeneralSettings,
        );

      default:
        return _buildContent();
    }
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: SettingsPage.primaryColor),
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
                color: SettingsPage.secondaryTextColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'No se pudo cargar la configuración.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SettingsPage.textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: SettingsPage.secondaryTextColor,
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
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.maybePop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  size: 19,
                  color: SettingsPage.primaryColor,
                ),
              ),
              const SizedBox(width: 17),
              const Text(
                'Configuración general',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: SettingsPage.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 42),
          const Text(
            'Reglas del establecimiento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: SettingsPage.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildRuleCard(
            title: 'Capacidad por bloque',
            value: '${settings.maxCapacityPerSlot} pacientes',
            onEdit: _openEditCapacity,
          ),
          const SizedBox(height: 14),
          _buildRuleCard(
            title: 'Tolerancia de llegada',
            value: '${settings.checkInToleranceMinutes} minutos',
            onEdit: () => _editNumericRule(
              title: 'Tolerancia de llegada',
              currentValue: '${settings.checkInToleranceMinutes} minutos',
              initialValue: settings.checkInToleranceMinutes,
              updateSettings: (value) =>
                  settings.copyWith(checkInToleranceMinutes: value),
            ),
          ),
          const SizedBox(height: 14),
          _buildRuleCard(
            title: 'Plazo después de llamada',
            value: '${settings.postCallToleranceMinutes} minutos',
            onEdit: () => _editNumericRule(
              title: 'Plazo después de llamada',
              currentValue: '${settings.postCallToleranceMinutes} minutos',
              initialValue: settings.postCallToleranceMinutes,
              updateSettings: (value) =>
                  settings.copyWith(postCallToleranceMinutes: value),
            ),
          ),
          const SizedBox(height: 14),
          _buildRuleCard(
            title: 'Respuesta a reasignación',
            value: '${settings.reassignmentResponseTimeoutMin} minutos',
            onEdit: () => _editNumericRule(
              title: 'Respuesta a reasignación',
              currentValue:
                  '${settings.reassignmentResponseTimeoutMin} minutos',
              initialValue: settings.reassignmentResponseTimeoutMin,
              updateSettings: (value) =>
                  settings.copyWith(reassignmentResponseTimeoutMin: value),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _isSaving ? null : _openMoreRules,
              style: OutlinedButton.styleFrom(
                foregroundColor: SettingsPage.primaryColor,
                side: const BorderSide(
                  color: SettingsPage.primaryColor,
                  width: 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Ver más reglas',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          if (_isSaving) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(color: SettingsPage.primaryColor),
          ],
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
      padding: const EdgeInsets.fromLTRB(16, 17, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: SettingsPage.borderColor, width: 1),
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
              color: SettingsPage.textColor,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: SettingsPage.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 9),
          GestureDetector(
            onTap: _isSaving ? null : onEdit,
            child: const Text(
              'Editar →',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: SettingsPage.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
