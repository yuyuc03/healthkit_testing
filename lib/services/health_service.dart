import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';
import 'dart:async';

typedef OnDataFetchedCallback = void Function(List<HealthMetric> metrics);

class HealthService extends ChangeNotifier {
  final Health health = Health();
  final DatabaseService _databaseService = DatabaseService();
  bool _isInitialized = false;
  Timer? _syncTimer;
  String? _currentUserId;
  UserProfile? _currentUserProfile;
  
  // Add a callback field
  OnDataFetchedCallback? onDataFetched;

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

  Future<bool> initialize() async {
    if (!_isInitialized) {
      try {
        await _databaseService.initialize();

        bool authorized = await health.requestAuthorization(types);
        if (!authorized) {
          print("Failed to get HealthKit authorization during initialization");
          return false;
        }

        _isInitialized = true;
        return true;
      } catch (e) {
        print("Initialization error: $e");
        _isInitialized = false;
        return false;
      }
    }
    return _isInitialized;
  }

  void startPeriodSync(String userId, UserProfile? userProfile,
      {Duration interval = const Duration(seconds: 30), OnDataFetchedCallback? callback}) {
    _currentUserId = userId;
    _currentUserProfile = userProfile;
    onDataFetched = callback;

    _syncTimer?.cancel();
    
    _syncTimer = Timer.periodic(interval, (timer) {
      _performSync();
    });
    
    _performSync();
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _currentUserId = null;
    _currentUserProfile = null;
    onDataFetched = null;
  }

  Future<void> _performSync() async {
    if (_currentUserId != null) {
      final fetchedData = await fetchHealthData(_currentUserId!, _currentUserProfile);
      
      if (fetchedData.isNotEmpty && onDataFetched != null) {
        onDataFetched!(fetchedData);
      }
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

  Future<List<HealthMetric>> fetchHealthData(
      String userId, UserProfile? userProfile) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      bool authorized = await health.requestAuthorization(types);
      if (!authorized) {
        print("HealthKit authorization failed");
        return [];
      }

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 1));
      List<HealthMetric> healthMetrics = [];

      print('Attempting to fetch health data from ${startTime} to ${now}');
      
      List<HealthDataPoint> healthPoints = await health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );
      
      print('Health points fetched: ${healthPoints.length}');

      for (var point in healthPoints) {
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue.toDouble();
          if (value > 0) {
            final metric = HealthMetric(
              type: point.type,
              value: value,
              unit: point.unit.toString(),
              timestamp: point.dateFrom,
            );
            healthMetrics.add(metric);
            print('Processing health point: ${point.type.name}, value: $value, time: ${point.dateFrom}');
          }
        }
      }

      if (healthMetrics.isNotEmpty) {
        await _databaseService.insertHealthMetrics(
            healthMetrics, userId, userProfile);
        print(
            'Saved ${healthMetrics.length} health metrics to MongoDB for user $userId');

        for (var metric in healthMetrics) {
          print(
              'Saved: ${metric.type.name} - Value: ${metric.value} ${metric.unit} at ${metric.timestamp}');
        }
        notifyListeners();
      } else {
        print('No health metrics found to save');
      }
      return healthMetrics;
    } catch (e) {
      print("Fetch error: $e");
      return [];
    }
  }

  Future<Map<HealthDataType, bool>> verifyPermissions() async {
    Map<HealthDataType, bool> permissionStatus = {};
    
    for (var type in types) {
      bool? hasPermission = await health.hasPermissions([type]);
      permissionStatus[type] = hasPermission ?? false;
      print('Permission for ${type.name}: ${hasPermission ?? false}');
    }
    
    return permissionStatus;
  }

  Future<List<HealthMetric>> fetchHealthDataWithExtendedRange(
      String userId, UserProfile? userProfile) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      bool authorized = await health.requestAuthorization(types);
      if (!authorized) {
        print("HealthKit authorization failed");
        return [];
      }

      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 30));
      List<HealthMetric> healthMetrics = [];

      print('Attempting to fetch health data with extended range from ${startTime} to ${now}');
      
      List<HealthDataPoint> healthPoints = await health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );
      
      print('Health points fetched with extended range: ${healthPoints.length}');

      for (var point in healthPoints) {
        if (point.value is NumericHealthValue) {
          final value = (point.value as NumericHealthValue).numericValue.toDouble();
          if (value > 0) {
            final metric = HealthMetric(
              type: point.type,
              value: value,
              unit: point.unit.toString(),
              timestamp: point.dateFrom,
            );
            healthMetrics.add(metric);
          }
        }
      }

      if (healthMetrics.isNotEmpty) {
        await _databaseService.insertHealthMetrics(
            healthMetrics, userId, userProfile);
        print(
            'Saved ${healthMetrics.length} health metrics from extended range to MongoDB for user $userId');
        notifyListeners();
      }
      return healthMetrics;
    } catch (e) {
      print("Fetch error with extended range: $e");
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

  @override
  void dispose() {
    stopPeriodicSync();
    _databaseService.close();
    super.dispose();
  }
}
