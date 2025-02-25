import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/health_metrics_viewmodel.dart';
import '../../widgets/health_metrics_card.dart';
import '../../widgets/activity_ring.dart';


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return ChangeNotifierProvider(
      create: (_) => HealthMetricsViewModel()..initializeHealth(),
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
                              onTap: () {
                                print("Profile button tapped");
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
