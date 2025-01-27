import 'package:flutter/foundation.dart';
import '../services/health_service.dart';
import '../models/health_metric.dart';
import 'package:health/health.dart';
import '../services/database_service.dart';

class HealthMetricsViewModel extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  final DatabaseService _databaseService = DatabaseService();
  List<HealthMetric> _metrics = [];
  bool _isLoading = false;

  List<HealthMetric> get metrics => _metrics;
  bool get isLoading => _isLoading;

  HealthMetricsViewModel() {
    _initializeDefaultMetrics();
    _loadInitialData();
  }

  void _initializeDefaultMetrics() {
    _metrics = [
      HealthMetric(
        type: HealthDataType.ACTIVE_ENERGY_BURNED,
        unit: 'kcal',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.EXERCISE_TIME,
        unit: 'min',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.HEART_RATE,
        unit: 'BPM',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.BLOOD_OXYGEN,
        unit: '%',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.BLOOD_PRESSURE_SYSTOLIC,
        unit: 'mmHg',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.BLOOD_PRESSURE_DIASTOLIC,
        unit: 'mmHg',
        value: 0,
      ),
    ];
  }

  Future<void> _loadInitialData() async {
    try {
      await _databaseService.chechkDatabaseStatus();

      for (var metric in _metrics) {
        final storedData = await _databaseService.getLatestMetric(metric.type);
        if (storedData != null) {
          final index = _metrics.indexWhere((m) => m.type == storedData.type);
          if (index != -1) {
            _metrics[index] = storedData;
          }
        }
      }
      notifyListeners();
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> initializeHealth() async {
    try {
      _isLoading = true;
      notifyListeners();

      final authorized = await _healthService.requestAuthorization();
      if (authorized) {
        final fetchedData = await _healthService.fetchHealthData();

        await _databaseService.insertHealthMetrics(fetchedData);

        // Update existing metrics with fetched values and store in database
        for (var fetchedMetric in fetchedData) {
          final index =
              _metrics.indexWhere((m) => m.type == fetchedMetric.type);
          if (index != -1) {
            _metrics[index] = fetchedMetric;
          }
        }
      }
    } catch (e) {
      print('Error initializing health: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    await initializeHealth();
  }

  // Method to get historical data for ML processing
  Future<List<HealthMetric>> getHistoricalData(HealthDataType type) async {
    try {
      return await _databaseService.getHealthMetricsForML(type.name);
    } catch (e) {
      print('Error getting historical data: $e');
      return [];
    }
  }

  // Clean up resources when the viewmodel is disposed
  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}
