import 'package:health/health.dart';

class UserProfile {
  final String userId;
  final int age;
  final int gender;
  final double height;
  final double weight;
  final double bmi;
  final bool smoke;
  final bool alco;
  final bool active;

  UserProfile({
    required this.userId,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    this.bmi = 0,
    required this.smoke,
    required this.alco,
    required this.active,
  });

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'bmi': calculateBMI(),
      'smoke': smoke ? 1 : 0,
      'alco': alco ? 1 : 0,
      'active': active ? 1 : 0,
    };
  }

  static UserProfile fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['user_id'],
      age: map['age'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      bmi: map['bmi'] ?? 0,
      smoke: map['smoke'] == 1,
      alco: map['alco'] == 1,
      active: map['active'] == 1,
    );
  }

  double calculateBMI() {
    if (height <= 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  static Future<UserProfile> fromHealthKit(String userId) async {
    final Health health = Health();

    await health.requestAuthorization([
      HealthDataType.HEIGHT,
      HealthDataType.WEIGHT,
      HealthDataType.BIRTH_DATE,
      HealthDataType.ACTIVE_ENERGY_BURNED,
      HealthDataType.GENDER,
    ]);

    double height = 170.0;
    double weight = 70.0;
    int age = 30;
    int gender = 1;
    bool active = false;

    try {
      List<HealthDataPoint> heightData = await health.getHealthDataFromTypes(
        types: [HealthDataType.HEIGHT],
        startTime: DateTime.now().subtract(Duration(days: 365)),
        endTime: DateTime.now(),
      );

      if (heightData.isNotEmpty &&
          heightData.first.value is NumericHealthValue) {
        height = (heightData.first.value as NumericHealthValue)
            .numericValue
            .toDouble();
      }

      List<HealthDataPoint> weightData = await health.getHealthDataFromTypes(
        types: [HealthDataType.WEIGHT],
        startTime: DateTime.now().subtract(Duration(days: 365)),
        endTime: DateTime.now(),
      );

      if (weightData.isNotEmpty &&
          weightData.first.value is NumericHealthValue) {
        weight = (weightData.first.value as NumericHealthValue)
            .numericValue
            .toDouble();
      }

      active = await _isUserActive(health);
    } catch (e) {
      print("Can't fetch profile data from HealthKit: $e");
    }

    return UserProfile(
      userId: userId,
      age: age,
      gender: gender,
      height: height,
      weight: weight,
      smoke: false,
      alco: false,
      active: active,
    );
  }

  static Future<bool> _isUserActive(Health health) async {
    try {
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(days: 7));

      List<HealthDataPoint> energyData = await health.getHealthDataFromTypes(
        types: [HealthDataType.ACTIVE_ENERGY_BURNED],
        startTime: startTime,
        endTime: DateTime.now(),
      );

      double totalCaloriesBurned = 0;
      for (var point in energyData) {
        if (point.value is NumericHealthValue) {
          totalCaloriesBurned +=
              (point.value as NumericHealthValue).numericValue.toDouble();
        }
      }

      return totalCaloriesBurned >= 2000;
    } catch (e) {
      print("Error determining activity level: $e");
      return false;
    }
  }
}
