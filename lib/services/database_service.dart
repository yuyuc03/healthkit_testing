// database_service.dart
import 'package:health/health.dart';
import 'package:healthkit_integration_testing/models/user_profile.dart';
import 'package:mongo_dart/mongo_dart.dart';
import '../models/health_metric.dart';

class DatabaseService {
  late Db? _db;
  late DbCollection? _healthCollection;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      try {
        _db = await Db.create('mongodb+srv://yuyucheng2003:2yjbDeyUfi2GF8KI@healthmetrics.z6rit.mongodb.net/?retryWrites=true&w=majority&appName=HealthMetrics');
        await _db!.open();
        _healthCollection = _db!.collection('health_metrics');
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

  Future<void> insertHealthMetrics(List<HealthMetric> metrics, String userId, UserProfile? userProfile) async {
    await checkDatabaseStatus();
    if (metrics.isEmpty) return;

    try {
      final timestamp = metrics.first.timestamp;
      final metricsMap = <String, Map<String, dynamic>>{};
      
      for (var metric in metrics) {
        metricsMap[metric.type.name] = {
          'value': metric.value,
          'unit': metric.unit
        };
      }

      final document = {
        'timestamp': timestamp.toIso8601String(),
        'user_id': userId,
        'metrics': metricsMap,
        'updated_at': DateTime.now().toIso8601String()
      };

      if (userProfile != null) {
        document['user_profile'] = {
          'age': userProfile.age,
          'gender': userProfile.gender,
          'height': userProfile.height,
          'weight': userProfile.weight,
          'bmi': userProfile.calculateBMI(),
          'smoke': userProfile.smoke ? 1 : 0,
          'alco': userProfile.alco ? 1 : 0,
          'active': userProfile.active ? 1 : 0,
        };
      }

      await _healthCollection!.update(
        where
          .eq('timestamp', document['timestamp'])
          .eq('user_id', document['user_id']),
        document,
        upsert: true
      );
    } catch (e) {
      print('Error inserting health metrics: $e');
      rethrow;
    }
  }

  Future<HealthMetric?> getLatestMetric(HealthDataType type) async {
    await checkDatabaseStatus();
    
    try {
      final results = await _healthCollection!
          .find()
          .toList();

      if (results.isEmpty) return null;

      results.sort((a, b) => 
        DateTime.parse(b['timestamp']).compareTo(DateTime.parse(a['timestamp']))
      );

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

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _isInitialized = false;
    }
  }
}
