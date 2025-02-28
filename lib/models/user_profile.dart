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
}
