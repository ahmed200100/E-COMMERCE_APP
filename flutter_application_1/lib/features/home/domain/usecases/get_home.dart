import '../../../../core/result/result.dart';
import '../entities/home_entities.dart';
import '../repositories/home_repository.dart';

final class GetHome {
  const GetHome(this._repository);

  final HomeRepository _repository;

  Future<Result<HomeContent>> call({required int page}) =>
      _repository.getHome(page: page);
}
