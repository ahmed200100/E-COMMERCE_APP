abstract final class ApiConstants {
  /// Set API_BASE_URL for staging/production, or API_HOST for a local device.
  /// Examples:
  ///   flutter run --dart-define=API_HOST=192.168.1.25
  ///   flutter build apk --dart-define=API_BASE_URL=https://https://dummyjson.com/v1
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const _configuredHost = String.fromEnvironment('API_HOST');
  static const _configuredPort = String.fromEnvironment(
    'API_PORT',
    defaultValue: '3000',
  );
  static const _configuredPath = String.fromEnvironment(
    'API_PATH',
    defaultValue: '/v1',
  );

  static String get baseUrl {
    if (_configuredHost.isNotEmpty) {
      return _withTrailingSlash(
        'http://$_configuredHost:$_configuredPort$_configuredPath',
      );
    }
    if (_configuredBaseUrl.isNotEmpty) {
      return _withTrailingSlash(_configuredBaseUrl);
    }
    return 'https://dummyjson.com/';
  }

  static String _withTrailingSlash(String value) =>
      value.endsWith('/') ? value : '$value/';

  static const connectTimeout = Duration(seconds: 30);
  static const receiveTimeout = Duration(seconds: 30);
  static const sendTimeout = Duration(seconds: 30);
  static const maxRetries = 2;
}
