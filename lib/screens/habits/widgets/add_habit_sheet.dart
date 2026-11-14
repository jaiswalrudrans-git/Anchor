import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/habit_icons.dart';
import '../../../core/constants/theme.dart';
import '../../../models/habit.dart';
import '../../../providers/habits_providers.dart';
import '../../../widgets/motion/pressable_scale.dart';

/// Modal sheet to create or edit a habit.
/// Contains ONLY the habit title field and a 24-icon picker grid per Stage 5 specification.
class AddHabitSheet extends ConsumerStatefulWidget {
  final Habit? initialHabit;

  const AddHabitSheet({super.key, this.initialHabit});

  static Future<void> show(BuildContext context, {Habit? initialHabit}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddHabitSheet(initialHabit: initialHabit),
    );
  }

  @override
  ConsumerState<AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<AddHabitSheet> {
  late final TextEditingController _titleController;
  final _formKey = GlobalKey<FormState>();
  late String _selectedIcon;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialHabit?.title ?? '');
    _selectedIcon = widget.initialHabit?.icon ?? 'check_circle';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      if (widget.initialHabit == null) {
        await ref.read(habitsProvider.notifier).createHabit(
              _titleController.text.trim(),
              icon: _selectedIcon,
            );
      } else {
        await ref.read(habitsProvider.notifier).editHabit(
              widget.initialHabit!.id,
              title: _titleController.text.trim(),
              icon: _selectedIcon,
            );
      }
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save habit: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialHabit != null;

    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(
          top: BorderSide(color: palette.border, width: 1.0),
          left: BorderSide(color: palette.border, width: 1.0),
          right: BorderSide(color: palette.border, width: 1.0),
        ),
      ),
      padding: EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        top: 20.0,
        bottom: bottomInset + 20.0,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Habit' : 'New Habit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: palette.textPrimary,
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
                    return 'Enter a habit title';
                  }
                  return null;
                },
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 16),
              Text(
                'Choose Icon',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: palette.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              // 24 icons grid (6 columns)
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: HabitIcons.allKeys.map((iconKey) {
                  final isSelected = _selectedIcon == iconKey;
                  final iconData = HabitIcons.getIcon(iconKey);

                  return PressableScale(
                    onTap: () => setState(() => _selectedIcon = iconKey),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected ? palette.accentSoft : palette.cardRaised,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? palette.accent : palette.border,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          iconData,
                          size: 22,
                          color: isSelected ? palette.accent : palette.textSecondary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                key: const Key('create_habit_button'),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: palette.onAccent),
                      )
                    : Text(isEditing ? 'Save Changes' : 'Create Habit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
