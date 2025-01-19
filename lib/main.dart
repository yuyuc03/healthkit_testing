import 'package:flutter/material.dart';
import './screens/home_page/home_screen.dart';
import 'database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized;

  final dbHelper = DatabaseHelper();
  try {
    await dbHelper.database;
    await dbHelper.checkDatabaseStatus();
    print('Database initialized successfully');
  } catch (e) {
    print('Error initialzing database: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Health App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
      ),
      home: HomeScreen(),
    );
  }
}
