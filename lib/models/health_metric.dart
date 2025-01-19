import 'package:health/health.dart';

class HealthMetric {
  final HealthDataType type;
  final double? value;
  final String unit;
  final DateTime timestamp;

  HealthMetric({
    required this.type,
    this.value,
    required this.unit,
    DateTime? timestamp,
  }) : this.timestamp = timestamp ?? DateTime.now();

  String get displayName {
    switch (type) {
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return "Activity Energy Burned";
      case HealthDataType.EXERCISE_TIME:
        return "Exercise Time";
      case HealthDataType.HEART_RATE:
        return "Heart Rate";
      case HealthDataType.BLOOD_OXYGEN:
        return "Blood Oxygen";
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        return "Blood Pressure (Systolic)";
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return "Blood Pressure (Diastolic)";
      default:
        return type.toString();
    }
  }

  String get unitDisplay {
    switch (type) {
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return 'kcal';
      case HealthDataType.EXERCISE_TIME:
        return 'min';
      case HealthDataType.HEART_RATE:
        return 'BPM';
      case HealthDataType.BLOOD_OXYGEN:
        return '%';
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return 'mmHg';
      default:
        return unit;
    }
  }
}
