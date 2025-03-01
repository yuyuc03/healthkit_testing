import 'package:flutter/foundation.dart';
import 'package:healthkit_integration_testing/providers/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_service.dart';
import '../models/health_metric.dart';
import 'package:health/health.dart';
import '../services/database_service.dart';

class HealthMetricsViewModel extends ChangeNotifier {
  final HealthService _healthService = HealthService();
  final DatabaseService _databaseService = DatabaseService();
  final UserProfileProvider _userProfileProvider;

  List<HealthMetric> _metrics = [];
  bool _isLoading = false;
  String _userId = '';
  bool _isInitialized = false;

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

  HealthMetricsViewModel(this._userProfileProvider) {
    _initializeDefaultMetrics();
  }

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _isLoading = true;
      notifyListeners();
      
      await _initializeUserId();
      await _loadInitialData();
      
      if (_userId.isNotEmpty) {
        await initializeHealth();
      }
      
      _isInitialized = true;
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('current_user_id') ?? '';
      if (_userId.isEmpty) {
        print('Warning: User ID not found');
      } else {
        print('User ID initialized successfully: $_userId');
      }
    } catch (e) {
      print('Error initializing user ID: $e');
    }
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

      if (_userId.isEmpty) {
        await _initializeUserId();
        
        if (_userId.isEmpty) {
          print('Cannot initialize health: No user ID found');
          return;
        }
      }

      final authorized = await _healthService.requestAuthorization();
      if (authorized) {
        final fetchedData = await _healthService.fetchHealthData(
            _userId, _userProfileProvider.userProfile);

        if (fetchedData.isNotEmpty) {
          await _databaseService.insertHealthMetrics(
              fetchedData, _userId, _userProfileProvider.userProfile);

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

      if (!_isInitialized) {
        await initialize();
        return;
      }

      if (_userId.isEmpty) {
        await _initializeUserId();
        
        if (_userId.isEmpty) {
          print('Cannot refresh data: No user ID found');
          return;
        }
      }

      _initializeDefaultMetrics();
      final authorized = await _healthService.requestAuthorization();
      if (authorized) {
        final fetchedData = await _healthService.fetchHealthData(
            _userId, _userProfileProvider.userProfile);

        if (fetchedData.isNotEmpty) {
          await _databaseService.insertHealthMetrics(
              fetchedData, _userId, _userProfileProvider.userProfile);

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
