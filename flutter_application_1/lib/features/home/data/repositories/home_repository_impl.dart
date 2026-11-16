import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_data_source.dart';

final class HomeRepositoryImpl implements HomeRepository {
  const HomeRepositoryImpl(this._remoteDataSource);

  final HomeRemoteDataSource _remoteDataSource;

  @override
  Future<Result<HomeContent>> getHome({
    required int page,
    int pageSize = 20,
  }) async {
    try {
      return Success(
        (await _remoteDataSource.getHome(
          page: page,
          pageSize: pageSize,
        )).toEntity(),
      );
    } on DioException catch (error) {
      final failure = error.requestOptions.extra['failure'];
      if (failure is Failure) return Error(failure);
      return const Error(
        NetworkFailure('A network error occurred. Please try again.'),
      );
    } on FormatException catch (error) {
      return Error(CacheFailure(error.message));
    } catch (_) {
      return const Error(
        UnknownFailure('Something went wrong while loading the store.'),
      );
    }
  }
}
