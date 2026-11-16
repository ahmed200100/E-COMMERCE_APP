import '../../../../core/network/dio_client.dart';
import '../models/home_models.dart';

abstract interface class HomeRemoteDataSource {
  Future<HomeResponseModel> getHome({required int page, required int pageSize});
}

final class HomeRemoteDataSourceImpl implements HomeRemoteDataSource {
  const HomeRemoteDataSourceImpl(this._client);

  final DioClient _client;

  @override
  Future<HomeResponseModel> getHome({
    required int page,
    required int pageSize,
  }) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'products',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('The home response was empty.');
    }
    return HomeResponseModel.fromJson(data);
  }
}
