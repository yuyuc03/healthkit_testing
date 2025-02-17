import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized;

  final dbService = DatabaseService();
  try {
    await dbService.database;
    await dbService.checkDatabaseStatus();
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
      home: const LoginScreen(),
    );
  }
}
//
