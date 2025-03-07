import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/health_metrics_viewmodel.dart';
import '../../widgets/health_metrics_card.dart';
import '../../widgets/activity_ring.dart';
import './profile_screen.dart';
import '../providers/user_profile_provider.dart';
import 'dart:async';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final apiService = ApiService();
  String _suggestion = '';
  Timer? _timer;
  bool _isLoading = false;
  double _riskProbability = 0.0;
  int _prediction = 0;
  DateTime _lastUpdated = DateTime.now();

  void fetchPredictionAndSuggestion() async {
  if (mounted) {
    setState(() {
      _isLoading = true;
    });
  }
  try {
    try {
      final prediction = await apiService.fetchPrediction();
      print('Prediction: ${prediction['prediction']}');
      print('Risk Probability: ${prediction['risk_probability']}');

      if (mounted) {
        setState(() {
          _prediction = prediction['prediction'];
          _riskProbability = prediction['risk_probability'];
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      print('Error fetching prediction: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('current_user_id');
    print('User ID from SharedPreferences: $userId');

    if (userId != null && userId.isNotEmpty) {
      try {
        final response = await apiService.fetchSuggestion(userId);
        print('Suggestion API response status: ${response.statusCode}');
        print('Suggestion API response body: ${response.body}');

        if (response.statusCode == 200) {
          if (mounted) {
            setState(() {
              _suggestion = json.decode(response.body)['suggestion'];
              _isLoading = false;
            });
          }
        } else {
          print('Error response from suggestion API: ${response.body}');
          if (mounted) {
            setState(() {
              _suggestion = "Error: ${response.statusCode} - ${response.body}";
              _isLoading = false;
            });
          }
        }
      } catch (e) {
        print('Error fetching suggestion: $e');
        if (mounted) {
          setState(() {
            _suggestion = "Error fetching suggestion: $e";
            _isLoading = false;
          });
        }
      }
    } else {
      print('User ID not found or empty');
      if (mounted) {
        setState(() {
          _suggestion = "Error: User ID not found";
          _isLoading = false;
        });
      }
    }
  } catch (e) {
    print('General error in fetchPredictionAndSuggestion: $e');
    if (mounted) {
      setState(() {
        _suggestion = "An error occurred: $e";
        _isLoading = false;
      });
    }
  }
}

  void _startPeriodicFetching() {
    _timer?.cancel();
    
    fetchPredictionAndSuggestion();
    
    _timer = Timer.periodic(Duration(minutes: 2), (timer) {
      fetchPredictionAndSuggestion();
    });
  }

  @override
  void initState() {
    super.initState();
    _startPeriodicFetching();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = HealthMetricsViewModel(
            Provider.of<UserProfileProvider>(context, listen: false));
        Future.delayed(Duration.zero, () => viewModel.initialize());
        return viewModel;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<HealthMetricsViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                Positioned(
                  left: -size.width * 0.5,
                  top: -size.width * 0.5,
                  child: Container(
                    height: 450,
                    width: 450,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xB3C7B6FF),
                          Color(0xFFFFFFFF),
                        ],
                        stops: [0.3, 0.9],
                      ),
                    ),
                  ),
                ),
                RefreshIndicator(
                  onRefresh: () async {
                    await viewModel.refreshData();
                  },
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: GestureDetector(
                              onTap: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => ProfileScreen()),
                                );
                              },
                              child: CircleAvatar(
                                radius: 27,
                                backgroundImage:
                                    AssetImage('assets/images/profile_pic.jpg'),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Text(
                              'Hello, Yuyu!',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1B4B),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'How Do You Feel Today?',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D1B4B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(0.3),
                                const Color(0xFF8871E5).withOpacity(0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          height: 80,
                          child: Text(
                            _suggestion.isNotEmpty
                                ? _suggestion
                                : 'Fetching suggestion.....',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF1D1B4B),
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(left: 20),
                          child: const Text(
                            'Activity Status',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D1B4B),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 16.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.3),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: HealthRing(
                              caloriesValue: viewModel.caloriesBurned,
                              caloriesGoal: viewModel.calorieGoal,
                              exerciseValue: viewModel.exerciseMinutes,
                              exerciseGoal: viewModel.exerciseGoal,
                              stepValue: viewModel.steps,
                              stepGoal: viewModel.stepGoal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(left: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Health Overview',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D1B4B),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: viewModel.metrics.length,
                          itemBuilder: (context, index) {
                            return HealthMetricsCard(
                              metric: viewModel.metrics[index],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }
}
