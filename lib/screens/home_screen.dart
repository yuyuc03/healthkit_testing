import 'package:flutter/material.dart';
import 'package:healthkit_integration_testing/services/api_service.dart';
import 'package:healthkit_integration_testing/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../viewmodels/health_metrics_viewmodel.dart';
import '../../widgets/health_metrics_card.dart';
import '../../widgets/activity_ring.dart';
import './profile_screen.dart';
import '../providers/user_profile_provider.dart';
import 'ai_chat_screen.dart';
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
  Timer? _refreshTimer;
  bool _isLoading = false;
  double _riskProbability = 0.0;
  int _prediction = 0;
  DateTime _lastUpdated = DateTime.now();
  String _fullName = 'User';
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

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

        int predictionValue = (prediction['prediction'] is double)
            ? (prediction['prediction'] as double).toInt()
            : prediction['prediction'];

        double riskProbability = (prediction['risk_probability'] is int)
            ? (prediction['risk_probability'] as int).toDouble()
            : prediction['risk_probability'];

        if (mounted) {
          setState(() {
            _prediction = predictionValue;
            _riskProbability = riskProbability;
            _lastUpdated = DateTime.now();
          });
        }

        if (predictionValue == 1) {
          final notificationService =
              Provider.of<NotificationService>(context, listen: false);

          final bool? permissionGranted =
              await notificationService.requestIOSPermissions();

          if (permissionGranted == true) {
            await notificationService.showHeartDiseaseWarningNotification();
            print('Heart disease risk notification sent');
          } else {
            print('Notification permission not granted');
          }
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
                _suggestion =
                    "Error: ${response.statusCode} - ${response.body}";
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

    _timer = Timer.periodic(Duration(seconds: 40), (timer) {
      fetchPredictionAndSuggestion();
    });
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();

    // Initial refresh
    _refreshHealthData();

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      _refreshHealthData();
    });
  }

  void _refreshHealthData() {
    if (mounted) {
      print('Performing periodic health data refresh');
      // Trigger refresh indicator programmatically
      _refreshIndicatorKey.currentState?.show();
      // Or directly call refreshData
      Provider.of<HealthMetricsViewModel>(context, listen: false)
          .refreshData()
          .then((_) {
        print('Health data refresh completed');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _startPeriodicFetching();
    _startPeriodicRefresh();
    _loadUserName();
  }

  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (context) {
        final viewModel = HealthMetricsViewModel(
            Provider.of<UserProfileProvider>(context, listen: false));
        Future.delayed(Duration.zero, () {
          viewModel.initialize();
        });
        return viewModel;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Consumer<HealthMetricsViewModel>(
          builder: (context, viewModel, child) {
            print(
                'Rebuilding HomeScreen with metrics hash: ${viewModel.metrics.hashCode}');
            return Stack(
              key: ValueKey(viewModel.metrics.hashCode),
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
                  key: _refreshIndicatorKey,
                  onRefresh: () async {
                    print('Manual refresh triggered');
                    await viewModel.refreshData();
                    print('Manual refresh completed');
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
                          children: [
                            Text(
                              'Hello, $_fullName!',
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
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    _getRiskIcon(),
                                    color: _getRiskColor(),
                                    size: 24,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _prediction == 0
                                        ? 'Healthy'
                                        : 'Heart Disease - ${_getRiskLevel()}',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: _getRiskColor(),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _prediction == 0
                                        ? 'Health Status:'
                                        : 'Risk of Heart Disease:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF1D1B4B),
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Stack(
                                    children: [
                                      Container(
                                        height: 10,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.grey.withOpacity(0.3),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                      Container(
                                        height: 10,
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.8 *
                                                (_prediction == 0
                                                    ? 1.0
                                                    : _riskProbability),
                                        decoration: BoxDecoration(
                                          color: _getRiskColor(),
                                          borderRadius:
                                              BorderRadius.circular(5),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    _prediction == 0
                                        ? 'Healthy'
                                        : '${(_riskProbability * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1D1B4B),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              GestureDetector(
                                onTap: () => _showSuggestionDialog(),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates,
                                      size: 18,
                                      color: Colors.deepPurple,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'View Suggestions',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.deepPurple,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
                              Padding(
                                padding: const EdgeInsets.only(right: 20.0),
                                child: Text(
                                  'Last updated: ${_formatLastUpdated()}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
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

  String _formatLastUpdated() {
    return "${_lastUpdated.hour}:${_lastUpdated.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final fullName = prefs.getString('user_full_name') ?? 'User';

      if (mounted) {
        setState(() {
          _fullName = fullName;
        });
      }
    } catch (e) {
      print('Error loading user name: $e');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }

  IconData _getRiskIcon() {
    if (_prediction == 0) {
      return Icons.check_circle;
    } else if (_riskProbability < 0.3) {
      return Icons.info_outline;
    } else if (_riskProbability < 0.6) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  Color _getRiskColor() {
    if (_prediction == 0) {
      return Colors.green;
    } else if (_riskProbability < 0.3) {
      return Colors.blue;
    } else if (_riskProbability < 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getRiskLevel() {
    print('Getting risk level for probability: $_riskProbability');
    if (_prediction == 0) {
      return 'Healthy';
    } else if (_riskProbability < 0.3) {
      return 'Low Risk';
    } else if (_riskProbability < 0.6) {
      return 'Medium Risk';
    } else {
      return 'High Risk';
    }
  }

  void _showSuggestionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.all(20),
          contentPadding: EdgeInsets.only(left: 20, right: 20, bottom: 0),
          title: Row(
            children: [
              Icon(Icons.health_and_safety, color: Colors.deepPurple),
              SizedBox(width: 12),
              Text('Health Suggestions'),
            ],
          ),
          content: Container(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _suggestion.isNotEmpty
                      ? _buildStructuredSuggestions(_suggestion)
                      : Text('Fetching suggestions...'),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AIChatScreen()));
                    },
                    icon: Icon(Icons.chat, color: Colors.white),
                    label: Text('Chat with Health Assistant'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        );
      },
    );
  }

  Widget _buildStructuredSuggestions(String suggestionData) {
    try {
      // Parse JSON
      final parsed = json.decode(suggestionData);

      // Check if the structure matches what we expect
      if (parsed.containsKey('suggestions')) {
        final suggestions =
            List<Map<String, dynamic>>.from(parsed['suggestions']);

        // Build UI from structured data
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: suggestions.map((suggestion) {
            final number = suggestion['number'];
            final text = suggestion['text'];

            return Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        number.toString(),
                        style: TextStyle(
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.4,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      }
    } catch (e) {
      print("Error parsing suggestion data: $e");
      // Debug the actual content
      print("Raw suggestion data: $_suggestion");
    }

    // Fallback to displaying the text directly if parsing fails
    return Text(_suggestion);
  }
}
