import 'package:health/health.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/health_metric.dart';
import '../services/database_service.dart';

class HealthService {
  final Health health = Health();
  final DatabaseService _databaseService = DatabaseService();

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

  Future<List<HealthMetric>> getStoredHealthData(HealthDataType type) async {
    try {
      return await _databaseService.getHealthMetricsForML(type.name);
    } catch (e) {
      print("Error getting stored health data: $e");
      return [];
    }
  }

  Future<Map<String, dynamic>> prepareHealthDataForPrediction() async {
    try {
      final now = DateTime.now();
      final latestData = await Future.wait([
        getLatestHealthData(HealthDataType.BLOOD_PRESSURE_SYSTOLIC),
        getLatestHealthData(HealthDataType.BLOOD_PRESSURE_DIASTOLIC),
        getLatestHealthData(HealthDataType.BLOOD_GLUCOSE),
        getLatestHealthData(HealthDataType.DIETARY_CHOLESTEROL),
        getLatestHealthData(HealthDataType.HEART_RATE),
        getLatestHealthData(HealthDataType.ACTIVE_ENERGY_BURNED),
      ]);

      return {
        'ap_hi': latestData[0]?.value,
        'ap_lo': latestData[1]?.value,
        'gluc': _mapGlucoseLevel(latestData[2]?.value),
        'cholesterol': _mapCholesterolLevel(latestData[3]?.value),
        'heart_rate': latestData[4]?.value,
        'active': latestData[5]?.value != null ? 1 : 0,
      };
    } catch (e) {
      print("Error preparing health data for prediction: $e");
      return {};
    }
  }

  Future<Map<String, dynamic>> getPrediction() async {
    final healthData = await prepareHealthDataForPrediction();
    if (healthData.isEmpty) {
      return {'error': 'No recent health data available'};
    }

    try {
      final response = await http.post(
        Uri.parse('http://your-fastapi-server:8000/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(healthData)
      );

      if (response.statusCode == 200) {
        final prediction = jsonDecode(response.body);
        return prediction;
      } else {
        return {'error': 'Failed to get prediction'};
      }
    } catch (e) {
      print("Error getting prediction: $e");
      return {'error': e.toString()};
    }
  }

  int _mapGlucoseLevel(double? value) {
    if (value == null) return 1;
    if (value < 100) return 1;      // Normal
    if (value < 126) return 2;      // Above Normal
    return 3;                       // Well Above Normal
  }

  int _mapCholesterolLevel(double? value) {
    if (value == null) return 1;
    if (value < 200) return 1;      // Normal
    if (value < 240) return 2;      // Above Normal
    return 3;                       // Well Above Normal
  }

  Future<void> dispose() async {
    await _databaseService.close();
  }
}
