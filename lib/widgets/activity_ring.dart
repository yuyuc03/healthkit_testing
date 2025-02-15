import 'package:flutter/material.dart';

class HealthRing extends StatelessWidget {
  final double caloriesValue;
  final double caloriesGoal;
  final double exerciseValue;
  final double exerciseGoal;
  final double stepValue;
  final double stepGoal;

  const HealthRing({
    required this.caloriesValue,
    required this.caloriesGoal,
    required this.exerciseValue,
    required this.exerciseGoal,
    required this.stepValue,
    required this.stepGoal,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Labels and Progress Text
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetricLabel("Calories", caloriesValue, caloriesGoal, Colors.pink),
            const SizedBox(height: 16),
            _buildMetricLabel("Exercise", exerciseValue, exerciseGoal, Colors.green),
            const SizedBox(height: 16),
            _buildMetricLabel("Step", stepValue, stepGoal, Colors.blue),
          ],
        ),
        
        CustomPaint(
          size: const Size(150, 150), 
          painter: HealthRingPainter(
            caloriesProgress: (caloriesValue / caloriesGoal).clamp(0.0, 1.0),
            exerciseProgress: (exerciseValue / exerciseGoal).clamp(0.0, 1.0),
            stepProgress: (stepValue / stepGoal).clamp(0.0, 1.0),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricLabel(String label, double value, double goal, Color color) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        children: [
          TextSpan(text: "$label\n", style: TextStyle(color: color)),
          TextSpan(
            text: "${value.toInt()} / ${goal.toInt()} ${_getUnit(label)}",
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }

  String _getUnit(String label) {
    switch (label) {
      case "Calories":
        return "KCAL";
      case "Exercise":
        return "MIN";
      case "Step":
        return "HRS";
      default:
        return "";
    }
  }
}

class HealthRingPainter extends CustomPainter {
  final double caloriesProgress;
  final double exerciseProgress;
  final double stepProgress;

  HealthRingPainter({
    required this.caloriesProgress,
    required this.exerciseProgress,
    required this.stepProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    final backgroundPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15;

    final caloriesPaint = Paint()
      ..color = Colors.pink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final exercisePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    final standPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 15
      ..strokeCap = StrokeCap.round;

    
    canvas.drawCircle(center, radius + 20, backgroundPaint);
    canvas.drawCircle(center, radius + 10, backgroundPaint);
    canvas.drawCircle(center, radius, backgroundPaint);

    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 20),
      -1.5 * 3.14,
      caloriesProgress * 2 * 3.14,
      false,
      caloriesPaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 10),
      -1.5 * 3.14,
      exerciseProgress * 2 * 3.14,
      false,
      exercisePaint,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5 * 3.14,
      stepProgress * 2 * 3.14,
      false,
      standPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
