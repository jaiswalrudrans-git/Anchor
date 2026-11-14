import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/theme.dart';
import '../../../providers/workout_providers.dart';

/// Dialog to set or edit the split title for a specific weekday.
class EditSplitDialog extends ConsumerStatefulWidget {
  final int weekday;
  final String currentTitle;

  const EditSplitDialog({
    super.key,
    required this.weekday,
    required this.currentTitle,
  });

  static Future<void> show(BuildContext context, int weekday, String currentTitle) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => EditSplitDialog(weekday: weekday, currentTitle: currentTitle),
    );
  }

  @override
  ConsumerState<EditSplitDialog> createState() => _EditSplitDialogState();
}

class _EditSplitDialogState extends ConsumerState<EditSplitDialog> {
  late final TextEditingController _controller;
  bool _isSubmitting = false;

  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(workoutDaysProvider.notifier).setSplitTitle(widget.weekday, title);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update split: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dayName = _weekdayNames[widget.weekday - 1];

    return AlertDialog(
      title: Text('Set Split for $dayName'),
      shape: RoundedRectangleBorder(
        side: AppTheme.borderSide1,
        borderRadius: AppTheme.borderRadius8,
      ),
      content: TextField(
        key: const Key('split_title_field'),
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Split Title',
          hintText: 'e.g. Chest & Shoulders, Back & Biceps, Rest Day',
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          key: const Key('save_split_title_button'),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
