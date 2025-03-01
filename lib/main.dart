import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/providers/user_profile_provider.dart';
import 'package:healthkit_integration_testing/screens/login_screen.dart';
import 'package:healthkit_integration_testing/screens/register_screen.dart';
import 'package:healthkit_integration_testing/viewmodels/health_metrics_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:healthkit_integration_testing/providers/healthkit_provider.dart';
import 'services/database_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  try {
    await dbService.initialize(); 
    print('MongoDB connection initialized successfully');
  } catch (e) {
    print('Error initializing MongoDB connection: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthKitProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProxyProvider<UserProfileProvider, HealthMetricsViewModel>(
          create: (context) => HealthMetricsViewModel(Provider.of<UserProfileProvider>(context, listen: false)
          ), update: (context, userProfileProvider, previous) => previous ?? HealthMetricsViewModel(userProfileProvider),
        ),
      ],
      
      child: MaterialApp(
        title: 'Health App',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: const LoginScreen(),
        routes: {
          '/login': (context) => LoginScreen(),
          '/register': (context) => RegisterScreen(),
        },
      ),
    );
  }
}
