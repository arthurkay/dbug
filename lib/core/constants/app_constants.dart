class AppConstants {
  AppConstants._();

  static const String appName = 'dbug';
  static const String appVersion = '1.0.0';

  static const String dbName = 'dbug.db';
  static const int dbVersion = 2;

  static const int defaultMockPort = 3001;
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration historyRetention = Duration(days: 30);

  static const int maxHistoryItems = 5000;
  static const int maxRecentRequests = 20;
}
