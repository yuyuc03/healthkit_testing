// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/health_metrics_viewmodel.dart';
import 'components/health_metrics_card.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => HealthMetricsViewModel()..initializeHealth(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Dashboard'),
          actions: [
            Consumer<HealthMetricsViewModel>(
              builder: (context, viewModel, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: viewModel.isLoading
                      ? null
                      : () => viewModel.refreshData(),
                );
              },
            ),
          ],
        ),
        body: Consumer<HealthMetricsViewModel>(
          builder: (context, viewModel, child) {
            return Stack(
              children: [
                ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  itemCount: viewModel.metrics.length,
                  itemBuilder: (context, index) {
                    return HealthMetricsCard(
                      metric: viewModel.metrics[index],
                    );
                  },
                ),
                if (viewModel.isLoading)
                  Container(
                    color: Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
