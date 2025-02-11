import 'package:health/health.dart';
import 'package:sqflite/sqflite.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';

class HealthService {
  final Health health = Health();
  final DatabaseService _databaseService = DatabaseService();

  final List<HealthDataType> types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
    HealthDataType.HEART_RATE,
    HealthDataType.BLOOD_OXYGEN,
    HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
    HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
  ];

  Future<bool> requestAuthorization() async {
    try {
      return await health.requestAuthorization(types);
    } catch (e) {
      print("Authorization error: $e");
      return false;
    }
  }

  Future<List<HealthMetric>> fetchHealthData() async {
    final now = DateTime.now();
    final startTime = now.subtract(const Duration(days: 1));
    List<HealthMetric> healthMetrics = [];

    try {
      await _databaseService.checkDatabaseStatus();

      List<HealthDataPoint> healthPoint = await health.getHealthDataFromTypes(
          types: types, startTime: startTime, endTime: now);

      for (var point in healthPoint) {
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
        await _databaseService.insertHealthMetrics(healthMetrics);
      }
      return healthMetrics;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  // Get data for a specific type within a date range
  Future<List<HealthMetric>> getHealthDataByDateRange(
    HealthDataType type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      return await _databaseService.getMetricsByDateRange(
        type,
        startDate,
        endDate,
      );
    } catch (e) {
      print("Error getting health data by date range: $e");
      return [];
    }
  }

  Future<HealthMetric?> getLatestHealthData(HealthDataType type) async {
    try {
      return await _databaseService.getLatestMetric(type);
    } catch (e) {
      print("Error getting latest health data: $e");
      return null;
    }
  }

  // Retrieve stored data (maybe used for ML later)
  Future<List<HealthMetric>> getStoredHealthData(HealthDataType type) async {
    try {
      return await _databaseService.getHealthMetricsForML(type.name);
    } catch (e) {
      print("Error getting stored health data: $e");
      return [];
    }
  }

  Future<void> dispose() async {
    await _databaseService.close();
  }
}
