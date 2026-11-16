import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_constants.dart';
import 'auth_token_storage.dart';
import '../error/failures.dart';

final class DioClient {
  DioClient({required this._tokenStorage})
    : dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          sendTimeout: ApiConstants.sendTimeout,
          responseType: ResponseType.json,
          headers: {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.addAll([
      _AuthInterceptor(_tokenStorage),
      _RetryInterceptor(dio),
      _ErrorInterceptor(),
      if (kDebugMode) PrettyDioLogger(),
    ]);
  }

  final AuthTokenStorage _tokenStorage;
  final Dio dio;
}

final class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._tokenStorage);

  final AuthTokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.readToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}

final class _RetryInterceptor extends Interceptor {
  _RetryInterceptor(this._dio);

  final Dio _dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final count = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
    if (count >= ApiConstants.maxRetries || !_isTransient(err)) {
      handler.next(err);
      return;
    }
    err.requestOptions.extra['retryCount'] = count + 1;
    await Future<void>.delayed(
      Duration(milliseconds: 250 * math.pow(2, count).toInt()),
    );
    try {
      handler.resolve(await _dio.fetch<dynamic>(err.requestOptions));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  bool _isTransient(DioException error) =>
      error.type == DioExceptionType.connectionTimeout ||
      error.type == DioExceptionType.connectionError ||
      error.type == DioExceptionType.receiveTimeout ||
      (error.response?.statusCode != null &&
          error.response!.statusCode! >= 500);
}

final class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    err.requestOptions.extra['failure'] = DioFailureMapper.fromException(err);
    handler.next(err);
  }
}

abstract final class DioFailureMapper {
  static Failure fromException(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return const UnauthorizedFailure('Your session has expired.');
    }
    if (statusCode != null && statusCode >= 400 && statusCode < 500) {
      return ValidationFailure(
        _serverMessage(error) ?? 'The request could not be completed.',
        code: '$statusCode',
      );
    }
    if (statusCode != null && statusCode >= 500) {
      return ServerFailure(
        'The server is temporarily unavailable.',
        code: '$statusCode',
      );
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => const NetworkFailure(
        'The connection timed out. Please try again.',
      ),
      DioExceptionType.connectionError => const NetworkFailure(
        'Unable to reach the server. Check your network connection.',
      ),
      _ => const NetworkFailure('A network error occurred. Please try again.'),
    };
  }

  static String? _serverMessage(DioException error) {
    final data = error.response?.data;
    return data is Map<String, dynamic> && data['message'] is String
        ? data['message'] as String
        : null;
  }
}

final class PrettyDioLogger extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.uri}');
    if (options.queryParameters.isNotEmpty) {
      debugPrint('  query: ${options.queryParameters}');
    }
    if (options.data != null) {
      debugPrint('  body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    debugPrint(
      '← ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '× ${err.type.name} ${err.requestOptions.method} ${err.requestOptions.uri}',
    );
    debugPrint('  message: ${err.message}');
    handler.next(err);
  }
}
