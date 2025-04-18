import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';

class HealthKitProvider with ChangeNotifier {
  final HealthService healthService = HealthService();
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

      if (savedStatus) {
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

        if (!isAuthorized) {
          _healthKitConnected = false;
          await prefs.setBool(healthKitKey, false);
        }
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

  Future<void> disconnectHealthKit() async {
    _isLoading = true;
    notifyListeners();

    try {
      _healthKitConnected = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(healthKitKey, false);

      healthService.stopPeriodicSync();

      print('HealthKit disconnected successfully');
    } catch (e) {
      print("Error disconnecting from HealthKit: $e");
      throw e; 
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
