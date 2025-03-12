class AppConfig {
  static String get mongoUri => const String.fromEnvironment(
        'MONGO_URI',
        defaultValue: 'mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics',
      );
}
