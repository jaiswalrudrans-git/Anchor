import 'package:flutter/material.dart';

/// Placeholder slot for Workout Strip (implemented in Stage 7).
/// Kept empty in Stage 2 so later stages can fill it in.
class WorkoutStripSlot extends StatelessWidget {
  const WorkoutStripSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(
      key: Key('workout_strip_slot'),
    );
  }
}
