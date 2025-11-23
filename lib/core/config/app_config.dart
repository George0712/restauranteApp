/// Configuración del entorno de la aplicación
class AppConfig {
  final String environment;
  final bool isProduction;
  final String appName;

  AppConfig({
    required this.environment,
    required this.isProduction,
    required this.appName,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    _instance ??= AppConfig(
      environment: 'dev',
      isProduction: false,
      appName: 'Restaurante DEV',
    );
    return _instance!;
  }

  static void initialize({
    required String environment,
    required bool isProduction,
    required String appName,
  }) {
    _instance = AppConfig(
      environment: environment,
      isProduction: isProduction,
      appName: appName,
    );
  }
}
