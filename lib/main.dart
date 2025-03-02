import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/providers/user_profile_provider.dart';
import 'package:healthkit_integration_testing/screens/login_screen.dart';
import 'package:healthkit_integration_testing/screens/register_screen.dart';
import 'package:healthkit_integration_testing/viewmodels/health_metrics_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:healthkit_integration_testing/providers/healthkit_provider.dart';
import 'services/database_service.dart';
import './services/health_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dbService = DatabaseService();
  try {
    await dbService.initialize();
    print('MongoDB connection initialized successfully');
  } catch (e) {
    print('Error initializing MongoDB connection: $e');
  }

  final healthService = HealthService();

  runApp(MyApp(healthService: healthService));
}

class MyApp extends StatelessWidget {
  final HealthService healthService;

  const MyApp({Key? key, required this.healthService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => HealthKitProvider()),
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProxyProvider<UserProfileProvider,
            HealthMetricsViewModel>(
          create: (context) => HealthMetricsViewModel(
              Provider.of<UserProfileProvider>(context, listen: false)),
          update: (context, userProfileProvider, previous) =>
              previous ?? HealthMetricsViewModel(userProfileProvider),
        ),
        Provider.value(value: healthService),
      ],
      child: MaterialApp(
        title: 'Health App',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
          scaffoldBackgroundColor: Colors.grey[100],
        ),
        home: LoginScreen(healthService: healthService),
        routes: {
          '/login': (context) => LoginScreen(healthService: healthService),
          '/register': (context) => RegisterScreen(),
        },
      ),
    );
  }
}
