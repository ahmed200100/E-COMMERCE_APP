import 'package:get_it/get_it.dart';

import '../network/auth_token_storage.dart';
import '../network/dio_client.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_home.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  if (!getIt.isRegistered<AuthTokenStorage>()) {
    getIt.registerLazySingleton<AuthTokenStorage>(SecureAuthTokenStorage.new);
  }
  if (!getIt.isRegistered<DioClient>()) {
    getIt.registerLazySingleton<DioClient>(
      () => DioClient(tokenStorage: getIt()),
    );
  }
  if (!getIt.isRegistered<HomeRemoteDataSource>()) {
    getIt.registerLazySingleton<HomeRemoteDataSource>(
      () => HomeRemoteDataSourceImpl(getIt()),
    );
    getIt.registerLazySingleton<HomeRepository>(
      () => HomeRepositoryImpl(getIt()),
    );
    getIt.registerLazySingleton<GetHome>(() => GetHome(getIt()));
    getIt.registerFactory<HomeBloc>(() => HomeBloc(getIt()));
  }
}
