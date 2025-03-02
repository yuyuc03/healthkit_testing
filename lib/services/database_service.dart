import 'package:health/health.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/health_metric.dart';

class DatabaseService {
  late Db? _db;
  late DbCollection? _healthCollection;
  late DbCollection? _mlModelCollection;
  late DbCollection? _userProfileCollection;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        _db = await Db.create(
            'mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics');
        await _db!.open();
        _healthCollection = _db!.collection('health_metrics');
        _mlModelCollection = _db!.collection('ml_model_data');
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

  Future<void> insertHealthMetrics(List<HealthMetric> metrics, String userId,
      UserProfile? userProfile) async {
    await checkDatabaseStatus();
    if (metrics.isEmpty) return;

    try {
      final timestamp = DateTime.now().toIso8601String();
      final metricsMap = <String, Map<String, dynamic>>{};
      final mlMetrics = <String, dynamic>{};

      for (var metric in metrics) {
        metricsMap[metric.type.name] = {
          'value': metric.value,
          'unit': metric.unit
        };

        switch (metric.type) {
          case HealthDataType.BLOOD_PRESSURE_SYSTOLIC:
            mlMetrics['ap_hi'] = metric.value;
            break;
          case HealthDataType.BLOOD_PRESSURE_DIASTOLIC:
            mlMetrics['ap_lo'] = metric.value;
            break;
          case HealthDataType.DIETARY_CHOLESTEROL:
            double cholValue = metric.value ?? 0;
            int cholCategory = 1;
            if (cholValue > 200 && cholValue <= 240) {
              cholCategory = 2;
            } else if (cholValue > 240) {
              cholCategory = 3;
            }
            mlMetrics['cholesterol'] = cholCategory;
            break;
          case HealthDataType.BLOOD_GLUCOSE:
            double glucValue = metric.value ?? 0;
            int glucCategory = 1;
            if (glucValue >= 100 && glucValue < 126) {
              glucCategory = 2;
            } else if (glucValue >= 126) {
              glucCategory = 3;
            }
            mlMetrics['gluc'] = glucCategory;
            break;
          default:
            break;
        }
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
          userProfile != null) {
        if (!mlMetrics.containsKey('cholesterol')) {
          mlMetrics['cholesterol'] = 1;
          print("Added default cholesterol value");
        }
        if (!mlMetrics.containsKey('gluc')) {
          mlMetrics['gluc'] = 1;
          print("Added default glucose value");
        }

        final orderedMLData = {
          'timestamp': timestamp,
          'user_id': userId,
          'age': userProfile.age.toDouble(),
          'gender': userProfile.gender,
          'height': userProfile.height,
          'weight': userProfile.weight,
          'bmi': userProfile.calculateBMI(),
          'ap_hi': mlMetrics['ap_hi'],
          'ap_lo': mlMetrics['ap_lo'],
          'cholesterol': mlMetrics['cholesterol'],
          'gluc': mlMetrics['gluc'],
          'smoke': userProfile.smoke ? 1 : 0,
          'alco': userProfile.alco ? 1 : 0,
          'active': userProfile.active ? 1 : 0
        };
        await _mlModelCollection!.insertOne(orderedMLData);
        print("ML data inserted: $orderedMLData");
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
          where.eq('user_id', updatedProfile.userId), updatedProfile.toMap(),
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
      final results =
          await _healthCollection!.find(where.eq('user_id', userId)).toList();

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
          .find(where.eq('user_id', userId))
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
      final results =
          await _mlModelCollection!.find(where.eq('user_id', userId)).toList();

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
