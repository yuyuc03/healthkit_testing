import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../../../models/health_metric.dart';

class HealthMetricsCard extends StatelessWidget {
  final HealthMetric metric;

  const HealthMetricsCard({Key? key, required this.metric}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  metric.displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  _getIconForMetric(metric.type),
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  metric.value?.toStringAsFixed(1) ?? '- -',
                  style: TextStyle(
                    fontSize: 24,
                    color: metric.value != null ? Colors.black : Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  metric.unitDisplay,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForMetric(HealthDataType type) {
    switch (type) {
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
        return Icons.speed;
      case HealthDataType.BLOOD_GLUCOSE:
        return Icons.bloodtype;
      case HealthDataType.DIETARY_CHOLESTEROL:
        return Icons.restaurant;
      case HealthDataType.BLOOD_OXYGEN:
        return Icons.air;
      case HealthDataType.RESPIRATORY_RATE:
        return Icons.air;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return Icons.local_fire_department;
      case HealthDataType.EXERCISE_TIME:
        return Icons.timer;
      case HealthDataType.HEART_RATE:
        return Icons.favorite;
      case HealthDataType.STEPS:
        return Icons.directions_walk;
      default:
        return Icons.health_and_safety;
    }
  }
}
