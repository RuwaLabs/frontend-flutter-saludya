import 'package:saludya/features/settings/domain/establishment_settings.dart';
import 'package:saludya/features/settings/domain/settings_repository.dart';

class UpdateEstablishmentSettingsUseCase {
  final SettingsRepository repository;

  UpdateEstablishmentSettingsUseCase({
    required this.repository,
  });

  Future<void> execute(EstablishmentSettings settings) async {
    final errors = settings.validate();

    if (errors.isNotEmpty) {
      throw ArgumentError(errors.join('\n'));
    }

    await repository.updateSettings(settings);
  }
}