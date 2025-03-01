import 'package:health/health.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';

class HealthService {
  final Health health = Health();
  final DatabaseService _databaseService = DatabaseService();
  bool _isInitialized = false;

  final List<HealthDataType> types = [
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
    HealthDataType.BLOOD_GLUCOSE,
    HealthDataType.DIETARY_CHOLESTEROL,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.STEPS,
  ];

  Future<void> initialize() async {
    if (!_isInitialized) {
      await _databaseService.initialize();
      _isInitialized = true;
    }
  }

  Future<bool> requestAuthorization() async {
    try {
      await initialize();
      return await health.requestAuthorization(types);
    } catch (e) {
      print("Authorization error: $e");
      return false;
    }
  }

  Future<List<HealthMetric>> fetchHealthData(String userId, UserProfile? userProfile) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 1));
      List<HealthMetric> healthMetrics = [];

      List<HealthDataPoint> healthPoints = await health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );

      for (var point in healthPoints) {
        if (point.value is NumericHealthValue) {
          final metric = HealthMetric(
            type: point.type,
            value: (point.value as NumericHealthValue).numericValue.toDouble(),
            unit: point.unit.toString(),
            timestamp: point.dateFrom,
          );
          healthMetrics.add(metric);
        }
      }

      if (healthMetrics.isNotEmpty) {
        await _databaseService.insertHealthMetrics(healthMetrics, userId, userProfile);
        print('Saved ${healthMetrics.length} health metrics to MongoDB for user $userId');

        for (var metric in healthMetrics) {
          print(
              'Saved: ${metric.type.name} - Value: ${metric.value} ${metric.unit} at ${metric.timestamp}');
        }
      }
      return healthMetrics;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  Future<HealthMetric?> getLatestHealthData(HealthDataType type) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }
      return await _databaseService.getLatestMetric(type);
    } catch (e) {
      print("Error getting latest health data: $e");
      return null;
    }
  }

  Future<bool> isUserActive() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 7));

      List<HealthDataPoint> stepsData = await health.getHealthDataFromTypes(
        types: [HealthDataType.STEPS],
        startTime: startTime,
        endTime: now,
      );

      List<HealthDataPoint> exerciseData = await health.getHealthDataFromTypes(
        types: [HealthDataType.EXERCISE_TIME],
        startTime: startTime,
        endTime: now,
      );

      List<HealthDataPoint> energyData = await health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startTime,
        endTime: now,
      );

      double totalSteps = 0;
      double totalExerciseMinutes = 0;
      double totalCaloriesBurned = 0;

      for (var point in stepsData) {
        if (point.value is NumericHealthValue) {
          totalSteps +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      for (var point in exerciseData) {
        if (point.value is NumericHealthValue) {
          totalExerciseMinutes +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      for (var point in energyData) {
        if (point.value is NumericHealthValue) {
          totalCaloriesBurned +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      return totalExerciseMinutes >= 150 ||
          totalSteps >= 70000 ||
          totalCaloriesBurned >= 2000;
    } catch (e) {
      print("Error determining activity level: $e");
      return false;
    }
  }

  Future<void> dispose() async {
    await _databaseService.close();
  }
}
