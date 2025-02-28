import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';

class HealthKitProvider with ChangeNotifier {
  static const String healthKitKey = 'healthkit_connected';
  bool _isLoading = true;
  bool _healthKitConnected = false;

  bool get isLoading => _isLoading;
  bool get healthKitConnected => _healthKitConnected;

  HealthKitProvider() {
    _initializeHealthKitStatus();
  }

  Future<void> _initializeHealthKitStatus() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStatus = prefs.getBool(healthKitKey) ?? false;

      _healthKitConnected = savedStatus;

      // Verify with HealthKit
      Health health = Health();
      bool isAuthorized = await health.hasPermissions([
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
          ]) ??
          false;

      if (isAuthorized != savedStatus) {
        _healthKitConnected = isAuthorized;
        await prefs.setBool(healthKitKey, isAuthorized);
      }
    } catch (e) {
      print("Error initializing HealthKit status: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> connectHealthKit() async {
    _isLoading = true;
    notifyListeners();

    try {
      Health health = Health();
      bool authorized = await health.requestAuthorization([
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
      ]);

      _healthKitConnected = authorized;

      // Save connection status
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(healthKitKey, authorized);

      if (authorized) {
        print('HealthKit connected successfully');
      } else {
        print('Failed to connect to HealthKit');
      }
    } catch (e) {
      print("Error connecting to HealthKit: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
