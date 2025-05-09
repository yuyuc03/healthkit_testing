import 'package:health/health.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import '../models/health_metric.dart';
import '../config/app_config.dart';

class DatabaseService {
  late mongo.Db? _db;
  late mongo.DbCollection? _healthCollection;
  late mongo.DbCollection? _mlModelCollection;
  late mongo.DbCollection? _userProfileCollection;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        _db = await mongo.Db.create(AppConfig.mongoUri);
        await _db!.open();
        _healthCollection = _db!.collection('health_metrics');
        _mlModelCollection = _db!.collection('ml_model_data');
        _userProfileCollection = _db!.collection('user_profiles');
        _isInitialized = true;

        await _healthCollection!
            .createIndex(keys: {'timestamp': 1, 'user_id': 1}, unique: true);
      } catch (e) {
        print('Database initialization error: $e');
        _isInitialized = false;
        rethrow;
      }
    }
  }

  Future<void> checkDatabaseStatus() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  Future<UserProfile?> getUserProfile(String userId) async {
    await checkDatabaseStatus();
    try {
      final result = await _userProfileCollection!
          .findOne(mongo.where.eq('user_id', userId));
      if (result != null) {
        return UserProfile.fromMap(result);
      }
      return null;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> insertHealthMetrics(List<HealthMetric> metrics, String userId,
      UserProfile? userProfile) async {
    await checkDatabaseStatus();
    if (metrics.isEmpty) return;

    try {
      final latestUserProfile = await getUserProfile(userId);

      final Map<HealthDataType, HealthMetric> latestMetrics = {};

      for (var metric in metrics) {
        final existingMetric = latestMetrics[metric.type];
        if (existingMetric == null ||
            metric.timestamp.isAfter(existingMetric.timestamp)) {
          latestMetrics[metric.type] = metric;
          print(
              "Selected latest metric: ${metric.type} - Value: ${metric.value} at ${metric.timestamp}");
        }
      }

      final mlMetrics = <String, dynamic>{};
      DateTime latestTimestamp = DateTime.now();

      // Process only the latest metrics for each type
      for (var metric in latestMetrics.values) {
        if (metric.timestamp.isAfter(latestTimestamp)) {
          latestTimestamp = metric.timestamp;
        }

        switch (metric.type) {
          case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
            mlMetrics['ap_hi'] = metric.value;
            break;
          case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
            mlMetrics['ap_lo'] = metric.value;
            break;
          case HealthDataType.DIETARY_CHOLESTEROL:
            double cholValue = metric.value ?? 0;
            int cholCategory = 1; // Low: < 200 mg
            if (cholValue >= 200 && cholValue < 300) {
              cholCategory = 2; // Borderline high: 200-300 mg
            } else if (cholValue >= 300) {
              cholCategory = 3; // High: >= 300 mg
            }
            mlMetrics['chol'] = cholCategory;
            break;

          case HealthDataType.BLOOD_GLUCOSE:
            double glucValue = metric.value ?? 0;
            int glucCategory = 1; // Normal: < 5.6 mmol/L
            if (glucValue >= 5.6 && glucValue < 7.0) {
              glucCategory = 2; // Prediabetic: 5.6-7.0 mmol/L
            } else if (glucValue >= 7.0) {
              glucCategory = 3; // Diabetic: >= 7.0 mmol/L
            }
            mlMetrics['gluc'] = glucCategory;
            break;

          default:
            break;
        }
      }

      final timestamp = DateTime.now().toIso8601String();
      final metricsMap = <String, Map<String, dynamic>>{};

      for (var metric in metrics) {
        metricsMap[metric.type.name] = {
          'value': metric.value,
          'unit': metric.unit,
          'recorded_at': metric.timestamp.toIso8601String()
        };
      }

      final healthDocument = {
        'timestamp': timestamp,
        'user_id': userId,
        'metrics': metricsMap,
      };

      if (userProfile != null) {
        healthDocument['user_profile'] = {
          'age': userProfile.age,
          'gender': userProfile.gender,
          'height': userProfile.height,
          'weight': userProfile.weight,
          'bmi': userProfile.calculateBMI(),
          'smoke': userProfile.smoke ? 1 : 0,
          'alco': userProfile.alco ? 1 : 0,
          'active': userProfile.active ? 1 : 0
        };
      }
      await _healthCollection!.insertOne(healthDocument);

      if (mlMetrics.containsKey('ap_hi') &&
          mlMetrics.containsKey('ap_lo') &&
          latestUserProfile != null) {
        if (!mlMetrics.containsKey('cholesterol')) {
          mlMetrics['cholesterol'] = 1;
          print("Added default cholesterol value");
        }
        if (!mlMetrics.containsKey('gluc')) {
          mlMetrics['gluc'] = 1;
          print("Added default glucose value");
        }

        final orderedMLData = {
          'timestamp': latestTimestamp.toIso8601String(),
          'user_id': userId,
          'age': latestUserProfile.age?.toDouble() ?? 0.0,
          'gender': latestUserProfile.gender ?? 0,
          'height': latestUserProfile.height ?? 0.0,
          'weight': latestUserProfile.weight ?? 0.0,
          'bmi': latestUserProfile.calculateBMI() ?? 0.0,
          'ap_hi': mlMetrics['ap_hi'],
          'ap_lo': mlMetrics['ap_lo'],
          'cholesterol': mlMetrics['cholesterol'],
          'gluc': mlMetrics['gluc'],
          'smoke': latestUserProfile.smoke == true ? 1 : 0,
          'alco': latestUserProfile.alco == true ? 1 : 0,
          'active': latestUserProfile.active == true ? 1 : 0
        };

        await _mlModelCollection!.insertOne(orderedMLData);
        print("ML data inserted with latest values: $orderedMLData");
      }
    } catch (e) {
      print('Error inserting health metrics: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfileAndMLData(UserProfile updatedProfile) async {
    await checkDatabaseStatus();

    try {
      await _userProfileCollection!.update(
          mongo.where.eq('user_id', updatedProfile.userId),
          updatedProfile.toMap(),
          upsert: true);

      final latestMetrics = await getLatestHealthMetrics(updatedProfile.userId);

      await insertHealthMetrics(
          latestMetrics, updatedProfile.userId, updatedProfile);

      print("User profile and ML data updated successfully");
    } catch (e) {
      print("Error updating user profile and ML data: $e");
      rethrow;
    }
  }

  Future<List<HealthMetric>> getLatestHealthMetrics(String userId) async {
    await checkDatabaseStatus();

    try {
      final results = await _healthCollection!
          .find(mongo.where.eq('user_id', userId))
          .toList();

      if (results.isEmpty) return [];

      results.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      final latestDoc = results.first;
      final metricsMap = latestDoc['metrics'] as Map<String, dynamic>;

      return metricsMap.entries.map((entry) {
        return HealthMetric(
          type: HealthDataType.values
              .firstWhere((e) => e.toString() == 'HealthDataType.${entry.key}'),
          value: entry.value['value'],
          unit: entry.value['unit'],
          timestamp: DateTime.parse(latestDoc['timestamp']),
        );
      }).toList();
    } catch (e) {
      print('Error getting latest health metrics: $e');
      return [];
    }
  }

  Future<HealthMetric?> getLatestMetric(HealthDataType type) async {
    await checkDatabaseStatus();

    try {
      final results = await _healthCollection!.find().toList();

      if (results.isEmpty) return null;

      results.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      final latestDoc = results.first;
      if (!latestDoc['metrics'].containsKey(type.name)) return null;

      final metricData = latestDoc['metrics'][type.name];

      return HealthMetric(
        type: type,
        value: metricData['value'],
        unit: metricData['unit'],
        timestamp: DateTime.parse(latestDoc['timestamp']),
      );
    } catch (e) {
      print('Error getting latest metric: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getMLModelData(String userId,
      {int limit = 100}) async {
    await checkDatabaseStatus();

    try {
      final results = await _mlModelCollection!
          .find(mongo.where.eq('user_id', userId))
          .take(limit)
          .toList();
      return results;
    } catch (e) {
      print('Error getting ML Model data: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getLatestMlReadyData(String userId) async {
    await checkDatabaseStatus();

    try {
      final results = await _mlModelCollection!
          .find(mongo.where.eq('user_id', userId))
          .toList();

      if (results.isEmpty) return null;

      results.sort((a, b) => DateTime.parse(b['timestamp'])
          .compareTo(DateTime.parse(a['timestamp'])));

      return results.first;
    } catch (e) {
      print('Error getting latest ML-ready data: $e');
      return null;
    }
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _isInitialized = false;
    }
  }
}
