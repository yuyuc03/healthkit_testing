import 'package:flutter/material.dart';
import 'package:health/health.dart';
import '../models/health_metric.dart';

class HealthMetricsCard extends StatelessWidget {
  final HealthMetric metric;

  const HealthMetricsCard({Key? key, required this.metric}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate appropriate font sizes based on available width
        final titleSize = constraints.maxWidth * 0.075;
        final valueSize = constraints.maxWidth * 0.12;
        final unitSize = constraints.maxWidth * 0.06;

        return Container(
          decoration: BoxDecoration(
            color: Color(0xFFF6F6FE),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.2),
                spreadRadius: 1,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          margin: EdgeInsets.all(constraints.maxWidth * 0.02),
          padding: EdgeInsets.all(constraints.maxWidth * 0.04),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Icon(
                  _getIconForMetric(metric.type),
                  size: constraints.maxWidth * 0.14,
                  color: _getColorForMetric(metric.type),
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.03),
              Flexible(
                child: Text(
                  metric.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(height: constraints.maxHeight * 0.03),
              Flexible(
                flex: 2,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _formatValue(metric.value),
                        style: TextStyle(
                          fontSize: valueSize,
                          fontWeight: FontWeight.bold,
                          color: _getColorForMetric(metric.type),
                        ),
                      ),
                      SizedBox(width: 2),
                      Text(
                        metric.unitDisplay,
                        style: TextStyle(
                          fontSize: unitSize,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatValue(double? value) {
    if (value == null) return "0";
    // Handle specific formatting based on metric type
    if (metric.type == HealthDataType.BLOOD_GLUCOSE ||
        metric.type == HealthDataType.BLOOD_OXYGEN) {
      return value.toStringAsFixed(1);
    }
    return value.toInt().toString();
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
  Color _getColorForMetric(HealthDataType type) {
    switch (type) {
      case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
      case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
      case HealthDataType.HEART_RATE:
        return Colors.red;
      case HealthDataType.BLOOD_GLUCOSE:
        return Colors.orange;
      case HealthDataType.DIETARY_CHOLESTEROL:
        return Colors.amber;
      case HealthDataType.BLOOD_OXYGEN:
        return Colors.blue;
      case HealthDataType.RESPIRATORY_RATE:
        return Colors.indigo;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return Colors.deepOrange;
      case HealthDataType.EXERCISE_TIME:
        return Colors.green;
      case HealthDataType.STEPS:
        return Colors.teal;
      default:
        return Colors.deepPurple;
    }
  }
}
