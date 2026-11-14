import 'package:flutter/material.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/responsive_container.dart';

/// Academics tab placeholder screen.
class AcademicsScreen extends StatelessWidget {
  const AcademicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Academics'),
      ),
      body: const SafeArea(
        child: ResponsiveContainer(
          child: EmptyState(
            icon: Icons.school_outlined,
            title: 'Academics & Vault',
            message: 'Subjects, modules, chapters, files and exam schedules will be organized here in Stage 3.',
          ),
        ),
      ),
    );
  }
}
