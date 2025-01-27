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

  // Convert to Map for database operations
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

  // Create HealthMetric from Map (databse record)
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

  // For comparing health metrics
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

  // For debugging purposes
  @override
  String toString() {
    return 'HealthMetric{type: $type, value: $value, unit: $unit, timestamp: $timestamp, source: $source}';
  }
}
