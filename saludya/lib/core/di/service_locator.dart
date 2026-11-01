import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/application/auth_service.dart';
import '../../features/auth/domain/auth_repository.dart';
import '../../features/auth/infrastructure/auth_repository_impl.dart';

final sl = GetIt.instance;

void setupDependencies() {
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));
  sl.registerLazySingleton(() => AuthService(sl()));
}
