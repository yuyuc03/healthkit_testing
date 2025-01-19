import 'package:health/health.dart';
import 'package:sqflite/sqflite.dart';
import '../models/health_metric.dart';
import '../database/database_helper.dart';

class HealthService {
  final Health health = Health();
  final DatabaseHelper _databaseHelper = DatabaseHelper();

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

          // Store data in database
          await _databaseHelper.insertHealthMetric(metric);
        }
      }
      return healthMetrics;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  // Retrieve stored data (maybe used for ML later)
  Future<List<HealthMetric>> getStoredHealthData(HealthDataType type) async {
    final Database db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_metrics',
      where: 'type = ?',
      whereArgs: [type.name],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return HealthMetric(
        type: HealthDataType.values.firstWhere(
          (e) => e.name == maps[i]['type'],
        ),
        value: maps[i]['value'],
        unit: maps[i]['unit'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
      );
    });
  }
}
