import 'package:health/health.dart';

class HealthMetric {
  final int? id;
  final HealthDataType type;
  final double? value;
  final String unit;
  final DateTime timestamp;
  final String? source;

  HealthMetric({
    this.id,
    required this.type,
    this.value,
    required this.unit,
    DateTime? timestamp,
    this.source,
  }) : this.timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  static HealthMetric fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'],
      type: HealthDataType.values.firstWhere(
        (e) => e.name == map['type'],
      ),
      value: map['value'],
      unit: map['unit'],
      timestamp: DateTime.parse(map['timestamp']),
      source: map['source'],
    );
  }

  String get displayName {
    switch (type) {
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
        return "Blood Pressure (Systolic)";
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return "Blood Pressure (Diastolic)";
      case HealthDataType.BLOOD_GLUCOSE:
        return "Blood Glucose";
      case HealthDataType.DIETARY_CHOLESTEROL:
        return "Dietary Cholesterol";
      case HealthDataType.BLOOD_OXYGEN:
        return "Blood Oxygen";
      case HealthDataType.RESPIRATORY_RATE:
        return "Respiratory Rate";
      case HealthDataType.HEART_RATE:
        return "Heart Rate";
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return "Activity Energy Burned";
      case HealthDataType.EXERCISE_TIME:
        return "Exercise Time";
      case HealthDataType.STEPS:
        return "Steps";
      default:
        return type.toString();
    }
  }

  String get unitDisplay {
    switch (type) {
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return 'mmHg';
      case HealthDataType.BLOOD_GLUCOSE:
        return "mmol/L";
      case HealthDataType.DIETARY_CHOLESTEROL:
        return "mg";
      case HealthDataType.BLOOD_OXYGEN:
        return '%';
      case HealthDataType.RESPIRATORY_RATE:
        return "breaths/min";
      case HealthDataType.HEART_RATE:
        return 'BPM';
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return 'kcal';
      case HealthDataType.EXERCISE_TIME:
        return 'min';
      case HealthDataType.STEPS:
        return "steps";
      default:
        return unit;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthMetric &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value &&
          unit == other.unit &&
          timestamp == other.timestamp;

  @override
  int get hashCode =>
      type.hashCode ^ value.hashCode ^ unit.hashCode ^ timestamp.hashCode;

  @override
  String toString() {
    return 'HealthMetric{type: $type, value: $value, unit: $unit, timestamp: $timestamp, source: $source}';
  }
}
