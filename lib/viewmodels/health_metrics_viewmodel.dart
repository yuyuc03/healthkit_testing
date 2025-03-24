import 'package:flutter/foundation.dart';
import 'package:healthkit_integration_testing/providers/user_profile_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/health_service.dart';
import '../models/health_metric.dart';
import 'package:health/health.dart';
import '../services/database_service.dart';

typedef OnSignificantUpdateCallback = void Function();

class HealthMetricsViewModel extends ChangeNotifier {
  final HealthService _healthService;
  final DatabaseService _databaseService = DatabaseService();
  final UserProfileProvider _userProfileProvider;
  OnSignificantUpdateCallback? onSignificantUpdate;

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

  HealthMetricsViewModel(this._userProfileProvider)
      : _healthService = HealthService() {
    _initializeDefaultMetrics();
    _healthService.addListener(_onHealthServiceUpdate);
  }

  void _onHealthServiceUpdate() {
    refreshData();
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

        _healthService.startPeriodSync(
            _userId, _userProfileProvider.userProfile);

        Future.delayed(Duration(seconds: 5), () {
          _setupPeriodicDataCheck();
        });
      }

      _isInitialized = true;
    } catch (e) {
      print('Error during initialization: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _setupPeriodicDataCheck() {
    Future.delayed(Duration(minutes: 1), () async {
      await _checkForNewData();
      _setupPeriodicDataCheck();
    });
  }

  Future<void> _checkForNewData() async {
    try {
      bool hasUpdates = false;
      for (var type in _healthService.types) {
        final latestMetric = await _databaseService.getLatestMetric(type);
        if (latestMetric != null) {
          final index = _metrics.indexWhere((m) => m.type == latestMetric.type);
          if (index != -1) {
            if (_metrics[index].value != latestMetric.value ||
                _metrics[index].timestamp != latestMetric.timestamp) {
              _metrics[index] = latestMetric;
              print(
                  'Updated metric: ${latestMetric.type.name} to ${latestMetric.value}');
              hasUpdates = true;
            }
          }
        }
      }
      if (hasUpdates) {
        notifyListeners();
      }
    } catch (e) {
      print('Error checking for new data: $e');
    }
  }

  void _aggregateHealthData(List<HealthDataPoint> healthPoints) {
    Map<HealthDataType, List<HealthDataPoint>> groupedData = {};
    for (var point in healthPoints) {
      if (!groupedData.containsKey(point.type)) {
        groupedData[point.type] = [];
      }
      groupedData[point.type]!.add(point);
    }

    for (var type in groupedData.keys) {
      switch (type) {
        case HealthDataType.STEPS:
        case HealthDataType.ACTIVE_ENERGY_BURNED:
        case HealthDataType.EXERCISE_TIME:
          double total = 0;
          for (var point in groupedData[type]!) {
            total += _healthService.convertToStandardUnit(point);
          }
          _updateMetric(type, total, groupedData[type]!.first.unit.toString());
          break;

        case HealthDataType.HEART_RATE:
        case HealthDataType.BLOOD_OXYGEN:
        case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        case HealthDataType.BLOOD_GLUCOSE:
        case HealthDataType.RESPIRATORY_RATE:
          var latestPoint = groupedData[type]!
              .reduce((a, b) => a.dateFrom.isAfter(b.dateFrom) ? a : b);
          _updateMetric(type, _healthService.convertToStandardUnit(latestPoint),
              latestPoint.unit.toString());
          break;
        default:
          // Handle other types if needed
          break;
      }
    }
  }

  void _updateMetricsFromFetch(List<HealthMetric> fetchedData) {
    if (fetchedData.isEmpty) return;

    print('Processing ${fetchedData.length} new health metrics');

    for (var metric in fetchedData) {
      _updateMetric(metric.type, metric.value ?? 0.0, metric.unit);
    }

    notifyListeners();
  }

  void _updateMetric(HealthDataType type, double? value, String unit) {
    final index = _metrics.indexWhere((m) => m.type == type);
    if (index != -1) {
      _metrics[index] = HealthMetric(
        type: type,
        value: value,
        unit: unit,
        timestamp: DateTime.now(),
      );
      print('Updated metric: ${type.name} to $value $unit');
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

      await _healthService.initialize();
      final authorized = await _healthService.requestHealthPermissions();

      if (authorized) {
        final fetchedData = await _healthService.fetchHealthData(
            _userId, _userProfileProvider.userProfile);

        if (fetchedData.isNotEmpty) {
          _updateMetricsFromFetch(fetchedData);
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

      final authorized = await _healthService.requestHealthPermissions();
      if (authorized) {
        final fetchedData = await _healthService.fetchHealthData(
            _userId, _userProfileProvider.userProfile);

        if (fetchedData.isNotEmpty) {
          print(
              'Fetched ${fetchedData.length} new health data points from HealthKit');
          _updateMetricsFromFetch(fetchedData);
        } else {
          print('No new health data found in HealthKit');
        }
      }
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> checkHealthKitAccessibility() async {
    return await _healthService.isHealthKitAccessible();
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
    _healthService.removeListener(_onHealthServiceUpdate);
    _healthService.dispose();
    _databaseService.close();
    super.dispose();
  }
}
