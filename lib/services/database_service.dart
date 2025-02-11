import 'package:health/health.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_metric.dart';
import 'dart:async';
import 'dart:io';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;

  DatabaseService._internal();

  bool _isDatabaseInitialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    print('Initializing database......');
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    // Get the project's root directory
    final String currentDirectory = Directory.current.path;

    // Define the database path in the current directory
    final String dbPath = join(currentDirectory, 'health_metrics.db');
    print('Database will be created at: $dbPath'); //Debug

    try {
      final db = await openDatabase(
        dbPath,
        version: 1,
        onCreate: (Database db, int version) async {
          print('Creating database tables......'); //Debug
          await db.execute('''
          CREATE TABLE health_metrics(
          id INTEGER PRIMARY KEY AUTOINCREMENT
          type TEXT NOT NULL
          value DOUBLE NOT NULL
          unit TEXT NOT NULL
          timestamp INTEGER NOT NULL
          source TEXT NOT NULL
        )''');
          print('Databse opened successfully at $dbPath');
          _isDatabaseInitialized = true;
        },
        onOpen: (Database db) {
          print('Database opened successfully at $dbPath');
          _isDatabaseInitialized = true;
        },
      );
      return db;
    } catch (e) {
      print('Error initializing database: $e'); // Debug
      rethrow;
    }
  }

  Future<void> checkDatabaseStatus() async {
    try {
      final db = await database;
      final tables = await db
          .query('sqlite_master', where: 'type = ?', whereArgs: ['table']);
      print('Database initialized: $_isDatabaseInitialized');
      print('Available tables: ${tables.map((t) => t['name']).toList()}');

      final healthMetricsExists =
          tables.any((table) => table['name'] == 'health_metrics');
      print('health_metrics table exists: $healthMetricsExists');

      if (healthMetricsExists) {
        final count = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM health_metrics'));
        print('Number of records in health_metrics: $count');
      }
    } catch (e) {
      print('Error checking database status: $e');
    }
  }

  // Insert multiple data in a batch
  Future<bool> insertHealthMetrics(List<HealthMetric> metrics) async {
    final Database db = await database;
    try {
      await db.transaction((txn) async {
        Batch batch = txn.batch();
        for (var metric in metrics) {
          batch.insert(
            'health_metrics',
            {
              'type': metric.type.name,
              'value': metric.value,
              'unit': metric.unit,
              'timestamp': metric.timestamp.millisecondsSinceEpoch,
              'source': 'HealthKit'
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        await batch.commit(noResult: true);
      });
      return true;
    } catch (e) {
      print('Error inserting health metrics: $e');
      return false;
    }
  }

  // Insert single health metric
  Future<int> insertHealthMetric(HealthMetric metric) async {
    final Database db = await database;
    return await db.insert(
      'health_metrics',
      {
        'type': metric.type.name,
        'value': metric.value,
        'unit': metric.unit,
        'timestamp': metric.timestamp.millisecondsSinceEpoch,
        'source': 'HealthKit'
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get latest metric for a specific type
  Future<HealthMetric?> getLatestMetric(HealthDataType type) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> result = await db.query(
        'health_metrics',
        where: 'type = ?',
        whereArgs: [type.name],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (result.isNotEmpty) {
        return HealthMetric(
          type: type,
          value: result.first['value'],
          unit: result.first['unit'],
          timestamp:
              DateTime.fromMillisecondsSinceEpoch(result.first['timestamp']),
        );
      }
      return null;
    } catch (e) {
      print('Error getting latest metric: $e');
      return null;
    }
  }

  // Get metrics by date range
  Future<List<HealthMetric>> getMetricsByDateRange(
    HealthDataType type,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'health_metrics',
        where: 'type = ? AND timestamp BETWEEN ? AND ?',
        whereArgs: [
          type.name,
          startDate.millisecondsSinceEpoch,
          endDate.millisecondsSinceEpoch
        ],
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) {
        return HealthMetric(
          type: type,
          value: maps[i]['value'],
          unit: maps[i]['unit'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        );
      });
    } catch (e) {
      print('Error getting metrics by date range: $e');
      return [];
    }
  }

  Future<List<HealthMetric>> getHealthMetricsForML(String type,
      {int limit = 100}) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'health_metrics',
      where: 'type = ?',
      whereArgs: [type],
      orderBy: 'timestamp DESC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      try {
        return HealthMetric(
          type: HealthDataType.values.firstWhere(
            (e) => e.name == maps[i]['type'],
          ),
          value: maps[i]['value'],
          unit: maps[i]['unit'],
          timestamp: DateTime.fromMicrosecondsSinceEpoch(maps[i]['timestamp']),
        );
      } catch (e) {
        print('Error parsing health data type ${maps[i]['type']}');
        return HealthMetric(
          type: HealthDataType.STEPS,
          value: maps[i]['value'],
          unit: maps[i]['unit'],
          timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
        );
      }
    });
  }

  // Delete records
  Future<int> deleteOldRecords(DateTime beforeDate) async {
    try {
      final Database db = await database;
      return await db.delete(
        'health_metrics',
        where: 'timestamp <?',
        whereArgs: [beforeDate.millisecondsSinceEpoch],
      );
    } catch (e) {
      print('Error deleting old records: $e');
      return 0;
    }
  }

  // Close Database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
