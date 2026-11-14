import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../providers/habits_providers.dart';

/// Modal sheet to create a new habit.
/// Contains ONLY the habit title field per Stage 6 specification.
class AddHabitSheet extends ConsumerStatefulWidget {
  const AddHabitSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(
        side: AppTheme.borderSide1,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.maxRadius)),
      ),
      builder: (ctx) => const AddHabitSheet(),
    );
  }

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  final _titleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(habitsProvider.notifier).createHabit(_titleController.text.trim());
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create habit: $e')),
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
                  'New Habit',
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
              key: const Key('add_habit_title_field'),
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Habit Title',
                hintText: 'e.g. Read 20 pages, Meditate, Drink 3L water',
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Please enter a habit title';
                }
                return null;
              },
              onFieldSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const Key('create_habit_button'),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Create Habit'),
            ),
          ],
        ),
      ),
    );
  }
}
