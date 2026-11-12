import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:saludya/features/settings/application/get_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/application/update_establishment_settings_use_case.dart';
import 'package:saludya/features/settings/domain/settings_repository.dart';
import 'package:saludya/features/settings/infrastructure/remote/settings_api.dart';
import 'package:saludya/features/settings/infrastructure/settings_repository_impl.dart';

import '../../features/auth/application/auth_service.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/infrastructure/auth_repository_impl.dart';

final sl = GetIt.instance;
final getIt = sl;

void setupDependencies() {
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AuthService(sl()));

  const baseUrl = 'http://3.129.217.49:8080';
  sl.registerLazySingleton<SettingsApi>(() => SettingsApi(baseUrl: baseUrl));
  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(api: sl<SettingsApi>()),
  );
  sl.registerLazySingleton<GetEstablishmentSettingsUseCase>(
    () => GetEstablishmentSettingsUseCase(repository: sl<SettingsRepository>()),
  );
  sl.registerLazySingleton<UpdateEstablishmentSettingsUseCase>(
    () => UpdateEstablishmentSettingsUseCase(repository: sl<SettingsRepository>()),
  );
}
