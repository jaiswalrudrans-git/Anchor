import 'package:flutter/material.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_container.dart';

/// Habits tab placeholder screen.
class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habits'),
      ),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: EmptyState(
            icon: Icons.repeat_outlined,
            title: 'Habits & Streaks',
            message: 'Daily habit tracking and consistency grids will be displayed here in Stage 4.',
          ),
        ),
      ),
    );
  }
}
