import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../providers/workout_providers.dart';

/// Modal bottom sheet to add a new workout exercise template.
/// Contains ONLY exercise name and sets/reps fields.
class AddExerciseSheet extends ConsumerStatefulWidget {
  final int weekday;

  const AddExerciseSheet({super.key, required this.weekday});

  static Future<void> show(BuildContext context, int weekday) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        side: AppTheme.borderSide1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => AddExerciseSheet(weekday: weekday),
    );
  }

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _nameController = TextEditingController();
  final _setsRepsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _setsRepsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(workoutExercisesProvider.notifier).addExercise(
            weekday: widget.weekday,
            exerciseName: _nameController.text.trim(),
            setsReps: _setsRepsController.text.trim(),
          );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add exercise: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: bottomInset + 20.0,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    letterSpacing: -0.2,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('exercise_name_field'),
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Exercise Name',
                hintText: 'e.g. Flat Dumbbell Press, Incline Barbell, Pull-ups',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter an exercise name';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              key: const Key('exercise_sets_reps_field'),
              controller: _setsRepsController,
              decoration: const InputDecoration(
                labelText: 'Sets & Reps',
                hintText: 'e.g. 4 x 10, 3 x 12, Drop set to failure',
              ),
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('save_exercise_button'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Add Exercise'),
            ),
          ],
        ),
      ),
    );
  }
}
