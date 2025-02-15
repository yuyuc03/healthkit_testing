import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../models/health_metric.dart';

class HealthMetricsCard extends StatelessWidget {
  final HealthMetric metric;

  const HealthMetricsCard({Key? key, required this.metric}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF6F6FE), 
        borderRadius: BorderRadius.circular(16), 
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), 
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), 
          ),
        ],
      ),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  metric.displayName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple, 
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                _getIconForMetric(metric.type),
                color: Colors.deepPurple[900],
                size: 20, 
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                metric.value?.toStringAsFixed(1) ?? '- -',
                style: TextStyle(
                  fontSize: 28,
                  color: metric.value != null
                      ? Colors.black
                      : Colors.grey, 
                ),
              ),
              const SizedBox(width: 4),
              Text(
                metric.unitDisplay,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.blueGrey, 
                ),
              ),
            ],
          ),
        ],
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
