import 'package:saludya/features/settings/domain/establishment_settings.dart';
import 'package:saludya/features/settings/domain/settings_repository.dart';

class GetEstablishmentSettingsUseCase {
  final SettingsRepository repository;

  GetEstablishmentSettingsUseCase({required this.repository});

  Future<EstablishmentSettings> execute() {
    return repository.getSettings();
  }
}
