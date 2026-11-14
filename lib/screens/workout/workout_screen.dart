import 'package:flutter/material.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_container.dart';

/// Workout tab placeholder screen.
class WorkoutScreen extends StatelessWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
      ),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: EmptyState(
            icon: Icons.fitness_center_outlined,
            title: 'Workout Splits',
            message: 'Weekly workout splits and exercise logs will be managed here in Stage 6.',
          ),
        ),
      ),
    );
  }
}
