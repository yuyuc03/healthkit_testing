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

  double calorieGoal = 350;
  double exerciseGoal = 30;
  double stepGoal = 10000;

  List<HealthMetric> get metrics => _metrics;
  bool get isLoading => _isLoading;

  double get caloriesBurned {
    return _getMetricValue(HealthDataType.ACTIVE_ENERGY_BURNED);
  }

  double get exerciseMinutes {
    return _getMetricValue(HealthDataType.EXERCISE_TIME);
  }

  double get steps {
    return _getMetricValue(HealthDataType.STEPS);
  }

  HealthMetricsViewModel() {
    _initializeDefaultMetrics();
    _loadInitialData();
  }

  void _initializeDefaultMetrics() {
    _metrics = [
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
      HealthMetric(
        type: HealthDataType.BLOOD_GLUCOSE,
        unit: 'mmol/L',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.DIETARY_CHOLESTEROL,
        unit: 'mg',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.BLOOD_OXYGEN,
        unit: '%',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.RESPIRATORY_RATE,
        unit: 'breaths/min',
        value: 0,
      ),
      HealthMetric(
        type: HealthDataType.HEART_RATE,
        unit: 'BPM',
        value: 0,
      ),
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
        type: HealthDataType.STEPS,
        unit: 'steps',
        value: 0,
      ),
    ];
  }

  Future<void> _loadInitialData() async {
    try {
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
    try {
      _isLoading = true;
      notifyListeners();

      _initializeDefaultMetrics();

      final authorized = await _healthService.requestAuthorization();
      if (authorized) {
        final fetchedData = await _healthService.fetchHealthData();

        if (fetchedData.isNotEmpty) {
          await _databaseService.insertHealthMetrics(fetchedData);

          // Update metrics with new data
          for (var fetchedMetric in fetchedData) {
            final index =
                _metrics.indexWhere((m) => m.type == fetchedMetric.type);
            if (index != -1) {
              _metrics[index] = fetchedMetric;
            }
          }
        }
      }
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  double _getMetricValue(HealthDataType type) {
    final metric = _metrics.firstWhere(
      (m) => m.type == type,
      orElse: () => HealthMetric(type: type, unit: '', value: 0),
    );
    return metric.value ?? 0.0;
  }

  @override
  void dispose() {
    _databaseService.close();
    super.dispose();
  }
}
