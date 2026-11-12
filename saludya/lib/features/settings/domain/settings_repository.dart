import 'package:saludya/features/settings/domain/establishment_settings.dart';

abstract class SettingsRepository {
  Future<EstablishmentSettings> getSettings();

  Future<void> updateSettings(EstablishmentSettings settings);
}