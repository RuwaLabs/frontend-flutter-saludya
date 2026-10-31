import 'package:get_it/get_it.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/application/update_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/domain/settings_repository.dart';
import 'package:saludya/features/settings/infrastructure/remote/settings_api.dart';
import 'package:saludya/features/settings/infrastructure/settings_repository_impl.dart';

final GetIt getIt = GetIt.instance;

void setupDependencies() {
  const baseUrl = 'http://3.129.217.49:8080';

  getIt.registerLazySingleton<SettingsApi>(() => SettingsApi(baseUrl: baseUrl));

  getIt.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(api: getIt<SettingsApi>()),
  );

  getIt.registerLazySingleton<GetEstablishmentSettingsUseCase>(
    () => GetEstablishmentSettingsUseCase(
      repository: getIt<SettingsRepository>(),
    ),
  );

  getIt.registerLazySingleton<UpdateEstablishmentSettingsUseCase>(
    () => UpdateEstablishmentSettingsUseCase(
      repository: getIt<SettingsRepository>(),
    ),
  );
}
