import '../../../../core/result/result.dart';
import '../entities/home_entities.dart';

abstract interface class HomeRepository {
  Future<Result<HomeContent>> getHome({required int page, int pageSize = 20});
}
