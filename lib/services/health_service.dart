import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import '../models/health_metric.dart';
import '../services/database_service.dart';
import 'dart:async';

class HealthService extends ChangeNotifier {
  final Health health = Health();
  final DatabaseService _databaseService = DatabaseService();
  bool _isInitialized = false;
  Timer? _syncTimer;
  String? _currentUserId;
  UserProfile? _currentUserProfile;

  // Define all health data types we want to track
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

        bool authorized = await requestHealthPermissions();
        if (!authorized) {
          print("Failed to get HealthKit authorization during initialization");
          return false;
        }

        await setupBackgroundDelivery();

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

  Future<bool> requestHealthPermissions() async {
    try {
      return await health.requestAuthorization(types,
          permissions: List.filled(
            types.length,
            HealthDataAccess.READ,
          ));
    } catch (e) {
      print("Permission request error: $e");
      return false;
    }
  }

  Future<void> setupBackgroundDelivery() async {
    try {
      print("Setting up background delivery with native implementation");

      const platform =
          MethodChannel('com.example.healthkitIntegrationTesting/background');

      platform.setMethodCallHandler((call) async {
        if (call.method == 'healthDataUpdated') {
          print("Received health data update from native code");
          if (_currentUserId != null) {
            final metrics = await _performSync();

            notifyListeners();
          }
        }
      });

      final bool result =
          await platform.invokeMethod('setupHealthKitObservers');
      print("Background delivery setup completed: $result");
    } catch (e) {
      print("Error setting up background delivery: $e");
    }
  }

  void startPeriodSync(String userId, UserProfile? userProfile,
      {Duration interval = const Duration(seconds: 30)}) {
    _currentUserId = userId;
    _currentUserProfile = userProfile;

    stopPeriodicSync();

    _syncTimer = Timer.periodic(interval, (timer) async {
      try {
        await _performSync();
        print("Periodic sync completed successfully at ${DateTime.now()}");
      } catch (e) {
        print("Error during periodic sync: $e");
      }
    });
    _performSync();
  }

  void stopPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _currentUserId = null;
    _currentUserProfile = null;
  }

  Future<List<HealthMetric>> _performSync() async {
    print("Starting health data sync at ${DateTime.now()}");
    List<HealthMetric> updatedMetrics = [];

    if (_currentUserId != null) {
      try {
        updatedMetrics =
            await fetchHealthData(_currentUserId!, _currentUserProfile);
        print("Synced ${updatedMetrics.length} health metrics");
        for (var metric in updatedMetrics) {
          print("  - ${metric.type.name}: ${metric.value} ${metric.unit}");
        }
      } catch (e) {
        print("Sync error: $e");
      }
    } else {
      print("No user ID available for sync");
    }

    return updatedMetrics;
  }

  Future<bool> isHealthKitAccessible() async {
    try {
      final testTypes = [HealthDataType.STEPS];
      final now = DateTime.now();
      final yesterday = now.subtract(Duration(days: 1));

      final authorized = await health.requestAuthorization(testTypes);
      if (!authorized) return false;

      final data = await health.getHealthDataFromTypes(
        types: testTypes,
        startTime: yesterday,
        endTime: now,
      );

      return data.isNotEmpty;
    } catch (e) {
      print("HealthKit accessibility check failed: $e");
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
      final startTime = now.subtract(const Duration(hours: 24));
      List<HealthMetric> healthMetrics = [];

      List<HealthDataPoint> healthPoints = await health.getHealthDataFromTypes(
        types: types,
        startTime: startTime,
        endTime: now,
      );

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
              if (point.value is NumericHealthValue) {
                total += convertToStandardUnit(point);
              }
            }
            healthMetrics.add(HealthMetric(
              type: type,
              value: total,
              unit: groupedData[type]!.first.unit.toString(),
              timestamp: now,
            ));
            break;

          case HealthDataType.HEART_RATE:
          case HealthDataType.BLOOD_OXYGEN:
          case HealthDataType.RESPIRATORY_RATE:
          case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
          case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
          case HealthDataType.BLOOD_GLUCOSE:
          case HealthDataType.DIETARY_CHOLESTEROL:
            if (groupedData[type]!.isNotEmpty) {
              var latestPoint = groupedData[type]!
                  .reduce((a, b) => a.dateFrom.isAfter(b.dateFrom) ? a : b);

              if (latestPoint.value is NumericHealthValue) {
                healthMetrics.add(HealthMetric(
                  type: type,
                  value: convertToStandardUnit(latestPoint),
                  unit: latestPoint.unit.toString(),
                  timestamp: latestPoint.dateFrom,
                ));
              }
            }
            break;

          default:
            if (groupedData[type]!.isNotEmpty &&
                groupedData[type]!.first.value is NumericHealthValue) {
              var point = groupedData[type]!.first;
              healthMetrics.add(HealthMetric(
                type: type,
                value: convertToStandardUnit(point),
                unit: point.unit.toString(),
                timestamp: point.dateFrom,
              ));
            }
            break;
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
      }
      return healthMetrics;
    } catch (e) {
      print("Health data fetch error: $e");
      return [];
    }
  }

  double convertToStandardUnit(HealthDataPoint point) {
    if (point.value is NumericHealthValue) {
      double value =
          (point.value as NumericHealthValue).numericValue.toDouble();

      switch (point.type) {
        case HealthDataType.HEART_RATE:
          return value;
        case HealthDataType.STEPS:
          return value;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          return point.unit.toString().contains("J") ? value / 4184 : value;
        case HealthDataType.EXERCISE_TIME:
          // Convert to minutes if needed
          return point.unit.toString().contains("s") ? value / 60 : value;
        case HealthDataType.BLOOD_OXYGEN:
          return value > 1 ? value : value * 100;
        case HealthDataType.BLOOD_GLUCOSE:
          return point.unit.toString().contains("mmol/L")
              ? value
              : value / 18.0;
        case HealthDataType.DIETARY_CHOLESTEROL:
          return point.unit.toString().toLowerCase().contains("gram") ||
                  point.unit.toString().contains("g") ||
                  point.unit.toString().contains("GRAM")
              ? value * 1000
              : value;

        default:
          return value;
      }
    }
    return 0;
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
          totalSteps += convertToStandardUnit(point);
        }
      }

      for (var point in exerciseData) {
        if (point.value is NumericHealthValue) {
          totalExerciseMinutes += convertToStandardUnit(point);
        }
      }

      for (var point in energyData) {
        if (point.value is NumericHealthValue) {
          totalCaloriesBurned += convertToStandardUnit(point);
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
    stopPeriodicSync();
    await _databaseService.close();
  }
}
