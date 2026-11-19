class AppConfig {
  /// Toggle between mock remote datasource and real remote datasource in future
  static const bool useMockApi = bool.fromEnvironment('USE_MOCK', defaultValue: true);

  /// Allows testing network/server errors from Settings page
  static bool simulateErrors = false;

  /// Artificial network delay in milliseconds for MockRemoteDataSource (default 100ms for fast UI)
  static int artificialDelayMs = 100;

  /// Application Name
  static const String appName = 'TurnirPro';
  static const String appVersion = '1.0.0';
}

