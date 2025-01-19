import 'package:health/health.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/health_metric.dart';
import 'dart:async';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  bool _isDatabaseInitialized = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    print('Initializing database......'); // For Debug purpose
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'health_metrics.db');

    print('Databse path: $path'); // Debug

    try {
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: (Database db, int version) async {
          print('Creating database tables...'); // Debug
          await db.execute('''
          CREATE TABLE health_metrics (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            value DOUBLE NOT NULL,
            unit TEXT NOT NULL,
            timestamp INTEGER NOT NULL,
            source TEXT NOT NULL
          )
        ''');
          _isDatabaseInitialized = true;
          print('Databse tables create successfully'); // Debug
        },
        onOpen: (Database db) {
          print('Database opened successfully');
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
      final tables = await db.query('sqlite_master', 
          where: 'type = ?', 
          whereArgs: ['table']);
      
      print('Database initialized: $_isDatabaseInitialized');
      print('Available tables: ${tables.map((t) => t['name']).toList()}');
      
      // Check if our table exists
      final healthMetricsExists = tables.any((table) => table['name'] == 'health_metrics');
      print('health_metrics table exists: $healthMetricsExists');
      
      if (healthMetricsExists) {
        final count = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM health_metrics')
        );
        print('Number of records in health_metrics: $count');
      }
    } catch (e) {
      print('Error checking database status: $e');
    }
  }

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

  Future<HealthMetric?> getLatestMetric(HealthDataType type) async {
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
      return HealthMetric(
        type: maps[i]['type'],
        value: maps[i]['value'],
        unit: maps[i]['unit'],
        timestamp: DateTime.fromMillisecondsSinceEpoch(maps[i]['timestamp']),
      );
    });
  }
}
