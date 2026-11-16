class AppConstants {
  AppConstants._();

  static const String appName = 'dbug';
  /// Must match APPLICATION_ID in linux/CMakeLists.txt.
  static const String appId = 'zm.co.cloud.dbug';
  static const String appVersion = '0.2.1';

  static const String dbName = 'dbug.db';
  static const int dbVersion = 8;

  static const int defaultMockPort = 3001;
  static const Duration defaultTimeout = Duration(seconds: 30);
}
